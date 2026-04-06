import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Coverage data for a single technique from Firestore
class TechniqueCoverage {
  final String techniqueId;
  final bool covered;
  final String coverageLevel; // "full", "partial", "inactive", "none"
  final int enabledRules;
  final int totalRules;
  final int alertCount;
  final bool hasAlerts;
  final List<RuleCoverage> rules;

  TechniqueCoverage({
    required this.techniqueId,
    required this.covered,
    required this.coverageLevel,
    required this.enabledRules,
    required this.totalRules,
    required this.alertCount,
    required this.hasAlerts,
    required this.rules,
  });

  factory TechniqueCoverage.fromJson(Map<String, dynamic> json) {
    return TechniqueCoverage(
      techniqueId: json['techniqueId'] ?? '',
      covered: json['covered'] ?? false,
      coverageLevel: json['coverageLevel'] ?? 'none',
      enabledRules: json['enabledRules'] ?? 0,
      totalRules: json['totalRules'] ?? 0,
      alertCount: json['alertCount'] ?? 0,
      hasAlerts: json['hasAlerts'] ?? false,
      rules: (json['rules'] as List<dynamic>?)
              ?.map((r) => RuleCoverage.fromJson(r))
              .toList() ??
          [],
    );
  }
}

/// A detection rule from CrowdStrike
class RuleCoverage {
  final String id;
  final String name;
  final bool enabled;
  final String source; // "correlation" or "ioa"

  RuleCoverage({
    required this.id,
    required this.name,
    required this.enabled,
    required this.source,
  });

  factory RuleCoverage.fromJson(Map<String, dynamic> json) {
    return RuleCoverage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      enabled: json['enabled'] ?? false,
      source: json['source'] ?? '',
    );
  }
}

/// Summary data from Firestore
class CoverageApiSummary {
  final int totalTechniquesCovered;
  final int totalCorrelationRules;
  final int totalIOARules;
  final int totalAlerts;
  final int techniquesWithAlerts;
  final int techniquesWithRules;
  final String timestamp;

  CoverageApiSummary({
    required this.totalTechniquesCovered,
    required this.totalCorrelationRules,
    required this.totalIOARules,
    required this.totalAlerts,
    required this.techniquesWithAlerts,
    required this.techniquesWithRules,
    required this.timestamp,
  });

  factory CoverageApiSummary.fromJson(Map<String, dynamic> json) {
    return CoverageApiSummary(
      totalTechniquesCovered: json['totalTechniquesCovered'] ?? 0,
      totalCorrelationRules: json['totalCorrelationRules'] ?? 0,
      totalIOARules: json['totalIOARules'] ?? 0,
      totalAlerts: json['totalAlerts'] ?? 0,
      techniquesWithAlerts: json['techniquesWithAlerts'] ?? 0,
      techniquesWithRules: json['techniquesWithRules'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

/// Full coverage response
class CoverageResponse {
  final Map<String, TechniqueCoverage> coverage;
  final CoverageApiSummary summary;
  final bool fromCache;

  CoverageResponse({
    required this.coverage,
    required this.summary,
    required this.fromCache,
  });

  factory CoverageResponse.fromJson(Map<String, dynamic> json) {
    final coverageMap = <String, TechniqueCoverage>{};
    final coverageJson = json['coverage'] as Map<String, dynamic>? ?? {};

    for (final entry in coverageJson.entries) {
      coverageMap[entry.key] = TechniqueCoverage.fromJson(entry.value);
    }

    return CoverageResponse(
      coverage: coverageMap,
      summary: CoverageApiSummary.fromJson(json['summary'] ?? {}),
      fromCache: true, // Always from Firestore cache
    );
  }
}

/// Service to fetch coverage data directly from Firestore
/// No Cloud Function invocation - bypasses org policy entirely
class CoverageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch coverage data from Firestore
  /// Data is populated by scheduled Cloud Function (every 15 min)
  Future<CoverageResponse> fetchCoverage({bool refresh = false}) async {
    try {
      // Read directly from Firestore - no Cloud Function call
      // Functions write to cache/coverage, not coverage/current
      final doc = await _firestore.collection('cache').doc('coverage').get();

      if (!doc.exists) {
        debugPrint('No coverage data in Firestore yet - waiting for scheduled refresh');
        throw Exception('Coverage data not available. Please wait for initial data sync.');
      }

      final data = doc.data()!;
      return CoverageResponse.fromJson(data);
    } catch (e) {
      debugPrint('Firestore read error: $e');
      rethrow;
    }
  }

  /// Stream coverage data for real-time updates
  /// Useful if we want the UI to update when data changes
  Stream<CoverageResponse> streamCoverage() {
    return _firestore
        .collection('cache')
        .doc('coverage')
        .snapshots()
        .where((snapshot) => snapshot.exists)
        .map((snapshot) => CoverageResponse.fromJson(snapshot.data()!));
  }

  /// Check if coverage data is available
  Future<bool> checkHealth() async {
    try {
      final doc = await _firestore.collection('cache').doc('coverage').get();
      return doc.exists;
    } catch (e) {
      debugPrint('Health check error: $e');
      return false;
    }
  }

  /// Get last update timestamp
  Future<DateTime?> getLastUpdate() async {
    try {
      final doc = await _firestore.collection('cache').doc('coverage').get();
      if (doc.exists) {
        final updatedAt = doc.data()?['updatedAt'] as Timestamp?;
        return updatedAt?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get last update: $e');
      return null;
    }
  }
}
