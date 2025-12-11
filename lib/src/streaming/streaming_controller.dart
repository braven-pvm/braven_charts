// Copyright (c) 2025 braven_charts. All rights reserved.
// Streaming Controller for BravenChartPlus

import 'package:flutter/foundation.dart';

/// Viewport mode for streaming charts.
///
/// Determines whether the chart follows the latest data (auto-scroll)
/// or allows full exploration of historical data.
enum ViewportMode {
  /// Follow the latest data with auto-scroll (sliding window).
  ///
  /// When in this mode:
  /// - Viewport shows only the last N points (configured window size)
  /// - As new data arrives, viewport automatically pans to follow
  /// - User manual pan/zoom is limited to the visible window
  /// - Historical data is preserved but scrolled out of view
  followLatest,

  /// Allow full exploration of all historical data.
  ///
  /// When in this mode:
  /// - Viewport shows full data bounds (all accumulated points)
  /// - User can freely pan and zoom through entire dataset
  /// - No auto-scroll or viewport constraints
  /// - New data is buffered (not immediately visible)
  explore,
}

/// Controller for programmatic control of streaming behavior in BravenChartPlus.
///
/// Provides methods to control streaming state, allowing developers to build
/// custom UI controls (buttons, gestures) for pausing and resuming streams.
///
/// **Example Usage**:
/// ```dart
/// final streamingController = StreamingController();
///
/// // In your UI:
/// ElevatedButton(
///   onPressed: streamingController.isStreaming
///       ? streamingController.pauseStreaming
///       : streamingController.resumeStreaming,
///   child: Text(streamingController.isStreaming ? 'Pause' : 'Resume'),
/// ),
///
/// // Pass to BravenChartPlus:
/// BravenChartPlus(
///   chartType: ChartType.line,
///   series: [...],
///   dataStream: sensorDataStream,
///   streamingController: streamingController,
/// ),
///
/// // Clean up:
/// streamingController.dispose();
/// ```
class StreamingController extends ChangeNotifier {
  /// Whether streaming is currently active.
  bool _isStreaming = true;

  /// Current viewport mode (followLatest or explore).
  ViewportMode _viewportMode = ViewportMode.followLatest;

  /// Internal callback to resume streaming (set by BravenChartPlus).
  VoidCallback? _resumeStreamingCallback;

  /// Internal callback to pause streaming (set by BravenChartPlus).
  VoidCallback? _pauseStreamingCallback;

  /// Internal callback to clear/reset streaming data (set by BravenChartPlus).
  VoidCallback? _clearStreamingCallback;

  /// Whether streaming is currently active.
  bool get isStreaming => _isStreaming;

  /// Whether streaming is currently paused.
  bool get isPaused => !_isStreaming;

  /// Current viewport mode.
  ///
  /// - [ViewportMode.followLatest]: Auto-scroll enabled, shows sliding window
  /// - [ViewportMode.explore]: Full data exploration, manual pan/zoom
  ViewportMode get viewportMode => _viewportMode;

  /// Registers the resume callback (called by BravenChartPlus internally).
  void registerResumeCallback(VoidCallback callback) {
    _resumeStreamingCallback = callback;
  }

  /// Registers the pause callback (called by BravenChartPlus internally).
  void registerPauseCallback(VoidCallback callback) {
    _pauseStreamingCallback = callback;
  }

  /// Registers the clear callback (called by BravenChartPlus internally).
  void registerClearCallback(VoidCallback callback) {
    _clearStreamingCallback = callback;
  }

  /// Updates the streaming state (called by BravenChartPlus internally).
  void updateState(bool isStreaming) {
    if (_isStreaming != isStreaming) {
      _isStreaming = isStreaming;
      notifyListeners();
    } else {}
  }

  /// Manually resumes streaming.
  ///
  /// Effects:
  /// - Applies any buffered data points to chart
  /// - Clears buffer
  /// - Resumes real-time updates
  /// - Auto-scroll resumes (if enabled)
  /// - Viewport mode switches to [ViewportMode.followLatest]
  /// - Viewport jumps to show latest data (animated)
  ///
  /// **Idempotency**: Safe to call when already streaming (no-op).
  ///
  /// **Use Cases**:
  /// - "Resume" button in your UI
  /// - Custom gesture to resume (e.g., double-tap)
  /// - Keyboard shortcut (e.g., Spacebar)
  void resumeStreaming() {
    if (!_isStreaming) {
      _isStreaming = true; // Update state immediately
      _viewportMode = ViewportMode.followLatest;
      _resumeStreamingCallback?.call(); // Call widget callback FIRST
      notifyListeners(); // Notify AFTER callback
    } else {}
  }

  /// Manually pauses streaming.
  ///
  /// Effects:
  /// - Stops real-time updates
  /// - Future stream data will be buffered
  /// - User can interact with chart without new data interfering
  /// - Viewport mode switches to [ViewportMode.explore]
  /// - Full data bounds become available for pan/zoom
  ///
  /// **Idempotency**: Safe to call when already paused (no-op).
  ///
  /// **Use Cases**:
  /// - "Pause" button in your UI
  /// - Automatic pause on user interaction
  void pauseStreaming() async {
    if (_isStreaming) {
      _isStreaming = false; // Update state immediately
      _viewportMode = ViewportMode.explore;
      _pauseStreamingCallback
          ?.call(); // Call widget callback FIRST (sets _preserveAxesOnRebuild flag)
      notifyListeners(); // Notify AFTER callback so flag is already set
    } else {}
  }

  /// Clears all accumulated streaming data.
  ///
  /// Effects:
  /// - Removes all data points from the chart
  /// - Clears any buffered data
  /// - Resets the chart to initial empty state
  /// - Streaming continues if active
  ///
  /// **Use Cases**:
  /// - "Clear" or "Reset" button in your UI
  /// - Starting a new data collection session
  /// - Clearing old data before recording
  void clearStreamingData() {
    _clearStreamingCallback?.call();
  }

  @override
  void dispose() {
    _resumeStreamingCallback = null;
    _pauseStreamingCallback = null;
    _clearStreamingCallback = null;
    super.dispose();
  }
}
