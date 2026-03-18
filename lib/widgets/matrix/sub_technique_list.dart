import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mitre_models.dart';
import '../../providers/dashboard_providers.dart';
import '../../services/coverage_service.dart';
import '../../theme/app_theme.dart';
import 'coverage_badge.dart';

class SubTechniqueList extends ConsumerWidget {
  final Technique technique;

  const SubTechniqueList({
    super.key,
    required this.technique,
  });

  /// Get MITRE ATT&CK URL for a technique or sub-technique ID
  String _getAttackUrl(String techniqueId) {
    // Convert T1484.001 to T1484/001 for URL
    final parts = techniqueId.split('.');
    if (parts.length == 2) {
      return 'https://attack.mitre.org/techniques/${parts[0]}/${parts[1]}/';
    }
    return 'https://attack.mitre.org/techniques/$techniqueId/';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  void _showDetailsDialog(BuildContext context, TechniqueCoverage? coverageData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              technique.coverage != CoverageLevel.none ? Icons.shield : Icons.shield_outlined,
              color: technique.coverage.color,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(technique.id, style: const TextStyle(fontFamily: 'monospace')),
                  Text(
                    technique.name,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Coverage Status
                _buildInfoRow(context, 'Coverage Status', _getCoverageStatusText(technique.coverage), technique.coverage.color),
                const Divider(),

                // Rules Info
                if (coverageData != null) ...[
                  _buildInfoRow(context, 'Total Rules', '${coverageData.totalRules}', null),
                  _buildInfoRow(context, 'Enabled Rules', '${coverageData.enabledRules}',
                    coverageData.enabledRules > 0 ? AppTheme.coverageHigh : null),
                  _buildInfoRow(context, 'Alerts', '${coverageData.alertCount}',
                    coverageData.alertCount > 0 ? Colors.orange : null),

                  if (coverageData.rules.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Text('Detection Rules:', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppTheme.spacingSm),
                    ...coverageData.rules.map((rule) => Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            rule.enabled ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: rule.enabled ? AppTheme.coverageHigh : Colors.grey,
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rule.name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  '${rule.source.toUpperCase()} • ${rule.enabled ? "Enabled" : "Disabled"}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.hintColor),
                        const SizedBox(width: AppTheme.spacingSm),
                        const Expanded(child: Text('No coverage data available from API')),
                      ],
                    ),
                  ),
                ],

                // Sub-techniques count
                const SizedBox(height: AppTheme.spacingMd),
                _buildInfoRow(context, 'Sub-techniques', '${technique.subTechniques.length}', null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl(_getAttackUrl(technique.id));
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View in ATT&CK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, Color? valueColor) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getCoverageStatusText(CoverageLevel level) {
    switch (level) {
      case CoverageLevel.high:
        return 'Full Coverage';
      case CoverageLevel.medium:
        return 'Partial Coverage';
      case CoverageLevel.low:
        return 'Inactive Rules';
      case CoverageLevel.none:
        return 'No Coverage';
      case CoverageLevel.loading:
        return 'Loading...';
      case CoverageLevel.blocked:
        return 'Blocked';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (technique.subTechniques.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coverageData = ref.watch(techniqueDetailProvider(technique.id));

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? Colors.grey[700]! : AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : AppTheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey[700]! : AppTheme.divider)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_tree, size: 16, color: theme.hintColor),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  '${technique.id} Sub-techniques',
                  style: theme.textTheme.bodyMedium?.copyWith(
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
            separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.grey[700] : null),
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

                    // ID & Name - Now Clickable
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _launchUrl(_getAttackUrl(sub.id)),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    sub.id,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              CoverageBadge(coverage: sub.coverage),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Link to ATT&CK page for this sub-technique
                    IconButton(
                      onPressed: () => _launchUrl(_getAttackUrl(sub.id)),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: 'View ${sub.id} in ATT&CK',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            },
          ),

          // Action Buttons Footer
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? Colors.grey[700]! : AppTheme.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDetailsDialog(context, coverageData),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(_getAttackUrl(technique.id)),
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
