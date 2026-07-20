// Copyright (c) 2025 braven_charts. All rights reserved.
// High-Performance Live Streaming Controller

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/chart_data_point.dart';
import '../models/candlestick_data_point.dart';
import '../rendering/chart_render_box.dart';
import '../utils/data_converter.dart';
import 'buffer_manager.dart';
import 'streaming_buffer.dart';

enum CandlestickUpsertResult { appended, revised, rejectedOlder }

/// High-performance controller for live streaming data to charts.
///
/// **Purpose**: Provides the recommended way to stream high-frequency data
/// (50Hz+) to BravenChartPlus with optimal performance.
///
/// **Key Features**:
/// - Frame-coalesced updates (batches all points within a frame)
/// - Direct RenderBox path (bypasses widget rebuild)
/// - Built-in pause/resume with automatic buffering
/// - Auto-scroll that snaps to latest data
/// - Sliding window with O(1) bounds tracking
///
/// **Usage**:
/// ```dart
/// // Create controller
/// final controller = LiveStreamController(
///   maxPoints: 500,     // Keep last 500 points
///   autoScroll: true,   // Follow latest data
///   seriesId: 'sensor', // Match series ID in chart
/// );
///
/// // Add data (from sensor, WebSocket, etc.)
/// sensorStream.listen((reading) {
///   controller.addPoint(ChartDataPoint(x: reading.time, y: reading.value));
/// });
///
/// // Control streaming
/// controller.pause();   // Freeze viewport, buffer incoming
/// controller.resume();  // Apply buffered, snap to latest
///
/// // Use in widget
/// BravenChartPlus(
///   liveStreamController: controller,
///   series: [LineChartSeries(id: 'sensor', points: [])],
/// )
/// ```
///
/// **Performance Characteristics**:
/// - `addPoint()`: O(1), no widget rebuild
/// - Paint: Once per frame max (60fps ceiling)
/// - Memory: Fixed at `maxPoints * sizeof(ChartDataPoint)`
/// - Pause buffer: FIFO with `pauseBufferSize` limit
///
/// **Comparison with Alternatives**:
/// - `controller.addPoint()`: Triggers widget rebuild per point (slow)
/// - `widget.series`: Requires parent rebuild per update (slow)
/// - `LiveStreamController`: Direct render path, frame-coalesced (fast)
class LiveStreamController extends ChangeNotifier {
  /// Creates a live stream controller with the specified configuration.
  ///
  /// **Parameters**:
  /// - [seriesId]: ID of the series to stream data to. Must match a
  ///   series ID in the chart's series list.
  /// - [maxPoints]: Maximum points to retain in sliding window.
  ///   Older points are automatically evicted. Default: 1000.
  /// - [autoScroll]: Whether to automatically scroll to show latest data.
  ///   When true, viewport snaps to latest on each frame. Default: true.
  /// - [autoScrollMarginPercent]: Percentage of visible X range to keep as
  ///   margin on the right side when auto-scrolling. Default: 5%.
  /// - [viewportDataPoints]: Number of data points to show in viewport during
  ///   auto-scroll. If null, shows all accumulated data. Default: null.
  /// - [maxVisiblePoints]: Maximum points to show in viewport when autoScroll
  ///   is false (expand mode). When exceeded, viewport switches to sliding
  ///   window behavior. User can still pan back to see older data. Default: 10000.
  /// - [pauseBufferSize]: Maximum points to buffer while paused.
  ///   Older buffered points are discarded (FIFO). Default: 10000.
  /// - [manageViewport]: Whether this controller owns the chart's X viewport.
  ///   Set this to false when a `ChartInteractionGroupController` or
  ///   `CartesianNavigator` is the viewport authority. Default: true.
  ///
  /// **Example**:
  /// ```dart
  /// final controller = LiveStreamController(
  ///   seriesId: 'temperature',
  ///   maxPoints: 500,          // 500 point window
  ///   autoScroll: true,        // Follow latest
  ///   viewportDataPoints: 100, // Show last 100 points
  ///   pauseBufferSize: 5000,   // Buffer up to 5000 when paused
  /// );
  /// ```
  LiveStreamController({
    required this.seriesId,
    this.maxPoints = 1000,
    this.autoScroll = true,
    this.autoScrollMarginPercent = 5.0,
    this.viewportDataPoints,
    this.maxVisiblePoints = 10000,
    this.pauseBufferSize = 10000,
    this.manageViewport = true,
  }) : assert(maxPoints > 0, 'maxPoints must be positive'),
       assert(
         autoScrollMarginPercent >= 0 && autoScrollMarginPercent <= 50,
         'autoScrollMarginPercent must be between 0 and 50',
       ),
       assert(
         viewportDataPoints == null || viewportDataPoints > 0,
         'viewportDataPoints must be positive if specified',
       ),
       assert(maxVisiblePoints > 0, 'maxVisiblePoints must be positive'),
       assert(pauseBufferSize > 0, 'pauseBufferSize must be positive'),
       _streamingBuffer = StreamingBuffer(maxSize: maxPoints),
       _pauseBuffer = BufferManager<ChartDataPoint>(maxSize: pauseBufferSize);

  // ============================================================================
  // Configuration (Immutable)
  // ============================================================================

  /// ID of the series to stream data to.
  ///
  /// Must match a series ID in the chart's series list.
  /// The streaming data will be appended to this series.
  final String seriesId;

  /// Maximum number of points to retain in the sliding window.
  ///
  /// When this limit is reached, the oldest points are automatically
  /// evicted as new points are added.
  final int maxPoints;

  /// Whether to automatically scroll the viewport to show latest data.
  ///
  /// When true:
  /// - Viewport snaps to show latest data on each frame
  /// - User cannot pan during streaming (would be immediately overridden)
  ///
  /// When false:
  /// - Viewport remains fixed (user-controlled)
  /// - New data may scroll off the visible area
  final bool autoScroll;

  /// Percentage of visible X range to keep as margin when auto-scrolling.
  ///
  /// For example, 5.0 means 5% margin on the right side, so the latest
  /// data point appears at 95% of the visible width.
  final double autoScrollMarginPercent;

  /// Number of data points to show in viewport during auto-scroll.
  ///
  /// When set:
  /// - Viewport width is fixed to show this many points
  /// - Chart maintains a consistent "zoom level" as data accumulates
  ///
  /// When null:
  /// - Viewport expands to show all accumulated data (default behavior)
  /// - Chart gradually "zooms out" as buffer fills
  ///
  /// **Example**: Set to 100 to always show the last 100 points.
  final int? viewportDataPoints;

  /// Maximum points to show in viewport when autoScroll is false (expand mode).
  ///
  /// When the buffer exceeds this limit:
  /// - Viewport switches from expand mode to sliding window behavior
  /// - Oldest points scroll off the left edge (but remain in buffer)
  /// - User can still pan left to see historical data
  ///
  /// This prevents performance degradation when streaming large datasets
  /// in expand mode. Set higher for more visible history, lower for better
  /// performance.
  ///
  /// **Default**: 10000 points.
  final int maxVisiblePoints;

  /// Maximum points to buffer while streaming is paused.
  ///
  /// When paused, incoming points are buffered instead of displayed.
  /// When buffer is full, oldest buffered points are discarded (FIFO).
  final int pauseBufferSize;

  /// Whether live ingestion also controls the chart's X viewport.
  ///
  /// The default preserves the standard follow-latest or expand-then-slide
  /// behavior. Set this to false when the chart is attached to a caller-owned
  /// `ChartInteractionGroupController`, for example when a
  /// `CartesianNavigator` must remain the sole viewport authority. Streaming
  /// data still uses the direct, frame-coalesced render path.
  final bool manageViewport;

  // ============================================================================
  // Internal State
  // ============================================================================

  /// Circular buffer for streaming data (sliding window).
  final StreamingBuffer _streamingBuffer;

  /// FIFO buffer for data received while paused.
  final BufferManager<ChartDataPoint> _pauseBuffer;

  /// Points pending flush to RenderBox (accumulated within current frame).
  final List<ChartDataPoint> _pendingPoints = [];

  /// Whether a frame callback is scheduled.
  bool _frameCallbackScheduled = false;

  /// Whether streaming is active (not paused).
  bool _isStreaming = true;

  /// Attached RenderBox for direct data injection.
  ChartRenderBox? _renderBox;

  /// Whether this controller has been disposed.
  bool _isDisposed = false;

  /// Internal notification of effective stream data mutations.
  final ValueNotifier<int> _effectiveDataRevision = ValueNotifier(0);

  /// Frame rate tracking for diagnostics.
  int _frameCount = 0;
  DateTime? _frameCountStartTime;

  // ============================================================================
  // Public State
  // ============================================================================

  /// Whether streaming is currently active.
  ///
  /// When true, new points are immediately added to the chart.
  /// When false (paused), new points are buffered for later.
  bool get isStreaming => _isStreaming;

  /// Measured frame rate (frames per second) over the last second.
  /// Returns 0 if no frames have been rendered yet.
  double get measuredFrameRate {
    if (_frameCountStartTime == null || _frameCount == 0) return 0;
    final elapsed = DateTime.now()
        .difference(_frameCountStartTime!)
        .inMilliseconds;
    if (elapsed < 100) return 0; // Need at least 100ms of data
    return _frameCount / (elapsed / 1000);
  }

  /// Number of points currently in the streaming buffer.
  int get pointCount => _streamingBuffer.length;

  /// Number of points buffered while paused.
  ///
  /// Returns 0 when streaming is active.
  int get bufferedCount => _pauseBuffer.length;

  /// Data bounds of all points in the streaming buffer.
  DataBounds get bounds => _streamingBuffer.bounds;

  /// Whether the controller is attached to a RenderBox.
  bool get isAttached => _renderBox != null;

  /// The most recently added point, or null if empty.
  ChartDataPoint? get latestPoint => _streamingBuffer.latest;

  /// The oldest retained point, or null if empty.
  ///
  /// This is an O(1) view of the active streaming buffer and does not allocate
  /// the chronological snapshot returned by [points].
  ChartDataPoint? get oldestPoint => _streamingBuffer.oldest;

  /// All points currently in the streaming buffer.
  ///
  /// Returns points in chronological order (oldest to newest).
  /// Use this for debugging or export, not for high-frequency access.
  List<ChartDataPoint> get points => _streamingBuffer.toList();

  /// Points waiting in the pause buffer, in logical FIFO order.
  ///
  /// Snapshot consumers use this alongside [points] to preserve every point
  /// currently owned by the live controller without mutating pause state.
  List<ChartDataPoint> get pendingPoints => _pauseBuffer.toList();

  /// Revision of points committed to the chart's streaming buffer.
  int get committedDataRevision => _streamingBuffer.version;

  /// Revision of points waiting in the pause buffer.
  int get pendingDataRevision => _pauseBuffer.version;

  /// Notifies listeners whenever effective live data changes.
  ///
  /// The integer value is a monotonic invalidation token. Hosts that own an
  /// external viewport can listen for changes and coalesce follow-latest work
  /// to display frames without copying [points] at ingestion frequency.
  /// Reading [oldestPoint], [latestPoint], and [pointCount] from that callback
  /// is O(1). The signal includes both committed and paused-buffer mutations.
  ValueListenable<int> get dataRevision => _effectiveDataRevision;

  /// Effective-data mutation signal used by chart extraction.
  ///
  /// This signal is internal. Applications should observe
  /// `BravenChartController.effectiveDocumentRevision` instead.
  @internal
  ValueListenable<int> get effectiveDataRevision => _effectiveDataRevision;

  // ============================================================================
  // Data Input
  // ============================================================================

  /// Adds a single data point to the stream.
  ///
  /// If streaming is active, the point is added to the visible chart.
  /// If paused, the point is buffered for later.
  ///
  /// **Performance**: O(1), does not trigger widget rebuild.
  ///
  /// **Example**:
  /// ```dart
  /// controller.addPoint(ChartDataPoint(
  ///   x: DateTime.now().millisecondsSinceEpoch.toDouble(),
  ///   y: sensorReading,
  /// ));
  /// ```
  // Debug: Track addPoint call rate
  int _addPointCallCount = 0;
  DateTime? _addPointTrackingStart;

  void addPoint(ChartDataPoint point) {
    if (_isDisposed) return;

    // Debug: Track how often addPoint is called
    _addPointCallCount++;
    _addPointTrackingStart ??= DateTime.now();
    if (_addPointCallCount % 100 == 0) {
      // final elapsed = DateTime.now().difference(_addPointTrackingStart!).inMilliseconds;
      // final rate = _addPointCallCount / (elapsed / 1000);
      // Performance monitoring (disabled in production):
      // print('[LiveStreamController.addPoint] Called $rate Hz ($_addPointCallCount calls in ${elapsed}ms)');
      _addPointCallCount = 0;
      _addPointTrackingStart = DateTime.now();
    }

    // PERFORMANCE FIX: Process data immediately, don't wait for frame callback
    // Frame callback is only for rendering optimization, not data accumulation
    if (_isStreaming) {
      // Streaming: add to buffer immediately
      _streamingBuffer.add(point);
      _effectiveDataRevision.value++;
      // Schedule render update (frame-coalesced)
      _scheduleFrameCallback();
    } else {
      // Paused: buffer for later
      _pauseBuffer.add(point);
      _effectiveDataRevision.value++;
      // Notify listeners so UI can show buffer count (no frame needed)
      notifyListeners();
    }
  }

  /// Appends a new candle or revises the latest candle with the same X value.
  ///
  /// Older X values are rejected so the X-ordered candlestick contract stays
  /// valid. The active revision path is O(1) and remains frame-coalesced.
  CandlestickUpsertResult upsertLatestCandlestick(CandlestickDataPoint point) {
    if (_isDisposed) return CandlestickUpsertResult.rejectedOlder;
    final latest = _isStreaming
        ? _streamingBuffer.latest
        : _pauseBuffer.latest ?? _streamingBuffer.latest;
    if (latest != null && point.x < latest.x) {
      return CandlestickUpsertResult.rejectedOlder;
    }
    final revisesLatest = latest != null && point.x == latest.x;
    if (_isStreaming) {
      if (revisesLatest) {
        _streamingBuffer.replaceLatest(point);
      } else {
        _streamingBuffer.add(point);
      }
      _effectiveDataRevision.value++;
      _scheduleFrameCallback();
    } else {
      if (revisesLatest && _pauseBuffer.isNotEmpty) {
        _pauseBuffer.replaceLatest(point);
      } else {
        _pauseBuffer.add(point);
      }
      _effectiveDataRevision.value++;
      notifyListeners();
    }
    return revisesLatest
        ? CandlestickUpsertResult.revised
        : CandlestickUpsertResult.appended;
  }

  /// Adds multiple data points to the stream.
  ///
  /// More efficient than calling [addPoint] repeatedly when you have
  /// a batch of points to add (e.g., from a WebSocket message).
  ///
  /// **Performance**: O(k) where k = number of points.
  ///
  /// **Example**:
  /// ```dart
  /// final batch = webSocketMessage.points.map((p) =>
  ///   ChartDataPoint(x: p.timestamp, y: p.value)
  /// ).toList();
  /// controller.addPoints(batch);
  /// ```
  void addPoints(List<ChartDataPoint> points) {
    if (_isDisposed || points.isEmpty) return;

    // PERFORMANCE FIX: Process data immediately, don't wait for frame callback
    if (_isStreaming) {
      // Streaming: add all to buffer immediately
      _streamingBuffer.addAll(points);
      _effectiveDataRevision.value++;
      // Schedule render update (frame-coalesced)
      _scheduleFrameCallback();
    } else {
      // Paused: buffer all for later
      for (final point in points) {
        _pauseBuffer.add(point);
      }
      _effectiveDataRevision.value++;
      // Notify listeners so UI can show buffer count (no frame needed)
      notifyListeners();
    }
  }

  // ============================================================================
  // Streaming Control
  // ============================================================================

  /// Pauses streaming and begins buffering incoming data.
  ///
  /// When paused:
  /// - Viewport is frozen at current position
  /// - User can pan/zoom through existing data
  /// - Incoming data is buffered (not displayed)
  /// - [bufferedCount] shows how much is buffered
  ///
  /// Call [resume] to apply buffered data and resume streaming.
  ///
  /// **Note**: Does nothing if already paused.
  void pause() {
    if (!_isStreaming || _isDisposed) return;

    _isStreaming = false;

    // Notify RenderBox to lock viewport
    _renderBox?.lockViewportForPause();

    notifyListeners();
  }

  /// Resumes streaming and applies all buffered data.
  ///
  /// When resumed:
  /// - All buffered data is added to the chart
  /// - Viewport snaps to latest data (if [autoScroll] is true)
  /// - Streaming continues normally
  ///
  /// **Note**: Does nothing if already streaming.
  void resume() {
    if (_isStreaming || _isDisposed) return;

    _isStreaming = true;

    // Apply buffered data
    final buffered = _pauseBuffer.removeAll();
    if (buffered.isNotEmpty) {
      for (final point in buffered) {
        final latest = _streamingBuffer.latest;
        if (point is CandlestickDataPoint &&
            latest is CandlestickDataPoint &&
            point.x == latest.x) {
          _streamingBuffer.replaceLatest(point);
        } else {
          _streamingBuffer.add(point);
        }
      }
    }

    // Notify RenderBox to unlock viewport and update
    _renderBox?.unlockViewportForResume();

    // Force immediate update with all data
    _flushToRenderBox();

    notifyListeners();
  }

  /// Clears all streaming data and buffered data.
  ///
  /// Resets the chart to empty state. Does not change pause/resume state.
  void clear() {
    if (_isDisposed) return;

    _streamingBuffer.clear();
    _pauseBuffer.clear();
    _pendingPoints.clear();
    _effectiveDataRevision.value++;

    // Update RenderBox
    _renderBox?.clearStreamingData(seriesId);

    notifyListeners();
  }

  // ============================================================================
  // RenderBox Attachment (Internal)
  // ============================================================================

  /// Attaches this controller to a RenderBox for direct data injection.
  ///
  /// Called by BravenChartPlus when the widget is mounted.
  /// After attachment, data flows directly to the RenderBox without
  /// triggering widget rebuilds.
  ///
  /// **Internal API**: Do not call directly.
  void attachRenderBox(ChartRenderBox renderBox) {
    if (_isDisposed) return;

    _renderBox = renderBox;

    // Send current buffer state to RenderBox
    if (_streamingBuffer.isNotEmpty) {
      _flushToRenderBox();
    }
  }

  /// Detaches this controller from the RenderBox.
  ///
  /// Called by BravenChartPlus when the widget is unmounted.
  ///
  /// **Internal API**: Do not call directly.
  void detachRenderBox() {
    _renderBox = null;
  }

  // ============================================================================
  // Frame Scheduling (Internal)
  // ============================================================================

  /// Schedules a frame callback to flush pending points.
  ///
  /// Uses Flutter's scheduler to batch all points added within a frame
  /// into a single RenderBox update. This provides frame-coalesced updates
  /// at up to 60fps.
  void _scheduleFrameCallback() {
    if (_frameCallbackScheduled || _isDisposed) return;

    _frameCallbackScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _frameCallbackScheduled = false;
      _onFrame();
    });
  }

  /// Called once per frame to flush pending points.
  void _onFrame() {
    if (_isDisposed) return;

    // Track frame rate
    _frameCount++;
    _frameCountStartTime ??= DateTime.now();
    // Reset counter every second for rolling average
    final elapsed = DateTime.now()
        .difference(_frameCountStartTime!)
        .inMilliseconds;
    if (elapsed > 1000) {
      _frameCount = 1;
      _frameCountStartTime = DateTime.now();
    }

    // PERFORMANCE FIX: Data is already in _streamingBuffer (added immediately in addPoint)
    // This frame callback only updates the RenderBox for rendering
    if (_isStreaming && _streamingBuffer.isNotEmpty) {
      _flushToRenderBox();
    }

    _pendingPoints.clear();
  }

  /// Sends current buffer state to the attached RenderBox.
  void _flushToRenderBox() {
    final renderBox = _renderBox;
    if (renderBox == null) return;

    // PERFORMANCE: Pass buffer reference directly instead of copying to list.
    // The RenderBox will read from the buffer using indexed access.
    renderBox.setStreamingData(
      seriesId: seriesId,
      buffer: _streamingBuffer,
      expandViewportWhenNotAutoScrolling: manageViewport && !autoScroll,
      maxVisiblePoints: maxVisiblePoints,
    );

    // Auto-scroll to latest if enabled
    if (manageViewport && autoScroll && _streamingBuffer.isNotEmpty) {
      renderBox.snapViewportToStreamingData(
        marginPercent: autoScrollMarginPercent,
        viewportDataPoints: viewportDataPoints,
      );
    }
  }

  // ============================================================================
  // Lifecycle
  // ============================================================================

  @override
  void dispose() {
    _isDisposed = true;

    // Clear streaming data from RenderBox before detaching
    // This resets the viewport state for the next controller
    _renderBox?.clearStreamingData(seriesId);

    _renderBox = null;
    _pendingPoints.clear();
    _streamingBuffer.clear();
    _pauseBuffer.clear();
    _effectiveDataRevision.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return 'LiveStreamController('
        'seriesId: $seriesId, '
        'points: ${_streamingBuffer.length}/$maxPoints, '
        'buffered: ${_pauseBuffer.length}, '
        'streaming: $_isStreaming, '
        'manageViewport: $manageViewport, '
        'attached: ${_renderBox != null})';
  }
}
