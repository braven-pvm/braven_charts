// Copyright 2025 Braven Charts - Series Styling Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates complete series, label, segment, and point styling.
///
/// Features:
/// - Line charts: segmentStyle for per-segment colors
/// - Area charts: segmentStyle for stroke line colors
/// - Scatter charts: pointStyle for per-point colors/sizes
/// - Bar charts: pointStyle for per-bar colors
class SeriesStylingPage extends StatefulWidget {
  const SeriesStylingPage({super.key});

  @override
  State<SeriesStylingPage> createState() => _SeriesStylingPageState();
}

class _SeriesStylingPageState extends State<SeriesStylingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Styling options
  ChartType _chartType = ChartType.line;
  StylingMode _stylingMode = StylingMode.threshold;
  double _threshold = 70.0;
  double _rangeStart = 20.0;
  double _rangeEnd = 60.0;
  bool _useBezier = false;
  Color _highlightColor = Colors.red;

  // Whole-series appearance and inline label options.
  double _lineGlow = 0.0;
  SeriesLabelPosition _labelPosition = SeriesLabelPosition.right;
  double _labelOffsetY = 0.0;
  double _labelFontSize = 11.0;
  FontWeight _labelFontWeight = FontWeight.w500;
  bool _customLabelColor = false;
  Color _labelColor = Colors.white;
  bool _labelBackground = false;
  Color _labelBackgroundColor = Colors.white;
  double _labelBackgroundOpacity = 0.85;
  double? _labelCornerRadius;
  double _labelPadH = 4.0;
  double _labelPadV = 2.0;
  bool _labelBorder = false;
  Color _labelBorderColor = Colors.black87;
  double _labelBorderWidth = 1.0;

  // Per-data-point label options.
  bool _showDataPointLabels = true;
  DataPointLabelPosition _dataPointLabelPosition = DataPointLabelPosition.above;
  double _dataPointLabelFontSize = 10.0;
  FontWeight _dataPointLabelFontWeight = FontWeight.w600;
  bool _dataPointLabelShowUnit = false;
  DataPointMarkerStyle _dataPointMarkerStyle = DataPointMarkerStyle.filled;
  bool _dataPointLabelBackground = true;
  Color _dataPointLabelBackgroundColor = Colors.white;
  double _dataPointLabelBackgroundOpacity = 0.88;
  bool _customDataPointLabelColor = false;
  Color _dataPointLabelColor = Colors.black87;
  bool _customDataPointLabelFormatter = false;

  // Generated data
  late List<ChartDataPoint> _data;

  static const _seriesPoints = [
    ChartDataPoint(x: 0, y: 120),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 132),
    ChartDataPoint(x: 30, y: 168),
    ChartDataPoint(x: 40, y: 155),
    ChartDataPoint(x: 50, y: 178),
    ChartDataPoint(x: 60, y: 161),
  ];

  static const _comparisonPoints = [
    ChartDataPoint(x: 0, y: 80),
    ChartDataPoint(x: 10, y: 95),
    ChartDataPoint(x: 20, y: 110),
    ChartDataPoint(x: 30, y: 98),
    ChartDataPoint(x: 40, y: 115),
    ChartDataPoint(x: 50, y: 102),
    ChartDataPoint(x: 60, y: 120),
  ];

  static const _dataPointLabelPoints = [
    ChartDataPoint(x: 0, y: 3.4),
    ChartDataPoint(x: 10, y: 7.2),
    ChartDataPoint(x: 20, y: 12.8),
    ChartDataPoint(x: 30, y: 18.5),
    ChartDataPoint(x: 40, y: 22.1),
    ChartDataPoint(x: 50, y: 16.7),
    ChartDataPoint(x: 60, y: 9.3),
  ];

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      // Generate sine wave data
      _data = List.generate(80, (i) {
        final x = i.toDouble();
        final y = 50 + 40 * math.sin(x * 0.1);
        return ChartDataPoint(x: x, y: y);
      });
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
          'Configure series appearance, inline and data-point labels, conditional segments, and individual points',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      OptionSection(
        title: 'Series Appearance',
        icon: Icons.auto_awesome_outlined,
        children: [
          SliderOption(
            label: 'Glow Radius',
            value: _lineGlow,
            min: 0.0,
            max: 12.0,
            divisions: 12,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _lineGlow = value),
          ),
        ],
      ),

      OptionSection(
        title: 'Inline Labels',
        icon: Icons.label_outline,
        children: [
          EnumOption<SeriesLabelPosition>(
            label: 'Position',
            value: _labelPosition,
            values: SeriesLabelPosition.values,
            labelBuilder: (position) => position.name,
            onChanged: (value) => setState(() => _labelPosition = value),
          ),
          SliderOption(
            label: 'Offset Y',
            value: _labelOffsetY,
            min: -40.0,
            max: 40.0,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _labelOffsetY = value),
          ),
          SliderOption(
            label: 'Font Size',
            value: _labelFontSize,
            min: 8.0,
            max: 18.0,
            divisions: 10,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _labelFontSize = value),
          ),
          EnumOption<FontWeight>(
            label: 'Font Weight',
            value: _labelFontWeight,
            values: const [
              FontWeight.w400,
              FontWeight.w500,
              FontWeight.w600,
              FontWeight.w700,
            ],
            labelBuilder: (weight) => switch (weight) {
              FontWeight.w400 => '400',
              FontWeight.w500 => '500',
              FontWeight.w600 => '600',
              FontWeight.w700 => '700',
              _ => weight.toString(),
            },
            onChanged: (value) => setState(() => _labelFontWeight = value),
          ),
          BoolOption(
            label: 'Custom Text Color',
            value: _customLabelColor,
            onChanged: (value) => setState(() => _customLabelColor = value),
          ),
          if (_customLabelColor)
            ColorOption(
              label: 'Text Color',
              value: _labelColor,
              colors: const [
                Colors.white,
                Colors.black87,
                Color(0xFF6366F1),
                Color(0xFFEF4444),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
              ],
              onChanged: (color) => setState(() => _labelColor = color),
            ),
          BoolOption(
            label: 'Background Pill',
            value: _labelBackground,
            onChanged: (value) => setState(() => _labelBackground = value),
          ),
          if (_labelBackground) ...[
            ColorOption(
              label: 'Background Color',
              value: _labelBackgroundColor,
              colors: const [
                Colors.white,
                Color(0xFFF3F4F6),
                Color(0xFFFEF9C3),
                Color(0xFFDCFCE7),
                Color(0xFFDBEAFE),
                Colors.black,
              ],
              onChanged: (color) =>
                  setState(() => _labelBackgroundColor = color),
            ),
            SliderOption(
              label: 'Opacity',
              value: _labelBackgroundOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              decimalPlaces: 1,
              onChanged: (value) =>
                  setState(() => _labelBackgroundOpacity = value),
            ),
            SliderOption(
              label: 'Corner Radius',
              value: _labelCornerRadius ?? -1.0,
              min: -1.0,
              max: 20.0,
              divisions: 21,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _labelCornerRadius = value < 0 ? null : value),
            ),
            SliderOption(
              label: 'Horizontal Padding',
              value: _labelPadH,
              min: 0.0,
              max: 16.0,
              divisions: 16,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _labelPadH = value),
            ),
            SliderOption(
              label: 'Vertical Padding',
              value: _labelPadV,
              min: 0.0,
              max: 12.0,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _labelPadV = value),
            ),
            BoolOption(
              label: 'Border',
              value: _labelBorder,
              onChanged: (value) => setState(() => _labelBorder = value),
            ),
            if (_labelBorder) ...[
              ColorOption(
                label: 'Border Color',
                value: _labelBorderColor,
                colors: const [
                  Colors.black87,
                  Colors.white,
                  Color(0xFF6366F1),
                  Color(0xFFEF4444),
                  Color(0xFF10B981),
                  Color(0xFFF59E0B),
                ],
                onChanged: (color) => setState(() => _labelBorderColor = color),
              ),
              SliderOption(
                label: 'Border Width',
                value: _labelBorderWidth,
                min: 0.5,
                max: 4.0,
                divisions: 7,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _labelBorderWidth = value),
              ),
            ],
          ],
        ],
      ),

      OptionSection(
        title: 'Data Point Labels',
        icon: Icons.pin_outlined,
        children: [
          BoolOption(
            label: 'Show Labels',
            value: _showDataPointLabels,
            onChanged: (value) => setState(() => _showDataPointLabels = value),
          ),
          EnumOption<DataPointLabelPosition>(
            label: 'Position',
            value: _dataPointLabelPosition,
            values: DataPointLabelPosition.values,
            labelBuilder: (position) => position.name,
            onChanged: (value) =>
                setState(() => _dataPointLabelPosition = value),
          ),
          SliderOption(
            label: 'Font Size',
            value: _dataPointLabelFontSize,
            min: 7.0,
            max: 16.0,
            divisions: 9,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _dataPointLabelFontSize = value),
          ),
          EnumOption<FontWeight>(
            label: 'Font Weight',
            value: _dataPointLabelFontWeight,
            values: const [
              FontWeight.w400,
              FontWeight.w500,
              FontWeight.w600,
              FontWeight.w700,
            ],
            labelBuilder: (weight) => switch (weight) {
              FontWeight.w400 => '400',
              FontWeight.w500 => '500',
              FontWeight.w600 => '600',
              FontWeight.w700 => '700',
              _ => weight.toString(),
            },
            onChanged: (value) =>
                setState(() => _dataPointLabelFontWeight = value),
          ),
          EnumOption<DataPointMarkerStyle>(
            label: 'Marker Style',
            value: _dataPointMarkerStyle,
            values: DataPointMarkerStyle.values,
            labelBuilder: (style) => style.name,
            onChanged: (value) => setState(() => _dataPointMarkerStyle = value),
          ),
          BoolOption(
            label: 'Show Unit',
            value: _dataPointLabelShowUnit,
            onChanged: (value) =>
                setState(() => _dataPointLabelShowUnit = value),
          ),
          BoolOption(
            label: 'Background Pill',
            value: _dataPointLabelBackground,
            onChanged: (value) =>
                setState(() => _dataPointLabelBackground = value),
          ),
          if (_dataPointLabelBackground) ...[
            ColorOption(
              label: 'Background Color',
              value: _dataPointLabelBackgroundColor,
              colors: const [
                Colors.white,
                Color(0xFFF3F4F6),
                Color(0xFFFEF9C3),
                Color(0xFFDCFCE7),
                Color(0xFFDBEAFE),
                Color(0xFFFFE4E6),
                Colors.black,
              ],
              onChanged: (color) =>
                  setState(() => _dataPointLabelBackgroundColor = color),
            ),
            SliderOption(
              label: 'Background Opacity',
              value: _dataPointLabelBackgroundOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              decimalPlaces: 1,
              onChanged: (value) =>
                  setState(() => _dataPointLabelBackgroundOpacity = value),
            ),
          ],
          BoolOption(
            label: 'Custom Text Color',
            value: _customDataPointLabelColor,
            onChanged: (value) =>
                setState(() => _customDataPointLabelColor = value),
          ),
          if (_customDataPointLabelColor)
            ColorOption(
              label: 'Text Color',
              value: _dataPointLabelColor,
              colors: const [
                Colors.black87,
                Colors.white,
                Color(0xFF6366F1),
                Color(0xFFEF4444),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
                Color(0xFF0EA5E9),
              ],
              onChanged: (color) =>
                  setState(() => _dataPointLabelColor = color),
            ),
          BoolOption(
            label: 'Custom Formatter',
            subtitle: 'y.toStringAsFixed(1) + "!"',
            value: _customDataPointLabelFormatter,
            onChanged: (value) =>
                setState(() => _customDataPointLabelFormatter = value),
          ),
        ],
      ),

      // Chart type selector
      OptionSection(
        title: 'Conditional Styling',
        icon: Icons.format_color_fill_outlined,
        children: [
          EnumOption<ChartType>(
            label: 'Type',
            value: _chartType,
            values: ChartType.values,
            onChanged: (value) => setState(() => _chartType = value),
          ),
          if (_chartType == ChartType.line || _chartType == ChartType.area)
            BoolOption(
              label: 'Use Bezier curves',
              value: _useBezier,
              onChanged: (value) => setState(() => _useBezier = value),
            ),
          EnumOption<StylingMode>(
            label: 'Mode',
            value: _stylingMode,
            values: StylingMode.values,
            onChanged: (value) => setState(() => _stylingMode = value),
          ),
          ColorOption(
            label: 'Highlight Color',
            value: _highlightColor,
            colors: const [
              Colors.red,
              Colors.orange,
              Colors.amber,
              Colors.green,
              Colors.teal,
              Colors.blue,
              Colors.purple,
              Colors.pink,
            ],
            onChanged: (value) => setState(() => _highlightColor = value),
          ),
        ],
      ),

      // Mode-specific options
      if (_stylingMode == StylingMode.threshold)
        OptionSection(
          title: 'Threshold Options',
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Y Threshold',
              value: _threshold,
              min: 10.0,
              max: 90.0,
              divisions: 16,
              onChanged: (value) => setState(() => _threshold = value),
            ),
          ],
        ),

      if (_stylingMode == StylingMode.range)
        OptionSection(
          title: 'Range Options',
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'X Range Start',
              value: _rangeStart,
              min: 0.0,
              max: 70.0,
              divisions: 14,
              onChanged: (value) => setState(() {
                _rangeStart = value;
                if (_rangeEnd < value) _rangeEnd = value + 10;
              }),
            ),
            SliderOption(
              label: 'X Range End',
              value: _rangeEnd,
              min: 10.0,
              max: 80.0,
              divisions: 14,
              onChanged: (value) => setState(() {
                _rangeEnd = value;
                if (_rangeStart > value) _rangeStart = value - 10;
              }),
            ),
          ],
        ),

      // Actions
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Regenerate Data',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
        ],
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ListView(
          key: const ValueKey('series-styling-examples'),
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            const _StylingOverview(),
            const SizedBox(height: 16),
            SizedBox(
              height: 360,
              child: ChartCard(
                title: 'Whole-series appearance',
                subtitle:
                    'Glow and fully configurable labels remain anchored to each series',
                child: _buildSeriesAppearanceChart(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 360,
              child: ChartCard(
                title: 'Data-point labels',
                subtitle:
                    'Per-point values with configurable position, unit, marker, formatter, type, and background',
                child: _buildDataPointLabelsChart(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 380,
              child: ChartCard(
                title: 'Conditional segment and point styling',
                subtitle:
                    '${_chartType.name.toUpperCase()} · ${_getChartSubtitle()}',
                child: BravenChartPlus(
                  series: [_buildSeries()],
                  theme: _optionsController.theme,
                  showLegend: _optionsController.showLegend,
                  showXScrollbar: _optionsController.showXScrollbar,
                  showYScrollbar: _optionsController.showYScrollbar,
                  scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
                    autoHide: false,
                  ),
                  xAxisConfig: XAxisConfig(
                    label: 'Sample',
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Value',
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  interactionConfig: InteractionConfig(
                    enableZoom: _optionsController.enableZoom,
                    enablePan: _optionsController.enablePan,
                    tooltip: const TooltipConfig(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeriesAppearanceChart() {
    return BravenChartPlus(
      series: [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: _seriesPoints,
          color: const Color(0xFF6366F1),
          strokeWidth: 2.5,
          lineGlow: _lineGlow,
          inlineLabel: _buildLabelConfig('Power', const Color(0xFF6366F1)),
        ),
        LineChartSeries(
          id: 'heart-rate',
          name: 'Heart rate',
          points: _comparisonPoints,
          color: const Color(0xFFEF4444),
          strokeWidth: 2,
          lineGlow: _lineGlow,
          inlineLabel: _buildLabelConfig('Heart rate', const Color(0xFFEF4444)),
        ),
      ],
      theme: _optionsController.theme,
      showLegend: _optionsController.showLegend,
      xAxisConfig: const XAxisConfig(label: 'Time (min)', min: -5, max: 65),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Value',
        min: 60,
        max: 200,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.enableZoom,
        enablePan: _optionsController.enablePan,
        tooltip: const TooltipConfig(),
      ),
    );
  }

  Widget _buildDataPointLabelsChart() {
    return BravenChartPlus(
      series: [
        LineChartSeries(
          id: 'lactate-labels',
          name: 'Lactate',
          points: _dataPointLabelPoints,
          color: const Color(0xFF6366F1),
          strokeWidth: 2,
          showDataPointMarkers: true,
          dataPointMarkerRadius: 4,
          dataPointMarkerStyle: _dataPointMarkerStyle,
          unit: 'mmol/L',
          dataPointLabels: DataPointLabelConfig(
            show: _showDataPointLabels,
            position: _dataPointLabelPosition,
            fontSize: _dataPointLabelFontSize,
            fontWeight: _dataPointLabelFontWeight,
            showUnit: _dataPointLabelShowUnit,
            labelColor: _customDataPointLabelColor
                ? _dataPointLabelColor
                : null,
            formatter: _customDataPointLabelFormatter
                ? (point) => '${point.y.toStringAsFixed(1)}!'
                : null,
            background: _dataPointLabelBackground
                ? _dataPointLabelBackgroundColor
                : null,
            backgroundOpacity: _dataPointLabelBackgroundOpacity,
          ),
        ),
      ],
      theme: _optionsController.theme,
      showLegend: _optionsController.showLegend,
      xAxisConfig: const XAxisConfig(label: 'Time (min)', min: -5, max: 65),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Lactate',
        unit: 'mmol/L',
        min: 0,
        max: 28,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.enableZoom,
        enablePan: _optionsController.enablePan,
        tooltip: const TooltipConfig(),
      ),
    );
  }

  SeriesInlineLabelConfig _buildLabelConfig(String text, Color seriesColor) {
    return SeriesInlineLabelConfig(
      text: text,
      position: _labelPosition,
      offsetY: _labelOffsetY,
      color: _customLabelColor ? _labelColor : seriesColor,
      fontSize: _labelFontSize,
      fontWeight: _labelFontWeight,
      background: _labelBackground
          ? SeriesLabelBackground(
              color: _labelBackgroundColor.withValues(
                alpha: _labelBackgroundOpacity,
              ),
              cornerRadius: _labelCornerRadius,
              padding: EdgeInsets.symmetric(
                horizontal: _labelPadH,
                vertical: _labelPadV,
              ),
              borderColor: _labelBorder ? _labelBorderColor : null,
              borderWidth: _labelBorderWidth,
            )
          : null,
    );
  }

  ChartSeries _buildSeries() {
    switch (_chartType) {
      case ChartType.line:
        return _buildLineSeries();
      case ChartType.area:
        return _buildAreaSeries();
      case ChartType.scatter:
        return _buildScatterSeries();
      case ChartType.bar:
        return _buildBarSeries();
    }
  }

  LineChartSeries _buildLineSeries() {
    var series = LineChartSeries(
      id: 'line-styled',
      name: 'Styled Line',
      points: _data,
      color: Colors.blue,
      interpolation: _useBezier
          ? LineInterpolation.bezier
          : LineInterpolation.linear,
      strokeWidth: 2.5,
      showDataPointMarkers: _optionsController.showDataMarkers,
    );

    switch (_stylingMode) {
      case StylingMode.threshold:
        series = series.withColorWhere(
          (point) => point.y > _threshold,
          _highlightColor,
        );
      case StylingMode.range:
        series = series.withStyleInRange(
          _rangeStart,
          _rangeEnd,
          SegmentStyle.color(_highlightColor),
        );
      case StylingMode.indices:
        // Highlight every 10th segment
        final indices = <int, Color>{};
        for (int i = 0; i < _data.length - 1; i += 10) {
          indices[i] = _highlightColor;
          if (i + 1 < _data.length - 1) indices[i + 1] = _highlightColor;
        }
        series = series.withSegmentColors(indices);
      case StylingMode.gradient:
        // Apply gradient-like coloring based on Y position
        series = series.withStyleWhere(
          (point) => point.y > 70,
          const SegmentStyle(color: Colors.red, strokeWidth: 3.5),
        );
        series = series.withStyleWhere(
          (point) => point.y < 30,
          const SegmentStyle(color: Colors.blue, strokeWidth: 3.5),
        );
    }

    return series;
  }

  AreaChartSeries _buildAreaSeries() {
    var series = AreaChartSeries(
      id: 'area-styled',
      name: 'Styled Area',
      points: _data,
      color: Colors.green,
      interpolation: _useBezier
          ? LineInterpolation.bezier
          : LineInterpolation.linear,
      strokeWidth: 2.5,
      fillOpacity: 0.3,
    );

    switch (_stylingMode) {
      case StylingMode.threshold:
        series = series.withColorWhere(
          (point) => point.y > _threshold,
          _highlightColor,
        );
      case StylingMode.range:
        series = series.withStyleInRange(
          _rangeStart,
          _rangeEnd,
          SegmentStyle.color(_highlightColor),
        );
      case StylingMode.indices:
        final indices = <int, Color>{};
        for (int i = 0; i < _data.length - 1; i += 10) {
          indices[i] = _highlightColor;
        }
        series = series.withSegmentColors(indices);
      case StylingMode.gradient:
        series = series.withColorWhere((point) => point.y > 70, Colors.red);
    }

    return series;
  }

  ScatterChartSeries _buildScatterSeries() {
    // For scatter, we apply pointStyle directly
    List<ChartDataPoint> styledPoints;

    switch (_stylingMode) {
      case StylingMode.threshold:
        styledPoints = _data.map((point) {
          if (point.y > _threshold) {
            return point.copyWith(
              pointStyle: PointStyle(color: _highlightColor, size: 8.0),
            );
          }
          return point;
        }).toList();
      case StylingMode.range:
        styledPoints = _data.map((point) {
          if (point.x >= _rangeStart && point.x < _rangeEnd) {
            return point.copyWith(
              pointStyle: PointStyle(color: _highlightColor, size: 8.0),
            );
          }
          return point;
        }).toList();
      case StylingMode.indices:
        styledPoints = _data.asMap().entries.map((entry) {
          if (entry.key % 5 == 0) {
            return entry.value.copyWith(
              pointStyle: PointStyle(color: _highlightColor, size: 10.0),
            );
          }
          return entry.value;
        }).toList();
      case StylingMode.gradient:
        styledPoints = _data.map((point) {
          Color? color;
          double? size;
          if (point.y > 70) {
            color = Colors.red;
            size = 10.0;
          } else if (point.y > 50) {
            color = Colors.orange;
            size = 6.0;
          } else if (point.y < 30) {
            color = Colors.blue;
            size = 10.0;
          }
          if (color != null) {
            return point.copyWith(
              pointStyle: PointStyle(color: color, size: size),
            );
          }
          return point;
        }).toList();
    }

    return ScatterChartSeries(
      id: 'scatter-styled',
      name: 'Styled Scatter',
      points: styledPoints,
      color: Colors.purple,
      markerRadius: 4.0,
    );
  }

  BarChartSeries _buildBarSeries() {
    // Use fewer points for bar chart visibility
    final barData = _data.where((p) => p.x.toInt() % 4 == 0).toList();

    List<ChartDataPoint> styledPoints;

    switch (_stylingMode) {
      case StylingMode.threshold:
        styledPoints = barData.map((point) {
          if (point.y > _threshold) {
            return point.copyWith(
              pointStyle: PointStyle.color(_highlightColor),
            );
          }
          return point;
        }).toList();
      case StylingMode.range:
        styledPoints = barData.map((point) {
          if (point.x >= _rangeStart && point.x < _rangeEnd) {
            return point.copyWith(
              pointStyle: PointStyle.color(_highlightColor),
            );
          }
          return point;
        }).toList();
      case StylingMode.indices:
        styledPoints = barData.asMap().entries.map((entry) {
          if (entry.key % 3 == 0) {
            return entry.value.copyWith(
              pointStyle: PointStyle.color(_highlightColor),
            );
          }
          return entry.value;
        }).toList();
      case StylingMode.gradient:
        styledPoints = barData.map((point) {
          Color color;
          if (point.y > 70) {
            color = Colors.red;
          } else if (point.y > 50) {
            color = Colors.orange;
          } else if (point.y > 30) {
            color = Colors.yellow.shade700;
          } else {
            color = Colors.blue;
          }
          return point.copyWith(pointStyle: PointStyle.color(color));
        }).toList();
    }

    return BarChartSeries(
      id: 'bar-styled',
      name: 'Styled Bars',
      points: styledPoints,
      color: Colors.grey,
      barWidthPercent: 0.7,
    );
  }

  String _getChartSubtitle() {
    final modeDesc = switch (_stylingMode) {
      StylingMode.threshold => 'Y > ${_threshold.toInt()}',
      StylingMode.range => 'X ∈ [${_rangeStart.toInt()}, ${_rangeEnd.toInt()})',
      StylingMode.indices => 'Every Nth element',
      StylingMode.gradient => 'Value-based colors',
    };

    final styleType =
        (_chartType == ChartType.line || _chartType == ChartType.area)
        ? 'segmentStyle'
        : 'pointStyle';

    return '$modeDesc • Uses $styleType';
  }

  Widget _buildStatusPanel() {
    final styleType =
        (_chartType == ChartType.line || _chartType == ChartType.area)
        ? 'Segment'
        : 'Point';

    return StatusPanel(
      items: [
        const StatusItem(label: 'Coverage', value: 'All styling layers'),
        const StatusItem(label: 'Labels', value: 'Inline + Data-point'),
        StatusItem(
          label: 'Data Points',
          value: _chartType == ChartType.bar
              ? '${(_data.length / 4).floor()}'
              : '${_data.length}',
        ),
        StatusItem(label: 'Style Type', value: '${styleType}Style'),
        StatusItem(label: 'Mode', value: _stylingMode.name),
      ],
    );
  }
}

class _StylingOverview extends StatelessWidget {
  const _StylingOverview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const features = [
      (Icons.show_chart, 'Series', 'Color, width, glow'),
      (Icons.label_outline, 'Series labels', 'Anchor, type, background'),
      (Icons.pin_outlined, 'Point labels', 'Position, formatter, unit'),
      (Icons.timeline, 'Segments', 'Threshold, range, index'),
      (Icons.scatter_plot_outlined, 'Points', 'Color and size overrides'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Series styling API at a glance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start with a series theme, then override only the segments or points that carry meaning.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features
                  .map(
                    (feature) => Chip(
                      avatar: Icon(feature.$1, size: 16),
                      label: Text('${feature.$2} · ${feature.$3}'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Available styling modes for demonstration.
enum StylingMode { threshold, range, indices, gradient }
