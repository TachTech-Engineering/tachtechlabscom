import 'package:flutter/material.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/breakpoints.dart';

class TacticHeader extends StatelessWidget {
  final Tactic tactic;
  final bool isExpanded;

  const TacticHeader({
    super.key,
    required this.tactic,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    int total = tactic.techniques.length;
    int covered = tactic.techniques.where((t) => t.coverage != CoverageLevel.none).length;
    double percentage = total == 0 ? 0.0 : (covered / total) * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = Breakpoints.isMobile(constraints.maxWidth + 100); // Title row is narrower than screen

        return Row(
          children: [
            // Tactic ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                tactic.id,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Tactic Name
            Expanded(
              child: Text(
                tactic.name,
                style: isNarrow 
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
                    : Theme.of(context).textTheme.displaySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: AppTheme.spacingMd),
              // Mini Progress Bar
              _buildMiniProgressBar(context, covered, total),
            ],
            const SizedBox(width: AppTheme.spacingMd),
            // Fraction
            Text(
              '$covered/$total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Percentage
            SizedBox(
              width: 35,
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildMiniProgressBar(BuildContext context, int covered, int total) {
    double ratio = total == 0 ? 0 : covered / total;
    Color color = ratio > 0.7 ? AppTheme.coverageHigh : 
                  ratio > 0.3 ? AppTheme.coverageMedium : 
                  ratio > 0 ? AppTheme.coverageLow : AppTheme.coverageNone;

    return Row(
      children: List.generate(4, (index) {
        bool isActive = (ratio * 4) > index;
        return Container(
          width: 12,
          height: 8,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color : AppTheme.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
