// Copyright 2025 Braven Charts - Segment & Point Styling Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates per-segment and per-point styling across all chart types.
///
/// Features:
/// - Line charts: segmentStyle for per-segment colors
/// - Area charts: segmentStyle for stroke line colors
/// - Scatter charts: pointStyle for per-point colors/sizes
/// - Bar charts: pointStyle for per-bar colors
class SegmentStylingPage extends StatefulWidget {
  const SegmentStylingPage({super.key});

  @override
  State<SegmentStylingPage> createState() => _SegmentStylingPageState();
}

class _SegmentStylingPageState extends State<SegmentStylingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Styling options
  ChartType _chartType = ChartType.line;
  StylingMode _stylingMode = StylingMode.threshold;
  double _threshold = 70.0;
  double _rangeStart = 20.0;
  double _rangeEnd = 60.0;
  bool _useBezier = false;
  Color _highlightColor = Colors.red;

  // Generated data
  late List<ChartDataPoint> _data;

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
      title: 'Segment & Point Styling',
      subtitle: 'Per-segment and per-point color customization',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Chart type selector
      OptionSection(
        title: 'Chart Type',
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
        ],
      ),

      // Styling mode
      OptionSection(
        title: 'Styling Mode',
        children: [
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
        return ChartCard(
          title: '${_chartType.name.toUpperCase()} Chart',
          subtitle: _getChartSubtitle(),
          child: BravenChartPlus(
            series: [_buildSeries()],
            theme: _optionsController.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme:
                ScrollbarConfig.defaultLight.copyWith(autoHide: false),
            xAxisConfig: XAxisConfig(
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              showAxisLine: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
              tooltip: TooltipConfig(),
            ),
          ),
        );
      },
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
      interpolation:
          _useBezier ? LineInterpolation.bezier : LineInterpolation.linear,
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
      interpolation:
          _useBezier ? LineInterpolation.bezier : LineInterpolation.linear,
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
        series = series.withColorWhere(
          (point) => point.y > 70,
          Colors.red,
        );
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
                pointStyle: PointStyle(color: color, size: size));
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
        StatusItem(
          label: 'Data Points',
          value: _chartType == ChartType.bar
              ? '${(_data.length / 4).floor()}'
              : '${_data.length}',
        ),
        StatusItem(
          label: 'Style Type',
          value: '${styleType}Style',
        ),
        StatusItem(
          label: 'Mode',
          value: _stylingMode.name,
        ),
      ],
    );
  }
}

/// Available styling modes for demonstration.
enum StylingMode {
  threshold,
  range,
  indices,
  gradient,
}
