// Copyright (c) 2025 braven_charts. All rights reserved.
// Streaming Configuration for BravenChartPlus

/// Configuration for real-time data streaming in BravenChartPlus.
///
/// Controls buffer limits, auto-scroll behavior, window size, and provides
/// callbacks for stream events. This is a simplified version focused on the
/// core streaming use case (no dual-mode complexity).
///
/// **Basic Example**:
/// ```dart
/// BravenChartPlus(
///   chartType: ChartType.line,
///   series: [...],
///   dataStream: sensorDataStream,
///   streamingConfig: StreamingConfig(),  // Uses defaults
/// )
/// ```
///
/// **Advanced Example**:
/// ```dart
/// BravenChartPlus(
///   chartType: ChartType.line,
///   series: [...],
///   dataStream: sensorDataStream,
///   streamingConfig: StreamingConfig(
///     maxBufferSize: 5000,           // Smaller buffer
///     autoScroll: true,              // Follow latest data
///     autoScrollWindowSize: 100,     // Show last 100 points
///     resumeAnimationDuration: Duration(milliseconds: 500),  // Slower animation
///     onBufferUpdated: (count) {
///       print('Buffered: $count points');
///     },
///   ),
/// )
/// ```
class StreamingConfig {
  /// Creates a streaming configuration.
  ///
  /// All parameters optional with sensible defaults:
  /// - [maxBufferSize]: 10,000 points
  /// - [autoScroll]: true (viewport follows latest data)
  /// - [autoScrollWindowSize]: 150 points (sliding window size)
  /// - [resumeAnimationDuration]: 300ms (smooth jump to latest)
  /// - All callbacks: null (optional)
  ///
  /// Validation:
  /// - [maxBufferSize] must be positive (> 0)
  /// - [autoScrollWindowSize] must be positive (> 0)
  const StreamingConfig({
    this.maxBufferSize = 10000,
    this.autoScroll = true,
    this.autoScrollWindowSize = 150,
    this.resumeAnimationDuration = const Duration(milliseconds: 300),
    this.onBufferUpdated,
    this.onStreamError,
  })  : assert(maxBufferSize > 0, 'maxBufferSize must be positive'),
        assert(
            autoScrollWindowSize > 0, 'autoScrollWindowSize must be positive');

  /// Maximum number of data points to buffer.
  ///
  /// When the buffer reaches this limit, oldest points are discarded
  /// (FIFO overflow). This prevents unbounded memory growth.
  ///
  /// **Default**: 10,000 points
  ///
  /// Example sizing:
  /// - Low-frequency (1 Hz): 10,000 points = 2.7 hours
  /// - Medium-frequency (10 Hz): 10,000 points = 16 minutes
  /// - High-frequency (100 Hz): 10,000 points = 100 seconds
  final int maxBufferSize;

  /// Whether to automatically scroll viewport to show latest data.
  ///
  /// When true, the chart viewport automatically pans to keep the
  /// most recent data points visible as new data arrives.
  ///
  /// When false, the viewport stays fixed and user must manually
  /// pan to see new data.
  ///
  /// **Default**: true
  final bool autoScroll;

  /// Number of data points to display in the auto-scroll window.
  ///
  /// When [autoScroll] is enabled, this determines how many of the
  /// most recent data points are visible in the viewport at once.
  /// Older data scrolls off the left edge as new data arrives.
  ///
  /// This creates a "sliding window" effect where you always see
  /// the last N points.
  ///
  /// **Default**: 150 points
  ///
  /// **Examples**:
  /// - Small window (50): Good for high-frequency data (10+ Hz)
  /// - Medium window (150): Default, balanced for most use cases
  /// - Large window (500): Good for low-frequency data with long trends
  ///
  /// **Use Cases**:
  /// - High-frequency monitoring: 50-100 points (30 sec @ 10 Hz)
  /// - Medium-frequency: 150-300 points (5 min @ 1 Hz)
  /// - Low-frequency analysis: 500+ points (longer time spans)
  final int autoScrollWindowSize;

  /// Duration of animation when resuming streaming.
  ///
  /// When user resumes streaming after pause, the viewport smoothly
  /// animates back to show the latest data. This duration controls
  /// how long that animation takes.
  ///
  /// **Default**: 300ms
  ///
  /// **Guidelines**:
  /// - Fast (100-200ms): Snappy, responsive feel
  /// - Medium (300-400ms): Smooth, balanced (default)
  /// - Slow (500-1000ms): Very smooth, deliberate
  ///
  /// **Zero duration**: Set to Duration.zero for instant jump (no animation)
  final Duration resumeAnimationDuration;

  /// Callback invoked when data is added to the buffer.
  ///
  /// Provides the current buffer count. Useful for showing users
  /// how much data has accumulated.
  ///
  /// **Example**:
  /// ```dart
  /// onBufferUpdated: (count) {
  ///   setState(() {
  ///     bufferedPoints = count;
  ///   });
  /// }
  /// ```
  ///
  /// **Frequency**: Called on every new data point.
  /// For high-frequency streams, consider throttling UI updates.
  ///
  /// **Optional**: If null, buffer updates occur silently.
  final void Function(int bufferCount)? onBufferUpdated;

  /// Callback invoked when the data stream throws an error.
  ///
  /// Use this to display error messages, log errors, or attempt
  /// reconnection.
  ///
  /// **Example**:
  /// ```dart
  /// onStreamError: (error) {
  ///   showSnackBar('Stream error: $error');
  ///   attemptReconnection();
  /// }
  /// ```
  ///
  /// **Optional**: If null, stream errors are silently ignored.
  final void Function(Object error)? onStreamError;

  /// Creates a copy with modified properties.
  StreamingConfig copyWith({
    int? maxBufferSize,
    bool? autoScroll,
    int? autoScrollWindowSize,
    Duration? resumeAnimationDuration,
    void Function(int bufferCount)? onBufferUpdated,
    void Function(Object error)? onStreamError,
  }) {
    return StreamingConfig(
      maxBufferSize: maxBufferSize ?? this.maxBufferSize,
      autoScroll: autoScroll ?? this.autoScroll,
      autoScrollWindowSize: autoScrollWindowSize ?? this.autoScrollWindowSize,
      resumeAnimationDuration:
          resumeAnimationDuration ?? this.resumeAnimationDuration,
      onBufferUpdated: onBufferUpdated ?? this.onBufferUpdated,
      onStreamError: onStreamError ?? this.onStreamError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamingConfig &&
        other.maxBufferSize == maxBufferSize &&
        other.autoScroll == autoScroll &&
        other.autoScrollWindowSize == autoScrollWindowSize &&
        other.resumeAnimationDuration == resumeAnimationDuration;
    // Callbacks intentionally excluded from equality
  }

  @override
  int get hashCode => Object.hash(
      maxBufferSize, autoScroll, autoScrollWindowSize, resumeAnimationDuration);

  @override
  String toString() {
    return 'StreamingConfig(maxBufferSize: $maxBufferSize, autoScroll: $autoScroll, '
        'autoScrollWindowSize: $autoScrollWindowSize, resumeAnimationDuration: $resumeAnimationDuration)';
  }
}
