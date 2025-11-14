// Copyright (c) 2025 braven_charts. All rights reserved.
// Streaming Controller for BravenChartPlus

import 'package:flutter/foundation.dart';

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

  /// Internal callback to resume streaming (set by BravenChartPlus).
  VoidCallback? _resumeStreamingCallback;

  /// Internal callback to pause streaming (set by BravenChartPlus).
  VoidCallback? _pauseStreamingCallback;

  /// Whether streaming is currently active.
  bool get isStreaming => _isStreaming;

  /// Whether streaming is currently paused.
  bool get isPaused => !_isStreaming;

  /// Registers the resume callback (called by BravenChartPlus internally).
  void registerResumeCallback(VoidCallback callback) {
    _resumeStreamingCallback = callback;
  }

  /// Registers the pause callback (called by BravenChartPlus internally).
  void registerPauseCallback(VoidCallback callback) {
    _pauseStreamingCallback = callback;
  }

  /// Updates the streaming state (called by BravenChartPlus internally).
  void updateState(bool isStreaming) {
    if (_isStreaming != isStreaming) {
      _isStreaming = isStreaming;
      notifyListeners();
    }
  }

  /// Manually resumes streaming.
  ///
  /// Effects:
  /// - Applies any buffered data points to chart
  /// - Clears buffer
  /// - Resumes real-time updates
  /// - Auto-scroll resumes (if enabled)
  ///
  /// **Idempotency**: Safe to call when already streaming (no-op).
  ///
  /// **Use Cases**:
  /// - "Resume" button in your UI
  /// - Custom gesture to resume (e.g., double-tap)
  /// - Keyboard shortcut (e.g., Spacebar)
  void resumeStreaming() {
    if (!_isStreaming) {
      _resumeStreamingCallback?.call();
    }
  }

  /// Manually pauses streaming.
  ///
  /// Effects:
  /// - Stops real-time updates
  /// - Future stream data will be buffered
  /// - User can interact with chart without new data interfering
  ///
  /// **Idempotency**: Safe to call when already paused (no-op).
  ///
  /// **Use Cases**:
  /// - "Pause" button in your UI
  /// - Automatic pause on user interaction
  void pauseStreaming() {
    if (_isStreaming) {
      _pauseStreamingCallback?.call();
    }
  }

  @override
  void dispose() {
    _resumeStreamingCallback = null;
    _pauseStreamingCallback = null;
    super.dispose();
  }
}
