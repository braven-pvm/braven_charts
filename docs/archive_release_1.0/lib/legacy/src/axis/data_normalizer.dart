/// Utility class for normalizing and denormalizing data values.
///
/// This class provides static methods to transform data values between
/// their original range and a normalized 0.0-1.0 range. This is essential
/// for multi-axis charts where different data series may have vastly
/// different value ranges that need to be displayed together.
///
/// Example:
/// ```dart
/// // Normalize a heart rate value (60-200 bpm) to 0.0-1.0 range
/// final normalized = DataNormalizer.normalize(130.0, 60.0, 200.0);
/// // normalized = 0.5 (midpoint)
///
/// // Convert back to original range
/// final original = DataNormalizer.denormalize(0.5, 60.0, 200.0);
/// // original = 130.0
/// ```
///
/// ## Edge Cases
///
/// - **Zero range** (min == max): Returns 0.5 for normalize, returns min for denormalize
/// - **Values outside range**: Allowed - will produce values < 0.0 or > 1.0
class DataNormalizer {
  /// Private constructor to prevent instantiation.
  ///
  /// This is a utility class with only static methods.
  DataNormalizer._();

  /// Normalizes a raw data value to a 0.0-1.0 range.
  ///
  /// Converts [value] from the range [min, max] to the range [0.0, 1.0].
  ///
  /// - When [value] equals [min], returns 0.0
  /// - When [value] equals [max], returns 1.0
  /// - Values between [min] and [max] scale proportionally
  /// - Values outside the range will produce results < 0.0 or > 1.0
  ///
  /// **Edge case**: When [min] equals [max] (zero range), returns 0.5
  /// to provide a neutral midpoint rather than causing a division by zero.
  ///
  /// Example:
  /// ```dart
  /// DataNormalizer.normalize(150.0, 100.0, 200.0); // Returns 0.5
  /// DataNormalizer.normalize(100.0, 100.0, 200.0); // Returns 0.0
  /// DataNormalizer.normalize(200.0, 100.0, 200.0); // Returns 1.0
  /// DataNormalizer.normalize(50.0, 100.0, 200.0);  // Returns -0.5
  /// ```
  static double normalize(double value, double min, double max) {
    final range = max - min;

    // Handle zero range edge case
    if (range == 0) {
      return 0.5;
    }

    return (value - min) / range;
  }

  /// Denormalizes a value from 0.0-1.0 range back to original range.
  ///
  /// Converts [normalized] from the range [0.0, 1.0] back to [min, max].
  /// This is the inverse operation of [normalize].
  ///
  /// - When [normalized] is 0.0, returns [min]
  /// - When [normalized] is 1.0, returns [max]
  /// - Values between 0.0 and 1.0 scale proportionally
  /// - Values outside 0.0-1.0 will produce results outside [min, max]
  ///
  /// **Edge case**: When [min] equals [max] (zero range), returns [min]
  /// since there's only one possible value in the range.
  ///
  /// Example:
  /// ```dart
  /// DataNormalizer.denormalize(0.5, 100.0, 200.0);  // Returns 150.0
  /// DataNormalizer.denormalize(0.0, 100.0, 200.0);  // Returns 100.0
  /// DataNormalizer.denormalize(1.0, 100.0, 200.0);  // Returns 200.0
  /// DataNormalizer.denormalize(-0.5, 100.0, 200.0); // Returns 50.0
  /// ```
  static double denormalize(double normalized, double min, double max) {
    final range = max - min;

    // Handle zero range edge case
    if (range == 0) {
      return min;
    }

    return min + (normalized * range);
  }
}
