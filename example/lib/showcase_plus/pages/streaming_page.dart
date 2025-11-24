import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/streaming_config.dart';
import 'package:braven_charts/src_plus/streaming/streaming_controller.dart';
import 'package:braven_charts/src_plus/axis/axis_config.dart';
import 'package:braven_charts/src_plus/models/enums.dart';
import '../widgets/options_panel.dart';

class StreamingPage extends StatefulWidget {
  const StreamingPage({super.key});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  // Streaming controller
  late final StreamingController _streamingController;
  late final StreamController<ChartDataPoint> _dataStreamController;

  // Streaming configuration
  int _maxBufferSize = 10000;
  bool _autoScroll = true;
  int _autoScrollWindowSize = 150;

  // Stream generation
  Timer? _dataTimer;
  double _currentX = 0;
  double _frequency = 10.0; // 10 Hz
  String _bufferCount = '0';

  // Data generation settings
  String _dataPattern = 'sine';
  double _noise = 5.0;

  @override
  void initState() {
    super.initState();
    _streamingController = StreamingController();
    _dataStreamController = StreamController<ChartDataPoint>();
    _startDataGeneration();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    _dataStreamController.close();
    _streamingController.dispose();
    super.dispose();
  }

  void _startDataGeneration() {
    _dataTimer?.cancel();
    final period = Duration(milliseconds: (1000 / _frequency).round());

    _dataTimer = Timer.periodic(period, (timer) {
      final random = math.Random();
      double y;

      switch (_dataPattern) {
        case 'sine':
          y = 50 + 30 * math.sin(_currentX * 0.2) + (random.nextDouble() - 0.5) * _noise;
          break;
        case 'random':
          y = 50 + (random.nextDouble() - 0.5) * 40;
          break;
        case 'step':
          y = 30 + (_currentX ~/ 20 % 2) * 40 + (random.nextDouble() - 0.5) * _noise;
          break;
        default:
          y = 50;
      }

      _dataStreamController.add(ChartDataPoint(x: _currentX, y: y));
      _currentX += 1;
    });
  }

  void _updateFrequency(double newFrequency) {
    setState(() {
      _frequency = newFrequency;
    });
    _startDataGeneration();
  }

  @override
  Widget build(BuildContext context) {
    // Empty series - data will come from stream
    final series = [
      LineChartSeries(
        id: 'stream-series',
        name: 'Real-time Data',
        points: const [],
        color: Colors.blue,
        interpolation: LineInterpolation.linear,
        showDataPointMarkers: false,
      ),
    ];

    // Create streaming config
    final streamingConfig = StreamingConfig(
      maxBufferSize: _maxBufferSize,
      autoScroll: _autoScroll,
      autoScrollWindowSize: _autoScrollWindowSize,
      onBufferUpdated: (count) {
        setState(() {
          _bufferCount = count.toString();
        });
      },
      onStreamError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stream error: $error')),
        );
      },
    );

    // Create axis configs
    final xAxis = AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: true,
      showAxisLine: true,
    );

    final yAxis = AxisConfig(
      orientation: AxisOrientation.vertical,
      position: AxisPosition.left,
      showGrid: true,
      showAxisLine: true,
    );

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
                  'Real-time Streaming',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Live data streaming with pause/resume and auto-scroll',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    series: series,
                    dataStream: _dataStreamController.stream,
                    streamingConfig: streamingConfig,
                    streamingController: _streamingController,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    showLegend: false,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Controls
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _streamingController,
                      builder: (context, _) {
                        return ElevatedButton.icon(
                          onPressed: _streamingController.isStreaming
                              ? _streamingController.pauseStreaming
                              : _streamingController.resumeStreaming,
                          icon: Icon(
                            _streamingController.isStreaming ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_streamingController.isStreaming ? 'Pause' : 'Resume'),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _dataTimer?.cancel();
                        _currentX = 0;
                        _dataStreamController.close();
                        setState(() {
                          _dataStreamController = StreamController<ChartDataPoint>();
                        });
                        _startDataGeneration();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                    const SizedBox(width: 24),
                    // Status info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _streamingController,
                            builder: (context, _) {
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _streamingController.isStreaming ? Colors.green : Colors.red,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text('Buffered: $_bufferCount points'),
                          const SizedBox(width: 16),
                          Text('Frequency: ${_frequency.toStringAsFixed(0)} Hz'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Options Panel
        SizedBox(
          width: 320,
          child: OptionsPanel(
            title: 'Streaming Options',
            children: [
              OptionSection(
                title: 'Stream Configuration',
                children: [
                  BoolOption(
                    label: 'Auto-Scroll',
                    value: _autoScroll,
                    onChanged: (value) => setState(() => _autoScroll = value),
                  ),
                  SliderOption(
                    label: 'Window Size',
                    value: _autoScrollWindowSize.toDouble(),
                    min: 50,
                    max: 500,
                    divisions: 9,
                    onChanged: (value) => setState(() => _autoScrollWindowSize = value.round()),
                  ),
                  SliderOption(
                    label: 'Buffer Size',
                    value: _maxBufferSize.toDouble(),
                    min: 1000,
                    max: 20000,
                    divisions: 19,
                    onChanged: (value) => setState(() => _maxBufferSize = value.round()),
                  ),
                ],
              ),
              OptionSection(
                title: 'Data Generation',
                children: [
                  EnumOption<String>(
                    label: 'Pattern',
                    value: _dataPattern,
                    values: const ['sine', 'random', 'step'],
                    labelBuilder: (pattern) => pattern[0].toUpperCase() + pattern.substring(1),
                    onChanged: (value) => setState(() => _dataPattern = value),
                  ),
                  SliderOption(
                    label: 'Frequency (Hz)',
                    value: _frequency,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: _updateFrequency,
                  ),
                  SliderOption(
                    label: 'Noise',
                    value: _noise,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    onChanged: (value) => setState(() => _noise = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
