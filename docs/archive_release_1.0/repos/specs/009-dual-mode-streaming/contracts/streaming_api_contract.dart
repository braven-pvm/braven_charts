/// API Contract: Dual-Mode Streaming Chart
///
/// This file defines the public API surface for dual-mode streaming functionality.
/// Implementation files MUST match these signatures exactly.

// ============================================================================
// ChartMode Enum
// ============================================================================

/// Operating mode for BravenChart with streaming data support.
///
/// Chart operates in exactly ONE mode at any time (FR-001).
/// Each chart instance manages its mode independently (FR-001a).
enum ChartMode {
  /// Streaming mode: Data updates freely, interaction handlers disabled,
  /// auto-scroll enabled. Optimized for real-time monitoring at 60fps (FR-018).
  streaming,

  /// Interactive mode: Streaming paused, data buffered, full interaction
  /// enabled. Responds to user input within 16ms (FR-019).
  interactive,
}

// ============================================================================
// StreamingConfig Class
// ============================================================================

/// Configuration for dual-mode streaming behavior in BravenChart.
///
/// Controls mode transitions, buffer limits, and developer callbacks.
/// All parameters are optional with sensible defaults.
///
/// Example:
/// ```dart
/// StreamingConfig(
///   autoResumeTimeout: Duration(seconds: 15),
///   maxBufferSize: 5000,
///   onModeChanged: (mode) {
///     print('Chart mode: $mode');
///   },
///   onBufferUpdated: (count) {
///     print('Buffered: $count points');
///   },
/// )
/// ```
class StreamingConfig {
  /// Creates a streaming configuration.
  ///
  /// All parameters optional. Defaults support common streaming scenarios.
  const StreamingConfig({
    this.autoResumeTimeout = const Duration(seconds: 10),
    this.maxBufferSize = 10000,
    this.pauseOnFirstInteraction = true,
    this.onModeChanged,
    this.onBufferUpdated,
    this.onReturnToLive,
    this.onStreamError,
  }) : assert(maxBufferSize > 0, 'maxBufferSize must be positive'),
       assert(
         autoResumeTimeout > Duration.zero,
         'autoResumeTimeout must be positive',
       );

  /// Duration of inactivity before auto-resuming streaming mode (FR-007).
  ///
  /// Timer resets on ANY user interaction (hover, click, zoom, pan, scroll, keyboard).
  /// Default: 10 seconds.
  ///
  /// See also:
  /// - [pauseOnFirstInteraction] to disable auto-pause behavior
  /// - [onModeChanged] to track mode transitions
  final Duration autoResumeTimeout;

  /// Maximum number of data points to buffer during interactive mode (FR-013).
  ///
  /// When reached, chart forces immediate return to streaming mode
  /// to prevent data loss (FR-014). All buffered points are applied.
  /// Default: 10,000 points.
  ///
  /// See also:
  /// - [onBufferUpdated] to monitor buffer growth
  final int maxBufferSize;

  /// Whether to pause streaming on first user interaction (FR-004).
  ///
  /// If true (default): Chart starts in streaming mode, pauses on interaction.
  /// If false: Chart stays in interactive mode, never auto-pauses.
  /// Default: true.
  final bool pauseOnFirstInteraction;

  /// Callback invoked when chart mode changes (FR-015).
  ///
  /// Called on transitions: streaming→interactive, interactive→streaming.
  /// Provides new mode for developer UI updates.
  ///
  /// Example use cases:
  /// - Show "LIVE" indicator when in streaming mode
  /// - Disable zoom controls when in streaming mode
  /// - Update status badge
  ///
  /// Optional. No callback if null.
  final void Function(ChartMode newMode)? onModeChanged;

  /// Callback invoked when data is buffered in interactive mode (FR-016).
  ///
  /// Called each time a new data point is buffered (not rendered).
  /// Provides current buffer count.
  ///
  /// Example use cases:
  /// - Display "142 new points" badge
  /// - Show "5 seconds behind live" message
  /// - Warn user when approaching maxBufferSize
  ///
  /// Optional. No callback if null.
  final void Function(int bufferCount)? onBufferUpdated;

  /// Callback invoked to enable "Return to Live" UI (FR-017).
  ///
  /// Called when chart enters interactive mode.
  /// Developer can show manual resume button or similar control.
  ///
  /// Example use cases:
  /// - Show "Return to Live" button
  /// - Enable jump-to-latest navigation
  ///
  /// Optional. No callback if null.
  ///
  /// See also:
  /// - [BravenChart.resumeStreaming()] to manually resume
  final VoidCallback? onReturnToLive;

  /// Callback invoked when stream errors occur (FR-017a).
  ///
  /// Called immediately when data stream throws error.
  /// Developer responsible for reconnection/retry logic.
  /// Chart does NOT retry automatically.
  ///
  /// Example use cases:
  /// - Show error banner
  /// - Log error to monitoring service
  /// - Attempt reconnection
  ///
  /// Optional. No callback if null (error silently ignored).
  final void Function(Object error)? onStreamError;
}

// ============================================================================
// BravenChart API Extension
// ============================================================================

/// Extension to BravenChart widget for dual-mode streaming support.
///
/// This contract defines the new API surface added to BravenChart.
/// Existing non-streaming charts remain unaffected (backward compatible).
abstract class BravenChartStreamingAPI {
  /// Optional configuration for dual-mode streaming behavior.
  ///
  /// Required when [data] is a Stream. Optional for static data.
  /// If null, chart operates in traditional mode (always interactive).
  ///
  /// Throws [ArgumentError] if [data] is Stream but [streamingConfig] is null.
  ///
  /// Example:
  /// ```dart
  /// // Streaming chart (new feature)
  /// BravenChart(
  ///   data: myStreamController.stream,
  ///   streamingConfig: StreamingConfig(),
  /// )
  ///
  /// // Static chart (existing behavior)
  /// BravenChart(
  ///   data: myStaticData,
  ///   // streamingConfig not needed
  /// )
  /// ```
  StreamingConfig? get streamingConfig;

  /// Manually resume streaming mode from interactive mode (FR-010).
  ///
  /// Forces immediate transition to streaming mode regardless of timeout.
  /// Applies all buffered data, clears buffer, jumps viewport to latest.
  /// Cancels auto-resume timer.
  ///
  /// No-op if already in streaming mode (idempotent).
  ///
  /// Example use case:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => chartKey.currentState?.resumeStreaming(),
  ///   child: Text('Return to Live'),
  /// )
  /// ```
  ///
  /// See also:
  /// - [StreamingConfig.onReturnToLive] to show resume button
  /// - [StreamingConfig.onModeChanged] to track mode transitions
  void resumeStreaming();
}

// ============================================================================
// Internal State (Not Public API)
// ============================================================================

/// Internal state management (private to BravenChart implementation).
///
/// These are NOT part of the public API. Listed here for contract completeness.
/// Developers MUST NOT access these directly.
abstract class _BravenChartInternalState {
  /// Current chart mode (streaming or interactive).
  /// Managed via ValueNotifier for reactive updates.
  ValueNotifier<ChartMode> get chartMode;

  /// FIFO buffer for data points arriving during interactive mode.
  /// Implemented using dart:collection Queue for O(1) operations.
  Queue<DataPoint> get bufferedPoints;

  /// Auto-resume timer (null when in streaming mode).
  /// Triggers _resumeStreaming() on timeout expiration.
  Timer? get autoResumeTimer;

  /// Transition from streaming to interactive mode.
  /// Triggered by first user interaction (FR-004).
  void pauseStreaming();

  /// Transition from interactive to streaming mode.
  /// Applies buffered data, clears buffer, jumps viewport (FR-011, FR-012).
  void resumeStreamingInternal();

  /// Reset auto-resume timer on user interaction (FR-008).
  void resetAutoResumeTimer();

  /// Buffer incoming data point during interactive mode (FR-006).
  /// Enforces maxBufferSize limit (FR-013, FR-014).
  void bufferDataPoint(DataPoint point);

  /// Apply all buffered data points to chart.
  /// Called during transition to streaming mode.
  void applyBufferedData();

  /// Update viewport to show latest data points.
  /// Called after resuming streaming mode (FR-012).
  void jumpToLatestData();

  /// Handle user interaction event.
  /// Pauses streaming if in streaming mode, resets timer if in interactive.
  void handleInteraction();
}

// ============================================================================
// Contract Validation Checklist
// ============================================================================

/// This contract satisfies the following functional requirements:
///
/// [x] FR-001: Chart operates in exactly one mode (streaming OR interactive)
/// [x] FR-001a: Each chart instance manages mode independently
/// [x] FR-002: Chart starts in streaming mode when stream configured
/// [x] FR-003: Chart starts in interactive mode when no stream
/// [x] FR-004: Auto-transition to interactive on first interaction
/// [x] FR-005: Disable ALL interaction handlers in streaming mode
/// [x] FR-006: Buffer data silently in interactive mode
/// [x] FR-006a: No validation (fail-fast on invalid data)
/// [x] FR-007: Configurable auto-resume timeout (default 10s)
/// [x] FR-008: Reset timer on any interaction
/// [x] FR-009: Auto-resume on timeout
/// [x] FR-010: Manual resume method (resumeStreaming())
/// [x] FR-011: Apply buffered data on resume
/// [x] FR-012: Jump viewport to latest on resume
/// [x] FR-013: Buffer size limit (configurable, default 10K)
/// [x] FR-014: Force resume when buffer fills
/// [x] FR-015: onModeChanged callback
/// [x] FR-016: onBufferUpdated callback
/// [x] FR-017: onReturnToLive callback
/// [x] FR-017a: onStreamError callback
/// [x] FR-017b: No built-in logging
/// [x] FR-018: 60fps streaming target
/// [x] FR-019: 16ms interaction response target
/// [x] FR-020: No rendering errors (box.dart, mouse_tracker.dart)
///
/// Success Criteria Coverage:
/// [x] SC-001: 60fps for 10-minute sessions
/// [x] SC-002: <50ms mode transitions
/// [x] SC-003: Zero rendering errors
/// [x] SC-004: <16ms interaction response
/// [x] SC-005: Buffer 10K points, forced resume
/// [x] SC-006: <100ms auto-resume
/// [x] SC-007: <500ms buffered data application
/// [x] SC-008: Unlimited interaction cycles
/// [x] SC-009: Stable memory (1-hour sessions)
/// [x] SC-010: 100+ points/sec handling
