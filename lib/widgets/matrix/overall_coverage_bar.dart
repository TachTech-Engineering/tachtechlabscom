import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../theme/app_theme.dart';

class OverallCoverageBar extends ConsumerWidget {
  const OverallCoverageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(overallSummaryProvider);

    return summaryAsync.when(
      data: (summary) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            bottom: BorderSide(color: AppTheme.divider),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall: ${summary.covered} / ${summary.total} techniques covered (${summary.percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: LinearProgressIndicator(
                    value: summary.percentage / 100,
                    minHeight: 12,
                    backgroundColor: AppTheme.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      summary.percentage > 70 ? AppTheme.coverageHigh : 
                      summary.percentage > 30 ? AppTheme.coverageMedium : AppTheme.coverageLow,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, stack) => const SizedBox.shrink(),
    );
  }
}
