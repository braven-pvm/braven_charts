// Copyright 2025 Braven Charts - Series Styling Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _StylingPattern {
  appearance,
  inlineLabels,
  callouts,
  pointLabels,
  conditional,
}

enum _AppearanceType { line, area }

enum _ConditionalMode { threshold, range, indices, gradient }

/// A focused workbench for every public series-level styling layer.
class SeriesStylingPage extends StatefulWidget {
  const SeriesStylingPage({super.key});

  @override
  State<SeriesStylingPage> createState() => _SeriesStylingPageState();
}

class _SeriesStylingPageState extends State<SeriesStylingPage> {
  static const _indigo = Color(0xFF5D5FEF);
  static const _red = Color(0xFFEF445C);
  static const _green = Color(0xFF0EA888);
  static const _orange = Color(0xFFF59E0B);

  final ChartOptionsController _optionsController = ChartOptionsController();

  _StylingPattern _selectedPattern = _StylingPattern.appearance;

  _AppearanceType _appearanceType = _AppearanceType.line;
  double _strokeWidth = 2.5;
  double _lineGlow = 4;
  double _fillOpacity = 0.2;
  LineInterpolation _interpolation = LineInterpolation.monotone;
  bool _showMarkers = false;
  DataPointMarkerStyle _markerStyle = DataPointMarkerStyle.filled;

  SeriesLabelPosition _inlinePosition = SeriesLabelPosition.right;
  double _inlineOffsetY = 0;
  double _inlineFontSize = 12;
  FontWeight _inlineFontWeight = FontWeight.w600;
  bool _inlineBackground = true;
  double _inlineBackgroundOpacity = 0.9;
  bool _inlineBorder = false;

  SeriesCalloutSide _calloutSide = SeriesCalloutSide.right;
  SeriesCalloutAnchor _calloutAnchor = SeriesCalloutAnchor.xValue;
  SeriesCalloutConnector _calloutConnector = SeriesCalloutConnector.elbow;
  SeriesCalloutPacking _calloutPacking = SeriesCalloutPacking.followAnchors;
  double _calloutAnchorX = 44;
  double _calloutLaneWidth = 152;
  double _calloutGap = 6;
  double _calloutFontSize = 11;
  FontWeight _calloutFontWeight = FontWeight.w600;
  Color? _calloutTextColor;
  Color? _calloutBackgroundColor = const Color(0xFFFFFFFF);
  double _calloutBackgroundOpacity = 0.94;
  Color? _calloutBorderColor;
  double _calloutBorderWidth = 1;
  double _calloutBorderRadius = 5;
  Color? _calloutConnectorColor;
  double _calloutConnectorWidth = 1.25;
  double _calloutConnectorOpacity = 1;
  double _calloutConnectorGlow = 0;
  Color? _calloutPanelBackgroundColor = const Color(0xFFF5F3FF);
  double _calloutPanelOpacity = 0.48;
  Color? _calloutPanelBorderColor = const Color(0xFFC4B5FD);
  double _calloutPanelBorderWidth = 1;
  double _calloutPanelBorderRadius = 8;
  double _calloutPanelPadding = 6;
  int _calloutMaximumVisible = 7;
  bool _hideRecoveryCallout = false;
  bool _customizeBuildCallout = true;
  Color? _buildCalloutColor = const Color(0xFF312E81);
  Color? _buildCalloutBackgroundColor = const Color(0xFFEDE9FE);
  double _buildCalloutConnectorWidth = 2.5;
  double _buildCalloutConnectorGlow = 4;

  bool _showPointLabels = true;
  DataPointLabelPosition _pointLabelPosition = DataPointLabelPosition.above;
  double _pointLabelFontSize = 10;
  FontWeight _pointLabelFontWeight = FontWeight.w600;
  bool _pointLabelShowUnit = true;
  bool _pointLabelBackground = true;
  double _pointLabelBackgroundOpacity = 0.88;
  bool _customPointFormatter = false;
  double _pointMarkerRadius = 4;
  DataPointMarkerStyle _pointMarkerStyle = DataPointMarkerStyle.hollow;

  ChartType _conditionalType = ChartType.line;
  _ConditionalMode _conditionalMode = _ConditionalMode.threshold;
  double _threshold = 70;
  double _rangeStart = 20;
  double _rangeEnd = 60;
  Color _highlightColor = _red;

  late final List<ChartDataPoint> _appearancePrimary;
  late final List<ChartDataPoint> _appearanceComparison;
  late final List<ChartDataPoint> _labelPoints;
  late final List<ChartDataPoint> _conditionalData;

  @override
  void initState() {
    super.initState();
    _appearancePrimary = const [
      ChartDataPoint(x: 0, y: 120),
      ChartDataPoint(x: 10, y: 145),
      ChartDataPoint(x: 20, y: 132),
      ChartDataPoint(x: 30, y: 168),
      ChartDataPoint(x: 40, y: 155),
      ChartDataPoint(x: 50, y: 178),
      ChartDataPoint(x: 60, y: 161),
    ];
    _appearanceComparison = const [
      ChartDataPoint(x: 0, y: 82),
      ChartDataPoint(x: 10, y: 96),
      ChartDataPoint(x: 20, y: 110),
      ChartDataPoint(x: 30, y: 98),
      ChartDataPoint(x: 40, y: 116),
      ChartDataPoint(x: 50, y: 103),
      ChartDataPoint(x: 60, y: 121),
    ];
    _labelPoints = const [
      ChartDataPoint(x: 0, y: 3.4),
      ChartDataPoint(x: 10, y: 7.2),
      ChartDataPoint(x: 20, y: 12.8),
      ChartDataPoint(x: 30, y: 18.5),
      ChartDataPoint(x: 40, y: 22.1),
      ChartDataPoint(x: 50, y: 16.7),
      ChartDataPoint(x: 60, y: 9.3),
    ];
    _conditionalData = List.generate(80, (index) {
      final x = index.toDouble();
      return ChartDataPoint(x: x, y: 50 + 40 * math.sin(x * 0.1));
    });
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Series Styling',
      subtitle:
          'Control whole series, inline and callout labels, data-point labels, and conditional segments or points',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          'Choose a styling layer',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        );
        final guide = _StylingGuide(
          key: const ValueKey('series-styling-guide'),
          pattern: _selectedPattern,
        );

        if (constraints.maxHeight < 420) {
          return ListView(
            children: [
              heading,
              const SizedBox(height: 8),
              SizedBox(height: 172, child: _buildPatternRibbon()),
              const SizedBox(height: 16),
              guide,
              const SizedBox(height: 16),
              SizedBox(height: 430, child: _buildMainStage()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 8),
            SizedBox(height: 172, child: _buildPatternRibbon()),
            const SizedBox(height: 16),
            guide,
            const SizedBox(height: 16),
            Expanded(child: _buildMainStage()),
          ],
        );
      },
    );
  }

  Widget _buildPatternRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth >= 920
            ? (constraints.maxWidth - gap * 4) / 5
            : 200.0;
        return SingleChildScrollView(
          key: const ValueKey('series-styling-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < _StylingPattern.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: _StylingPatternCard(
                    key: ValueKey(
                      'series-styling-pattern-${_StylingPattern.values[index].name}',
                    ),
                    pattern: _StylingPattern.values[index],
                    selected: _selectedPattern == _StylingPattern.values[index],
                    onTap: () => _selectPattern(_StylingPattern.values[index]),
                    chart: _buildPatternPreview(_StylingPattern.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternPreview(_StylingPattern pattern) {
    return BravenChartPlus(
      key: ValueKey('series-styling-preview-${pattern.name}'),
      series: _seriesForPattern(pattern, preview: true),
      xAxisConfig: const XAxisConfig(
        showTickLabels: false,
        showTicks: false,
        showAxisLine: true,
        minHeight: 8,
        maxHeight: 8,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        showTickLabels: false,
        showTicks: false,
        maxWidth: 14,
      ),
      grid: const GridConfig(horizontal: true, vertical: false),
      showLegend: false,
      interactionConfig: const InteractionConfig(
        enableZoom: false,
        enablePan: false,
      ),
      seriesCallouts: pattern == _StylingPattern.callouts
          ? const SeriesCalloutConfig(
              enabled: true,
              anchor: SeriesCalloutAnchor.lastVisible,
              laneWidth: 70,
              labelStyle: TextStyle(fontSize: 7, fontWeight: FontWeight.w600),
              labelPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumGap: 2,
              anchorRadius: 1.5,
            )
          : const SeriesCalloutConfig(),
    );
  }

  Widget _buildMainStage() {
    return ChartCard(
      key: const ValueKey('series-styling-main-stage'),
      title: _stageTitle(_selectedPattern),
      subtitle: _stageSubtitle(_selectedPattern),
      child: ListenableBuilder(
        listenable: _optionsController,
        builder: (context, _) => BravenChartPlus(
          key: ValueKey('series-styling-main-chart-${_selectedPattern.name}'),
          series: _seriesForPattern(_selectedPattern),
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
            autoHide: false,
          ),
          xAxisConfig: XAxisConfig(
            label: _selectedPattern == _StylingPattern.pointLabels
                ? 'Time'
                : 'Sample',
            unit: _selectedPattern == _StylingPattern.pointLabels
                ? 'min'
                : null,
            min: -5,
            max: _selectedPattern == _StylingPattern.conditional ? 84 : 65,
            renderMin: 0,
            renderMax: _selectedPattern == _StylingPattern.conditional
                ? 79
                : 60,
            showAxisLine: _optionsController.showAxisLines,
          ),
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            label: _selectedPattern == _StylingPattern.pointLabels
                ? 'Lactate'
                : 'Value',
            unit: _selectedPattern == _StylingPattern.pointLabels
                ? 'mmol/L'
                : null,
            min: _selectedPattern == _StylingPattern.pointLabels ? 0 : null,
            max: _selectedPattern == _StylingPattern.pointLabels ? 28 : null,
            showAxisLine: _optionsController.showAxisLines,
          ),
          grid: GridConfig(
            horizontal: _optionsController.showGrid,
            vertical: _optionsController.showGrid,
          ),
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
            crosshair: CrosshairConfig.tracking(interpolate: true),
            tooltip: const TooltipConfig(enabled: true),
          ),
          seriesCallouts: _selectedPattern == _StylingPattern.callouts
              ? _calloutConfig()
              : const SeriesCalloutConfig(),
        ),
      ),
    );
  }

  List<ChartSeries> _seriesForPattern(
    _StylingPattern pattern, {
    bool preview = false,
  }) {
    return switch (pattern) {
      _StylingPattern.appearance => _appearanceSeries(preview: preview),
      _StylingPattern.inlineLabels => _inlineLabelSeries(preview: preview),
      _StylingPattern.callouts => _calloutSeries(preview: preview),
      _StylingPattern.pointLabels => _pointLabelSeries(preview: preview),
      _StylingPattern.conditional => [_conditionalSeries(preview: preview)],
    };
  }

  List<ChartSeries> _calloutSeries({required bool preview}) {
    const colors = [
      _indigo,
      _red,
      _green,
      _orange,
      Color(0xFF8B5CF6),
      Color(0xFF0891B2),
      Color(0xFFE11D8A),
    ];
    const names = [
      'Build',
      'Capacity',
      'Readiness',
      'Demand',
      'Forecast',
      'Recovery',
      'Target',
    ];
    return [
      for (var seriesIndex = 0; seriesIndex < names.length; seriesIndex++)
        LineChartSeries(
          id: names[seriesIndex].toLowerCase(),
          name: names[seriesIndex],
          color: colors[seriesIndex],
          interpolation: LineInterpolation.monotone,
          strokeWidth: preview ? 1 : 2,
          points: [
            for (var pointIndex = 0; pointIndex < 14; pointIndex++)
              ChartDataPoint(
                x: pointIndex * 5,
                y:
                    34 +
                    seriesIndex * 5.2 +
                    17 * math.sin(pointIndex * 0.46 + seriesIndex * 0.52) +
                    pointIndex * 0.8,
              ),
          ],
        ),
    ];
  }

  SeriesCalloutConfig _calloutConfig() => SeriesCalloutConfig(
    enabled: true,
    side: _calloutSide,
    anchor: _calloutAnchor,
    anchorX: _calloutAnchorX,
    connector: _calloutConnector,
    packing: _calloutPacking,
    laneWidth: _calloutLaneWidth,
    minimumGap: _calloutGap,
    maximumVisible: _calloutMaximumVisible,
    connectorColor: _calloutConnectorColor,
    connectorWidth: _calloutConnectorWidth,
    connectorOpacity: _calloutConnectorOpacity,
    connectorGlow: _calloutConnectorGlow,
    labelStyle: TextStyle(
      fontSize: _calloutFontSize,
      fontWeight: _calloutFontWeight,
      color: _calloutTextColor,
    ),
    backgroundColor: _calloutBackgroundColor,
    backgroundOpacity: _calloutBackgroundOpacity,
    borderColor: _calloutBorderColor,
    borderWidth: _calloutBorderWidth,
    borderRadius: _calloutBorderRadius,
    panelBackgroundColor: _calloutPanelBackgroundColor,
    panelOpacity: _calloutPanelOpacity,
    panelBorderColor: _calloutPanelBorderColor,
    panelBorderWidth: _calloutPanelBorderWidth,
    panelBorderRadius: _calloutPanelBorderRadius,
    panelPadding: EdgeInsets.all(_calloutPanelPadding),
    series: {
      'build': SeriesCalloutSpec(
        label: 'Build · primary',
        priority: 10,
        color: _customizeBuildCallout ? _buildCalloutColor : null,
        backgroundColor: _customizeBuildCallout
            ? _buildCalloutBackgroundColor
            : null,
        connectorWidth: _customizeBuildCallout
            ? _buildCalloutConnectorWidth
            : null,
        connectorGlow: _customizeBuildCallout
            ? _buildCalloutConnectorGlow
            : null,
      ),
      'target': const SeriesCalloutSpec(priority: 8),
      'recovery': SeriesCalloutSpec(show: !_hideRecoveryCallout),
    },
  );

  List<ChartSeries> _appearanceSeries({required bool preview}) {
    final glow = preview ? 3.0 : _lineGlow;
    final width = preview ? 1.6 : _strokeWidth;
    final markers =
        !preview && (_showMarkers || _optionsController.showDataMarkers);
    if (_appearanceType == _AppearanceType.area && !preview) {
      return [
        AreaChartSeries(
          id: 'power-area',
          name: 'Power profile',
          points: _appearancePrimary,
          color: _indigo,
          interpolation: _interpolation,
          strokeWidth: width,
          fillOpacity: _fillOpacity,
          lineGlow: glow,
          showDataPointMarkers: markers,
          dataPointMarkerStyle: _markerStyle,
        ),
        AreaChartSeries(
          id: 'reference-area',
          name: 'Reference',
          points: _appearanceComparison,
          color: _green,
          interpolation: _interpolation,
          strokeWidth: width,
          fillOpacity: _fillOpacity * 0.65,
          lineGlow: glow,
          showDataPointMarkers: markers,
          dataPointMarkerStyle: _markerStyle,
        ),
      ];
    }
    return [
      LineChartSeries(
        id: 'power-line',
        name: 'Power profile',
        points: _appearancePrimary,
        color: _indigo,
        interpolation: preview ? LineInterpolation.monotone : _interpolation,
        strokeWidth: width,
        lineGlow: glow,
        showDataPointMarkers: markers,
        dataPointMarkerStyle: _markerStyle,
      ),
      LineChartSeries(
        id: 'reference-line',
        name: 'Reference',
        points: _appearanceComparison,
        color: _green,
        interpolation: preview ? LineInterpolation.monotone : _interpolation,
        strokeWidth: width,
        lineGlow: glow,
        showDataPointMarkers: markers,
        dataPointMarkerStyle: _markerStyle,
      ),
    ];
  }

  List<ChartSeries> _inlineLabelSeries({required bool preview}) {
    SeriesInlineLabelConfig label(String text, Color color, double offset) {
      return SeriesInlineLabelConfig(
        text: text,
        position: preview ? SeriesLabelPosition.right : _inlinePosition,
        offsetY: preview ? offset : _inlineOffsetY + offset,
        color: color,
        fontSize: preview ? 8 : _inlineFontSize,
        fontWeight: _inlineFontWeight,
        background: _inlineBackground || preview
            ? SeriesLabelBackground(
                color: Colors.white.withValues(
                  alpha: preview ? 0.82 : _inlineBackgroundOpacity,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: preview ? 2 : 6,
                  vertical: preview ? 1 : 3,
                ),
                borderColor: !preview && _inlineBorder ? color : null,
                borderWidth: 1,
              )
            : null,
      );
    }

    return [
      LineChartSeries(
        id: 'power-inline',
        name: 'Power',
        points: _appearancePrimary,
        color: _indigo,
        interpolation: LineInterpolation.monotone,
        strokeWidth: preview ? 1.5 : 2.5,
        lineGlow: preview ? 2 : _lineGlow,
        inlineLabel: label('Power', _indigo, -6),
      ),
      LineChartSeries(
        id: 'heart-inline',
        name: 'Heart rate',
        points: _appearanceComparison,
        color: _red,
        interpolation: LineInterpolation.monotone,
        strokeWidth: preview ? 1.4 : 2,
        lineGlow: preview ? 1 : _lineGlow * 0.7,
        inlineLabel: label('Heart rate', _red, 6),
      ),
    ];
  }

  List<ChartSeries> _pointLabelSeries({required bool preview}) {
    return [
      LineChartSeries(
        id: 'lactate-labels',
        name: 'Lactate',
        points: _labelPoints,
        color: _indigo,
        unit: 'mmol/L',
        interpolation: LineInterpolation.monotone,
        strokeWidth: preview ? 1.5 : 2.2,
        showDataPointMarkers: true,
        dataPointMarkerRadius: preview ? 2.2 : _pointMarkerRadius,
        dataPointMarkerStyle: preview
            ? DataPointMarkerStyle.filled
            : _pointMarkerStyle,
        dataPointLabels: DataPointLabelConfig(
          show: preview || _showPointLabels,
          position: preview
              ? DataPointLabelPosition.above
              : _pointLabelPosition,
          fontSize: preview ? 6.5 : _pointLabelFontSize,
          fontWeight: _pointLabelFontWeight,
          showUnit: !preview && _pointLabelShowUnit,
          formatter: !preview && _customPointFormatter
              ? (point) => '${point.y.toStringAsFixed(1)}×'
              : null,
          background: _pointLabelBackground || preview ? Colors.white : null,
          backgroundOpacity: preview ? 0.78 : _pointLabelBackgroundOpacity,
        ),
      ),
    ];
  }

  ChartSeries _conditionalSeries({required bool preview}) {
    final type = preview ? ChartType.line : _conditionalType;
    final mode = preview ? _ConditionalMode.gradient : _conditionalMode;
    final color = preview ? _orange : _highlightColor;
    final data = preview
        ? _conditionalData
              .asMap()
              .entries
              .where((entry) => entry.key % 4 == 0)
              .map((entry) => entry.value)
              .toList()
        : _conditionalData;

    if (type == ChartType.line || type == ChartType.area) {
      final styled = _segmentStyledData(data, mode, color);
      if (type == ChartType.area) {
        return AreaChartSeries(
          id: 'conditional-area',
          name: 'Conditional area',
          points: styled,
          color: _green,
          interpolation: _interpolation,
          strokeWidth: _strokeWidth,
          fillOpacity: _fillOpacity,
          showDataPointMarkers: _optionsController.showDataMarkers,
        );
      }
      return LineChartSeries(
        id: 'conditional-line',
        name: 'Conditional line',
        points: styled,
        color: _indigo,
        interpolation: preview ? LineInterpolation.monotone : _interpolation,
        strokeWidth: preview ? 1.6 : _strokeWidth,
        showDataPointMarkers: !preview && _optionsController.showDataMarkers,
      );
    }

    final source = type == ChartType.bar
        ? data.where((point) => point.x.toInt() % 4 == 0).toList()
        : data.where((point) => point.x.toInt() % 2 == 0).toList();
    final styled = _pointStyledData(source, mode, color);
    if (type == ChartType.bar) {
      return BarChartSeries(
        id: 'conditional-bars',
        name: 'Conditional bars',
        points: styled,
        color: _indigo,
        barWidthPercent: 0.7,
      );
    }
    return ScatterChartSeries(
      id: 'conditional-scatter',
      name: 'Conditional scatter',
      points: styled,
      color: _indigo,
      markerRadius: 4,
    );
  }

  List<ChartDataPoint> _segmentStyledData(
    List<ChartDataPoint> source,
    _ConditionalMode mode,
    Color color,
  ) {
    return source.asMap().entries.map((entry) {
      final point = entry.value;
      final highlighted = switch (mode) {
        _ConditionalMode.threshold => point.y > _threshold,
        _ConditionalMode.range => point.x >= _rangeStart && point.x < _rangeEnd,
        _ConditionalMode.indices => entry.key % 10 <= 1,
        _ConditionalMode.gradient => point.y > 68 || point.y < 30,
      };
      if (!highlighted) return point;
      final resolvedColor = mode == _ConditionalMode.gradient && point.y < 30
          ? _blueForLow
          : color;
      return point.copyWith(
        segmentStyle: SegmentStyle(
          color: resolvedColor,
          strokeWidth: mode == _ConditionalMode.gradient ? 3.5 : null,
        ),
      );
    }).toList();
  }

  static const _blueForLow = Color(0xFF168AF3);

  List<ChartDataPoint> _pointStyledData(
    List<ChartDataPoint> source,
    _ConditionalMode mode,
    Color color,
  ) {
    return source.asMap().entries.map((entry) {
      final point = entry.value;
      final highlighted = switch (mode) {
        _ConditionalMode.threshold => point.y > _threshold,
        _ConditionalMode.range => point.x >= _rangeStart && point.x < _rangeEnd,
        _ConditionalMode.indices => entry.key % 5 == 0,
        _ConditionalMode.gradient => true,
      };
      if (!highlighted) return point;
      final resolvedColor = mode == _ConditionalMode.gradient
          ? point.y > 70
                ? _red
                : point.y > 50
                ? _orange
                : point.y < 30
                ? _blueForLow
                : _green
          : color;
      return point.copyWith(
        pointStyle: PointStyle(
          color: resolvedColor,
          size: _conditionalType == ChartType.scatter ? 8 : null,
        ),
      );
    }).toList();
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Styling Layer',
        icon: Icons.layers_outlined,
        children: [
          EnumOption<_StylingPattern>(
            label: 'Example',
            value: _selectedPattern,
            values: _StylingPattern.values,
            labelBuilder: _patternLabel,
            onChanged: _selectPattern,
          ),
        ],
      ),
      ..._patternOptions(),
      StandardChartOptions(
        controller: _optionsController,
        showMarkerOption: false,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'What to Try',
        icon: Icons.fact_check_outlined,
        children: [InfoBox(message: _instruction(_selectedPattern))],
      ),
    ];
  }

  List<Widget> _patternOptions() {
    return switch (_selectedPattern) {
      _StylingPattern.appearance => [
        OptionSection(
          title: 'Series Appearance',
          icon: Icons.auto_awesome_outlined,
          children: [
            EnumOption<_AppearanceType>(
              label: 'Series Type',
              value: _appearanceType,
              values: _AppearanceType.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _appearanceType = value),
            ),
            EnumOption<LineInterpolation>(
              label: 'Interpolation',
              value: _interpolation,
              values: LineInterpolation.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _interpolation = value),
            ),
            SliderOption(
              label: 'Stroke Width',
              value: _strokeWidth,
              min: 1,
              max: 6,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
            SliderOption(
              label: 'Glow Radius',
              value: _lineGlow,
              min: 0,
              max: 12,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _lineGlow = value),
            ),
            if (_appearanceType == _AppearanceType.area)
              SliderOption(
                label: 'Fill Opacity',
                value: _fillOpacity,
                min: 0.05,
                max: 0.6,
                divisions: 11,
                decimalPlaces: 2,
                onChanged: (value) => setState(() => _fillOpacity = value),
              ),
            BoolOption(
              label: 'Show Markers',
              value: _showMarkers,
              onChanged: (value) => setState(() => _showMarkers = value),
            ),
            if (_showMarkers)
              EnumOption<DataPointMarkerStyle>(
                label: 'Marker Style',
                value: _markerStyle,
                values: DataPointMarkerStyle.values,
                labelBuilder: (value) => value.name,
                onChanged: (value) => setState(() => _markerStyle = value),
              ),
          ],
        ),
      ],
      _StylingPattern.inlineLabels => [
        OptionSection(
          title: 'Inline Labels',
          icon: Icons.label_outline,
          children: [
            EnumOption<SeriesLabelPosition>(
              label: 'Anchor Position',
              value: _inlinePosition,
              values: SeriesLabelPosition.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _inlinePosition = value),
            ),
            SliderOption(
              label: 'Vertical Offset',
              value: _inlineOffsetY,
              min: -32,
              max: 32,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _inlineOffsetY = value),
            ),
            SliderOption(
              label: 'Font Size',
              value: _inlineFontSize,
              min: 8,
              max: 18,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _inlineFontSize = value),
            ),
            EnumOption<FontWeight>(
              label: 'Font Weight',
              value: _inlineFontWeight,
              values: _fontWeights,
              labelBuilder: _fontWeightLabel,
              onChanged: (value) => setState(() => _inlineFontWeight = value),
            ),
            BoolOption(
              label: 'Background Pill',
              value: _inlineBackground,
              onChanged: (value) => setState(() => _inlineBackground = value),
            ),
            if (_inlineBackground) ...[
              SliderOption(
                label: 'Background Opacity',
                value: _inlineBackgroundOpacity,
                min: 0.2,
                max: 1,
                divisions: 8,
                decimalPlaces: 1,
                onChanged: (value) =>
                    setState(() => _inlineBackgroundOpacity = value),
              ),
              BoolOption(
                label: 'Series-Color Border',
                value: _inlineBorder,
                onChanged: (value) => setState(() => _inlineBorder = value),
              ),
            ],
          ],
        ),
      ],
      _StylingPattern.callouts => [
        OptionSection(
          title: 'Callout layout',
          icon: Icons.label_important_outline,
          children: [
            EnumOption<SeriesCalloutSide>(
              label: 'Label Lane',
              value: _calloutSide,
              values: SeriesCalloutSide.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _calloutSide = value),
            ),
            EnumOption<SeriesCalloutAnchor>(
              label: 'Anchor Strategy',
              value: _calloutAnchor,
              values: SeriesCalloutAnchor.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _calloutAnchor = value),
            ),
            EnumOption<SeriesCalloutPacking>(
              label: 'Label packing',
              value: _calloutPacking,
              values: SeriesCalloutPacking.values,
              labelBuilder: (value) => switch (value) {
                SeriesCalloutPacking.followAnchors => 'Follow anchors',
                SeriesCalloutPacking.compact => 'Compact stack',
              },
              onChanged: (value) => setState(() => _calloutPacking = value),
            ),
            if (_calloutAnchor == SeriesCalloutAnchor.xValue)
              SliderOption(
                label: 'Anchor X',
                value: _calloutAnchorX,
                min: 0,
                max: 65,
                divisions: 13,
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _calloutAnchorX = value),
              ),
            SliderOption(
              label: 'Lane Width',
              value: _calloutLaneWidth,
              min: 92,
              max: 240,
              divisions: 37,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _calloutLaneWidth = value),
            ),
            SliderOption(
              label: 'Minimum Gap',
              value: _calloutGap,
              min: 0,
              max: 20,
              divisions: 20,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _calloutGap = value),
            ),
            SliderOption(
              label: 'Maximum Labels',
              value: _calloutMaximumVisible.toDouble(),
              min: 2,
              max: 7,
              divisions: 5,
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _calloutMaximumVisible = value.round()),
            ),
          ],
        ),
        OptionSection(
          title: 'Label style',
          icon: Icons.text_fields_outlined,
          children: [
            SliderOption(
              label: 'Font Size',
              value: _calloutFontSize,
              min: 8,
              max: 18,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _calloutFontSize = value),
            ),
            EnumOption<FontWeight>(
              label: 'Font Weight',
              value: _calloutFontWeight,
              values: _fontWeights,
              labelBuilder: _fontWeightLabel,
              onChanged: (value) => setState(() => _calloutFontWeight = value),
            ),
            PaletteColorOption(
              keyPrefix: 'callout-text-color',
              label: 'Text color',
              subtitle: 'Clear for automatic contrast',
              value: _calloutTextColor,
              customColorFallback: Colors.black87,
              onChanged: (value) => setState(() => _calloutTextColor = value),
            ),
            PaletteColorOption(
              keyPrefix: 'callout-background-color',
              label: 'Label background',
              subtitle: 'Clear to inherit the chart background',
              value: _calloutBackgroundColor,
              customColorFallback: Colors.white,
              onChanged: (value) =>
                  setState(() => _calloutBackgroundColor = value),
            ),
            SliderOption(
              label: 'Background opacity',
              value: _calloutBackgroundOpacity,
              min: 0,
              max: 1,
              divisions: 20,
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _calloutBackgroundOpacity = value),
            ),
            PaletteColorOption(
              keyPrefix: 'callout-border-color',
              label: 'Label border',
              subtitle: 'Clear to derive it from the connector color',
              value: _calloutBorderColor,
              customColorFallback: _indigo,
              onChanged: (value) => setState(() => _calloutBorderColor = value),
            ),
            SliderOption(
              label: 'Border width',
              value: _calloutBorderWidth,
              min: 0,
              max: 4,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _calloutBorderWidth = value),
            ),
            SliderOption(
              label: 'Corner radius',
              value: _calloutBorderRadius,
              min: 0,
              max: 16,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _calloutBorderRadius = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Connectors & lane panel',
          icon: Icons.polyline_outlined,
          children: [
            EnumOption<SeriesCalloutConnector>(
              label: 'Connector',
              value: _calloutConnector,
              values: SeriesCalloutConnector.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _calloutConnector = value),
            ),
            PaletteColorOption(
              keyPrefix: 'callout-connector-color',
              label: 'Connector color',
              subtitle: 'Clear to inherit each series color',
              value: _calloutConnectorColor,
              customColorFallback: _indigo,
              onChanged: (value) =>
                  setState(() => _calloutConnectorColor = value),
            ),
            SliderOption(
              label: 'Connector width',
              value: _calloutConnectorWidth,
              min: 0.5,
              max: 5,
              divisions: 18,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _calloutConnectorWidth = value),
            ),
            SliderOption(
              label: 'Connector opacity',
              value: _calloutConnectorOpacity,
              min: 0,
              max: 1,
              divisions: 20,
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _calloutConnectorOpacity = value),
            ),
            SliderOption(
              label: 'Connector glow',
              value: _calloutConnectorGlow,
              min: 0,
              max: 12,
              divisions: 24,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) =>
                  setState(() => _calloutConnectorGlow = value),
            ),
            PaletteColorOption(
              keyPrefix: 'callout-panel-fill',
              label: 'Panel background',
              subtitle: 'Clear for a transparent lane',
              value: _calloutPanelBackgroundColor,
              customColorFallback: const Color(0xFFF5F3FF),
              onChanged: (value) =>
                  setState(() => _calloutPanelBackgroundColor = value),
            ),
            SliderOption(
              label: 'Panel opacity',
              value: _calloutPanelOpacity,
              min: 0,
              max: 1,
              divisions: 20,
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _calloutPanelOpacity = value),
            ),
            PaletteColorOption(
              keyPrefix: 'callout-panel-border',
              label: 'Panel border',
              subtitle: 'Clear to remove its outline',
              value: _calloutPanelBorderColor,
              customColorFallback: const Color(0xFFC4B5FD),
              onChanged: (value) =>
                  setState(() => _calloutPanelBorderColor = value),
            ),
            SliderOption(
              label: 'Panel border width',
              value: _calloutPanelBorderWidth,
              min: 0,
              max: 4,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) =>
                  setState(() => _calloutPanelBorderWidth = value),
            ),
            SliderOption(
              label: 'Panel padding',
              value: _calloutPanelPadding,
              min: 0,
              max: 24,
              divisions: 24,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _calloutPanelPadding = value),
            ),
            SliderOption(
              label: 'Panel corner radius',
              value: _calloutPanelBorderRadius,
              min: 0,
              max: 24,
              divisions: 24,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _calloutPanelBorderRadius = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Per-series overrides',
          icon: Icons.tune_outlined,
          children: [
            BoolOption(
              label: 'Customize Build',
              subtitle: 'Override its connector and label presentation',
              value: _customizeBuildCallout,
              onChanged: (value) =>
                  setState(() => _customizeBuildCallout = value),
            ),
            if (_customizeBuildCallout) ...[
              PaletteColorOption(
                keyPrefix: 'build-callout-color',
                label: 'Build connector color',
                value: _buildCalloutColor,
                customColorFallback: const Color(0xFF312E81),
                onChanged: (value) =>
                    setState(() => _buildCalloutColor = value),
              ),
              PaletteColorOption(
                keyPrefix: 'build-callout-background',
                label: 'Build label background',
                value: _buildCalloutBackgroundColor,
                customColorFallback: const Color(0xFFEDE9FE),
                onChanged: (value) =>
                    setState(() => _buildCalloutBackgroundColor = value),
              ),
              SliderOption(
                label: 'Build connector width',
                value: _buildCalloutConnectorWidth,
                min: 0.5,
                max: 5,
                divisions: 18,
                suffix: 'px',
                decimalPlaces: 2,
                onChanged: (value) =>
                    setState(() => _buildCalloutConnectorWidth = value),
              ),
              SliderOption(
                label: 'Build connector glow',
                value: _buildCalloutConnectorGlow,
                min: 0,
                max: 12,
                divisions: 24,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) =>
                    setState(() => _buildCalloutConnectorGlow = value),
              ),
            ],
            BoolOption(
              label: 'Hide Recovery',
              subtitle: 'Per-series opt-out while global callouts stay enabled',
              value: _hideRecoveryCallout,
              onChanged: (value) =>
                  setState(() => _hideRecoveryCallout = value),
            ),
          ],
        ),
      ],
      _StylingPattern.pointLabels => [
        OptionSection(
          title: 'Data Point Labels',
          icon: Icons.pin_outlined,
          children: [
            BoolOption(
              label: 'Show Labels',
              value: _showPointLabels,
              onChanged: (value) => setState(() => _showPointLabels = value),
            ),
            EnumOption<DataPointLabelPosition>(
              label: 'Label Position',
              value: _pointLabelPosition,
              values: DataPointLabelPosition.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _pointLabelPosition = value),
            ),
            SliderOption(
              label: 'Font Size',
              value: _pointLabelFontSize,
              min: 7,
              max: 16,
              divisions: 9,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _pointLabelFontSize = value),
            ),
            EnumOption<FontWeight>(
              label: 'Font Weight',
              value: _pointLabelFontWeight,
              values: _fontWeights,
              labelBuilder: _fontWeightLabel,
              onChanged: (value) =>
                  setState(() => _pointLabelFontWeight = value),
            ),
            BoolOption(
              label: 'Show Unit',
              value: _pointLabelShowUnit,
              onChanged: (value) => setState(() => _pointLabelShowUnit = value),
            ),
            BoolOption(
              label: 'Custom Formatter',
              subtitle: 'Formats each value as 12.8×',
              value: _customPointFormatter,
              onChanged: (value) =>
                  setState(() => _customPointFormatter = value),
            ),
            BoolOption(
              label: 'Background Pill',
              value: _pointLabelBackground,
              onChanged: (value) =>
                  setState(() => _pointLabelBackground = value),
            ),
            if (_pointLabelBackground)
              SliderOption(
                label: 'Background Opacity',
                value: _pointLabelBackgroundOpacity,
                min: 0.2,
                max: 1,
                divisions: 8,
                decimalPlaces: 1,
                onChanged: (value) =>
                    setState(() => _pointLabelBackgroundOpacity = value),
              ),
            EnumOption<DataPointMarkerStyle>(
              label: 'Marker Style',
              value: _pointMarkerStyle,
              values: DataPointMarkerStyle.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _pointMarkerStyle = value),
            ),
            SliderOption(
              label: 'Marker Radius',
              value: _pointMarkerRadius,
              min: 2,
              max: 8,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _pointMarkerRadius = value),
            ),
          ],
        ),
      ],
      _StylingPattern.conditional => [
        OptionSection(
          title: 'Conditional Styling',
          icon: Icons.format_color_fill_outlined,
          children: [
            EnumOption<ChartType>(
              label: 'Chart Type',
              value: _conditionalType,
              values: ChartType.values
                  .where(
                    (value) =>
                        value != ChartType.pie &&
                        value != ChartType.donut &&
                        value != ChartType.candlestick,
                  )
                  .toList(growable: false),
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _conditionalType = value),
            ),
            EnumOption<_ConditionalMode>(
              label: 'Rule',
              value: _conditionalMode,
              values: _ConditionalMode.values,
              labelBuilder: (value) => value.name,
              onChanged: (value) => setState(() => _conditionalMode = value),
            ),
            ColorOption(
              label: 'Highlight Color',
              value: _highlightColor,
              colors: const [
                _red,
                _orange,
                _green,
                _indigo,
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
              onChanged: (value) => setState(() => _highlightColor = value),
            ),
            if (_conditionalMode == _ConditionalMode.threshold)
              SliderOption(
                label: 'Y Threshold',
                value: _threshold,
                min: 10,
                max: 90,
                divisions: 16,
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _threshold = value),
              ),
            if (_conditionalMode == _ConditionalMode.range) ...[
              SliderOption(
                label: 'X Range Start',
                value: _rangeStart,
                min: 0,
                max: 60,
                divisions: 12,
                decimalPlaces: 0,
                onChanged: (value) => setState(() {
                  _rangeStart = value;
                  if (_rangeEnd <= value) _rangeEnd = value + 5;
                }),
              ),
              SliderOption(
                label: 'X Range End',
                value: _rangeEnd,
                min: 20,
                max: 80,
                divisions: 12,
                decimalPlaces: 0,
                onChanged: (value) => setState(() {
                  _rangeEnd = value;
                  if (_rangeStart >= value) _rangeStart = value - 5;
                }),
              ),
            ],
          ],
        ),
      ],
    };
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(label: 'Layer', value: _patternLabel(_selectedPattern)),
        StatusItem(
          label: 'Series',
          value: '${_seriesForPattern(_selectedPattern).length}',
        ),
        StatusItem(
          label: 'Points',
          value: '${_seriesForPattern(_selectedPattern).first.points.length}',
        ),
        StatusItem(label: 'API', value: _statusApi(_selectedPattern)),
      ],
    );
  }

  void _selectPattern(_StylingPattern pattern) {
    if (_selectedPattern == pattern) return;
    setState(() => _selectedPattern = pattern);
  }

  static const _fontWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

  static String _fontWeightLabel(FontWeight weight) {
    if (weight == FontWeight.w400) return '400 · regular';
    if (weight == FontWeight.w500) return '500 · medium';
    if (weight == FontWeight.w600) return '600 · semibold';
    return '700 · bold';
  }

  static String _patternLabel(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance => 'Series appearance',
      _StylingPattern.inlineLabels => 'Inline labels',
      _StylingPattern.callouts => 'Series callouts',
      _StylingPattern.pointLabels => 'Point labels',
      _StylingPattern.conditional => 'Conditional styling',
    };
  }

  static String _patternDescription(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance => 'Stroke · fill · glow · markers',
      _StylingPattern.inlineLabels => 'Anchored series identity',
      _StylingPattern.callouts => 'Shared label lane · connectors',
      _StylingPattern.pointLabels => 'Values · units · formatter',
      _StylingPattern.conditional => 'Segments and individual points',
    };
  }

  static String _stageTitle(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance => 'Whole-series appearance',
      _StylingPattern.inlineLabels => 'Labels anchored to series geometry',
      _StylingPattern.callouts => 'Collision-aware labels for dense series',
      _StylingPattern.pointLabels => 'Lactate values at every sample',
      _StylingPattern.conditional => 'Data-driven styling overrides',
    };
  }

  String _stageSubtitle(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance =>
        '${_appearanceType.name} · ${_interpolation.name} · ${_lineGlow.toStringAsFixed(0)} px glow',
      _StylingPattern.inlineLabels =>
        '${_inlinePosition.name} anchor · ${_inlineBackground ? 'background pill' : 'text only'}',
      _StylingPattern.callouts =>
        '${_calloutSide.name} lane · ${_calloutAnchor.name} · $_calloutMaximumVisible labels',
      _StylingPattern.pointLabels =>
        '${_pointLabelPosition.name} · ${_pointLabelShowUnit ? 'unit visible' : 'value only'} · ${_pointMarkerStyle.name} markers',
      _StylingPattern.conditional =>
        '${_conditionalType.name} · ${_conditionalMode.name} · ${_conditionalType == ChartType.line || _conditionalType == ChartType.area ? 'SegmentStyle' : 'PointStyle'}',
    };
  }

  static String _instruction(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance =>
        'Switch between line and area, then combine interpolation, stroke width, glow, fill opacity, and marker treatment. Theme and interaction controls remain independent.',
      _StylingPattern.inlineLabels =>
        'Move the label anchor from left to right, offset it vertically, and add a pill or series-colored border. Labels follow the rendered series instead of occupying a separate legend.',
      _StylingPattern.callouts =>
        'Move the shared lane, change anchor semantics, and reduce its capacity to exercise collision handling. Hide Recovery to prove one series can opt out without disabling global callouts.',
      _StylingPattern.pointLabels =>
        'Change label position, unit display, formatter, background, and marker style. Labels are configured once on the series and formatted from each ChartDataPoint.',
      _StylingPattern.conditional =>
        'Change chart type to see SegmentStyle apply to line/area segments and PointStyle apply to scatter markers or bars. Try threshold, range, index, and value-gradient rules.',
    };
  }

  static String _statusApi(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance => 'Series fields',
      _StylingPattern.inlineLabels => 'InlineLabel',
      _StylingPattern.callouts => 'SeriesCallouts',
      _StylingPattern.pointLabels => 'PointLabels',
      _StylingPattern.conditional => 'Segment/Point',
    };
  }
}

class _StylingPatternCard extends StatelessWidget {
  const _StylingPatternCard({
    super.key,
    required this.pattern,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _StylingPattern pattern;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'Select ${_SeriesStylingPageState._patternLabel(pattern)} styling layer',
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _SeriesStylingPageState._patternLabel(pattern),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-styling-${pattern.name}'),
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _SeriesStylingPageState._patternDescription(pattern),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(child: IgnorePointer(child: chart)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StylingGuide extends StatelessWidget {
  const _StylingGuide({super.key, required this.pattern});

  final _StylingPattern pattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanation = Row(
            children: [
              Icon(_icon(pattern), size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _explanation(pattern),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
          final api = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _api(pattern),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(child: explanation),
                const SizedBox(width: 16),
                SizedBox(width: 470, child: api),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [explanation, const SizedBox(height: 10), api],
          );
        },
      ),
    );
  }

  static IconData _icon(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance => Icons.auto_awesome_outlined,
      _StylingPattern.inlineLabels => Icons.label_outline,
      _StylingPattern.callouts => Icons.label_important_outline,
      _StylingPattern.pointLabels => Icons.pin_outlined,
      _StylingPattern.conditional => Icons.format_color_fill_outlined,
    };
  }

  static String _explanation(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance =>
        'Define the default visual identity once on the series: type, interpolation, stroke, fill, glow, and marker treatment.',
      _StylingPattern.inlineLabels =>
        'Attach identity directly to series geometry with configurable anchor, typography, offset, background, and border.',
      _StylingPattern.callouts =>
        'Coordinate direct labels across every visible series so one shared lane can resolve anchors, priority, connectors, and collisions.',
      _StylingPattern.pointLabels =>
        'Render formatted values from each point with independent label placement, units, typography, background, and marker style.',
      _StylingPattern.conditional =>
        'Override only meaningful segments or points while every unstyled element continues to inherit the series default.',
    };
  }

  static String _api(_StylingPattern pattern) {
    return switch (pattern) {
      _StylingPattern.appearance =>
        'strokeWidth · interpolation · lineGlow · fillOpacity · dataPointMarkerStyle',
      _StylingPattern.inlineLabels =>
        'SeriesInlineLabelConfig · SeriesLabelBackground · SeriesLabelPosition',
      _StylingPattern.callouts =>
        'SeriesCalloutConfig · SeriesCalloutSpec · SeriesCalloutAnchor',
      _StylingPattern.pointLabels =>
        'DataPointLabelConfig(position, showUnit, formatter, background)',
      _StylingPattern.conditional =>
        'ChartDataPoint.segmentStyle · ChartDataPoint.pointStyle · inheritance fast path',
    };
  }
}
