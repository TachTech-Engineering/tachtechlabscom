import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as dotenv from "dotenv";

// Load .env.local file for local development (not deployed)
dotenv.config({ path: ".env.local" });

// Define secrets for production (Cloud Secret Manager)
const csClientIdSecret = defineSecret("CROWDSTRIKE_CLIENT_ID");
const csClientSecretSecret = defineSecret("CROWDSTRIKE_CLIENT_SECRET");

admin.initializeApp();

const db = admin.firestore();

// Cache configuration
const CACHE_TTL_MS = 15 * 60 * 1000; // 15 minutes

interface CoverageData {
  coverage: Record<string, {
    techniqueId: string;
    covered: boolean;
    coverageLevel: "full" | "partial" | "inactive" | "none";
    enabledRules: number;
    totalRules: number;
    alertCount: number;
    hasAlerts: boolean;
    rules: Array<{
      id: string;
      name: string;
      enabled: boolean;
      source: "correlation" | "ioa";
    }>;
  }>;
  summary: {
    totalTechniquesCovered: number;
    totalCorrelationRules: number;
    totalIOARules: number;
    totalAlerts: number;
    techniquesWithAlerts: number;
    techniquesWithRules: number;
    timestamp: string;
  };
}

// In-memory cache (fallback when Firestore emulator isn't available)
let memoryCachedCoverage: { data: CoverageData; cachedAt: number } | null = null;

/**
 * Get coverage from cache if fresh
 * Uses Firestore if available, falls back to in-memory
 */
async function getCachedCoverage(): Promise<CoverageData | null> {
  // Try Firestore first
  try {
    const cacheDoc = await db.collection("cache").doc("coverage").get();
    if (cacheDoc.exists) {
      const data = cacheDoc.data();
      if (data && data.cachedAt) {
        const cachedAt = data.cachedAt.toDate().getTime();
        if (Date.now() - cachedAt <= CACHE_TTL_MS) {
          console.log("Using Firestore cached coverage data");
          return data.data as CoverageData;
        }
      }
    }
  } catch (error) {
    console.log("Firestore not available, using memory cache");
  }

  // Fallback to in-memory cache
  if (memoryCachedCoverage && Date.now() - memoryCachedCoverage.cachedAt <= CACHE_TTL_MS) {
    console.log("Using in-memory cached coverage data");
    return memoryCachedCoverage.data;
  }

  return null;
}

/**
 * Save coverage to cache
 * Uses Firestore if available, falls back to in-memory
 */
async function setCachedCoverage(data: CoverageData): Promise<void> {
  // Always update in-memory cache
  memoryCachedCoverage = { data, cachedAt: Date.now() };

  // Try Firestore
  try {
    await db.collection("cache").doc("coverage").set({
      data,
      cachedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Also save individual technique documents for querying
    const batch = db.batch();
    for (const [techId, techData] of Object.entries(data.coverage)) {
      const techRef = db.collection("techniques").doc(techId);
      batch.set(techRef, {
        ...techData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    console.log(`Cached ${Object.keys(data.coverage).length} techniques to Firestore`);
  } catch (error) {
    console.log("Firestore not available, using memory cache only");
  }
}

// CrowdStrike API configuration
const CS_BASE_URL = "https://api.crowdstrike.com";

interface TokenResponse {
  access_token: string;
  expires_in: number;
}

interface CachedToken {
  token: string;
  expiresAt: number;
}

let tokenCache: CachedToken | null = null;

/**
 * Get CrowdStrike credentials from either environment (local) or secrets (production)
 */
function getCredentials(): { clientId: string; clientSecret: string } {
  // Try secrets first (production), fall back to env vars (local dev)
  const clientId = csClientIdSecret.value() || process.env.CROWDSTRIKE_CLIENT_ID || "";
  const clientSecret = csClientSecretSecret.value() || process.env.CROWDSTRIKE_CLIENT_SECRET || "";
  return { clientId, clientSecret };
}

/**
 * Get OAuth2 token from CrowdStrike
 */
async function getAccessToken(): Promise<string> {
  // Check if we have a valid cached token
  if (tokenCache && tokenCache.expiresAt > Date.now() + 60000) {
    return tokenCache.token;
  }

  const { clientId, clientSecret } = getCredentials();

  if (!clientId || !clientSecret) {
    throw new Error("CrowdStrike credentials not configured");
  }

  const response = await fetch(`${CS_BASE_URL}/oauth2/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
    }),
  });

  if (!response.ok) {
    throw new Error(`Failed to get access token: ${response.status}`);
  }

  const data: TokenResponse = await response.json();

  // Cache the token (expire 60 seconds early for safety)
  tokenCache = {
    token: data.access_token,
    expiresAt: Date.now() + (data.expires_in - 60) * 1000,
  };

  return tokenCache.token;
}

/**
 * Make authenticated request to CrowdStrike API
 */
async function csApiRequest(endpoint: string, options: RequestInit = {}) {
  const token = await getAccessToken();

  const response = await fetch(`${CS_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      ...options.headers,
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`CrowdStrike API error: ${response.status} - ${errorText}`);
  }

  return response.json();
}

/**
 * Extract ATT&CK technique IDs from rule name/description
 */
function extractTechniqueIds(text: string): string[] {
  const pattern = /T\d{4}(?:\.\d{3})?/g;
  const matches = text.match(pattern) || [];
  return [...new Set(matches)]; // Remove duplicates
}

// v2 function options with CORS and secrets
const functionOpts = {
  cors: true,
  secrets: [csClientIdSecret, csClientSecretSecret],
};

/**
 * Get Correlation Rules from CrowdStrike Next-Gen SIEM
 */
export const getCorrelationRules = onRequest(functionOpts, async (req, res) => {
  try {
      // Get all correlation rules
      const rulesResponse = await csApiRequest(
        "/correlation-rules/queries/rules/v1?limit=500"
      );

      const ruleIds = rulesResponse.resources || [];

      if (ruleIds.length === 0) {
        res.json({ rules: [], techniqueMapping: {} });
        return;
      }

      // Get full rule details
      const detailsResponse = await csApiRequest(
        "/correlation-rules/entities/rules/v1",
        {
          method: "POST",
          body: JSON.stringify({ ids: ruleIds }),
        }
      );

      const rules = detailsResponse.resources || [];

      // Build technique mapping
      const techniqueMapping: Record<string, Array<{
        ruleId: string;
        ruleName: string;
        enabled: boolean;
        severity: string;
      }>> = {};

      for (const rule of rules) {
        const name = rule.name || "";
        const description = rule.description || "";
        const techniqueIds = extractTechniqueIds(`${name} ${description}`);

        for (const techId of techniqueIds) {
          if (!techniqueMapping[techId]) {
            techniqueMapping[techId] = [];
          }
          techniqueMapping[techId].push({
            ruleId: rule.id,
            ruleName: rule.name,
            enabled: rule.enabled ?? true,
            severity: rule.severity || "medium",
          });
        }
      }

      res.json({
        rules,
        techniqueMapping,
        totalRules: rules.length,
        mappedTechniques: Object.keys(techniqueMapping).length,
      });
  } catch (error) {
    console.error("Error fetching correlation rules:", error);
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Get Custom IOA Rules
 */
export const getCustomIOARules = onRequest(functionOpts, async (req, res) => {
  try {
      // Get all IOA rule groups
      const groupsResponse = await csApiRequest(
        "/ioarules/queries/rule-groups/v1?limit=500"
      );

      const groupIds = groupsResponse.resources || [];

      if (groupIds.length === 0) {
        res.json({ ruleGroups: [], rules: [], techniqueMapping: {} });
        return;
      }

      // Get full group details with rules
      const detailsResponse = await csApiRequest(
        `/ioarules/entities/rule-groups/v1?ids=${groupIds.join("&ids=")}`
      );

      const ruleGroups = detailsResponse.resources || [];

      // Flatten all rules and build technique mapping
      const allRules: Array<Record<string, unknown>> = [];
      const techniqueMapping: Record<string, Array<{
        ruleId: string;
        ruleName: string;
        enabled: boolean;
        ruleGroupName: string;
      }>> = {};

      for (const group of ruleGroups) {
        const rules = group.rules || [];
        for (const rule of rules) {
          allRules.push(rule);

          const name = rule.name || "";
          const description = rule.description || "";
          const techniqueIds = extractTechniqueIds(`${name} ${description}`);

          for (const techId of techniqueIds) {
            if (!techniqueMapping[techId]) {
              techniqueMapping[techId] = [];
            }
            techniqueMapping[techId].push({
              ruleId: rule.instance_id,
              ruleName: rule.name,
              enabled: rule.enabled ?? true,
              ruleGroupName: group.name,
            });
          }
        }
      }

      res.json({
        ruleGroups,
        rules: allRules,
        techniqueMapping,
        totalRules: allRules.length,
        mappedTechniques: Object.keys(techniqueMapping).length,
      });
  } catch (error) {
    console.error("Error fetching IOA rules:", error);
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Get combined coverage data for the ATT&CK matrix
 * This is the main endpoint the Flutter app will call
 */
export const getCoverage = onRequest(functionOpts, async (req, res) => {
  try {
      // Check for fresh cache first (skip if ?refresh=true)
      const forceRefresh = req.query.refresh === "true";
      if (!forceRefresh) {
        const cached = await getCachedCoverage();
        if (cached) {
          res.json({ ...cached, fromCache: true });
          return;
        }
      }

      // Fetch rules, detections, and alerts in parallel
      const [correlationRules, ioaRules, alertsData, detectionsData] = await Promise.all([
        // Use combined endpoint for correlation rules (includes full details)
        csApiRequest("/correlation-rules/combined/rules/v1?limit=500")
          .then((res) => res.resources || [])
          .catch((e) => {
            console.error("Correlation rules error:", e);
            return [];
          }),

        csApiRequest("/ioarules/queries/rule-groups/v1?limit=500")
          .then(async (queryRes) => {
            if (!queryRes.resources?.length) return [];
            const details = await csApiRequest(
              `/ioarules/entities/rule-groups/v1?ids=${queryRes.resources.join("&ids=")}`
            );
            const groups = details.resources || [];
            return groups.flatMap((g: { rules?: Array<Record<string, unknown>> }) => g.rules || []);
          })
          .catch((e) => {
            console.error("IOA rules error:", e);
            return [];
          }),

        // Fetch unified alerts - filter for endpoint product (epp) which has ATT&CK data
        // Also try idp_detection and mobile products which may have ATT&CK mappings
        csApiRequest("/alerts/queries/alerts/v2?limit=500&sort=created_timestamp.desc&filter=product:['epp','idp_detection','mobile','falcon']")
          .then(async (queryRes) => {
            const totalAlerts = queryRes.meta?.pagination?.total || 0;
            console.log(`Found ${totalAlerts} endpoint alerts`);
            if (!queryRes.resources?.length) return { alerts: [], total: totalAlerts };

            // Fetch alert details
            const alertIds = queryRes.resources.slice(0, 200);
            const details = await csApiRequest(
              "/alerts/entities/alerts/v2",
              {
                method: "POST",
                body: JSON.stringify({ composite_ids: alertIds }),
              }
            );
            return { alerts: details.resources || [], total: totalAlerts };
          })
          .catch((e) => {
            console.error("Endpoint alerts error:", e);
            // Fallback: try without filter
            return csApiRequest("/alerts/queries/alerts/v2?limit=500&sort=created_timestamp.desc")
              .then(async (queryRes) => {
                const totalAlerts = queryRes.meta?.pagination?.total || 0;
                if (!queryRes.resources?.length) return { alerts: [], total: totalAlerts };
                const alertIds = queryRes.resources.slice(0, 200);
                const details = await csApiRequest(
                  "/alerts/entities/alerts/v2",
                  {
                    method: "POST",
                    body: JSON.stringify({ composite_ids: alertIds }),
                  }
                );
                return { alerts: details.resources || [], total: totalAlerts };
              })
              .catch(() => ({ alerts: [], total: 0 }));
          }),

        // Try incidents API as fallback - incidents often have ATT&CK technique data
        csApiRequest("/incidents/queries/incidents/v1?limit=500&sort=start.desc")
          .then(async (queryRes) => {
            const totalIncidents = queryRes.meta?.pagination?.total || 0;
            console.log(`Found ${totalIncidents} incidents`);
            if (!queryRes.resources?.length) return { detections: [], total: totalIncidents };

            // Fetch incident details
            const incidentIds = queryRes.resources.slice(0, 200);
            const details = await csApiRequest(
              "/incidents/entities/incidents/GET/v1",
              {
                method: "POST",
                body: JSON.stringify({ ids: incidentIds }),
              }
            );
            return { detections: details.resources || [], total: totalIncidents };
          })
          .catch((e) => {
            console.error("Incidents error:", e);
            return { detections: [], total: 0 };
          }),
      ]);

      // Build unified technique coverage map
      const coverage: Record<string, {
        techniqueId: string;
        covered: boolean;
        coverageLevel: "full" | "partial" | "inactive" | "none";
        enabledRules: number;
        totalRules: number;
        alertCount: number;
        hasAlerts: boolean;
        rules: Array<{
          id: string;
          name: string;
          enabled: boolean;
          source: "correlation" | "ioa";
        }>;
      }> = {};

      // Helper to ensure technique entry exists
      const ensureTechnique = (techId: string) => {
        if (!coverage[techId]) {
          coverage[techId] = {
            techniqueId: techId,
            covered: false,
            coverageLevel: "none",
            enabledRules: 0,
            totalRules: 0,
            alertCount: 0,
            hasAlerts: false,
            rules: [],
          };
        }
      };

      // Process correlation rules - use mitre_attack field if available
      for (const rule of correlationRules) {
        // First try the structured mitre_attack array
        const mitreAttack = rule.mitre_attack as Array<{tactic_id?: string; technique_id?: string}> || [];
        let techniqueIds: string[] = mitreAttack
          .map((m) => m.technique_id)
          .filter((id): id is string => !!id);

        // Fallback: also check technique field directly
        if (rule.technique && !techniqueIds.includes(rule.technique)) {
          techniqueIds.push(rule.technique);
        }

        // Fallback: extract from name/description if no structured data
        if (techniqueIds.length === 0) {
          const text = `${rule.name || ""} ${rule.description || ""}`;
          techniqueIds = extractTechniqueIds(text);
        }

        const isEnabled = rule.status === "active" || rule.enabled === true;

        for (const techId of techniqueIds) {
          ensureTechnique(techId);
          coverage[techId].rules.push({
            id: rule.id || rule.rule_id,
            name: rule.name,
            enabled: isEnabled,
            source: "correlation",
          });
          coverage[techId].totalRules++;
          if (isEnabled) coverage[techId].enabledRules++;
        }
      }

      // Process IOA rules
      for (const rule of ioaRules) {
        const text = `${rule.name || ""} ${rule.description || ""}`;
        const techniqueIds = extractTechniqueIds(text);

        for (const techId of techniqueIds) {
          ensureTechnique(techId);
          coverage[techId].rules.push({
            id: rule.instance_id,
            name: rule.name,
            enabled: rule.enabled ?? true,
            source: "ioa",
          });
          coverage[techId].totalRules++;
          if (rule.enabled) coverage[techId].enabledRules++;
        }
      }

      // Process alerts - extract ATT&CK techniques from endpoint alerts
      const alertTechniqueCounts: Record<string, number> = {};
      for (const alert of alertsData.alerts) {
        // Skip non-endpoint alerts (third-party integrations may not have ATT&CK data)
        const techniqueIds: string[] = [];

        // Check direct technique fields
        if (alert.technique_id) techniqueIds.push(alert.technique_id);
        if (alert.technique && !techniqueIds.includes(alert.technique)) {
          techniqueIds.push(alert.technique);
        }

        // Check behaviors array (common in Falcon alerts)
        if (alert.behaviors && Array.isArray(alert.behaviors)) {
          for (const behavior of alert.behaviors) {
            if (behavior.technique_id && !techniqueIds.includes(behavior.technique_id)) {
              techniqueIds.push(behavior.technique_id);
            }
          }
        }

        // Extract from pattern_id or tactic fields if present
        if (alert.tactic_id && alert.technique_id) {
          const techId = alert.technique_id;
          if (!techniqueIds.includes(techId)) techniqueIds.push(techId);
        }

        // Count alerts per technique
        for (const techId of techniqueIds) {
          alertTechniqueCounts[techId] = (alertTechniqueCounts[techId] || 0) + 1;
        }
      }

      // Merge alert data into coverage
      for (const [techId, count] of Object.entries(alertTechniqueCounts)) {
        ensureTechnique(techId);
        coverage[techId].alertCount += count;
        coverage[techId].hasAlerts = true;
      }

      // Process incidents/detections - these often have ATT&CK mappings via behaviors/techniques
      console.log(`Processing ${detectionsData.detections.length} incidents (total: ${detectionsData.total})`);
      for (const incident of detectionsData.detections) {
        const techniqueIds: string[] = [];

        // Incidents have techniques array directly
        if (incident.techniques && Array.isArray(incident.techniques)) {
          for (const tech of incident.techniques) {
            if (typeof tech === 'string' && !techniqueIds.includes(tech)) {
              techniqueIds.push(tech);
            } else if (tech.technique_id && !techniqueIds.includes(tech.technique_id)) {
              techniqueIds.push(tech.technique_id);
            }
          }
        }

        // Also check tactics (may contain technique references)
        if (incident.tactics && Array.isArray(incident.tactics)) {
          // Tactics don't directly give us techniques, but log for debugging
          console.log(`Incident tactics: ${incident.tactics.join(', ')}`);
        }

        // Check fine_score which may have technique breakdown
        if (incident.fine_score_details) {
          // This might have technique-level scores
          console.log(`Fine score details available for incident`);
        }

        // Count incidents per technique
        for (const techId of techniqueIds) {
          ensureTechnique(techId);
          coverage[techId].alertCount += 1;
          coverage[techId].hasAlerts = true;
        }
      }

      // Log technique extraction summary
      const extractedTechniques = Object.keys(coverage).filter(id => coverage[id].hasAlerts);
      console.log(`Extracted ${extractedTechniques.length} techniques from incidents: ${extractedTechniques.join(', ')}`);

      // Also try to extract from alert behaviors (endpoint alerts have these)
      for (const alert of alertsData.alerts) {
        if (alert.behaviors && Array.isArray(alert.behaviors)) {
          for (const behavior of alert.behaviors) {
            if (behavior.technique_id) {
              ensureTechnique(behavior.technique_id);
              coverage[behavior.technique_id].alertCount += 1;
              coverage[behavior.technique_id].hasAlerts = true;
            }
            if (behavior.technique && behavior.technique !== behavior.technique_id) {
              ensureTechnique(behavior.technique);
              coverage[behavior.technique].alertCount += 1;
              coverage[behavior.technique].hasAlerts = true;
            }
          }
        }
      }

      // Calculate coverage levels (rules + detections + alerts)
      for (const techId of Object.keys(coverage)) {
        const tech = coverage[techId];
        const hasRules = tech.totalRules > 0;
        const hasEnabledRules = tech.enabledRules > 0;
        const hasDetections = tech.hasAlerts && tech.alertCount > 0;

        // Coverage logic:
        // - Green (full): Has detections OR has enabled rules (technique is being detected)
        // - Yellow (partial): Has alerts but no enabled rules
        // - Orange (inactive): Has rules but all disabled
        // - Red (none): No rules, no detections
        if (hasDetections || hasEnabledRules) {
          // Any detection or enabled rule = full coverage (green)
          tech.coverageLevel = "full";
          tech.covered = true;
        } else if (hasRules && !hasEnabledRules) {
          // Rules exist but disabled = inactive (orange)
          tech.coverageLevel = "inactive";
          tech.covered = false;
        } else {
          // No rules, no detections = no coverage (red)
          tech.coverageLevel = "none";
          tech.covered = false;
        }
      }

      // Calculate summary stats
      const techniquesWithAlerts = Object.values(coverage).filter((c) => c.hasAlerts).length;
      const techniquesWithRules = Object.values(coverage).filter((c) => c.totalRules > 0).length;
      const totalDetectionCount = Object.values(coverage).reduce((sum, c) => sum + c.alertCount, 0);

      console.log(`Coverage summary: ${Object.values(coverage).filter((c) => c.covered).length} techniques covered`);
      console.log(`  - Techniques with detections: ${techniquesWithAlerts}`);
      console.log(`  - Techniques with rules: ${techniquesWithRules}`);
      console.log(`  - Total detections: ${totalDetectionCount}`);

      const result: CoverageData = {
        coverage,
        summary: {
          totalTechniquesCovered: Object.values(coverage).filter((c) => c.covered).length,
          totalCorrelationRules: correlationRules.length,
          totalIOARules: ioaRules.length,
          totalAlerts: alertsData.total + detectionsData.total,
          techniquesWithAlerts,
          techniquesWithRules,
          timestamp: new Date().toISOString(),
        },
      };

      // Cache the result for future requests
      await setCachedCoverage(result);

      res.json({ ...result, fromCache: false });
  } catch (error) {
    console.error("Error fetching coverage:", error);
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Debug endpoint - shows raw API responses
 */
export const debug = onRequest(functionOpts, async (req, res) => {
  try {
      const results: Record<string, unknown> = {};

      // Test correlation rules endpoint
      try {
        const correlationQuery = await csApiRequest(
          "/correlation-rules/queries/rules/v1?limit=10"
        );
        results.correlationRulesQuery = correlationQuery;
      } catch (e) {
        results.correlationRulesError = String(e);
      }

      // Test IOA rules endpoint
      try {
        const ioaQuery = await csApiRequest(
          "/ioarules/queries/rule-groups/v1?limit=10"
        );
        results.ioaRulesQuery = ioaQuery;
      } catch (e) {
        results.ioaRulesError = String(e);
      }

      // Try combined endpoint (query + details in one call)
      try {
        const combined = await csApiRequest(
          "/correlation-rules/combined/rules/v1?limit=100"
        );
        results.correlationRulesCombined = combined;
      } catch (e) {
        results.correlationRulesCombinedError = String(e);
      }

      // Also try GET method for entities
      if (results.correlationRulesQuery &&
          (results.correlationRulesQuery as {resources?: string[]}).resources?.length) {
        try {
          const ruleIds = (results.correlationRulesQuery as {resources: string[]}).resources;
          const details = await csApiRequest(
            `/correlation-rules/entities/rules/v1?ids=${ruleIds.join("&ids=")}`
          );
          results.correlationRulesDetails = details;
        } catch (e) {
          results.correlationRulesDetailsError = String(e);
        }
      }

      // Fetch full IOA rule group details
      if (results.ioaRulesQuery &&
          (results.ioaRulesQuery as {resources?: string[]}).resources?.length) {
        try {
          const groupIds = (results.ioaRulesQuery as {resources: string[]}).resources;
          const details = await csApiRequest(
            `/ioarules/entities/rule-groups/v1?ids=${groupIds.join("&ids=")}`
          );
          results.ioaRulesDetails = details;
        } catch (e) {
          results.ioaRulesDetailsError = String(e);
        }
      }

      // Test Alerts API (v2)
      try {
        // Get all alerts (any product)
        const alertsQuery = await csApiRequest(
          "/alerts/queries/alerts/v2?limit=50"
        );
        results.alertsQuery = alertsQuery;
        results.totalAlerts = alertsQuery.meta?.pagination?.total;

        // Fetch alert details
        if (alertsQuery.resources?.length) {
          const alertDetails = await csApiRequest(
            "/alerts/entities/alerts/v2",
            {
              method: "POST",
              body: JSON.stringify({ composite_ids: alertsQuery.resources.slice(0, 20) }),
            }
          );
          results.alertDetails = alertDetails;

          // Analyze alert types and extract techniques
          const productCounts: Record<string, number> = {};
          const techniques = new Set<string>();

          for (const alert of alertDetails.resources || []) {
            // Count by product
            const product = alert.product || 'unknown';
            productCounts[product] = (productCounts[product] || 0) + 1;

            // Extract ATT&CK data
            if (alert.tactic_id) techniques.add(alert.tactic_id);
            if (alert.technique_id) techniques.add(alert.technique_id);
            if (alert.technique) techniques.add(alert.technique);
            // Some alerts have behaviors array
            if (alert.behaviors) {
              for (const b of alert.behaviors) {
                if (b.tactic_id) techniques.add(b.tactic_id);
                if (b.technique_id) techniques.add(b.technique_id);
              }
            }
          }

          results.productCounts = productCounts;
          results.uniqueTechniques = Array.from(techniques);
        }
      } catch (e) {
        results.alertsError = String(e);
      }

      // Test Incidents API
      try {
        const incidentsQuery = await csApiRequest(
          "/incidents/queries/incidents/v1?limit=10"
        );
        results.incidentsQuery = incidentsQuery;
      } catch (e) {
        results.incidentsError = String(e);
      }

      // Test Next-Gen SIEM / Foundry / Investigation endpoints
      const siemEndpoints = [
        "/foundry/queries/detections/v1?limit=10",
        "/triage/queries/detections/v1?limit=10",
        "/investigate/queries/detections/v1?limit=10",
        "/search/queries/results/v1?limit=10",
        "/threatgraph/queries/detections/v1?limit=10",
        "/unified-detections/queries/detections/v1?limit=10",
      ];

      const siemEndpointTests: Record<string, unknown> = {};
      for (const endpoint of siemEndpoints) {
        try {
          const resp = await csApiRequest(endpoint);
          siemEndpointTests[endpoint] = { success: true, total: resp.meta?.pagination?.total, sample: resp.resources?.slice(0, 2) };
        } catch (e) {
          siemEndpointTests[endpoint] = { success: false, error: String(e).substring(0, 200) };
        }
      }
      results.siemEndpointTests = siemEndpointTests;

      // Try LogScale / Humio API endpoints (Next-Gen SIEM)
      const logscaleEndpoints = [
        "/humio/queries/v1",
        "/loggingapi/entities/saved-searches/v1",
        "/loggingapi/combined/detections/v1",
        "/data-replicator/queries/entities/v1",
        "/fdr/queries/detections/v1",
        "/ng-siem/queries/detections/v1",
      ];

      const logscaleTests: Record<string, unknown> = {};
      for (const endpoint of logscaleEndpoints) {
        try {
          const resp = await csApiRequest(endpoint);
          logscaleTests[endpoint] = { success: true, data: resp };
        } catch (e) {
          const errStr = String(e);
          logscaleTests[endpoint] = {
            success: false,
            is403: errStr.includes("403"),
            error: errStr.substring(0, 150)
          };
        }
      }
      results.logscaleTests = logscaleTests;

      // Check token scopes
      let tokenInfo = null;
      try {
        const token = await getAccessToken();
        // Decode JWT to see scopes (middle part is payload)
        const parts = token.split('.');
        if (parts.length === 3) {
          const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
          tokenInfo = {
            scopes: payload.scope || payload.scopes,
            exp: payload.exp,
            iss: payload.iss,
          };
        }
      } catch (e) {
        tokenInfo = { error: String(e) };
      }

      res.json({
        timestamp: new Date().toISOString(),
        env: {
          hasClientId: !!process.env.CROWDSTRIKE_CLIENT_ID,
          hasClientSecret: !!process.env.CROWDSTRIKE_CLIENT_SECRET,
        },
        tokenInfo,
        results,
      });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

/**
 * Health check endpoint
 */
export const health = onRequest(functionOpts, async (req, res) => {
  try {
    // Try to get a token to verify credentials work
    await getAccessToken();
    res.json({
      status: "healthy",
      crowdstrike: "connected",
      region: "us-1",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      status: "unhealthy",
      crowdstrike: "disconnected",
      error: String(error),
      timestamp: new Date().toISOString(),
    });
  }
});
