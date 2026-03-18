import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import '../../providers/dashboard_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedTechniqueIdProvider);
    final isSelected = selectedId == widget.technique.id;
    final hasSubTechniques = widget.technique.subTechniques.isNotEmpty;
    
    // Determine cell display string
    String truncatedName = widget.technique.name;
    if (truncatedName.length > 20) {
      truncatedName = '${truncatedName.substring(0, 18)}...';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Toggle selection
          if (isSelected) {
            ref.read(selectedTechniqueIdProvider.notifier).state = null;
          } else {
            ref.read(selectedTechniqueIdProvider.notifier).state = widget.technique.id;
          }
        },
        child: Tooltip(
          message: '${widget.technique.id}: ${widget.technique.name}\nCoverage: ${widget.technique.coverage.name}',
          waitDuration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: widget.technique.coverage.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: isSelected
                  ? Border.all(color: AppTheme.textPrimary, width: 2)
                  : Border.all(color: Colors.black12, width: 1),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.technique.id,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: _getTextColor(widget.technique.coverage.color),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        truncatedName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: _getTextColor(widget.technique.coverage.color),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasSubTechniques)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '${widget.technique.subTechniques.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
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
    // Determine text color based on background darkness
    if (background == AppTheme.coverageNone || background == AppTheme.coverageLow) {
      return AppTheme.textPrimary;
    }
    return Colors.white;
  }
}
