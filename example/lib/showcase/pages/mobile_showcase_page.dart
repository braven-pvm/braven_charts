// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/braven_brand.dart';
import '../widgets/chart_type_catalog.dart';

/// A phone-first introduction to every Braven Charts family.
///
/// The desktop showcase is intentionally dense and exploratory. This surface
/// instead mounts one focused chart at a time, uses touch-sized family
/// selectors, and keeps each example close to a typical mobile product use
/// case.
class MobileShowcasePage extends StatefulWidget {
  const MobileShowcasePage({
    super.key,
    this.initialChartSlug,
    this.onChartTypeSelected,
  });

  final String? initialChartSlug;
  final ValueChanged<String>? onChartTypeSelected;

  @override
  State<MobileShowcasePage> createState() => _MobileShowcasePageState();
}

class _MobileShowcasePageState extends State<MobileShowcasePage> {
  final ScrollController _chartTypeScrollController = ScrollController();
  late int _selectedIndex;
  _MobileVisualStyle _visualStyle = _MobileVisualStyle.vivid;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForSlug(widget.initialChartSlug);
    _scheduleSelectedChartTypeVisibility(animate: false);
  }

  @override
  void didUpdateWidget(covariant MobileShowcasePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialChartSlug == widget.initialChartSlug) return;
    final nextIndex = _indexForSlug(widget.initialChartSlug);
    if (nextIndex != _selectedIndex) {
      _selectedIndex = nextIndex;
      _scheduleSelectedChartTypeVisibility(animate: true);
    }
  }

  int _indexForSlug(String? slug) {
    final index = showcaseChartTypes.indexWhere((entry) => entry.slug == slug);
    return index < 0 ? 0 : index;
  }

  void _selectChartType(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _scheduleSelectedChartTypeVisibility(animate: true);
    widget.onChartTypeSelected?.call(showcaseChartTypes[index].slug);
  }

  void _selectVisualStyle(_MobileVisualStyle style) {
    if (style == _visualStyle) return;
    setState(() => _visualStyle = style);
  }

  void _scheduleSelectedChartTypeVisibility({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chartTypeScrollController.hasClients) return;
      final position = _chartTypeScrollController.position;
      final target = (_selectedIndex * 144.0).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (animate) {
        _chartTypeScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _chartTypeScrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _chartTypeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartType = showcaseChartTypes[_selectedIndex];
    final scheme = Theme.of(context).colorScheme;
    final examples = _mobileExamples(chartType.slug, _visualStyle);

    return Scaffold(
      key: const ValueKey('mobile-showcase'),
      appBar: AppBar(
        title: const BravenBrand(markSize: 34),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charts for Flutter',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a chart type, pick a look, then scroll through purpose-built mobile examples.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Chart types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                key: const ValueKey('mobile-chart-type-strip'),
                height: 76,
                child: ListView.separated(
                  controller: _chartTypeScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: showcaseChartTypes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final entry = showcaseChartTypes[index];
                    return _MobileChartTypeButton(
                      key: ValueKey('mobile-chart-type-${entry.slug}'),
                      chartType: entry,
                      selected: index == _selectedIndex,
                      onPressed: () => _selectChartType(index),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MobileStyleSelector(
                      selected: _visualStyle,
                      onSelected: _selectVisualStyle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chartType.label,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Three focused examples. Tap any mark for details.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${examples.length} examples',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList.separated(
                key: ValueKey('mobile-chart-list-${chartType.slug}'),
                itemCount: examples.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _MobileChartEntrance(
                  key: ValueKey(
                    'mobile-chart-entrance-${chartType.slug}-${_visualStyle.name}-$index',
                  ),
                  delay: Duration(milliseconds: index * 70),
                  child: _MobileChartCard(
                    key: ValueKey('mobile-chart-card-${chartType.slug}-$index'),
                    chartType: chartType,
                    example: examples[index],
                    visualStyle: _visualStyle,
                    index: index,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileChartTypeButton extends StatelessWidget {
  const _MobileChartTypeButton({
    super.key,
    required this.chartType,
    required this.selected,
    required this.onPressed,
  });

  final ShowcaseChartType chartType;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? chartType.accent.withValues(alpha: 0.12)
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? chartType.accent : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 136,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    _mobileChartIcon(chartType),
                    size: 20,
                    color: chartType.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chartType.slug == 'concentric-donut'
                          ? 'Concentric'
                          : chartType.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? chartType.accent : scheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MobileVisualStyle { vivid, midnight, calm }

extension on _MobileVisualStyle {
  String get label => switch (this) {
    _MobileVisualStyle.vivid => 'Vivid',
    _MobileVisualStyle.midnight => 'Midnight',
    _MobileVisualStyle.calm => 'Calm',
  };
}

class _MobileStyleSelector extends StatelessWidget {
  const _MobileStyleSelector({
    required this.selected,
    required this.onSelected,
  });

  final _MobileVisualStyle selected;
  final ValueChanged<_MobileVisualStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('mobile-style-selector'),
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            for (final (index, style) in _MobileVisualStyle.values.indexed) ...[
              if (index > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant,
                ),
              Expanded(
                child: Semantics(
                  selected: selected == style,
                  button: true,
                  child: Material(
                    color: selected == style
                        ? scheme.secondaryContainer
                        : Colors.transparent,
                    child: InkWell(
                      key: ValueKey('mobile-style-${style.name}'),
                      onTap: () => onSelected(style),
                      child: Center(
                        child: Text(
                          style.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected == style
                                    ? scheme.onSecondaryContainer
                                    : scheme.onSurfaceVariant,
                                fontWeight: selected == style
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileChartEntrance extends StatelessWidget {
  const _MobileChartEntrance({
    super.key,
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 480 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 14),
          child: child,
        ),
      ),
    );
  }
}

class _MobileChartExample {
  const _MobileChartExample({
    required this.title,
    required this.description,
    required this.series,
    this.annotations = const [],
    this.showLegend = false,
    this.grid,
    this.xAxisConfig,
    this.yAxis,
    this.concentricDonutConfig,
    this.polarChartConfig,
    this.chartHeight,
  });

  final String title;
  final String description;
  final List<ChartSeries> series;
  final List<ChartAnnotation> annotations;
  final bool showLegend;
  final GridConfig? grid;
  final XAxisConfig? xAxisConfig;
  final YAxisConfig? yAxis;
  final ConcentricDonutConfig? concentricDonutConfig;
  final PolarChartConfig? polarChartConfig;
  final double? chartHeight;
}

class _MobileStylePresentation {
  const _MobileStylePresentation({
    required this.chartTheme,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.border,
    required this.palette,
  });

  final ChartTheme chartTheme;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color border;
  final List<Color> palette;

  static _MobileStylePresentation resolve(_MobileVisualStyle style) =>
      switch (style) {
        _MobileVisualStyle.vivid => _MobileStylePresentation(
          chartTheme: ChartTheme.vibrant.copyWith(
            backgroundColor: const Color(0xFFFFFFFF),
          ),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF172033),
          onSurfaceVariant: const Color(0xFF5E687B),
          border: const Color(0xFFD7DCE8),
          palette: const [
            Color(0xFF4F46E5),
            Color(0xFF06B6D4),
            Color(0xFFF97316),
            Color(0xFF8B5CF6),
            Color(0xFF10B981),
          ],
        ),
        _MobileVisualStyle.midnight => _MobileStylePresentation(
          chartTheme: ChartTheme.dark.copyWith(
            backgroundColor: const Color(0xFF0F172A),
          ),
          surface: const Color(0xFF0F172A),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFFB7C3D4),
          border: const Color(0xFF334155),
          palette: const [
            Color(0xFF22D3EE),
            Color(0xFFA78BFA),
            Color(0xFFFBBF24),
            Color(0xFFFB7185),
            Color(0xFF34D399),
          ],
        ),
        _MobileVisualStyle.calm => _MobileStylePresentation(
          chartTheme: ChartTheme.minimal.copyWith(
            backgroundColor: const Color(0xFFFFFDF8),
          ),
          surface: const Color(0xFFFFFDF8),
          onSurface: const Color(0xFF24352F),
          onSurfaceVariant: const Color(0xFF65736D),
          border: const Color(0xFFDCE5DF),
          palette: const [
            Color(0xFF2A9D8F),
            Color(0xFF6574CD),
            Color(0xFFE76F51),
            Color(0xFFE9C46A),
            Color(0xFF4F9DA6),
          ],
        ),
      };
}

class _MobileChartCard extends StatelessWidget {
  const _MobileChartCard({
    super.key,
    required this.chartType,
    required this.example,
    required this.visualStyle,
    required this.index,
  });

  final ShowcaseChartType chartType;
  final _MobileChartExample example;
  final _MobileVisualStyle visualStyle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final presentation = _MobileStylePresentation.resolve(visualStyle);
    final theme = Theme.of(context);
    final isRadial =
        chartType.type == ChartType.pie ||
        chartType.type == ChartType.donut ||
        chartType.type == ChartType.polarColumn;

    return Material(
      color: presentation.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: presentation.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: presentation.palette[index % 5].withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _mobileChartIcon(chartType),
                      size: 20,
                      color: presentation.palette[index % 5],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: presentation.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        example.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: presentation.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              key: ValueKey('mobile-chart-${chartType.slug}-$index'),
              height: example.chartHeight ?? (isRadial ? 286 : 270),
              child: BravenChartPlus(
                series: example.series,
                annotations: example.annotations,
                theme: presentation.chartTheme,
                showLegend: example.showLegend,
                legendStyle: example.showLegend
                    ? const LegendStyle(
                        position: LegendPosition.topRight,
                        orientation: LegendOrientation.horizontal,
                        allowDragging: false,
                      )
                    : null,
                grid:
                    example.grid ??
                    (isRadial
                        ? const GridConfig(horizontal: false, vertical: false)
                        : GridConfig(
                            horizontal: true,
                            vertical: false,
                            horizontalColor: presentation.border.withValues(
                              alpha: 0.6,
                            ),
                          )),
                xAxisConfig:
                    example.xAxisConfig ??
                    (isRadial
                        ? const XAxisConfig(visible: false)
                        : const XAxisConfig(
                            tickCount: 5,
                            showMinorTicks: false,
                          )),
                yAxis:
                    example.yAxis ??
                    (isRadial
                        ? YAxisConfig(position: YAxisPosition.hidden)
                        : YAxisConfig(
                            position: YAxisPosition.left,
                            tickCount: 5,
                            maxWidth: 48,
                            showMinorTicks: false,
                          )),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(enabled: false),
                  tooltip: TooltipConfig(
                    enabled: true,
                    triggerMode: TooltipTriggerMode.tap,
                  ),
                  keyboard: KeyboardConfig(enabled: false),
                  enableZoom: false,
                  enablePan: false,
                  enableSelection: true,
                  enableFocusOnHover: false,
                ),
                concentricDonutConfig:
                    example.concentricDonutConfig ??
                    (chartType.slug == 'concentric-donut'
                        ? ConcentricDonutConfig(
                            innerRadiusFactor: 0.34,
                            ringGap: 5,
                            centerContent: DonutCenterContent(
                              label: index == 0 ? 'Weeks' : 'Rings',
                              valueMode: DonutCenterValueMode.custom,
                              customValue: index == 0 ? '2' : '${index + 1}',
                            ),
                          )
                        : const ConcentricDonutConfig()),
                polarChartConfig:
                    example.polarChartConfig ??
                    (chartType.type == ChartType.polarColumn
                        ? const PolarChartConfig(
                            pane: PolarPaneConfig(outerRadiusFactor: 0.78),
                            angularAxis: PolarCategoryAxisConfig(
                              innerPadding: 0.14,
                              showLabels: true,
                              showGridLines: false,
                            ),
                            radialAxis: PolarNumericAxisConfig(
                              showLabels: false,
                              showGridLines: true,
                            ),
                          )
                        : const PolarChartConfig()),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 17,
                  color: presentation.palette[index % 5],
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Tap a mark for details',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: presentation.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: presentation.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  'Animated',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: presentation.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _mobileChartIcon(ShowcaseChartType chartType) =>
    chartType.slug == 'polar-column' ? Icons.explore_outlined : chartType.icon;

const _mobileExampleCopy = <String, List<(String, String)>>{
  'line-charts': [
    ('Weekly activity', 'One clear trend with friendly tap targets.'),
    ('Plan comparison', 'Current, previous, and target share one scale.'),
    ('Forecast', 'Observed values become a dotted future after now.'),
  ],
  'area-charts': [
    ('Screen time', 'Daily magnitude with a restrained fill and one scale.'),
    ('Target delta', 'Positive and negative deviation use distinct fills.'),
    ('Demand composition', 'Two filled layers and a plan line stay readable.'),
  ],
  'range-area-charts': [
    ('Temperature range', 'One low-high band for a compact forecast.'),
    ('Seasonal range', 'A changing weekly envelope preserves both bounds.'),
    ('Forecast fan', 'Nested 50% and 95% intervals frame one centre line.'),
  ],
  'bar-charts': [
    ('Daily steps', 'A familiar category comparison for a weekly goal.'),
    ('Medal comparison', 'Overlaid reference and current bars save space.'),
    ('Product survey', 'Responses diverge around a neutral centre.'),
  ],
  'scatter-charts': [
    ('Walk pace', 'Individual observations without a connecting line.'),
    ('Market opportunity', 'Position, bubble area, and shape carry meaning.'),
    ('Generated cohorts', 'Three small populations reveal one relationship.'),
  ],
  'candlestick-charts': [
    ('Price movement', 'A concise open, high, low, and close history.'),
    ('Price and average', 'Candles share the pane with a moving average.'),
    ('Volatility study', 'A range envelope, candles, and trend work together.'),
  ],
  'pie-charts': [
    ('Monthly spending', 'Four categories contributing to a single total.'),
    (
      'Revenue contribution',
      'Outside labels and connectors suit small slices.',
    ),
    ('Campaign reach', 'A second metric controls each slice radius.'),
  ],
  'donut-charts': [
    ('Storage used', 'Part-to-whole values with useful center context.'),
    ('Delivery mix', 'A partial sweep creates a compact progress display.'),
    ('Channel reach', 'Angle shows share while radius shows reach.'),
  ],
  'concentric-donut': [
    ('Week comparison', 'Two independent periods in one compact radial view.'),
    ('Revenue by period', 'Three rings keep their own totals and categories.'),
    ('Service portfolio', 'Partial multi-ring arcs create a dashboard moment.'),
  ],
  'polar-column': [
    ('Activity rhythm', 'A cyclical view of activity across the week.'),
    ('Demand vs capacity', 'Two radial layers compare observed and available.'),
    ('Regional mix', 'Grouped radial columns compare three compact series.'),
  ],
};

List<_MobileChartExample> _mobileExamples(
  String slug,
  _MobileVisualStyle visualStyle,
) {
  final presentation = _MobileStylePresentation.resolve(visualStyle);
  final copy = _mobileExampleCopy[slug] ?? const [('Chart', 'Simple example')];
  return [
    for (var index = 0; index < copy.length; index++)
      _MobileChartExample(
        title: copy[index].$1,
        description: copy[index].$2,
        series: index == 0
            ? _mobileSeries(slug, presentation)
            : _mobileVariantSeries(slug, index, presentation),
        annotations: slug == 'line-charts' && index == 2
            ? [
                ThresholdAnnotation(
                  id: 'mobile-forecast-now',
                  axis: AnnotationAxis.x,
                  value: 4,
                  label: 'Now',
                  dashPattern: [5, 4],
                  allowDragging: false,
                  allowEditing: false,
                ),
              ]
            : const [],
        showLegend:
            (slug == 'line-charts' && index == 1) ||
            (slug == 'area-charts' && index == 2) ||
            (slug == 'range-area-charts' && index == 2) ||
            (slug == 'bar-charts' && index > 0) ||
            (slug == 'scatter-charts' && index > 0) ||
            (slug == 'candlestick-charts' && index > 0) ||
            (slug == 'polar-column' && index > 0),
        xAxisConfig: _mobileXAxis(slug, index),
        yAxis: _mobileYAxis(slug, index),
        concentricDonutConfig: slug == 'concentric-donut'
            ? _mobileConcentricConfig(index)
            : null,
        polarChartConfig: slug == 'polar-column'
            ? _mobilePolarConfig(index)
            : null,
        grid: slug == 'bar-charts' && index == 2
            ? const GridConfig(horizontal: false, vertical: true)
            : null,
        chartHeight: switch ((slug, index)) {
          ('bar-charts', 2) => 300,
          ('pie-charts', 1) => 330,
          ('polar-column', _) => 310,
          _ => null,
        },
      ),
  ];
}

XAxisConfig? _mobileXAxis(String slug, int index) => switch (slug) {
  'line-charts' when index == 2 => const XAxisConfig(
    label: 'Hour',
    tickCount: 5,
    showMinorTicks: false,
  ),
  'range-area-charts' when index == 2 => const XAxisConfig(
    label: 'Horizon',
    tickCount: 4,
    showMinorTicks: false,
  ),
  'scatter-charts' when index == 1 => const XAxisConfig(
    label: 'Growth %',
    tickCount: 4,
    showMinorTicks: false,
  ),
  'bar-charts' when index == 1 => XAxisConfig(
    label: 'Country',
    min: -0.6,
    max: 4.6,
    renderMin: 0,
    renderMax: 4,
    tickCount: 5,
    labelFormatter: (value) =>
        _mobileCategoryLabel(value, const ['CN', 'US', 'JP', 'AU', 'FR']),
  ),
  'bar-charts' when index == 2 => XAxisConfig(
    label: 'Statement',
    min: -1,
    max: 3,
    renderMin: 0,
    renderMax: 2,
    tickCount: 3,
    maxHeight: 88,
    labelFormatter: (value) =>
        _mobileCategoryLabel(value, const ['Easy', 'Fast', 'Recommend']),
  ),
  _ => null,
};

String _mobileCategoryLabel(double value, List<String> labels) {
  final index = value.round();
  if ((value - index).abs() > 0.05) return '';
  return index >= 0 && index < labels.length ? labels[index] : '';
}

YAxisConfig? _mobileYAxis(String slug, int index) => switch (slug) {
  'line-charts' when index == 2 => YAxisConfig(
    position: YAxisPosition.left,
    label: '°C',
    tickCount: 4,
    maxWidth: 48,
  ),
  'scatter-charts' when index == 1 => YAxisConfig(
    position: YAxisPosition.left,
    label: 'Retention %',
    min: 68,
    max: 100,
    tickCount: 4,
    maxWidth: 48,
  ),
  _ => null,
};

ConcentricDonutConfig _mobileConcentricConfig(int index) =>
    ConcentricDonutConfig(
      innerRadiusFactor: index == 0 ? 0.34 : 0.28,
      ringGap: 5,
      centerContent: DonutCenterContent(
        label: index == 0
            ? 'Weeks'
            : index == 1
            ? 'Current'
            : 'Services',
        valueMode: DonutCenterValueMode.custom,
        customValue: index == 0
            ? '2'
            : index == 1
            ? '100'
            : '3 rings',
      ),
    );

PolarChartConfig _mobilePolarConfig(int index) => PolarChartConfig(
  pane: const PolarPaneConfig(outerRadiusFactor: 0.9),
  angularAxis: const PolarCategoryAxisConfig(
    innerPadding: 0.14,
    showLabels: true,
    showGridLines: false,
  ),
  radialAxis: const PolarNumericAxisConfig(
    showLabels: false,
    showGridLines: true,
  ),
  composition: PolarColumnCompositionConfig(
    mode: index == 2
        ? PolarColumnCompositionMode.grouped
        : PolarColumnCompositionMode.layered,
  ),
);

const _pathEntrance = PathAnimationStyle(
  entranceMode: PathEntranceAnimationMode.reveal,
  dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
  entranceTiming: PathAnimationTiming(duration: Duration(milliseconds: 720)),
  dataUpdateTiming: PathAnimationTiming(duration: Duration(milliseconds: 420)),
);

List<ChartSeries> _mobileSeries(
  String slug,
  _MobileStylePresentation presentation,
) => switch (slug) {
  'line-charts' => [
    LineChartSeries(
      id: 'mobile-line',
      name: 'Active minutes',
      unit: 'min',
      color: presentation.palette[0],
      interpolation: LineInterpolation.monotone,
      strokeWidth: 3,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 4,
      pathAnimation: _pathEntrance,
      points: const [
        ChartDataPoint(x: 1, y: 28),
        ChartDataPoint(x: 2, y: 36),
        ChartDataPoint(x: 3, y: 32),
        ChartDataPoint(x: 4, y: 45),
        ChartDataPoint(x: 5, y: 51),
        ChartDataPoint(x: 6, y: 47),
        ChartDataPoint(x: 7, y: 60),
      ],
    ),
  ],
  'area-charts' => [
    AreaChartSeries(
      id: 'mobile-area',
      name: 'Screen time',
      unit: 'min',
      color: presentation.palette[1],
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.5,
      fillOpacity: 0.26,
      pathAnimation: _pathEntrance,
      points: const [
        ChartDataPoint(x: 1, y: 42),
        ChartDataPoint(x: 2, y: 55),
        ChartDataPoint(x: 3, y: 48),
        ChartDataPoint(x: 4, y: 66),
        ChartDataPoint(x: 5, y: 58),
        ChartDataPoint(x: 6, y: 72),
        ChartDataPoint(x: 7, y: 63),
      ],
    ),
  ],
  'range-area-charts' => [
    RangeAreaChartSeries(
      id: 'mobile-range-area',
      name: 'Forecast',
      unit: '°C',
      color: presentation.palette[0],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.3,
      pathAnimation: _pathEntrance,
      points: [
        RangeAreaDataPoint(x: 1, low: 13, high: 22),
        RangeAreaDataPoint(x: 2, low: 15, high: 25),
        RangeAreaDataPoint(x: 3, low: 12, high: 20),
        RangeAreaDataPoint(x: 4, low: 14, high: 24),
        RangeAreaDataPoint(x: 5, low: 16, high: 27),
        RangeAreaDataPoint(x: 6, low: 17, high: 29),
        RangeAreaDataPoint(x: 7, low: 15, high: 26),
      ],
    ),
  ],
  'bar-charts' => [
    BarChartSeries(
      id: 'mobile-bar',
      name: 'Steps',
      color: presentation.palette[4],
      barWidthPercent: 0.68,
      barStyle: const BarChartStyle(
        cornerRadius: 6,
        motion: BarMotionStyle(
          order: BarAnimationOrder.forward,
          staggerFraction: 0.52,
        ),
      ),
      points: const [
        ChartDataPoint(x: 1, y: 6200),
        ChartDataPoint(x: 2, y: 8100),
        ChartDataPoint(x: 3, y: 7400),
        ChartDataPoint(x: 4, y: 9800),
        ChartDataPoint(x: 5, y: 10500),
        ChartDataPoint(x: 6, y: 8900),
        ChartDataPoint(x: 7, y: 11200),
      ],
    ),
  ],
  'scatter-charts' => [
    ScatterChartSeries(
      id: 'mobile-scatter',
      name: 'Walks',
      unit: 'min/km',
      color: presentation.palette[3],
      markerRadius: 6,
      points: const [
        ChartDataPoint(x: 2.1, y: 8.4),
        ChartDataPoint(x: 2.8, y: 7.9),
        ChartDataPoint(x: 3.4, y: 8.1),
        ChartDataPoint(x: 4.2, y: 7.4),
        ChartDataPoint(x: 5.1, y: 7.2),
        ChartDataPoint(x: 5.8, y: 6.9),
        ChartDataPoint(x: 6.4, y: 7.1),
      ],
    ),
  ],
  'candlestick-charts' => [
    CandlestickChartSeries(
      id: 'mobile-candlestick',
      name: 'Price',
      candlestickStyle: CandlestickChartStyle(
        risingBodyFillColor: presentation.palette[4],
        risingBorderColor: presentation.palette[4],
        risingWickColor: presentation.palette[4],
        fallingBodyFillColor: presentation.palette[3],
        fallingBorderColor: presentation.palette[3],
        fallingWickColor: presentation.palette[3],
        bodyFillMode: CandlestickBodyFillMode.filled,
        bodyCornerRadius: 2,
      ),
      animation: const CandlestickAnimationStyle(staggerFraction: 0.7),
      points: [
        CandlestickDataPoint(x: 1, open: 44, high: 49, low: 42, close: 47),
        CandlestickDataPoint(x: 2, open: 47, high: 51, low: 45, close: 49),
        CandlestickDataPoint(x: 3, open: 49, high: 50, low: 43, close: 45),
        CandlestickDataPoint(x: 4, open: 45, high: 52, low: 44, close: 50),
        CandlestickDataPoint(x: 5, open: 50, high: 55, low: 48, close: 53),
        CandlestickDataPoint(x: 6, open: 53, high: 54, low: 49, close: 51),
        CandlestickDataPoint(x: 7, open: 51, high: 57, low: 50, close: 56),
      ],
    ),
  ],
  'pie-charts' => [
    PieChartSeries.fromMap(
      id: 'mobile-pie',
      name: 'Spending',
      values: const {'Home': 42, 'Food': 27, 'Travel': 18, 'Other': 13},
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.inside,
        content: PieDataLabelContent.percentage,
        minimumShare: 0.12,
      ),
      pieStyle: const PieChartStyle(
        sliceGap: 3,
        cornerRadius: 3,
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
  'donut-charts' => [
    DonutChartSeries.fromMap(
      id: 'mobile-donut',
      name: 'Storage',
      values: const {'Photos': 46, 'Apps': 31, 'Files': 23},
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.58,
        sliceGap: 3,
        cornerRadius: 6,
        animationMode: PieAnimationMode.grow,
      ),
      centerContent: const DonutCenterContent(
        label: 'Used',
        valueMode: DonutCenterValueMode.custom,
        customValue: '78%',
      ),
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.inside,
        content: PieDataLabelContent.percentage,
        minimumShare: 0.14,
      ),
    ),
  ],
  'concentric-donut' => [
    DonutChartSeries.fromMap(
      id: 'mobile-concentric-current',
      name: 'This week',
      values: const {'Active': 68, 'Rest': 32},
      sliceColors: {
        'Active': presentation.palette[3],
        'Rest': presentation.palette[3].withValues(alpha: 0.2),
      },
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        sliceGap: 2,
        cornerRadius: 5,
        selectionExplodeOffset: 0,
        animationMode: PieAnimationMode.sweep,
      ),
    ),
    DonutChartSeries.fromMap(
      id: 'mobile-concentric-previous',
      name: 'Last week',
      values: const {'Active': 54, 'Rest': 46},
      sliceColors: {
        'Active': presentation.palette[1],
        'Rest': presentation.palette[1].withValues(alpha: 0.2),
      },
      dataLabels: const PieDataLabelConfig(isVisible: false),
      donutStyle: const DonutChartStyle(
        sliceGap: 2,
        cornerRadius: 5,
        selectionExplodeOffset: 0,
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
  'polar-column' => [
    PolarColumnChartSeries.rose(
      id: 'mobile-polar-column',
      name: 'Activity',
      values: const {
        'Mon': 48,
        'Tue': 64,
        'Wed': 55,
        'Thu': 76,
        'Fri': 68,
        'Sat': 88,
        'Sun': 58,
      },
      color: presentation.palette[0],
      polarStyle: const PolarColumnStyle(
        cornerRadius: 3,
        showDataLabels: false,
        animationMode: PolarColumnAnimationMode.sweep,
      ),
    ),
  ],
  _ => const <ChartSeries>[],
};

List<ChartSeries> _mobileVariantSeries(
  String slug,
  int variant,
  _MobileStylePresentation presentation,
) => switch (slug) {
  'line-charts' => [
    if (variant == 1) ...[
      _mobileLine(
        id: 'mobile-line-current',
        name: 'Current',
        color: presentation.palette[0],
        values: const [30, 38, 35, 48, 44, 55, 63, 58],
      ),
      _mobileLine(
        id: 'mobile-line-previous',
        name: 'Previous',
        color: presentation.palette[3],
        values: const [24, 32, 29, 42, 38, 49, 57, 52],
      ),
      _mobileLine(
        id: 'mobile-line-target',
        name: 'Target',
        color: presentation.palette[2],
        values: const [34, 36, 39, 43, 47, 51, 55, 59],
        interpolation: LineInterpolation.linear,
      ),
    ] else
      LineChartSeries(
        id: 'mobile-line-forecast',
        name: 'Observed + forecast',
        unit: '°C',
        color: presentation.palette[0],
        interpolation: LineInterpolation.monotone,
        strokeWidth: 3,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        dataPointMarkerStyle: DataPointMarkerStyle.hollow,
        pathAnimation: _pathEntrance,
        inlineLabel: SeriesInlineLabelConfig(
          text: 'Forecast',
          position: SeriesLabelPosition.right,
          color: presentation.palette[0],
        ),
        points: const [
          ChartDataPoint(x: 0, y: 12.1),
          ChartDataPoint(x: 1, y: 11.9),
          ChartDataPoint(x: 2, y: 11.8),
          ChartDataPoint(x: 3, y: 11.7),
          ChartDataPoint(
            x: 4,
            y: 11.8,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 5,
            y: 11.4,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 6,
            y: 11.1,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 7,
            y: 10.4,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
          ChartDataPoint(
            x: 8,
            y: 9.9,
            segmentStyle: SegmentStyle(dashPattern: [2, 6]),
          ),
        ],
      ),
  ],
  'area-charts' => [
    if (variant == 1)
      AreaChartSeries(
        id: 'mobile-area-baseline',
        name: 'Delta from target',
        unit: '%',
        color: presentation.palette[3],
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.8,
        fillOpacity: 0.34,
        baselineValue: 0,
        aboveBaselineFillColor: presentation.palette[4].withValues(alpha: 0.3),
        belowBaselineFillColor: presentation.palette[3].withValues(alpha: 0.28),
        showDataPointMarkers: true,
        dataPointMarkerRadius: 3.5,
        pathAnimation: _pathEntrance,
        points: _points(const [14, 9, 5, -3, -9, -16, -8, 4]),
      )
    else ...[
      AreaChartSeries(
        id: 'mobile-area-total',
        name: 'Total',
        color: presentation.palette[0],
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.2,
        pathAnimation: _pathEntrance,
        points: _points(const [58, 65, 69, 66, 74, 81, 78]),
      ),
      AreaChartSeries(
        id: 'mobile-area-active',
        name: 'Active',
        color: presentation.palette[1],
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.3,
        pathAnimation: _pathEntrance,
        points: _points(const [32, 37, 41, 39, 46, 52, 49]),
      ),
      _mobileLine(
        id: 'mobile-area-plan',
        name: 'Plan',
        color: presentation.palette[2],
        values: const [35, 38, 41, 44, 47, 50, 53],
        interpolation: LineInterpolation.linear,
      ),
    ],
  ],
  'range-area-charts' => [
    if (variant == 1)
      RangeAreaChartSeries(
        id: 'mobile-range-seasonal',
        name: 'Seasonal range',
        unit: '°C',
        color: presentation.palette[3],
        interpolation: LineInterpolation.monotone,
        fillOpacity: 0.3,
        fillGradient: AreaGradient(
          colors: [
            presentation.palette[3].withValues(alpha: 0.55),
            presentation.palette[3].withValues(alpha: 0.08),
          ],
        ),
        showBoundaryMarkers: true,
        markerRadius: 3,
        pathAnimation: _pathEntrance,
        points: _rangePoints(
          const [-8, -5, -2, 2, 7, 11, 9, 5, 0, -4, -7, -9],
          const [-1, 2, 6, 11, 16, 20, 18, 15, 10, 6, 2, 0],
        ),
      )
    else
      ..._mobileForecastFan(presentation),
  ],
  'bar-charts' => [
    if (variant == 1)
      ..._mobileOverlayBars(presentation)
    else
      ..._mobileSurveyBars(presentation),
  ],
  'scatter-charts' => [
    if (variant == 1)
      ..._mobileBubbleSeries(presentation)
    else
      ..._mobileCohortSeries(presentation),
  ],
  'candlestick-charts' => [
    if (variant == 1)
      ..._mobilePriceAndAverage(presentation)
    else
      ..._mobileVolatilityStudy(presentation),
  ],
  'pie-charts' => [
    PieChartSeries.fromMap(
      id: 'mobile-pie-$variant',
      name: variant == 1 ? 'Revenue' : 'Campaigns',
      values: variant == 1
          ? const {
              'Subscriptions': 46,
              'Services': 24,
              'Hardware': 15,
              'Training': 9,
              'Other': 6,
            }
          : const {
              'Search': 31,
              'Social': 24,
              'Partners': 19,
              'Events': 15,
              'Email': 11,
            },
      radiusValues: variant == 2
          ? const {
              'Search': 92,
              'Social': 76,
              'Partners': 64,
              'Events': 51,
              'Email': 43,
            }
          : const {},
      sliceRadiusConfig: variant == 2
          ? const PieSliceRadiusConfig(
              minimumFactor: 0.48,
              scale: PieSliceRadiusScale.area,
              label: 'Audience reach',
            )
          : null,
      sliceColors: _sliceColors(
        variant == 1
            ? const [
                'Subscriptions',
                'Services',
                'Hardware',
                'Training',
                'Other',
              ]
            : const ['Search', 'Social', 'Partners', 'Events', 'Email'],
        presentation.palette,
      ),
      dataLabels: PieDataLabelConfig(
        position: variant == 1
            ? PieDataLabelPosition.outside
            : PieDataLabelPosition.inside,
        content: variant == 1
            ? PieDataLabelContent.category
            : PieDataLabelContent.percentage,
        secondaryContent: variant == 1 ? PieDataLabelContent.percentage : null,
        secondaryPosition: PieDataLabelPosition.inside,
        minimumShare: 0.06,
        padding: 4,
        connectorLength: 10,
      ),
      pieStyle: PieChartStyle(
        sliceGap: variant == 1 ? 2 : 5,
        cornerRadius: variant == 1 ? 3 : 8,
        gradient: const PieGradientStyle(),
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
  'donut-charts' => [
    DonutChartSeries.fromMap(
      id: 'mobile-donut-$variant',
      name: variant == 1 ? 'Delivery' : 'Channels',
      values: variant == 1
          ? const {
              'Build': 46,
              'Discovery': 18,
              'Design': 14,
              'Testing': 12,
              'Launch': 7,
              'Support': 3,
            }
          : const {
              'Search': 31,
              'Social': 24,
              'Partners': 19,
              'Events': 15,
              'Email': 11,
            },
      radiusValues: variant == 2
          ? const {
              'Search': 92,
              'Social': 76,
              'Partners': 64,
              'Events': 51,
              'Email': 43,
            }
          : const {},
      sliceRadiusConfig: variant == 2
          ? const RadialSliceRadiusConfig(
              minimumFactor: 0.42,
              scale: PieSliceRadiusScale.area,
              label: 'Audience reach',
            )
          : null,
      sliceColors: _sliceColors(
        variant == 1
            ? const [
                'Build',
                'Discovery',
                'Design',
                'Testing',
                'Launch',
                'Support',
              ]
            : const ['Search', 'Social', 'Partners', 'Events', 'Email'],
        presentation.palette,
      ),
      donutStyle: DonutChartStyle(
        innerRadiusFactor: variant == 1 ? 0.68 : 0.36,
        sweepAngleDegrees: variant == 1 ? 280 : 360,
        startAngleDegrees: variant == 1 ? 130 : -90,
        sliceGap: 3,
        cornerRadius: 10,
        animationMode: PieAnimationMode.sweep,
      ),
      centerContent: DonutCenterContent(
        label: variant == 1 ? 'Status' : 'Reach',
        valueMode: DonutCenterValueMode.custom,
        customValue: variant == 1 ? 'On track' : '100',
      ),
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.inside,
        content: PieDataLabelContent.percentage,
        minimumShare: 0.1,
      ),
    ),
  ],
  'concentric-donut' => _concentricSeries(variant, presentation),
  'polar-column' => _mobilePolarSeries(variant, presentation),
  _ => const <ChartSeries>[],
};

LineChartSeries _mobileLine({
  required String id,
  required String name,
  required Color color,
  required List<double> values,
  LineInterpolation interpolation = LineInterpolation.monotone,
}) => LineChartSeries(
  id: id,
  name: name,
  color: color,
  interpolation: interpolation,
  strokeWidth: 2.7,
  showDataPointMarkers: true,
  dataPointMarkerRadius: 3,
  pathAnimation: _pathEntrance,
  points: _points(values),
);

List<ChartSeries> _mobileForecastFan(_MobileStylePresentation presentation) {
  const centre = <double>[62, 65, 68, 69, 68, 67, 69, 74, 79];
  return [
    RangeAreaChartSeries(
      id: 'mobile-forecast-95',
      name: '95% interval',
      color: presentation.palette[0],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.22,
      pathAnimation: _pathEntrance,
      points: _rangePoints(
        const [56, 58, 60, 60, 58, 56, 57, 60, 63],
        const [68, 72, 76, 78, 78, 78, 82, 88, 95],
      ),
    ),
    RangeAreaChartSeries(
      id: 'mobile-forecast-50',
      name: '50% interval',
      color: presentation.palette[3],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.34,
      pathAnimation: _pathEntrance,
      points: _rangePoints(
        const [59, 62, 65, 66, 64, 63, 64, 68, 72],
        const [65, 68, 71, 72, 72, 71, 74, 80, 86],
      ),
    ),
    _mobileLine(
      id: 'mobile-forecast-centre',
      name: 'Centre',
      color: presentation.palette[2],
      values: centre,
    ),
  ];
}

List<ChartSeries> _mobileOverlayBars(_MobileStylePresentation presentation) => [
  BarChartSeries(
    id: 'mobile-medals-reference',
    name: 'Previous',
    color: presentation.onSurfaceVariant.withValues(alpha: 0.38),
    layoutMode: BarLayoutMode.overlaid,
    groupId: 'medals',
    overlayWidthFactor: 1,
    barWidthPercent: 0.72,
    barStyle: const BarChartStyle(
      cornerRadius: 4,
      motion: BarMotionStyle(staggerFraction: 0.5),
    ),
    points: _labelledPoints(
      const ['CN', 'US', 'JP', 'AU', 'FR'],
      const [38, 39, 27, 17, 10],
    ),
  ),
  BarChartSeries(
    id: 'mobile-medals-current',
    name: 'Current',
    color: presentation.palette[0],
    layoutMode: BarLayoutMode.overlaid,
    groupId: 'medals',
    overlayWidthFactor: 0.68,
    overlayOffsetFactor: 0.12,
    barWidthPercent: 0.72,
    barStyle: const BarChartStyle(
      cornerRadius: 4,
      motion: BarMotionStyle(
        order: BarAnimationOrder.centerOut,
        staggerFraction: 0.62,
      ),
    ),
    labelStyle: const BarLabelStyle(
      show: true,
      position: BarLabelPosition.insideCenter,
    ),
    points: _labelledPoints(
      const ['CN', 'US', 'JP', 'AU', 'FR'],
      const [40, 40, 20, 18, 16],
      colors: presentation.palette,
    ),
  ),
];

List<ChartSeries> _mobileSurveyBars(_MobileStylePresentation presentation) {
  const labels = ['Easy to learn', 'Fast enough', 'Would recommend'];
  const values = <List<double>>[
    [22, 30, 18],
    [18, 16, 14],
    [60, 54, 68],
  ];
  const names = ['Disagree', 'Neutral', 'Agree'];
  const roles = [
    BarDivergingRole.negative,
    BarDivergingRole.neutral,
    BarDivergingRole.positive,
  ];
  return [
    for (var index = 0; index < values.length; index++)
      BarChartSeries(
        id: 'mobile-survey-$index',
        name: names[index],
        color: presentation.palette[index == 2 ? 2 : index],
        unit: '%',
        orientation: BarOrientation.horizontal,
        layoutMode: BarLayoutMode.divergingStacked,
        divergingRole: roles[index],
        groupId: 'survey',
        barWidthPercent: 0.62,
        barStyle: const BarChartStyle(
          cornerRadius: 3,
          motion: BarMotionStyle(staggerFraction: 0.55),
        ),
        labelStyle: const BarLabelStyle(
          show: true,
          position: BarLabelPosition.insideCenter,
          valueMode: BarLabelValueMode.percentage,
          collisionPolicy: BarLabelCollisionPolicy.hide,
        ),
        points: _labelledPoints(labels, values[index]),
      ),
  ];
}

List<ChartSeries> _mobileBubbleSeries(_MobileStylePresentation presentation) =>
    [
      ScatterChartSeries(
        id: 'mobile-bubble-established',
        name: 'Established',
        color: presentation.palette[4],
        markerShape: SeriesMarkerShape.circle,
        sizeEncoding: const ScatterSizeEncoding(
          minimumRadius: 5,
          maximumRadius: 16,
          maximumValue: 18000,
          label: 'Active accounts',
        ),
        points: const [
          ChartDataPoint(x: 4, y: 94, magnitude: 16400),
          ChartDataPoint(x: 7, y: 89, magnitude: 9800),
          ChartDataPoint(x: 11, y: 84, magnitude: 7200),
          ChartDataPoint(x: 15, y: 79, magnitude: 4100),
        ],
      ),
      ScatterChartSeries(
        id: 'mobile-bubble-growth',
        name: 'Growth',
        color: presentation.palette[2],
        markerShape: SeriesMarkerShape.diamond,
        sizeEncoding: const ScatterSizeEncoding(
          minimumRadius: 5,
          maximumRadius: 16,
          maximumValue: 18000,
          label: 'Active accounts',
        ),
        points: const [
          ChartDataPoint(x: 8, y: 75, magnitude: 11300),
          ChartDataPoint(x: 12, y: 84, magnitude: 6900),
          ChartDataPoint(x: 16, y: 77, magnitude: 9800),
          ChartDataPoint(x: 20, y: 70, magnitude: 2600),
        ],
      ),
    ];

List<ChartSeries> _mobileCohortSeries(_MobileStylePresentation presentation) {
  const x = <double>[18, 25, 31, 36, 42, 47, 51, 56, 61, 67, 73, 82];
  const cohorts = <List<double>>[
    [30, 36, 40, 45, 47, 51, 49, 55, 59, 64, 68, 72],
    [24, 34, 38, 42, 52, 48, 55, 44, 61, 57, 66, 63],
    [32, 28, 41, 46, 43, 54, 50, 58, 53, 66, 61, 70],
  ];
  return [
    for (var index = 0; index < cohorts.length; index++)
      ScatterChartSeries(
        id: 'mobile-cohort-$index',
        name: 'Cohort ${index + 1}',
        color: presentation.palette[index],
        markerRadius: 4.5,
        points: _xyPoints(x, cohorts[index]),
      ),
  ];
}

List<ChartSeries> _mobilePriceAndAverage(
  _MobileStylePresentation presentation,
) => [
  _mobileCandles('mobile-price-average', presentation, _candles(1)),
  _mobileLine(
    id: 'mobile-price-average-line',
    name: 'Average',
    color: presentation.palette[0],
    values: const [40, 42, 42.7, 44.2, 46, 47.5, 49.5],
  ),
];

List<ChartSeries> _mobileVolatilityStudy(
  _MobileStylePresentation presentation,
) {
  final candles = _candles(2);
  return [
    RangeAreaChartSeries(
      id: 'mobile-volatility-band',
      name: 'Volatility',
      color: presentation.palette[4],
      interpolation: LineInterpolation.monotone,
      fillOpacity: 0.18,
      pathAnimation: _pathEntrance,
      points: _rangePoints(
        const [56, 57, 58, 61, 60, 62, 65],
        const [68, 70, 71, 74, 73, 76, 79],
      ),
    ),
    _mobileCandles('mobile-volatility-price', presentation, candles),
    _mobileLine(
      id: 'mobile-volatility-trend',
      name: 'Trend',
      color: presentation.palette[1],
      values: const [63, 62, 63.5, 65, 66, 68, 70],
    ),
  ];
}

CandlestickChartSeries _mobileCandles(
  String id,
  _MobileStylePresentation presentation,
  List<CandlestickDataPoint> points,
) => CandlestickChartSeries(
  id: id,
  name: 'Price',
  points: points,
  candlestickStyle: CandlestickChartStyle(
    risingBodyFillColor: presentation.palette[4],
    risingBorderColor: presentation.palette[4],
    risingWickColor: presentation.palette[4],
    fallingBodyFillColor: presentation.palette[3],
    fallingBorderColor: presentation.palette[3],
    fallingWickColor: presentation.palette[3],
    bodyFillMode: CandlestickBodyFillMode.hollowRising,
    bodyCornerRadius: 2,
  ),
  animation: const CandlestickAnimationStyle(staggerFraction: 0.68),
);

List<PolarColumnChartSeries> _mobilePolarSeries(
  int variant,
  _MobileStylePresentation presentation,
) {
  const categories = ['Direct', 'Search', 'Social', 'Partners', 'Email'];
  const observed = <double>[83, 72, 48, 68, 39];
  const capacity = <double>[96, 88, 74, 82, 64];
  const south = <double>[55, 68, 61, 74, 52];
  const west = <double>[44, 57, 70, 63, 78];
  final style = const PolarColumnStyle(
    cornerRadius: 4,
    showDataLabels: false,
    animationMode: PolarColumnAnimationMode.sweep,
  );
  if (variant == 1) {
    return [
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-capacity',
        name: 'Capacity',
        values: _categoryValues(categories, capacity),
        color: presentation.palette[3],
        polarStyle: style.copyWith(opacity: 0.3),
      ),
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-observed',
        name: 'Observed',
        values: _categoryValues(categories, observed),
        color: presentation.palette[0],
        polarStyle: style,
      ),
    ];
  }
  return [
    for (final (index, values) in [observed, south, west].indexed)
      PolarColumnChartSeries.fromMap(
        id: 'mobile-polar-region-$index',
        name: ['North', 'South', 'West'][index],
        values: _categoryValues(categories, values),
        color: presentation.palette[index],
        polarStyle: style,
      ),
  ];
}

Map<String, num> _categoryValues(
  List<String> categories,
  List<double> values,
) => {
  for (var index = 0; index < categories.length; index++)
    categories[index]: values[index],
};

List<ChartDataPoint> _labelledPoints(
  List<String> labels,
  List<double> values, {
  List<Color>? colors,
}) => [
  for (var index = 0; index < values.length; index++)
    ChartDataPoint(
      x: index.toDouble(),
      y: values[index],
      label: labels[index],
      pointStyle: colors == null
          ? null
          : PointStyle.color(colors[index % colors.length]),
    ),
];

List<ChartDataPoint> _points(List<double> values) => [
  for (var index = 0; index < values.length; index++)
    ChartDataPoint(x: index + 1, y: values[index]),
];

List<ChartDataPoint> _xyPoints(List<double> x, List<double> y) => [
  for (var index = 0; index < x.length; index++)
    ChartDataPoint(x: x[index], y: y[index]),
];

List<RangeAreaDataPoint> _rangePoints(List<double> lows, List<double> highs) =>
    [
      for (var index = 0; index < lows.length; index++)
        RangeAreaDataPoint(x: index + 1, low: lows[index], high: highs[index]),
    ];

Map<String, Color> _sliceColors(
  Iterable<String> categories,
  List<Color> palette,
) => {
  for (final (index, category) in categories.indexed)
    category: palette[index % palette.length],
};

List<CandlestickDataPoint> _candles(int variant) {
  final source = variant == 1
      ? const [
          (38.0, 44.0, 36.0, 42.0),
          (42.0, 47.0, 40.0, 45.0),
          (45.0, 46.0, 39.0, 41.0),
          (41.0, 48.0, 40.0, 47.0),
          (47.0, 52.0, 45.0, 50.0),
          (50.0, 53.0, 47.0, 49.0),
          (49.0, 56.0, 48.0, 54.0),
        ]
      : const [
          (62.0, 66.0, 59.0, 64.0),
          (64.0, 65.0, 58.0, 60.0),
          (60.0, 67.0, 59.0, 66.0),
          (66.0, 71.0, 64.0, 69.0),
          (69.0, 70.0, 63.0, 65.0),
          (65.0, 72.0, 64.0, 70.0),
          (70.0, 75.0, 68.0, 73.0),
        ];
  return [
    for (var index = 0; index < source.length; index++)
      CandlestickDataPoint(
        x: index + 1,
        open: source[index].$1,
        high: source[index].$2,
        low: source[index].$3,
        close: source[index].$4,
      ),
  ];
}

List<ChartSeries> _concentricSeries(
  int variant,
  _MobileStylePresentation presentation,
) {
  final seriesValues = variant == 1
      ? const <Map<String, num>>[
          {'Subscriptions': 45, 'Services': 30, 'Other': 25},
          {'Subscriptions': 30, 'Services': 35, 'Other': 35},
          {'Subscriptions': 30, 'Services': 25, 'Other': 45},
        ]
      : const <Map<String, num>>[
          {'Core': 42, 'Growth': 34, 'Other': 24},
          {'Core': 31, 'Growth': 44, 'Other': 25},
          {'Core': 52, 'Growth': 28, 'Other': 20},
        ];
  final count = variant == 0 ? 2 : 3;
  return [
    for (var index = 0; index < count; index++)
      DonutChartSeries.fromMap(
        id: 'mobile-concentric-$variant-$index',
        name: variant == 1
            ? ['Current', 'Previous', 'Forecast'][index]
            : variant == 2
            ? ['Platform', 'Services', 'Support'][index]
            : ['This week', 'Last week'][index],
        values: variant == 0
            ? index == 0
                  ? const {'Active': 68, 'Rest': 32}
                  : const {'Active': 54, 'Rest': 46}
            : seriesValues[index],
        sliceColors: variant == 0
            ? {
                'Active': presentation.palette[index],
                'Rest': presentation.palette[index].withValues(alpha: 0.2),
              }
            : _sliceColors(seriesValues[index].keys, [
                presentation.palette[index],
                presentation.palette[(index + 2) % 5],
                presentation.palette[(index + 4) % 5],
              ]),
        dataLabels: const PieDataLabelConfig(isVisible: false),
        donutStyle: DonutChartStyle(
          sweepAngleDegrees: variant == 2 ? 300 : 360,
          startAngleDegrees: variant == 2 ? 120 : -90,
          sliceGap: 3,
          cornerRadius: 7,
          selectionExplodeOffset: 0,
          animationMode: PieAnimationMode.sweep,
        ),
      ),
  ];
}
