// Copyright 2025 Braven Charts - Live Streaming Page
// SPDX-License-Identifier: MIT

import 'dart:async';
// Only import dart:isolate on non-web platforms
import 'dart:isolate' if (dart.library.html) 'live_streaming_page_web_stub.dart';
import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

// ============================================================================
// Isolate-based Data Generator (Background Thread)
// ============================================================================

/// Message to control the isolate generator
class IsolateControlMessage {
  final String command; // 'start', 'stop', 'update_rate'
  final int? rateHz;
  final DataPattern? pattern;
  final double? amplitude;
  final double? frequency;

  IsolateControlMessage({
    required this.command,
    this.rateHz,
    this.pattern,
    this.amplitude,
    this.frequency,
  });
}

/// Data batch sent from isolate to main
class DataBatch {
  final List<ChartDataPoint> points;
  final int generatedCount;
  final DateTime timestamp;

  DataBatch({
    required this.points,
    required this.generatedCount,
    required this.timestamp,
  });
}

/// Entry point for the background isolate
void _dataGeneratorIsolate(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Timer? timer;
  int pointCounter = 0;
  double lastValue = 50.0;
  final random = Random();

  // Current config
  int rateHz = 20;
  DataPattern pattern = DataPattern.randomWalk;
  double amplitude = 30.0;
  double frequency = 0.05;

  // Batch points to reduce SendPort overhead
  List<ChartDataPoint> pendingBatch = [];
  const batchSize = 10; // Send 10 points at a time

  void generatePoint() {
    final y = _generateValueInIsolate(
      pointCounter,
      pattern,
      amplitude,
      frequency,
      random,
      lastValue,
    );
    lastValue = y;

    pendingBatch.add(ChartDataPoint(
      x: pointCounter.toDouble(),
      y: y,
    ));
    pointCounter++;

    // Send batch when full
    if (pendingBatch.length >= batchSize) {
      mainSendPort.send(DataBatch(
        points: List.from(pendingBatch),
        generatedCount: pointCounter,
        timestamp: DateTime.now(),
      ));
      pendingBatch.clear();
    }
  }

  receivePort.listen((message) {
    if (message is IsolateControlMessage) {
      switch (message.command) {
        case 'start':
          timer?.cancel();
          if (message.rateHz != null) rateHz = message.rateHz!;
          if (message.pattern != null) pattern = message.pattern!;
          if (message.amplitude != null) amplitude = message.amplitude!;
          if (message.frequency != null) frequency = message.frequency!;

          final intervalMs = (1000 / rateHz).round();
          timer = Timer.periodic(
            Duration(milliseconds: intervalMs),
            (_) => generatePoint(),
          );
          break;

        case 'stop':
          timer?.cancel();
          timer = null;
          // Flush remaining batch
          if (pendingBatch.isNotEmpty) {
            mainSendPort.send(DataBatch(
              points: List.from(pendingBatch),
              generatedCount: pointCounter,
              timestamp: DateTime.now(),
            ));
            pendingBatch.clear();
          }
          break;

        case 'update_rate':
          if (message.rateHz != null) {
            rateHz = message.rateHz!;
            if (timer != null) {
              timer!.cancel();
              final intervalMs = (1000 / rateHz).round();
              timer = Timer.periodic(
                Duration(milliseconds: intervalMs),
                (_) => generatePoint(),
              );
            }
          }
          break;
      }
    }
  });
}

/// Generate value in isolate (no access to instance variables)
double _generateValueInIsolate(
  int counter,
  DataPattern pattern,
  double amplitude,
  double frequency,
  Random random,
  double lastValue,
) {
  switch (pattern) {
    case DataPattern.randomWalk:
      final change = random.nextDouble() * amplitude * 0.1 - amplitude * 0.05;
      return (lastValue + change).clamp(10.0, 90.0);

    case DataPattern.sine:
      return 50 + amplitude * sin(counter * frequency);

    case DataPattern.sawtooth:
      final phase = (counter * frequency) % 1.0;
      return 50 - amplitude + (phase * amplitude * 2);

    case DataPattern.noise:
      return 50 + (random.nextDouble() * 2 - 1) * amplitude;

    case DataPattern.stepFunction:
      final stepValue = ((counter ~/ 20) % 5) * (amplitude / 2);
      return 30 + stepValue + (random.nextDouble() * 5 - 2.5);
  }
}

/// Data generation pattern for streaming demo.
enum DataPattern {
  randomWalk,
  sine,
  sawtooth,
  noise,
  stepFunction,
}

/// Demonstrates high-performance live streaming using LiveStreamController.
///
/// Key features:
/// - Frame-coalesced updates (max 60fps)
/// - Direct RenderBox path (no widget rebuild)
/// - Built-in pause/resume with buffering
/// - Auto-scroll that snaps to latest data
/// - Configurable buffer sizes and auto-scroll margin
///
/// Compare with streaming_page.dart which uses the legacy approach.
class LiveStreamingPage extends StatefulWidget {
  const LiveStreamingPage({super.key});

  @override
  State<LiveStreamingPage> createState() => _LiveStreamingPageState();
}

class _LiveStreamingPageState extends State<LiveStreamingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // LiveStreamController - the recommended high-performance streaming API
  LiveStreamController? _streamController;

  // Isolate-based data generation (only available on native platforms)
  Isolate? _generatorIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _isolateReceivePort;
  bool _useIsolate = !kIsWeb; // Isolates not supported on web platform

  // Legacy Timer-based generation (for comparison)
  Timer? _dataTimer;
  int _pointCounter = 0;
  double _lastValue = 50.0;
  final Random _random = Random();

  // LiveStreamController Configuration
  int _maxPoints = 500;
  bool _autoScroll = true;
  double _autoScrollMarginPercent = 5.0;
  int _pauseBufferSize = 5000;
  int _viewportDataPoints = 100; // How many points to show in viewport
  int _maxVisiblePoints = 1000; // Max points before expand mode switches to sliding

  // Data Generation Configuration
  int _updateRateHz = 20;
  DataPattern _dataPattern = DataPattern.randomWalk;
  double _amplitude = 30.0;
  double _frequency = 0.05; // For sine/sawtooth

  // Series Styling
  LineInterpolation _interpolation = LineInterpolation.bezier;
  double _strokeWidth = 2.0;
  Color _lineColor = Colors.blue;

  // Performance stats
  int _totalPointsGenerated = 0;
  DateTime? _streamStartTime;
  int _bufferSizeAtStart = 0;

  // Rolling rate calculation (last second)
  int _pointsInLastSecond = 0;
  DateTime? _lastSecondStart;

  // Timer accuracy measurement
  DateTime? _lastTimerFire;
  final List<int> _timerIntervals = [];

  @override
  void initState() {
    super.initState();
    _optionsController.showXScrollbar = true;

    // Create the LiveStreamController with initial configuration
    _createStreamController();

    // Initialize with some data
    _initializeData();
  }

  void _createStreamController() {
    // Dispose old controller if exists
    _streamController?.removeListener(_onStreamStateChanged);
    _streamController?.dispose();

    // When auto-scroll is OFF, we want to keep ALL data (expand mode)
    // Use a much larger buffer to avoid losing data
    // When auto-scroll is ON, use the configured maxPoints for sliding window
    final effectiveMaxPoints = _autoScroll ? _maxPoints : 100000;

    // Create new controller with current settings
    _streamController = LiveStreamController(
      seriesId: 'live-data', // Must match series ID in chart
      maxPoints: effectiveMaxPoints,
      autoScroll: _autoScroll,
      autoScrollMarginPercent: _autoScrollMarginPercent,
      viewportDataPoints: _viewportDataPoints,
      maxVisiblePoints: _maxVisiblePoints,
      pauseBufferSize: _pauseBufferSize,
    );

    // Add listener to update UI (status panel, etc.)
    _streamController!.addListener(_onStreamStateChanged);
  }

  void _recreateController() {
    final wasStreaming = _dataTimer != null;
    _stopStreaming();

    // Preserve some data for continuity
    final oldPoints = _streamController?.points ?? [];

    _createStreamController();

    // Re-add preserved points (up to new maxPoints limit)
    final startIdx = oldPoints.length > _maxPoints ? oldPoints.length - _maxPoints : 0;
    for (var i = startIdx; i < oldPoints.length; i++) {
      _streamController!.addPoint(oldPoints[i]);
    }

    if (wasStreaming) {
      _startStreaming();
    }

    setState(() {});
  }

  void _initializeData() {
    // Add initial points
    for (var i = 0; i < 50; i++) {
      _generateAndAddPoint();
    }
  }

  void _onStreamStateChanged() {
    // Rebuild to update UI
    if (mounted) setState(() {});
  }

  void _startStreaming() async {
    if ((_useIsolate && _generatorIsolate != null) || (!_useIsolate && _dataTimer != null)) {
      return;
    }

    _streamStartTime = DateTime.now();
    _totalPointsGenerated = 0;
    _pointsInLastSecond = 0;
    _lastSecondStart = null;
    _lastTimerFire = null;
    _timerIntervals.clear();
    _bufferSizeAtStart = _streamController?.pointCount ?? 0;

    // Make sure streaming is resumed (unlocks viewport for auto-scroll)
    if (!(_streamController?.isStreaming ?? true)) {
      _streamController?.resume();
    }

    if (_useIsolate && !kIsWeb) {
      // Start isolate-based generation (native platforms only)
      print('Starting ISOLATE-based generation: $_updateRateHz Hz');

      try {
        _isolateReceivePort = ReceivePort();
        _generatorIsolate = await Isolate.spawn(
          _dataGeneratorIsolate,
          _isolateReceivePort!.sendPort,
        );

        // Wait for isolate to send back its SendPort
        _isolateReceivePort!.listen((message) {
          if (message is SendPort) {
            _isolateSendPort = message;
            // Start generation
            _isolateSendPort!.send(IsolateControlMessage(
              command: 'start',
              rateHz: _updateRateHz,
              pattern: _dataPattern,
              amplitude: _amplitude,
              frequency: _frequency,
            ));
          } else if (message is DataBatch) {
            // Receive batch from isolate
            _handleDataBatch(message);
          }
        });
      } catch (e) {
        print('Failed to spawn isolate: $e');
        print('Falling back to main thread Timer');
        _useIsolate = false;
        setState(() {});
      }
    }

    if (!_useIsolate || kIsWeb) {
      // Start main-thread Timer-based generation
      final intervalMs = (1000 / _updateRateHz).round();
      print('Starting MAIN THREAD Timer.periodic: $_updateRateHz Hz (${intervalMs}ms interval)');

      _dataTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _generateDataPoint(),
      );
    }

    setState(() {});
  }

  void _handleDataBatch(DataBatch batch) {
    if (!mounted) return;

    // Add all points from batch to controller
    for (final point in batch.points) {
      _streamController?.addPoint(point);
      _pointCounter++;
      _pointsInLastSecond++;
      _totalPointsGenerated++;
    }

    // Track rolling rate (last second)
    _lastSecondStart ??= DateTime.now();
    final elapsedMs = DateTime.now().difference(_lastSecondStart!).inMilliseconds;
    if (elapsedMs >= 1000) {
      // Reset counter every second and update UI
      _pointsInLastSecond = 0;
      _lastSecondStart = DateTime.now();
      setState(() {});
    }
  }

  void _stopStreaming() {
    if (_useIsolate && !kIsWeb && _generatorIsolate != null) {
      try {
        _isolateSendPort?.send(IsolateControlMessage(command: 'stop'));
        _generatorIsolate?.kill(priority: Isolate.immediate);
      } catch (e) {
        print('Error stopping isolate: $e');
      }
      _generatorIsolate = null;
      _isolateSendPort = null;
      _isolateReceivePort?.close();
      _isolateReceivePort = null;
    }

    if (_dataTimer != null) {
      _dataTimer?.cancel();
      _dataTimer = null;
    }

    _streamStartTime = null;
    _lastSecondStart = null;
    _lastTimerFire = null;

    // When stopping data flow, also lock viewport so user can pan historical data
    _streamController?.pause();

    setState(() {});
  }

  void _generateDataPoint() {
    if (!mounted) return;

    // Measure actual timer interval
    final now = DateTime.now();
    if (_lastTimerFire != null) {
      final intervalMs = now.difference(_lastTimerFire!).inMilliseconds;
      _timerIntervals.add(intervalMs);
      if (_timerIntervals.length > 100) _timerIntervals.removeAt(0);

      // Log diagnostics every 60 fires
      if (_totalPointsGenerated % 60 == 0 && _timerIntervals.length > 10) {
        final avg = _timerIntervals.reduce((a, b) => a + b) / _timerIntervals.length;
        final actualHz = 1000 / avg;
        print('Timer diagnostic: requested ${_updateRateHz}Hz (${(1000 / _updateRateHz).toStringAsFixed(1)}ms), '
            'actual ${actualHz.toStringAsFixed(1)}Hz (${avg.toStringAsFixed(1)}ms avg over ${_timerIntervals.length} samples)');
      }
    }
    _lastTimerFire = now;

    _generateAndAddPoint();
    _totalPointsGenerated++;

    // Track rolling rate (last second)
    _lastSecondStart ??= DateTime.now();
    _pointsInLastSecond++;
    final elapsedMs = DateTime.now().difference(_lastSecondStart!).inMilliseconds;
    if (elapsedMs >= 1000) {
      // Reset counter every second
      _pointsInLastSecond = 0;
      _lastSecondStart = DateTime.now();

      // CRITICAL: Only update UI once per second to avoid blocking timer callbacks
      // setState() is SYNCHRONOUS and blocks the microtask queue!
      setState(() {});
    }
  }

  void _generateAndAddPoint() {
    final y = _generateValue();

    // Add point via LiveStreamController
    // This does NOT trigger widget rebuild - it goes directly to RenderBox!
    _streamController?.addPoint(ChartDataPoint(
      x: _pointCounter.toDouble(),
      y: y,
    ));
    _pointCounter++;
  }

  double _generateValue() {
    switch (_dataPattern) {
      case DataPattern.randomWalk:
        final change = _random.nextDouble() * _amplitude * 0.1 - _amplitude * 0.05;
        _lastValue = (_lastValue + change).clamp(10.0, 90.0);
        return _lastValue;

      case DataPattern.sine:
        return 50 + _amplitude * sin(_pointCounter * _frequency);

      case DataPattern.sawtooth:
        final phase = (_pointCounter * _frequency) % 1.0;
        return 50 - _amplitude + (phase * _amplitude * 2);

      case DataPattern.noise:
        return 50 + (_random.nextDouble() * 2 - 1) * _amplitude;

      case DataPattern.stepFunction:
        // Step every 20 points
        final stepValue = ((_pointCounter ~/ 20) % 5) * (_amplitude / 2);
        return 30 + stepValue + (_random.nextDouble() * 5 - 2.5);
    }
  }

  void _togglePause() {
    if (_streamController?.isStreaming ?? false) {
      _streamController?.pause();
    } else {
      _streamController?.resume();
    }
  }

  void _resetData() {
    _stopStreaming();
    _streamController?.clear();
    _pointCounter = 0;
    _lastValue = 50.0;
    _totalPointsGenerated = 0;
    _pointsInLastSecond = 0;
    _lastSecondStart = null;
    _initializeData();
    setState(() {});
  }

  @override
  void dispose() {
    // CRITICAL: Remove listener BEFORE stopping stream to prevent setState() during dispose
    _streamController?.removeListener(_onStreamStateChanged);

    _stopStreaming();
    _streamController?.dispose();
    _optionsController.dispose();

    // Ensure isolate is killed (native platforms only)
    if (!kIsWeb && _generatorIsolate != null) {
      try {
        _generatorIsolate?.kill(priority: Isolate.immediate);
        _isolateReceivePort?.close();
      } catch (e) {
        print('Error cleaning up isolate in dispose: $e');
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Live Streaming (High-Performance)',
      subtitle: 'Using LiveStreamController - Frame-coalesced, direct RenderBox path',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    final isDataFlowing = _useIsolate ? _generatorIsolate != null : _dataTimer != null;
    final isPaused = !(_streamController?.isStreaming ?? true);

    return [
      // Standard display options (disable marker/lineStyle since we have custom controls)
      StandardChartOptions(
        controller: _optionsController,
        showMarkerOption: false, // We have custom 'Show Data Markers' in Line Styling
        showLineStyleOption: false, // We use interpolation setting instead
        showLegendOption: false, // Legend not needed for single series
      ),

      // LiveStreamController Configuration
      // Only show buffer settings when auto-scroll is ON
      // When auto-scroll is OFF (expand mode), buffer is effectively unlimited
      if (_autoScroll)
        OptionSection(
          title: 'Buffer Settings',
          icon: Icons.memory,
          children: [
            IntSliderOption(
              label: 'Max Points (Window Size)',
              value: _maxPoints,
              min: 100,
              max: 5000,
              suffix: 'pts',
              onChanged: (v) {
                setState(() => _maxPoints = v);
                _recreateController();
              },
            ),
            IntSliderOption(
              label: 'Pause Buffer Size',
              value: _pauseBufferSize,
              min: 1000,
              max: 50000,
              suffix: 'pts',
              onChanged: (v) {
                setState(() => _pauseBufferSize = v);
                _recreateController();
              },
            ),
          ],
        ),

      // Auto-scroll settings
      OptionSection(
        title: 'Viewport Mode',
        icon: _autoScroll ? Icons.auto_awesome : Icons.zoom_out_map,
        children: [
          BoolOption(
            label: 'Auto-Scroll Mode',
            value: _autoScroll,
            subtitle: _autoScroll ? 'Following latest data (sliding window)' : 'Expand Mode: Viewport grows until $_maxVisiblePoints pts',
            onChanged: (v) {
              setState(() => _autoScroll = v);
              _recreateController();
            },
          ),
          if (_autoScroll) ...[
            SliderOption(
              label: 'Scroll Margin',
              value: _autoScrollMarginPercent,
              min: 0,
              max: 30,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (v) {
                setState(() => _autoScrollMarginPercent = v);
                _recreateController();
              },
            ),
            IntSliderOption(
              label: 'Viewport Width',
              value: _viewportDataPoints,
              min: 20,
              max: _maxPoints,
              suffix: 'pts',
              onChanged: (v) {
                setState(() => _viewportDataPoints = v);
                _recreateController();
              },
            ),
          ] else ...[
            // Expand mode settings
            IntSliderOption(
              label: 'Max Visible Points',
              value: _maxVisiblePoints,
              min: 500,
              max: 50000,
              suffix: 'pts',
              onChanged: (v) {
                setState(() => _maxVisiblePoints = v);
                _recreateController();
              },
            ),
          ],
        ],
      ),

      // Data generation controls
      OptionSection(
        title: 'Data Generation',
        icon: Icons.show_chart,
        children: [
          BoolOption(
            label: 'Use Background Isolate',
            value: _useIsolate,
            subtitle: kIsWeb
                ? '🌐 Web platform: Isolates not supported (dart:isolate unavailable in browsers)'
                : _useIsolate
                    ? '✓ Isolate mode: Timer runs in background thread (true high-frequency)'
                    : '⚠ Main thread mode: Timer shares event loop with rendering',
            onChanged: kIsWeb
                ? (_) {} // Disabled on web - isolates not supported
                : (v) {
                    final wasStreaming = (_useIsolate && _generatorIsolate != null) || (!_useIsolate && _dataTimer != null);
                    if (wasStreaming) {
                      _stopStreaming();
                    }
                    setState(() => _useIsolate = v);
                    if (wasStreaming) {
                      _startStreaming();
                    }
                  },
          ),
          const SizedBox(height: 8),
          IntSliderOption(
            label: 'Update Rate',
            value: _updateRateHz,
            min: 1,
            max: 1000,
            suffix: 'Hz',
            onChanged: (v) {
              setState(() => _updateRateHz = v);
              final wasStreaming = (_useIsolate && _generatorIsolate != null) || (!_useIsolate && _dataTimer != null);
              if (wasStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
          ),
          EnumOption<DataPattern>(
            label: 'Data Pattern',
            value: _dataPattern,
            values: DataPattern.values,
            onChanged: (v) => setState(() => _dataPattern = v),
            labelBuilder: (p) => switch (p) {
              DataPattern.randomWalk => 'Random Walk',
              DataPattern.sine => 'Sine Wave',
              DataPattern.sawtooth => 'Sawtooth',
              DataPattern.noise => 'Random Noise',
              DataPattern.stepFunction => 'Step Function',
            },
          ),
          SliderOption(
            label: 'Amplitude',
            value: _amplitude,
            min: 5,
            max: 45,
            suffix: '',
            decimalPlaces: 0,
            onChanged: (v) => setState(() => _amplitude = v),
          ),
          if (_dataPattern == DataPattern.sine || _dataPattern == DataPattern.sawtooth)
            SliderOption(
              label: 'Frequency',
              value: _frequency,
              min: 0.01,
              max: 0.2,
              suffix: '',
              decimalPlaces: 2,
              onChanged: (v) => setState(() => _frequency = v),
            ),
        ],
      ),

      // Series styling
      OptionSection(
        title: 'Line Styling',
        icon: Icons.brush,
        children: [
          EnumOption<LineInterpolation>(
            label: 'Line Interpolation',
            value: _interpolation,
            values: LineInterpolation.values,
            onChanged: (v) => setState(() => _interpolation = v),
            labelBuilder: (i) => switch (i) {
              LineInterpolation.linear => 'Linear',
              LineInterpolation.bezier => 'Bezier (Smooth)',
              LineInterpolation.stepped => 'Stepped',
              LineInterpolation.monotone => 'Monotone',
            },
          ),
          SliderOption(
            label: 'Stroke Width',
            value: _strokeWidth,
            min: 0.5,
            max: 5.0,
            suffix: 'px',
            decimalPlaces: 1,
            onChanged: (v) => setState(() => _strokeWidth = v),
          ),
          BoolOption(
            label: 'Show Data Markers',
            value: _optionsController.showDataMarkers,
            subtitle: 'Display points on line',
            onChanged: (v) => _optionsController.showDataMarkers = v,
          ),
          ColorOption(
            label: 'Line Color',
            value: _lineColor,
            colors: const [
              Colors.blue,
              Colors.green,
              Colors.red,
              Colors.orange,
              Colors.purple,
              Colors.teal,
              Colors.pink,
              Colors.indigo,
            ],
            onChanged: (v) => setState(() => _lineColor = v),
          ),
        ],
      ),

      // Data flow controls
      OptionSection(
        title: 'Data Flow',
        icon: Icons.play_arrow,
        children: [
          ActionButton(
            label: isDataFlowing ? 'Stop Data' : 'Start Data',
            icon: isDataFlowing ? Icons.stop : Icons.play_arrow,
            isPrimary: !isDataFlowing,
            isDestructive: isDataFlowing,
            onPressed: isDataFlowing ? _stopStreaming : _startStreaming,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: isPaused ? 'Resume Chart' : 'Pause Chart',
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            isPrimary: isPaused,
            onPressed: _togglePause,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Reset',
            icon: Icons.refresh,
            onPressed: _resetData,
          ),
        ],
      ),

      // Performance info
      InfoBox(
        message: isPaused
            ? 'Chart paused. ${_streamController?.bufferedCount ?? 0} points buffered. '
                'Click Resume to apply buffered data.'
            : 'Using LiveStreamController for high-performance streaming. '
                'Data flows directly to RenderBox without widget rebuilds!',
        type: isPaused ? InfoBoxType.warning : (isDataFlowing ? InfoBoxType.success : InfoBoxType.info),
      ),
    ];
  }

  Widget _buildChart() {
    final isDataFlowing = _useIsolate ? _generatorIsolate != null : _dataTimer != null;
    final isPaused = !(_streamController?.isStreaming ?? true);

    // Determine line color based on state
    final effectiveColor = isPaused ? Colors.orange : (isDataFlowing ? _lineColor : _lineColor.withValues(alpha: 0.7));

    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Live Data Stream',
          subtitle: isPaused ? 'Paused (buffering...)' : (isDataFlowing ? 'Streaming at $_updateRateHz Hz' : 'Stopped'),
          actions: [
            // Buffered count badge
            if (isPaused && (_streamController?.bufferedCount ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${_streamController?.bufferedCount ?? 0}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPaused ? Colors.orange : (isDataFlowing ? Colors.green : Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaused ? Icons.pause : (isDataFlowing ? Icons.fiber_manual_record : Icons.stop),
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPaused ? 'PAUSED' : (isDataFlowing ? 'LIVE' : 'STOPPED'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: BravenChartPlus(
            // Series defines styling, LiveStreamController provides data
            series: [
              LineChartSeries(
                id: 'live-data', // Must match LiveStreamController.seriesId!
                name: 'Live Data',
                points: const [], // Initial points (can be empty)
                color: effectiveColor,
                interpolation: _interpolation,
                strokeWidth: _strokeWidth,
                showDataPointMarkers: _optionsController.showDataMarkers,
              ),
            ],
            // Connect LiveStreamController - this is the key!
            liveStreamController: _streamController,
            theme: _optionsController.theme,
            showLegend: false,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,

            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
            xAxis: AxisConfig(
              showGrid: _optionsController.showGrid,
              showAxis: _optionsController.showAxisLines,
            ),
            yAxis: AxisConfig(
              showGrid: _optionsController.showGrid,
              showAxis: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    final isDataFlowing = _useIsolate ? _generatorIsolate != null : _dataTimer != null;
    final isPaused = !(_streamController?.isStreaming ?? true);
    final bounds = _streamController?.bounds;

    // Calculate effective rate - use rolling 1-second window for accuracy
    String effectiveRate = '$_updateRateHz Hz';
    if (isDataFlowing && _lastSecondStart != null) {
      final elapsedInSecond = DateTime.now().difference(_lastSecondStart!).inMilliseconds;
      if (elapsedInSecond > 100) {
        // Wait at least 100ms for stable measurement
        final instantRate = (_pointsInLastSecond / (elapsedInSecond / 1000)).toStringAsFixed(1);
        effectiveRate = '$instantRate Hz';
      }
    }

    // Calculate ACTUAL buffer growth rate
    String actualBufferRate = '-';
    String expectedVsActual = '-';
    if (isDataFlowing && _streamStartTime != null) {
      final elapsed = DateTime.now().difference(_streamStartTime!).inSeconds;
      if (elapsed > 0) {
        final currentBufferSize = _streamController?.pointCount ?? 0;
        final pointsAdded = currentBufferSize - _bufferSizeAtStart;
        final actualRate = pointsAdded / elapsed;
        actualBufferRate = '${actualRate.toStringAsFixed(1)} pts/s';

        final expected = _updateRateHz * elapsed;
        final percentAchieved = (pointsAdded / expected * 100).toStringAsFixed(1);
        expectedVsActual = '$pointsAdded / $expected pts ($percentAchieved%)';
      }
    }

    // Get measured frame rate from controller
    final frameRate = _streamController?.measuredFrameRate ?? 0;
    final frameRateStr = frameRate > 0 ? '${frameRate.toStringAsFixed(1)} fps' : '-';

    return StatusPanel(
      highlighted: isDataFlowing && !isPaused,
      items: [
        StatusItem(
          label: 'Status',
          value: isPaused ? 'Paused' : (isDataFlowing ? 'Streaming' : 'Stopped'),
          color: isPaused ? Colors.orange : (isDataFlowing ? Colors.green : Colors.grey),
        ),
        StatusItem(
          label: 'Points',
          value: '${_streamController?.pointCount ?? 0}/$_maxPoints',
        ),
        StatusItem(
          label: 'Buffered',
          value: '${_streamController?.bufferedCount ?? 0}',
          color: (_streamController?.bufferedCount ?? 0) > 0 ? Colors.orange : null,
        ),
        StatusItem(
          label: 'Requested Rate',
          value: '$_updateRateHz Hz',
        ),
        StatusItem(
          label: 'Measured Rate',
          value: effectiveRate,
        ),
        StatusItem(
          label: 'Buffer Growth',
          value: actualBufferRate,
          color: Colors.blue,
        ),
        StatusItem(
          label: 'Expected vs Actual',
          value: expectedVsActual,
          color: Colors.purple,
        ),
        StatusItem(
          label: 'Frame Rate',
          value: frameRateStr,
          color: frameRate > 50 ? Colors.green : (frameRate > 30 ? Colors.orange : Colors.red),
        ),
        StatusItem(
          label: 'Pattern',
          value: _dataPattern.name,
        ),
        StatusItem(
          label: 'X Range',
          value: bounds != null ? '${bounds.xMin.toInt()}-${bounds.xMax.toInt()}' : '-',
        ),
        StatusItem(
          label: 'Y Range',
          value: bounds != null ? '${bounds.yMin.toStringAsFixed(1)}-${bounds.yMax.toStringAsFixed(1)}' : '-',
        ),
        StatusItem(
          label: 'Latest',
          value: _streamController?.latestPoint?.y.toStringAsFixed(1) ?? '-',
        ),
      ],
    );
  }
}
