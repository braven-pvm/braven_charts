import 'package:braven_charts/src_plus/axis/axis_config.dart';
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
  // Theme selection
  String _themeMode = 'light';
  bool _useCustomColors = false;

  // Custom colors
  Color _backgroundColor = Colors.white;
  Color _gridColor = const Color(0xFFE0E0E0);
  Color _axisColor = Colors.black87;
  Color _textColor = Colors.black87;
  Color _seriesColor1 = Colors.blue;
  Color _seriesColor2 = Colors.red;
  Color _seriesColor3 = Colors.green;

  ChartTheme get _currentTheme {
    if (_useCustomColors) {
      return ChartTheme(
        backgroundColor: _backgroundColor,
        gridColor: _gridColor,
        axisColor: _axisColor,
        textColor: _textColor,
        seriesColors: [_seriesColor1, _seriesColor2, _seriesColor3],
      );
    }

    switch (_themeMode) {
      case 'dark':
        return ChartTheme.dark;
      case 'light':
      default:
        return ChartTheme.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate sample data
    final data1 = DataGenerator.generateSineWave(
      count: 40,
      amplitude: 30,
      frequency: 0.4,
      yOffset: 100,
    );
    final data2 = DataGenerator.generateSineWave(
      count: 40,
      amplitude: 25,
      frequency: 0.5,
      phase: 1,
      yOffset: 100,
    );
    final data3 = DataGenerator.generateSineWave(
      count: 40,
      amplitude: 20,
      frequency: 0.3,
      phase: 2,
      yOffset: 100,
    );

    // Create series
    final series = [
      LineChartSeries(
        id: 'series-1',
        name: 'Series 1',
        points: data1,
        color: _currentTheme.seriesColors[0],
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: true,
      ),
      LineChartSeries(
        id: 'series-2',
        name: 'Series 2',
        points: data2,
        color: _currentTheme.seriesColors[1],
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: true,
      ),
      LineChartSeries(
        id: 'series-3',
        name: 'Series 3',
        points: data3,
        color: _currentTheme.seriesColors[2],
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: true,
      ),
    ];

    // Create axis configs
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

    return Container(
      color: _currentTheme.backgroundColor,
      child: Row(
        children: [
          // Chart
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chart Theming',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _currentTheme.textColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Switch between light/dark themes or customize colors',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _currentTheme.textColor.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BravenChartPlus(
                      chartType: ChartType.line,
                      series: series,
                      theme: _currentTheme,
                      xAxis: xAxis,
                      yAxis: yAxis,
                      showLegend: true,
                      backgroundColor: _currentTheme.backgroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Options Panel
          Container(
            width: 320,
            color: _themeMode == 'dark' ? const Color(0xFF2D2D2D) : Colors.white,
            child: OptionsPanel(
              title: 'Theme Options',
              children: [
                OptionSection(
                  title: 'Theme Mode',
                  children: [
                    EnumOption<String>(
                      label: 'Preset Theme',
                      value: _themeMode,
                      values: const ['light', 'dark'],
                      labelBuilder: (mode) => mode[0].toUpperCase() + mode.substring(1),
                      onChanged: (value) => setState(() {
                        _themeMode = value;
                        _useCustomColors = false;
                      }),
                    ),
                    BoolOption(
                      label: 'Use Custom Colors',
                      value: _useCustomColors,
                      onChanged: (value) => setState(() => _useCustomColors = value),
                    ),
                  ],
                ),
                if (_useCustomColors)
                  OptionSection(
                    title: 'Custom Colors',
                    children: [
                      _buildColorOption('Background', _backgroundColor, (c) => setState(() => _backgroundColor = c)),
                      _buildColorOption('Grid', _gridColor, (c) => setState(() => _gridColor = c)),
                      _buildColorOption('Axis', _axisColor, (c) => setState(() => _axisColor = c)),
                      _buildColorOption('Text', _textColor, (c) => setState(() => _textColor = c)),
                      _buildColorOption('Series 1', _seriesColor1, (c) => setState(() => _seriesColor1 = c)),
                      _buildColorOption('Series 2', _seriesColor2, (c) => setState(() => _seriesColor2 = c)),
                      _buildColorOption('Series 3', _seriesColor3, (c) => setState(() => _seriesColor3 = c)),
                    ],
                  ),
                OptionSection(
                  title: 'Theme Preview',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _currentTheme.backgroundColor,
                        border: Border.all(color: _currentTheme.gridColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPreviewSwatch('Background', _currentTheme.backgroundColor),
                          _buildPreviewSwatch('Grid', _currentTheme.gridColor),
                          _buildPreviewSwatch('Axis', _currentTheme.axisColor),
                          _buildPreviewSwatch('Text', _currentTheme.textColor),
                          const SizedBox(height: 8),
                          Text(
                            'Series Colors:',
                            style: TextStyle(
                              color: _currentTheme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: _currentTheme.seriesColors
                                .map((color) => Container(
                                      width: 30,
                                      height: 30,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(color: _currentTheme.gridColor),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(String label, Color color, Function(Color) onChanged) {
    final colorOptions = [
      Colors.white,
      Colors.black,
      Colors.grey,
      const Color(0xFF1E1E1E),
      const Color(0xFFE0E0E0),
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.yellow,
      Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorOptions.map((c) {
            final isSelected = c == color;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPreviewSwatch(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: _currentTheme.textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
