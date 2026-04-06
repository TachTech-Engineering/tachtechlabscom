import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Coverage data for a single technique from the API
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

/// Summary data from the API
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

/// Full API response
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
      fromCache: json['fromCache'] ?? false,
    );
  }
}

/// Service to fetch coverage data from the CrowdStrike API proxy
class CoverageService {
  // Use appropriate host based on platform
  // - Android emulator: 10.0.2.2 (maps to host machine's localhost)
  // - Web/Desktop debug: 127.0.0.1
  // - Production: relative /api path
  String get _baseUrl {
    if (kDebugMode) {
      // Check if we're on Android (emulator uses 10.0.2.2 to reach host)
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5055/tachtechlabscom/us-central1';
      }
      return 'http://127.0.0.1:5055/tachtechlabscom/us-central1';
    }
    return '/api';
  }

  /// Get Firebase Auth token for authenticated requests
  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('Failed to get auth token: $e');
    }
    return null;
  }

  /// Build headers with optional auth token
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = await _getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Fetch coverage data from the API
  Future<CoverageResponse> fetchCoverage({bool refresh = false}) async {
    final url = Uri.parse('$_baseUrl/getCoverage${refresh ? '?refresh=true' : ''}');

    try {
      final headers = await _buildHeaders();
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CoverageResponse.fromJson(json);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Coverage fetch error: $e');
      rethrow;
    }
  }

  /// Check API health
  Future<bool> checkHealth() async {
    final url = Uri.parse('$_baseUrl/health');

    try {
      final headers = await _buildHeaders();
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      debugPrint('Health check error: $e');
      return false;
    }
  }
}
