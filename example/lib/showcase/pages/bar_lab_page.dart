// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';
import '../widgets/persistent_resizable_chart_panel.dart';
import '../widgets/showcase_randomizer.dart';
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
  stress,
  labels,
  rotatedLabels,
  drilldown,
  race,
  config,
  patterns,
  motion,
  states,
  stacked,
  normalized,
}

enum _BarDrillDataset { nutrition, regions }

enum _BarRacePeriodPreset {
  authoredLabel,
  monthYearLong,
  monthYearShort,
  year,
  isoMonth,
  custom,
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
    _BarLabPreset.stress => 'Stress',
    _BarLabPreset.labels => 'Labels',
    _BarLabPreset.rotatedLabels => 'Rotated labels',
    _BarLabPreset.drilldown => 'Drill-down',
    _BarLabPreset.race => 'Race',
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
    _BarLabPreset.stress => Icons.speed,
    _BarLabPreset.labels => Icons.label_outline,
    _BarLabPreset.rotatedLabels => Icons.text_rotate_vertical,
    _BarLabPreset.drilldown => Icons.account_tree_outlined,
    _BarLabPreset.race => Icons.play_circle_outline,
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
  static const String _raceDefaultFrameId = '2006-12';

  static const _categoryFormatterId = 'braven.showcase.bar-category';
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final ChartInteractionGroupController _interactionGroupController =
      ChartInteractionGroupController();
  late final ShowcaseRandomizerController<int> _showcaseRandomizer;
  late final BarDrilldownController _drilldownController;
  late final BarRaceController _raceController;
  static const _dayCategories = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _cityCategories = [
    'Tokyo',
    'Delhi',
    'Shanghai',
    'São Paulo',
    'Mexico City',
    'Dhaka',
    'Cairo',
    'Beijing',
    'Mumbai',
    'Osaka',
    'Karachi',
    'Chongqing',
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
  static final _stressCategories = List<String>.unmodifiable([
    for (var index = 0; index < 10000; index++)
      'Region ${(index + 1).toString().padLeft(2, '0')} · '
          'Segment ${String.fromCharCode(65 + index % 6)}',
  ]);
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
  _BarLabPreset _authoredPreset = _BarLabPreset.capacity;
  bool _playgroundActive = false;
  int _seriesCount = 2;
  int _stackGroupCount = 1;
  BarLayoutMode _layoutMode = BarLayoutMode.grouped;
  BarOrientation _orientation = BarOrientation.vertical;
  ChartSelectionScope _selectionScope = ChartSelectionScope.mark;
  bool _showDataPointPopup = true;
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
  BarLabelRotationMode _labelRotationMode = BarLabelRotationMode.fixed;
  double _labelRotationDegrees = 0;
  double _labelEdgeOffset = 8;
  double _dimmedOpacity = 0.42;
  int _motionRevision = 0;
  List<double> _playgroundValues = const [54, 72, 61, 88, 69, 94, 76];
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
  int _stressCategoryCount = 48;
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
  bool _drillShowBreadcrumbs = true;
  BarDrillActivation _drillActivation = BarDrillActivation.primaryAction;
  BarDrillTransition _drillTransition = BarDrillTransition.fadeThrough;
  BarDrillSelectionPolicy _drillSelectionPolicy = BarDrillSelectionPolicy.clear;
  _BarDrillDataset _drillDataset = _BarDrillDataset.nutrition;
  int _drillLazyDelayMs = 600;
  bool _drillSimulateFailure = false;

  @override
  void initState() {
    super.initState();
    _drilldownController = BarDrilldownController(
      config: BarDrilldownConfig(
        root: _buildDrillHierarchy(),
        lazyResolverBinding: 'showcase.resolveNutritionDetails',
      ),
      resolver: _resolveDrillChildren,
    )..addListener(_onDrilldownChanged);
    _raceController = BarRaceController(config: _buildPopulationRaceConfig());
    _seekRaceToDefaultFrame();
    _raceController.addListener(_onRaceChanged);
    _showcaseRandomizer = ShowcaseRandomizerController<int>(
      initialSeed: 101,
      generate: (seed) => seed,
      apply: _applyRandomSeed,
    );
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
    _authoredPreset = _preset;
  }

  @override
  void dispose() {
    _showcaseRandomizer.dispose();
    _chartController
      ..removeListener(_onChartInteractionChanged)
      ..dispose();
    _workbenchController.dispose();
    _interactionGroupController.dispose();
    _drilldownController
      ..removeListener(_onDrilldownChanged)
      ..dispose();
    _raceController
      ..removeListener(_onRaceChanged)
      ..dispose();
    super.dispose();
  }

  void _onDrilldownChanged() {
    if (!mounted) return;
    if (_drillSelectionPolicy == BarDrillSelectionPolicy.clear) {
      _chartController.clearPointSelection();
    }
    setState(() {});
  }

  void _onRaceChanged() {
    if (mounted) setState(() {});
  }

  void _replaceDrillHierarchy() {
    _drilldownController.replaceConfig(
      BarDrilldownConfig(
        root: _buildDrillHierarchy(),
        activation: _drillActivation,
        transition: _drillTransition,
        showBreadcrumbs: _drillShowBreadcrumbs,
        selectionPolicy: _drillSelectionPolicy,
        lazyResolverBinding: _drillDataset == _BarDrillDataset.nutrition
            ? 'showcase.resolveNutritionDetails'
            : null,
      ),
    );
  }

  void _onChartInteractionChanged() {
    if (mounted && _preset == _BarLabPreset.states) setState(() {});
  }

  void _applyRandomSeed(int seed) {
    if (!mounted) return;
    final random = math.Random(seed);
    setState(() {
      _playgroundValues = List<double>.generate(
        _categories.length,
        (_) => 12 + random.nextDouble() * 88,
        growable: false,
      );
      _seriesCount = 1 + random.nextInt(6);
      _stackGroupCount = 1 + random.nextInt(_seriesCount);
      _layoutMode = const [
        BarLayoutMode.grouped,
        BarLayoutMode.overlaid,
        BarLayoutMode.stacked,
        BarLayoutMode.normalizedStacked,
      ][random.nextInt(4)];
      _orientation =
          BarOrientation.values[random.nextInt(BarOrientation.values.length)];
      _barWidth = 0.48 + random.nextDouble() * 0.46;
      _barGap = random.nextDouble() * 10;
      _overlayWidthStep = random.nextDouble() * 42;
      _overlayOffsetStep = -20 + random.nextDouble() * 40;
      _cornerRadius = random.nextDouble() * 14;
      _cornerPolicy = BarCornerRadiusPolicy
          .values[random.nextInt(BarCornerRadiusPolicy.values.length)];
      _showGradient = random.nextBool();
      _showBorder = random.nextBool();
      _showLabels = random.nextBool();
      _showConnectors = random.nextBool();
      _labelPosition = BarLabelPosition
          .values[random.nextInt(BarLabelPosition.values.length)];
      _labelRotationMode = BarLabelRotationMode
          .values[random.nextInt(BarLabelRotationMode.values.length)];
      _labelRotationDegrees = [
        -90.0,
        -45.0,
        0.0,
        45.0,
        90.0,
      ][random.nextInt(5)];
      _labelEdgeOffset = 2 + random.nextDouble() * 14;
      _showTracks = random.nextBool();
      _showDataPointPopup = random.nextBool();
      _dimmedOpacity = 0.2 + random.nextDouble() * 0.55;
      _categoryLabelDensity = CategoryLabelDensity
          .values[random.nextInt(CategoryLabelDensity.values.length)];
      _categoryLabelOverflow = CategoryLabelOverflow
          .values[random.nextInt(CategoryLabelOverflow.values.length)];
      _animateBars = random.nextBool();
      _motionDurationMs = 250 + random.nextDouble() * 950;
      _motionOrder = BarAnimationOrder
          .values[random.nextInt(BarAnimationOrder.values.length)];
      _motionStagger = random.nextDouble() * 0.7;
      _motionIncludeSunday = random.nextBool();
      _motionIncludeForecast = random.nextBool();
      _showTargets = random.nextBool();
      _targetMarkerWidth = 0.5 + random.nextDouble() * 3.5;
      _targetMarkerLength = 0.5 + random.nextDouble() * 1.5;
      _showUncertainty = random.nextBool();
      _errorBarWidth = 0.5 + random.nextDouble() * 3;
      _errorCapLength = 0.2 + random.nextDouble() * 1.2;
      _lollipopStemWidth = 1 + random.nextDouble() * 5;
      _lollipopHeadRadius = 3 + random.nextDouble() * 11;
      _paretoLineWidth = 1 + random.nextDouble() * 5;
      _showParetoMarkers = random.nextBool();
      _showParetoCumulativeLabels = random.nextBool();
      _histogramMethod = HistogramBinningMethod
          .values[random.nextInt(HistogramBinningMethod.values.length)];
      _histogramBinCount = 4 + random.nextInt(17);
      _histogramValueMode = HistogramValueMode
          .values[random.nextInt(HistogramValueMode.values.length)];
      _showPatterns = random.nextBool();
      _patternSpacing = 3 + random.nextDouble() * 13;
      _patternStrokeWidth = 0.5 + random.nextDouble() * 3;
      _patternOpacity = 0.25 + random.nextDouble() * 0.7;
      _categoryMinimumExtent = 40 + random.nextDouble() * 100;
      _categoryMaxLines = 1 + random.nextInt(4);
      _categoryRotation = -60 + random.nextDouble() * 120;
      _stressCategoryCount = 16 + random.nextInt(113);
      _labelCollisionPolicy = BarLabelCollisionPolicy
          .values[random.nextInt(BarLabelCollisionPolicy.values.length)];
      _labelPlotEdgeAware = random.nextBool();
      _labelCollisionPadding = random.nextDouble() * 8;
      _showLabelBackground = random.nextBool();
      _showLabelCallouts = random.nextBool();
      _showStackTotals = random.nextBool();
      _bulletRangeCount = 2 + random.nextInt(4);
      _bulletMeasureThickness = 0.2 + random.nextDouble() * 0.6;
      _bulletRangeRadius = random.nextDouble() * 12;
      _showDivergingCenterLine = random.nextBool();
      _divergingCenterLineWidth = 0.5 + random.nextDouble() * 3;
    });
  }

  void _setPlaygroundActive(bool active) {
    if (active == _playgroundActive) return;
    if (active) {
      _authoredPreset = _preset;
      setState(() {
        _playgroundActive = true;
        _preset = _BarLabPreset.capacity;
        _setPresetValues(_BarLabPreset.capacity);
      });
      _showcaseRandomizer.generateCurrent();
      return;
    }

    _showcaseRandomizer.pause();
    _showcaseRandomizer.clear();
    _applyPreset(_authoredPreset);
  }

  List<Widget> _buildPlaygroundOptions() => _buildOptions();

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

  BarDrillNode _buildDrillHierarchy() => switch (_drillDataset) {
    _BarDrillDataset.nutrition => _buildNutritionDrillHierarchy(),
    _BarDrillDataset.regions => _buildRegionalDrillHierarchy(),
  };

  Future<List<BarDrillNode>> _resolveDrillChildren(BarDrillNode node) async {
    await Future<void>.delayed(Duration(milliseconds: _drillLazyDelayMs));
    if (_drillSimulateFailure) {
      throw StateError('Simulated showcase network failure');
    }
    if (node.id != 'berries') return const <BarDrillNode>[];
    BarDrillNode detail(
      String id,
      String label,
      List<String> categories,
      List<double> values,
    ) => BarDrillNode(
      id: id,
      label: label,
      series: [_drillSeries(id, label, categories, values, unit: '%')],
      metadata: {'categories': categories, 'unit': '%'},
    );
    return <BarDrillNode>[
      detail(
        'berry-sugars',
        'Berry sugars',
        const ['Glucose', 'Fructose', 'Other sugars'],
        const [34, 31, 17],
      ),
      detail(
        'berry-fibre',
        'Berry fibre',
        const ['Soluble', 'Insoluble'],
        const [3, 5],
      ),
      detail(
        'berry-micronutrients',
        'Berry micronutrients',
        const ['Vitamin C', 'Manganese', 'Other'],
        const [18, 6, 4],
      ),
    ];
  }

  BarDrillNode _buildRegionalDrillHierarchy() {
    BarDrillNode market(
      String id,
      String label,
      List<String> categories,
      List<double> values,
    ) => BarDrillNode(
      id: id,
      label: label,
      series: [_drillSeries(id, label, categories, values, unit: 'M')],
      metadata: {'categories': categories, 'unit': 'M'},
    );

    BarDrillNode region(
      String id,
      String label,
      List<String> categories,
      List<double> values,
      List<BarDrillNode> children,
    ) => BarDrillNode(
      id: id,
      label: label,
      series: [
        _drillSeries(
          id,
          label,
          categories,
          values,
          children: [for (final child in children) child.id],
          unit: 'M',
        ),
      ],
      children: children,
      metadata: {'categories': categories, 'unit': 'M'},
    );

    final americas = region(
      'region-americas',
      'Americas',
      const ['United States', 'Brazil', 'Canada'],
      const [184, 72, 48],
      [
        market(
          'market-us',
          'United States',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [96, 58, 30],
        ),
        market(
          'market-brazil',
          'Brazil',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [29, 25, 18],
        ),
        market(
          'market-canada',
          'Canada',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [22, 17, 9],
        ),
      ],
    );
    final emea = region(
      'region-emea',
      'EMEA',
      const ['United Kingdom', 'Germany', 'South Africa'],
      const [88, 76, 45],
      [
        market(
          'market-uk',
          'United Kingdom',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [41, 30, 17],
        ),
        market(
          'market-germany',
          'Germany',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [37, 26, 13],
        ),
        market(
          'market-za',
          'South Africa',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [18, 16, 11],
        ),
      ],
    );
    final apac = region(
      'region-apac',
      'APAC',
      const ['Japan', 'Australia', 'Singapore'],
      const [83, 57, 38],
      [
        market(
          'market-japan',
          'Japan',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [42, 29, 12],
        ),
        market(
          'market-australia',
          'Australia',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [25, 20, 12],
        ),
        market(
          'market-singapore',
          'Singapore',
          const ['Enterprise', 'Mid-market', 'SMB'],
          const [19, 12, 7],
        ),
      ],
    );
    const incubator = BarDrillNode(
      id: 'region-incubator',
      label: 'Incubator',
      series: <ChartSeries>[],
      metadata: <String, Object?>{'categories': <String>[], 'unit': 'M'},
    );
    return BarDrillNode(
      id: 'global-revenue',
      label: 'Global revenue',
      series: [
        _drillSeries(
          'global-revenue',
          'Global revenue',
          const ['Americas', 'EMEA', 'APAC', 'Incubator'],
          const [304, 209, 178, 12],
          children: const [
            'region-americas',
            'region-emea',
            'region-apac',
            'region-incubator',
          ],
          unit: 'M',
        ),
      ],
      children: [americas, emea, apac, incubator],
      metadata: const {
        'categories': ['Americas', 'EMEA', 'APAC', 'Incubator'],
        'unit': 'M',
      },
    );
  }

  BarDrillNode _buildNutritionDrillHierarchy() {
    BarDrillNode leaf(
      String id,
      String label,
      List<String> categories,
      List<double> values, {
      String unit = '%',
    }) => BarDrillNode(
      id: id,
      label: label,
      series: [_drillSeries(id, label, categories, values, unit: unit)],
      metadata: {'categories': categories, 'unit': unit},
    );

    final rolledOats = BarDrillNode(
      id: 'rolled-oats',
      label: 'Rolled oats',
      series: [
        _drillSeries(
          'rolled-oats',
          'Rolled oats',
          const ['Carbohydrates', 'Fat', 'Protein'],
          const [67, 6, 13],
          children: const ['carbohydrates', null, 'protein'],
          unit: '%',
        ),
      ],
      metadata: const {
        'categories': ['Carbohydrates', 'Fat', 'Protein'],
        'unit': '%',
      },
      children: [
        leaf(
          'carbohydrates',
          'Carbohydrates',
          const ['Starch', 'Fibre', 'Sugars'],
          const [53, 10, 4],
        ),
        leaf(
          'protein',
          'Protein',
          const ['Avenalin', 'Avenin', 'Other proteins'],
          const [8, 3, 2],
        ),
      ],
    );
    final maple = leaf(
      'maple-syrup',
      'Maple syrup',
      const ['Sucrose', 'Water', 'Minerals'],
      const [66, 32, 2],
    );
    final almonds = leaf(
      'almonds',
      'Flaked almonds',
      const ['Fat', 'Protein', 'Carbohydrates'],
      const [50, 21, 22],
    );
    final berries = BarDrillNode(
      id: 'berries',
      label: 'Dried berries',
      series: [
        _drillSeries(
          'berries',
          'Dried berries',
          const ['Sugars', 'Fibre', 'Micronutrients'],
          const [82, 8, 4],
          children: const [
            'berry-sugars',
            'berry-fibre',
            'berry-micronutrients',
          ],
          unit: '%',
        ),
      ],
      metadata: const {
        'categories': ['Sugars', 'Fibre', 'Micronutrients'],
        'unit': '%',
      },
      mayHaveLazyChildren: true,
    );
    const rootCategories = [
      'Rolled oats',
      'Maple syrup',
      'Flaked almonds',
      'Dried berries',
      'Sunflower seeds',
      'Sesame seeds',
      'Pumpkin seeds',
      'Coconut',
      'Honey',
      'Vegetable oil',
    ];
    return BarDrillNode(
      id: 'ingredients',
      label: 'Ingredients',
      series: [
        _drillSeries(
          'ingredients',
          'Ingredient weight',
          rootCategories,
          const [300, 170, 100, 98, 52, 50, 49, 47, 42, 25],
          children: const [
            'rolled-oats',
            'maple-syrup',
            'almonds',
            'berries',
            null,
            null,
            null,
            null,
            null,
            null,
          ],
          unit: 'g',
        ),
      ],
      metadata: const {'categories': rootCategories, 'unit': 'g'},
      children: [rolledOats, maple, almonds, berries],
    );
  }

  BarRaceConfig _buildPopulationRaceConfig() {
    const categories = [
      BarRaceCategory(id: 'chn', label: 'China', color: Color(0xFFEF4444)),
      BarRaceCategory(id: 'ind', label: 'India', color: Color(0xFFF59E0B)),
      BarRaceCategory(
        id: 'usa',
        label: 'United States',
        color: Color(0xFF3B82F6),
      ),
      BarRaceCategory(id: 'idn', label: 'Indonesia', color: Color(0xFF10B981)),
      BarRaceCategory(id: 'pak', label: 'Pakistan', color: Color(0xFF8B5CF6)),
      BarRaceCategory(id: 'nga', label: 'Nigeria', color: Color(0xFFEC4899)),
      BarRaceCategory(id: 'bra', label: 'Brazil', color: Color(0xFF14B8A6)),
      BarRaceCategory(id: 'bgd', label: 'Bangladesh', color: Color(0xFF6366F1)),
      BarRaceCategory(id: 'rus', label: 'Russia', color: Color(0xFF64748B)),
      BarRaceCategory(id: 'mex', label: 'Mexico', color: Color(0xFF84CC16)),
      BarRaceCategory(id: 'jpn', label: 'Japan', color: Color(0xFF06B6D4)),
      BarRaceCategory(id: 'eth', label: 'Ethiopia', color: Color(0xFFF97316)),
      BarRaceCategory(
        id: 'phl',
        label: 'Philippines',
        color: Color(0xFF0EA5E9),
      ),
      BarRaceCategory(id: 'egy', label: 'Egypt', color: Color(0xFFA855F7)),
      BarRaceCategory(id: 'deu', label: 'Germany', color: Color(0xFF71717A)),
      BarRaceCategory(id: 'vnm', label: 'Vietnam', color: Color(0xFF22C55E)),
      BarRaceCategory(id: 'tur', label: 'Türkiye', color: Color(0xFFFB7185)),
      BarRaceCategory(id: 'cod', label: 'DR Congo', color: Color(0xFF2DD4BF)),
    ];
    const anchorYears = [1960, 1980, 2000, 2024];
    const anchors = <String, List<double>>{
      'chn': [667, 981, 1264, 1410],
      'ind': [445, 698, 1057, 1450],
      'usa': [181, 227, 282, 342],
      'idn': [88, 148, 216, 281],
      'pak': [46, 81, 154, 252],
      'nga': [45, 73, 123, 229],
      'bra': [72, 121, 175, 216],
      'bgd': [50, 80, 130, 174],
      'rus': [120, 139, 146, 144],
      'mex': [38, 68, 99, 130],
      'jpn': [93, 117, 127, 123],
      'eth': [23, 35, 66, 129],
      'phl': [27, 48, 78, 119],
      'egy': [27, 44, 71, 114],
      'deu': [73, 78, 82, 84],
      'vnm': [33, 54, 79, 101],
      'tur': [28, 44, 64, 87],
      // Deliberately accelerated showcase scenario: this category begins
      // outside the visible top-N, enters the race, and eventually becomes
      // the leader so entry, overtaking, and first-place transitions are all
      // inspectable in one deterministic playback sequence.
      'cod': [15, 70, 420, 1600],
    };

    double populationAt(String categoryId, double year) {
      final values = anchors[categoryId]!;
      for (var index = 0; index < anchorYears.length - 1; index++) {
        final startYear = anchorYears[index];
        final endYear = anchorYears[index + 1];
        if (year > endYear) continue;
        final progress = (year - startYear) / (endYear - startYear);
        return values[index] + (values[index + 1] - values[index]) * progress;
      }
      return values.last;
    }

    double showcaseRaceVariation(
      String categoryId,
      double year,
      double population,
    ) {
      final categoryIndex = categories.indexWhere(
        (category) => category.id == categoryId,
      );
      final elapsedYears = year - anchorYears.first;
      // This showcase deliberately adds small, smooth estimate revisions so
      // similarly sized countries exchange ranks often enough to exercise the
      // race layout. The dominant long-term population trend still comes from
      // the authored anchors above.
      final amplitude = switch (categoryIndex) {
        < 3 => 0.004,
        < 8 => 0.035,
        _ => 0.075,
      };
      final primaryCycleYears = 1.2 + (categoryIndex % 5) * 0.28;
      final secondaryCycleYears = 4.2 + (categoryIndex % 4) * 0.55;
      final phase = categoryIndex * 1.31;
      final motion =
          math.sin((elapsedYears / primaryCycleYears) * math.pi * 2 + phase) *
              0.72 +
          math.sin((elapsedYears / secondaryCycleYears) * math.pi * 2 - phase) *
              0.28;
      return population * (1 + amplitude * motion);
    }

    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final frames = <BarRaceFrame>[];
    final firstMonth = DateTime(1960);
    final lastMonth = DateTime(2024);
    for (
      var month = firstMonth;
      !month.isAfter(lastMonth);
      month = DateTime(month.year, month.month + 1)
    ) {
      final yearPosition = month.year + (month.month - 1) / 12;
      final values = <String, double>{
        for (final category in categories)
          category.id: showcaseRaceVariation(
            category.id,
            yearPosition,
            populationAt(category.id, yearPosition),
          ),
      };
      frames.add(
        BarRaceFrame(
          id: '${month.year}-${month.month.toString().padLeft(2, '0')}',
          label: '${monthNames[month.month - 1]} ${month.year}',
          timestamp: month,
          values: values,
          total: values.values.fold<double>(0, (sum, value) => sum + value),
        ),
      );
    }
    return BarRaceConfig(
      categories: categories,
      frames: List.unmodifiable(frames),
      topCount: 15,
      durationPerFrame: const Duration(milliseconds: 100),
      axisRange: BarRaceAxisRange.continuous,
      showPeriod: true,
      showTotal: true,
      periodStyle: const BarRacePeriodStyle(
        position: BarRacePeriodPosition.bottomRight,
        fontSize: 44,
        color: Color(0xFF38BDF8),
        fontWeight: FontWeight.w700,
        opacity: 0.90,
        inset: 64,
        supportingTextSize: 16,
      ),
      periodFormat: const BarRacePeriodFormat(pattern: '{MMM} {yyyy}'),
      valueFormat: const BarRaceValueFormat(
        pattern: '{value} M',
        notation: BarRaceValueNotation.standard,
        decimalPlaces: 3,
        useGrouping: true,
        trimTrailingZeros: true,
        scale: 1,
      ),
      totalFormat: const BarRaceValueFormat(
        pattern: '{value} M combined population',
        notation: BarRaceValueNotation.standard,
        decimalPlaces: 0,
        useGrouping: true,
        trimTrailingZeros: true,
        scale: 1,
      ),
    );
  }

  void _seekRaceToDefaultFrame() {
    final index = _raceController.config.frames.indexWhere(
      (frame) => frame.id == _raceDefaultFrameId,
    );
    _raceController.seekToFrame(index < 0 ? 0 : index);
  }

  BarChartSeries _drillSeries(
    String id,
    String name,
    List<String> categories,
    List<double> values, {
    List<String?>? children,
    required String unit,
  }) => BarChartSeries(
    id: 'drill-$id',
    name: name,
    points: [
      for (var index = 0; index < categories.length; index++)
        ChartDataPoint(
          x: index.toDouble(),
          y: values[index],
          label: categories[index],
          metadata:
              children != null &&
                  index < children.length &&
                  children[index] != null
              ? {barDrillNodeIdMetadataKey: children[index]}
              : null,
        ),
    ],
    unit: unit,
    barWidthPercent: 0.72,
  );

  List<ChartSeries> _buildDrillSeries() => [
    for (final source in _drilldownController.current.series)
      if (source is BarChartSeries)
        source.copyWith(
          color: const Color(0xFF2389DA),
          barWidthPercent: _barWidth,
          barGap: _barGap,
          orientation: _orientation,
          layoutMode: BarLayoutMode.grouped,
          barStyle: BarChartStyle(
            animationMode: _animateBars
                ? BarAnimationMode.grow
                : BarAnimationMode.none,
            cornerRadius: _cornerRadius,
            cornerRadiusPolicy: _cornerPolicy,
            gradient: _showGradient
                ? const BarGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                  )
                : null,
            border: _showBorder
                ? const BarBorderStyle(color: Color(0xFF1D4ED8), width: 1.25)
                : null,
          ),
          labelStyle: BarLabelStyle(
            show: _showLabels,
            position: _labelPosition,
            rotationMode: _labelRotationMode,
            rotationDegrees: _labelRotationDegrees,
            showUnit: true,
            padding: _labelEdgeOffset,
            collisionPolicy: _labelCollisionPolicy,
            plotEdgeAware: _labelPlotEdgeAware,
            collisionPadding: _labelCollisionPadding,
            backgroundColor: _showLabelBackground
                ? const Color(0xEEFFFFFF)
                : null,
          ),
        ),
  ];

  List<ChartSeries> _buildRaceSeries() {
    final config = _raceController.config;
    final ranked = _raceController.effectiveRankedValues;
    final valueFormat = config.valueFormat;
    return <ChartSeries>[
      BarChartSeries(
        id: 'population-race',
        name: 'Population',
        points: [
          for (var index = 0; index < ranked.length; index++)
            ChartDataPoint(
              x: ranked[index].rank,
              y: ranked[index].value,
              pointKey: ranked[index].category.id,
              label: ranked[index].category.label,
              pointStyle: PointStyle.color(ranked[index].category.color),
              metadata: {
                barRaceCategoryIdMetadataKey: ranked[index].category.id,
              },
            ),
        ],
        unit: 'M',
        barWidthPercent: _barWidth,
        categorySpacing: 1,
        barGap: _barGap,
        orientation: BarOrientation.horizontal,
        layoutMode: BarLayoutMode.grouped,
        barStyle: BarChartStyle(
          // The race controller already interpolates values and fractional
          // ranks on its frame clock. A second chart animation clock can be
          // restarted by inspector edits and must not compete with it.
          animationMode: BarAnimationMode.none,
          cornerRadius: _cornerRadius,
          cornerRadiusPolicy: _cornerPolicy,
          border: _showBorder
              ? const BarBorderStyle(color: Color(0xFF334155), width: 1)
              : null,
        ),
        labelStyle: BarLabelStyle(
          show: _showLabels,
          position: _labelPosition,
          rotationMode: _labelRotationMode,
          rotationDegrees: _labelRotationDegrees,
          showUnit: false,
          formatter: (point) => valueFormat.format(point.y),
          padding: _labelEdgeOffset,
          collisionPolicy: _labelCollisionPolicy,
          plotEdgeAware: _labelPlotEdgeAware,
          collisionPadding: _labelCollisionPadding,
          backgroundColor: _showLabelBackground
              ? const Color(0xEEFFFFFF)
              : null,
        ),
      ),
    ];
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
      playground: ChartPlaygroundConfig(
        active: _playgroundActive,
        optionsChildren: _buildPlaygroundOptions(),
        randomizer: _showcaseRandomizer,
      ),
      randomizerKeyPrefix: 'bar-randomizer',
      chart: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return PersistentResizableChartPanelWorkspace(
            preferenceKey: showcaseChartPanelHeightKey(compact: compact),
            minimumPanelHeight: compact ? 520 : 360,
            maximumPanelHeight: compact ? 1400 : 1200,
            initialPanelHeight: compact ? 760 : 620,
            scrollViewKey: const ValueKey('bar-showcase-scroll'),
            leading: [_buildPresetPicker(), const SizedBox(height: 16)],
            panel: _buildChartCard(),
          );
        },
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
            Wrap(
              key: const ValueKey('bar-lab-preset-wrap'),
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in _BarLabPreset.values)
                  ShowcaseExampleChoiceChip(
                    key: ValueKey('bar-lab-preset-${preset.name}'),
                    label: preset.label,
                    icon: preset.icon,
                    selected: !_playgroundActive && preset == _preset,
                    onSelected: () => _applyPreset(preset),
                  ),
                PlaygroundChoiceChip(
                  key: const ValueKey('bar-playground'),
                  selected: _playgroundActive,
                  onSelected: () => _setPlaygroundActive(true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _playgroundActive
                  ? 'Generated values and every compatible bar property. Seeded playback is available in Options.'
                  : _presetDescription(),
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
        availableDisplayModes: const {
          ChartDisplayMode.chart,
          ChartDisplayMode.data,
          ChartDisplayMode.split,
          ChartDisplayMode.source,
        },
        sourceOptions: const ChartDartSourceOptions(variableName: 'barChart'),
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
              if (_preset == _BarLabPreset.drilldown && _drillShowBreadcrumbs)
                BarDrilldownBreadcrumbs(
                  key: const ValueKey('bar-lab-drill-breadcrumbs'),
                  controller: _drilldownController,
                ),
              if (_preset == _BarLabPreset.race) _buildRacePlaybackControls(),
              SizedBox(
                height: showWaterfallLegend ? 20 : 0,
                child: Offstage(
                  offstage: !showWaterfallLegend,
                  child: _buildWaterfallLegend(),
                ),
              ),
              SizedBox(height: showWaterfallLegend ? 8 : 0),
              Expanded(
                child: _preset == _BarLabPreset.race
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          chart,
                          BarRacePeriodIndicator(
                            key: const ValueKey('bar-race-period'),
                            controller: _raceController,
                          ),
                        ],
                      )
                    : _preset == _BarLabPreset.drilldown
                    ? AnimatedSwitcher(
                        duration:
                            _drillTransition == BarDrillTransition.fadeThrough
                            ? const Duration(milliseconds: 260)
                            : Duration.zero,
                        child: KeyedSubtree(
                          key: ValueKey(_drilldownController.current.id),
                          child: chart,
                        ),
                      )
                    : chart,
              ),
              if (_preset == _BarLabPreset.categories) ...[
                const SizedBox(height: 8),
                SizedBox(height: 72, child: _buildCategoryNavigator()),
              ],
            ],
          );
        },
      ),
    );
    final directed = Directionality(
      textDirection: _preset == _BarLabPreset.rtl
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: card,
    );
    return BarRaceTicker(
      controller: _raceController,
      disableMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      child: directed,
    );
  }

  Widget _buildRacePlaybackControls() {
    final frame = _raceController.currentFrame;
    final config = _raceController.config;
    final period = config.periodFormat.format(frame);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = <Widget>[
            IconButton(
              key: const ValueKey('bar-race-play-pause'),
              tooltip: _raceController.isPlaying ? 'Pause race' : 'Play race',
              onPressed: _raceController.toggle,
              icon: Icon(
                _raceController.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            IconButton(
              tooltip: 'Previous frame',
              onPressed: _raceController.frameIndex == 0
                  ? null
                  : _raceController.previous,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton(
              key: const ValueKey('bar-race-next'),
              tooltip: 'Next frame',
              onPressed:
                  _raceController.frameIndex == config.frames.length - 1 &&
                      !config.loop
                  ? null
                  : _raceController.next,
              icon: const Icon(Icons.skip_next),
            ),
          ];
          final seek = Slider(
            key: const ValueKey('bar-race-seek'),
            value: _raceController.progress,
            semanticFormatterCallback: (_) => 'Period $period',
            onChanged: _raceController.seek,
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [...actions, const Spacer()]),
                SizedBox(height: 48, child: seek),
              ],
            );
          }
          return Row(
            children: [
              ...actions,
              Expanded(child: seek),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChart(BravenChartController controller) {
    final lastCategory = _categories.length - 1;
    final baseTheme = ChartTheme.light;
    final configured = _preset == _BarLabPreset.config
        ? _agentBuildResult
        : null;
    return BravenChartPlus(
      key: const ValueKey('bar-lab-chart'),
      transitionKey: _preset == _BarLabPreset.drilldown
          ? _drilldownController.current.id
          : _preset,
      bravenChartController: controller,
      interactionGroupController: _preset == _BarLabPreset.categories
          ? _interactionGroupController
          : null,
      theme: baseTheme.copyWith(
        animationTheme: baseTheme.animationTheme.copyWith(
          dataUpdateDuration: _preset == _BarLabPreset.race
              ? Duration.zero
              : Duration(milliseconds: _motionDurationMs.round()),
          dataUpdateCurve: _preset == _BarLabPreset.race
              ? Curves.linear
              : Curves.easeInOutCubic,
        ),
      ),
      series: configured?.series ?? _buildSeries(),
      showXScrollbar:
          _preset == _BarLabPreset.categories ||
          _preset == _BarLabPreset.stress,
      scrollbarTheme:
          _preset == _BarLabPreset.categories || _preset == _BarLabPreset.stress
          ? ScrollbarConfig.defaultLight.copyWith(autoHide: false)
          : null,
      showLegend:
          configured?.showLegend ??
          (_preset != _BarLabPreset.waterfall &&
              _preset != _BarLabPreset.labels &&
              _preset != _BarLabPreset.race &&
              _preset != _BarLabPreset.stress &&
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
                : _preset == _BarLabPreset.stress
                ? 'Region and segment'
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
                : _preset == _BarLabPreset.drilldown
                ? _drilldownController.current.label
                : _preset == _BarLabPreset.race
                ? 'Population rank'
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
            maxHeight:
                _preset == _BarLabPreset.categories ||
                    _preset == _BarLabPreset.stress
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
                    // A race's topCount has already reduced the domain to the
                    // intended visible ranks. Applying the generic category
                    // auto-viewport as well would silently reduce that list a
                    // second time based on panel height (15 ranks became 8 in
                    // the default showcase workspace).
                    autoViewport: _preset != _BarLabPreset.race,
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
            : _preset == _BarLabPreset.drilldown
            ? 'Amount (${_drilldownController.current.metadata['unit'] ?? ''})'
            : _preset == _BarLabPreset.race
            ? 'Population (millions)'
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
        max: _preset == _BarLabPreset.race
            ? _raceController.effectiveAxisMaximum
            : _layoutMode == BarLayoutMode.normalizedStacked
            ? 110
            : null,
        tickCount: 7,
      ),
      interactionConfig: InteractionConfig(
        selection: ChartSelectionConfig(scope: _selectionScope),
        tooltip: TooltipConfig(enabled: _showDataPointPopup),
        crosshair: CrosshairConfig(
          mode: CrosshairMode.both,
          displayMode: _orientation == BarOrientation.horizontal
              ? CrosshairDisplayMode.tracking
              : CrosshairDisplayMode.auto,
        ),
        onSelectionChanged:
            _preset == _BarLabPreset.drilldown &&
                _drillActivation == BarDrillActivation.selection
            ? (points) {
                if (points.isEmpty) return;
                final childId = barDrillNodeIdForPointMetadata(
                  points.last.metadata,
                );
                if (childId != null) {
                  _drilldownController.drillTo(childId);
                }
              }
            : null,
      ),
      onPointTap:
          _preset == _BarLabPreset.drilldown &&
              _drillActivation == BarDrillActivation.primaryAction
          ? (point, _) {
              final childId = barDrillNodeIdForPointMetadata(point.metadata);
              if (childId != null) {
                _drilldownController.drillTo(childId);
              }
            }
          : null,
    );
  }

  Widget _buildCategoryNavigator() {
    final source = _buildSeries().whereType<BarChartSeries>().first;
    final lastCategory = _categories.length - 1;
    final initialMax = lastCategory > 8 ? 8.0 : lastCategory.toDouble();
    return CartesianNavigator(
      key: const ValueKey('bar-categories-navigator'),
      interactionGroupController: _interactionGroupController,
      overviewSeries: AreaChartSeries(
        id: 'bar-categories-overview',
        name: 'Category overview',
        points: source.points,
        color: const Color(0xFF168AAD),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.5,
        fillOpacity: .22,
        showDataPointMarkers: false,
      ),
      fullDomain: ChartXViewport(min: 0, max: lastCategory.toDouble()),
      initialViewport: ChartXViewport(min: 0, max: initialMax),
      behavior: const CartesianNavigatorBehavior(minimumSpan: 2),
      snapPolicy: CartesianNavigatorSnapPolicy.interval(1),
      theme: ChartTheme.light,
      height: 72,
      semanticLabel: 'Market segment viewport',
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

  _BarRacePeriodPreset _racePeriodPreset(BarRacePeriodFormat format) =>
      switch (format.pattern) {
        '{label}' => _BarRacePeriodPreset.authoredLabel,
        '{MMMM} {yyyy}' => _BarRacePeriodPreset.monthYearLong,
        '{MMM} {yyyy}' => _BarRacePeriodPreset.monthYearShort,
        '{yyyy}' => _BarRacePeriodPreset.year,
        '{yyyy}-{MM}' => _BarRacePeriodPreset.isoMonth,
        _ => _BarRacePeriodPreset.custom,
      };

  void _setRacePeriodPreset(_BarRacePeriodPreset preset) {
    final pattern = switch (preset) {
      _BarRacePeriodPreset.authoredLabel => '{label}',
      _BarRacePeriodPreset.monthYearLong => '{MMMM} {yyyy}',
      _BarRacePeriodPreset.monthYearShort => '{MMM} {yyyy}',
      _BarRacePeriodPreset.year => '{yyyy}',
      _BarRacePeriodPreset.isoMonth => '{yyyy}-{MM}',
      _BarRacePeriodPreset.custom => 'Period {MMM} {yyyy}',
    };
    _raceController.replaceConfig(
      _raceController.config.copyWith(
        periodFormat: BarRacePeriodFormat(pattern: pattern),
      ),
      preserveFrame: true,
    );
  }

  Widget _buildRaceValueFormatPreview() {
    final format = _raceController.config.valueFormat;
    final rankedValues = _raceController.effectiveRankedValues;
    final rawValue = rankedValues.isEmpty ? 0.0 : rankedValues.first.value;
    final theme = Theme.of(context);
    final divisor = format.scale.toStringAsFixed(
      format.scale == format.scale.roundToDouble() ? 0 : 2,
    );
    return SearchableOption(
      key: const ValueKey('bar-race-value-preview'),
      label: 'Bar value format preview',
      description:
          'Shows the current leader before and after division, notation, decimal, grouping, and template formatting.',
      aliases: const ['format', 'template', 'divisor', 'scale', 'example'],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.48,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formatting preview',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${rawValue.toStringAsFixed(3)} ÷ $divisor  →  ${format.format(rawValue)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Order: divide → notation → decimals and grouping → template',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions() => _prioritizePresetOptions([
    if (_preset == _BarLabPreset.race)
      OptionSection(
        key: const ValueKey('bar-options-race-playback'),
        title: 'Race playback',
        icon: Icons.play_circle_outline,
        children: [
          IntSliderOption(
            key: const ValueKey('bar-race-top-count'),
            label: 'Visible ranks',
            value: _raceController.config.topCount,
            min: 3,
            max: _raceController.config.categories.length,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(topCount: value),
              preserveFrame: true,
            ),
          ),
          SliderOption(
            key: const ValueKey('bar-race-frame-duration'),
            label: 'Frame duration',
            value: _raceController.config.durationPerFrame.inMilliseconds
                .toDouble(),
            min: 50,
            max: 2000,
            divisions: 39,
            suffix: 'ms',
            decimalPlaces: 0,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                durationPerFrame: Duration(milliseconds: value.round()),
              ),
              preserveFrame: true,
            ),
          ),
          SliderOption(
            key: const ValueKey('bar-race-speed'),
            label: 'Playback speed',
            value: _raceController.speed,
            min: 0.25,
            max: 10,
            divisions: 39,
            suffix: '×',
            decimalPlaces: 2,
            description:
                'Scale playback from quarter speed to 10× in 0.25× steps.',
            onChanged: _raceController.setSpeed,
          ),
          EnumOption<BarRaceAxisRange>(
            key: const ValueKey('bar-race-axis-range'),
            label: 'Value axis',
            value: _raceController.config.axisRange,
            values: BarRaceAxisRange.values,
            labelBuilder: (value) => switch (value) {
              BarRaceAxisRange.dynamic => 'Stepped leader headroom',
              BarRaceAxisRange.continuous => 'Continuous leader headroom',
              BarRaceAxisRange.fixed => 'Fixed across race',
            },
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(axisRange: value),
              preserveFrame: true,
            ),
          ),
          EnumOption<BarRaceSort>(
            key: const ValueKey('bar-race-sort'),
            label: 'Rank order',
            value: _raceController.config.sort,
            values: BarRaceSort.values,
            labelBuilder: (value) => switch (value) {
              BarRaceSort.descending => 'Largest first',
              BarRaceSort.ascending => 'Smallest first',
            },
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(sort: value),
              preserveFrame: true,
            ),
          ),
          BoolOption(
            key: const ValueKey('bar-race-loop'),
            label: 'Loop playback',
            value: _raceController.config.loop,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(loop: value),
              preserveFrame: true,
            ),
          ),
        ],
      ),
    if (_preset == _BarLabPreset.race)
      OptionSection(
        key: const ValueKey('bar-options-race-formatting'),
        title: 'Race labels and formatting',
        icon: Icons.format_shapes_outlined,
        description:
            'Formats the active period, continuously counting bar values, and the aggregate total.',
        children: [
          BoolOption(
            key: const ValueKey('bar-race-show-period'),
            label: 'Show period',
            value: _raceController.config.showPeriod,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(showPeriod: value),
              preserveFrame: true,
            ),
          ),
          EnumOption<_BarRacePeriodPreset>(
            key: const ValueKey('bar-race-period-preset'),
            label: 'Period format',
            value: _racePeriodPreset(_raceController.config.periodFormat),
            values: _BarRacePeriodPreset.values,
            labelBuilder: (value) => switch (value) {
              _BarRacePeriodPreset.authoredLabel => 'Authored frame label',
              _BarRacePeriodPreset.monthYearLong => 'January 1965',
              _BarRacePeriodPreset.monthYearShort => 'Jan 1965',
              _BarRacePeriodPreset.year => '1965',
              _BarRacePeriodPreset.isoMonth => '1965-01',
              _BarRacePeriodPreset.custom => 'Custom pattern',
            },
            onChanged: (value) => _setRacePeriodPreset(value),
          ),
          TextOption(
            key: ValueKey(
              'bar-race-period-pattern-${_racePeriodPreset(_raceController.config.periodFormat).name}',
            ),
            label: 'Period pattern',
            value: _raceController.config.periodFormat.pattern,
            hint: '{MMMM} {yyyy}',
            description:
                'Tokens: {label}, date tokens through {d}, and time tokens {HH}, {H}, {mm}, {m}, {ss}, {s}.',
            onChanged: (value) {
              if (value.isEmpty) return;
              _raceController.replaceConfig(
                _raceController.config.copyWith(
                  periodFormat: BarRacePeriodFormat(pattern: value),
                ),
                preserveFrame: true,
              );
            },
          ),
          EnumOption<BarLabelCollisionPolicy>(
            key: const ValueKey('bar-race-label-collision'),
            label: 'Transition label behavior',
            value: _labelCollisionPolicy,
            values: BarLabelCollisionPolicy.values,
            labelBuilder: (value) => switch (value) {
              BarLabelCollisionPolicy.none => 'Keep outside · allow overlap',
              BarLabelCollisionPolicy.reposition => 'Allow inside fallback',
              BarLabelCollisionPolicy.hide => 'Keep outside · hide collision',
            },
            description:
                'Controls whether outside-end values remain outside while ranks cross. The default preserves placement and briefly hides only a colliding label.',
            onChanged: (value) => setState(() => _labelCollisionPolicy = value),
          ),
          EnumOption<BarRaceValueNotation>(
            key: const ValueKey('bar-race-value-notation'),
            label: 'Bar value notation',
            value: _raceController.config.valueFormat.notation,
            values: BarRaceValueNotation.values,
            labelBuilder: (value) => switch (value) {
              BarRaceValueNotation.standard => 'Standard',
              BarRaceValueNotation.compact => 'Compact (k, M, B)',
              BarRaceValueNotation.scientific => 'Scientific',
            },
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                valueFormat: _raceController.config.valueFormat.copyWith(
                  notation: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          TextOption(
            key: const ValueKey('bar-race-value-pattern'),
            label: 'Bar value template',
            value: _raceController.config.valueFormat.pattern,
            hint: '{value}M',
            description:
                'Place {value} where the formatted number belongs. Examples: {value}M, \${value}, or {value} people.',
            onChanged: (value) {
              if (value.isEmpty || !value.contains('{value}')) return;
              _raceController.replaceConfig(
                _raceController.config.copyWith(
                  valueFormat: _raceController.config.valueFormat.copyWith(
                    pattern: value,
                  ),
                ),
                preserveFrame: true,
              );
            },
          ),
          IntSliderOption(
            key: const ValueKey('bar-race-value-decimals'),
            label: 'Bar value decimals',
            value: _raceController.config.valueFormat.decimalPlaces,
            min: 0,
            max: 4,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                valueFormat: _raceController.config.valueFormat.copyWith(
                  decimalPlaces: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          BoolOption(
            key: const ValueKey('bar-race-value-grouping'),
            label: 'Group thousands',
            value: _raceController.config.valueFormat.useGrouping,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                valueFormat: _raceController.config.valueFormat.copyWith(
                  useGrouping: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          TextOption(
            key: const ValueKey('bar-race-value-scale'),
            label: 'Scale divisor',
            value: _raceController.config.valueFormat.scale.toString(),
            hint: '1',
            description:
                'Divide the raw value before notation and decimals. Use 1 for no scaling, 1000 to convert thousands to millions.',
            onChanged: (value) {
              final scale = double.tryParse(value);
              if (scale == null || !scale.isFinite || scale <= 0) return;
              _raceController.replaceConfig(
                _raceController.config.copyWith(
                  valueFormat: _raceController.config.valueFormat.copyWith(
                    scale: scale,
                  ),
                ),
                preserveFrame: true,
              );
            },
          ),
          BoolOption(
            key: const ValueKey('bar-race-value-trim-zeros'),
            label: 'Trim trailing zeros',
            value: _raceController.config.valueFormat.trimTrailingZeros,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                valueFormat: _raceController.config.valueFormat.copyWith(
                  trimTrailingZeros: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          _buildRaceValueFormatPreview(),
          BoolOption(
            key: const ValueKey('bar-race-show-total'),
            label: 'Show total',
            value: _raceController.config.showTotal,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(showTotal: value),
              preserveFrame: true,
            ),
          ),
          TextOption(
            key: const ValueKey('bar-race-total-pattern'),
            label: 'Total pattern',
            value: _raceController.config.totalFormat.pattern,
            hint: '{value}M combined population',
            description:
                'The continuously interpolated aggregate replaces {value}.',
            onChanged: (value) {
              if (value.isEmpty || !value.contains('{value}')) return;
              _raceController.replaceConfig(
                _raceController.config.copyWith(
                  totalFormat: _raceController.config.totalFormat.copyWith(
                    pattern: value,
                  ),
                ),
                preserveFrame: true,
              );
            },
          ),
          EnumOption<BarRaceValueNotation>(
            key: const ValueKey('bar-race-total-notation'),
            label: 'Total notation',
            value: _raceController.config.totalFormat.notation,
            values: BarRaceValueNotation.values,
            labelBuilder: (value) => switch (value) {
              BarRaceValueNotation.standard => 'Standard',
              BarRaceValueNotation.compact => 'Compact (k, M, B)',
              BarRaceValueNotation.scientific => 'Scientific',
            },
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                totalFormat: _raceController.config.totalFormat.copyWith(
                  notation: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          IntSliderOption(
            key: const ValueKey('bar-race-total-decimals'),
            label: 'Total decimals',
            value: _raceController.config.totalFormat.decimalPlaces,
            min: 0,
            max: 4,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                totalFormat: _raceController.config.totalFormat.copyWith(
                  decimalPlaces: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          BoolOption(
            key: const ValueKey('bar-race-total-grouping'),
            label: 'Group total thousands',
            value: _raceController.config.totalFormat.useGrouping,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                totalFormat: _raceController.config.totalFormat.copyWith(
                  useGrouping: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          BoolOption(
            key: const ValueKey('bar-race-total-trim-zeros'),
            label: 'Trim total trailing zeros',
            value: _raceController.config.totalFormat.trimTrailingZeros,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                totalFormat: _raceController.config.totalFormat.copyWith(
                  trimTrailingZeros: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          TextOption(
            key: const ValueKey('bar-race-total-scale'),
            label: 'Total divisor',
            value: _raceController.config.totalFormat.scale.toString(),
            hint: '1',
            description: 'Divide the aggregate before applying its pattern.',
            onChanged: (value) {
              final scale = double.tryParse(value);
              if (scale == null || !scale.isFinite || scale <= 0) return;
              _raceController.replaceConfig(
                _raceController.config.copyWith(
                  totalFormat: _raceController.config.totalFormat.copyWith(
                    scale: scale,
                  ),
                ),
                preserveFrame: true,
              );
            },
          ),
          EnumOption<BarRacePeriodPosition>(
            key: const ValueKey('bar-race-period-position'),
            label: 'Period position',
            value: _raceController.config.periodStyle.position,
            values: BarRacePeriodPosition.values,
            labelBuilder: (value) => switch (value) {
              BarRacePeriodPosition.topLeft => 'Top left',
              BarRacePeriodPosition.topRight => 'Top right',
              BarRacePeriodPosition.bottomLeft => 'Bottom left',
              BarRacePeriodPosition.bottomRight => 'Bottom right',
            },
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  position: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          SliderOption(
            key: const ValueKey('bar-race-period-size'),
            label: 'Period text size',
            value: _raceController.config.periodStyle.fontSize,
            min: 24,
            max: 96,
            divisions: 18,
            decimalPlaces: 0,
            suffix: 'px',
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  fontSize: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          SliderOption(
            key: const ValueKey('bar-race-total-size'),
            label: 'Total text size',
            value: _raceController.config.periodStyle.supportingTextSize,
            min: 8,
            max: 28,
            divisions: 20,
            decimalPlaces: 0,
            suffix: 'px',
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  supportingTextSize: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          SliderOption(
            key: const ValueKey('bar-race-period-opacity'),
            label: 'Period opacity',
            value: _raceController.config.periodStyle.opacity,
            min: 0.1,
            max: 1,
            divisions: 18,
            decimalPlaces: 2,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  opacity: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          SliderOption(
            key: const ValueKey('bar-race-period-inset'),
            label: 'Period edge inset',
            value: _raceController.config.periodStyle.inset,
            min: 0,
            max: 64,
            divisions: 16,
            decimalPlaces: 0,
            suffix: 'px',
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  inset: value,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          BoolOption(
            key: const ValueKey('bar-race-period-bold'),
            label: 'Bold period label',
            value:
                _raceController.config.periodStyle.fontWeight ==
                FontWeight.w700,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  fontWeight: value ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              preserveFrame: true,
            ),
          ),
          PaletteColorOption(
            key: const ValueKey('bar-race-period-color'),
            keyPrefix: 'bar-race-period-color',
            label: 'Period color',
            value: _raceController.config.periodStyle.color,
            customColorFallback: Theme.of(context).colorScheme.onSurface,
            onChanged: (value) => _raceController.replaceConfig(
              _raceController.config.copyWith(
                periodStyle: _raceController.config.periodStyle.copyWith(
                  color: value,
                  clearColor: value == null,
                ),
              ),
              preserveFrame: true,
            ),
          ),
        ],
      ),
    if (_preset == _BarLabPreset.drilldown)
      OptionSection(
        key: const ValueKey('bar-options-hierarchy'),
        title: 'Hierarchy',
        icon: Icons.account_tree_outlined,
        children: [
          EnumOption<_BarDrillDataset>(
            key: const ValueKey('bar-drill-dataset'),
            label: 'Example data',
            value: _drillDataset,
            values: _BarDrillDataset.values,
            labelBuilder: (value) => switch (value) {
              _BarDrillDataset.nutrition => 'Nutrition hierarchy',
              _BarDrillDataset.regions => 'Regional revenue',
            },
            onChanged: (value) {
              _drillDataset = value;
              _replaceDrillHierarchy();
            },
          ),
          BoolOption(
            key: const ValueKey('bar-drill-show-breadcrumbs'),
            label: 'Show breadcrumbs',
            subtitle: 'Expose the complete current path and back navigation',
            value: _drillShowBreadcrumbs,
            onChanged: (value) => setState(() => _drillShowBreadcrumbs = value),
          ),
          EnumOption<BarDrillActivation>(
            key: const ValueKey('bar-drill-activation'),
            label: 'Activation',
            value: _drillActivation,
            values: BarDrillActivation.values,
            labelBuilder: (value) => switch (value) {
              BarDrillActivation.primaryAction => 'Tap / primary action',
              BarDrillActivation.selection => 'Selection change',
            },
            onChanged: (value) => setState(() => _drillActivation = value),
          ),
          EnumOption<BarDrillTransition>(
            key: const ValueKey('bar-drill-transition'),
            label: 'Level transition',
            value: _drillTransition,
            values: BarDrillTransition.values,
            labelBuilder: (value) => switch (value) {
              BarDrillTransition.none => 'Immediate',
              BarDrillTransition.fadeThrough => 'Fade through',
            },
            onChanged: (value) => setState(() => _drillTransition = value),
          ),
          EnumOption<BarDrillSelectionPolicy>(
            key: const ValueKey('bar-drill-selection-policy'),
            label: 'Selection on navigation',
            value: _drillSelectionPolicy,
            values: BarDrillSelectionPolicy.values,
            labelBuilder: (value) => switch (value) {
              BarDrillSelectionPolicy.clear => 'Clear selection',
              BarDrillSelectionPolicy.preserveStableIdentities =>
                'Preserve stable IDs',
            },
            onChanged: (value) => setState(() => _drillSelectionPolicy = value),
          ),
          IntSliderOption(
            key: const ValueKey('bar-drill-lazy-delay'),
            label: 'Lazy-load delay',
            description: 'Applied when Dried berries loads its third level.',
            value: _drillLazyDelayMs,
            min: 0,
            max: 1600,
            suffix: 'ms',
            onChanged: (value) => setState(() => _drillLazyDelayMs = value),
          ),
          BoolOption(
            key: const ValueKey('bar-drill-simulate-failure'),
            label: 'Simulate lazy failure',
            subtitle: 'Reset the hierarchy, then use Retry after disabling',
            value: _drillSimulateFailure,
            onChanged: (value) {
              _drillSimulateFailure = value;
              _replaceDrillHierarchy();
            },
          ),
        ],
      ),
    OptionSection(
      key: const ValueKey('bar-options-composition'),
      title: 'Composition',
      icon: Icons.view_week_outlined,
      children: [
        if (_playgroundActive ||
            (_preset != _BarLabPreset.pareto &&
                _preset != _BarLabPreset.histogram)) ...[
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
            onChanged: (value) => setState(() {
              _layoutMode = value;
              if (_selectionScope == ChartSelectionScope.categoryStack &&
                  !_layoutHasComposableStacks) {
                _selectionScope = ChartSelectionScope.wholeSeries;
              }
            }),
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
        if (_playgroundActive ||
            _layoutMode == BarLayoutMode.overlaid ||
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
        if (_playgroundActive || _layoutMode == BarLayoutMode.overlaid)
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
        if (_playgroundActive || _layoutMode == BarLayoutMode.overlaid)
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
    if (_playgroundActive || _preset == _BarLabPreset.pareto)
      OptionSection(
        key: const ValueKey('bar-options-cumulative-line'),
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
    if (_playgroundActive || _preset == _BarLabPreset.histogram)
      OptionSection(
        key: const ValueKey('bar-options-binning'),
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
          if (_playgroundActive ||
              _histogramMethod == HistogramBinningMethod.fixedCount)
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
    if (_playgroundActive ||
        _preset == _BarLabPreset.categories ||
        _preset == _BarLabPreset.stress)
      OptionSection(
        key: const ValueKey('bar-options-category-axis'),
        title: 'Category axis',
        icon: Icons.view_week_outlined,
        children: [
          if (_playgroundActive || _preset == _BarLabPreset.stress)
            IntSliderOption(
              key: const ValueKey('bar-lab-stress-category-count'),
              label: 'Category count',
              value: _stressCategoryCount,
              min: 12,
              max: _stressCategories.length,
              onChanged: (value) =>
                  setState(() => _stressCategoryCount = value),
            ),
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
      key: const ValueKey('bar-options-shape'),
      title: 'Shape',
      icon: Icons.rounded_corner,
      children: [
        if (_playgroundActive || _preset == _BarLabPreset.lollipop) ...[
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
        ],
        if (_playgroundActive || _preset != _BarLabPreset.lollipop) ...[
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
        if (_playgroundActive || _layoutMode != BarLayoutMode.waterfall)
          if (_playgroundActive ||
              (_preset != _BarLabPreset.bullet &&
                  _preset != _BarLabPreset.pareto &&
                  _preset != _BarLabPreset.histogram))
            BoolOption(
              label: 'Capacity tracks',
              value: _showTracks,
              onChanged: (value) => setState(() => _showTracks = value),
              subtitle: 'Show the available range behind each bar',
            ),
        if (_playgroundActive || _layoutMode == BarLayoutMode.waterfall)
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
        if (_playgroundActive || _layoutMode != BarLayoutMode.waterfall)
          if (_playgroundActive ||
              (_preset != _BarLabPreset.bullet &&
                  _preset != _BarLabPreset.lollipop))
            BoolOption(
              key: const ValueKey('bar-lab-gradient'),
              label: 'Gradient',
              value: _showGradient,
              onChanged: (value) => setState(() => _showGradient = value),
            ),
      ],
    ),
    if (_playgroundActive || _preset == _BarLabPreset.patterns)
      OptionSection(
        key: const ValueKey('bar-options-pattern-encoding'),
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
          if (_playgroundActive || _showPatterns)
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
          if (_playgroundActive || _showPatterns)
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
          if (_playgroundActive || _showPatterns)
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
    if (_playgroundActive || _preset == _BarLabPreset.bullet)
      OptionSection(
        key: const ValueKey('bar-options-bullet-ranges'),
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
    if (_playgroundActive || _preset == _BarLabPreset.likert)
      OptionSection(
        key: const ValueKey('bar-options-diverging-scale'),
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
          if (_playgroundActive || _showDivergingCenterLine)
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
      key: const ValueKey('bar-options-labels'),
      title: 'Labels',
      icon: Icons.label_outline,
      children: [
        BoolOption(
          label: 'Value labels',
          value: _showLabels,
          onChanged: (value) => setState(() => _showLabels = value),
        ),
        if (_playgroundActive || _showLabels)
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
        if (_playgroundActive || _showLabels)
          EnumOption<BarLabelRotationMode>(
            key: const ValueKey('bar-lab-label-rotation-mode'),
            label: 'Rotation behavior',
            value: _labelRotationMode,
            values: BarLabelRotationMode.values,
            labelBuilder: (value) => switch (value) {
              BarLabelRotationMode.fixed => 'Fixed angle',
              BarLabelRotationMode.autoFit => 'Auto fit',
            },
            onChanged: (value) => setState(() => _labelRotationMode = value),
          ),
        if (_playgroundActive || _showLabels)
          SliderOption(
            key: const ValueKey('bar-lab-label-rotation-degrees'),
            label: 'Value-label angle',
            value: _labelRotationDegrees,
            min: -180,
            max: 180,
            divisions: 24,
            suffix: '°',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _labelRotationDegrees = value),
          ),
        if (_playgroundActive ||
            (_showLabels && _labelPosition != BarLabelPosition.insideCenter))
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
        if (_playgroundActive ||
            (_showLabels &&
                (_preset == _BarLabPreset.labels ||
                    _preset == _BarLabPreset.config ||
                    _preset == _BarLabPreset.stress)))
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
        if (_playgroundActive ||
            (_showLabels &&
                (_preset == _BarLabPreset.labels ||
                    _preset == _BarLabPreset.config ||
                    _preset == _BarLabPreset.stress)))
          BoolOption(
            label: 'Plot-edge aware',
            value: _labelPlotEdgeAware,
            subtitle: 'Keep labels inside the visible plotting area',
            onChanged: (value) => setState(() => _labelPlotEdgeAware = value),
          ),
        if (_playgroundActive ||
            (_showLabels &&
                (_preset == _BarLabPreset.labels ||
                    _preset == _BarLabPreset.config ||
                    _preset == _BarLabPreset.stress) &&
                _labelCollisionPolicy != BarLabelCollisionPolicy.none))
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
        if (_playgroundActive ||
            (_showLabels &&
                (_preset == _BarLabPreset.labels ||
                    _preset == _BarLabPreset.config ||
                    _preset == _BarLabPreset.stress)))
          BoolOption(
            label: 'Label background',
            value: _showLabelBackground,
            subtitle: 'Add a restrained box when labels cross chart marks',
            onChanged: (value) => setState(() => _showLabelBackground = value),
          ),
        if (_playgroundActive ||
            (_showLabels &&
                (_preset == _BarLabPreset.labels ||
                    _preset == _BarLabPreset.config ||
                    _preset == _BarLabPreset.stress)))
          BoolOption(
            label: 'Callout lines',
            value: _showLabelCallouts,
            subtitle: 'Connect displaced labels to their value end',
            onChanged: (value) => setState(() => _showLabelCallouts = value),
          ),
        if (_playgroundActive ||
            (_showLabels &&
                (_layoutMode == BarLayoutMode.stacked ||
                    _layoutMode == BarLayoutMode.normalizedStacked)))
          BoolOption(
            label: 'Stack totals',
            value: _showStackTotals,
            subtitle: 'Show one resolved total at each stack end',
            onChanged: (value) => setState(() => _showStackTotals = value),
          ),
      ],
    ),
    if (_playgroundActive ||
        _preset == _BarLabPreset.targets ||
        _preset == _BarLabPreset.bullet ||
        (_preset == _BarLabPreset.config &&
            (_layoutMode == BarLayoutMode.grouped ||
                _layoutMode == BarLayoutMode.overlaid)))
      OptionSection(
        key: const ValueKey('bar-options-benchmarks'),
        title: 'Benchmarks',
        icon: Icons.flag_outlined,
        children: [
          BoolOption(
            label: 'Target markers',
            value: _showTargets,
            subtitle: 'Show one benchmark across each bar',
            onChanged: (value) => setState(() => _showTargets = value),
          ),
          if (_playgroundActive || _showTargets)
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
          if (_playgroundActive || _showTargets)
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
    if (_playgroundActive ||
        _preset == _BarLabPreset.uncertainty ||
        (_preset == _BarLabPreset.config &&
            (_layoutMode == BarLayoutMode.grouped ||
                _layoutMode == BarLayoutMode.overlaid)))
      OptionSection(
        key: const ValueKey('bar-options-uncertainty'),
        title: 'Uncertainty',
        icon: Icons.align_vertical_center,
        children: [
          BoolOption(
            label: 'Error bars',
            value: _showUncertainty,
            subtitle: 'Show absolute lower and upper bounds',
            onChanged: (value) => setState(() => _showUncertainty = value),
          ),
          if (_playgroundActive || _showUncertainty)
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
          if (_playgroundActive || _showUncertainty)
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
    if (_playgroundActive || _preset == _BarLabPreset.states)
      OptionSection(
        key: const ValueKey('bar-options-interaction'),
        title: 'Interaction',
        icon: Icons.touch_app_outlined,
        children: [
          EnumOption<ChartSelectionScope>(
            key: const ValueKey('bar-lab-selection-scope'),
            label: 'Selection scope',
            value: _selectionScope,
            values: _availableSelectionScopes,
            labelBuilder: _selectionScopeLabel,
            description:
                'Choose one mark, every mark at a category, or the same '
                'series across every category. A category stack is available '
                'only for stacked layouts.',
            onChanged: (value) => setState(() => _selectionScope = value),
          ),
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
    if (_playgroundActive || _preset == _BarLabPreset.motion)
      OptionSection(
        key: const ValueKey('bar-options-motion'),
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
          if (_playgroundActive || _motionOrder != BarAnimationOrder.together)
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
    OptionSection(
      key: const ValueKey('bar-options-point-popup'),
      title: 'Point popup',
      icon: Icons.chat_bubble_outline,
      children: [
        BoolOption(
          key: const ValueKey('bar-lab-show-data-point-popup'),
          label: 'Show Data Point Popup',
          subtitle:
              'Show the single-bar value popup for a directly hovered mark',
          value: _showDataPointPopup,
          onChanged: (value) => setState(() => _showDataPointPopup = value),
        ),
      ],
    ),
  ]);

  List<Widget> _prioritizePresetOptions(List<Widget> options) {
    final preferredKey = switch (_preset) {
      _BarLabPreset.targets => 'bar-options-benchmarks',
      _BarLabPreset.bullet => 'bar-options-bullet-ranges',
      _BarLabPreset.uncertainty => 'bar-options-uncertainty',
      _BarLabPreset.states => 'bar-options-interaction',
      _BarLabPreset.motion => 'bar-options-motion',
      _BarLabPreset.rotatedLabels ||
      _BarLabPreset.labels => 'bar-options-labels',
      _ => null,
    };
    if (preferredKey == null) return options;

    final index = options.indexWhere(
      (option) => option.key == ValueKey<String>(preferredKey),
    );
    if (index <= 0) return options;

    final preferred = options.removeAt(index);
    return <Widget>[preferred, ...options];
  }

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
        'bar_label_rotation_mode': switch (_labelRotationMode) {
          BarLabelRotationMode.fixed => 'fixed',
          BarLabelRotationMode.autoFit => 'auto_fit',
        },
        'bar_label_rotation_degrees': _labelRotationDegrees,
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
    if (_preset == _BarLabPreset.drilldown) return _buildDrillSeries();
    if (_preset == _BarLabPreset.race) return _buildRaceSeries();
    final values = _playgroundActive
        ? _playgroundValues
        : switch (_preset) {
            _BarLabPreset.capacity => const <double>[
              42,
              61,
              88,
              35,
              70,
              94,
              55,
            ],
            _BarLabPreset.bullet => const <double>[82, 64, 91, 73, 58, 87],
            _BarLabPreset.likert => const <double>[8, 12, 6, 15, 10, 7],
            _BarLabPreset.targets => const <double>[68, 74, 81, 57, 88, 92, 70],
            _BarLabPreset.uncertainty => const <double>[
              64,
              72,
              78,
              58,
              85,
              90,
              69,
            ],
            _BarLabPreset.lollipop => const <double>[
              54,
              72,
              61,
              88,
              69,
              94,
              76,
            ],
            _BarLabPreset.pareto => const <double>[],
            _BarLabPreset.histogram => const <double>[],
            _BarLabPreset.rtl => const <double>[96, 84, 73, 61, 49, 36],
            _BarLabPreset.rods => const <double>[34, 57, 46, 69, 81, 96, 62],
            _BarLabPreset.gradient => const <double>[
              28,
              49,
              64,
              91,
              73,
              84,
              58,
            ],
            _BarLabPreset.signed => const <double>[
              38,
              -24,
              52,
              -38,
              71,
              26,
              -18,
            ],
            _BarLabPreset.overlay => const <double>[42, 61, 88, 35, 70, 94, 55],
            _BarLabPreset.offset => const <double>[38, 39, 27, 17, 10],
            _BarLabPreset.range => const <double>[25, 29, 27, 31, 28, 24, 26],
            _BarLabPreset.waterfall => const <double>[
              82,
              28,
              16,
              -18,
              -24,
              7,
              0,
            ],
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
            _BarLabPreset.stress => List<double>.generate(
              _categories.length,
              (index) => (12 + index * 11 % 32).toDouble(),
              growable: false,
            ),
            _BarLabPreset.labels => const <double>[88, 91, 86, 93, 89, 95, 87],
            _BarLabPreset.rotatedLabels => const <double>[
              37.3,
              31.2,
              27.8,
              22.2,
              21.9,
              21.7,
              21.3,
              20.9,
              20.7,
              19.1,
              16.5,
              16.4,
            ],
            _BarLabPreset.drilldown => const <double>[],
            _BarLabPreset.race => const <double>[],
            _BarLabPreset.config => const <double>[],
            _BarLabPreset.patterns => const <double>[
              74,
              58,
              86,
              67,
              92,
              79,
              63,
            ],
            _BarLabPreset.motion =>
              _motionRevision.isEven
                  ? const <double>[54, 72, 61, 88, 69, 94, 76]
                  : const <double>[82, 48, 91, 63, 86, 57, 96],
            _BarLabPreset.states => const <double>[54, 72, 61, 88, 69, 94, 76],
            _BarLabPreset.stacked => const <double>[18, 24, 31, 22, 28, 35, 26],
            _BarLabPreset.normalized => const <double>[
              18,
              24,
              31,
              22,
              28,
              35,
              26,
            ],
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
      _BarLabPreset.stress => List<double>.generate(
        _categories.length,
        (index) => (14 + index * 17 % 30).toDouble(),
        growable: false,
      ),
      _BarLabPreset.labels => const <double>[90, 87, 92, 89, 94, 88, 93],
      _BarLabPreset.rotatedLabels => const <double>[
        35.8,
        29.7,
        26.4,
        21.1,
        20.8,
        20.5,
        19.9,
        19.7,
        19.4,
        18.6,
        15.9,
        15.6,
      ],
      _BarLabPreset.drilldown => const <double>[],
      _BarLabPreset.race => const <double>[],
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
          rotationMode: _labelRotationMode,
          rotationDegrees: _labelRotationDegrees,
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
          rotationMode: _labelRotationMode,
          rotationDegrees: _labelRotationDegrees,
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
          _preset == _BarLabPreset.normalized ||
          _preset == _BarLabPreset.stress) {
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
      if (_preset == _BarLabPreset.rotatedLabels) {
        return (14 + seed % 24).toDouble();
      }
      if (_preset == _BarLabPreset.drilldown) {
        return (18 + seed % 45).toDouble();
      }
      if (_preset == _BarLabPreset.race) {
        return (40 + seed % 120).toDouble();
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
    final categories = _categories;
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
            label: categories[index],
            pointStyle: _preset == _BarLabPreset.offset && seriesIndex == 1
                ? PointStyle.color(_medalColors[index])
                : null,
          ),
      ],
      isXOrdered: true,
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
        rotationMode: _labelRotationMode,
        rotationDegrees: _labelRotationDegrees,
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
    _BarLabPreset.stress => _stressCategories.sublist(0, _stressCategoryCount),
    _BarLabPreset.rotatedLabels => _cityCategories,
    _BarLabPreset.drilldown => [
      for (final value
          in (_drilldownController.current.metadata['categories']
                  as List<Object?>? ??
              const <Object?>[]))
        value.toString(),
    ],
    _BarLabPreset.race => [
      for (final value in _raceController.rankedValues) value.category.label,
    ],
    _ => _dayCategories,
  };

  bool get _usesNativeCategoryAxis =>
      _preset == _BarLabPreset.categories ||
      _preset == _BarLabPreset.stress ||
      _preset == _BarLabPreset.pareto ||
      _preset == _BarLabPreset.histogram ||
      _preset == _BarLabPreset.rtl ||
      _preset == _BarLabPreset.rotatedLabels ||
      _preset == _BarLabPreset.drilldown ||
      _preset == _BarLabPreset.race;

  void _applyPreset(_BarLabPreset preset) {
    _showcaseRandomizer.pause();
    _raceController.pause();
    if (preset == _BarLabPreset.race) {
      _raceController
        ..replaceConfig(_buildPopulationRaceConfig())
        ..setSpeed(1);
      _seekRaceToDefaultFrame();
    }
    _showcaseRandomizer.clear();
    _interactionGroupController.reset();
    _chartController
      ..clearPointFocus()
      ..clearPointSelection();
    _drilldownController.root();
    setState(() {
      _playgroundActive = false;
      _authoredPreset = preset;
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
    _labelRotationMode = BarLabelRotationMode.fixed;
    _labelRotationDegrees = 0;
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
    _drillShowBreadcrumbs = true;
    _drillActivation = BarDrillActivation.primaryAction;
    _drillTransition = BarDrillTransition.fadeThrough;
    _drillSelectionPolicy = BarDrillSelectionPolicy.clear;
    _selectionScope = ChartSelectionScope.mark;
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
      case _BarLabPreset.stress:
        _seriesCount = 8;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.normalizedStacked;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.9;
        _barGap = 1;
        _cornerRadius = 2;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideCenter;
        _labelCollisionPolicy = BarLabelCollisionPolicy.hide;
        _labelCollisionPadding = 2;
        _showStackTotals = false;
        _categoryLabelDensity = CategoryLabelDensity.auto;
        _categoryLabelOverflow = CategoryLabelOverflow.ellipsis;
        _categoryMinimumExtent = 48;
        _categoryMaxLines = 1;
        _categoryRotation = 0;
        _stressCategoryCount = 48;
        _cornerPolicy = BarCornerRadiusPolicy.all;
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
      case _BarLabPreset.rotatedLabels:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.66;
        _barGap = 3;
        _cornerRadius = 2;
        _showTracks = false;
        _showGradient = true;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.insideEnd;
        _labelRotationMode = BarLabelRotationMode.fixed;
        _labelRotationDegrees = -90;
        _labelEdgeOffset = 5;
        _labelCollisionPolicy = BarLabelCollisionPolicy.hide;
        _labelCollisionPadding = 2;
        _showLabelBackground = true;
        _showLabelCallouts = false;
        _categoryLabelDensity = CategoryLabelDensity.showAll;
        _categoryLabelOverflow = CategoryLabelOverflow.ellipsis;
        _categoryMinimumExtent = 48;
        _categoryMaxLines = 1;
        _categoryRotation = -45;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.drilldown:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.vertical;
        _barWidth = 0.68;
        _barGap = 5;
        _cornerRadius = 3;
        _showTracks = false;
        _showGradient = true;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.outsideEnd;
        _labelRotationMode = BarLabelRotationMode.fixed;
        _labelRotationDegrees = 0;
        _labelEdgeOffset = 6;
        _labelCollisionPolicy = BarLabelCollisionPolicy.reposition;
        _labelCollisionPadding = 3;
        _showLabelBackground = false;
        _showLabelCallouts = false;
        _categoryLabelDensity = CategoryLabelDensity.showAll;
        _categoryLabelOverflow = CategoryLabelOverflow.ellipsis;
        _categoryMinimumExtent = 56;
        _categoryMaxLines = 1;
        _categoryRotation = -45;
        _cornerPolicy = BarCornerRadiusPolicy.valueEnd;
      case _BarLabPreset.race:
        _seriesCount = 1;
        _stackGroupCount = 1;
        _layoutMode = BarLayoutMode.grouped;
        _orientation = BarOrientation.horizontal;
        _barWidth = 0.72;
        _barGap = 4;
        _cornerRadius = 4;
        _showTracks = false;
        _showGradient = false;
        _showBorder = false;
        _showLabels = true;
        _labelPosition = BarLabelPosition.rangeEnds;
        _labelRotationMode = BarLabelRotationMode.fixed;
        _labelRotationDegrees = 0;
        _labelEdgeOffset = 12;
        _labelCollisionPolicy = BarLabelCollisionPolicy.hide;
        _labelCollisionPadding = 2;
        _showLabelBackground = false;
        _showLabelCallouts = false;
        _categoryLabelDensity = CategoryLabelDensity.showAll;
        _categoryLabelOverflow = CategoryLabelOverflow.ellipsis;
        _categoryMinimumExtent = 42;
        _categoryMaxLines = 1;
        _categoryRotation = 0;
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
        _selectionScope = ChartSelectionScope.wholeSeries;
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

  String _presetTitle() => _playgroundActive
      ? 'Bar playground'
      : switch (_preset) {
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
          _BarLabPreset.stress => 'Dense category and label stress',
          _BarLabPreset.labels => 'Collision-aware value labels',
          _BarLabPreset.rotatedLabels => 'Vertical value labels',
          _BarLabPreset.drilldown =>
            _drillDataset == _BarDrillDataset.nutrition
                ? 'Granola recipe · ${_drilldownController.current.label}'
                : 'Revenue hierarchy · ${_drilldownController.current.label}',
          _BarLabPreset.race => 'Population by country',
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
    _BarLabPreset.stress =>
      'Hundreds of normalized segments exercise category scrolling and chart-wide label collision indexing without sacrificing frame time.',
    _BarLabPreset.labels =>
      'Labels share one chart-wide layout pass, fall back inside the bar, and can use restrained boxes or callouts.',
    _BarLabPreset.rotatedLabels =>
      'Value labels rotate independently from the category axis and can turn automatically when the authored angle does not fit.',
    _BarLabPreset.drilldown =>
      'Activate a bar to replace the effective dataset, then use the accessible breadcrumb to return to any ancestor.',
    _BarLabPreset.race =>
      'Illustrative stress data keeps country identities stable: close ranks exchange often and one off-screen challenger climbs into first place.',
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
      if (_preset == _BarLabPreset.stress)
        '${_categories.length * _seriesCount} labelled segments',
      if (_showLabels && _labelRotationDegrees != 0)
        '${_labelRotationDegrees.round()}° value labels',
      if (_preset == _BarLabPreset.drilldown)
        '${_drilldownController.path.length} hierarchy level${_drilldownController.path.length == 1 ? '' : 's'}',
      if (_preset == _BarLabPreset.race)
        '${_raceController.config.periodFormat.format(_raceController.currentFrame)} · top ${_raceController.config.topCount} · ${_raceController.config.axisRange.name} axis',
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
        '${_effectiveSelectedBarPointRefs.length} selected',
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

  String _selectionScopeLabel(ChartSelectionScope scope) => switch (scope) {
    ChartSelectionScope.mark => 'Single mark',
    ChartSelectionScope.category => 'All series at this category',
    ChartSelectionScope.categoryStack => 'Stack at this category',
    ChartSelectionScope.wholeSeries => 'Same series across all categories',
    ChartSelectionScope.markOrWholeSeries => 'Mark or complete series',
  };

  bool get _layoutHasComposableStacks =>
      _layoutMode == BarLayoutMode.stacked ||
      _layoutMode == BarLayoutMode.normalizedStacked ||
      _layoutMode == BarLayoutMode.divergingStacked;

  List<ChartSelectionScope> get _availableSelectionScopes => [
    ChartSelectionScope.mark,
    ChartSelectionScope.category,
    if (_layoutHasComposableStacks) ChartSelectionScope.categoryStack,
    ChartSelectionScope.wholeSeries,
    ChartSelectionScope.markOrWholeSeries,
  ];

  Set<ChartPointRef> get _effectiveSelectedBarPointRefs {
    final selectedRefs = <ChartPointRef>{..._chartController.selectedPointRefs};
    final selectedSeriesIds = _chartController.selectedSeriesIds;
    if (selectedSeriesIds.isEmpty) return selectedRefs;

    for (final series in _buildSeries().whereType<BarChartSeries>()) {
      if (!selectedSeriesIds.contains(series.id)) continue;
      for (
        var pointIndex = 0;
        pointIndex < series.points.length;
        pointIndex++
      ) {
        if (!series.points[pointIndex].isValid) continue;
        selectedRefs.add(
          ChartPointRef(seriesId: series.id, pointIndex: pointIndex),
        );
      }
    }
    return selectedRefs;
  }

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
