// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Operating mode for BravenChart widget.
///
/// The chart operates in exactly ONE mode at any time:
/// - **Streaming**: Real-time data updates, interactions disabled, auto-scroll enabled
/// - **Interactive**: Streaming paused, data buffered, full interaction enabled
///
/// Mode transitions:
/// - Streaming → Interactive: Automatic on first user interaction (hover, tap, pan, zoom)
/// - Interactive → Streaming: Automatic after timeout OR manual via resumeStreaming()
///
/// Example:
/// ```dart
/// // Chart automatically starts in streaming mode when dataStream provided
/// BravenChart(
///   dataStream: sensorDataStream,
///   streamingConfig: StreamingConfig(
///     onModeChanged: (mode) {
///       print('Mode: ${mode == ChartMode.streaming ? 'LIVE' : 'PAUSED'}');
///     },
///   ),
/// )
/// ```
///
/// Related: T005 (ChartMode enum implementation)
enum ChartMode {
  /// Real-time streaming mode.
  ///
  /// Characteristics:
  /// - Data updates applied immediately to chart
  /// - Auto-scroll enabled (shows latest data)
  /// - Interaction handlers disabled (no hover, zoom, pan)
  /// - ValueListenableBuilder safe from MouseTracker conflicts
  /// - Target: 60fps rendering at 100+ points/sec
  ///
  /// This mode prevents rendering pipeline errors (box.dart:3345,
  /// mouse_tracker.dart:199) by disabling all interactions at widget tree level.
  streaming,

  /// Interactive mode with paused streaming.
  ///
  /// Characteristics:
  /// - Data updates buffered silently (FIFO queue, max 10K points)
  /// - Auto-scroll disabled (user controls viewport)
  /// - Full interaction enabled (crosshair, tooltip, zoom, pan)
  /// - Auto-resume timer active (returns to streaming after timeout)
  /// - Target: <16ms interaction response time
  ///
  /// Entering this mode:
  /// - Automatically: On first user interaction (pauseOnFirstInteraction = true)
  /// - Never: If pauseOnFirstInteraction = false (interactions disabled forever)
  ///
  /// Exiting this mode:
  /// - Automatically: After autoResumeTimeout with no interactions (default 10s)
  /// - Manually: Via chartState.resumeStreaming() API call
  interactive,
}
