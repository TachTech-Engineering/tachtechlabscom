import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/search/search_filter_bar.dart';
import '../widgets/matrix/tactic_accordion.dart';
import '../widgets/matrix/overall_coverage_bar.dart';

class MatrixPage extends ConsumerWidget {
  const MatrixPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTacticsAsync = ref.watch(filteredMatrixProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ATT&CK Coverage Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Center(
              child: Text(
                'v1.0 (Enterprise)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Persistent Search & Filters
          const SearchAndFilterBar(),
          
          // 2. Summary Bar
          const OverallCoverageBar(),

          // 3. Main Content Area
          Expanded(
            child: filteredTacticsAsync.when(
              data: (tactics) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: tactics.isEmpty 
                    ? const Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXl),
                        child: Center(
                          child: Text('No techniques found matching your search.'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                        itemCount: tactics.length,
                        itemBuilder: (context, index) {
                          return TacticAccordion(tactic: tactics[index]);
                        },
                      ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading ATT&CK data: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
