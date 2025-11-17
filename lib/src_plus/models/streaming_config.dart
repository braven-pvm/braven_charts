// Copyright (c) 2025 braven_charts. All rights reserved.
// Streaming Configuration for BravenChartPlus

/// Configuration for real-time data streaming in BravenChartPlus.
///
/// Controls buffer limits, auto-scroll behavior, and provides callbacks
/// for stream events. This is a simplified version focused on the core
/// streaming use case (no dual-mode complexity).
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
///     maxBufferSize: 5000,  // Smaller buffer
///     autoScroll: true,     // Follow latest data
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
  /// - All callbacks: null (optional)
  ///
  /// Validation:
  /// - [maxBufferSize] must be positive (> 0)
  const StreamingConfig({
    this.maxBufferSize = 10000,
    this.autoScroll = true,
    this.onBufferUpdated,
    this.onStreamError,
  }) : assert(maxBufferSize > 0, 'maxBufferSize must be positive');

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
    void Function(int bufferCount)? onBufferUpdated,
    void Function(Object error)? onStreamError,
  }) {
    return StreamingConfig(
      maxBufferSize: maxBufferSize ?? this.maxBufferSize,
      autoScroll: autoScroll ?? this.autoScroll,
      onBufferUpdated: onBufferUpdated ?? this.onBufferUpdated,
      onStreamError: onStreamError ?? this.onStreamError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamingConfig && other.maxBufferSize == maxBufferSize && other.autoScroll == autoScroll;
    // Callbacks intentionally excluded from equality
  }

  @override
  int get hashCode => Object.hash(maxBufferSize, autoScroll);

  @override
  String toString() {
    return 'StreamingConfig(maxBufferSize: $maxBufferSize, autoScroll: $autoScroll)';
  }
}
