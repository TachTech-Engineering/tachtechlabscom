import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../theme/app_theme.dart';

class OverallCoverageBar extends ConsumerWidget {
  const OverallCoverageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(overallSummaryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return summaryAsync.when(
      data: (summary) => Container(
        padding: EdgeInsets.all(isMobile ? AppTheme.spacingSm : AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  // Mobile: Stack the info vertically
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${summary.covered}/${summary.total} covered',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: summary.percentage > 70 ? AppTheme.coverageHigh :
                                 summary.percentage > 30 ? AppTheme.coverageMedium : AppTheme.coverageLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          '${summary.percentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Desktop: Single line
                  Text(
                    'Overall: ${summary.covered} / ${summary.total} techniques covered (${summary.percentage.toStringAsFixed(1)}%)',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: LinearProgressIndicator(
                    value: summary.percentage / 100,
                    minHeight: isMobile ? 8 : 12,
                    backgroundColor: isDark ? Colors.grey[800] : AppTheme.divider,
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
