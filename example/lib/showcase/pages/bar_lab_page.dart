// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _BarLabPreset {
  capacity,
  bullet,
  likert,
  targets,
  uncertainty,
  lollipop,
  pareto,
  histogram,
  rtl,
  rods,
  gradient,
  signed,
  overlay,
  offset,
  range,
  waterfall,
  horizontal,
  axes,
  categories,
  labels,
  config,
  patterns,
  motion,
  states,
  stacked,
  normalized,
}

extension on _BarLabPreset {
  String get label => switch (this) {
    _BarLabPreset.capacity => 'Capacity',
    _BarLabPreset.bullet => 'Bullet',
    _BarLabPreset.likert => 'Likert',
    _BarLabPreset.targets => 'Targets',
    _BarLabPreset.uncertainty => 'Uncertainty',
    _BarLabPreset.lollipop => 'Lollipop',
    _BarLabPreset.pareto => 'Pareto',
    _BarLabPreset.histogram => 'Histogram',
    _BarLabPreset.rtl => 'RTL',
    _BarLabPreset.rods => 'Rods',
    _BarLabPreset.gradient => 'Gradient',
    _BarLabPreset.signed => 'Signed',
    _BarLabPreset.overlay => 'Overlay',
    _BarLabPreset.offset => 'Offset',
    _BarLabPreset.range => 'Range',
    _BarLabPreset.waterfall => 'Waterfall',
    _BarLabPreset.horizontal => 'Horizontal',
    _BarLabPreset.axes => 'Axes',
    _BarLabPreset.categories => 'Categories',
    _BarLabPreset.labels => 'Labels',
    _BarLabPreset.config => 'Config',
    _BarLabPreset.patterns => 'Patterns',
    _BarLabPreset.motion => 'Motion',
    _BarLabPreset.states => 'States',
    _BarLabPreset.stacked => 'Stacked',
    _BarLabPreset.normalized => '100%',
  };

  IconData get icon => switch (this) {
    _BarLabPreset.capacity => Icons.stacked_bar_chart,
    _BarLabPreset.bullet => Icons.linear_scale,
    _BarLabPreset.likert => Icons.balance,
    _BarLabPreset.targets => Icons.flag_outlined,
    _BarLabPreset.uncertainty => Icons.align_vertical_center,
    _BarLabPreset.lollipop => Icons.scatter_plot_outlined,
    _BarLabPreset.pareto => Icons.trending_up,
    _BarLabPreset.histogram => Icons.bar_chart,
    _BarLabPreset.rtl => Icons.format_textdirection_r_to_l,
    _BarLabPreset.rods => Icons.equalizer,
    _BarLabPreset.gradient => Icons.gradient,
    _BarLabPreset.signed => Icons.swap_vert,
    _BarLabPreset.overlay => Icons.layers_outlined,
    _BarLabPreset.offset => Icons.compare_arrows,
    _BarLabPreset.range => Icons.height,
    _BarLabPreset.waterfall => Icons.waterfall_chart,
    _BarLabPreset.horizontal => Icons.align_horizontal_left,
    _BarLabPreset.axes => Icons.straighten,
    _BarLabPreset.categories => Icons.view_week_outlined,
    _BarLabPreset.labels => Icons.label_outline,
    _BarLabPreset.config => Icons.data_object,
    _BarLabPreset.patterns => Icons.texture,
    _BarLabPreset.motion => Icons.animation,
    _BarLabPreset.states => Icons.touch_app_outlined,
    _BarLabPreset.stacked => Icons.stacked_bar_chart,
    _BarLabPreset.normalized => Icons.percent,
  };
}

/// Interactive review surface for the modern bar geometry and style system.
class BarLabPage extends StatefulWidget {
  const BarLabPage({super.key});

  @override
  State<BarLabPage> createState() => _BarLabPageState();
}

class _BarLabPageState extends State<BarLabPage> {
  static const _categoryFormatterId = 'braven.showcase.bar-category';
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  static const _dayCategories = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _medalCategories = ['CN', 'US', 'JP', 'AU', 'FR'];
  static const _waterfallCategories = [
    'Opening',
    'New sales',
    'Expansion',
    'Churn',
    'Costs',
    'Other',
    'Net',
  ];
  static const _channelCategories = [
    'Enterprise',
    'Online',
    'Partners',
    'Mid-market',
    'Retail',
    'Direct',
  ];
  static const _likertCategories = [
    'Easy to learn',
    'Fast enough',
    'Reports are clear',
    'Fits our workflow',
    'Support is helpful',
    'Would recommend',
  ];
  static const _rtlCategories = [
    'المؤسسات',
    'المتجر الإلكتروني',
    'الشركاء',
    'السوق المتوسطة',
    'التجزئة',
    'المبيعات المباشرة',
  ];
  static const _paretoCategories = [
    ParetoCategory(label: 'Notification delay', value: 29),
    ParetoCategory(label: 'Missing profile data', value: 126),
    ParetoCategory(label: 'Other', value: 12),
    ParetoCategory(label: 'Billing mismatch', value: 53),
    ParetoCategory(label: 'Password reset', value: 84),
    ParetoCategory(label: 'Export formatting', value: 18),
    ParetoCategory(label: 'Duplicate account', value: 41),
  ];
  static const _responseTimeSamples = <double>[
    3.8,
    4.2,
    4.9,
    5.1,
    5.3,
    5.7,
    6.0,
    6.2,
    6.4,
    6.8,
    7.0,
    7.1,
    7.3,
    7.5,
    7.8,
    8.0,
    8.2,
    8.4,
    8.5,
    8.7,
    8.9,
    9.0,
    9.2,
    9.4,
    9.6,
    9.8,
    10.0,
    10.3,
    10.5,
    10.8,
    11.0,
    11.2,
    11.5,
    11.8,
    12.1,
    12.4,
    12.8,
    13.2,
    13.6,
    14.0,
    14.5,
    15.1,
    15.8,
    16.6,
    17.5,
    18.4,
    19.6,
    21.0,
    22.8,
    25.4,
    28.7,
    34.2,
  ];
  static const _denseCategories = [
    'North America Enterprise',
    'North America Commercial',
    'Latin America Growth',
    'United Kingdom & Ireland',
    'Northern Europe',
    'Central Europe',
    'Southern Europe',
    'Middle East Enterprise',
    'Africa Growth Markets',
    'India & South Asia',
    'Southeast Asia',
    'Greater China',
    'Japan Enterprise',
    'Korea Commercial',
    'Australia & New Zealand',
    'Public Sector Americas',
    'Public Sector EMEA',
    'Digital Native Accounts',
    'Strategic Partnerships',
    'Channel & Distribution',
    'Customer Expansion',
    'New Market Incubation',
    'Global Services',
    'Renewals & Retention',
  ];
  static const _medalColors = <Color>[
    Color(0xFF1F77B4),
    Color(0xFFC44FEA),
    Color(0xFF5149C6),
    Color(0xFF2CA5E8),
    Color(0xFFD90429),
  ];
  static const _seriesColors = <Color>[
    Color(0xFF168AAD),
    Color(0xFFF9735B),
    Color(0xFF6D5BD0),
    Color(0xFFE5A11A),
    Color(0xFF2F80ED),
    Color(0xFF34A853),
    Color(0xFFD94F8A),
    Color(0xFF8E6C4A),
    Color(0xFF00A6A6),
    Color(0xFF7A8B2E),
    Color(0xFFC65D21),
    Color(0xFF526D82),
  ];

  _BarLabPreset _preset = _BarLabPreset.capacity;
  int _seriesCount = 2;
  int _stackGroupCount = 1;
  BarLayoutMode _layoutMode = BarLayoutMode.grouped;
  BarOrientation _orientation = BarOrientation.vertical;
  double _barWidth = 0.72;
  double _barGap = 4;
  double _overlayWidthStep = 22;
  double _overlayOffsetStep = 0;
  double _cornerRadius = 8;
  bool _showTracks = true;
  bool _showGradient = false;
  bool _showBorder = false;
  bool _showLabels = true;
  bool _showConnectors = true;
  BarCornerRadiusPolicy _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
  BarLabelPosition _labelPosition = BarLabelPosition.auto;
  double _labelEdgeOffset = 8;
  double _dimmedOpacity = 0.42;
  int _motionRevision = 0;
  double _motionDurationMs = 650;
  BarAnimationOrder _motionOrder = BarAnimationOrder.together;
  double _motionStagger = 0;
  bool _animateBars = true;
  bool _motionIncludeSunday = true;
  bool _motionIncludeForecast = true;
  bool _showTargets = false;
  double _targetMarkerWidth = 2;
  double _targetMarkerLength = 1.3;
  bool _showUncertainty = false;
  double _errorBarWidth = 1.5;
  double _errorCapLength = 0.6;
  double _lollipopStemWidth = 3;
  double _lollipopHeadRadius = 8;
  double _paretoLineWidth = 3;
  bool _showParetoMarkers = true;
  bool _showParetoCumulativeLabels = false;
  HistogramBinningMethod _histogramMethod =
      HistogramBinningMethod.freedmanDiaconis;
  int _histogramBinCount = 8;
  HistogramValueMode _histogramValueMode = HistogramValueMode.count;
  ChartDisplayMode _initialDisplayMode = ChartDisplayMode.chart;
  CategoryLabelDensity _categoryLabelDensity = CategoryLabelDensity.auto;
  CategoryLabelOverflow _categoryLabelOverflow = CategoryLabelOverflow.wrap;
  double _categoryMinimumExtent = 72;
  int _categoryMaxLines = 2;
  double _categoryRotation = 0;
  BarLabelCollisionPolicy _labelCollisionPolicy = BarLabelCollisionPolicy.none;
  bool _labelPlotEdgeAware = true;
  double _labelCollisionPadding = 2;
  bool _showLabelBackground = false;
  bool _showLabelCallouts = false;
  bool _showStackTotals = false;
  bool _showPatterns = true;
  double _patternSpacing = 8;
  double _patternStrokeWidth = 1.5;
  double _patternOpacity = 0.58;
  int _bulletRangeCount = 3;
  double _bulletMeasureThickness = 0.42;
  double _bulletRangeRadius = 4;
  bool _showDivergingCenterLine = true;
  double _divergingCenterLineWidth = 1.25;

  @override
  void initState() {
    super.initState();
    _chartController.addListener(_onChartInteractionChanged);
    final requestedView = Uri.base.queryParameters['view'];
    for (final mode in ChartDisplayMode.values) {
      if (mode.name == requestedView) {
        _initialDisplayMode = mode;
        break;
      }
    }
    final requestedPreset = Uri.base.queryParameters['preset'];
    for (final preset in _BarLabPreset.values) {
      if (preset.name == requestedPreset) {
        _preset = preset;
        _setPresetValues(preset);
        break;
      }
    }
    final requestedSeries = int.tryParse(
      Uri.base.queryParameters['series'] ?? '',
    );
    if (requestedSeries != null) {
      _seriesCount = requestedSeries.clamp(1, _seriesColors.length);
    }
    final requestedLayout = Uri.base.queryParameters['layout'];
    for (final mode in BarLayoutMode.values) {
      if (mode.name == requestedLayout && _supportsLayout(_preset, mode)) {
        _layoutMode = mode;
        break;
      }
    }
    final requestedGroups = int.tryParse(
      Uri.base.queryParameters['groups'] ?? '',
    );
    if (requestedGroups != null) {
      _stackGroupCount = requestedGroups.clamp(1, _seriesCount);
    }
    final requestedCorners = Uri.base.queryParameters['corners'];
    for (final policy in BarCornerRadiusPolicy.values) {
      if (policy.name == requestedCorners) {
        _cornerPolicy = policy;
        break;
      }
    }
  }

  @override
  void dispose() {
    _chartController
      ..removeListener(_onChartInteractionChanged)
      ..dispose();
    _workbenchController.dispose();
    super.dispose();
  }

  void _onChartInteractionChanged() {
    if (mounted && _preset == _BarLabPreset.states) setState(() {});
  }

  ChartDocumentExtractOptions get _documentOptions =>
      ChartDocumentExtractOptions(
        documentId: 'bar-lab-${_preset.name}',
        includeViewState: true,
        xAxisFormatterDescriptor:
            _usesNativeCategoryAxis || _preset == _BarLabPreset.config
            ? null
            : ChartFormatterDescriptor(
                id: _categoryFormatterId,
                arguments: {
                  'labels': JsonArrayValue([
                    for (final label in _categories) JsonStringValue(label),
                  ]),
                },
              ).toDocument(),
      );

  ChartTableOptions get _tableOptions => const ChartTableOptions(
    formatters: ChartFormatterRegistry(
      customFormatters: {_categoryFormatterId: _formatCategory},
    ),
  );

  static String _formatCategory(
    double value,
    Map<String, JsonValue> arguments,
  ) {
    final labels = arguments['labels'];
    final index = value.round();
    if (labels is! JsonArrayValue ||
        index < 0 ||
        index >= labels.values.length) {
      return value.toString();
    }
    final label = labels.values[index];
    return label is JsonStringValue ? label.value : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Bar Charts',
      subtitle:
          'Grouped, stacked, horizontal, range, waterfall, and precision styling',
      actions: [
        OutlinedButton.icon(
          onPressed: _resetPreset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset style'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 16),
          Expanded(child: _buildChartCard()),
        ],
      ),
    );
  }

  Widget _buildPresetPicker() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final chips = <Widget>[
                  for (final preset in _BarLabPreset.values)
                    ChoiceChip(
                      key: ValueKey('bar-lab-preset-${preset.name}'),
                      showCheckmark: false,
                      selected: preset == _preset,
                      onSelected: (_) => _applyPreset(preset),
                      avatar: Icon(
                        preset.icon,
                        size: 17,
                        color: preset == _preset
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(preset.label),
                      labelStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: preset == _preset
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: preset == _preset
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      selectedColor: theme.colorScheme.secondaryContainer,
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ];
                if (constraints.maxWidth < 900) {
                  return SingleChildScrollView(
                    key: const ValueKey('bar-lab-preset-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: Row(spacing: 6, children: chips),
                  );
                }
                return Wrap(
                  key: const ValueKey('bar-lab-preset-wrap'),
                  spacing: 6,
                  runSpacing: 6,
                  children: chips,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              _presetDescription(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final card = ChartCard(
      title: _presetTitle(),
      subtitle: _chartSummary(),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: BravenChartWorkbench(
        chartController: _chartController,
        workbenchController: _workbenchController,
        initialDisplayMode: _initialDisplayMode,
        documentOptions: _documentOptions,
        tableOptions: _tableOptions,
        splitBreakpoint: 760,
        tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
        chartBuilder: (context, controller) {
          final chart = _buildChart(controller);
          final showWaterfallLegend = _preset == _BarLabPreset.waterfall;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: showWaterfallLegend ? 20 : 0,
                child: Offstage(
                  offstage: !showWaterfallLegend,
                  child: _buildWaterfallLegend(),
                ),
              ),
              SizedBox(height: showWaterfallLegend ? 8 : 0),
              Expanded(child: chart),
            ],
          );
        },
      ),
    );
    return Directionality(
      textDirection: _preset == _BarLabPreset.rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: card,
    );
  }

  Widget _buildChart(BravenChartController controller) {
    final lastCategory = _categories.length - 1;
    final baseTheme = ChartTheme.light;
    final configured = _preset == _BarLabPreset.config
        ? _agentBuildResult
        : null;
    return BravenChartPlus(
      bravenChartController: controller,
      theme: baseTheme.copyWith(
        animationTheme: baseTheme.animationTheme.copyWith(
          dataUpdateDuration: Duration(milliseconds: _motionDurationMs.round()),
          dataUpdateCurve: Curves.easeInOutCubic,
        ),
      ),
      series: configured?.series ?? _buildSeries(),
      showXScrollbar: _preset == _BarLabPreset.categories,
      scrollbarTheme: _preset == _BarLabPreset.categories
          ? ScrollbarConfig.defaultLight.copyWith(autoHide: false)
          : null,
      showLegend:
          configured?.showLegend ??
          (_preset != _BarLabPreset.waterfall &&
              _preset != _BarLabPreset.labels &&
              _preset != _BarLabPreset.histogram &&
              _preset != _BarLabPreset.rtl),
      normalizationMode: _preset == _BarLabPreset.axes
          ? NormalizationMode.perSeries
          : null,
      maxAxesPerSide: 3,
      grid:
          configured?.gridConfig ??
          GridConfig(
            horizontal: _orientation == BarOrientation.vertical,
            vertical: _orientation == BarOrientation.horizontal,
          ),
      xAxisConfig:
          configured?.xAxisConfig ??
          XAxisConfig(
            label: _preset == _BarLabPreset.categories
                ? 'Market segment'
                : _preset == _BarLabPreset.pareto
                ? 'Issue cause'
                : _preset == _BarLabPreset.histogram
                ? 'Response time (minutes)'
                : _preset == _BarLabPreset.rtl
                ? 'القناة'
                : _preset == _BarLabPreset.offset
                ? 'Country'
                : _preset == _BarLabPreset.waterfall
                ? 'Stage'
                : _preset == _BarLabPreset.likert
                ? 'Survey statement'
                : _preset == _BarLabPreset.bullet ||
                      _preset == _BarLabPreset.horizontal ||
                      _preset == _BarLabPreset.axes
                ? 'Channel'
                : 'Day',
            min: _usesNativeCategoryAxis
                ? null
                : _orientation == BarOrientation.horizontal
                ? -1
                : -0.6,
            max: _usesNativeCategoryAxis
                ? null
                : lastCategory +
                      (_orientation == BarOrientation.horizontal ? 1 : 0.6),
            renderMin: _usesNativeCategoryAxis ? null : 0,
            renderMax: _usesNativeCategoryAxis ? null : lastCategory.toDouble(),
            tickCount: _categories.length,
            maxHeight: _preset == _BarLabPreset.categories
                ? 92
                : _preset == _BarLabPreset.pareto
                ? 76
                : _preset == _BarLabPreset.histogram
                ? 68
                : 60,
            categoryAxis: _usesNativeCategoryAxis
                ? CategoryAxisConfig(
                    categories: _categories,
                    labelDensity:
                        _preset == _BarLabPreset.pareto ||
                            _preset == _BarLabPreset.histogram
                        ? CategoryLabelDensity.showAll
                        : _categoryLabelDensity,
                    labelOverflow:
                        _preset == _BarLabPreset.pareto ||
                            _preset == _BarLabPreset.histogram
                        ? CategoryLabelOverflow.wrap
                        : _categoryLabelOverflow,
                    minimumCategoryExtent: _preset == _BarLabPreset.pareto
                        ? 68
                        : _preset == _BarLabPreset.histogram
                        ? 56
                        : _categoryMinimumExtent,
                    maximumLabelExtent: 132,
                    maxLabelLines:
                        _preset == _BarLabPreset.pareto ||
                            _preset == _BarLabPreset.histogram
                        ? 2
                        : _categoryMaxLines,
                    labelRotationDegrees:
                        _preset == _BarLabPreset.pareto ||
                            _preset == _BarLabPreset.histogram
                        ? 0
                        : _categoryRotation,
                  )
                : null,
            labelFormatter: _usesNativeCategoryAxis ? null : _categoryLabel,
          ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: _preset == _BarLabPreset.offset
            ? 'Gold medals'
            : _preset == _BarLabPreset.bullet
            ? 'Performance (%)'
            : _preset == _BarLabPreset.likert
            ? 'Response share (%)'
            : _preset == _BarLabPreset.targets
            ? 'Completion (%)'
            : _preset == _BarLabPreset.uncertainty
            ? 'Estimate (%)'
            : _preset == _BarLabPreset.pareto
            ? 'Issues'
            : _preset == _BarLabPreset.histogram
            ? switch (_histogramValueMode) {
                HistogramValueMode.count => 'Frequency',
                HistogramValueMode.percentage => 'Share (%)',
                HistogramValueMode.density => 'Density',
              }
            : _preset == _BarLabPreset.rtl
            ? 'الإيرادات (بالآلاف)'
            : _preset == _BarLabPreset.range
            ? 'Temperature (°C)'
            : _preset == _BarLabPreset.waterfall
            ? 'Cash flow (thousands)'
            : _preset == _BarLabPreset.horizontal
            ? 'Revenue (thousands)'
            : _preset == _BarLabPreset.axes
            ? 'Independent values'
            : _preset == _BarLabPreset.config
            ? 'Configured value'
            : _layoutMode == BarLayoutMode.normalizedStacked
            ? 'Share of total (%)'
            : _preset == _BarLabPreset.signed
            ? 'Net change'
            : 'Value',
        min: _layoutMode == BarLayoutMode.normalizedStacked
            ? (_preset == _BarLabPreset.signed ? -110 : 0)
            : (_preset == _BarLabPreset.likert ||
                  _preset == _BarLabPreset.signed ||
                  _preset == _BarLabPreset.range ||
                  _preset == _BarLabPreset.waterfall)
            ? null
            : 0,
        max: _layoutMode == BarLayoutMode.normalizedStacked ? 110 : null,
        tickCount: 7,
      ),
      interactionConfig: InteractionConfig(
        tooltip: const TooltipConfig(),
        crosshair: CrosshairConfig(
          mode: CrosshairMode.both,
          displayMode: _orientation == BarOrientation.horizontal
              ? CrosshairDisplayMode.tracking
              : CrosshairDisplayMode.auto,
        ),
      ),
    );
  }

  Widget _buildWaterfallLegend() => const Padding(
    padding: EdgeInsets.only(left: 52, right: 8),
    child: Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _BarLabLegendItem(color: Color(0xFF168AAD), label: 'Increase'),
        _BarLabLegendItem(color: Color(0xFFE15B64), label: 'Decrease'),
        _BarLabLegendItem(color: Color(0xFF5149C6), label: 'Total'),
      ],
    ),
  );

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Composition',
      icon: Icons.view_week_outlined,
      children: [
        if (_preset != _BarLabPreset.pareto &&
            _preset != _BarLabPreset.histogram) ...[
          IntSliderOption(
            label: 'Series count',
            value: _seriesCount,
            min: 1,
            max: _seriesColors.length,
            onChanged: (value) => setState(() => _seriesCount = value),
          ),
          EnumOption<BarLayoutMode>(
            label: 'Layout',
            value: _layoutMode,
            values: BarLayoutMode.values
                .where((mode) => _supportsLayout(_preset, mode))
                .toList(growable: false),
            labelBuilder: _layoutLabel,
            onChanged: (value) => setState(() => _layoutMode = value),
          ),
          EnumOption<BarOrientation>(
            key: const ValueKey('bar-lab-orientation'),
            label: 'Orientation',
            value: _orientation,
            values: BarOrientation.values,
            labelBuilder: (value) => switch (value) {
              BarOrientation.vertical => 'Vertical',
              BarOrientation.horizontal => 'Horizontal',
            },
            onChanged: (value) => setState(() => _orientation = value),
          ),
        ],
        if (_layoutMode == BarLayoutMode.overlaid ||
            _layoutMode == BarLayoutMode.stacked ||
            _layoutMode == BarLayoutMode.normalizedStacked)
          IntSliderOption(
            label: _layoutMode == BarLayoutMode.overlaid
                ? 'Overlay groups'
                : 'Named stacks',
            value: _stackGroupCount.clamp(1, _seriesCount),
            min: 1,
            max: _seriesCount,
            onChanged: (value) => setState(() => _stackGroupCount = value),
          ),
        if (_layoutMode == BarLayoutMode.overlaid)
          SliderOption(
            label: 'Layer inset',
            value: _overlayWidthStep,
            min: 0,
            max: 35,
            divisions: 7,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _overlayWidthStep = value),
          ),
        if (_layoutMode == BarLayoutMode.overlaid)
          SliderOption(
            label: 'Layer offset',
            value: _overlayOffsetStep,
            min: 0,
            max: 40,
            divisions: 8,
            suffix: '%',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _overlayOffsetStep = value),
          ),
        SliderOption(
          label: 'Category fill',
          value: _barWidth,
          min: 0.2,
          max: 0.95,
          divisions: 15,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _barWidth = value),
        ),
        SliderOption(
          label: 'Bar gap',
          value: _barGap,
          min: 0,
          max: 16,
          divisions: 16,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _barGap = value),
        ),
      ],
    ),
    if (_preset == _BarLabPreset.pareto)
      OptionSection(
        title: 'Cumulative line',
        icon: Icons.trending_up,
        children: [
          BoolOption(
            key: const ValueKey('bar-lab-pareto-markers'),
            label: 'Markers',
            value: _showParetoMarkers,
            subtitle: 'Mark the cumulative share at each ranked cause',
            onChanged: (value) => setState(() => _showParetoMarkers = value),
          ),
          BoolOption(
            key: const ValueKey('bar-lab-pareto-labels'),
            label: 'Cumulative labels',
            value: _showParetoCumulativeLabels,
            subtitle: 'Show percentages above the line markers',
            onChanged: (value) =>
                setState(() => _showParetoCumulativeLabels = value),
          ),
          SliderOption(
            key: const ValueKey('bar-lab-pareto-line-width'),
            label: 'Line width',
            value: _paretoLineWidth,
            min: 1,
            max: 6,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _paretoLineWidth = value),
          ),
        ],
      ),
    if (_preset == _BarLabPreset.histogram)
      OptionSection(
        title: 'Binning',
        icon: Icons.grid_on_outlined,
        children: [
          EnumOption<HistogramBinningMethod>(
            key: const ValueKey('bar-lab-histogram-method'),
            label: 'Method',
            value: _histogramMethod,
            values: HistogramBinningMethod.values,
            labelBuilder: _histogramMethodLabel,
            onChanged: (value) => setState(() => _histogramMethod = value),
          ),
          if (_histogramMethod == HistogramBinningMethod.fixedCount)
            IntSliderOption(
              key: const ValueKey('bar-lab-histogram-bin-count'),
              label: 'Bin count',
              value: _histogramBinCount,
              min: 2,
              max: 20,
              onChanged: (value) => setState(() => _histogramBinCount = value),
            ),
          EnumOption<HistogramValueMode>(
            key: const ValueKey('bar-lab-histogram-value-mode'),
            label: 'Bar height',
            value: _histogramValueMode,
            values: HistogramValueMode.values,
            labelBuilder: (value) => switch (value) {
              HistogramValueMode.count => 'Count',
              HistogramValueMode.percentage => 'Percentage',
              HistogramValueMode.density => 'Density',
            },
            onChanged: (value) => setState(() => _histogramValueMode = value),
          ),
          Text(
            '${_histogramData.bins.length} bins from ${_histogramData.sampleCount} samples',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    if (_preset == _BarLabPreset.categories)
      OptionSection(
        title: 'Category axis',
        icon: Icons.view_week_outlined,
        children: [
          EnumOption<CategoryLabelDensity>(
            label: 'Label density',
            value: _categoryLabelDensity,
            values: CategoryLabelDensity.values,
            labelBuilder: (value) => switch (value) {
              CategoryLabelDensity.auto => 'Automatic',
              CategoryLabelDensity.showAll => 'Show all',
            },
            onChanged: (value) => setState(() => _categoryLabelDensity = value),
          ),
          EnumOption<CategoryLabelOverflow>(
            label: 'Long labels',
            value: _categoryLabelOverflow,
            values: CategoryLabelOverflow.values,
            labelBuilder: (value) => switch (value) {
              CategoryLabelOverflow.wrap => 'Wrap',
              CategoryLabelOverflow.ellipsis => 'Ellipsis',
            },
            onChanged: (value) =>
                setState(() => _categoryLabelOverflow = value),
          ),
          SliderOption(
            label: 'Category width',
            value: _categoryMinimumExtent,
            min: 40,
            max: 120,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _categoryMinimumExtent = value),
          ),
          IntSliderOption(
            label: 'Wrap lines',
            value: _categoryMaxLines,
            min: 1,
            max: 3,
            onChanged: (value) => setState(() => _categoryMaxLines = value),
          ),
          SliderOption(
            label: 'Label rotation',
            value: _categoryRotation,
            min: -60,
            max: 60,
            divisions: 8,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _categoryRotation = value),
          ),
        ],
      ),
    OptionSection(
      title: 'Shape',
      icon: Icons.rounded_corner,
      children: [
        if (_preset == _BarLabPreset.lollipop) ...[
          SliderOption(
            key: const ValueKey('bar-lab-lollipop-stem-width'),
            label: 'Stem width',
            value: _lollipopStemWidth,
            min: 1,
            max: 8,
            divisions: 14,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (value) => setState(() => _lollipopStemWidth = value),
          ),
          SliderOption(
            key: const ValueKey('bar-lab-lollipop-head-radius'),
            label: 'Marker radius',
            value: _lollipopHeadRadius,
            min: 4,
            max: 18,
            divisions: 14,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _lollipopHeadRadius = value),
          ),
        ] else ...[
          SliderOption(
            label: 'Corner radius',
            value: _cornerRadius,
            min: 0,
            max: 32,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _cornerRadius = value),
          ),
          EnumOption<BarCornerRadiusPolicy>(
            label: 'Rounded corners',
            value: _cornerPolicy,
            values: BarCornerRadiusPolicy.values,
            labelBuilder: (value) => switch (value) {
              BarCornerRadiusPolicy.all => 'All corners',
              BarCornerRadiusPolicy.valueEnd => 'Value end only',
            },
            onChanged: (value) => setState(() => _cornerPolicy = value),
          ),
        ],
        if (_layoutMode != BarLayoutMode.waterfall)
          if (_preset != _BarLabPreset.bullet &&
              _preset != _BarLabPreset.pareto &&
              _preset != _BarLabPreset.histogram)
            BoolOption(
              label: 'Capacity tracks',
              value: _showTracks,
              onChanged: (value) => setState(() => _showTracks = value),
              subtitle: 'Show the available range behind each bar',
            ),
        if (_layoutMode == BarLayoutMode.waterfall)
          BoolOption(
            label: 'Connectors',
            value: _showConnectors,
            onChanged: (value) => setState(() => _showConnectors = value),
            subtitle: 'Link each step at its cumulative value',
          ),
        BoolOption(
          key: const ValueKey('bar-lab-border'),
          label: 'Border',
          value: _showBorder,
          onChanged: (value) => setState(() => _showBorder = value),
        ),
        if (_layoutMode != BarLayoutMode.waterfall)
          if (_preset != _BarLabPreset.bullet &&
              _preset != _BarLabPreset.lollipop)
            BoolOption(
              key: const ValueKey('bar-lab-gradient'),
              label: 'Gradient',
              value: _showGradient,
              onChanged: (value) => setState(() => _showGradient = value),
            ),
      ],
    ),
    if (_preset == _BarLabPreset.patterns)
      OptionSection(
        title: 'Pattern encoding',
        icon: Icons.texture,
        children: [
          BoolOption(
            key: const ValueKey('bar-lab-pattern-fills'),
            label: 'Pattern fills',
            value: _showPatterns,
            subtitle: 'Pair line direction with one shared hue',
            onChanged: (value) => setState(() => _showPatterns = value),
          ),
          if (_showPatterns)
            SliderOption(
              label: 'Pattern spacing',
              value: _patternSpacing,
              min: 4,
              max: 16,
              divisions: 6,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _patternSpacing = value),
            ),
          if (_showPatterns)
            SliderOption(
              label: 'Line width',
              value: _patternStrokeWidth,
              min: 0.5,
              max: 3,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _patternStrokeWidth = value),
            ),
          if (_showPatterns)
            SliderOption(
              label: 'Pattern opacity',
              value: _patternOpacity,
              min: 0.2,
              max: 1,
              divisions: 8,
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _patternOpacity = value),
            ),
        ],
      ),
    if (_preset == _BarLabPreset.bullet)
      OptionSection(
        title: 'Bullet ranges',
        icon: Icons.linear_scale,
        children: [
          IntSliderOption(
            key: const ValueKey('bar-lab-bullet-range-count'),
            label: 'Qualitative bands',
            value: _bulletRangeCount,
            min: 2,
            max: 4,
            onChanged: (value) => setState(() => _bulletRangeCount = value),
          ),
          SliderOption(
            key: const ValueKey('bar-lab-bullet-measure-thickness'),
            label: 'Measure thickness',
            value: _bulletMeasureThickness,
            min: 0.25,
            max: 0.75,
            divisions: 10,
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _bulletMeasureThickness = value),
          ),
          SliderOption(
            label: 'Range radius',
            value: _bulletRangeRadius,
            min: 0,
            max: 12,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _bulletRangeRadius = value),
          ),
        ],
      ),
    if (_preset == _BarLabPreset.likert)
      OptionSection(
        title: 'Diverging scale',
        icon: Icons.balance,
        children: [
          BoolOption(
            key: const ValueKey('bar-lab-diverging-center-line'),
            label: 'Center line',
            value: _showDivergingCenterLine,
            subtitle: 'Anchor neutral responses at the shared midpoint',
            onChanged: (value) =>
                setState(() => _showDivergingCenterLine = value),
          ),
          if (_showDivergingCenterLine)
            SliderOption(
              key: const ValueKey('bar-lab-diverging-center-line-width'),
              label: 'Line width',
              value: _divergingCenterLineWidth,
              min: 0.5,
              max: 3,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _divergingCenterLineWidth = value),
            ),
        ],
      ),
    OptionSection(
      title: 'Labels',
      icon: Icons.label_outline,
      children: [
        BoolOption(
          label: 'Value labels',
          value: _showLabels,
          onChanged: (value) => setState(() => _showLabels = value),
        ),
        if (_showLabels)
          EnumOption<BarLabelPosition>(
            label: 'Label position',
            value: _labelPosition,
            values:
                _preset == _BarLabPreset.pareto ||
                    _preset == _BarLabPreset.histogram
                ? const [
                    BarLabelPosition.auto,
                    BarLabelPosition.insideEnd,
                    BarLabelPosition.insideCenter,
                    BarLabelPosition.outsideEnd,
                  ]
                : BarLabelPosition.values,
            labelBuilder: (value) => switch (value) {
              BarLabelPosition.auto => 'Auto',
              BarLabelPosition.insideEnd => 'Inside end',
              BarLabelPosition.insideCenter => 'Inside center',
              BarLabelPosition.outsideEnd => 'Outside end',
              BarLabelPosition.rangeEnds => 'Range ends',
            },
            onChanged: (value) => setState(() => _labelPosition = value),
          ),
        if (_showLabels && _labelPosition != BarLabelPosition.insideCenter)
          SliderOption(
            label: 'Edge offset',
            value: _labelEdgeOffset,
            min: 0,
            max: 20,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _labelEdgeOffset = value),
          ),
        if (_showLabels &&
            (_preset == _BarLabPreset.labels ||
                _preset == _BarLabPreset.config))
          EnumOption<BarLabelCollisionPolicy>(
            label: 'Collisions',
            value: _labelCollisionPolicy,
            values: BarLabelCollisionPolicy.values,
            labelBuilder: (value) => switch (value) {
              BarLabelCollisionPolicy.none => 'Allow overlap',
              BarLabelCollisionPolicy.reposition => 'Reposition',
              BarLabelCollisionPolicy.hide => 'Hide overlap',
            },
            onChanged: (value) => setState(() => _labelCollisionPolicy = value),
          ),
        if (_showLabels &&
            (_preset == _BarLabPreset.labels ||
                _preset == _BarLabPreset.config))
          BoolOption(
            label: 'Plot-edge aware',
            value: _labelPlotEdgeAware,
            subtitle: 'Keep labels inside the visible plotting area',
            onChanged: (value) => setState(() => _labelPlotEdgeAware = value),
          ),
        if (_showLabels &&
            (_preset == _BarLabPreset.labels ||
                _preset == _BarLabPreset.config) &&
            _labelCollisionPolicy != BarLabelCollisionPolicy.none)
          SliderOption(
            label: 'Collision gap',
            value: _labelCollisionPadding,
            min: 0,
            max: 12,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _labelCollisionPadding = value),
          ),
        if (_showLabels &&
            (_preset == _BarLabPreset.labels ||
                _preset == _BarLabPreset.config))
          BoolOption(
            label: 'Label background',
            value: _showLabelBackground,
            subtitle: 'Add a restrained box when labels cross chart marks',
            onChanged: (value) => setState(() => _showLabelBackground = value),
          ),
        if (_showLabels &&
            (_preset == _BarLabPreset.labels ||
                _preset == _BarLabPreset.config))
          BoolOption(
            label: 'Callout lines',
            value: _showLabelCallouts,
            subtitle: 'Connect displaced labels to their value end',
            onChanged: (value) => setState(() => _showLabelCallouts = value),
          ),
        if (_showLabels &&
            (_layoutMode == BarLayoutMode.stacked ||
                _layoutMode == BarLayoutMode.normalizedStacked))
          BoolOption(
            label: 'Stack totals',
            value: _showStackTotals,
            subtitle: 'Show one resolved total at each stack end',
            onChanged: (value) => setState(() => _showStackTotals = value),
          ),
      ],
    ),
    if (_preset == _BarLabPreset.targets ||
        _preset == _BarLabPreset.bullet ||
        (_preset == _BarLabPreset.config &&
            (_layoutMode == BarLayoutMode.grouped ||
                _layoutMode == BarLayoutMode.overlaid)))
      OptionSection(
        title: 'Benchmarks',
        icon: Icons.flag_outlined,
        children: [
          BoolOption(
            label: 'Target markers',
            value: _showTargets,
            subtitle: 'Show one benchmark across each bar',
            onChanged: (value) => setState(() => _showTargets = value),
          ),
          if (_showTargets)
            SliderOption(
              label: 'Marker width',
              value: _targetMarkerWidth,
              min: 1,
              max: 6,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _targetMarkerWidth = value),
            ),
          if (_showTargets)
            SliderOption(
              label: 'Marker span',
              value: _targetMarkerLength,
              min: 0.8,
              max: 2.8,
              divisions: 10,
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _targetMarkerLength = value),
            ),
        ],
      ),
    if (_preset == _BarLabPreset.uncertainty ||
        (_preset == _BarLabPreset.config &&
            (_layoutMode == BarLayoutMode.grouped ||
                _layoutMode == BarLayoutMode.overlaid)))
      OptionSection(
        title: 'Uncertainty',
        icon: Icons.align_vertical_center,
        children: [
          BoolOption(
            label: 'Error bars',
            value: _showUncertainty,
            subtitle: 'Show absolute lower and upper bounds',
            onChanged: (value) => setState(() => _showUncertainty = value),
          ),
          if (_showUncertainty)
            SliderOption(
              label: 'Line width',
              value: _errorBarWidth,
              min: 0.5,
              max: 4,
              divisions: 14,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _errorBarWidth = value),
            ),
          if (_showUncertainty)
            SliderOption(
              label: 'Cap span',
              value: _errorCapLength,
              min: 0.2,
              max: 1.2,
              divisions: 10,
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _errorCapLength = value),
            ),
        ],
      ),
    if (_preset == _BarLabPreset.states)
      OptionSection(
        title: 'Interaction',
        icon: Icons.touch_app_outlined,
        children: [
          SliderOption(
            label: 'Inactive opacity',
            value: _dimmedOpacity,
            min: 0.15,
            max: 0.8,
            divisions: 13,
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _dimmedOpacity = value),
          ),
        ],
      ),
    if (_preset == _BarLabPreset.motion)
      OptionSection(
        title: 'Motion',
        icon: Icons.animation,
        children: [
          BoolOption(
            label: 'Animate bars',
            value: _animateBars,
            subtitle: 'Reduced-motion settings still take priority',
            onChanged: (value) => setState(() => _animateBars = value),
          ),
          BoolOption(
            key: const ValueKey('bar-lab-motion-sunday'),
            label: 'Sunday point',
            value: _motionIncludeSunday,
            subtitle: 'Toggle to inspect a keyed point exit',
            onChanged: (value) => setState(() => _motionIncludeSunday = value),
          ),
          BoolOption(
            key: const ValueKey('bar-lab-motion-forecast'),
            label: 'Forecast series',
            value: _motionIncludeForecast,
            subtitle: 'Toggle to inspect a full-series exit',
            onChanged: (value) =>
                setState(() => _motionIncludeForecast = value),
          ),
          EnumOption<BarAnimationOrder>(
            key: const ValueKey('bar-lab-motion-order'),
            label: 'Sequence',
            value: _motionOrder,
            values: BarAnimationOrder.values,
            labelBuilder: _motionOrderLabel,
            onChanged: (value) => setState(() => _motionOrder = value),
          ),
          if (_motionOrder != BarAnimationOrder.together)
            SliderOption(
              label: 'Stagger',
              value: _motionStagger * 100,
              min: 0,
              max: 70,
              divisions: 14,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _motionStagger = value / 100),
            ),
          SliderOption(
            label: 'Duration',
            value: _motionDurationMs,
            min: 150,
            max: 1200,
            divisions: 21,
            suffix: 'ms',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _motionDurationMs = value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('bar-lab-replay-motion'),
              onPressed: _animateBars
                  ? () => setState(() => _motionRevision++)
                  : null,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Replay values'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ),
        ],
      ),
  ];

  ChartBuildResult get _agentBuildResult {
    final layout = switch (_layoutMode) {
      BarLayoutMode.grouped => 'grouped',
      BarLayoutMode.overlaid => 'overlaid',
      BarLayoutMode.stacked => 'stacked',
      BarLayoutMode.normalizedStacked => 'normalized_stacked',
      BarLayoutMode.divergingStacked => 'diverging_stacked',
      BarLayoutMode.waterfall => 'waterfall',
    };
    final isComposed =
        _layoutMode == BarLayoutMode.overlaid ||
        _layoutMode == BarLayoutMode.stacked ||
        _layoutMode == BarLayoutMode.normalizedStacked ||
        _layoutMode == BarLayoutMode.divergingStacked;
    final supportsReferences =
        _layoutMode == BarLayoutMode.grouped ||
        _layoutMode == BarLayoutMode.overlaid;

    return ChartConfigBuilder.fromJson({
      'chart_id': 'bar-lab-agent-config',
      'chart_type': 'bar',
      'title': 'Tool-configured operations',
      'x_axis': {
        'label': 'Day',
        'categories': _dayCategories,
        'category_label_density': 'show_all',
        'category_label_overflow': 'wrap',
        'category_minimum_extent': 64,
        'category_maximum_label_extent': 112,
        'category_max_label_lines': 2,
        'category_auto_viewport': false,
      },
      'series': [
        for (var seriesIndex = 0; seriesIndex < _seriesCount; seriesIndex++)
          {
            'id': 'configured-${seriesIndex + 1}',
            'name': seriesIndex == 0
                ? 'Current'
                : seriesIndex == 1
                ? 'Plan'
                : 'Series ${seriesIndex + 1}',
            'color': _colorHex(_seriesColors[seriesIndex]),
            if (_showGradient)
              'bar_gradient_colors': [
                _colorHex(
                  Color.lerp(_seriesColors[seriesIndex], Colors.white, 0.56)!,
                ),
                _colorHex(_seriesColors[seriesIndex]),
              ],
            if (_showBorder)
              'bar_border_color': _colorHex(
                Color.lerp(_seriesColors[seriesIndex], Colors.black, 0.28)!,
              ),
            if (_showTracks)
              'bar_track_color': _colorHex(
                Color.lerp(_seriesColors[seriesIndex], Colors.white, 0.86)!,
              ),
            if (isComposed)
              'bar_group_id': 'group-${seriesIndex % _effectiveGroupCount}',
            if (_layoutMode == BarLayoutMode.overlaid)
              'bar_overlay_width_factor':
                  (1 -
                          (seriesIndex ~/ _effectiveGroupCount) *
                              _overlayWidthStep /
                              100)
                      .clamp(0.2, 1),
            if (_layoutMode == BarLayoutMode.overlaid)
              'bar_overlay_offset_factor':
                  (seriesIndex ~/ _effectiveGroupCount) *
                  _overlayOffsetStep /
                  100,
            'data': [
              for (
                var categoryIndex = 0;
                categoryIndex < _dayCategories.length;
                categoryIndex++
              )
                {
                  'x': categoryIndex,
                  'y': _agentBarValue(seriesIndex, categoryIndex),
                  'label': _dayCategories[categoryIndex],
                  if (supportsReferences && _showTargets)
                    'bar_target':
                        (_agentBarValue(seriesIndex, categoryIndex) + 6).clamp(
                          0,
                          100,
                        ),
                  if (supportsReferences && _showUncertainty)
                    'bar_error_lower':
                        _agentBarValue(seriesIndex, categoryIndex) - 5,
                  if (supportsReferences && _showUncertainty)
                    'bar_error_upper':
                        _agentBarValue(seriesIndex, categoryIndex) + 7,
                },
            ],
          },
      ],
      'style': {
        'show_legend': true,
        'bar_layout': layout,
        'bar_orientation': _orientation.name,
        'bar_width_percent': _barWidth,
        'bar_gap': _barGap,
        'bar_minimum_length': 4,
        'bar_corner_radius': _cornerRadius,
        'bar_corner_policy': _cornerPolicy == BarCornerRadiusPolicy.all
            ? 'all'
            : 'value_end',
        'bar_animation_mode': _animateBars ? 'grow' : 'none',
        if (_showBorder) 'bar_border_width': 1.25,
        'bar_track_enabled': _showTracks,
        if (_showTracks) 'bar_track_value': 100,
        'bar_target_color': '#334155',
        'bar_target_width': _targetMarkerWidth,
        'bar_target_length_factor': _targetMarkerLength,
        'bar_error_color': '#475569',
        'bar_error_width': _errorBarWidth,
        'bar_error_cap_length_factor': _errorCapLength,
        'bar_dimmed_opacity': _dimmedOpacity,
        'bar_labels_show': _showLabels,
        'bar_label_position': switch (_labelPosition) {
          BarLabelPosition.auto => 'auto',
          BarLabelPosition.insideEnd => 'inside_end',
          BarLabelPosition.insideCenter => 'inside_center',
          BarLabelPosition.outsideEnd => 'outside_end',
          BarLabelPosition.rangeEnds => 'range_ends',
        },
        'bar_label_value_mode': _layoutMode == BarLayoutMode.normalizedStacked
            ? 'percentage'
            : 'value',
        'bar_label_padding': _labelEdgeOffset,
        'bar_label_collision': _labelCollisionPolicy.name,
        'bar_label_plot_edge_aware': _labelPlotEdgeAware,
        'bar_label_collision_padding': _labelCollisionPadding,
        if (_showLabelBackground) 'bar_label_background_color': '#EEFFFFFF',
        if (_showLabelBackground) 'bar_label_border_color': '#55334155',
        if (_showLabelBackground) 'bar_label_border_width': 1,
        'bar_label_callout_show': _showLabelCallouts,
        'bar_label_callout_color': '#475569',
        'bar_label_show_stack_total': _showStackTotals,
      },
    });
  }

  double _agentBarValue(int seriesIndex, int categoryIndex) {
    final seed = seriesIndex * 17 + categoryIndex * 11;
    if (_layoutMode == BarLayoutMode.stacked ||
        _layoutMode == BarLayoutMode.normalizedStacked) {
      return (12 + seed % 28).toDouble();
    }
    return (48 + seed % 47).toDouble();
  }

  String _colorHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  List<ChartSeries> _buildSeries() {
    if (_preset == _BarLabPreset.config) return _agentBuildResult.series;
    if (_preset == _BarLabPreset.pareto) return _buildParetoSeries();
    if (_preset == _BarLabPreset.histogram) return _buildHistogramSeries();
    final values = switch (_preset) {
      _BarLabPreset.capacity => const <double>[42, 61, 88, 35, 70, 94, 55],
      _BarLabPreset.bullet => const <double>[82, 64, 91, 73, 58, 87],
      _BarLabPreset.likert => const <double>[8, 12, 6, 15, 10, 7],
      _BarLabPreset.targets => const <double>[68, 74, 81, 57, 88, 92, 70],
      _BarLabPreset.uncertainty => const <double>[64, 72, 78, 58, 85, 90, 69],
      _BarLabPreset.lollipop => const <double>[54, 72, 61, 88, 69, 94, 76],
      _BarLabPreset.pareto => const <double>[],
      _BarLabPreset.histogram => const <double>[],
      _BarLabPreset.rtl => const <double>[96, 84, 73, 61, 49, 36],
      _BarLabPreset.rods => const <double>[34, 57, 46, 69, 81, 96, 62],
      _BarLabPreset.gradient => const <double>[28, 49, 64, 91, 73, 84, 58],
      _BarLabPreset.signed => const <double>[38, -24, 52, -38, 71, 26, -18],
      _BarLabPreset.overlay => const <double>[42, 61, 88, 35, 70, 94, 55],
      _BarLabPreset.offset => const <double>[38, 39, 27, 17, 10],
      _BarLabPreset.range => const <double>[25, 29, 27, 31, 28, 24, 26],
      _BarLabPreset.waterfall => const <double>[82, 28, 16, -18, -24, 7, 0],
      _BarLabPreset.horizontal => const <double>[96, 84, 73, 61, 49, 36],
      _BarLabPreset.axes => const <double>[96, 84, 73, 61, 49, 36],
      _BarLabPreset.categories => const <double>[
        72,
        64,
        81,
        58,
        69,
        76,
        62,
        88,
        54,
        79,
        67,
        91,
        73,
        61,
        84,
        70,
        56,
        86,
        77,
        65,
        89,
        60,
        75,
        82,
      ],
      _BarLabPreset.labels => const <double>[88, 91, 86, 93, 89, 95, 87],
      _BarLabPreset.config => const <double>[],
      _BarLabPreset.patterns => const <double>[74, 58, 86, 67, 92, 79, 63],
      _BarLabPreset.motion =>
        _motionRevision.isEven
            ? const <double>[54, 72, 61, 88, 69, 94, 76]
            : const <double>[82, 48, 91, 63, 86, 57, 96],
      _BarLabPreset.states => const <double>[54, 72, 61, 88, 69, 94, 76],
      _BarLabPreset.stacked => const <double>[18, 24, 31, 22, 28, 35, 26],
      _BarLabPreset.normalized => const <double>[18, 24, 31, 22, 28, 35, 26],
    };
    final comparison = switch (_preset) {
      _BarLabPreset.capacity => const <double>[31, 69, 81, 52, 64, 86, 72],
      _BarLabPreset.bullet => const <double>[78, 69, 84, 76, 63, 90],
      _BarLabPreset.likert => const <double>[14, 18, 12, 20, 16, 11],
      _BarLabPreset.targets => const <double>[61, 82, 76, 69, 79, 86, 73],
      _BarLabPreset.uncertainty => const <double>[59, 77, 73, 66, 80, 84, 75],
      _BarLabPreset.lollipop => const <double>[42, 64, 79, 58, 83, 71, 91],
      _BarLabPreset.pareto => const <double>[],
      _BarLabPreset.histogram => const <double>[],
      _BarLabPreset.rtl => const <double>[88, 79, 68, 57, 44, 31],
      _BarLabPreset.rods => const <double>[46, 39, 71, 53, 88, 72, 90],
      _BarLabPreset.gradient => const <double>[41, 58, 51, 76, 89, 65, 78],
      _BarLabPreset.signed => const <double>[21, -39, 34, -14, 48, -28, 32],
      _BarLabPreset.overlay => const <double>[31, 69, 81, 52, 64, 86, 72],
      _BarLabPreset.offset => const <double>[40, 40, 20, 18, 16],
      _BarLabPreset.range => const <double>[23, 27, 30, 29, 26, 25, 28],
      _BarLabPreset.waterfall => const <double>[76, 22, 12, -15, -20, 5, 0],
      _BarLabPreset.horizontal => const <double>[88, 79, 68, 57, 44, 31],
      _BarLabPreset.axes => const <double>[420, 385, 352, 316, 274, 230],
      _BarLabPreset.categories => const <double>[
        66,
        70,
        74,
        63,
        72,
        68,
        77,
        81,
        59,
        73,
        71,
        85,
        69,
        65,
        78,
        76,
        61,
        80,
        74,
        70,
        83,
        64,
        79,
        75,
      ],
      _BarLabPreset.labels => const <double>[90, 87, 92, 89, 94, 88, 93],
      _BarLabPreset.config => const <double>[],
      _BarLabPreset.patterns => const <double>[62, 81, 71, 89, 68, 94, 76],
      _BarLabPreset.motion =>
        _motionRevision.isEven
            ? const <double>[42, 64, 79, 58, 83, 71, 91]
            : const <double>[68, 84, 55, 92, 61, 88, 73],
      _BarLabPreset.states => const <double>[42, 64, 79, 58, 83, 71, 91],
      _BarLabPreset.stacked => const <double>[14, 19, 26, 18, 24, 29, 21],
      _BarLabPreset.normalized => const <double>[14, 19, 26, 18, 24, 29, 21],
    };

    return [
      for (var index = 0; index < _seriesCount; index++)
        if (_preset != _BarLabPreset.motion ||
            index != 1 ||
            _motionIncludeForecast)
          _series(
            id: 'series-${index + 1}',
            name: switch ((_preset, index)) {
              (_BarLabPreset.targets, 0) => 'Actual',
              (_BarLabPreset.bullet, 0) => 'Actual',
              (_BarLabPreset.likert, _) => _likertSeriesName(index),
              (_BarLabPreset.uncertainty, 0) => 'Estimate',
              (_BarLabPreset.lollipop, 0) => 'Current',
              (_BarLabPreset.lollipop, 1) => 'Previous',
              (_BarLabPreset.offset, 0) => 'Summer 2020',
              (_BarLabPreset.offset, 1) => 'Current result',
              (_BarLabPreset.range, 0) => 'Observed',
              (_BarLabPreset.range, 1) => 'Forecast',
              (_BarLabPreset.waterfall, 0) => 'Current plan',
              (_BarLabPreset.waterfall, 1) => 'Previous plan',
              (_BarLabPreset.horizontal, 0) => 'Current',
              (_BarLabPreset.horizontal, 1) => 'Target',
              (_BarLabPreset.rtl, 0) => 'الإيراد الحالي',
              (_BarLabPreset.rtl, 1) => 'الهدف',
              (_BarLabPreset.axes, _) => _axisMetric(index).name,
              (_BarLabPreset.patterns, 0) => 'Actual',
              (_BarLabPreset.patterns, 1) => 'Forecast',
              (_BarLabPreset.patterns, 2) => 'Prior year',
              (_BarLabPreset.patterns, 3) => 'Benchmark',
              (_BarLabPreset.motion, 0) => 'Actual',
              (_BarLabPreset.motion, 1) => 'Forecast',
              (_BarLabPreset.states, 0) => 'Actual',
              (_BarLabPreset.states, 1) => 'Plan',
              (_, 0) => 'Current',
              (_, 1) => 'Previous',
              _ => 'Series ${index + 1}',
            },
            values: _motionValues(_valuesForSeries(index, values, comparison)),
            color: _seriesColor(index),
            gradientColors: [
              Color.lerp(_seriesColor(index), Colors.white, 0.38)!,
              _seriesColor(index),
            ],
            trackColor: Color.lerp(_seriesColor(index), Colors.white, 0.84)!,
          ),
    ];
  }

  ParetoChartData get _paretoData =>
      ParetoChartData(categories: _paretoCategories);

  HistogramChartData get _histogramData => HistogramChartData(
    samples: _responseTimeSamples,
    method: _histogramMethod,
    requestedBinCount: _histogramBinCount,
  );

  String? get _histogramUnit => switch (_histogramValueMode) {
    HistogramValueMode.count => null,
    HistogramValueMode.percentage => '%',
    HistogramValueMode.density => null,
  };

  List<ChartSeries> _buildHistogramSeries() {
    const color = Color(0xFF3F7CAC);
    final data = _histogramData;
    return [
      BarChartSeries(
        id: 'histogram-frequency',
        name: switch (_histogramValueMode) {
          HistogramValueMode.count => 'Count',
          HistogramValueMode.percentage => 'Percentage',
          HistogramValueMode.density => 'Density',
        },
        points: data.pointsFor(_histogramValueMode),
        color: color,
        unit: _histogramUnit,
        barWidthPercent: _barWidth,
        barGap: _barGap,
        orientation: BarOrientation.vertical,
        layoutMode: BarLayoutMode.grouped,
        barStyle: BarChartStyle(
          cornerRadius: _cornerRadius,
          cornerRadiusPolicy: _cornerPolicy,
          gradient: _showGradient
              ? BarGradient(
                  colors: [Color.lerp(color, Colors.white, 0.34)!, color],
                )
              : null,
          border: _showBorder
              ? BarBorderStyle(color: color.withValues(alpha: 0.9), width: 1.5)
              : null,
        ),
        labelStyle: BarLabelStyle(
          show: _showLabels,
          position: _labelPosition,
          showUnit: _histogramValueMode == HistogramValueMode.percentage,
          padding: _labelEdgeOffset,
          plotEdgeAware: true,
        ),
      ),
    ];
  }

  List<ChartSeries> _buildParetoSeries() {
    const barColor = Color(0xFF168AAD);
    const lineColor = Color(0xFFE56B3F);
    final data = _paretoData;
    return [
      BarChartSeries(
        id: 'pareto-frequency',
        name: 'Issues',
        points: data.valuePoints,
        color: barColor,
        unit: 'issues',
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          color: barColor,
          label: 'Issue count',
          min: 0,
          tickCount: 7,
          showCrosshairLabel: true,
        ),
        barWidthPercent: _barWidth,
        barGap: _barGap,
        orientation: BarOrientation.vertical,
        layoutMode: BarLayoutMode.grouped,
        barStyle: BarChartStyle(
          cornerRadius: _cornerRadius,
          cornerRadiusPolicy: _cornerPolicy,
          gradient: _showGradient
              ? BarGradient(
                  colors: [Color.lerp(barColor, Colors.white, 0.38)!, barColor],
                )
              : null,
          border: _showBorder
              ? BarBorderStyle(
                  color: barColor.withValues(alpha: 0.9),
                  width: 1.5,
                )
              : null,
        ),
        labelStyle: BarLabelStyle(
          show: _showLabels,
          position: _labelPosition,
          padding: _labelEdgeOffset,
          plotEdgeAware: true,
        ),
      ),
      LineChartSeries(
        id: 'pareto-cumulative',
        name: 'Cumulative share',
        points: data.cumulativePoints,
        color: lineColor,
        unit: '%',
        interpolation: LineInterpolation.linear,
        strokeWidth: _paretoLineWidth,
        showDataPointMarkers: _showParetoMarkers,
        dataPointMarkerRadius: 4,
        dataPointLabels: DataPointLabelConfig(
          show: _showParetoCumulativeLabels,
          position: DataPointLabelPosition.above,
          offsetY: -2,
          labelColor: lineColor,
          showUnit: true,
          background: Colors.white,
          backgroundOpacity: 0.9,
        ),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          color: lineColor,
          label: 'Cumulative share',
          unit: '%',
          min: 0,
          max: 100,
          renderMin: 0,
          renderMax: 100,
          tickCount: 6,
          showCrosshairLabel: true,
        ),
      ),
    ];
  }

  Color _seriesColor(int index) {
    if (_preset == _BarLabPreset.bullet && index == 0) {
      return const Color(0xFF155E75);
    }
    if (_preset == _BarLabPreset.patterns) {
      return const Color(0xFF386A78);
    }
    if (_preset == _BarLabPreset.likert) {
      const colors = <Color>[
        Color(0xFF294E6B),
        Color(0xFF6687A1),
        Color(0xFF9AA1A8),
        Color(0xFFD78A50),
        Color(0xFFA84E2F),
      ];
      if (_seriesCount == 5) return colors[index];
      final role = _divergingRoleForIndex(index);
      return switch (role) {
        BarDivergingRole.negative => Color.lerp(
          colors[0],
          colors[1],
          index / (_seriesCount / 2).ceil().clamp(1, _seriesCount),
        )!,
        BarDivergingRole.neutral => colors[2],
        BarDivergingRole.positive => Color.lerp(
          colors[3],
          colors[4],
          (index - _seriesCount / 2).abs() /
              (_seriesCount / 2).ceil().clamp(1, _seriesCount),
        )!,
      };
    }
    if (_preset == _BarLabPreset.offset && index == 0) {
      return const Color(0xFFB8BBC2);
    }
    return _seriesColors[index];
  }

  List<double> _valuesForSeries(
    int seriesIndex,
    List<double> primary,
    List<double> comparison,
  ) {
    if (seriesIndex == 0) return primary;
    if (seriesIndex == 1) return comparison;

    if (_preset == _BarLabPreset.likert && _seriesCount == 5) {
      return switch (seriesIndex) {
        2 => const [18, 16, 22, 17, 21, 14],
        3 => const [38, 34, 39, 31, 35, 40],
        _ => const [22, 20, 21, 17, 18, 28],
      };
    }

    return List.generate(_categories.length, (categoryIndex) {
      final seed = seriesIndex * 19 + categoryIndex * 13;
      if (_preset == _BarLabPreset.signed) {
        final magnitude = 14 + seed % 45;
        return (seriesIndex + categoryIndex) % 3 == 0
            ? -magnitude.toDouble()
            : magnitude.toDouble();
      }
      if (_preset == _BarLabPreset.stacked ||
          _preset == _BarLabPreset.normalized) {
        return (12 + seed % 32).toDouble();
      }
      if (_preset == _BarLabPreset.likert) {
        return (8 + seed % 28).toDouble();
      }
      if (_preset == _BarLabPreset.range) {
        return (22 + seed % 11).toDouble();
      }
      if (_preset == _BarLabPreset.waterfall) {
        if (categoryIndex == _categories.length - 1) return 0;
        if (categoryIndex == 0) return (70 + seed % 20).toDouble();
        final magnitude = (6 + seed % 24).toDouble();
        return categoryIndex == 3 || categoryIndex == 4
            ? -magnitude
            : magnitude;
      }
      if (_preset == _BarLabPreset.horizontal) {
        return (30 + seed % 70).toDouble();
      }
      if (_preset == _BarLabPreset.bullet) {
        return (48 + seed % 47).toDouble();
      }
      if (_preset == _BarLabPreset.axes) {
        return switch (seriesIndex % 4) {
          0 => (36 + seed % 64).toDouble(),
          1 => (180 + seed * 7 % 270).toDouble(),
          2 => (58 + seed % 34).toDouble(),
          _ => (18 + seed % 24).toDouble(),
        };
      }
      if (_preset == _BarLabPreset.labels) {
        return (82 + seed % 15).toDouble();
      }
      return (24 + seed % 73).toDouble();
    }, growable: false);
  }

  List<double> _motionValues(List<double> values) {
    if (_preset != _BarLabPreset.motion || _motionIncludeSunday) return values;
    return values.sublist(0, values.length - 1);
  }

  ({
    String name,
    String axisLabel,
    String unit,
    YAxisPosition position,
    double max,
  })
  _axisMetric(int seriesIndex) {
    final cycle = seriesIndex ~/ 4;
    final metric = switch (seriesIndex % 4) {
      0 => (
        name: 'Revenue',
        axisLabel: 'Revenue',
        unit: r'$k',
        position: YAxisPosition.left,
        max: 110.0,
      ),
      1 => (
        name: 'Orders',
        axisLabel: 'Orders',
        unit: 'orders',
        position: YAxisPosition.right,
        max: 500.0,
      ),
      2 => (
        name: 'Conversion',
        axisLabel: 'Conversion',
        unit: '%',
        position: YAxisPosition.right,
        max: 100.0,
      ),
      _ => (
        name: 'Margin',
        axisLabel: 'Margin',
        unit: '%',
        position: YAxisPosition.left,
        max: 50.0,
      ),
    };
    if (cycle == 0) return metric;
    return (
      name: '${metric.name} ${cycle + 1}',
      axisLabel: '${metric.axisLabel} ${cycle + 1}',
      unit: metric.unit,
      position: metric.position,
      max: metric.max,
    );
  }

  BarChartSeries _series({
    required String id,
    required String name,
    required List<double> values,
    required Color color,
    required List<Color> gradientColors,
    required Color trackColor,
  }) {
    final seriesIndex = int.parse(id.split('-').last) - 1;
    final groupCount = _effectiveGroupCount;
    final groupIndex = seriesIndex % groupCount;
    final overlayLayer = seriesIndex ~/ groupCount;
    final overlayLayerCount =
        ((_seriesCount - 1 - groupIndex) ~/ groupCount) + 1;
    final overlayWidthFactor = (1 - overlayLayer * _overlayWidthStep / 100)
        .clamp(0.2, 1.0);
    final overlayOffsetFactor =
        (overlayLayer - (overlayLayerCount - 1) / 2) * _overlayOffsetStep / 100;
    final isFrontOverlayLayer = seriesIndex + groupCount >= _seriesCount;
    final rangeStartValues = _rangeStartsForSeries(seriesIndex, values);
    final axisMetric = _preset == _BarLabPreset.axes
        ? _axisMetric(seriesIndex)
        : null;
    return BarChartSeries(
      id: id,
      name: name,
      points: [
        for (var index = 0; index < values.length; index++)
          ChartDataPoint(
            x: index.toDouble(),
            y: values[index],
            label: _categories[index],
            pointStyle: _preset == _BarLabPreset.offset && seriesIndex == 1
                ? PointStyle.color(_medalColors[index])
                : null,
          ),
      ],
      color: color,
      unit:
          _preset == _BarLabPreset.bullet ||
              _preset == _BarLabPreset.likert ||
              _preset == _BarLabPreset.lollipop ||
              _preset == _BarLabPreset.targets ||
              _preset == _BarLabPreset.uncertainty
          ? '%'
          : _preset == _BarLabPreset.signed
          ? '%'
          : _preset == _BarLabPreset.range
          ? '°C'
          : axisMetric?.unit,
      yAxisConfig: axisMetric == null
          ? null
          : YAxisConfig(
              position: axisMetric.position,
              color: color,
              label: axisMetric.axisLabel,
              unit: axisMetric.unit,
              min: 0,
              max: axisMetric.max,
              tickCount: 5,
              showCrosshairLabel: true,
            ),
      barWidthPercent: _barWidth,
      barGap: _barGap,
      orientation: _orientation,
      overlayWidthFactor: _layoutMode == BarLayoutMode.overlaid
          ? overlayWidthFactor
          : 1,
      overlayOffsetFactor: _layoutMode == BarLayoutMode.overlaid
          ? overlayOffsetFactor
          : 0,
      rangeStartValues: rangeStartValues,
      waterfallTotalIndices: _preset == _BarLabPreset.waterfall
          ? {_categories.length - 1}
          : const {},
      waterfallStyle: BarWaterfallStyle(
        increaseColor: const Color(0xFF168AAD),
        decreaseColor: const Color(0xFFE15B64),
        totalColor: const Color(0xFF5149C6),
        connector: BarWaterfallConnectorStyle(
          show: _showConnectors,
          color: const Color(0xFF9CA3AF),
          width: 1.25,
        ),
      ),
      minBarLength: 4,
      barStyle: BarChartStyle(
        animationMode: _animateBars
            ? BarAnimationMode.grow
            : BarAnimationMode.none,
        cornerRadius: _cornerRadius,
        cornerRadiusPolicy: _cornerPolicy,
        gradient: _showGradient ? BarGradient(colors: gradientColors) : null,
        pattern: _preset == _BarLabPreset.patterns && _showPatterns
            ? BarPatternStyle(
                pattern: BarFillPattern
                    .values[seriesIndex % BarFillPattern.values.length],
                spacing: _patternSpacing,
                strokeWidth: _patternStrokeWidth,
                opacity: _patternOpacity,
              )
            : null,
        border: _showBorder
            ? BarBorderStyle(color: color.withValues(alpha: 0.9), width: 1.5)
            : null,
        interaction: BarInteractionStyle(dimmedOpacity: _dimmedOpacity),
        motion: BarMotionStyle(
          order: _motionOrder,
          staggerFraction: _motionStagger,
        ),
      ),
      trackStyle: _showTracks
          ? BarTrackStyle(
              color: trackColor,
              value: _preset == _BarLabPreset.signed
                  ? null
                  : _preset == _BarLabPreset.range
                  ? 34
                  : 100,
              cornerRadius: _cornerRadius,
            )
          : null,
      lollipopStyle: _preset == _BarLabPreset.lollipop
          ? BarLollipopStyle(
              stemWidth: _lollipopStemWidth,
              headRadius: _lollipopHeadRadius,
              stemColor: Color.lerp(color, Colors.white, 0.28),
              headColor: color,
            )
          : null,
      bulletStyle: _preset == _BarLabPreset.bullet
          ? BarBulletStyle(
              ranges: _bulletRanges,
              measureThicknessFactor: _bulletMeasureThickness,
              cornerRadius: _bulletRangeRadius,
            )
          : null,
      targetValues: _showTargets
          ? _targetValuesForSeries(seriesIndex)
          : const [],
      targetMarkerStyle: BarTargetMarkerStyle(
        color: _preset == _BarLabPreset.bullet ? const Color(0xFF111827) : null,
        width: _targetMarkerWidth,
        lengthFactor: _targetMarkerLength,
      ),
      errorLowerValues: _showUncertainty
          ? _errorLowerValuesForSeries(seriesIndex, values)
          : const [],
      errorUpperValues: _showUncertainty
          ? _errorUpperValuesForSeries(seriesIndex, values)
          : const [],
      errorBarStyle: BarErrorBarStyle(
        width: _errorBarWidth,
        capLengthFactor: _errorCapLength,
      ),
      labelStyle: BarLabelStyle(
        show:
            _showLabels &&
            (_layoutMode != BarLayoutMode.overlaid || isFrontOverlayLayer),
        position: _labelPosition,
        valueMode:
            _layoutMode == BarLayoutMode.normalizedStacked ||
                _layoutMode == BarLayoutMode.divergingStacked
            ? BarLabelValueMode.percentage
            : _preset == _BarLabPreset.range
            ? BarLabelValueMode.range
            : _preset == _BarLabPreset.waterfall
            ? BarLabelValueMode.waterfall
            : BarLabelValueMode.value,
        showUnit:
            _preset == _BarLabPreset.signed ||
            _preset == _BarLabPreset.range ||
            _preset == _BarLabPreset.axes,
        padding: _labelEdgeOffset,
        collisionPolicy: _labelCollisionPolicy,
        plotEdgeAware: _labelPlotEdgeAware,
        collisionPadding: _labelCollisionPadding,
        backgroundColor: _showLabelBackground ? const Color(0xEEFFFFFF) : null,
        borderColor: _showLabelBackground
            ? color.withValues(alpha: 0.38)
            : null,
        borderWidth: _showLabelBackground ? 1 : 0,
        borderRadius: 4,
        backgroundPadding: 3,
        callout: BarLabelCalloutStyle(
          show: _showLabelCallouts,
          color: color.withValues(alpha: 0.7),
          width: 1,
          minimumLength: 4,
        ),
        showStackTotal: _showStackTotals,
      ),
      layoutMode: _layoutMode,
      divergingRole: _divergingRoleForIndex(seriesIndex),
      divergingStyle: BarDivergingStyle(
        showCenterLine: _showDivergingCenterLine,
        centerLineWidth: _divergingCenterLineWidth,
      ),
      groupId:
          _layoutMode == BarLayoutMode.overlaid ||
              _layoutMode == BarLayoutMode.stacked ||
              _layoutMode == BarLayoutMode.normalizedStacked ||
              _layoutMode == BarLayoutMode.divergingStacked
          ? 'group-${seriesIndex % groupCount}'
          : null,
    );
  }

  BarDivergingRole _divergingRoleForIndex(int index) {
    if (_layoutMode != BarLayoutMode.divergingStacked) {
      return BarDivergingRole.positive;
    }
    final midpoint = _seriesCount ~/ 2;
    if (_seriesCount.isOdd && index == midpoint) {
      return BarDivergingRole.neutral;
    }
    return index < _seriesCount / 2
        ? BarDivergingRole.negative
        : BarDivergingRole.positive;
  }

  String _likertSeriesName(int index) {
    if (_seriesCount == 5) {
      return const [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree',
      ][index];
    }
    return switch (_divergingRoleForIndex(index)) {
      BarDivergingRole.negative => 'Negative ${index + 1}',
      BarDivergingRole.neutral => 'Neutral',
      BarDivergingRole.positive => 'Positive ${index + 1}',
    };
  }

  List<double?> _rangeStartsForSeries(int seriesIndex, List<double> values) {
    if (_preset != _BarLabPreset.range) return const [];
    if (seriesIndex == 0) return const [14, 17, 15, 19, 16, 13, 14];
    if (seriesIndex == 1) return const [12, 16, 18, 17, 15, 14, 17];
    return [
      for (var index = 0; index < values.length; index++)
        values[index] - 8 - ((seriesIndex + index) % 4),
    ];
  }

  List<double?> _targetValuesForSeries(int seriesIndex) {
    final baseTargets = _preset == _BarLabPreset.bullet
        ? const <double>[88, 70, 85, 78, 65, 90]
        : const <double>[72, 78, 85, 68, 84, 95, 76];
    return [
      for (var index = 0; index < _categories.length; index++)
        (baseTargets[index] + seriesIndex * 3).clamp(0, 100).toDouble(),
    ];
  }

  List<BarBulletRange> get _bulletRanges {
    return switch (_bulletRangeCount) {
      2 => const [
        BarBulletRange(
          endValue: 65,
          color: Color(0xFFE2E8F0),
          label: 'Needs attention',
        ),
        BarBulletRange(
          endValue: 100,
          color: Color(0xFF94A3B8),
          label: 'On track',
        ),
      ],
      4 => const [
        BarBulletRange(
          endValue: 55,
          color: Color(0xFFE2E8F0),
          label: 'Needs attention',
        ),
        BarBulletRange(
          endValue: 75,
          color: Color(0xFFCBD5E1),
          label: 'On track',
        ),
        BarBulletRange(
          endValue: 100,
          color: Color(0xFF94A3B8),
          label: 'Strong',
        ),
        BarBulletRange(
          endValue: 115,
          color: Color(0xFF64748B),
          label: 'Stretch',
        ),
      ],
      _ => const [
        BarBulletRange(
          endValue: 55,
          color: Color(0xFFE2E8F0),
          label: 'Needs attention',
        ),
        BarBulletRange(
          endValue: 75,
          color: Color(0xFFCBD5E1),
          label: 'On track',
        ),
        BarBulletRange(
          endValue: 100,
          color: Color(0xFF94A3B8),
          label: 'Strong',
        ),
      ],
    };
  }

  List<double?> _errorLowerValuesForSeries(
    int seriesIndex,
    List<double> values,
  ) => [
    for (var index = 0; index < values.length; index++)
      values[index] - 4 - ((seriesIndex + index) % 4),
  ];

  List<double?> _errorUpperValuesForSeries(
    int seriesIndex,
    List<double> values,
  ) => [
    for (var index = 0; index < values.length; index++)
      values[index] + 5 + ((seriesIndex + index * 2) % 5),
  ];

  int get _effectiveGroupCount => _stackGroupCount.clamp(1, _seriesCount);

  bool _supportsLayout(_BarLabPreset preset, BarLayoutMode mode) {
    if (preset == _BarLabPreset.waterfall) {
      return mode == BarLayoutMode.waterfall;
    }
    if (mode == BarLayoutMode.waterfall) return false;
    if (preset == _BarLabPreset.bullet) {
      return mode == BarLayoutMode.grouped;
    }
    if (preset == _BarLabPreset.lollipop) {
      return mode == BarLayoutMode.grouped || mode == BarLayoutMode.overlaid;
    }
    if (preset == _BarLabPreset.pareto) {
      return mode == BarLayoutMode.grouped;
    }
    if (preset == _BarLabPreset.histogram) {
      return mode == BarLayoutMode.grouped;
    }
    if (preset == _BarLabPreset.likert) {
      return mode == BarLayoutMode.divergingStacked;
    }
    if (mode == BarLayoutMode.divergingStacked) return false;
    return preset != _BarLabPreset.range ||
        mode == BarLayoutMode.grouped ||
        mode == BarLayoutMode.overlaid;
  }

  List<String> get _categories => switch (_preset) {
    _BarLabPreset.offset => _medalCategories,
    _BarLabPreset.bullet => _channelCategories,
    _BarLabPreset.likert => _likertCategories,
    _BarLabPreset.pareto => [
      for (final category in _paretoData.categories) category.label,
    ],
    _BarLabPreset.histogram => [
      for (final bin in _histogramData.bins) bin.label,
    ],
    _BarLabPreset.rtl => _rtlCategories,
    _BarLabPreset.waterfall => _waterfallCategories,
    _BarLabPreset.horizontal => _channelCategories,
    _BarLabPreset.axes => _channelCategories,
    _BarLabPreset.categories => _denseCategories,
    _ => _dayCategories,
  };

  bool get _usesNativeCategoryAxis =>
      _preset == _BarLabPreset.categories ||
      _preset == _BarLabPreset.pareto ||
      _preset == _BarLabPreset.histogram ||
      _preset == _BarLabPreset.rtl;

  void _applyPreset(_BarLabPreset preset) {
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    setState(() {
      _preset = preset;
      _setPresetValues(preset);
    });
  }

  void _setPresetValues(_BarLabPreset preset) {
    _showBorder = false;
    _showConnectors = true;
    _dimmedOpacity = 0.42;
    _overlayWidthStep = 22;
    _overlayOffsetStep = 0;
    _labelPosition = BarLabelPosition.auto;
    _labelEdgeOffset = 8;
    _orientation = BarOrientation.vertical;
    _motionRevision = 0;
    _motionDurationMs = 650;
    _motionOrder = BarAnimationOrder.together;
    _motionStagger = 0;
    _animateBars = true;
    _motionIncludeSunday = true;
    _motionIncludeForecast = true;
    _showTargets = false;
    _targetMarkerWidth = 2;
    _targetMarkerLength = 1.3;
    _showUncertainty = false;
    _errorBarWidth = 1.5;
    _errorCapLength = 0.6;
    _lollipopStemWidth = 3;
    _lollipopHeadRadius = 8;
    _paretoLineWidth = 3;
    _showParetoMarkers = true;
    _showParetoCumulativeLabels = false;
    _histogramMethod = HistogramBinningMethod.freedmanDiaconis;
    _histogramBinCount = 8;
    _histogramValueMode = HistogramValueMode.count;
    _labelCollisionPolicy = BarLabelCollisionPolicy.none;
    _labelPlotEdgeAware = true;
    _labelCollisionPadding = 2;
    _showLabelBackground = false;
    _showLabelCallouts = false;
    _showStackTotals = false;
    _showPatterns = true;
    _patternSpacing = 8;
    _patternStrokeWidth = 1.5;
    _patternOpacity = 0.58;
    _bulletRangeCount = 3;
    _bulletMeasureThickness = 0.42;
    _bulletRangeRadius = 4;
    _showDivergingCenterLine = true;
    _divergingCenterLineWidth = 1.25;
    switch (preset) {
      case _BarLabPreset.capacity:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.72;
        _barGap = 4;
        _cornerRadius = 6;
        _showTracks = true;
        _showGradient = false;
        _showLabels = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.bullet:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.34;
        _barGap = 10;
        _cornerRadius = 2;
        _showTracks = false;
        _showTargets = true;
        _targetMarkerWidth = 2.5;
        _targetMarkerLength = 2.2;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.likert:
        _seriesCount = 5;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.divergingStacked;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.68;
        _barGap = 4;
        _cornerRadius = 3;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _labelCollisionPolicy = BarLabelCollisionPolicy.hide;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.targets:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.52;
        _barGap = 6;
        _cornerRadius = 5;
        _showTracks = true;
        _showTargets = true;
        _showGradient = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.uncertainty:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.46;
        _barGap = 8;
        _cornerRadius = 5;
        _showTracks = false;
        _showUncertainty = true;
        _showGradient = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.lollipop:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.48;
        _barGap = 12;
        _cornerRadius = 0;
        _showTracks = false;
        _showGradient = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.pareto:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.62;
        _barGap = 8;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _labelEdgeOffset = 6;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.histogram:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 1;
        _barGap = 0;
        _cornerRadius = 0;
        _showTracks = false;
        _showGradient = false;
        _showBorder = true;
        _showLabels = false;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.rtl:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.68;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _categoryLabelDensity = CategoryLabelDensity.showAll;
        _categoryLabelOverflow = CategoryLabelOverflow.wrap;
        _categoryMinimumExtent = 64;
        _categoryMaxLines = 2;
        _categoryRotation = 0;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.rods:
        _seriesCount = 3;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.34;
        _barGap = 10;
        _cornerRadius = 32;
        _showTracks = false;
        _showGradient = false;
        _showLabels = false;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.gradient:
        _seriesCount = 4;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.68;
        _barGap = 4;
        _cornerRadius = 10;
        _showTracks = false;
        _showGradient = true;
        _showLabels = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.signed:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.68;
        _barGap = 4;
        _cornerRadius = 7;
        _showTracks = false;
        _showGradient = false;
        _showLabels = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.overlay:
        _seriesCount = 4;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.overlaid;
        _barWidth = 0.72;
        _barGap = 4;
        _overlayWidthStep = 22;
        _cornerRadius = 6;
        _showTracks = true;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.auto;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.offset:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.overlaid;
        _barWidth = 0.68;
        _barGap = 4;
        _overlayWidthStep = 0;
        _overlayOffsetStep = 30;
        _cornerRadius = 2;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.range:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.64;
        _barGap = 8;
        _cornerRadius = 8;
        _showTracks = false;
        _showGradient = true;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.rangeEnds;
        _cornerPolicy = BarCornerRadiusPolicy.all;
      case _BarLabPreset.waterfall:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.waterfall;
        _barWidth = 0.62;
        _barGap = 4;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _showConnectors = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.horizontal:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.72;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.axes:
        _seriesCount = 4;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.76;
        _barGap = 4;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.categories:
        _seriesCount = 3;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.74;
        _barGap = 5;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = false;
        _categoryLabelDensity = CategoryLabelDensity.auto;
        _categoryLabelOverflow = CategoryLabelOverflow.wrap;
        _categoryMinimumExtent = 72;
        _categoryMaxLines = 2;
        _categoryRotation = 0;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.labels:
        _seriesCount = 6;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.88;
        _barGap = 1;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _labelEdgeOffset = 6;
        _labelCollisionPolicy = BarLabelCollisionPolicy.reposition;
        _labelCollisionPadding = 3;
        _showLabelBackground = true;
        _showLabelCallouts = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.config:
        _seriesCount = 3;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.78;
        _barGap = 5;
        _cornerRadius = 7;
        _showTracks = true;
        _showGradient = true;
        _showBorder = true;
        _showLabels = true;
        _showTargets = true;
        _showUncertainty = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _labelEdgeOffset = 6;
        _labelCollisionPolicy = BarLabelCollisionPolicy.reposition;
        _labelCollisionPadding = 3;
        _showLabelBackground = true;
        _showLabelCallouts = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.patterns:
        _seriesCount = 4;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.76;
        _barGap = 5;
        _cornerRadius = 5;
        _showTracks = false;
        _showGradient = false;
        _showBorder = true;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.motion:
        _seriesCount = 2;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.7;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
        _motionOrder = BarAnimationOrder.forward;
        _motionStagger = 0.45;
      case _BarLabPreset.states:
        _seriesCount = 3;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _barWidth = 0.7;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _dimmedOpacity = 0.32;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.stacked:
        _seriesCount = 6;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.stacked;
        _barWidth = 0.78;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _labelCollisionPolicy = BarLabelCollisionPolicy.reposition;
        _showStackTotals = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.normalized:
        _seriesCount = 6;
        _stackGroupCount = 2;
        _layoutMode = BarLayoutMode.normalizedStacked;
        _barWidth = 0.78;
        _barGap = 6;
        _cornerRadius = 6;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _labelCollisionPolicy = BarLabelCollisionPolicy.reposition;
        _showStackTotals = true;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
    }
  }

  void _resetPreset() => _applyPreset(_preset);

  String _categoryLabel(double value) {
    final index = value.round();
    if (index < 0 || index >= _categories.length) return '';
    return _categories[index];
  }

  String _presetTitle() => switch (_preset) {
    _BarLabPreset.capacity => 'Progress against capacity',
    _BarLabPreset.bullet => 'Delivery against target',
    _BarLabPreset.likert => 'Product experience survey',
    _BarLabPreset.targets => 'Actual against target',
    _BarLabPreset.uncertainty => 'Estimate with uncertainty',
    _BarLabPreset.lollipop => 'Weekly activation score',
    _BarLabPreset.pareto => 'Support issues by cause',
    _BarLabPreset.histogram => 'Support response-time distribution',
    _BarLabPreset.rtl => 'الإيرادات حسب القناة',
    _BarLabPreset.rods => 'Compact rounded rods',
    _BarLabPreset.gradient => 'Value-axis gradients',
    _BarLabPreset.signed => 'Positive and negative values',
    _BarLabPreset.overlay => 'Layered comparisons',
    _BarLabPreset.offset => 'Offset comparisons',
    _BarLabPreset.range => 'Floating temperature ranges',
    _BarLabPreset.waterfall => 'Cash-flow bridge',
    _BarLabPreset.horizontal => 'Revenue by channel',
    _BarLabPreset.axes => 'Independent channel metrics',
    _BarLabPreset.categories => 'Dense categorical comparison',
    _BarLabPreset.labels => 'Collision-aware value labels',
    _BarLabPreset.config => 'Tool-configured analytical bars',
    _BarLabPreset.patterns => 'Pattern-coded comparisons',
    _BarLabPreset.motion => 'Keyed lifecycle motion',
    _BarLabPreset.states => 'Interactive bar states',
    _BarLabPreset.stacked => 'Named stacked totals',
    _BarLabPreset.normalized => '100% stacked composition',
  };

  String _presetDescription() => switch (_preset) {
    _BarLabPreset.capacity =>
      'Tracks reveal remaining capacity without adding another data series.',
    _BarLabPreset.bullet =>
      'Qualitative ranges, an actual measure, and a target marker share one compact comparison without synthetic series.',
    _BarLabPreset.likert =>
      'Negative and positive response shares diverge from one centered neutral segment while source values stay intact.',
    _BarLabPreset.targets =>
      'Benchmarks remain distinct from actual values without becoming another series.',
    _BarLabPreset.uncertainty =>
      'Whiskers expose absolute lower and upper bounds without becoming interactive series.',
    _BarLabPreset.lollipop =>
      'Slim stems preserve a common baseline while circular markers make exact values easy to compare.',
    _BarLabPreset.pareto =>
      'Categories rank by frequency while the line reveals their cumulative share.',
    _BarLabPreset.histogram =>
      'Continuous response times become equal-width intervals without changing the bar renderer.',
    _BarLabPreset.rtl =>
      'Arabic categories, value labels, tooltips, crosshairs, and semantics inherit one right-to-left reading direction.',
    _BarLabPreset.rods =>
      'Narrow bars and full rounding create a compact dashboard treatment.',
    _BarLabPreset.gradient =>
      'Gradients follow each bar from its baseline to its value end.',
    _BarLabPreset.signed =>
      'Negative values use the same geometry and round away from the baseline.',
    _BarLabPreset.overlay =>
      'Wide reference bars remain visible behind narrower comparison layers.',
    _BarLabPreset.offset =>
      'Equal-width results shift left and right for a compact reference comparison.',
    _BarLabPreset.range =>
      'Each bar spans an explicit start and end instead of growing from zero.',
    _BarLabPreset.waterfall =>
      'Sequential increases and decreases bridge the opening value to a resolved total.',
    _BarLabPreset.horizontal =>
      'Horizontal ranking gives category names room while values remain easy to compare.',
    _BarLabPreset.axes =>
      'Independent value axes stack above and below one shared category plot.',
    _BarLabPreset.categories =>
      'A native category domain wraps, thins, scrolls, and persists long labels without a formatter callback.',
    _BarLabPreset.labels =>
      'Labels share one chart-wide layout pass, fall back inside the bar, and can use restrained boxes or callouts.',
    _BarLabPreset.config =>
      'Every visible series, category, benchmark, uncertainty interval, style, and label is rebuilt from the public tool JSON contract.',
    _BarLabPreset.patterns =>
      'Line direction pairs with one shared hue so every series remains identifiable in monochrome.',
    _BarLabPreset.motion =>
      'Replay value changes or remove keyed points and series through the same geometry used for labels and interaction.',
    _BarLabPreset.states =>
      'Hover, press, click, or use the arrow keys and Enter to inspect every state.',
    _BarLabPreset.stacked =>
      'Two named stacks compare totals while preserving every contribution.',
    _BarLabPreset.normalized =>
      'Each named stack resolves to 100% while tooltips retain raw values.',
  };

  String _chartSummary() {
    final features = <String>[
      '$_seriesCount series',
      _orientation.name,
      _layoutMode == BarLayoutMode.grouped
          ? 'grouped'
          : _layoutMode == BarLayoutMode.overlaid
          ? 'overlaid · $_effectiveGroupCount ${_effectiveGroupCount == 1 ? 'group' : 'groups'}'
          : _layoutMode == BarLayoutMode.waterfall
          ? 'waterfall'
          : '${_layoutLabel(_layoutMode).toLowerCase()} · $_effectiveGroupCount ${_effectiveGroupCount == 1 ? 'stack' : 'stacks'}',
      '${(_barWidth * 100).round()}% category fill',
      if (_showTracks) 'capacity tracks',
      if (_preset == _BarLabPreset.bullet)
        '$_bulletRangeCount qualitative ranges',
      if (_preset == _BarLabPreset.likert) 'centered neutral response',
      if (_showTargets) 'benchmark markers',
      if (_showUncertainty) 'uncertainty whiskers',
      if (_preset == _BarLabPreset.lollipop) 'stem and marker values',
      if (_preset == _BarLabPreset.pareto)
        '${_paretoData.categories.length} ranked causes',
      if (_preset == _BarLabPreset.pareto)
        '80% reached by ${(_paretoData.firstIndexAtOrAbove(80) ?? -1) + 1} causes',
      if (_preset == _BarLabPreset.histogram)
        '${_histogramData.sampleCount} samples',
      if (_preset == _BarLabPreset.histogram)
        '${_histogramData.bins.length} bins · ${_histogramMethodLabel(_histogramMethod).toLowerCase()}',
      if (_preset == _BarLabPreset.histogram) _histogramValueMode.name,
      if (_preset == _BarLabPreset.rtl) 'right-to-left text',
      if (_showGradient) 'gradient fill',
      if (_preset == _BarLabPreset.range) 'floating ranges',
      if (_preset == _BarLabPreset.waterfall) 'cumulative bridge',
      if (_preset == _BarLabPreset.waterfall && _showConnectors) 'connectors',
      if (_preset == _BarLabPreset.axes) 'independent value axes',
      if (_preset == _BarLabPreset.categories)
        '${_categories.length} native categories',
      if (_preset == _BarLabPreset.config) 'public tool JSON',
      if (_preset == _BarLabPreset.patterns && _showPatterns)
        '$_seriesCount pattern encodings',
      if (_showLabels && _labelCollisionPolicy != BarLabelCollisionPolicy.none)
        '${_labelCollisionPolicy.name} collisions',
      if (_showStackTotals) 'stack totals',
      if (_preset == _BarLabPreset.motion && _animateBars)
        '${_motionOrderLabel(_motionOrder).toLowerCase()} · ${(_motionStagger * 100).round()}% stagger · ${_motionDurationMs.round()}ms',
      if (_preset == _BarLabPreset.motion && !_motionIncludeSunday)
        'Sunday exiting',
      if (_preset == _BarLabPreset.motion && !_motionIncludeForecast)
        'forecast exiting',
      if (_preset == _BarLabPreset.states)
        '${_chartController.selectedPointRefs.length} selected',
      if (_showLabels)
        _layoutMode == BarLayoutMode.overlaid
            ? 'front-layer ${_labelPosition.name} labels'
            : '${_labelPosition.name} labels',
    ];
    return features.join(' · ');
  }

  String _layoutLabel(BarLayoutMode mode) => switch (mode) {
    BarLayoutMode.grouped => 'Grouped',
    BarLayoutMode.overlaid => 'Overlaid',
    BarLayoutMode.stacked => 'Stacked',
    BarLayoutMode.normalizedStacked => '100% stacked',
    BarLayoutMode.divergingStacked => 'Diverging',
    BarLayoutMode.waterfall => 'Waterfall',
  };

  String _histogramMethodLabel(HistogramBinningMethod method) =>
      switch (method) {
        HistogramBinningMethod.freedmanDiaconis => 'Freedman–Diaconis',
        HistogramBinningMethod.sturges => 'Sturges',
        HistogramBinningMethod.squareRoot => 'Square root',
        HistogramBinningMethod.fixedCount => 'Fixed count',
      };

  String _motionOrderLabel(BarAnimationOrder order) => switch (order) {
    BarAnimationOrder.together => 'Together',
    BarAnimationOrder.forward => 'First to last',
    BarAnimationOrder.reverse => 'Last to first',
    BarAnimationOrder.centerOut => 'Center out',
    BarAnimationOrder.edgesIn => 'Edges in',
  };
}

class _BarLabLegendItem extends StatelessWidget {
  const _BarLabLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
