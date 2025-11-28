import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/options_panel.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  // Performance settings
  int _dataPointCount = 1000;
  int _seriesCount = 1;
  bool _showMarkers = false;
  bool _showGrid = true;
  bool _enableInteraction = true;

  // Performance metrics
  int _renderTime = 0;
  DateTime? _lastRenderStart;

  void _regenerateData() {
    setState(() {
      _lastRenderStart = DateTime.now();
    });

    // Measure render time after frame is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastRenderStart != null) {
        setState(() {
          _renderTime = DateTime.now().difference(_lastRenderStart!).inMilliseconds;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  @override
  Widget build(BuildContext context) {
    // Generate large dataset
    final series = List.generate(_seriesCount, (seriesIndex) {
      final data = DataGenerator.generateSineWave(
        count: _dataPointCount,
        amplitude: 30,
        frequency: 0.05,
        phase: seriesIndex * 1.5,
        yOffset: 100,
        noise: 5.0,
      );

      final colors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.cyan,
        Colors.pink,
        Colors.teal,
      ];

      return LineChartSeries(
        id: 'series-$seriesIndex',
        name: 'Series ${seriesIndex + 1}',
        points: data,
        color: colors[seriesIndex % colors.length],
        interpolation: LineInterpolation.linear,
        showDataPointMarkers: _showMarkers,
      );
    });

    // Create axis configs
    final xAxis = AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: _showGrid,
      showAxisLine: true,
    );

    final yAxis = AxisConfig(
      orientation: AxisOrientation.vertical,
      position: AxisPosition.left,
      showGrid: _showGrid,
      showAxisLine: true,
    );

    final totalPoints = _dataPointCount * _seriesCount;

    return Row(
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
                  'Performance Testing',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Test chart performance with large datasets',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    series: series,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    showLegend: _seriesCount <= 5,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Performance metrics
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Performance Metrics',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetric('Total Points', totalPoints.toString()),
                          _buildMetric('Series Count', _seriesCount.toString()),
                          _buildMetric('Points/Series', _dataPointCount.toString()),
                          _buildMetric(
                            'Render Time',
                            '${_renderTime}ms',
                            color: _renderTime < 100
                                ? Colors.green
                                : _renderTime < 300
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _regenerateData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Regenerate & Test'),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _getPerformanceRating(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getPerformanceColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Options Panel
        SizedBox(
          width: 320,
          child: OptionsPanel(
            title: 'Performance Options',
            children: [
              OptionSection(
                title: 'Dataset Size',
                children: [
                  SliderOption(
                    label: 'Points per Series',
                    value: _dataPointCount.toDouble(),
                    min: 100,
                    max: 10000,
                    divisions: 99,
                    onChanged: (value) => setState(() {
                      _dataPointCount = value.round();
                      _regenerateData();
                    }),
                  ),
                  SliderOption(
                    label: 'Number of Series',
                    value: _seriesCount.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    onChanged: (value) => setState(() {
                      _seriesCount = value.round();
                      _regenerateData();
                    }),
                  ),
                ],
              ),
              OptionSection(
                title: 'Rendering Options',
                children: [
                  BoolOption(
                    label: 'Show Data Point Markers',
                    value: _showMarkers,
                    onChanged: (value) => setState(() {
                      _showMarkers = value;
                      _regenerateData();
                    }),
                  ),
                  BoolOption(
                    label: 'Show Grid',
                    value: _showGrid,
                    onChanged: (value) => setState(() {
                      _showGrid = value;
                      _regenerateData();
                    }),
                  ),
                  BoolOption(
                    label: 'Enable Interaction',
                    value: _enableInteraction,
                    onChanged: (value) => setState(() {
                      _enableInteraction = value;
                      _regenerateData();
                    }),
                  ),
                ],
              ),
              OptionSection(
                title: 'Performance Guide',
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optimization Tips:',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildTip('• Disable markers for large datasets'),
                        _buildTip('• Use linear interpolation instead of bezier'),
                        _buildTip('• Limit visible series to 5-8'),
                        _buildTip('• Reduce grid line density'),
                        _buildTip('• Consider data downsampling > 5000 points'),
                      ],
                    ),
                  ),
                ],
              ),
              OptionSection(
                title: 'Benchmark Tests',
                children: [
                  ElevatedButton(
                    onPressed: () => _runBenchmark(1000, 1),
                    child: const Text('1K points, 1 series'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _runBenchmark(5000, 1),
                    child: const Text('5K points, 1 series'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _runBenchmark(10000, 1),
                    child: const Text('10K points, 1 series'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _runBenchmark(1000, 5),
                    child: const Text('1K points, 5 series'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
      ),
    );
  }

  String _getPerformanceRating() {
    if (_renderTime < 50) return '⚡ Excellent Performance';
    if (_renderTime < 100) return '✓ Good Performance';
    if (_renderTime < 300) return '⚠ Acceptable Performance';
    if (_renderTime < 500) return '⚠ Slow Performance';
    return '❌ Poor Performance';
  }

  Color _getPerformanceColor() {
    if (_renderTime < 50) return Colors.green;
    if (_renderTime < 100) return Colors.lightGreen;
    if (_renderTime < 300) return Colors.orange;
    if (_renderTime < 500) return Colors.deepOrange;
    return Colors.red;
  }

  void _runBenchmark(int points, int series) {
    setState(() {
      _dataPointCount = points;
      _seriesCount = series;
      _regenerateData();
    });
  }
}

