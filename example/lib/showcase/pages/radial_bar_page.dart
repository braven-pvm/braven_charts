// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

enum _RadialBarPresentation {
  progress('Progress', Icons.track_changes_outlined),
  signed('Signed baseline', Icons.compare_arrows_outlined),
  partial('Partial target', Icons.donut_small_outlined),
  dense('Dense tracks', Icons.density_medium_outlined);

  const _RadialBarPresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}

@immutable
class _RandomRadialBarState {
  const _RandomRadialBarState({
    required this.values,
    required this.minimum,
    required this.maximum,
    required this.baseline,
    required this.startAngle,
    required this.sweepAngle,
    required this.clockwise,
    required this.innerRadius,
    required this.outerRadius,
    required this.trackGap,
    required this.cornerRadius,
    required this.trackOpacity,
    required this.tickCount,
    required this.thresholdValue,
    required this.showThreshold,
  });

  final Map<String, num> values;
  final double minimum;
  final double maximum;
  final double baseline;
  final double startAngle;
  final double sweepAngle;
  final bool clockwise;
  final double innerRadius;
  final double outerRadius;
  final double trackGap;
  final double cornerRadius;
  final double trackOpacity;
  final int tickCount;
  final double thresholdValue;
  final bool showThreshold;
}

/// Public Radial Bar showcase and complete property workbench.
class RadialBarPage extends StatefulWidget {
  const RadialBarPage({super.key});

  @override
  State<RadialBarPage> createState() => _RadialBarPageState();
}

class _RadialBarPageState extends State<RadialBarPage> {
  static const _progressValues = <String, num>{
    'Activation': 92,
    'Retention': 78,
    'Adoption': 66,
    'Satisfaction': 84,
    'Expansion': 57,
  };

  static const _signedValues = <String, num>{
    'Acquisition': 64,
    'Support': -36,
    'Reliability': 82,
    'Churn': -52,
    'Advocacy': 48,
  };

  static const _partialValues = <String, num>{
    'Search': 88,
    'Social': 72,
    'Direct': 94,
    'Partner': 63,
    'Referral': 79,
  };

  static const _denseValues = <String, num>{
    'North': 82,
    'North-east': 64,
    'East': 91,
    'South-east': 58,
    'South': 76,
    'South-west': 49,
    'West': 86,
    'North-west': 69,
    'Central': 74,
    'Remote': 55,
    'Partner': 80,
    'Direct': 67,
  };

  static const _categoryPalette = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFE11D48),
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
    Color(0xFFDB2777),
    Color(0xFF0284C7),
    Color(0xFF65A30D),
  ];

  late final ShowcaseRandomizerController<_RandomRadialBarState> _randomizer;

  _RadialBarPresentation _presentation = _RadialBarPresentation.progress;
  bool _playgroundActive = false;
  int _chartRevision = 0;
  Map<String, num> _values = Map.of(_progressValues);

  double _minimum = 0;
  double _maximum = 100;
  double _baseline = 0;
  double _startAngle = -90;
  double _sweepAngle = 360;
  bool _clockwise = true;
  double _innerRadius = 0.22;
  double _outerRadius = 0.82;
  double _trackGap = 6;
  RadialBarTrackOrder _trackOrder = RadialBarTrackOrder.outerToInner;

  double _cornerRadius = 8;
  double _markOpacity = 1;
  double _borderWidth = 0;
  Color? _borderColor;
  Color? _barColor;
  Color? _trackColor;
  double _trackOpacity = 0.12;
  bool _showDataLabels = true;

  bool _showCategoryLabels = true;
  bool _showScaleLabels = true;
  bool _showGridLines = true;
  int _tickCount = 5;
  bool _showThreshold = true;
  double _thresholdValue = 75;
  Color? _thresholdColor;
  double _thresholdWidth = 1.5;
  bool _dashedThreshold = true;

  bool _showTooltip = true;
  ThemePreset _themePreset = ThemePreset.light;

  @override
  void initState() {
    super.initState();
    _randomizer = ShowcaseRandomizerController<_RandomRadialBarState>(
      generate: _generateRandomState,
      apply: _applyRandomState,
    );
  }

  @override
  void dispose() {
    _randomizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Radial Bar Charts',
      subtitle:
          'Compare independent category values on concentric tracks and one explicit angular scale',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('radial-bar-reset-example'),
          onPressed: _resetExample,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      playground: ChartPlaygroundConfig(
        active: _playgroundActive,
        optionsChildren: _buildOptions(),
        randomizer: _randomizer,
      ),
      randomizerKeyPrefix: 'radial-bar-randomizer',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final contentHeight = math.max(
          constraints.maxHeight,
          compact ? 980.0 : 800.0,
        );
        final content = SizedBox(
          height: contentHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresentationSelector(),
              const SizedBox(height: 16),
              Expanded(child: _buildChartCard()),
            ],
          ),
        );
        if (contentHeight <= constraints.maxHeight) return content;
        return SingleChildScrollView(
          key: const ValueKey('radial-bar-showcase-scroll'),
          primary: false,
          child: content,
        );
      },
    );
  }

  Widget _buildPresentationSelector() {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Choose a Radial Bar example',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a Radial Bar example',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('radial-bar-presentation-selector'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final presentation in _RadialBarPresentation.values)
                    ShowcaseExampleChoiceChip(
                      key: ValueKey(
                        'radial-bar-presentation-${presentation.name}',
                      ),
                      label: presentation.label,
                      icon: presentation.icon,
                      selected:
                          !_playgroundActive && _presentation == presentation,
                      onSelected: () => _applyPresentation(presentation),
                    ),
                  PlaygroundChoiceChip(
                    key: const ValueKey('radial-bar-playground'),
                    selected: _playgroundActive,
                    onSelected: () => _setPlaygroundActive(true),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _presentationDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final series = _buildSeries();
    final config = _buildConfig();
    final theme = _themePreset.theme;
    final subtitle =
        '${_values.length} independent tracks · '
        '${_minimum.toStringAsFixed(0)}–${_maximum.toStringAsFixed(0)} domain · '
        '${_sweepAngle.toStringAsFixed(0)}° sweep';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _chartTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BravenChartWorkbench(
                initialDisplayMode: ChartDisplayMode.chart,
                availableDisplayModes: const {
                  ChartDisplayMode.chart,
                  ChartDisplayMode.data,
                  ChartDisplayMode.split,
                  ChartDisplayMode.source,
                },
                sourceOptions: const ChartDartSourceOptions(
                  variableName: 'radialBarChart',
                ),
                splitBreakpoint: 1,
                splitGap: 8,
                minimumChartPaneExtent: 340,
                minimumTablePaneExtent: 380,
                maximumAutoTablePaneExtent: 520,
                autoFitTablePane: true,
                isSplitResizable: true,
                documentOptions: const ChartDocumentExtractOptions(
                  includeViewState: true,
                ),
                tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
                chartBuilder: (context, controller) => BravenChartPlus(
                  key: ValueKey('radial-bar-chart-$_chartRevision'),
                  series: [series],
                  radialBarChartConfig: config,
                  bravenChartController: controller,
                  theme: theme,
                  showLegend: false,
                  interactionConfig: InteractionConfig(
                    tooltip: TooltipConfig(enabled: _showTooltip),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  RadialBarChartSeries _buildSeries() {
    final colors = <String, Color>{
      for (final (index, category) in _values.keys.indexed)
        category:
            _barColor ?? _categoryPalette[index % _categoryPalette.length],
    };
    return RadialBarChartSeries.fromMap(
      id: 'radial-bar-showcase',
      name: _chartTitle,
      values: _values,
      barColors: colors,
      minimum: _minimum,
      maximum: _maximum,
      baseline: _baseline,
      unit: _minimum < 0 ? 'pts' : '%',
      radialBarStyle: RadialBarStyle(
        cornerRadius: _cornerRadius,
        opacity: _markOpacity,
        borderColor: _borderColor,
        borderWidth: _borderWidth,
        trackColor: _trackColor,
        trackOpacity: _trackOpacity,
        showDataLabels: _showDataLabels,
      ),
    );
  }

  RadialBarChartConfig _buildConfig() => RadialBarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: _startAngle,
      sweepAngleDegrees: _sweepAngle,
      clockwise: _clockwise,
      innerRadiusFactor: _innerRadius,
      outerRadiusFactor: _outerRadius,
    ),
    trackGap: _trackGap,
    trackOrder: _trackOrder,
    showCategoryLabels: _showCategoryLabels,
    showScaleLabels: _showScaleLabels,
    showGridLines: _showGridLines,
    tickCount: _tickCount,
    thresholds: _showThreshold
        ? [
            RadialBarThreshold(
              value: _thresholdValue.clamp(_minimum, _maximum),
              label: 'Target ${_thresholdValue.toStringAsFixed(0)}',
              color: _thresholdColor,
              width: _thresholdWidth,
              dashPattern: _dashedThreshold ? const [6, 4] : const [],
            ),
          ]
        : const [],
  );

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Chart appearance',
      icon: Icons.palette_outlined,
      description:
          'Select the chart theme and optionally override the category marks, tracks, and borders.',
      children: [
        EnumOption<ThemePreset>(
          label: 'Theme',
          value: _themePreset,
          values: ThemePreset.values,
          labelBuilder: (value) => value.displayName,
          onChanged: (value) => setState(() => _themePreset = value),
        ),
        PaletteColorOption(
          label: 'Bar color override',
          subtitle: 'Clear to use a distinct color for every category.',
          value: _barColor,
          keyPrefix: 'radial-bar-mark-color',
          customColorFallback: const Color(0xFF2563EB),
          onChanged: (value) => setState(() => _barColor = value),
        ),
        PaletteColorOption(
          label: 'Track color',
          subtitle: 'Clear to derive the track from each mark color.',
          value: _trackColor,
          keyPrefix: 'radial-bar-track-color',
          customColorFallback: const Color(0xFF94A3B8),
          onChanged: (value) => setState(() => _trackColor = value),
        ),
        PaletteColorOption(
          label: 'Border color',
          value: _borderColor,
          enabled: _borderWidth > 0,
          onEnabledChanged: (enabled) => setState(() {
            _borderWidth = enabled ? math.max(_borderWidth, 1) : 0;
          }),
          keyPrefix: 'radial-bar-border-color',
          customColorFallback: const Color(0xFF0F172A),
          onChanged: (value) => setState(() => _borderColor = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Polar geometry',
      icon: Icons.donut_small_outlined,
      description:
          'Controls the angular pane and the annular space available to category tracks.',
      children: [
        SliderOption(
          label: 'Start angle',
          value: _startAngle,
          min: -180,
          max: 180,
          divisions: 36,
          suffix: '°',
          onChanged: (value) => setState(() => _startAngle = value),
        ),
        SliderOption(
          label: 'Sweep angle',
          value: _sweepAngle,
          min: 90,
          max: 360,
          divisions: 27,
          suffix: '°',
          onChanged: (value) => setState(() => _sweepAngle = value),
        ),
        BoolOption(
          label: 'Clockwise',
          value: _clockwise,
          onChanged: (value) => setState(() => _clockwise = value),
        ),
        SliderOption(
          label: 'Inner radius',
          value: _innerRadius,
          min: 0,
          max: math.max(0, _outerRadius - 0.1),
          divisions: 16,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _innerRadius = value),
        ),
        SliderOption(
          label: 'Outer radius',
          value: _outerRadius,
          min: math.min(1, _innerRadius + 0.1),
          max: 1,
          divisions: 16,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _outerRadius = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Tracks and marks',
      icon: Icons.view_stream_outlined,
      description:
          'Adjust track order, physical separation, rounded ends, opacity, and mark borders.',
      children: [
        EnumOption<RadialBarTrackOrder>(
          label: 'Track order',
          value: _trackOrder,
          values: RadialBarTrackOrder.values,
          labelBuilder: (value) => switch (value) {
            RadialBarTrackOrder.outerToInner => 'First category outside',
            RadialBarTrackOrder.innerToOuter => 'First category inside',
          },
          onChanged: (value) => setState(() => _trackOrder = value),
        ),
        SliderOption(
          label: 'Track gap',
          value: _trackGap,
          min: 0,
          max: 18,
          divisions: 18,
          suffix: 'px',
          onChanged: (value) => setState(() => _trackGap = value),
        ),
        SliderOption(
          label: 'Corner radius',
          value: _cornerRadius,
          min: 0,
          max: 20,
          divisions: 20,
          suffix: 'px',
          onChanged: (value) => setState(() => _cornerRadius = value),
        ),
        SliderOption(
          label: 'Mark opacity',
          value: _markOpacity,
          min: 0.1,
          max: 1,
          divisions: 18,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _markOpacity = value),
        ),
        SliderOption(
          label: 'Track opacity',
          value: _trackOpacity,
          min: 0,
          max: 0.5,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _trackOpacity = value),
        ),
        SliderOption(
          label: 'Border width',
          value: _borderWidth,
          min: 0,
          max: 4,
          divisions: 8,
          suffix: 'px',
          onChanged: (value) => setState(() => _borderWidth = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Scale, labels, and target',
      icon: Icons.straighten_outlined,
      description:
          'Configures the shared numeric angular scale, visible labels, grid rings, and absolute target guide.',
      children: [
        BoolOption(
          label: 'Category labels',
          value: _showCategoryLabels,
          onChanged: (value) => setState(() => _showCategoryLabels = value),
        ),
        BoolOption(
          label: 'Value labels',
          value: _showDataLabels,
          onChanged: (value) => setState(() => _showDataLabels = value),
        ),
        BoolOption(
          label: 'Scale labels',
          value: _showScaleLabels,
          onChanged: (value) => setState(() => _showScaleLabels = value),
        ),
        BoolOption(
          label: 'Grid lines',
          value: _showGridLines,
          onChanged: (value) => setState(() => _showGridLines = value),
        ),
        IntSliderOption(
          label: 'Tick count',
          value: _tickCount,
          min: 2,
          max: 12,
          onChanged: (value) => setState(() => _tickCount = value),
        ),
        BoolOption(
          label: 'Target guide',
          value: _showThreshold,
          onChanged: (value) => setState(() => _showThreshold = value),
        ),
        if (_showThreshold) ...[
          SliderOption(
            label: 'Target value',
            value: _thresholdValue.clamp(_minimum, _maximum),
            min: _minimum,
            max: _maximum,
            divisions: 40,
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _thresholdValue = value),
          ),
          SliderOption(
            label: 'Target width',
            value: _thresholdWidth,
            min: 0.5,
            max: 5,
            divisions: 9,
            suffix: 'px',
            onChanged: (value) => setState(() => _thresholdWidth = value),
          ),
          BoolOption(
            label: 'Dashed target',
            value: _dashedThreshold,
            onChanged: (value) => setState(() => _dashedThreshold = value),
          ),
          PaletteColorOption(
            label: 'Target color',
            value: _thresholdColor,
            keyPrefix: 'radial-bar-threshold-color',
            customColorFallback: const Color(0xFFDC2626),
            onChanged: (value) => setState(() => _thresholdColor = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Interaction',
      icon: Icons.touch_app_outlined,
      description:
          'Radial Bar uses the shared chart hit testing, focus, selection, keyboard, and tooltip contracts.',
      initiallyExpanded: false,
      children: [
        BoolOption(
          label: 'Data point popup',
          value: _showTooltip,
          onChanged: (value) => setState(() => _showTooltip = value),
        ),
        const InfoBox(
          message:
              'Hover or tap a track to inspect it. Use Tab and the arrow keys to move between categories, then Enter to select.',
        ),
      ],
    ),
  ];

  void _applyPresentation(_RadialBarPresentation presentation) {
    _randomizer.pause();
    _randomizer.clear();
    setState(() {
      _playgroundActive = false;
      _presentation = presentation;
      _chartRevision++;
      _applyPresentationState(presentation);
    });
  }

  void _applyPresentationState(_RadialBarPresentation presentation) {
    _trackOrder = RadialBarTrackOrder.outerToInner;
    _markOpacity = 1;
    _borderWidth = 0;
    _borderColor = null;
    _barColor = null;
    _trackColor = null;
    _showCategoryLabels = true;
    _showScaleLabels = true;
    _showGridLines = true;
    _showDataLabels = true;
    _showTooltip = true;
    _clockwise = true;
    _tickCount = 5;
    _thresholdWidth = 1.5;
    _thresholdColor = null;
    _dashedThreshold = true;
    _themePreset = ThemePreset.light;

    switch (presentation) {
      case _RadialBarPresentation.progress:
        _values = Map.of(_progressValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.22;
        _outerRadius = 0.82;
        _trackGap = 6;
        _cornerRadius = 8;
        _trackOpacity = 0.12;
        _showThreshold = true;
        _thresholdValue = 75;
      case _RadialBarPresentation.signed:
        _values = Map.of(_signedValues);
        _minimum = -100;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.2;
        _outerRadius = 0.84;
        _trackGap = 7;
        _cornerRadius = 7;
        _trackOpacity = 0.1;
        _showThreshold = true;
        _thresholdValue = 50;
      case _RadialBarPresentation.partial:
        _values = Map.of(_partialValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -135;
        _sweepAngle = 270;
        _innerRadius = 0.24;
        _outerRadius = 0.84;
        _trackGap = 8;
        _cornerRadius = 10;
        _trackOpacity = 0.14;
        _showThreshold = true;
        _thresholdValue = 80;
      case _RadialBarPresentation.dense:
        _values = Map.of(_denseValues);
        _minimum = 0;
        _maximum = 100;
        _baseline = 0;
        _startAngle = -90;
        _sweepAngle = 360;
        _innerRadius = 0.12;
        _outerRadius = 0.9;
        _trackGap = 3;
        _cornerRadius = 4;
        _trackOpacity = 0.1;
        _showThreshold = false;
        _thresholdValue = 75;
    }
  }

  void _setPlaygroundActive(bool active) {
    setState(() => _playgroundActive = active);
    if (active && !_randomizer.hasGeneratedValue) {
      _randomizer.generateCurrent();
    }
  }

  void _resetExample() {
    _randomizer.pause();
    _randomizer.clear();
    setState(() {
      _playgroundActive = false;
      _presentation = _RadialBarPresentation.progress;
      _chartRevision++;
      _applyPresentationState(_presentation);
    });
  }

  _RandomRadialBarState _generateRandomState(int seed) {
    final random = math.Random(seed);
    final signed = random.nextBool();
    final minimum = signed ? -100.0 : 0.0;
    const maximum = 100.0;
    final baseline = signed ? 0.0 : minimum;
    final categoryCount = 4 + random.nextInt(9);
    final values = <String, num>{
      for (var index = 0; index < categoryCount; index++)
        'Category ${index + 1}':
            minimum + random.nextDouble() * (maximum - minimum),
    };
    final sweep = 180.0 + random.nextInt(19) * 10.0;
    final threshold = minimum + random.nextDouble() * (maximum - minimum);
    return _RandomRadialBarState(
      values: values,
      minimum: minimum,
      maximum: maximum,
      baseline: baseline,
      startAngle: -180 + random.nextInt(37) * 10.0,
      sweepAngle: sweep,
      clockwise: random.nextBool(),
      innerRadius: 0.08 + random.nextDouble() * 0.28,
      outerRadius: 0.75 + random.nextDouble() * 0.2,
      trackGap: random.nextDouble() * 12,
      cornerRadius: random.nextDouble() * 16,
      trackOpacity: 0.06 + random.nextDouble() * 0.22,
      tickCount: 3 + random.nextInt(8),
      thresholdValue: threshold,
      showThreshold: random.nextBool(),
    );
  }

  void _applyRandomState(_RandomRadialBarState value) {
    if (!mounted) return;
    setState(() {
      _playgroundActive = true;
      _chartRevision++;
      _values = Map.of(value.values);
      _minimum = value.minimum;
      _maximum = value.maximum;
      _baseline = value.baseline;
      _startAngle = value.startAngle;
      _sweepAngle = value.sweepAngle;
      _clockwise = value.clockwise;
      _innerRadius = value.innerRadius;
      _outerRadius = value.outerRadius;
      _trackGap = value.trackGap;
      _cornerRadius = value.cornerRadius;
      _trackOpacity = value.trackOpacity;
      _tickCount = value.tickCount;
      _thresholdValue = value.thresholdValue;
      _showThreshold = value.showThreshold;
      _barColor = null;
    });
  }

  String get _chartTitle => _playgroundActive
      ? 'Generated category tracks'
      : switch (_presentation) {
          _RadialBarPresentation.progress => 'Customer journey progress',
          _RadialBarPresentation.signed => 'Net contribution by driver',
          _RadialBarPresentation.partial => 'Channel target attainment',
          _RadialBarPresentation.dense => 'Regional operating profile',
        };

  String get _presentationDescription => switch (_presentation) {
    _RadialBarPresentation.progress =>
      'Each category owns an independent track on one explicit 0–100 scale.',
    _RadialBarPresentation.signed =>
      'Marks grow in either direction from an explicit zero baseline.',
    _RadialBarPresentation.partial =>
      'A partial pane preserves absolute values and one shared target guide.',
    _RadialBarPresentation.dense =>
      'Compact geometry reduces physical gaps while keeping every category hit-testable.',
  };
}
