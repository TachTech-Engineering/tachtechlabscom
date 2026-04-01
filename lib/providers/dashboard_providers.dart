import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mitre_models.dart';
import '../services/matrix_service.dart';
import '../services/coverage_service.dart';

/// Provider for the MatrixService
final matrixServiceProvider = Provider((ref) => MatrixService());

/// Provider for the CoverageService
final coverageServiceProvider = Provider((ref) => CoverageService());

/// Provider that loads the base ATT&CK matrix data (without coverage)
final baseMatrixProvider = FutureProvider<List<Tactic>>((ref) async {
  final service = ref.watch(matrixServiceProvider);
  return await service.loadMatrix();
});

/// Provider that fetches coverage data from CrowdStrike API
final coverageDataProvider = FutureProvider<CoverageResponse?>((ref) async {
  final service = ref.watch(coverageServiceProvider);
  try {
    return await service.fetchCoverage();
  } catch (e) {
    debugPrint('Failed to fetch coverage: $e');
    return null; // Return null if API unavailable, matrix still renders
  }
});

/// Provider that merges ATT&CK matrix with live coverage data
final attackMatrixProvider = FutureProvider<List<Tactic>>((ref) async {
  final baseMatrix = await ref.watch(baseMatrixProvider.future);
  final coverageData = await ref.watch(coverageDataProvider.future);

  // If no coverage data, set all techniques to "none" (red) to indicate no detection
  if (coverageData == null) {
    return baseMatrix.map((tactic) {
      final updatedTechniques = tactic.techniques.map((technique) {
        final updatedSubTechniques = technique.subTechniques.map((sub) {
          return SubTechnique(
            id: sub.id,
            name: sub.name,
            coverage: CoverageLevel.none,
          );
        }).toList();
        return Technique(
          id: technique.id,
          name: technique.name,
          coverage: CoverageLevel.none,
          subTechniques: updatedSubTechniques,
        );
      }).toList();
      return Tactic(
        id: tactic.id,
        name: tactic.name,
        techniques: updatedTechniques,
      );
    }).toList();
  }

  // Merge coverage into the matrix
  // API data is available, so update all techniques (red for no detection, green for covered)
  return baseMatrix.map((tactic) {
    final updatedTechniques = tactic.techniques.map((technique) {
      // Check if we have coverage for this technique
      final coverage = coverageData.coverage[technique.id];
      final newCoverageLevel = _mapCoverageLevel(
        coverage?.coverageLevel,
        hasApiData: true,
      );

      // Also update sub-techniques - inherit from parent if no direct coverage
      final updatedSubTechniques = technique.subTechniques.map((sub) {
        final subCoverage = coverageData.coverage[sub.id];
        // If sub-technique has its own coverage, use it
        // Otherwise, inherit from parent technique (CrowdStrike often only reports parent IDs)
        final effectiveCoverage = subCoverage?.coverageLevel ?? coverage?.coverageLevel;
        return SubTechnique(
          id: sub.id,
          name: sub.name,
          coverage: _mapCoverageLevel(
            effectiveCoverage,
            hasApiData: true,
          ),
        );
      }).toList();

      return Technique(
        id: technique.id,
        name: technique.name,
        coverage: newCoverageLevel,
        subTechniques: updatedSubTechniques,
      );
    }).toList();

    return Tactic(
      id: tactic.id,
      name: tactic.name,
      techniques: updatedTechniques,
    );
  }).toList();
});

/// Map API coverage level string to CoverageLevel enum
/// Returns null if no coverage data exists (technique not in API response)
CoverageLevel _mapCoverageLevel(String? level, {bool hasApiData = false}) {
  if (level == null && !hasApiData) {
    // No API data yet - show as red (no detection)
    return CoverageLevel.none;
  }
  switch (level) {
    case 'full':
      return CoverageLevel.high;    // Green - has detection
    case 'partial':
      return CoverageLevel.medium;  // Yellow - partial coverage
    case 'inactive':
      return CoverageLevel.low;     // Orange - rules exist but disabled
    case 'none':
    default:
      return CoverageLevel.none;    // Red - no detection
  }
}

/// Notifier for search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Provider for debounced search query (300ms)
final debouncedSearchQueryProvider = FutureProvider<String>((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) return '';

  // Wait for 300ms
  await Future.delayed(const Duration(milliseconds: 300));
  
  return query;
});

/// Notifier for platform filter
class PlatformFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'Windows'};

  @override
  set state(Set<String> value) => super.state = value;
}

final platformFilterProvider = NotifierProvider<PlatformFilterNotifier, Set<String>>(PlatformFilterNotifier.new);

/// Enum for coverage filtering
enum CoverageFilter { all, covered, partial, gaps, notApplicable }

/// Notifier for coverage filter
class CoverageFilterNotifier extends Notifier<CoverageFilter> {
  @override
  CoverageFilter build() => CoverageFilter.all;

  @override
  set state(CoverageFilter value) => super.state = value;
}

final coverageFilterProvider = NotifierProvider<CoverageFilterNotifier, CoverageFilter>(CoverageFilterNotifier.new);

/// Notifier for currently selected technique ID
class SelectedTechniqueIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final selectedTechniqueIdProvider = NotifierProvider<SelectedTechniqueIdNotifier, String?>(SelectedTechniqueIdNotifier.new);

/// Notifier for ThemeMode
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Summary data model for coverage statistics
class CoverageSummary {
  final int total;
  final int covered;
  final double percentage;
  final int totalRules;
  final bool fromCache;
  final String? timestamp;

  CoverageSummary({
    required this.total,
    required this.covered,
    required this.percentage,
    this.totalRules = 0,
    this.fromCache = false,
    this.timestamp,
  });
}

/// Provider that computes overall coverage summary
final overallSummaryProvider = Provider<AsyncValue<CoverageSummary>>((ref) {
  final matrixAsync = ref.watch(attackMatrixProvider);
  final coverageAsync = ref.watch(coverageDataProvider);

  return matrixAsync.whenData((tactics) {
    // Collect all unique techniques across all tactics
    final allTechniques = <String, Technique>{};
    for (final tactic in tactics) {
      for (final tech in tactic.techniques) {
        allTechniques[tech.id] = tech;
      }
    }

    final total = allTechniques.length;
    final covered = allTechniques.values.where((t) => t.coverage != CoverageLevel.none).length;
    final percentage = total == 0 ? 0.0 : (covered / total) * 100;

    // Get additional info from coverage API response
    final coverageData = coverageAsync.whenOrNull(data: (d) => d);

    return CoverageSummary(
      total: total,
      covered: covered,
      percentage: percentage,
      totalRules: (coverageData?.summary.totalCorrelationRules ?? 0) +
                  (coverageData?.summary.totalIOARules ?? 0),
      fromCache: coverageData?.fromCache ?? false,
      timestamp: coverageData?.summary.timestamp,
    );
  });
});

/// Provider to get detailed coverage info for a specific technique
final techniqueDetailProvider = Provider.family<TechniqueCoverage?, String>((ref, techniqueId) {
  final coverageAsync = ref.watch(coverageDataProvider);
  final coverageData = coverageAsync.whenOrNull(data: (d) => d);
  return coverageData?.coverage[techniqueId];
});

/// Provider to refresh coverage data
final refreshCoverageProvider = FutureProvider.family<CoverageResponse?, bool>((ref, force) async {
  final service = ref.watch(coverageServiceProvider);
  try {
    return await service.fetchCoverage(refresh: force);
  } catch (e) {
    debugPrint('Failed to refresh coverage: $e');
    return null;
  }
});

/// Computed provider that applies all filters to the matrix data
final filteredMatrixProvider = Provider<AsyncValue<List<Tactic>>>((ref) {
  final matrixAsync = ref.watch(attackMatrixProvider);
  final queryAsync = ref.watch(debouncedSearchQueryProvider);
  final filter = ref.watch(coverageFilterProvider);

  return matrixAsync.whenData((tactics) {
    final query = queryAsync.value?.toLowerCase() ?? '';

    if (query.isEmpty && filter == CoverageFilter.all) {
      return tactics;
    }

    return tactics.map((tactic) {
      final filteredTechniques = tactic.techniques.where((technique) {
        // 1. Search Query Filter (Fuzzy match ID or Name)
        final matchesQuery = technique.id.toLowerCase().contains(query) || 
                             technique.name.toLowerCase().contains(query);
        
        final matchesSubQuery = technique.subTechniques.any((sub) => 
                                 sub.id.toLowerCase().contains(query) || 
                                 sub.name.toLowerCase().contains(query));

        if (!matchesQuery && !matchesSubQuery && query.isNotEmpty) return false;

        // 2. Coverage Status Filter
        switch (filter) {
          case CoverageFilter.covered:
            if (technique.coverage != CoverageLevel.high) return false;
            break;
          case CoverageFilter.partial:
            if (technique.coverage != CoverageLevel.medium && technique.coverage != CoverageLevel.low) return false;
            break;
          case CoverageFilter.gaps:
            if (technique.coverage != CoverageLevel.none) return false;
            break;
          case CoverageFilter.notApplicable:
            // Placeholder logic
            break;
          case CoverageFilter.all:
            break;
        }

        return true;
      }).toList();

      return Tactic(
        id: tactic.id,
        name: tactic.name,
        techniques: filteredTechniques,
      );
    }).where((tactic) => tactic.techniques.isNotEmpty).toList();
  });
});
