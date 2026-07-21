// Copyright 2025 Braven Charts - Live Streaming Page
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:async';
// Only import dart:isolate on non-web platforms
import 'dart:isolate'
    if (dart.library.html) 'live_streaming_page_web_stub.dart';
import 'dart:math';
import 'dart:ui' show FramePhase;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

    pendingBatch.add(ChartDataPoint(x: pointCounter.toDouble(), y: y));
    pointCounter++;

    // Send batch when full
    if (pendingBatch.length >= batchSize) {
      mainSendPort.send(
        DataBatch(
          points: List.from(pendingBatch),
          generatedCount: pointCounter,
          timestamp: DateTime.now(),
        ),
      );
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
            mainSendPort.send(
              DataBatch(
                points: List.from(pendingBatch),
                generatedCount: pointCounter,
                timestamp: DateTime.now(),
              ),
            );
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
enum DataPattern { randomWalk, sine, sawtooth, noise, stepFunction }

enum _LiveScenario {
  followLatest,
  pausedBuffer,
  expandThenSlide,
  highFrequency,
  navigator,
}

class _NavigatorSnapshotTelemetry {
  const _NavigatorSnapshotTelemetry({
    this.sequence = 0,
    this.timestamp,
    this.duration = Duration.zero,
    this.domainMax,
  });

  final int sequence;
  final DateTime? timestamp;
  final Duration duration;
  final double? domainMax;
}

/// Demonstrates the recommended live-data workflow using LiveStreamController.
///
/// Key features:
/// - Frame-coalesced updates (max 60fps)
/// - Direct RenderBox path (no widget rebuild)
/// - Built-in pause/resume with buffering
/// - Auto-scroll that snaps to latest data
/// - Configurable buffer sizes and auto-scroll margin
///
class LiveStreamingPage extends StatefulWidget {
  const LiveStreamingPage({super.key});

  @override
  State<LiveStreamingPage> createState() => _LiveStreamingPageState();
}

class _LiveStreamingPageState extends State<LiveStreamingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final ChartInteractionGroupController _navigatorController =
      ChartInteractionGroupController();
  final ValueNotifier<int> _navigatorUiRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> _navigatorOverviewRevision = ValueNotifier<int>(0);
  final ValueNotifier<_NavigatorSnapshotTelemetry> _navigatorSnapshotTelemetry =
      ValueNotifier<_NavigatorSnapshotTelemetry>(
        const _NavigatorSnapshotTelemetry(),
      );

  _LiveScenario _selectedScenario = _LiveScenario.followLatest;

  // LiveStreamController - the recommended streaming API
  LiveStreamController? _streamController;

  // Isolate-based data generation (only available on native platforms)
  Isolate? _generatorIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _isolateReceivePort;
  int _streamGeneration = 0;
  bool _useIsolate = !kIsWeb; // Isolates not supported on web platform

  // Main-thread Timer-based generation (used by the web showcase)
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
  int _maxVisiblePoints =
      1000; // Max points before expand mode switches to sliding

  // Live navigator state. In this preset the interaction group is the sole
  // X-viewport authority while LiveStreamController continues to own ingest.
  List<ChartDataPoint> _navigatorOverviewPoints = const [];
  int _navigatorCommittedDataRevision = -1;
  bool _navigatorFrameUpdateScheduled = false;
  bool _navigatorFollowingLatest = true;
  bool _publishingLiveNavigatorViewport = false;
  double? _navigatorInspectionStartedAtX;

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
    _navigatorController.viewportListenable.addListener(
      _handleNavigatorViewportChanged,
    );

    // Create the LiveStreamController with initial configuration
    _createStreamController();

    // Initialize with some data
    _initializeData();

    // Make the public showcase feel live immediately. The page still exposes
    // explicit stop, pause, resume, and reset controls for experimentation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startStreaming();
    });
  }

  void _createStreamController() {
    // Dispose old controller if exists
    _streamController?.removeListener(_onStreamStateChanged);
    _streamController?.dataRevision.removeListener(_onStreamDataRevision);
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
      manageViewport: _selectedScenario != _LiveScenario.navigator,
    );
    _navigatorCommittedDataRevision = -1;

    // Add listener to update UI (status panel, etc.)
    _streamController!.addListener(_onStreamStateChanged);
    _streamController!.dataRevision.addListener(_onStreamDataRevision);
  }

  void _recreateController() {
    final wasStreaming = _dataTimer != null;
    _stopStreaming();

    // Preserve some data for continuity
    final oldPoints = _streamController?.points ?? [];

    _createStreamController();

    // Re-add preserved points (up to new maxPoints limit)
    final startIdx = oldPoints.length > _maxPoints
        ? oldPoints.length - _maxPoints
        : 0;
    for (var i = startIdx; i < oldPoints.length; i++) {
      _streamController!.addPoint(oldPoints[i]);
    }

    if (_selectedScenario == _LiveScenario.navigator) {
      _refreshNavigatorSnapshot(force: true);
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
    if (!mounted) return;
    if (_selectedScenario == _LiveScenario.navigator) {
      _refreshNavigatorSnapshot(force: true);
    }
    // Rebuild to update UI
    setState(() {});
  }

  void _onStreamDataRevision() {
    _scheduleNavigatorFrameUpdate();
  }

  void _scheduleNavigatorFrameUpdate() {
    if (_navigatorFrameUpdateScheduled ||
        !mounted ||
        _selectedScenario != _LiveScenario.navigator) {
      return;
    }

    _navigatorFrameUpdateScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _navigatorFrameUpdateScheduled = false;
      _refreshNavigatorSnapshot();
    });
  }

  void _publishNavigatorLiveViewport() {
    final controller = _streamController;
    if (!mounted ||
        _selectedScenario != _LiveScenario.navigator ||
        !_navigatorFollowingLatest ||
        !(controller?.isStreaming ?? false) ||
        (controller?.pointCount ?? 0) < 2) {
      return;
    }

    final oldestX = controller!.oldestPoint!.x;
    final latestX = controller.latestPoint!.x;
    final viewportMin = max(
      oldestX,
      latestX - max(1, _viewportDataPoints - 1),
    ).toDouble();
    _publishingLiveNavigatorViewport = true;
    try {
      _navigatorController.setViewport(
        ChartXViewport(min: viewportMin, max: latestX),
      );
    } finally {
      _publishingLiveNavigatorViewport = false;
    }
  }

  void _handleNavigatorViewportChanged() {
    if (!mounted ||
        _selectedScenario != _LiveScenario.navigator ||
        _publishingLiveNavigatorViewport ||
        _navigatorController.viewport == null) {
      return;
    }

    // Controller notifications also carry programmatic follow-latest writes.
    // Entering history must be driven by an explicit navigator/chart gesture,
    // not inferred from this shared state channel.
    if (_navigatorFollowingLatest) return;

    final viewport = _navigatorController.viewport!;
    final actualWindowPoints = ((viewport.max - viewport.min).abs().round() + 1)
        .clamp(10, _maxPoints)
        .toInt();
    _viewportDataPoints = actualWindowPoints;
    _notifyNavigatorUi();
  }

  void _enterNavigatorHistory() {
    if (!mounted ||
        _selectedScenario != _LiveScenario.navigator ||
        !_navigatorFollowingLatest) {
      return;
    }
    setState(() {
      _navigatorFollowingLatest = false;
      _navigatorInspectionStartedAtX = _streamController?.latestPoint?.x;
    });
  }

  void _setNavigatorDetailWindow(int value) {
    _viewportDataPoints = value;
    final current = _navigatorController.viewport;
    final points = _navigatorOverviewPoints;

    if (_navigatorFollowingLatest || current == null || points.length < 2) {
      _refreshNavigatorSnapshot(force: true);
      return;
    }

    final domainMin = points.first.x;
    final domainMax = points.last.x;
    final requestedSpan = min(value - 1.0, domainMax - domainMin);
    final center = (current.min + current.max) / 2;
    final viewportMin = (center - requestedSpan / 2).clamp(
      domainMin,
      domainMax - requestedSpan,
    );
    final viewport = ChartXViewport(
      min: viewportMin.toDouble(),
      max: (viewportMin + requestedSpan).toDouble(),
    );

    _publishingLiveNavigatorViewport = true;
    try {
      _navigatorController.setViewport(viewport);
    } finally {
      _publishingLiveNavigatorViewport = false;
    }
    _notifyNavigatorUi();
  }

  void _refreshNavigatorSnapshot({bool force = false}) {
    if (!mounted || _selectedScenario != _LiveScenario.navigator) return;
    final controller = _streamController;
    final committedRevision = controller?.committedDataRevision ?? -1;
    if (!force && committedRevision == _navigatorCommittedDataRevision) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    final points = controller?.points ?? const <ChartDataPoint>[];
    _navigatorCommittedDataRevision = committedRevision;
    _navigatorOverviewPoints = points;

    _publishNavigatorLiveViewport();
    _navigatorOverviewRevision.value++;
    stopwatch.stop();
    final previousTelemetry = _navigatorSnapshotTelemetry.value;
    _navigatorSnapshotTelemetry.value = _NavigatorSnapshotTelemetry(
      sequence: previousTelemetry.sequence + 1,
      timestamp: DateTime.now(),
      duration: stopwatch.elapsed,
      domainMax: points.isEmpty ? null : points.last.x,
    );
  }

  void _notifyNavigatorUi() {
    if (!mounted) return;
    _navigatorUiRevision.value++;
  }

  void _returnNavigatorToLive() {
    setState(() {
      _navigatorFollowingLatest = true;
      _navigatorInspectionStartedAtX = null;
    });
    _refreshNavigatorSnapshot(force: true);
  }

  void _startStreaming() async {
    if ((_useIsolate && _generatorIsolate != null) ||
        (!_useIsolate && _dataTimer != null)) {
      return;
    }

    _totalPointsGenerated = 0;
    _pointsInLastSecond = 0;
    _lastSecondStart = null;
    _lastTimerFire = null;
    _timerIntervals.clear();
    // Make sure streaming is resumed (unlocks viewport for auto-scroll)
    if (!(_streamController?.isStreaming ?? true)) {
      _streamController?.resume();
    }

    if (_useIsolate && !kIsWeb) {
      // Start isolate-based generation (native platforms only)
      print('Starting ISOLATE-based generation: $_updateRateHz Hz');

      final generation = ++_streamGeneration;
      final receivePort = ReceivePort();
      _isolateReceivePort = receivePort;
      try {
        final isolate = await Isolate.spawn(
          _dataGeneratorIsolate,
          receivePort.sendPort,
        );

        // Isolate startup is asynchronous. A preset change or page disposal
        // can supersede this request before it completes.
        if (!mounted || generation != _streamGeneration) {
          isolate.kill(priority: Isolate.immediate);
          receivePort.close();
          return;
        }

        _generatorIsolate = isolate;

        // Wait for isolate to send back its SendPort
        receivePort.listen((message) {
          if (!mounted || generation != _streamGeneration) return;
          if (message is SendPort) {
            _isolateSendPort = message;
            // Start generation
            _isolateSendPort!.send(
              IsolateControlMessage(
                command: 'start',
                rateHz: _updateRateHz,
                pattern: _dataPattern,
                amplitude: _amplitude,
                frequency: _frequency,
              ),
            );
          } else if (message is DataBatch) {
            // Receive batch from isolate
            _handleDataBatch(message);
          }
        });
      } catch (e) {
        receivePort.close();
        if (!mounted || generation != _streamGeneration) return;
        print('Failed to spawn isolate: $e');
        print('Falling back to main thread Timer');
        _useIsolate = false;
        if (mounted) setState(() {});
      }
    }

    if (!_useIsolate || kIsWeb) {
      // Start main-thread Timer-based generation
      final intervalMs = (1000 / _updateRateHz).round();
      print(
        'Starting MAIN THREAD Timer.periodic: $_updateRateHz Hz (${intervalMs}ms interval)',
      );

      _dataTimer = Timer.periodic(
        Duration(milliseconds: intervalMs),
        (_) => _generateDataPoint(),
      );
    }

    if (mounted) setState(() {});
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
    final elapsedMs = DateTime.now()
        .difference(_lastSecondStart!)
        .inMilliseconds;
    if (elapsedMs >= 1000) {
      // Reset counter every second and update UI
      _pointsInLastSecond = 0;
      _lastSecondStart = DateTime.now();
      setState(() {});
    }
  }

  void _stopStreaming({bool rebuild = true}) {
    _streamGeneration++;

    if (_useIsolate && !kIsWeb) {
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

    _lastSecondStart = null;
    _lastTimerFire = null;

    // When stopping data flow, also lock viewport so user can pan historical data
    _streamController?.pause();

    if (rebuild && mounted) setState(() {});
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
        final avg =
            _timerIntervals.reduce((a, b) => a + b) / _timerIntervals.length;
        final actualHz = 1000 / avg;
        print(
          'Timer diagnostic: requested ${_updateRateHz}Hz (${(1000 / _updateRateHz).toStringAsFixed(1)}ms), '
          'actual ${actualHz.toStringAsFixed(1)}Hz (${avg.toStringAsFixed(1)}ms avg over ${_timerIntervals.length} samples)',
        );
      }
    }
    _lastTimerFire = now;

    _generateAndAddPoint();
    _totalPointsGenerated++;

    // Track rolling rate (last second)
    _lastSecondStart ??= DateTime.now();
    _pointsInLastSecond++;
    final elapsedMs = DateTime.now()
        .difference(_lastSecondStart!)
        .inMilliseconds;
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
    _streamController?.addPoint(
      ChartDataPoint(x: _pointCounter.toDouble(), y: y),
    );
    _pointCounter++;
  }

  double _generateValue() {
    switch (_dataPattern) {
      case DataPattern.randomWalk:
        final change =
            _random.nextDouble() * _amplitude * 0.1 - _amplitude * 0.05;
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

  void _selectScenario(_LiveScenario scenario) {
    if (_selectedScenario == scenario) return;

    _stopStreaming(rebuild: false);
    _streamController?.clear();
    _navigatorController.reset();
    _navigatorOverviewPoints = const [];
    _navigatorCommittedDataRevision = -1;
    _navigatorFollowingLatest = true;
    _navigatorInspectionStartedAtX = null;
    _pointCounter = 0;
    _lastValue = 50;
    _totalPointsGenerated = 0;
    _pointsInLastSecond = 0;
    _lastSecondStart = null;

    switch (scenario) {
      case _LiveScenario.followLatest:
        _autoScroll = true;
        _maxPoints = 500;
        _viewportDataPoints = 100;
        _updateRateHz = 20;
        _dataPattern = DataPattern.randomWalk;
        _lineColor = const Color(0xFF3B82F6);
        _interpolation = LineInterpolation.monotone;
        break;
      case _LiveScenario.pausedBuffer:
        _autoScroll = true;
        _maxPoints = 500;
        _viewportDataPoints = 100;
        _pauseBufferSize = 5000;
        _updateRateHz = 20;
        _dataPattern = DataPattern.sine;
        _lineColor = const Color(0xFFF59E0B);
        _interpolation = LineInterpolation.bezier;
        break;
      case _LiveScenario.expandThenSlide:
        _autoScroll = false;
        _maxVisiblePoints = 500;
        _updateRateHz = 20;
        _dataPattern = DataPattern.sawtooth;
        _lineColor = const Color(0xFF10B981);
        _interpolation = LineInterpolation.linear;
        break;
      case _LiveScenario.highFrequency:
        _autoScroll = true;
        _maxPoints = 2000;
        _viewportDataPoints = 250;
        _updateRateHz = 120;
        _dataPattern = DataPattern.noise;
        _lineColor = const Color(0xFF8B5CF6);
        _interpolation = LineInterpolation.linear;
        break;
      case _LiveScenario.navigator:
        _autoScroll = true;
        _maxPoints = 1200;
        _viewportDataPoints = 300;
        _updateRateHz = 20;
        _dataPattern = DataPattern.sine;
        _amplitude = 24;
        _frequency = 0.065;
        _lineColor = const Color(0xFF0F766E);
        _interpolation = LineInterpolation.monotone;
        break;
    }

    _selectedScenario = scenario;
    _createStreamController();
    _initializeData();
    if (scenario == _LiveScenario.navigator) {
      _refreshNavigatorSnapshot(force: true);
    }
    _startStreaming();
    if (scenario == _LiveScenario.pausedBuffer) {
      _streamController?.pause();
    }
    setState(() {});
  }

  void _resetData() {
    _stopStreaming(rebuild: false);
    _streamController?.clear();
    _pointCounter = 0;
    _lastValue = 50.0;
    _totalPointsGenerated = 0;
    _pointsInLastSecond = 0;
    _lastSecondStart = null;
    _initializeData();
    if (_selectedScenario == _LiveScenario.navigator) {
      _navigatorController.reset();
      _navigatorFollowingLatest = true;
      _navigatorInspectionStartedAtX = null;
      _refreshNavigatorSnapshot(force: true);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _navigatorController.viewportListenable.removeListener(
      _handleNavigatorViewportChanged,
    );
    // CRITICAL: Remove listener BEFORE stopping stream to prevent setState() during dispose
    _streamController?.removeListener(_onStreamStateChanged);
    _streamController?.dataRevision.removeListener(_onStreamDataRevision);

    _stopStreaming(rebuild: false);
    _streamController?.dispose();
    _navigatorController.dispose();
    _navigatorUiRevision.dispose();
    _navigatorOverviewRevision.dispose();
    _navigatorSnapshotTelemetry.dispose();
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
      title: 'Live Stream',
      subtitle:
          'Compare real-time viewport and buffering strategies, then configure them live',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    final isDataFlowing = _useIsolate
        ? _generatorIsolate != null
        : _dataTimer != null;
    final isPaused = !(_streamController?.isStreaming ?? true);

    return [
      OptionSection(
        title: 'Streaming Strategy',
        icon: Icons.bolt,
        children: [
          EnumOption<_LiveScenario>(
            label: 'Preset',
            value: _selectedScenario,
            values: _LiveScenario.values,
            labelBuilder: _scenarioLabel,
            onChanged: _selectScenario,
          ),
        ],
      ),
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
            label: 'Reset Stream',
            icon: Icons.refresh,
            onPressed: _resetData,
          ),
        ],
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
              label: _selectedScenario == _LiveScenario.navigator
                  ? 'Retained History'
                  : 'Buffer Capacity',
              value: _maxPoints,
              min: 100,
              max: 5000,
              suffix: 'pts',
              onChanged: (v) {
                setState(() {
                  _maxPoints = v;
                  if (_viewportDataPoints > v) {
                    _viewportDataPoints = v;
                  }
                });
                _recreateController();
              },
            ),
            IntSliderOption(
              label: 'Pause Buffer',
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

      if (_selectedScenario == _LiveScenario.navigator)
        ValueListenableBuilder<int>(
          valueListenable: _navigatorUiRevision,
          builder: (context, revision, child) => OptionSection(
            title: 'Navigator Viewport',
            icon: Icons.view_week_outlined,
            children: [
              BoolOption(
                label: 'Follow Latest',
                value: _navigatorFollowingLatest,
                subtitle: _navigatorFollowingLatest
                    ? 'Detail window advances while the overview grows'
                    : 'History is fixed while new samples keep arriving',
                onChanged: (value) {
                  if (value) {
                    _returnNavigatorToLive();
                  } else {
                    _enterNavigatorHistory();
                  }
                },
              ),
              IntSliderOption(
                label: 'Detail Window',
                value: _viewportDataPoints,
                min: 10,
                max: _maxPoints,
                suffix: 'pts',
                onChanged: _setNavigatorDetailWindow,
              ),
              if (!_navigatorFollowingLatest)
                ActionButton(
                  label: 'Return to Live',
                  icon: Icons.skip_next,
                  isPrimary: true,
                  onPressed: _returnNavigatorToLive,
                ),
            ],
          ),
        )
      else
        // Auto-scroll settings
        OptionSection(
          title: 'Viewport Mode',
          icon: _autoScroll ? Icons.auto_awesome : Icons.zoom_out_map,
          children: [
            BoolOption(
              label: 'Auto-Scroll Mode',
              value: _autoScroll,
              subtitle: _autoScroll
                  ? 'Following latest data (sliding window)'
                  : 'Expand Mode: Viewport grows until $_maxVisiblePoints pts',
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

      OptionSection(
        title: 'Live diagnostics',
        icon: Icons.speed_outlined,
        children: [
          _LiveNavigatorPerformanceProbe(
            key: ValueKey('live-performance-${_selectedScenario.name}'),
            scenarioLabel: _scenarioLabel(_selectedScenario),
            snapshotTelemetry: _navigatorSnapshotTelemetry,
            liveController: _streamController,
            showNavigatorMetrics: _selectedScenario == _LiveScenario.navigator,
          ),
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
                    final wasStreaming =
                        (_useIsolate && _generatorIsolate != null) ||
                        (!_useIsolate && _dataTimer != null);
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
              final wasStreaming =
                  (_useIsolate && _generatorIsolate != null) ||
                  (!_useIsolate && _dataTimer != null);
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
          if (_dataPattern == DataPattern.sine ||
              _dataPattern == DataPattern.sawtooth)
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
      StandardChartOptions(
        controller: _optionsController,
        showMarkerOption: false,
        showLineStyleOption: false,
        showLegendOption: false,
      ),

      // Streaming API guidance
      InfoBox(
        message: _selectedScenario == _LiveScenario.navigator
            ? 'LiveStreamController keeps the direct ingest path while '
                  'ChartInteractionGroupController exclusively owns the X viewport. '
                  'Move the navigator to inspect history without pausing the stream.'
            : (isPaused
                  ? 'Chart paused. ${_streamController?.bufferedCount ?? 0} points buffered. '
                        'Click Resume to apply buffered data.'
                  : 'LiveStreamController manages the rolling window, auto-scroll, '
                        'and frame-coalesced updates without rebuilding the chart widget.'),
        type: isPaused
            ? InfoBoxType.warning
            : (isDataFlowing ? InfoBoxType.success : InfoBoxType.info),
      ),
    ];
  }

  String _scenarioLabel(_LiveScenario scenario) => switch (scenario) {
    _LiveScenario.followLatest => 'Follow latest',
    _LiveScenario.pausedBuffer => 'Paused buffer',
    _LiveScenario.expandThenSlide => 'Expand then slide',
    _LiveScenario.highFrequency => 'High frequency',
    _LiveScenario.navigator => 'Live navigator',
  };

  String _scenarioDescription(_LiveScenario scenario) => switch (scenario) {
    _LiveScenario.followLatest => 'Rolling window tracks new data',
    _LiveScenario.pausedBuffer => 'Freeze view while ingest continues',
    _LiveScenario.expandThenSlide => 'Grow viewport before scrolling',
    _LiveScenario.highFrequency => 'Frame-coalesced 120 Hz ingest',
    _LiveScenario.navigator => 'Follow live, then inspect retained history',
  };

  String _scenarioExplanation(_LiveScenario scenario) => switch (scenario) {
    _LiveScenario.followLatest =>
      'A fixed-width viewport follows the newest samples and evicts the oldest points when the rolling buffer reaches its limit.',
    _LiveScenario.pausedBuffer =>
      'The viewport freezes while incoming samples collect in a FIFO pause buffer. Resume applies them together and returns to the latest data.',
    _LiveScenario.expandThenSlide =>
      'The visible domain expands as data arrives. Once it reaches the configured maximum, older samples move off-screen without being discarded.',
    _LiveScenario.highFrequency =>
      'Rapid samples travel directly through LiveStreamController. Paints are coalesced to display frames so widget rebuilds do not become the bottleneck.',
    _LiveScenario.navigator =>
      'The detail chart follows new samples until you move the navigator or pan the chart. Ingest continues while you inspect retained history; Return to live restores the rolling viewport.',
  };

  String _scenarioApiSummary(_LiveScenario scenario) => switch (scenario) {
    _LiveScenario.followLatest =>
      'autoScroll: true  ·  viewportDataPoints: $_viewportDataPoints  ·  maxPoints: $_maxPoints',
    _LiveScenario.pausedBuffer =>
      'pause() → addPoint() buffers  ·  resume() flushes ${_streamController?.bufferedCount ?? 0} queued points',
    _LiveScenario.expandThenSlide =>
      'autoScroll: false  ·  maxVisiblePoints: $_maxVisiblePoints  ·  history retained',
    _LiveScenario.highFrequency =>
      'addPoint() at $_updateRateHz Hz  ·  direct RenderBox path  ·  frame coalescing',
    _LiveScenario.navigator =>
      'manageViewport: false  ·  ChartInteractionGroupController owns X  ·  ${_navigatorFollowingLatest ? 'following latest' : 'inspecting history'}',
  };

  Color _scenarioColor(_LiveScenario scenario) => switch (scenario) {
    _LiveScenario.followLatest => const Color(0xFF3B82F6),
    _LiveScenario.pausedBuffer => const Color(0xFFF59E0B),
    _LiveScenario.expandThenSlide => const Color(0xFF10B981),
    _LiveScenario.highFrequency => const Color(0xFF8B5CF6),
    _LiveScenario.navigator => const Color(0xFF0F766E),
  };

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = max(600.0, constraints.maxHeight - 184);
        return SingleChildScrollView(
          key: const ValueKey('streaming-workspace-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 168, child: _buildScenarioRibbon()),
              const SizedBox(height: 16),
              SizedBox(height: chartHeight, child: _buildChart()),
              const SizedBox(height: 16),
              _StreamingGuide(
                title: _scenarioLabel(_selectedScenario),
                explanation: _scenarioExplanation(_selectedScenario),
                apiSummary: _scenarioApiSummary(_selectedScenario),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScenarioRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minimumCardWidth = 168.0;
        final scenarioCount = _LiveScenario.values.length;
        final fitWidth =
            (constraints.maxWidth - spacing * (scenarioCount - 1)) /
            scenarioCount;
        final cardWidth = fitWidth >= minimumCardWidth
            ? fitWidth
            : minimumCardWidth;

        return ListView.separated(
          key: const ValueKey('streaming-scenario-ribbon'),
          scrollDirection: Axis.horizontal,
          itemCount: _LiveScenario.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final scenario = _LiveScenario.values[index];
            return SizedBox(
              width: cardWidth,
              child: _StreamingScenarioCard(
                key: ValueKey('streaming-scenario-${scenario.name}'),
                scenario: scenario,
                label: _scenarioLabel(scenario),
                description: _scenarioDescription(scenario),
                selected: _selectedScenario == scenario,
                onTap: () => _selectScenario(scenario),
                chart: _buildScenarioPreview(scenario),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScenarioPreview(_LiveScenario scenario) {
    final color = _scenarioColor(scenario);
    final points = List.generate(32, (index) {
      final x = index.toDouble();
      final y = switch (scenario) {
        _LiveScenario.followLatest =>
          48 + sin(index * 0.42) * 16 + index * 0.45,
        _LiveScenario.pausedBuffer => 50 + sin(index * 0.38) * 22,
        _LiveScenario.expandThenSlide => 28 + (index % 9) * 4.5 + index * 0.55,
        _LiveScenario.highFrequency =>
          50 + sin(index * 1.85) * 17 + sin(index * 0.31) * 8,
        _LiveScenario.navigator =>
          48 + sin(index * 0.38) * 18 + sin(index * 0.11) * 7,
      };
      return ChartDataPoint(x: x, y: y);
    });

    return BravenChartPlus(
      series: [
        LineChartSeries(
          id: 'preview-${scenario.name}',
          name: _scenarioLabel(scenario),
          points: points,
          color: color,
          interpolation: scenario == _LiveScenario.highFrequency
              ? LineInterpolation.linear
              : LineInterpolation.monotone,
          strokeWidth: 2,
          showDataPointMarkers: scenario == _LiveScenario.pausedBuffer,
          dataPointMarkerRadius: 1.8,
        ),
      ],
      showLegend: false,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: const XAxisConfig(
        visible: false,
        minHeight: 0,
        maxHeight: 0,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.hidden,
        minWidth: 0,
        maxWidth: 0,
      ),
      interactionConfig: InteractionConfig.none(),
    );
  }

  Widget _buildChart() {
    final isDataFlowing = _useIsolate
        ? _generatorIsolate != null
        : _dataTimer != null;
    final isPaused = !(_streamController?.isStreaming ?? true);

    // Determine line color based on state
    final effectiveColor = isPaused
        ? Colors.orange
        : (isDataFlowing ? _lineColor : _lineColor.withValues(alpha: 0.7));
    final showsNavigator = _selectedScenario == _LiveScenario.navigator;

    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: showsNavigator ? 'Live Navigator' : 'Live Data Stream',
          subtitle: showsNavigator
              ? (_navigatorFollowingLatest
                    ? 'Following the latest samples'
                    : 'Inspecting retained history while ingest continues')
              : (isPaused
                    ? 'Paused (buffering...)'
                    : (isDataFlowing
                          ? 'Streaming at $_updateRateHz Hz'
                          : 'Stopped')),
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
                color: isPaused
                    ? Colors.orange
                    : (isDataFlowing ? Colors.green : Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaused
                        ? Icons.pause
                        : (isDataFlowing
                              ? Icons.fiber_manual_record
                              : Icons.stop),
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
            if (showsNavigator) ...[
              const SizedBox(width: 8),
              Container(
                key: const ValueKey('live-navigator-mode-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _navigatorFollowingLatest
                      ? const Color(0xFF0F766E)
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _navigatorFollowingLatest ? 'FOLLOWING' : 'HISTORY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _navigatorFollowingLatest
                        ? Colors.white
                        : Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
          child: Column(
            children: [
              if (showsNavigator)
                ValueListenableBuilder<int>(
                  valueListenable: _navigatorUiRevision,
                  builder: (context, revision, child) => _buildTelemetryBar(
                    isDataFlowing: isDataFlowing,
                    isPaused: isPaused,
                  ),
                )
              else
                _buildTelemetryBar(
                  isDataFlowing: isDataFlowing,
                  isPaused: isPaused,
                ),
              const Divider(height: 1),
              Expanded(
                child: Listener(
                  onPointerSignal: (_) => _enterNavigatorHistory(),
                  onPointerMove: (event) {
                    if (event.buttons != 0) _enterNavigatorHistory();
                  },
                  child: BravenChartPlus(
                    key: const ValueKey('live-stream-main-chart'),
                    interactionGroupController: showsNavigator
                        ? _navigatorController
                        : null,
                    // Series defines styling, LiveStreamController provides data
                    series: [
                      LineChartSeries(
                        id: 'live-data',
                        name: 'Live Data',
                        points: const [],
                        color: effectiveColor,
                        interpolation: _interpolation,
                        strokeWidth: _strokeWidth,
                        showDataPointMarkers:
                            _optionsController.showDataMarkers,
                      ),
                    ],
                    // LiveStreamController always owns high-frequency ingest.
                    // The interaction group owns only the X viewport in the
                    // dedicated navigator strategy.
                    liveStreamController: _streamController,
                    theme: _optionsController.theme,
                    showLegend: false,
                    showXScrollbar:
                        !showsNavigator && _optionsController.showXScrollbar,
                    showYScrollbar: _optionsController.showYScrollbar,
                    scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
                      autoHide: false,
                    ),
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
                    ),
                  ),
                ),
              ),
              if (showsNavigator)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    _buildLiveNavigatorModeBar(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: SizedBox(
                        height: 88,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _navigatorOverviewRevision,
                          builder: (context, revision, child) =>
                              _buildLiveNavigator(),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveNavigator() {
    final points = _navigatorOverviewPoints;
    final domainMin = points.isEmpty ? 0.0 : points.first.x;
    final rawDomainMax = points.isEmpty ? 1.0 : points.last.x;
    final domainMax = rawDomainMax > domainMin ? rawDomainMax : domainMin + 1;
    final initialMax = min(
      domainMax,
      domainMin + max(1, _viewportDataPoints - 1),
    ).toDouble();
    final chartTheme = _optionsController.theme ?? ChartTheme.light;

    return CartesianNavigator(
      key: const ValueKey('live-stream-cartesian-navigator'),
      interactionGroupController: _navigatorController,
      overviewSeries: AreaChartSeries(
        id: 'live-navigator-overview',
        name: 'Retained live history',
        points: points,
        color: const Color(0xFF0F766E),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.5,
        fillOpacity: 0.22,
        showDataPointMarkers: false,
      ),
      fullDomain: ChartXViewport(min: domainMin, max: domainMax),
      initialViewport: ChartXViewport(min: domainMin, max: initialMax),
      behavior: const CartesianNavigatorBehavior(
        minimumSpan: 9,
        allowExternalDomainGrowth: true,
      ),
      snapPolicy: CartesianNavigatorSnapPolicy.interval(1),
      theme: chartTheme,
      height: 88,
      semanticLabel: 'Retained live stream viewport',
      onViewportPreview: (_) => _enterNavigatorHistory(),
    );
  }

  Widget _buildLiveNavigatorModeBar() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final latestX = _streamController?.latestPoint?.x;
    final unseenSamples =
        !_navigatorFollowingLatest &&
            latestX != null &&
            _navigatorInspectionStartedAtX != null
        ? max(0, latestX - _navigatorInspectionStartedAtX!).round()
        : 0;

    return Container(
      key: const ValueKey('live-navigator-mode-bar'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            _navigatorFollowingLatest
                ? Icons.play_circle_outline
                : Icons.history,
            size: 20,
            color: _navigatorFollowingLatest
                ? const Color(0xFF0F766E)
                : colors.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _navigatorFollowingLatest
                      ? 'Following live viewport'
                      : 'Inspecting history',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _navigatorFollowingLatest
                      ? 'Drag the window below to inspect retained samples.'
                      : '$unseenSamples new samples arrived without moving this view.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!_navigatorFollowingLatest) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.tonalIcon(
                key: const ValueKey('live-navigator-return-to-live'),
                onPressed: _returnNavigatorToLive,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Return to live'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryBar({
    required bool isDataFlowing,
    required bool isPaused,
  }) {
    String effectiveRate = '$_updateRateHz Hz';
    if (isDataFlowing && _lastSecondStart != null) {
      final elapsedInSecond = DateTime.now()
          .difference(_lastSecondStart!)
          .inMilliseconds;
      if (elapsedInSecond > 100) {
        // Wait at least 100ms for stable measurement
        final instantRate = (_pointsInLastSecond / (elapsedInSecond / 1000))
            .toStringAsFixed(1);
        effectiveRate = '$instantRate Hz';
      }
    }

    final metrics = <(String, String, Color?)>[
      (
        'State',
        isPaused ? 'Paused' : (isDataFlowing ? 'Live' : 'Stopped'),
        isPaused ? Colors.orange : (isDataFlowing ? Colors.green : Colors.grey),
      ),
      ('Points', '${_streamController?.pointCount ?? 0}', null),
      (
        'Buffered',
        '${_streamController?.bufferedCount ?? 0}',
        (_streamController?.bufferedCount ?? 0) > 0 ? Colors.orange : null,
      ),
      ('Rate', effectiveRate, null),
      (
        'Latest',
        _streamController?.latestPoint?.y.toStringAsFixed(1) ?? '—',
        null,
      ),
    ];

    return Container(
      key: const ValueKey('live-stream-telemetry'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0)
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Theme.of(context).dividerColor,
              ),
            Expanded(
              child: _TelemetryMetric(
                label: metrics[index].$1,
                value: metrics[index].$2,
                color: metrics[index].$3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StreamingGuide extends StatelessWidget {
  const _StreamingGuide({
    required this.title,
    required this.explanation,
    required this.apiSummary,
  });

  final String title;
  final String explanation;
  final String apiSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey('streaming-strategy-guide'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanationBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final apiBlock = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 17, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    apiSummary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                explanationBlock,
                const SizedBox(height: 10),
                apiBlock,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: explanationBlock),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: apiBlock),
            ],
          );
        },
      ),
    );
  }
}

/// Rolling, device-local timings for the dedicated live-navigator scenario.
///
/// This widget owns its state so refreshing the diagnostics cannot rebuild the
/// chart, navigator, scenario ribbon, or options page around it.
class _LiveNavigatorPerformanceProbe extends StatefulWidget {
  const _LiveNavigatorPerformanceProbe({
    super.key,
    required this.scenarioLabel,
    required this.snapshotTelemetry,
    required this.liveController,
    required this.showNavigatorMetrics,
  });

  final String scenarioLabel;
  final ValueListenable<_NavigatorSnapshotTelemetry> snapshotTelemetry;
  final LiveStreamController? liveController;
  final bool showNavigatorMetrics;

  @override
  State<_LiveNavigatorPerformanceProbe> createState() =>
      _LiveNavigatorPerformanceProbeState();
}

class _LiveNavigatorPerformanceProbeState
    extends State<_LiveNavigatorPerformanceProbe> {
  static const _frameBudget = Duration(microseconds: 16667);
  static const _maxSamples = 180;
  static const _metricsRefreshInterval = Duration(milliseconds: 500);

  final List<FrameTiming> _frameTimings = [];
  final List<Duration> _snapshotDurations = [];
  final List<DateTime> _navigatorUpdateTimes = [];
  DateTime _lastMetricsRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    widget.snapshotTelemetry.addListener(_onSnapshotTelemetry);
    widget.liveController?.dataRevision.addListener(_onLiveDataRevision);
  }

  @override
  void didUpdateWidget(_LiveNavigatorPerformanceProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshotTelemetry != widget.snapshotTelemetry) {
      oldWidget.snapshotTelemetry.removeListener(_onSnapshotTelemetry);
      widget.snapshotTelemetry.addListener(_onSnapshotTelemetry);
    }
    if (oldWidget.liveController != widget.liveController) {
      oldWidget.liveController?.dataRevision.removeListener(
        _onLiveDataRevision,
      );
      widget.liveController?.dataRevision.addListener(_onLiveDataRevision);
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;
    _frameTimings.addAll(timings);
    _trimSamples(_frameTimings);
    _refreshMetricsIfDue();
  }

  void _onSnapshotTelemetry() {
    if (!mounted) return;
    final telemetry = widget.snapshotTelemetry.value;
    if (telemetry.timestamp == null) return;
    _snapshotDurations.add(telemetry.duration);
    _trimSamples(_snapshotDurations);
    _navigatorUpdateTimes.add(telemetry.timestamp!);
    _trimSamples(_navigatorUpdateTimes);
    _refreshMetricsIfDue();
  }

  void _onLiveDataRevision() {
    if (!mounted || !widget.showNavigatorMetrics) return;
    _refreshMetricsIfDue();
  }

  void _trimSamples<T>(List<T> samples) {
    if (samples.length <= _maxSamples) return;
    samples.removeRange(0, samples.length - _maxSamples);
  }

  void _refreshMetricsIfDue() {
    final now = DateTime.now();
    if (now.difference(_lastMetricsRefresh) < _metricsRefreshInterval) return;
    _lastMetricsRefresh = now;
    setState(() {});
  }

  void _resetMetrics() {
    setState(() {
      _frameTimings.clear();
      _snapshotDurations.clear();
      _navigatorUpdateTimes.clear();
      _lastMetricsRefresh = DateTime.now();
    });
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    widget.snapshotTelemetry.removeListener(_onSnapshotTelemetry);
    widget.liveController?.dataRevision.removeListener(_onLiveDataRevision);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final frameP95 = _percentileMs(
      _frameTimings.map((timing) => timing.totalSpan),
      0.95,
    );
    final buildP95 = _percentileMs(
      _frameTimings.map((timing) => timing.buildDuration),
      0.95,
    );
    final rasterP95 = _percentileMs(
      _frameTimings.map((timing) => timing.rasterDuration),
      0.95,
    );
    final frameGaps = _frameGaps();
    final frameGapP95 = _percentileMs(frameGaps, 0.95);
    final presentedFps = _presentedFramesPerSecond();
    final snapshotP95 = _percentileMs(_snapshotDurations, 0.95);
    final navigatorGaps = _navigatorUpdateGaps();
    final navigatorGapP95 = _percentileMs(navigatorGaps, 0.95);
    final navigatorUpdatesPerSecond = _navigatorUpdatesPerSecond();
    final navigatorDomainLag = _navigatorDomainLag();
    final worstFrame = _frameTimings.isEmpty
        ? null
        : _frameTimings
                  .map((timing) => timing.totalSpan.inMicroseconds)
                  .reduce(max) /
              1000;
    final slowFrames = _frameTimings
        .where((timing) => timing.totalSpan > _frameBudget)
        .length;
    final jankPercent = _frameTimings.isEmpty
        ? null
        : slowFrames / _frameTimings.length * 100;
    final frameStatus = _timingStatusColor(colors, frameP95);
    final cadenceStatus = _cadenceStatusColor(colors, frameGapP95);
    final fpsStatus = _fpsStatusColor(colors, presentedFps);
    final jankStatus = jankPercent == null
        ? colors.onSurface
        : jankPercent == 0
        ? Colors.green.shade700
        : jankPercent < 5
        ? Colors.orange.shade800
        : colors.error;

    return Semantics(
      container: true,
      label: 'Live navigator rolling performance diagnostics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.scenarioLabel} · rolling ${_frameTimings.length}/$_maxSamples frames on this browser and build.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('reset-live-navigator-performance'),
                tooltip: 'Reset performance samples',
                onPressed: _resetMetrics,
                icon: const Icon(Icons.restart_alt, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = max(96.0, (constraints.maxWidth - 8) / 2);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LiveDiagnosticMetric(
                    key: const ValueKey('live-navigator-frame-p95'),
                    width: metricWidth,
                    label: 'Frame p95',
                    value: _formatMilliseconds(frameP95),
                    color: frameStatus,
                  ),
                  _LiveDiagnosticMetric(
                    width: metricWidth,
                    label: 'Worst frame',
                    value: _formatMilliseconds(worstFrame),
                    color: _timingStatusColor(colors, worstFrame),
                  ),
                  _LiveDiagnosticMetric(
                    key: const ValueKey('live-presented-fps'),
                    width: metricWidth,
                    label: 'Presented FPS',
                    value: presentedFps == null
                        ? '—'
                        : presentedFps.toStringAsFixed(1),
                    color: fpsStatus,
                  ),
                  _LiveDiagnosticMetric(
                    key: const ValueKey('live-frame-gap-p95'),
                    width: metricWidth,
                    label: 'Frame gap p95',
                    value: _formatMilliseconds(frameGapP95),
                    color: cadenceStatus,
                  ),
                  _LiveDiagnosticMetric(
                    width: metricWidth,
                    label: 'Build p95',
                    value: _formatMilliseconds(buildP95),
                  ),
                  _LiveDiagnosticMetric(
                    width: metricWidth,
                    label: 'Raster p95',
                    value: _formatMilliseconds(rasterP95),
                  ),
                  _LiveDiagnosticMetric(
                    key: const ValueKey('live-navigator-jank'),
                    width: metricWidth,
                    label: 'Jank >16.7ms',
                    value: jankPercent == null
                        ? '—'
                        : '${jankPercent.toStringAsFixed(0)}%',
                    color: jankStatus,
                  ),
                  _LiveDiagnosticMetric(
                    key: const ValueKey('live-navigator-snapshot-p95'),
                    width: metricWidth,
                    label: 'Snapshot p95',
                    value: _formatMilliseconds(snapshotP95),
                  ),
                  if (widget.showNavigatorMetrics) ...[
                    _LiveDiagnosticMetric(
                      key: const ValueKey('live-navigator-update-hz'),
                      width: metricWidth,
                      label: 'Navigator updates',
                      value: navigatorUpdatesPerSecond == null
                          ? '—'
                          : '${navigatorUpdatesPerSecond.toStringAsFixed(1)} Hz',
                      color: _fpsStatusColor(colors, navigatorUpdatesPerSecond),
                    ),
                    _LiveDiagnosticMetric(
                      key: const ValueKey('live-navigator-gap-p95'),
                      width: metricWidth,
                      label: 'Navigator gap p95',
                      value: _formatMilliseconds(navigatorGapP95),
                      color: _cadenceStatusColor(colors, navigatorGapP95),
                    ),
                    _LiveDiagnosticMetric(
                      key: const ValueKey('live-navigator-domain-lag'),
                      width: metricWidth,
                      label: 'Navigator domain lag',
                      value: navigatorDomainLag == null
                          ? '—'
                          : '${navigatorDomainLag.toStringAsFixed(0)} pts',
                      color: _domainLagStatusColor(colors, navigatorDomainLag),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.showNavigatorMetrics
                ? 'Frame metrics cover the browser pipeline. Navigator updates and gap measure bottom-overview presentation cadence; domain lag is how far its snapshot trails live data.'
                : 'Frame measures work after rendering starts; frame gap and FPS expose slow presentation cadence.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  double? _percentileMs(Iterable<Duration> durations, double percentile) {
    final values = durations.map((duration) => duration.inMicroseconds).toList()
      ..sort();
    if (values.isEmpty) return null;
    final index = ((values.length - 1) * percentile).ceil();
    return values[index] / 1000;
  }

  List<Duration> _frameGaps() {
    if (_frameTimings.length < 2) return const [];
    final gaps = <Duration>[];
    for (var index = 1; index < _frameTimings.length; index++) {
      final previous = _frameTimings[index - 1].timestampInMicroseconds(
        FramePhase.vsyncStart,
      );
      final current = _frameTimings[index].timestampInMicroseconds(
        FramePhase.vsyncStart,
      );
      final gap = current - previous;
      if (gap > 0) gaps.add(Duration(microseconds: gap));
    }
    return gaps;
  }

  double? _presentedFramesPerSecond() {
    if (_frameTimings.length < 2) return null;
    final first = _frameTimings.first.timestampInMicroseconds(
      FramePhase.vsyncStart,
    );
    final last = _frameTimings.last.timestampInMicroseconds(
      FramePhase.vsyncStart,
    );
    final elapsedMicroseconds = last - first;
    if (elapsedMicroseconds <= 0) return null;
    return (_frameTimings.length - 1) * 1000000 / elapsedMicroseconds;
  }

  List<Duration> _navigatorUpdateGaps() {
    if (_navigatorUpdateTimes.length < 2) return const [];
    final gaps = <Duration>[];
    for (var index = 1; index < _navigatorUpdateTimes.length; index++) {
      final gap = _navigatorUpdateTimes[index].difference(
        _navigatorUpdateTimes[index - 1],
      );
      if (!gap.isNegative && gap > Duration.zero) gaps.add(gap);
    }
    return gaps;
  }

  double? _navigatorUpdatesPerSecond() {
    if (_navigatorUpdateTimes.length < 2) return null;
    final elapsed = _navigatorUpdateTimes.last.difference(
      _navigatorUpdateTimes.first,
    );
    if (elapsed <= Duration.zero) return null;
    return (_navigatorUpdateTimes.length - 1) *
        Duration.microsecondsPerSecond /
        elapsed.inMicroseconds;
  }

  double? _navigatorDomainLag() {
    final latestX = widget.liveController?.latestPoint?.x;
    final snapshotMax = widget.snapshotTelemetry.value.domainMax;
    if (latestX == null || snapshotMax == null) return null;
    return max(0, latestX - snapshotMax).toDouble();
  }

  String _formatMilliseconds(double? value) {
    if (value == null) return '—';
    if (value < 0.1) return '<0.1ms';
    return '${value.toStringAsFixed(1)}ms';
  }

  Color _timingStatusColor(ColorScheme colors, double? milliseconds) {
    if (milliseconds == null) return colors.onSurface;
    if (milliseconds <= 16.667) return Colors.green.shade700;
    if (milliseconds <= 33.334) return Colors.orange.shade800;
    return colors.error;
  }

  Color _cadenceStatusColor(ColorScheme colors, double? milliseconds) {
    if (milliseconds == null) return colors.onSurface;
    if (milliseconds <= 20) return Colors.green.shade700;
    if (milliseconds <= 40) return Colors.orange.shade800;
    return colors.error;
  }

  Color _fpsStatusColor(ColorScheme colors, double? fps) {
    if (fps == null) return colors.onSurface;
    if (fps >= 55) return Colors.green.shade700;
    if (fps >= 30) return Colors.orange.shade800;
    return colors.error;
  }

  Color _domainLagStatusColor(ColorScheme colors, double? lag) {
    if (lag == null) return colors.onSurface;
    if (lag <= 2) return Colors.green.shade700;
    if (lag <= 10) return Colors.orange.shade800;
    return colors.error;
  }
}

class _LiveDiagnosticMetric extends StatelessWidget {
  const _LiveDiagnosticMetric({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    this.color,
  });

  final double width;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamingScenarioCard extends StatelessWidget {
  const _StreamingScenarioCard({
    super.key,
    required this.scenario,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _LiveScenario scenario;
  final String label;
  final String description;
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
      label: 'Select $label streaming strategy',
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-streaming-${scenario.name}'),
                        size: 17,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: IgnorePointer(child: chart)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  const _TelemetryMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = color ?? theme.colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
