import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../models/mitre_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/download_helper.dart';
import 'dart:convert';

class SearchAndFilterBar extends ConsumerWidget {
  const SearchAndFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(coverageFilterProvider);
    final resultsAsync = ref.watch(filteredMatrixProvider);
    final themeMode = ref.watch(themeModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : AppTheme.divider;

    return Container(
      color: theme.cardTheme.color ?? theme.cardColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingMd : AppTheme.spacingLg,
        vertical: isMobile ? AppTheme.spacingSm : AppTheme.spacingMd,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: isMobile ? 48 : null, // Ensure touch target on mobile
                          child: TextField(
                            onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                            decoration: InputDecoration(
                              hintText: isDesktop
                                  ? 'Search by Technique Name or ID (e.g. T1078)'
                                  : 'Search techniques...',
                              prefixIcon: Icon(Icons.search, color: theme.hintColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: BorderSide(color: theme.colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 0,
                                horizontal: AppTheme.spacingMd,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? AppTheme.spacingSm : AppTheme.spacingMd),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                          icon: Icon(
                            themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                            size: isMobile ? 22 : 24,
                          ),
                          tooltip: 'Toggle Theme',
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: AppTheme.spacingMd),
                        _buildFilterDropdown(context, ref, currentFilter, isMobile: false),
                        const SizedBox(width: AppTheme.spacingMd),
                        ElevatedButton.icon(
                          onPressed: () => _handleExport(ref),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isDesktop) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(child: _buildFilterDropdown(context, ref, currentFilter, isMobile: true)),
                        const SizedBox(width: AppTheme.spacingSm),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            onPressed: () => _handleExport(ref),
                            icon: const Icon(Icons.download),
                            tooltip: 'Export JSON',
                          ),
                        ),
                        resultsAsync.when(
                          data: (tactics) {
                            final uniqueIds = <String>{};
                            for (var t in tactics) {
                              for (var tech in t.techniques) {
                                uniqueIds.add(tech.id);
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                              child: Text(
                                '${uniqueIds.length} found',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, stack) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                  if (isDesktop) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        resultsAsync.when(
                          data: (tactics) {
                            final uniqueIds = <String>{};
                            for (var t in tactics) {
                              for (var tech in t.techniques) {
                                uniqueIds.add(tech.id);
                              }
                            }
                            return Text(
                              '${uniqueIds.length} techniques match',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, stack) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, WidgetRef ref, CoverageFilter currentFilter, {required bool isMobile}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : AppTheme.divider;

    return Container(
      height: isMobile ? 48 : null, // Ensure touch target on mobile
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingSm : AppTheme.spacingMd,
        vertical: isMobile ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CoverageFilter>(
          value: currentFilter,
          isExpanded: isMobile,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          onChanged: (value) {
            if (value != null) {
              ref.read(coverageFilterProvider.notifier).state = value;
            }
          },
          items: [
            DropdownMenuItem(
              value: CoverageFilter.all,
              child: Text(isMobile ? 'All' : 'Show All'),
            ),
            DropdownMenuItem(
              value: CoverageFilter.covered,
              child: Text(isMobile ? 'Covered' : 'Covered Only'),
            ),
            DropdownMenuItem(
              value: CoverageFilter.partial,
              child: Text(isMobile ? 'Partial' : 'Partial Coverage'),
            ),
            DropdownMenuItem(
              value: CoverageFilter.gaps,
              child: Text(isMobile ? 'Gaps' : 'Gaps Only'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExport(WidgetRef ref) {
    final matrixAsync = ref.read(attackMatrixProvider);
    matrixAsync.whenData((tactics) {
      final layer = {
        'name': 'ATT&CK Coverage Export',
        'versions': {
          'attack': '18',
          'navigator': '4.5',
          'layer': '4.4',
        },
        'domain': 'enterprise-attack',
        'techniques': tactics.expand((t) => t.techniques).map((tech) => {
          'techniqueID': tech.id,
          'score': tech.coverage == CoverageLevel.high ? 100 : tech.coverage == CoverageLevel.medium ? 50 : 0,
          'color': '#${tech.coverage.color.toARGB32().toRadixString(16).substring(2)}',
          'comment': 'Exported from TachTech Labs Dashboard',
        }).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(layer);
      downloadStringAsFile(jsonString, 'attck_coverage_layer.json');
    });
  }
}
