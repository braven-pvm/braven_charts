// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../widgets/chart_type_catalog.dart';
import '../widgets/standard_options.dart';

/// Fast chart-family overview. Detailed configuration belongs to the
/// dedicated chart pages nested directly below this destination.
class ChartTypesPage extends StatelessWidget {
  const ChartTypesPage({super.key, this.onOpenChartType});

  final ValueChanged<String>? onOpenChartType;

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Chart Types',
      subtitle:
          'Choose the right visual structure, then explore its complete feature set',
      chart: CustomScrollView(
        key: const ValueKey('chart-types-overview'),
        slivers: [
          SliverToBoxAdapter(child: _OverviewIntroduction()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverGrid(
            key: const ValueKey('chart-type-catalog-grid'),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 360,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final chartType = showcaseChartTypes[index];
              return ChartTypeCatalogCard(
                chartType: chartType,
                onOpen: onOpenChartType == null
                    ? null
                    : () => onOpenChartType!(chartType.slug),
              );
            }, childCount: showcaseChartTypes.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: _SelectionGuide()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
      ),
    );
  }
}

class _OverviewIntroduction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start with the data question',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use trends for change, areas for magnitude, bars for categories, scatter plots for relationships, and radial charts for part-to-whole stories.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            );
            final architectureNote = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Each family has its own runnable guide. New chart families join this catalog only when their package API and full demo are ready.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, const SizedBox(height: 16), architectureNote],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: architectureNote),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectionGuide extends StatelessWidget {
  const _SelectionGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selection guide',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _GuideItem(
                  icon: Icons.timeline,
                  title: 'Continuous X values',
                  body: 'Start with line or area.',
                ),
                _GuideItem(
                  icon: Icons.category_outlined,
                  title: 'Discrete categories',
                  body: 'Start with bar.',
                ),
                _GuideItem(
                  icon: Icons.scatter_plot_outlined,
                  title: 'Independent observations',
                  body: 'Start with scatter.',
                ),
                _GuideItem(
                  icon: Icons.donut_large_outlined,
                  title: 'One total',
                  body: 'Start with Pie or Donut.',
                ),
                _GuideItem(
                  icon: Icons.radar_outlined,
                  title: 'Several independent totals',
                  body: 'Start with Concentric Donut.',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cartesian families share interaction, axes, and annotations. Every family supports themes, tables, artifacts, and controller APIs.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
