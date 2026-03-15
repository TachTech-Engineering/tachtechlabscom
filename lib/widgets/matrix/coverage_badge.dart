import 'package:flutter/material.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';

class CoverageBadge extends StatelessWidget {
  final CoverageLevel coverage;

  const CoverageBadge({super.key, required this.coverage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: coverage.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: coverage.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        coverage.name,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: coverage.color == AppTheme.coverageNone || coverage.color == AppTheme.coverageLow 
                 ? AppTheme.textPrimary 
                 : coverage.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
