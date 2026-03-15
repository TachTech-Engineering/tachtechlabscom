import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mitre_models.dart';
import '../services/matrix_service.dart';

/// Provider for the MatrixService
final matrixServiceProvider = Provider((ref) => MatrixService());

/// Provider that loads the base ATT&CK matrix data
final attackMatrixProvider = FutureProvider<List<Tactic>>((ref) async {
  final service = ref.watch(matrixServiceProvider);
  return await service.loadMatrix();
});

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

/// Summary data model for coverage statistics
class CoverageSummary {
  final int total;
  final int covered;
  final double percentage;

  CoverageSummary({required this.total, required this.covered, required this.percentage});
}

/// Provider that computes overall coverage summary
final overallSummaryProvider = Provider<AsyncValue<CoverageSummary>>((ref) {
  final matrixAsync = ref.watch(attackMatrixProvider);
  
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
    
    return CoverageSummary(total: total, covered: covered, percentage: percentage);
  });
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
