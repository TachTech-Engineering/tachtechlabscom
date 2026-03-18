import 'package:flutter/material.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import 'coverage_badge.dart';

class SubTechniqueList extends StatelessWidget {
  final Technique technique;

  const SubTechniqueList({
    super.key,
    required this.technique,
  });

  @override
  Widget build(BuildContext context) {
    if (technique.subTechniques.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_tree, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  '${technique.id} Sub-techniques',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          
          // List of Sub-techniques
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: technique.subTechniques.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final sub = technique.subTechniques[index];
              return Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    // Status Icon
                    Icon(
                      sub.coverage != CoverageLevel.none ? Icons.check_circle : Icons.cancel,
                      color: sub.coverage != CoverageLevel.none ? AppTheme.coverageHigh : AppTheme.coverageNone,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    
                    // ID & Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sub.id,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              CoverageBadge(coverage: sub.coverage),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    // Link to CQL (mocked)
                    if (sub.coverage != CoverageLevel.none)
                      TextButton.icon(
                        onPressed: () {}, // Action to view CQL rule
                        icon: const Icon(Icons.code, size: 16),
                        label: const Text('View Rule'),
                      ),
                  ],
                ),
              );
            },
          ),
          
          // Action Buttons Footer
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Details'),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View in ATT&CK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
