import 'package:flutter/material.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import 'technique_grid.dart';
import 'tactic_header.dart';

class TacticAccordion extends StatefulWidget {
  final Tactic tactic;

  const TacticAccordion({super.key, required this.tactic});

  @override
  State<TacticAccordion> createState() => _TacticAccordionState();
}

class _TacticAccordionState extends State<TacticAccordion> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          title: TacticHeader(
            tactic: widget.tactic,
            isExpanded: _isExpanded,
          ),
          children: [
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: TechniqueGrid(techniques: widget.tactic.techniques),
            ),
          ],
        ),
      ),
    );
  }
}
