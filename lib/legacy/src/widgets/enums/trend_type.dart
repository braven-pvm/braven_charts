/// Trend calculation types
///
/// Defines the statistical method used for trend annotations.
enum TrendType {
  /// Linear regression trend line
  linear,

  /// Polynomial regression trend line
  polynomial,

  /// Exponential regression trend line
  exponential,

  /// Moving average trend line
  movingAverage,
}
