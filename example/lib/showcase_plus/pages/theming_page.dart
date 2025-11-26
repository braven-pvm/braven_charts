import 'dart:math';

import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_annotation.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_theme.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/options_panel.dart';

class ThemingPage extends StatefulWidget {
  const ThemingPage({super.key});

  @override
  State<ThemingPage> createState() => _ThemingPageState();
}

class _ThemingPageState extends State<ThemingPage> {
  // Theme selection - all 7 presets
  String _selectedTheme = 'light';
  bool _showMultipleCharts = false;

  // Element visibility toggles
  bool _showAnnotations = true;
  bool _showMarkers = true;
  bool _showTooltips = true;
  bool _showLegend = true;
  final bool _showScrollbars = true;

  // Map of theme names to ChartTheme instances
  final Map<String, ChartTheme> _themes = {
    'light': ChartTheme.light,
    'dark': ChartTheme.dark,
    'corporateBlue': ChartTheme.corporateBlue,
    'vibrant': ChartTheme.vibrant,
    'minimal': ChartTheme.minimal,
    'highContrast': ChartTheme.highContrast,
    'colorblindFriendly': ChartTheme.colorblindFriendly,
  };

  // Theme display names for UI
  final Map<String, String> _themeDisplayNames = {
    'light': 'Light',
    'dark': 'Dark',
    'corporateBlue': 'Corporate Blue',
    'vibrant': 'Vibrant',
    'minimal': 'Minimal',
    'highContrast': 'High Contrast',
    'colorblindFriendly': 'Colorblind Friendly',
  };

  ChartTheme get _currentTheme => _themes[_selectedTheme]!;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _currentTheme.backgroundColor,
      child: Row(
        children: [
          // Chart(s) Display
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _showMultipleCharts ? _buildMultipleChartsView() : _buildComprehensiveChart(),
                  ),
                ],
              ),
            ),
          ),

          // Options Panel
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: _currentTheme.backgroundColor,
              border: Border(
                left: BorderSide(
                  color: _currentTheme.gridStyle.majorColor,
                  width: 1,
                ),
              ),
            ),
            child: OptionsPanel(
              title: 'Theme & Elements',
              children: [
                OptionSection(
                  title: 'Theme Preset',
                  children: [_buildThemeSelector()],
                ),
                OptionSection(
                  title: 'Display Mode',
                  children: [
                    BoolOption(
                      label: 'Show Multiple Charts',
                      value: _showMultipleCharts,
                      onChanged: (value) => setState(() => _showMultipleCharts = value),
                    ),
                  ],
                ),
                OptionSection(
                  title: 'Element Visibility',
                  children: [
                    BoolOption(
                      label: 'Show Annotations',
                      value: _showAnnotations,
                      onChanged: (value) => setState(() => _showAnnotations = value),
                    ),
                    BoolOption(
                      label: 'Show Markers',
                      value: _showMarkers,
                      onChanged: (value) => setState(() => _showMarkers = value),
                    ),
                    BoolOption(
                      label: 'Show Tooltips',
                      value: _showTooltips,
                      onChanged: (value) => setState(() => _showTooltips = value),
                    ),
                    BoolOption(
                      label: 'Show Legend',
                      value: _showLegend,
                      onChanged: (value) => setState(() => _showLegend = value),
                    ),
                  ],
                ),
                OptionSection(
                  title: 'Theme Components',
                  children: [_buildThemeComponentPreview()],
                ),
                OptionSection(
                  title: 'All Themes',
                  children: [_buildAllThemesPreview()],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.palette, color: _currentTheme.axisStyle.lineColor, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comprehensive Theming Showcase',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _currentTheme.axisStyle.lineColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Theme: ${_themeDisplayNames[_selectedTheme]} • Mixed chart types, annotations, markers, tooltips',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _currentTheme.axisStyle.lineColor.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._themes.keys.map((key) {
          final theme = _themes[key]!;
          final isSelected = key == _selectedTheme;

          return GestureDetector(
            onTap: () => setState(() => _selectedTheme = key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                border: Border.all(
                  color: isSelected ? theme.seriesTheme.colorAt(0) : theme.gridStyle.majorColor,
                  width: isSelected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.seriesTheme.colorAt(0).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Color swatches
                  ...List.generate(
                    3,
                    (i) => Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: theme.seriesTheme.colorAt(i),
                        border: Border.all(color: theme.gridStyle.majorColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _themeDisplayNames[key]!,
                      style: TextStyle(
                        color: theme.axisStyle.lineColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.seriesTheme.colorAt(0),
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Build comprehensive chart showing ALL elements: mixed chart types, annotations, markers, tooltips
  Widget _buildComprehensiveChart() {
    final series = _generateMixedSeries();
    final xAxis = const AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: true,
      showAxisLine: true,
      label: 'Time (samples)',
    );
    final yAxis = const AxisConfig(
      orientation: AxisOrientation.vertical,
      position: AxisPosition.left,
      showGrid: true,
      showAxisLine: true,
      label: 'Value',
    );

    return Card(
      color: _currentTheme.backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _currentTheme.gridStyle.majorColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BravenChartPlus(
          chartType: ChartType.line, // Base type for mixed series
          series: series,
          annotations: _showAnnotations ? _generateAnnotations() : [],
          theme: _currentTheme,
          xAxis: xAxis,
          yAxis: yAxis,
          showLegend: _showLegend,
          backgroundColor: _currentTheme.backgroundColor,
        ),
      ),
    );
  }

  /// Generate mixed series: line, area, scatter showing on one chart
  List<ChartSeries> _generateMixedSeries() {
    const count = 40;
    final random = Random(42);

    // Line series with trend
    final linePoints = List.generate(count, (i) {
      final x = i.toDouble();
      final y = 50 + i * 2 + random.nextDouble() * 20 - 10;
      return ChartDataPoint(x: x, y: y);
    });

    // Area series with different pattern
    final areaPoints = List.generate(count, (i) {
      final x = i.toDouble();
      final y = 30 + sin(i * 0.3) * 15 + random.nextDouble() * 10;
      return ChartDataPoint(x: x, y: y);
    });

    // Scatter points
    final scatterPoints = List.generate(count ~/ 2, (i) {
      final x = (i * 2).toDouble();
      final y = 80 + random.nextDouble() * 40 - 20;
      return ChartDataPoint(x: x, y: y);
    });

    return [
      LineChartSeries(
        id: 'line-series',
        name: 'Line Trend',
        points: linePoints,
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: _showMarkers,
      ),
      AreaChartSeries(
        id: 'area-series',
        name: 'Area Pattern',
        points: areaPoints,
        interpolation: LineInterpolation.bezier,
      ),
      ScatterChartSeries(
        id: 'scatter-series',
        name: 'Data Points',
        points: scatterPoints,
      ),
    ];
  }

  /// Generate all 5 annotation types for comprehensive showcase
  List<ChartAnnotation> _generateAnnotations() {
    return [
      // 1. Point annotation - highlights specific data point
      PointAnnotation(
        id: 'peak-point',
        seriesId: 'line-series',
        dataPointIndex: 30,
        markerShape: MarkerShape.star,
        markerSize: 20.0,
        label: 'Peak',
      ),
      // 2. Range annotation - highlights region
      RangeAnnotation(
        id: 'interest-range',
        startX: 15,
        endX: 25,
        fillColor: _currentTheme.seriesTheme.colorAt(1).withOpacity(0.15),
        borderColor: _currentTheme.seriesTheme.colorAt(1),
        label: 'Focus Period',
        style: _currentTheme.annotationTheme.rangeDefaults.toAnnotationStyle(
          borderColor: _currentTheme.seriesTheme.colorAt(1),
        ),
      ),
      // 3. Text annotation - free-form label
      TextAnnotation(
        id: 'note-text',
        text: 'Trend Rising',
        position: const Offset(200, 50),
        anchor: AnnotationAnchor.topRight,
        style: _currentTheme.annotationTheme.textDefaults.toAnnotationStyle(),
      ),
      // 4. Threshold annotation - reference line
      ThresholdAnnotation(
        id: 'target-threshold',
        axis: AnnotationAxis.y,
        value: 90,
        lineColor: _currentTheme.seriesTheme.colorAt(3),
        lineWidth: 2.5,
        dashPattern: const [8, 4],
        label: 'Target (90)',
        labelPosition: AnnotationLabelPosition.topLeft,
        style: _currentTheme.annotationTheme.thresholdDefaults.toAnnotationStyle(),
      ),
      // 5. Trend annotation - shows trend line
      TrendAnnotation(
        id: 'series-trend',
        seriesId: 'line-series',
        trendType: TrendType.linear,
        lineColor: _currentTheme.seriesTheme.colorAt(4).withOpacity(0.7),
        lineWidth: 3.0,
        label: 'Linear Trend',
        style: _currentTheme.annotationTheme.trendDefaults.toAnnotationStyle(),
      ),
    ];
  }

  Widget _buildMultipleChartsView() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMiniChart(ChartType.line, 'Line Chart with Trend'),
        _buildMiniChart(ChartType.scatter, 'Scatter Plot'),
        _buildMiniChart(ChartType.area, 'Area Chart with Range'),
        _buildMiniChart(ChartType.line, 'Mixed Series'),
      ],
    );
  }

  Widget _buildMiniChart(ChartType type, String title) {
    final series = _generateSeries(_currentTheme, type, mini: true);
    final xAxis = const AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: true,
      showAxisLine: true,
    );
    final yAxis = const AxisConfig(
      orientation: AxisOrientation.vertical,
      position: AxisPosition.left,
      showGrid: true,
      showAxisLine: true,
    );

    return Card(
      color: _currentTheme.backgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _currentTheme.gridStyle.majorColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                color: _currentTheme.axisStyle.lineColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BravenChartPlus(
                chartType: type,
                series: series,
                theme: _currentTheme,
                xAxis: xAxis,
                yAxis: yAxis,
                showLegend: false,
                backgroundColor: _currentTheme.backgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeComponentPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _currentTheme.backgroundColor,
        border: Border.all(color: _currentTheme.gridStyle.majorColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComponentRow('Background', _currentTheme.backgroundColor),
          _buildComponentRow('Grid Lines', _currentTheme.gridStyle.majorColor),
          _buildComponentRow('Axis Lines', _currentTheme.axisStyle.lineColor),
          _buildComponentRow('Crosshair', _currentTheme.interactionTheme.crosshairColor),
          _buildComponentRow('Selection', _currentTheme.interactionTheme.selectionColor),
          const SizedBox(height: 8),
          Text(
            'Series Colors:',
            style: TextStyle(
              color: _currentTheme.axisStyle.lineColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              6,
              (i) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _currentTheme.seriesTheme.colorAt(i),
                  border: Border.all(color: _currentTheme.gridStyle.majorColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _currentTheme.gridStyle.majorColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _currentTheme.axisStyle.lineColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllThemesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Preview',
          style: TextStyle(
            color: _currentTheme.axisStyle.lineColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._themes.entries.map((entry) {
          final theme = entry.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedTheme = entry.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                border: Border.all(
                  color: theme.gridStyle.majorColor,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  ...List.generate(
                    4,
                    (i) => Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: theme.seriesTheme.colorAt(i),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _themeDisplayNames[entry.key]!,
                      style: TextStyle(
                        color: theme.axisStyle.lineColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<ChartSeries> _generateSeries(ChartTheme theme, ChartType chartType, {bool mini = false}) {
    final count = mini ? 20 : 40;

    // Generate sample data
    final data1 = DataGenerator.generateSineWave(
      count: count,
      amplitude: 30,
      frequency: 0.4,
      yOffset: 100,
    );
    final data2 = DataGenerator.generateSineWave(
      count: count,
      amplitude: 25,
      frequency: 0.5,
      phase: 1,
      yOffset: 100,
    );
    final data3 = DataGenerator.generateSineWave(
      count: count,
      amplitude: 20,
      frequency: 0.3,
      phase: 2,
      yOffset: 100,
    );

    // Create series based on chart type
    if (chartType == ChartType.scatter) {
      return [
        ScatterChartSeries(
          id: 'series-1',
          name: 'Dataset A',
          points: data1,
        ),
        ScatterChartSeries(
          id: 'series-2',
          name: 'Dataset B',
          points: data2,
        ),
        ScatterChartSeries(
          id: 'series-3',
          name: 'Dataset C',
          points: data3,
        ),
      ];
    } else if (chartType == ChartType.area) {
      return [
        AreaChartSeries(
          id: 'series-1',
          name: 'Series Alpha',
          points: data1,
          interpolation: LineInterpolation.bezier,
        ),
        AreaChartSeries(
          id: 'series-2',
          name: 'Series Beta',
          points: data2,
          interpolation: LineInterpolation.bezier,
        ),
        AreaChartSeries(
          id: 'series-3',
          name: 'Series Gamma',
          points: data3,
          interpolation: LineInterpolation.bezier,
        ),
      ];
    } else {
      // Line chart (default)
      return [
        LineChartSeries(
          id: 'series-1',
          name: 'Trend 1',
          points: data1,
          interpolation: LineInterpolation.bezier,
          showDataPointMarkers: !mini,
        ),
        LineChartSeries(
          id: 'series-2',
          name: 'Trend 2',
          points: data2,
          interpolation: LineInterpolation.bezier,
          showDataPointMarkers: !mini,
        ),
        LineChartSeries(
          id: 'series-3',
          name: 'Trend 3',
          points: data3,
          interpolation: LineInterpolation.bezier,
          showDataPointMarkers: !mini,
        ),
      ];
    }
  }
}
