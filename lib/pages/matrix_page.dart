import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/search/search_filter_bar.dart';
import '../widgets/matrix/tactic_accordion.dart';
import '../widgets/matrix/overall_coverage_bar.dart';

class MatrixPage extends ConsumerStatefulWidget {
  final String? initialTechniqueId;

  const MatrixPage({super.key, this.initialTechniqueId});

  @override
  ConsumerState<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends ConsumerState<MatrixPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTechniqueId != null) {
      // Small delay to ensure providers are ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedTechniqueIdProvider.notifier).state = widget.initialTechniqueId;
      });
    }
  }

  Future<void> _handleRefresh() async {
    // Invalidate the coverage data to force a refresh
    ref.invalidate(coverageDataProvider);
    // Wait for new data to load
    await ref.read(coverageDataProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTacticsAsync = ref.watch(filteredMatrixProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'ATT&CK Coverage Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isMobile)
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
      body: SafeArea(
        child: Column(
          children: [
            // 1. Persistent Search & Filters
            const SearchAndFilterBar(),

            // 2. Summary Bar
            const OverallCoverageBar(),

            // 3. Main Content Area with Pull-to-Refresh
            Expanded(
              child: filteredTacticsAsync.when(
                data: (tactics) => RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: tactics.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(AppTheme.spacingXl),
                                child: Center(
                                  child: Text('No techniques found matching your search.'),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd,
                              horizontal: isMobile ? AppTheme.spacingXs : 0,
                            ),
                            itemCount: tactics.length,
                            itemBuilder: (context, index) {
                              return TacticAccordion(tactic: tactics[index]);
                            },
                          ),
                    ),
                  ),
                ),
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppTheme.spacingMd),
                      Text('Loading coverage data...'),
                    ],
                  ),
                ),
                error: (err, stack) => RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off_outlined,
                                size: 64,
                                color: AppTheme.coverageNone,
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                'Unable to load coverage data',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Text(
                                'The API may be temporarily unavailable.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.invalidate(coverageDataProvider);
                                  ref.invalidate(attackMatrixProvider);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
