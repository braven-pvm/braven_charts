// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Controller for programmatic control of dual-mode streaming behavior.
///
/// Provides methods to manually control streaming mode transitions,
/// allowing developers to build custom UI controls (buttons, gestures)
/// for pausing and resuming the stream.
///
/// Example:
/// ```dart
/// final streamingController = StreamingController();
///
/// // In your UI:
/// ElevatedButton(
///   onPressed: () => streamingController.resumeStreaming(),
///   child: Text('Resume Live Data'),
/// ),
///
/// // Pass to BravenChart:
/// BravenChart(
///   streamingController: streamingController,
///   // ...other config
/// ),
///
/// // Clean up:
/// streamingController.dispose();
/// ```
///
/// **Note**: Methods are no-ops if chart is not in the expected mode.
/// For example, resumeStreaming() does nothing if already streaming.
class StreamingController extends ChangeNotifier {
  /// Internal callback to resume streaming (set by BravenChart).
  VoidCallback? _resumeStreamingCallback;

  /// Internal callback to pause streaming (set by BravenChart).
  VoidCallback? _pauseStreamingCallback;

  /// Registers the resume callback (called by BravenChart internally).
  void registerResumeCallback(VoidCallback callback) {
    _resumeStreamingCallback = callback;
  }

  /// Registers the pause callback (called by BravenChart internally).
  void registerPauseCallback(VoidCallback callback) {
    _pauseStreamingCallback = callback;
  }

  /// Manually resumes streaming from interactive mode (FR-010).
  ///
  /// This immediately transitions the chart from interactive mode back to
  /// streaming mode, applying any buffered data and cancelling the auto-resume timer.
  ///
  /// **Effects**:
  /// - Cancels auto-resume timer if active
  /// - Applies buffered data points to chart
  /// - Clears buffer
  /// - Transitions to streaming mode
  /// - Jumps viewport to latest data (if configured)
  /// - Invokes onModeChanged and onReturnToLive callbacks
  ///
  /// **Idempotency**: Safe to call when already streaming (no-op).
  ///
  /// **Use Cases**:
  /// - "Return to Live" button in your UI
  /// - Custom gesture to resume (e.g., double-tap)
  /// - Keyboard shortcut (e.g., Spacebar)
  /// - External trigger (e.g., API call, timer)
  void resumeStreaming() {
    _resumeStreamingCallback?.call();
  }

  /// Manually pauses streaming and enters interactive mode.
  ///
  /// This allows programmatic pause in addition to automatic pause on interaction.
  ///
  /// **Effects**:
  /// - Transitions to interactive mode
  /// - Starts auto-resume timer
  /// - Future stream data will be buffered instead of displayed
  ///
  /// **Idempotency**: Safe to call when already paused (resets timer).
  void pauseStreaming() {
    _pauseStreamingCallback?.call();
  }

  @override
  void dispose() {
    _resumeStreamingCallback = null;
    _pauseStreamingCallback = null;
    super.dispose();
  }
}
