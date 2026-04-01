import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/breakpoints.dart';
import '../../providers/dashboard_providers.dart';
import 'technique_cell.dart';
import 'sub_technique_list.dart';

class TechniqueGrid extends ConsumerWidget {
  final List<Technique> techniques;

  const TechniqueGrid({
    super.key,
    required this.techniques,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedTechniqueIdProvider);
    
    // Check if any technique in this grid is currently selected
    Technique? selectedTechnique;
    if (selectedId != null) {
      try {
        selectedTechnique = techniques.firstWhere((t) => t.id == selectedId);
      } catch (_) {
        selectedTechnique = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine column count based on width
            final spacing = AppTheme.spacingSm;
            int columns;
            if (Breakpoints.isDesktop(constraints.maxWidth)) {
              columns = 6;
            } else if (Breakpoints.isTablet(constraints.maxWidth)) {
              columns = 4;
            } else if (constraints.maxWidth > 300) {
              columns = 2;
            } else {
              columns = 1; // Very narrow screens
            }

            final availableWidth = constraints.maxWidth - (spacing * (columns - 1));
            final cellWidth = (availableWidth / columns).clamp(100.0, double.infinity);

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: techniques.map((technique) {
                return TechniqueCell(
                  technique: technique,
                  width: cellWidth,
                );
              }).toList(),
            );
          },
        ),
        
        // Render Sub-Technique Drill-Down if a technique in this tactic is selected
        if (selectedTechnique != null)
          SubTechniqueList(technique: selectedTechnique),
      ],
    );
  }
}
