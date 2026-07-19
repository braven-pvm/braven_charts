// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Public showcase metadata for one supported chart family.
///
/// The Gallery, Chart Types overview, and navigation all use these stable
/// slugs. Adding a future chart family should start here once its runnable
/// detail page and package API have landed.
class ShowcaseChartType {
  const ShowcaseChartType({
    required this.type,
    required this.label,
    required this.slug,
    required this.summary,
    required this.bestFor,
    required this.icon,
    required this.accent,
    required this.highlights,
  });

  final ChartType type;
  final String label;
  final String slug;
  final String summary;
  final String bestFor;
  final IconData icon;
  final Color accent;
  final List<String> highlights;

  /// Stable test and automation suffix, including composition variants.
  String get cardKeySuffix => slug == '${type.name}-charts' ? type.name : slug;
}

const showcaseChartTypes = <ShowcaseChartType>[
  ShowcaseChartType(
    type: ChartType.line,
    label: 'Line',
    slug: 'line-charts',
    summary: 'Continuous trends',
    bestFor: 'Time series and analytical workhorses',
    icon: Icons.show_chart,
    accent: Color(0xFF2563EB),
    highlights: ['4 interpolations', 'Motion', 'Synchronized'],
  ),
  ShowcaseChartType(
    type: ChartType.area,
    label: 'Area',
    slug: 'area-charts',
    summary: 'Magnitude and accumulation',
    bestFor: 'Volume, ranges, and baseline comparison',
    icon: Icons.area_chart_outlined,
    accent: Color(0xFF06B6D4),
    highlights: ['Layered fills', 'Baselines', 'Motion + data'],
  ),
  ShowcaseChartType(
    type: ChartType.bar,
    label: 'Bar',
    slug: 'bar-charts',
    summary: 'Category comparison',
    bestFor: 'Grouped, stacked, range, and waterfall data',
    icon: Icons.bar_chart,
    accent: Color(0xFF10B981),
    highlights: ['16 presets', 'Targets + uncertainty', 'Interaction + motion'],
  ),
  ShowcaseChartType(
    type: ChartType.scatter,
    label: 'Scatter',
    slug: 'scatter-charts',
    summary: 'Relationships and outliers',
    bestFor: 'Correlation and distinct observation sets',
    icon: Icons.scatter_plot_outlined,
    accent: Color(0xFF8B5CF6),
    highlights: ['Cohorts', 'Point styling', 'Tooltips'],
  ),
  ShowcaseChartType(
    type: ChartType.pie,
    label: 'Pie',
    slug: 'pie-charts',
    summary: 'Contribution to one whole',
    bestFor: 'Small categorical share datasets',
    icon: Icons.pie_chart_outline,
    accent: Color(0xFFE11D48),
    highlights: ['Labels', 'Motion', 'Grouping'],
  ),
  ShowcaseChartType(
    type: ChartType.donut,
    label: 'Donut',
    slug: 'donut-charts',
    summary: 'Contribution with center context',
    bestFor: 'Part-to-whole data that benefits from a central value',
    icon: Icons.donut_large_outlined,
    accent: Color(0xFF0F766E),
    highlights: ['Center', 'Variable radius', 'Motion'],
  ),
  ShowcaseChartType(
    type: ChartType.donut,
    label: 'Concentric Donut',
    slug: 'concentric-donut',
    summary: 'Independent totals, shared view',
    bestFor: 'Comparing distributions across periods or groups',
    icon: Icons.radar_outlined,
    accent: Color(0xFF7C3AED),
    highlights: ['Independent totals', 'Ring weights', 'Shared selection'],
  ),
];

ShowcaseChartType showcaseChartTypeForSlug(String slug) =>
    showcaseChartTypes.firstWhere((entry) => entry.slug == slug);

/// Small native chart preview used wherever users choose a chart family.
class ChartTypePreview extends StatelessWidget {
  const ChartTypePreview({super.key, required this.chartType});

  final ShowcaseChartType chartType;

  @override
  Widget build(BuildContext context) {
    final isRadial =
        chartType.type == ChartType.pie || chartType.type == ChartType.donut;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseTheme = isDark ? ChartTheme.dark : ChartTheme.light;
    final background = Color.alphaBlend(
      chartType.accent.withValues(alpha: isDark ? 0.08 : 0.045),
      baseTheme.backgroundColor,
    );

    final preview = BravenChartPlus(
      key: ValueKey('chart-type-preview-${chartType.cardKeySuffix}'),
      series: _previewSeries(chartType),
      concentricDonutConfig: chartType.slug == 'concentric-donut'
          ? const ConcentricDonutConfig(
              innerRadiusFactor: 0.25,
              outerRadiusFactor: 0.94,
              ringGap: 3,
              centerContent: DonutCenterContent(
                label: 'Rings',
                valueMode: DonutCenterValueMode.custom,
                customValue: '2',
              ),
            )
          : const ConcentricDonutConfig(),
      theme: baseTheme.copyWith(backgroundColor: background),
      showLegend: false,
      grid: isRadial
          ? const GridConfig(horizontal: false, vertical: false)
          : GridConfig(
              horizontal: true,
              vertical: false,
              horizontalColor: chartType.accent.withValues(alpha: 0.10),
            ),
      xAxisConfig: const XAxisConfig(visible: false),
      yAxis: YAxisConfig(position: YAxisPosition.hidden),
      interactionConfig: InteractionConfig.none(),
    );
    return IgnorePointer(
      child: chartType.slug == 'concentric-donut'
          ? Transform.scale(
              key: const ValueKey('chart-type-preview-scale-concentric-donut'),
              scale: 1.18,
              child: preview,
            )
          : preview,
    );
  }
}

/// A concise chart-family card. It deliberately explains selection rather
/// than exposing controls; configuration belongs on each detail page.
class ChartTypeCatalogCard extends StatelessWidget {
  const ChartTypeCatalogCard({
    super.key,
    required this.chartType,
    this.onOpen,
    this.compact = false,
  });

  final ShowcaseChartType chartType;
  final VoidCallback? onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('chart-type-card-${chartType.cardKeySuffix}'),
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: chartType.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        chartType.icon,
                        size: 19,
                        color: chartType.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chartType.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          chartType.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ChartTypePreview(chartType: chartType),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 12),
                Text(
                  chartType.bestFor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: chartType.highlights
                      .map(
                        (highlight) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            highlight,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (onOpen != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        compact
                            ? 'View ${_compactGuideName(chartType)}'
                            : 'Explore ${chartType.label.toLowerCase()} charts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 17, color: scheme.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: onOpen != null,
      label: '${chartType.label} charts. ${chartType.summary}',
      child: card,
    );
  }
}

/// One-row sampler on wide screens, horizontally scrollable when space is
/// constrained. This mirrors the compact pub.dev chart-family overview.
class ChartTypeCatalogStrip extends StatelessWidget {
  const ChartTypeCatalogStrip({super.key, this.onOpenChartType});

  final ValueChanged<String>? onOpenChartType;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final fittedWidth =
            (constraints.maxWidth - (gap * (showcaseChartTypes.length - 1))) /
            showcaseChartTypes.length;
        // Keep the complete family map visible on the standard 1440px
        // showcase viewport. Concise copy and enlarged native previews retain
        // legibility at this density; narrower layouts scroll intentionally.
        final fitAll = fittedWidth >= 145;
        final cardWidth = fitAll ? fittedWidth : 220.0;
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < showcaseChartTypes.length; index++) ...[
              if (index > 0) const SizedBox(width: gap),
              SizedBox(
                width: cardWidth,
                child: ChartTypeCatalogCard(
                  chartType: showcaseChartTypes[index],
                  compact: true,
                  onOpen: onOpenChartType == null
                      ? null
                      : () => onOpenChartType!(showcaseChartTypes[index].slug),
                ),
              ),
            ],
          ],
        );

        if (fitAll) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }
}

String _compactGuideName(ShowcaseChartType chartType) =>
    chartType.slug == 'concentric-donut' ? 'Concentric' : chartType.label;

List<ChartSeries> _previewSeries(ShowcaseChartType chartType) {
  const primary = [
    ChartDataPoint(x: 0, y: 18),
    ChartDataPoint(x: 1, y: 27),
    ChartDataPoint(x: 2, y: 24),
    ChartDataPoint(x: 3, y: 39),
    ChartDataPoint(x: 4, y: 43),
    ChartDataPoint(x: 5, y: 38),
    ChartDataPoint(x: 6, y: 55),
    ChartDataPoint(x: 7, y: 62),
  ];
  const secondary = [
    ChartDataPoint(x: 0, y: 36),
    ChartDataPoint(x: 1, y: 32),
    ChartDataPoint(x: 2, y: 43),
    ChartDataPoint(x: 3, y: 35),
    ChartDataPoint(x: 4, y: 49),
    ChartDataPoint(x: 5, y: 46),
    ChartDataPoint(x: 6, y: 58),
    ChartDataPoint(x: 7, y: 52),
  ];

  return switch (chartType.type) {
    ChartType.line => const [
      LineChartSeries(
        id: 'catalog-line-primary',
        points: primary,
        color: Color(0xFF2563EB),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.5,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 2.2,
      ),
      LineChartSeries(
        id: 'catalog-line-secondary',
        points: secondary,
        color: Color(0xFFF97316),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.8,
      ),
    ],
    ChartType.area => const [
      AreaChartSeries(
        id: 'catalog-area-primary',
        points: primary,
        color: Color(0xFF06B6D4),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2,
        fillOpacity: 0.28,
      ),
      AreaChartSeries(
        id: 'catalog-area-secondary',
        points: secondary,
        color: Color(0xFF8B5CF6),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.5,
        fillOpacity: 0.14,
      ),
    ],
    ChartType.bar => const [
      BarChartSeries(
        id: 'catalog-bar-primary',
        points: primary,
        color: Color(0xFF10B981),
        barWidthPercent: 0.72,
        barStyle: BarChartStyle(cornerRadius: 5),
      ),
      BarChartSeries(
        id: 'catalog-bar-secondary',
        points: secondary,
        color: Color(0xFF3B82F6),
        barWidthPercent: 0.72,
        barStyle: BarChartStyle(cornerRadius: 5),
        targetValues: [30, 34, 39, 45, 52, 49, 57, 61],
        targetMarkerStyle: BarTargetMarkerStyle(
          color: Color(0xFFF97316),
          width: 1.5,
          lengthFactor: 1.35,
        ),
        errorLowerValues: [15, 20, 25, 31, 36, 31, 48, 53],
        errorUpperValues: [23, 29, 34, 39, 46, 45, 58, 65],
        errorBarStyle: BarErrorBarStyle(
          color: Color(0xFF334155),
          width: 1,
          capLengthFactor: 0.55,
        ),
      ),
    ],
    ChartType.scatter => const [
      ScatterChartSeries(
        id: 'catalog-scatter-primary',
        points: primary,
        color: Color(0xFF8B5CF6),
        markerRadius: 5,
      ),
      ScatterChartSeries(
        id: 'catalog-scatter-secondary',
        points: secondary,
        color: Color(0xFFF97316),
        markerRadius: 4,
      ),
    ],
    ChartType.pie => [
      PieChartSeries.fromMap(
        id: 'catalog-pie',
        values: const {'Core': 42, 'Growth': 27, 'Income': 18, 'Other': 13},
        pieStyle: const PieChartStyle(
          radiusFactor: 0.94,
          sliceGap: 3,
          cornerRadius: 7,
          borderWidth: 1,
          borderColorMode: PieBorderColorMode.slice,
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.12,
        ),
      ),
    ],
    ChartType.donut when chartType.slug == 'concentric-donut' => [
      DonutChartSeries.fromMap(
        id: 'catalog-concentric-outer',
        values: const {'Product': 44, 'Services': 32, 'Other': 24},
        sliceColors: const {
          'Product': Color(0xFF7C3AED),
          'Services': Color(0xFF0EA5E9),
          'Other': Color(0xFFF59E0B),
        },
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          radiusFactor: 0.94,
          sliceGap: 2,
          cornerRadius: 4,
          selectionExplodeOffset: 0,
          selectedElevation: PieElevationStyle(),
          animationMode: PieAnimationMode.none,
        ),
      ),
      DonutChartSeries.fromMap(
        id: 'catalog-concentric-inner',
        values: const {'Product': 30, 'Services': 45, 'Other': 25},
        sliceColors: const {
          'Product': Color(0xFF7C3AED),
          'Services': Color(0xFF0EA5E9),
          'Other': Color(0xFFF59E0B),
        },
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          radiusFactor: 0.94,
          sliceGap: 2,
          cornerRadius: 4,
          selectionExplodeOffset: 0,
          selectedElevation: PieElevationStyle(),
          animationMode: PieAnimationMode.none,
        ),
      ),
    ],
    ChartType.donut => [
      DonutChartSeries.fromMap(
        id: 'catalog-donut',
        values: const {
          'Product': 38,
          'Services': 26,
          'Platform': 21,
          'Other': 15,
        },
        sliceColors: const {
          'Product': Color(0xFF0F766E),
          'Services': Color(0xFF14B8A6),
          'Platform': Color(0xFF5EEAD4),
          'Other': Color(0xFF99F6E4),
        },
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.58,
          radiusFactor: 0.94,
          sliceGap: 3,
          cornerRadius: 7,
          borderWidth: 1,
          borderColorMode: PieBorderColorMode.slice,
        ),
        centerContent: const DonutCenterContent(
          label: 'Total',
          valueMode: DonutCenterValueMode.total,
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.14,
        ),
      ),
    ],
  };
}
