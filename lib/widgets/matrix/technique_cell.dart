import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_providers.dart';
import '../../services/coverage_service.dart';

class TechniqueCell extends ConsumerStatefulWidget {
  final Technique technique;
  final double width;

  const TechniqueCell({
    super.key,
    required this.technique,
    required this.width,
  });

  @override
  ConsumerState<TechniqueCell> createState() => _TechniqueCellState();
}

class _TechniqueCellState extends ConsumerState<TechniqueCell> {
  bool _isHovering = false;

  String _getAttackUrl(String techniqueId) {
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
    final technique = widget.technique;
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
                if (technique.subTechniques.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInfoRow(context, 'Sub-techniques', '${technique.subTechniques.length}', null),
                ],
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
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedTechniqueIdProvider);
    final isSelected = selectedId == widget.technique.id;
    final hasSubTechniques = widget.technique.subTechniques.isNotEmpty;
    final coverageData = ref.watch(techniqueDetailProvider(widget.technique.id));

    // Use full name - let overflow handle truncation naturally
    final displayName = widget.technique.name;

    final textColor = _getTextColor(widget.technique.coverage.color);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // For techniques without sub-techniques, show details directly
          if (!hasSubTechniques) {
            _showDetailsDialog(context, coverageData);
          } else {
            // Toggle selection to show/hide sub-techniques
            if (isSelected) {
              ref.read(selectedTechniqueIdProvider.notifier).state = null;
            } else {
              ref.read(selectedTechniqueIdProvider.notifier).state = widget.technique.id;
            }
          }
        },
        onLongPress: () {
          // Long press always shows details
          _showDetailsDialog(context, coverageData);
        },
        child: Tooltip(
          message: '${widget.technique.id}: ${widget.technique.name}\nCoverage: ${widget.technique.coverage.name}\n${hasSubTechniques ? "Tap to expand • " : ""}Long press for details',
          waitDuration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: 90, // Fixed height for uniform grid alignment
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 6),
            decoration: BoxDecoration(
              color: widget.technique.coverage.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: isSelected
                  ? Border.all(color: AppTheme.textPrimary, width: 2.5)
                  : Border.all(color: Colors.black26, width: 1),
              boxShadow: _isHovering || isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.technique.id,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: textColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                height: 1.2,
                                color: textColor.withValues(alpha: 0.9),
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSubTechniques)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${widget.technique.subTechniques.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTextColor(Color background) {
    // Calculate luminance for better contrast decisions
    final luminance = background.computeLuminance();
    // Use white text on dark backgrounds, dark text on light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
