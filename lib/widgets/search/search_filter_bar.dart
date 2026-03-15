import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_providers.dart';
import '../../theme/app_theme.dart';

class SearchAndFilterBar extends ConsumerWidget {
  const SearchAndFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(coverageFilterProvider);
    final resultsAsync = ref.watch(filteredMatrixProvider);

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
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
                        child: TextField(
                          onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                          decoration: InputDecoration(
                            hintText: isDesktop 
                                ? 'Search by Technique Name or ID (e.g. T1078)' 
                                : 'Search by ID/Name...',
                            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: const BorderSide(color: AppTheme.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: const BorderSide(color: AppTheme.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: const BorderSide(color: AppTheme.primary),
                            ),
                            filled: true,
                            fillColor: AppTheme.background,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppTheme.spacingMd),
                          ),
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: AppTheme.spacingMd),
                        _buildFilterDropdown(ref, currentFilter),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: AppTheme.spacingSm,
                        runSpacing: isDesktop ? 0 : AppTheme.spacingSm,
                        children: [
                          FilterChip(
                            label: const Text('Windows'),
                            selected: true,
                            onSelected: (_) {},
                            selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                            checkmarkColor: AppTheme.primary,
                          ),
                          FilterChip(
                            label: const Text('Linux'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                          FilterChip(
                            label: const Text('macOS'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                          FilterChip(
                            label: const Text('Cloud'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                      resultsAsync.when(
                        data: (tactics) {
                          int techCount = 0;
                          for (var t in tactics) {
                            techCount += t.techniques.length;
                          }
                          return Text(
                            '$techCount techniques match',
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
                  if (!isDesktop) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildFilterDropdown(ref, currentFilter),
                  ],
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(WidgetRef ref, CoverageFilter currentFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CoverageFilter>(
          value: currentFilter,
          onChanged: (value) {
            if (value != null) {
              ref.read(coverageFilterProvider.notifier).state = value;
            }
          },
          items: const [
            DropdownMenuItem(value: CoverageFilter.all, child: Text('Show All')),
            DropdownMenuItem(value: CoverageFilter.covered, child: Text('Covered Only')),
            DropdownMenuItem(value: CoverageFilter.partial, child: Text('Partial Coverage')),
            DropdownMenuItem(value: CoverageFilter.gaps, child: Text('Gaps Only')),
          ],
        ),
      ),
    );
  }
}
