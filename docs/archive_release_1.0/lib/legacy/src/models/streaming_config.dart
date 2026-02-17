// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/models/chart_mode.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

/// Configuration for dual-mode streaming behavior in BravenChart.
///
/// Controls automatic mode transitions, buffer limits, and developer callbacks.
/// Use this class when creating charts with real-time data streams that need
/// to support both live monitoring and historical analysis.
///
/// **Basic Example** (minimal configuration):
/// ```dart
/// BravenChart(
///   dataStream: sensorDataStream,
///   streamingConfig: StreamingConfig(),  // Uses all defaults
/// )
/// ```
///
/// **Advanced Example** (custom timeout and callbacks):
/// ```dart
/// BravenChart(
///   dataStream: sensorDataStream,
///   streamingConfig: StreamingConfig(
///     autoResumeTimeout: Duration(seconds: 15),  // Longer timeout
///     maxBufferSize: 5000,  // Smaller buffer
///     onModeChanged: (mode) {
///       // Update UI indicator
///       setState(() {
///         isLive = (mode == ChartMode.streaming);
///       });
///     },
///     onBufferUpdated: (count) {
///       // Show buffered point count
///       setState(() {
///         bufferedCount = count;
///       });
///     },
///     onReturnToLive: () {
///       // Show "Return to Live" button
///       setState(() {
///         showResumeButton = true;
///       });
///     },
///   ),
/// )
/// ```
///
/// Related: T002 (StreamingConfig class implementation), T006 (class implementation with validation)
class StreamingConfig {
  /// Creates a streaming configuration.
  ///
  /// All parameters are optional with sensible defaults:
  /// - [autoResumeTimeout]: 10 seconds
  /// - [maxBufferSize]: 10,000 points
  /// - [pauseOnFirstInteraction]: true
  /// - All callbacks: null (optional)
  ///
  /// Validation:
  /// - [autoResumeTimeout] must be positive (> Duration.zero)
  /// - [maxBufferSize] must be positive (> 0)
  ///
  /// Throws [AssertionError] if validation fails (fail-fast per FR-006a).
  StreamingConfig({
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

  /// Duration of inactivity before automatically resuming streaming mode (FR-007).
  ///
  /// When the chart is in interactive mode (paused), this timer counts down.
  /// If no user interactions occur before the timeout expires, the chart
  /// automatically resumes streaming mode, applying all buffered data.
  ///
  /// **Timer reset**: The countdown resets to the full duration on ANY user
  /// interaction: hover, click, zoom, pan, scroll, keyboard navigation (FR-008).
  ///
  /// **Default**: 10 seconds
  /// **Range**: 1-60 seconds recommended (must be positive)
  ///
  /// Example use cases:
  /// - Short timeout (5s): Fast-paced monitoring, quick return to live
  /// - Medium timeout (10s): Balanced - default for most use cases
  /// - Long timeout (30s): Detailed analysis, longer investigation periods
  ///
  /// See also:
  /// - [pauseOnFirstInteraction] to control auto-pause behavior
  /// - [onModeChanged] to track when auto-resume occurs
  final Duration autoResumeTimeout;

  /// Maximum number of data points to buffer during interactive mode (FR-013).
  ///
  /// While the chart is in interactive mode (paused), incoming data points
  /// are buffered instead of rendered. This parameter limits the buffer size
  /// to prevent unbounded memory growth.
  ///
  /// **Overflow behavior**: When the buffer reaches this limit, the chart
  /// IMMEDIATELY force-resumes to streaming mode and applies all buffered
  /// data (FR-014). This ensures no data loss.
  ///
  /// **Default**: 10,000 points
  /// **Performance**: Tested up to 10K points with <500ms application time (SC-007)
  ///
  /// Example sizing:
  /// - Low-frequency (1 Hz): 10,000 points = 2.7 hours buffer
  /// - Medium-frequency (10 Hz): 10,000 points = 16 minutes buffer
  /// - High-frequency (100 Hz): 10,000 points = 100 seconds buffer
  ///
  /// See also:
  /// - [onBufferUpdated] to monitor buffer growth
  /// - [onModeChanged] to detect forced auto-resume
  final int maxBufferSize;

  /// Whether to pause streaming automatically on first user interaction (FR-004).
  ///
  /// Controls the chart's behavior when a user interacts with a streaming chart:
  ///
  /// **If true (default)**:
  /// - Chart starts in streaming mode (live data updates)
  /// - On first interaction (hover, click, zoom, pan): automatically pauses
  /// - Subsequent data is buffered silently
  /// - User can analyze historical data without new data interfering
  /// - Chart auto-resumes after [autoResumeTimeout] of inactivity
  ///
  /// **If false**:
  /// - Chart starts in interactive mode
  /// - Streaming never auto-pauses
  /// - User interactions always enabled
  /// - Data continues streaming even during interactions (may cause visual conflicts)
  ///
  /// **Default**: true (recommended for most streaming scenarios)
  ///
  /// Example use cases:
  /// - true: Real-time monitoring with pause-for-analysis capability
  /// - false: Always-interactive chart with streaming data feed
  final bool pauseOnFirstInteraction;

  /// Callback invoked when chart mode changes (FR-015).
  ///
  /// Called during mode transitions:
  /// - streaming → interactive: User interacted, chart paused
  /// - interactive → streaming: Auto-resume or manual resume triggered
  ///
  /// Use this callback to update your UI to reflect the current chart state:
  /// - Show "LIVE" indicator when streaming
  /// - Show "PAUSED" indicator when interactive
  /// - Enable/disable controls based on mode
  ///
  /// **Example**:
  /// ```dart
  /// onModeChanged: (mode) {
  ///   setState(() {
  ///     isLive = (mode == ChartMode.streaming);
  ///   });
  /// }
  /// ```
  ///
  /// **Optional**: If null, mode changes occur silently.
  ///
  /// See also:
  /// - [ChartMode] enum for mode values
  /// - [onReturnToLive] for interactive→streaming transition specifically
  final void Function(ChartMode newMode)? onModeChanged;

  /// Callback invoked when data is buffered in interactive mode (FR-016).
  ///
  /// Called each time a new data point arrives and is added to the buffer
  /// (not rendered). Provides the current buffer count.
  ///
  /// Use this callback to show users how much data has accumulated during
  /// their analysis, helping them decide when to return to live mode.
  ///
  /// **Example**:
  /// ```dart
  /// onBufferUpdated: (count) {
  ///   setState(() {
  ///     bufferedPointsText = '$count new points';
  ///   });
  /// }
  /// ```
  ///
  /// **Frequency**: Called on every buffered data point arrival.
  /// For high-frequency streams (100+ Hz), consider throttling your UI updates.
  ///
  /// **Optional**: If null, buffer updates occur silently.
  ///
  /// See also:
  /// - [maxBufferSize] for buffer limit configuration
  /// - [onModeChanged] to detect forced resume when buffer fills
  final void Function(int bufferCount)? onBufferUpdated;

  /// Callback invoked when chart enters interactive mode (FR-017).
  ///
  /// Called when the chart transitions from streaming to interactive mode,
  /// signaling that a "Return to Live" button or similar UI control should
  /// be shown to the user.
  ///
  /// This callback helps you provide explicit user control over mode transitions:
  /// - Chart pauses automatically on interaction
  /// - You show a "Return to Live" button
  /// - User clicks button → call `chartState.resumeStreaming()`
  /// - Chart resumes streaming mode
  ///
  /// **Example**:
  /// ```dart
  /// onReturnToLive: () {
  ///   setState(() {
  ///     showResumeButton = true;
  ///   });
  /// }
  /// ```
  ///
  /// **Optional**: If null, mode transitions are fully automatic without
  /// explicit user controls.
  ///
  /// See also:
  /// - [BravenChart.resumeStreaming()] to manually resume
  /// - [onModeChanged] to track both transition directions
  final VoidCallback? onReturnToLive;

  /// Callback invoked when the data stream throws an error (FR-017a).
  ///
  /// Called immediately when an error is caught from the data stream.
  /// The chart does NOT automatically retry or reconnect - error handling
  /// is the responsibility of the developer.
  ///
  /// Use this callback to:
  /// - Display error messages to the user
  /// - Log errors to monitoring services
  /// - Attempt reconnection logic
  /// - Switch to fallback data source
  ///
  /// **Example**:
  /// ```dart
  /// onStreamError: (error) {
  ///   print('Stream error: $error');
  ///   showSnackBar('Lost connection to sensor');
  ///   // Attempt reconnection after delay
  ///   Future.delayed(Duration(seconds: 5), () {
  ///     reconnectToSensor();
  ///   });
  /// }
  /// ```
  ///
  /// **Optional**: If null, stream errors are silently ignored (NOT recommended).
  ///
  /// **Note**: The chart does NOT include built-in logging per FR-017b.
  /// All error handling must be implemented in this callback.
  final void Function(Object error)? onStreamError;
}
