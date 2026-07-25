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
    type: ChartType.area,
    label: 'Range Area',
    slug: 'range-area-charts',
    summary: 'Intervals and uncertainty',
    bestFor: 'Low–high envelopes, confidence bands, and bounded ranges',
    icon: Icons.water_outlined,
    accent: Color(0xFF0EA5E9),
    highlights: ['Paired low/high', 'Gradient bands', 'Line overlays'],
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
    type: ChartType.candlestick,
    label: 'Candlestick',
    slug: 'candlestick-charts',
    summary: 'Open-high-low-close movement',
    bestFor: 'Price action and interval-based financial observations',
    icon: Icons.candlestick_chart,
    accent: Color(0xFF0F766E),
    highlights: ['OHLC', 'Hollow + filled', 'Cartesian overlays'],
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
  ShowcaseChartType(
    type: ChartType.polarColumn,
    label: 'Polar Column',
    slug: 'polar-column',
    summary: 'Magnitude on polar axes',
    bestFor: 'Cyclical categories and compact magnitude profiles',
    icon: Icons.rotate_right_outlined,
    accent: Color(0xFF0369A1),
    highlights: ['Numeric radius', 'Rose preset', 'Partial sweeps'],
  ),
  ShowcaseChartType(
    type: ChartType.radialBar,
    label: 'Radial Bar',
    slug: 'radial-bar',
    summary: 'Independent progress tracks',
    bestFor: 'Comparing category values on one explicit numeric scale',
    icon: Icons.donut_small_outlined,
    accent: Color(0xFF4F46E5),
    highlights: ['Explicit domain', 'Signed baseline', 'Targets + selection'],
  ),
];

ShowcaseChartType showcaseChartTypeForSlug(String slug) =>
    showcaseChartTypes.firstWhere((entry) => entry.slug == slug);

/// Small native chart preview used wherever users choose a chart family.
class ChartTypePreview extends StatefulWidget {
  const ChartTypePreview({super.key, required this.chartType});

  final ShowcaseChartType chartType;

  @override
  State<ChartTypePreview> createState() => _ChartTypePreviewState();
}

class _ChartTypePreviewState extends State<ChartTypePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scatterEntranceController;
  late final Animation<double> _scatterEntrance;
  bool _scatterEntranceScheduled = false;

  @override
  void initState() {
    super.initState();
    _scatterEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      value: widget.chartType.type == ChartType.scatter ? 0 : 1,
    );
    _scatterEntrance = CurvedAnimation(
      parent: _scatterEntranceController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleScatterEntrance();
  }

  @override
  void didUpdateWidget(covariant ChartTypePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartType.type == widget.chartType.type) return;
    _scatterEntranceScheduled = false;
    _scatterEntranceController.value =
        widget.chartType.type == ChartType.scatter ? 0 : 1;
    _scheduleScatterEntrance();
  }

  void _scheduleScatterEntrance() {
    if (widget.chartType.type != ChartType.scatter) {
      _scatterEntranceController.value = 1;
      return;
    }
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _scatterEntranceScheduled = true;
      _scatterEntranceController.value = 1;
      return;
    }
    if (_scatterEntranceScheduled) return;
    _scatterEntranceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scatterEntranceController.forward();
    });
  }

  @override
  void dispose() {
    _scatterEntranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chartType.type == ChartType.scatter) {
      return AnimatedBuilder(
        animation: _scatterEntrance,
        builder: (context, _) => _buildPreview(
          context,
          scatterEntranceProgress: _scatterEntrance.value,
        ),
      );
    }
    return _buildPreview(context);
  }

  Widget _buildPreview(
    BuildContext context, {
    double scatterEntranceProgress = 1,
  }) {
    final chartType = widget.chartType;
    final isRadial =
        chartType.type == ChartType.pie ||
        chartType.type == ChartType.donut ||
        chartType.type == ChartType.polarColumn ||
        chartType.type == ChartType.radialBar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseTheme = isDark ? ChartTheme.dark : ChartTheme.light;
    final background = Color.alphaBlend(
      chartType.accent.withValues(alpha: isDark ? 0.08 : 0.045),
      baseTheme.backgroundColor,
    );

    final preview = BravenChartPlus(
      key: ValueKey('chart-type-preview-${chartType.cardKeySuffix}'),
      series: _previewSeries(
        chartType,
        scatterEntranceProgress: scatterEntranceProgress,
      ),
      concentricDonutConfig: chartType.slug == 'concentric-donut'
          ? const ConcentricDonutConfig(
              innerRadiusFactor: 0.45,
              outerRadiusFactor: 0.92,
              ringGap: 5,
              centerContent: DonutCenterContent(
                label: 'Rings',
                valueMode: DonutCenterValueMode.custom,
                customValue: '3',
              ),
            )
          : const ConcentricDonutConfig(),
      polarChartConfig: chartType.type == ChartType.polarColumn
          ? const PolarChartConfig(
              pane: PolarPaneConfig(outerRadiusFactor: 0.8),
              angularAxis: PolarCategoryAxisConfig(
                innerPadding: 0.16,
                showLabels: false,
                showGridLines: false,
              ),
              radialAxis: PolarNumericAxisConfig(
                showLabels: false,
                showGridLines: false,
              ),
            )
          : const PolarChartConfig(),
      radialBarChartConfig: chartType.type == ChartType.radialBar
          ? const RadialBarChartConfig(
              pane: PolarPaneConfig(
                innerRadiusFactor: 0.18,
                outerRadiusFactor: 0.84,
              ),
              trackGap: 3,
              showCategoryLabels: false,
              showScaleLabels: false,
              showGridLines: false,
            )
          : const RadialBarChartConfig(),
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
              scale: 1.12,
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

/// A compact family sampler with purposeful Cartesian and radial rows.
///
/// Each row scrolls independently only when its cards cannot retain a useful
/// preview width. Cartesian and radial-axis families stay in purposeful rows
/// so compact radial previews retain enough physical area to remain legible.
class ChartTypeCatalogStrip extends StatelessWidget {
  const ChartTypeCatalogStrip({super.key, this.onOpenChartType});

  final ValueChanged<String>? onOpenChartType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ChartTypeCatalogRow(
            chartTypes: showcaseChartTypes.take(6).toList(growable: false),
            onOpenChartType: onOpenChartType,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _ChartTypeCatalogRow(
            chartTypes: showcaseChartTypes.skip(6).toList(growable: false),
            onOpenChartType: onOpenChartType,
          ),
        ),
      ],
    );
  }
}

class _ChartTypeCatalogRow extends StatelessWidget {
  const _ChartTypeCatalogRow({
    required this.chartTypes,
    required this.onOpenChartType,
  });

  final List<ShowcaseChartType> chartTypes;
  final ValueChanged<String>? onOpenChartType;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final fittedWidth =
            (constraints.maxWidth - (gap * (chartTypes.length - 1))) /
            chartTypes.length;
        final fitAll = fittedWidth >= 200;
        final cardWidth = fitAll ? fittedWidth : 240.0;
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < chartTypes.length; index++) ...[
              if (index > 0) const SizedBox(width: gap),
              SizedBox(
                width: cardWidth,
                child: ChartTypeCatalogCard(
                  chartType: chartTypes[index],
                  compact: true,
                  onOpen: onOpenChartType == null
                      ? null
                      : () => onOpenChartType!(chartTypes[index].slug),
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

List<ChartSeries> _previewSeries(
  ShowcaseChartType chartType, {
  double scatterEntranceProgress = 1,
}) {
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

  if (chartType.slug == 'range-area-charts') {
    return [
      RangeAreaChartSeries(
        id: 'catalog-range-area-envelope',
        name: 'Low–high interval',
        points: [
          RangeAreaDataPoint(x: 0, low: 13, high: 28),
          RangeAreaDataPoint(x: 1, low: 16, high: 35),
          RangeAreaDataPoint(x: 2, low: 19, high: 33),
          RangeAreaDataPoint(x: 3, low: 22, high: 44),
          RangeAreaDataPoint(x: 4, low: 27, high: 49),
          RangeAreaDataPoint(x: 5, low: 25, high: 47),
          RangeAreaDataPoint(x: 6, low: 32, high: 58),
          RangeAreaDataPoint(x: 7, low: 36, high: 65),
        ],
        color: const Color(0xFF0EA5E9),
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.32,
        fillGradient: const AreaGradient(
          colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        upperBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF0284C7),
          strokeWidth: 1.8,
        ),
        lowerBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF38BDF8),
          strokeWidth: 1.4,
        ),
        pathAnimation: const PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            duration: Duration(milliseconds: 560),
          ),
        ),
      ),
      const LineChartSeries(
        id: 'catalog-range-area-observed',
        name: 'Observed',
        points: primary,
        color: Color(0xFF2563EB),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.2,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 2.1,
        pathAnimation: PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            delay: Duration(milliseconds: 90),
            duration: Duration(milliseconds: 500),
          ),
        ),
      ),
    ];
  }

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
        pathAnimation: PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            duration: Duration(milliseconds: 560),
          ),
        ),
      ),
      LineChartSeries(
        id: 'catalog-line-secondary',
        points: secondary,
        color: Color(0xFFF97316),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.8,
        pathAnimation: PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            delay: Duration(milliseconds: 90),
            duration: Duration(milliseconds: 500),
          ),
        ),
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
        pathAnimation: PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            duration: Duration(milliseconds: 560),
          ),
        ),
      ),
      AreaChartSeries(
        id: 'catalog-area-secondary',
        points: secondary,
        color: Color(0xFF8B5CF6),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.5,
        fillOpacity: 0.14,
        pathAnimation: PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            delay: Duration(milliseconds: 90),
            duration: Duration(milliseconds: 500),
          ),
        ),
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
    ChartType.scatter => [
      ScatterChartSeries(
        id: 'catalog-scatter-triathlon',
        name: 'Triathlon',
        points: const [
          ChartDataPoint(x: 0, y: 15),
          ChartDataPoint(x: 1, y: 19),
          ChartDataPoint(x: 2, y: 22),
          ChartDataPoint(x: 3, y: 27),
          ChartDataPoint(x: 4, y: 29),
          ChartDataPoint(x: 5, y: 35),
          ChartDataPoint(x: 6, y: 38),
          ChartDataPoint(x: 7, y: 43),
          ChartDataPoint(x: 8, y: 46),
        ],
        color: const Color(0xFF38BDF8),
        markerRadius:
            4.4 *
            _scatterSeriesProgress(
              scatterEntranceProgress,
              start: 0,
              end: 0.78,
            ),
        markerShape: SeriesMarkerShape.triangle,
        markerStyle: ScatterMarkerStyle(
          opacity: _scatterSeriesProgress(
            scatterEntranceProgress,
            start: 0,
            end: 0.78,
          ),
        ),
      ),
      ScatterChartSeries(
        id: 'catalog-scatter-volleyball',
        name: 'Volleyball',
        points: const [
          ChartDataPoint(x: 2, y: 25),
          ChartDataPoint(x: 3, y: 30),
          ChartDataPoint(x: 4, y: 33),
          ChartDataPoint(x: 5, y: 39),
          ChartDataPoint(x: 6, y: 42),
          ChartDataPoint(x: 7, y: 47),
          ChartDataPoint(x: 8, y: 49),
          ChartDataPoint(x: 9, y: 55),
          ChartDataPoint(x: 10, y: 58),
          ChartDataPoint(x: 11, y: 61),
        ],
        color: const Color(0xFF7C3AED),
        markerRadius:
            4.2 *
            _scatterSeriesProgress(
              scatterEntranceProgress,
              start: 0.10,
              end: 0.90,
            ),
        markerShape: SeriesMarkerShape.square,
        markerStyle: ScatterMarkerStyle(
          opacity: _scatterSeriesProgress(
            scatterEntranceProgress,
            start: 0.10,
            end: 0.90,
          ),
        ),
      ),
      ScatterChartSeries(
        id: 'catalog-scatter-basketball',
        name: 'Basketball',
        points: const [
          ChartDataPoint(x: 4, y: 35),
          ChartDataPoint(x: 5, y: 40),
          ChartDataPoint(x: 6, y: 44),
          ChartDataPoint(x: 7, y: 49),
          ChartDataPoint(x: 8, y: 52),
          ChartDataPoint(x: 9, y: 57),
          ChartDataPoint(x: 10, y: 60),
          ChartDataPoint(x: 11, y: 65),
          ChartDataPoint(x: 12, y: 68),
          ChartDataPoint(x: 13, y: 73),
        ],
        color: const Color(0xFF10B981),
        markerRadius:
            4.5 *
            _scatterSeriesProgress(
              scatterEntranceProgress,
              start: 0.22,
              end: 1,
            ),
        markerStyle: ScatterMarkerStyle(
          opacity: _scatterSeriesProgress(
            scatterEntranceProgress,
            start: 0.22,
            end: 1,
          ),
        ),
      ),
    ],
    ChartType.candlestick => [
      CandlestickChartSeries(
        id: 'catalog-candlestick',
        points: [
          CandlestickDataPoint(x: 0, open: 99, high: 104, low: 97, close: 102),
          CandlestickDataPoint(
            x: 1,
            open: 102,
            high: 108,
            low: 100,
            close: 106,
          ),
          CandlestickDataPoint(
            x: 2,
            open: 106,
            high: 107,
            low: 101,
            close: 104,
          ),
          CandlestickDataPoint(
            x: 3,
            open: 104,
            high: 112,
            low: 103,
            close: 110,
          ),
          CandlestickDataPoint(
            x: 4,
            open: 110,
            high: 116,
            low: 109,
            close: 114,
          ),
          CandlestickDataPoint(
            x: 5,
            open: 114,
            high: 117,
            low: 110,
            close: 112,
          ),
          CandlestickDataPoint(
            x: 6,
            open: 112,
            high: 113,
            low: 106,
            close: 108,
          ),
          CandlestickDataPoint(
            x: 7,
            open: 108,
            high: 109,
            low: 102,
            close: 105,
          ),
          CandlestickDataPoint(
            x: 8,
            open: 105,
            high: 111,
            low: 104,
            close: 109,
          ),
          CandlestickDataPoint(
            x: 9,
            open: 109,
            high: 118,
            low: 108,
            close: 116,
          ),
          CandlestickDataPoint(
            x: 10,
            open: 116,
            high: 123,
            low: 115,
            close: 121,
          ),
          CandlestickDataPoint(
            x: 11,
            open: 121,
            high: 123,
            low: 116,
            close: 118,
          ),
          CandlestickDataPoint(
            x: 12,
            open: 118,
            high: 126,
            low: 117,
            close: 124,
          ),
          CandlestickDataPoint(
            x: 13,
            open: 124,
            high: 126,
            low: 120,
            close: 122,
          ),
          CandlestickDataPoint(
            x: 14,
            open: 122,
            high: 129,
            low: 121,
            close: 127,
          ),
          CandlestickDataPoint(
            x: 15,
            open: 127,
            high: 130,
            low: 123,
            close: 125,
          ),
        ],
        candlestickStyle: const CandlestickChartStyle(
          maxBodyWidth: 8,
          bodyWidthFactor: 0.64,
          bodyCornerRadius: 1,
        ),
        animation: const CandlestickAnimationStyle(staggerFraction: 0.82),
      ),
      const LineChartSeries(
        id: 'catalog-candlestick-average',
        points: [
          ChartDataPoint(x: 4, y: 107.2),
          ChartDataPoint(x: 5, y: 109.2),
          ChartDataPoint(x: 6, y: 109.6),
          ChartDataPoint(x: 7, y: 109.8),
          ChartDataPoint(x: 8, y: 109.6),
          ChartDataPoint(x: 9, y: 110),
          ChartDataPoint(x: 10, y: 111.8),
          ChartDataPoint(x: 11, y: 113.8),
          ChartDataPoint(x: 12, y: 117.6),
          ChartDataPoint(x: 13, y: 120.2),
          ChartDataPoint(x: 14, y: 122.4),
          ChartDataPoint(x: 15, y: 123.2),
        ],
        color: Color(0xFF6366F1),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.5,
        pathAnimation: PathAnimationStyle(
          entranceMode: PathEntranceAnimationMode.reveal,
          entranceTiming: PathAnimationTiming(
            delay: Duration(milliseconds: 80),
            duration: Duration(milliseconds: 520),
          ),
        ),
      ),
    ],
    ChartType.pie => [
      PieChartSeries.fromMap(
        id: 'catalog-pie',
        values: const {
          'Core': 42,
          'Growth': 27,
          'Income': 18,
          'Other': 13,
          'Extra': 8,
        },
        pieStyle: const PieChartStyle(
          radiusFactor: 1.0,
          sliceGap: 3,
          cornerRadius: 1,
          borderWidth: 1,
          borderColorMode: PieBorderColorMode.slice,
          gradient: PieGradientStyle(type: PieGradientType.radial),
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.12,
          calloutStyle: LabelStyle(
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 1,
            borderRadius: 4,
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            textStyle: TextStyle(fontSize: 9),
          ),
        ),
      ),
    ],
    ChartType.donut when chartType.slug == 'concentric-donut' => [
      DonutChartSeries.fromMap(
        id: 'catalog-concentric-outer',
        values: const {'Product': 44, 'Services': 32, 'Other': 24, 'Extra': 12},
        sliceColors: const {
          'Product': Color(0xFF7C3AED),
          'Services': Color(0xFF0EA5E9),
          'Other': Color(0xFFF59E0B),
          'Extra': Color(0xFF22C55E),
        },
        dataLabels: const PieDataLabelConfig(isVisible: true),
        donutStyle: const DonutChartStyle(
          radiusFactor: 1.0,
          sliceGap: 0,
          cornerRadius: 0,
          borderWidth: 0.2,
          selectionExplodeOffset: 0,
          selectedElevation: PieElevationStyle(),
          animationMode: PieAnimationMode.sweep,
        ),
      ),
      DonutChartSeries.fromMap(
        id: 'catalog-concentric-middle',
        values: const {'Product': 30, 'Services': 45, 'Other': 25},
        sliceColors: const {
          'Product': Color(0xFF7C3AED),
          'Services': Color(0xFF0EA5E9),
          'Other': Color(0xFFF59E0B),
        },
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          radiusFactor: 1.0,
          sliceGap: 0,
          cornerRadius: 0,
          borderWidth: 0.2,
          selectionExplodeOffset: 0,
          selectedElevation: PieElevationStyle(),
          animationMode: PieAnimationMode.sweep,
        ),
      ),
      DonutChartSeries.fromMap(
        id: 'catalog-concentric-inner',
        values: const {'Product': 52, 'Services': 28, 'Other': 20, 'Extra': 10},
        sliceColors: const {
          'Product': Color(0xFF7C3AED),
          'Services': Color(0xFF0EA5E9),
          'Other': Color(0xFFF59E0B),
          'Extra': Color(0xFF22C55E),
        },
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: const DonutChartStyle(
          radiusFactor: 1.0,
          sliceGap: 0,
          cornerRadius: 0,
          borderWidth: 0.2,
          selectionExplodeOffset: 0,
          selectedElevation: PieElevationStyle(),
          animationMode: PieAnimationMode.sweep,
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
          'Extra': 10,
        },
        sliceColors: const {
          'Product': Color(0xFF0F766E),
          'Services': Color(0xFF14B8A6),
          'Platform': Color(0xFF5EEAD4),
          'Other': Color(0xFF99F6E4),
          'Extra': Color(0xFF22C55E),
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
    ChartType.polarColumn => [
      PolarColumnChartSeries.rose(
        id: 'catalog-polar-column',
        values: const {
          'North': 52,
          'North-east': 76,
          'East': 64,
          'South-east': 88,
          'South': 46,
          'South-west': 70,
          'West': 58,
          'North-west': 82,
        },
        columnColors: const {
          'North': Color(0xFF0EA5E9),
          'North-east': Color(0xFF0891B2),
          'East': Color(0xFF0D9488),
          'South-east': Color(0xFF16A34A),
          'South': Color(0xFFF59E0B),
          'South-west': Color(0xFFF97316),
          'West': Color(0xFFE11D48),
          'North-west': Color(0xFF7C3AED),
        },
        polarStyle: const PolarColumnStyle(
          cornerRadius: 3,
          borderWidth: 0.5,
          showDataLabels: false,
          animationMode: PolarColumnAnimationMode.sweep,
        ),
      ),
    ],
    ChartType.radialBar => [
      RadialBarChartSeries.fromMap(
        id: 'catalog-radial-bar',
        values: const {
          'Activation': 88,
          'Retention': 72,
          'Adoption': 61,
          'Expansion': 79,
        },
        barColors: const {
          'Activation': Color(0xFF2563EB),
          'Retention': Color(0xFF0891B2),
          'Adoption': Color(0xFF0D9488),
          'Expansion': Color(0xFF7C3AED),
        },
        radialBarStyle: const RadialBarStyle(
          cornerRadius: 5,
          trackOpacity: 0.1,
          showDataLabels: false,
        ),
      ),
    ],
  };
}

double _scatterSeriesProgress(
  double progress, {
  required double start,
  required double end,
}) {
  if (progress <= start) return 0;
  if (progress >= end) return 1;
  return (progress - start) / (end - start);
}
