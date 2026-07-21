// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _RangeAreaPreset {
  temperature,
  seasonal,
  confidence,
  forecastFan,
  volatility,
  gapsAndSteps,
}

enum _SummaryPresentation { overlay, draggableAnnotation }

enum _SummaryAnchor { topLeft, topRight, bottomLeft, bottomRight }

class RangeAreaChartsPage extends StatefulWidget {
  const RangeAreaChartsPage({super.key});

  @override
  State<RangeAreaChartsPage> createState() => _RangeAreaChartsPageState();
}

class _RangeAreaChartsPageState extends State<RangeAreaChartsPage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showDataMarkers: true),
  );

  _RangeAreaPreset _preset = _RangeAreaPreset.temperature;
  LineInterpolation _interpolation = LineInterpolation.monotone;
  RangeAreaBorderMode _borderMode = RangeAreaBorderMode.boundaries;
  RangeAreaHitTestMode _hitTestMode = RangeAreaHitTestMode.band;
  double _fillOpacity = 0.3;
  double _boundaryWidth = 1.8;
  double _boundaryGlow = 0;
  double _markerRadius = 3.5;
  bool _useGradient = true;
  bool _showUpperBoundary = true;
  bool _showLowerBoundary = true;
  bool _dashLowerBoundary = false;
  bool _showObservedLine = true;
  bool _connectGaps = false;
  bool _trackingEnabled = true;
  bool _showTrackingTooltip = true;
  bool _showCoordinateLabels = true;
  bool _showIntersectionMarkers = true;
  bool _interpolateTracking = true;
  bool _showValueSummary = true;
  bool _keyboardNavigation = true;
  RangeAreaLabelValue _labelValue = RangeAreaLabelValue.none;
  DataPointLabelCollisionPolicy _labelCollision =
      DataPointLabelCollisionPolicy.reposition;
  _SummaryPresentation _summaryPresentation = _SummaryPresentation.overlay;
  _SummaryAnchor _summaryAnchor = _SummaryAnchor.topLeft;
  double _summaryOpacity = 0.92;
  double _summaryCornerRadius = 10;
  bool _reducedMotion = false;
  double _motionDuration = 650;
  double _pointCount = 24;
  double _breadthScale = 1;
  int _dataRevision = 0;
  Color? _bandColor;
  Color? _upperBoundaryColor;
  Color? _lowerBoundaryColor;

  @override
  void initState() {
    super.initState();
    final requestedPreset = Uri.base.queryParameters['preset'];
    for (final preset in _RangeAreaPreset.values) {
      if (preset.name == requestedPreset) {
        _setPresetDefaults(preset);
        break;
      }
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _workbenchController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _reset() {
    _optionsController.update(const ChartOptions(showDataMarkers: true));
    setState(() {
      _preset = _RangeAreaPreset.temperature;
      _interpolation = LineInterpolation.monotone;
      _borderMode = RangeAreaBorderMode.boundaries;
      _hitTestMode = RangeAreaHitTestMode.band;
      _fillOpacity = 0.3;
      _boundaryWidth = 1.8;
      _boundaryGlow = 0;
      _markerRadius = 3.5;
      _useGradient = true;
      _showUpperBoundary = true;
      _showLowerBoundary = true;
      _dashLowerBoundary = false;
      _showObservedLine = true;
      _connectGaps = false;
      _trackingEnabled = true;
      _showTrackingTooltip = true;
      _showCoordinateLabels = true;
      _showIntersectionMarkers = true;
      _interpolateTracking = true;
      _showValueSummary = true;
      _keyboardNavigation = true;
      _labelValue = RangeAreaLabelValue.none;
      _labelCollision = DataPointLabelCollisionPolicy.reposition;
      _summaryPresentation = _SummaryPresentation.overlay;
      _summaryAnchor = _SummaryAnchor.topLeft;
      _summaryOpacity = 0.92;
      _summaryCornerRadius = 10;
      _reducedMotion = false;
      _motionDuration = 650;
      _pointCount = _temperatureRanges.length.toDouble();
      _breadthScale = 1;
      _dataRevision = 0;
      _bandColor = null;
      _upperBoundaryColor = null;
      _lowerBoundaryColor = null;
    });
    _persistPreset(_RangeAreaPreset.temperature);
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Range Area Charts',
      subtitle:
          'Show an interval between paired low and high values on the shared Cartesian surface',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('range-area-replay-entrance'),
          onPressed: _reducedMotion
              ? null
              : _chartController.replaySeriesEntrance,
          icon: const Icon(Icons.play_arrow_outlined, size: 18),
          label: const Text('Replay entrance'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('range-area-animate-update'),
          onPressed: () => setState(() => _dataRevision++),
          icon: const Icon(Icons.autorenew, size: 18),
          label: const Text('Animate update'),
        ),
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPresetPicker(compact: compact),
              SizedBox(height: compact ? 8 : 16),
              Expanded(child: _buildChartCard(compact: compact)),
              if (!compact) ...[
                const SizedBox(height: 16),
                const _RangeAreaCoverageStrip(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetPicker({required bool compact}) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('range-area-preset-picker'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a range area example',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _presetChip(
                  _RangeAreaPreset.temperature,
                  label: 'Temperature',
                  icon: Icons.thermostat_outlined,
                ),
                _presetChip(
                  _RangeAreaPreset.seasonal,
                  label: 'Seasonal',
                  icon: Icons.calendar_month_outlined,
                ),
                _presetChip(
                  _RangeAreaPreset.confidence,
                  label: 'Confidence',
                  icon: Icons.query_stats_outlined,
                ),
                _presetChip(
                  _RangeAreaPreset.forecastFan,
                  label: 'Forecast fan',
                  icon: Icons.filter_tilt_shift_outlined,
                ),
                _presetChip(
                  _RangeAreaPreset.volatility,
                  label: 'Volatility',
                  icon: Icons.candlestick_chart_outlined,
                ),
                _presetChip(
                  _RangeAreaPreset.gapsAndSteps,
                  label: 'Gaps & steps',
                  icon: Icons.stacked_line_chart_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _presetDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(
    _RangeAreaPreset preset, {
    required String label,
    required IconData icon,
  }) => ShowcaseExampleChoiceChip(
    key: ValueKey('range-area-preset-${preset.name}'),
    label: label,
    icon: icon,
    selected: _preset == preset,
    onSelected: () => _applyPreset(preset),
  );

  void _applyPreset(_RangeAreaPreset preset) {
    setState(() => _setPresetDefaults(preset));
    _persistPreset(preset);
  }

  void _setPresetDefaults(_RangeAreaPreset preset) {
    _preset = preset;
    _interpolation = preset == _RangeAreaPreset.gapsAndSteps
        ? LineInterpolation.stepped
        : LineInterpolation.monotone;
    _showObservedLine = switch (preset) {
      _RangeAreaPreset.seasonal || _RangeAreaPreset.gapsAndSteps => false,
      _ => true,
    };
    _useGradient = preset != _RangeAreaPreset.gapsAndSteps;
    _connectGaps = false;
    _pointCount = _baseRangePoints.length.toDouble();
    _breadthScale = 1;
    _dataRevision = 0;
  }

  void _persistPreset(_RangeAreaPreset preset) {
    if (!kIsWeb) return;
    final query = Map<String, String>.from(Uri.base.queryParameters);
    query['preset'] = preset.name;
    final location = Uri(
      path: Uri.base.path,
      queryParameters: query,
    ).toString();
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(location),
      replace: true,
    );
  }

  String get _presetDescription => switch (_preset) {
    _RangeAreaPreset.temperature =>
      'Daily minimum and maximum temperatures form one interval; the observed mean remains an independent line.',
    _RangeAreaPreset.seasonal =>
      'A range-only annual envelope varies in both centre and breadth without an extra midpoint series.',
    _RangeAreaPreset.confidence =>
      'A model estimate sits inside one 90% confidence interval with a deliberate missing interval.',
    _RangeAreaPreset.forecastFan =>
      'Nested 50% and 95% intervals share one forecast centre while uncertainty expands over time.',
    _RangeAreaPreset.volatility =>
      'A rolling price envelope uses paired boundaries and an independently tracked close line.',
    _RangeAreaPreset.gapsAndSteps =>
      'Stepped intervals preserve explicit missing windows and demonstrate optional gap connection.',
  };

  Widget _buildChartCard({required bool compact}) {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        final options = _optionsController.options;
        return ChartCard(
          key: const ValueKey('range-area-reference-card'),
          title: _chartTitle,
          subtitle:
              '${_rangePoints.where((point) => !point.isGap).length} intervals · ${_interpolation.name} · ${(_fillOpacity * 100).round()}% fill${_useGradient ? ' · gradient' : ''} · typed tracking',
          padding: EdgeInsets.all(compact ? 8 : 16),
          child: BravenChartWorkbench(
            key: const ValueKey('range-area-workbench'),
            chartController: _chartController,
            workbenchController: _workbenchController,
            availableDisplayModes: const {
              ChartDisplayMode.chart,
              ChartDisplayMode.data,
              ChartDisplayMode.split,
              ChartDisplayMode.source,
            },
            documentOptions: ChartDocumentExtractOptions(
              documentId: 'range-area-${_preset.name}-showcase',
              includeViewState: true,
              dataStorage: ChartDataStorage.inlineColumns,
            ),
            tableOptions: const ChartTableOptions(includeMetadata: true),
            tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
            sourceOptions: const ChartDartSourceOptions(
              variableName: 'rangeAreaChart',
            ),
            splitBreakpoint: 760,
            splitAxis: compact ? Axis.vertical : Axis.horizontal,
            splitGap: 8,
            splitRatio: compact ? .52 : .58,
            minimumChartPaneExtent: compact ? 260 : 340,
            minimumTablePaneExtent: compact ? 260 : 420,
            maximumAutoTablePaneExtent: 640,
            autoFitTablePane: true,
            isSplitResizable: true,
            chartBuilder: (context, controller) =>
                _buildChart(options, controller),
          ),
        );
      },
    );
  }

  Widget _buildChart(ChartOptions options, BravenChartController controller) {
    final baseColor = _bandColor ?? _presetColor;
    final points = _rangePoints;
    final theme = options.theme ?? ChartTheme.light;
    final animation = PathAnimationStyle(
      entranceMode: _reducedMotion
          ? PathEntranceAnimationMode.none
          : PathEntranceAnimationMode.reveal,
      dataUpdateMode: _reducedMotion
          ? PathDataUpdateAnimationMode.none
          : PathDataUpdateAnimationMode.interpolate,
      entranceTiming: PathAnimationTiming(
        duration: Duration(milliseconds: _motionDuration.round()),
      ),
      dataUpdateTiming: PathAnimationTiming(
        duration: Duration(milliseconds: _motionDuration.round()),
      ),
    );
    RangeAreaChartSeries buildBand({
      required String id,
      required String name,
      required List<RangeAreaDataPoint> bandPoints,
      required Color color,
      double opacityScale = 1,
      double boundaryScale = 1,
      bool primary = true,
    }) => RangeAreaChartSeries(
      id: id,
      name: name,
      points: bandPoints,
      color: color,
      unit: _unit,
      interpolation: _interpolation,
      fillOpacity: (_fillOpacity * opacityScale).clamp(0.02, 0.82).toDouble(),
      fillGradient: _useGradient
          ? AreaGradient(
              colors: [Color.lerp(color, Colors.white, 0.42)!, color],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : null,
      borderMode: _borderMode,
      upperBoundaryStyle: RangeAreaBoundaryStyle(
        visible: _showUpperBoundary,
        color: _upperBoundaryColor,
        strokeWidth: _boundaryWidth * boundaryScale,
        glowRadius: _boundaryGlow,
      ),
      lowerBoundaryStyle: RangeAreaBoundaryStyle(
        visible: _showLowerBoundary,
        color: _lowerBoundaryColor,
        strokeWidth: _boundaryWidth * boundaryScale,
        dashPattern: _dashLowerBoundary ? const [6, 4] : const [],
        glowRadius: _boundaryGlow,
      ),
      connectGaps: _connectGaps,
      showBoundaryMarkers: options.showDataMarkers && primary,
      markerRadius: _markerRadius,
      labelConfig: RangeAreaLabelConfig(
        value: primary ? _labelValue : RangeAreaLabelValue.none,
        boundaryGap: 6,
        labels: DataPointLabelConfig(
          show: primary && _labelValue != RangeAreaLabelValue.none,
          collisionPolicy: _labelCollision,
          showUnit: true,
          background: Theme.of(context).colorScheme.surface,
          backgroundOpacity: 0.88,
        ),
      ),
      hitTestMode: _hitTestMode,
      pathAnimation: animation,
    );
    final series = <ChartSeries>[
      buildBand(
        id: '${_preset.name}-range',
        name: _rangeSeriesName,
        bandPoints: points,
        color: baseColor,
      ),
      if (_secondaryRangePoints case final secondaryPoints?)
        buildBand(
          id: '${_preset.name}-inner-range',
          name: '50% forecast interval',
          bandPoints: secondaryPoints,
          color: Color.lerp(baseColor, _lineColor, 0.3)!,
          opacityScale: 1.45,
          boundaryScale: 0.8,
          primary: false,
        ),
      if (_showObservedLine)
        LineChartSeries(
          id: '${_preset.name}-observed',
          name: _lineSeriesName,
          points: _observedPoints,
          color: _lineColor,
          unit: _unit,
          interpolation: _interpolation,
          strokeWidth: 2.4,
          showDataPointMarkers: true,
          dataPointMarkerRadius: 3.4,
          pathAnimation: animation,
        ),
    ];
    return BravenChartPlus(
      key: ValueKey('range-area-chart-${_preset.name}'),
      bravenChartController: controller,
      series: series,
      theme: theme,
      showLegend: options.showLegend,
      grid: GridConfig(
        horizontal: options.showGrid,
        vertical: options.showGrid,
      ),
      xAxisConfig: XAxisConfig(
        label: _xAxisLabel,
        showAxisLine: options.showAxisLines,
      ),
      yAxis: YAxisConfig(
        label: _yAxisLabel,
        position: YAxisPosition.left,
        showAxisLine: options.showAxisLines,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: options.enableZoom,
        enablePan: options.enablePan,
        showXScrollbar: options.showXScrollbar,
        showYScrollbar: options.showYScrollbar,
        keyboard: KeyboardConfig(enabled: _keyboardNavigation),
        crosshair: CrosshairConfig(
          enabled: _trackingEnabled,
          mode: CrosshairMode.vertical,
          snapToDataPoint: true,
          displayMode: CrosshairDisplayMode.tracking,
          interpolateValues: _interpolateTracking,
          showTrackingTooltip: _showTrackingTooltip,
          showCoordinateLabels: _showCoordinateLabels,
          showIntersectionMarkers: _showIntersectionMarkers,
        ),
        tooltip: const TooltipConfig(enabled: true),
        valueSummary: CartesianValueSummaryConfig(
          enabled: _showValueSummary,
          presentation: switch (_summaryPresentation) {
            _SummaryPresentation.overlay =>
              CartesianValueSummaryPresentation.overlay(
                placement: _summaryPlacement,
              ),
            _SummaryPresentation.draggableAnnotation =>
              CartesianValueSummaryPresentation.annotation(
                placement: _summaryPlacement,
                draggable: true,
              ),
          },
          valuePolicy: CartesianValueSummaryValuePolicy.trackingThenLatest,
          style: CartesianValueSummaryStyle(
            backgroundOpacity: ChartStyleValue.value(_summaryOpacity),
            borderRadius: ChartStyleValue.value(
              BorderRadius.circular(_summaryCornerRadius),
            ),
            maxWidth: const ChartStyleValue.value(220),
            labelValueGap: const ChartStyleValue.value(12),
          ),
        ),
      ),
    );
  }

  ChartOverlayPlacement get _summaryPlacement => ChartOverlayPlacement(
    anchor: switch (_summaryAnchor) {
      _SummaryAnchor.topLeft => Alignment.topLeft,
      _SummaryAnchor.topRight => Alignment.topRight,
      _SummaryAnchor.bottomLeft => Alignment.bottomLeft,
      _SummaryAnchor.bottomRight => Alignment.bottomRight,
    },
    offset: const Offset(12, 12),
  );

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Range Area options',
      icon: Icons.area_chart_outlined,
      children: [
        EnumOption<LineInterpolation>(
          label: 'Interpolation',
          value: _interpolation,
          values: LineInterpolation.values,
          onChanged: (value) => setState(() => _interpolation = value),
        ),
        SliderOption(
          label: 'Fill opacity',
          value: _fillOpacity,
          min: 0.05,
          max: 0.65,
          divisions: 12,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _fillOpacity = value),
        ),
        BoolOption(
          label: 'Use gradient fill',
          value: _useGradient,
          onChanged: (value) => setState(() => _useGradient = value),
        ),
        EnumOption<RangeAreaBorderMode>(
          label: 'Border mode',
          value: _borderMode,
          values: RangeAreaBorderMode.values,
          onChanged: (value) => setState(() => _borderMode = value),
        ),
        EnumOption<RangeAreaHitTestMode>(
          label: 'Hit test mode',
          value: _hitTestMode,
          values: RangeAreaHitTestMode.values,
          onChanged: (value) => setState(() => _hitTestMode = value),
        ),
        BoolOption(
          label: 'Show observed line',
          value: _showObservedLine,
          onChanged: (value) => setState(() => _showObservedLine = value),
        ),
        BoolOption(
          label: 'Connect gaps',
          subtitle: 'Disabled gaps produce no tracked interval',
          value: _connectGaps,
          onChanged: (value) => setState(() => _connectGaps = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Boundaries and markers',
      icon: Icons.border_outer,
      children: [
        BoolOption(
          label: 'Show upper boundary',
          value: _showUpperBoundary,
          onChanged: (value) => setState(() => _showUpperBoundary = value),
        ),
        BoolOption(
          label: 'Show lower boundary',
          value: _showLowerBoundary,
          onChanged: (value) => setState(() => _showLowerBoundary = value),
        ),
        BoolOption(
          label: 'Dash lower boundary',
          value: _dashLowerBoundary,
          onChanged: (value) => setState(() => _dashLowerBoundary = value),
        ),
        SliderOption(
          label: 'Boundary width',
          value: _boundaryWidth,
          min: 0.5,
          max: 5,
          divisions: 18,
          suffix: 'px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _boundaryWidth = value),
        ),
        SliderOption(
          label: 'Boundary glow',
          value: _boundaryGlow,
          min: 0,
          max: 10,
          divisions: 10,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _boundaryGlow = value),
        ),
        SliderOption(
          label: 'Marker radius',
          value: _markerRadius,
          min: 1,
          max: 8,
          divisions: 14,
          suffix: 'px',
          decimalPlaces: 1,
          onChanged: (value) => setState(() => _markerRadius = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Data variation',
      icon: Icons.tune_outlined,
      children: [
        SliderOption(
          label: 'Interval count',
          value: _pointCount,
          min: math.min(8, _baseRangePoints.length).toDouble(),
          max: _baseRangePoints.length.toDouble(),
          divisions: math.max(1, _baseRangePoints.length - 8),
          decimalPlaces: 0,
          onChanged: (value) =>
              setState(() => _pointCount = value.roundToDouble()),
        ),
        SliderOption(
          label: 'Interval breadth',
          value: _breadthScale,
          min: 0.35,
          max: 1.8,
          divisions: 29,
          suffix: '×',
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _breadthScale = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Tracking and values',
      icon: Icons.track_changes_outlined,
      children: [
        BoolOption(
          label: 'Enable typed tracking',
          subtitle: 'Resolve low, high, midpoint, and span together',
          value: _trackingEnabled,
          onChanged: (value) => setState(() => _trackingEnabled = value),
        ),
        BoolOption(
          label: 'Interpolate interval values',
          value: _interpolateTracking,
          onChanged: (value) => setState(() => _interpolateTracking = value),
        ),
        BoolOption(
          label: 'Show tracking tooltip',
          value: _showTrackingTooltip,
          onChanged: (value) => setState(() => _showTrackingTooltip = value),
        ),
        BoolOption(
          label: 'Show paired intersections',
          value: _showIntersectionMarkers,
          onChanged: (value) =>
              setState(() => _showIntersectionMarkers = value),
        ),
        BoolOption(
          label: 'Show axis values',
          subtitle: 'Paired low and high labels use their true Y positions',
          value: _showCoordinateLabels,
          onChanged: (value) => setState(() => _showCoordinateLabels = value),
        ),
        BoolOption(
          label: 'Keyboard navigation',
          subtitle: 'Arrow keys skip disconnected intervals',
          value: _keyboardNavigation,
          onChanged: (value) => setState(() => _keyboardNavigation = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Interval labels',
      icon: Icons.label_outline,
      children: [
        EnumOption<RangeAreaLabelValue>(
          label: 'Label value',
          value: _labelValue,
          values: RangeAreaLabelValue.values,
          onChanged: (value) => setState(() => _labelValue = value),
        ),
        EnumOption<DataPointLabelCollisionPolicy>(
          label: 'Collision policy',
          value: _labelCollision,
          values: DataPointLabelCollisionPolicy.values,
          onChanged: (value) => setState(() => _labelCollision = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Static value summary',
      icon: Icons.summarize_outlined,
      children: [
        BoolOption(
          label: 'Show interval summary',
          subtitle: 'Persistent low, high, midpoint, and span rows',
          value: _showValueSummary,
          onChanged: (value) => setState(() => _showValueSummary = value),
        ),
        EnumOption<_SummaryPresentation>(
          label: 'Presentation',
          value: _summaryPresentation,
          values: _SummaryPresentation.values,
          labelBuilder: (value) => switch (value) {
            _SummaryPresentation.overlay => 'Fixed overlay',
            _SummaryPresentation.draggableAnnotation => 'Draggable annotation',
          },
          onChanged: (value) => setState(() => _summaryPresentation = value),
        ),
        EnumOption<_SummaryAnchor>(
          label: 'Anchor',
          value: _summaryAnchor,
          values: _SummaryAnchor.values,
          onChanged: (value) => setState(() => _summaryAnchor = value),
        ),
        SliderOption(
          label: 'Background opacity',
          value: _summaryOpacity,
          min: 0,
          max: 1,
          divisions: 20,
          decimalPlaces: 2,
          onChanged: (value) => setState(() => _summaryOpacity = value),
        ),
        SliderOption(
          label: 'Corner radius',
          value: _summaryCornerRadius,
          min: 0,
          max: 24,
          divisions: 12,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _summaryCornerRadius = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Motion',
      icon: Icons.animation_outlined,
      children: [
        BoolOption(
          label: 'Reduced motion',
          subtitle: 'Render final geometry without transitions',
          value: _reducedMotion,
          onChanged: (value) => setState(() => _reducedMotion = value),
        ),
        SliderOption(
          label: 'Animation duration',
          value: _motionDuration,
          min: 150,
          max: 1400,
          divisions: 25,
          suffix: 'ms',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _motionDuration = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Colours',
      icon: Icons.palette_outlined,
      children: [
        PaletteColorOption(
          label: 'Band colour',
          value: _bandColor,
          keyPrefix: 'range-area-band-color',
          customColorFallback: _presetColor,
          onChanged: (value) => setState(() => _bandColor = value),
        ),
        PaletteColorOption(
          label: 'Upper boundary colour',
          value: _upperBoundaryColor,
          keyPrefix: 'range-area-upper-color',
          customColorFallback: _presetColor,
          onChanged: (value) => setState(() => _upperBoundaryColor = value),
        ),
        PaletteColorOption(
          label: 'Lower boundary colour',
          value: _lowerBoundaryColor,
          keyPrefix: 'range-area-lower-color',
          customColorFallback: _presetColor,
          onChanged: (value) => setState(() => _lowerBoundaryColor = value),
        ),
      ],
    ),
    StandardChartOptions(
      controller: _optionsController,
      showLineStyleOption: false,
    ),
  ];

  String get _chartTitle => switch (_preset) {
    _RangeAreaPreset.temperature => 'April temperature envelope',
    _RangeAreaPreset.seasonal => 'Seasonal temperature variation',
    _RangeAreaPreset.confidence => 'Forecast confidence interval',
    _RangeAreaPreset.forecastFan => 'Nested demand forecast fan',
    _RangeAreaPreset.volatility => 'Rolling price volatility band',
    _RangeAreaPreset.gapsAndSteps => 'Service-level windows and outages',
  };

  String get _rangeSeriesName => switch (_preset) {
    _RangeAreaPreset.temperature => 'Daily low–high',
    _RangeAreaPreset.seasonal => 'Seasonal range',
    _RangeAreaPreset.confidence => '90% confidence',
    _RangeAreaPreset.forecastFan => '95% forecast interval',
    _RangeAreaPreset.volatility => 'Volatility range',
    _RangeAreaPreset.gapsAndSteps => 'Service-level range',
  };

  String get _lineSeriesName => switch (_preset) {
    _RangeAreaPreset.temperature => 'Observed mean',
    _RangeAreaPreset.seasonal => 'Seasonal midpoint',
    _RangeAreaPreset.confidence => 'Model estimate',
    _RangeAreaPreset.forecastFan => 'Forecast centre',
    _RangeAreaPreset.volatility => 'Close',
    _RangeAreaPreset.gapsAndSteps => 'Service level',
  };

  String get _unit => switch (_preset) {
    _RangeAreaPreset.temperature || _RangeAreaPreset.seasonal => '°C',
    _RangeAreaPreset.confidence ||
    _RangeAreaPreset.forecastFan ||
    _RangeAreaPreset.gapsAndSteps => '%',
    _RangeAreaPreset.volatility => 'USD',
  };

  String get _xAxisLabel => switch (_preset) {
    _RangeAreaPreset.temperature => 'Day of April',
    _RangeAreaPreset.seasonal => 'Week of year',
    _RangeAreaPreset.confidence ||
    _RangeAreaPreset.forecastFan => 'Forecast horizon',
    _RangeAreaPreset.volatility => 'Trading session',
    _RangeAreaPreset.gapsAndSteps => 'Service window',
  };

  String get _yAxisLabel => switch (_preset) {
    _RangeAreaPreset.temperature ||
    _RangeAreaPreset.seasonal => 'Temperature (°C)',
    _RangeAreaPreset.confidence => 'Response (%)',
    _RangeAreaPreset.forecastFan => 'Demand (%)',
    _RangeAreaPreset.volatility => 'Price (USD)',
    _RangeAreaPreset.gapsAndSteps => 'Service level (%)',
  };

  Color get _presetColor => switch (_preset) {
    _RangeAreaPreset.temperature => const Color(0xFF0EA5E9),
    _RangeAreaPreset.seasonal => const Color(0xFF9333EA),
    _RangeAreaPreset.confidence => const Color(0xFF7C3AED),
    _RangeAreaPreset.forecastFan => const Color(0xFF4F46E5),
    _RangeAreaPreset.volatility => const Color(0xFF0F766E),
    _RangeAreaPreset.gapsAndSteps => const Color(0xFF0891B2),
  };

  Color get _lineColor => switch (_preset) {
    _RangeAreaPreset.temperature => const Color(0xFF2563EB),
    _RangeAreaPreset.seasonal => const Color(0xFFF97316),
    _RangeAreaPreset.confidence => const Color(0xFFDB2777),
    _RangeAreaPreset.forecastFan => const Color(0xFFEC4899),
    _RangeAreaPreset.volatility => const Color(0xFFF97316),
    _RangeAreaPreset.gapsAndSteps => const Color(0xFF0F766E),
  };

  List<RangeAreaDataPoint> get _baseRangePoints => switch (_preset) {
    _RangeAreaPreset.temperature => _temperatureRanges,
    _RangeAreaPreset.seasonal => _seasonalRanges,
    _RangeAreaPreset.confidence => _confidenceRanges,
    _RangeAreaPreset.forecastFan => _forecastOuterRanges,
    _RangeAreaPreset.volatility => _volatilityRanges,
    _RangeAreaPreset.gapsAndSteps => _gapsAndStepsRanges,
  };

  List<RangeAreaDataPoint> get _rangePoints {
    return _transformRangePoints(_baseRangePoints);
  }

  List<RangeAreaDataPoint>? get _secondaryRangePoints =>
      _preset == _RangeAreaPreset.forecastFan
      ? _transformRangePoints(_forecastInnerRanges)
      : null;

  List<RangeAreaDataPoint> _transformRangePoints(
    List<RangeAreaDataPoint> source,
  ) {
    final pointLimit = math.min(_pointCount.round(), source.length);
    return [
      for (final point in source.take(pointLimit))
        if (point.isGap)
          RangeAreaDataPoint.gap(x: point.x)
        else
          _transformInterval(point),
    ];
  }

  RangeAreaDataPoint _transformInterval(RangeAreaDataPoint point) {
    final revisionOffset = _dataRevision.isEven
        ? 0.0
        : math.sin(point.x * 0.43 + _dataRevision) * 0.55;
    final midpoint = point.midpoint! + revisionOffset;
    final halfSpan = point.span! * _breadthScale / 2;
    return RangeAreaDataPoint(
      x: point.x,
      low: midpoint - halfSpan,
      high: midpoint + halfSpan,
    );
  }

  List<ChartDataPoint> get _observedPoints => [
    for (final point in _rangePoints)
      if (!point.isGap)
        ChartDataPoint(
          x: point.x,
          y: switch (_preset) {
            _RangeAreaPreset.temperature =>
              point.midpoint! + math.sin(point.x * 0.72) * 0.9,
            _RangeAreaPreset.seasonal => point.midpoint!,
            _RangeAreaPreset.confidence =>
              point.midpoint! + math.sin(point.x * 0.48) * 1.2,
            _RangeAreaPreset.forecastFan =>
              point.midpoint! + math.sin(point.x * 0.34) * 0.8,
            _RangeAreaPreset.volatility =>
              point.midpoint! + math.cos(point.x * 0.55) * 1.6,
            _RangeAreaPreset.gapsAndSteps => point.midpoint!,
          },
        ),
  ];

  static final List<RangeAreaDataPoint> _temperatureRanges = [
    for (var index = 0; index < 24; index++)
      RangeAreaDataPoint(
        x: index + 1,
        low: 1.5 + math.sin(index * 0.62) * 3.2 + math.sin(index * 0.17) * 1.4,
        high:
            10.5 +
            math.sin(index * 0.62 + 0.45) * 3.8 +
            math.sin(index * 0.17) * 1.4,
      ),
  ];

  static final List<RangeAreaDataPoint> _seasonalRanges = [
    for (var index = 0; index < 52; index++)
      RangeAreaDataPoint(
        x: index + 1,
        low:
            5 +
            math.sin((index - 15) * math.pi / 26) * 10 -
            (2.4 + math.sin(index * 0.9).abs() * 3.4),
        high:
            5 +
            math.sin((index - 15) * math.pi / 26) * 10 +
            (2.4 + math.sin(index * 0.9).abs() * 3.4),
      ),
  ];

  static final List<RangeAreaDataPoint> _confidenceRanges = [
    for (var index = 0; index < 20; index++)
      if (index == 10)
        RangeAreaDataPoint.gap(x: index.toDouble())
      else
        RangeAreaDataPoint(
          x: index.toDouble(),
          low:
              44 +
              index * 1.15 +
              math.sin(index * 0.46) * 4 -
              (3.2 + index * 0.18),
          high:
              44 +
              index * 1.15 +
              math.sin(index * 0.46) * 4 +
              (3.2 + index * 0.18),
        ),
  ];

  static final List<RangeAreaDataPoint> _forecastOuterRanges = [
    for (var index = 0; index < 24; index++)
      RangeAreaDataPoint(
        x: index.toDouble(),
        low:
            62 +
            index * 0.75 +
            math.sin(index * 0.42) * 3.2 -
            (4.2 + index * 0.32),
        high:
            62 +
            index * 0.75 +
            math.sin(index * 0.42) * 3.2 +
            (4.2 + index * 0.32),
      ),
  ];

  static final List<RangeAreaDataPoint> _forecastInnerRanges = [
    for (var index = 0; index < 24; index++)
      RangeAreaDataPoint(
        x: index.toDouble(),
        low:
            62 +
            index * 0.75 +
            math.sin(index * 0.42) * 3.2 -
            (1.8 + index * 0.13),
        high:
            62 +
            index * 0.75 +
            math.sin(index * 0.42) * 3.2 +
            (1.8 + index * 0.13),
      ),
  ];

  static final List<RangeAreaDataPoint> _volatilityRanges = [
    for (var index = 0; index < 28; index++)
      RangeAreaDataPoint(
        x: index.toDouble(),
        low:
            96 +
            index * 0.42 +
            math.sin(index * 0.53) * 5.5 -
            (2.4 + math.sin(index * 0.28).abs() * 3.6),
        high:
            96 +
            index * 0.42 +
            math.sin(index * 0.53) * 5.5 +
            (2.4 + math.sin(index * 0.28).abs() * 3.6),
      ),
  ];

  static final List<RangeAreaDataPoint> _gapsAndStepsRanges = [
    RangeAreaDataPoint(x: 0, low: 91, high: 96),
    RangeAreaDataPoint(x: 1, low: 91, high: 96),
    RangeAreaDataPoint(x: 2, low: 92, high: 97),
    RangeAreaDataPoint(x: 3, low: 92, high: 97),
    RangeAreaDataPoint.gap(x: 4),
    RangeAreaDataPoint.gap(x: 5),
    RangeAreaDataPoint(x: 6, low: 94, high: 99),
    RangeAreaDataPoint(x: 7, low: 94, high: 99),
    RangeAreaDataPoint(x: 8, low: 93, high: 98),
    RangeAreaDataPoint(x: 9, low: 93, high: 98),
    RangeAreaDataPoint(x: 10, low: 95, high: 100),
    RangeAreaDataPoint(x: 11, low: 95, high: 100),
    RangeAreaDataPoint.gap(x: 12),
    RangeAreaDataPoint(x: 13, low: 96, high: 101),
    RangeAreaDataPoint(x: 14, low: 96, high: 101),
    RangeAreaDataPoint(x: 15, low: 94, high: 99),
    RangeAreaDataPoint(x: 16, low: 94, high: 99),
    RangeAreaDataPoint(x: 17, low: 97, high: 102),
  ];
}

class _RangeAreaCoverageStrip extends StatelessWidget {
  const _RangeAreaCoverageStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('range-area-coverage-strip'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _CoverageItem('Paired low/high data'),
          _CoverageItem('4 interpolations'),
          _CoverageItem('Gradient fill'),
          _CoverageItem('Independent boundaries'),
          _CoverageItem('Nested forecast fan'),
          _CoverageItem('Stepped gaps'),
          _CoverageItem('Line composition'),
          _CoverageItem('Count + breadth variation'),
          _CoverageItem('Zoom + pan'),
          _CoverageItem('Typed tracking'),
          _CoverageItem('Static summary'),
          _CoverageItem('Labels + keyboard'),
          _CoverageItem('Entrance + update motion'),
        ],
      ),
    );
  }
}

class _CoverageItem extends StatelessWidget {
  const _CoverageItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.check_circle_outline,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}
