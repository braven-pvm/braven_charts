import 'package:equatable/equatable.dart';

/// A single data point with X and Y coordinates.
///
/// Represents an immutable point in a chart's data series.
/// Uses [EquatableMixin] for value equality comparisons.
///
/// ## Example
///
/// ```dart
/// final point = DataPoint(x: 1.0, y: 2.5);
/// final updated = point.copyWith(y: 3.0);
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = {'x': 1.0, 'y': 2.5};
/// final point = DataPoint.fromJson(json);
/// final map = point.toJson(); // {'x': 1.0, 'y': 2.5}
/// ```
class DataPoint with EquatableMixin {
  /// The X coordinate of this data point.
  final double x;

  /// The Y coordinate of this data point.
  final double y;

  /// Creates a [DataPoint] with the given [x] and [y] coordinates.
  ///
  /// Both parameters are required.
  const DataPoint({
    required this.x,
    required this.y,
  });

  /// Creates a [DataPoint] from a JSON map.
  ///
  /// The map must contain 'x' and 'y' keys with numeric values.
  /// Both int and double values are accepted and converted to double.
  ///
  /// Throws [TypeError] if values are not numeric.
  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  /// Converts this [DataPoint] to a JSON map.
  ///
  /// Returns a map with 'x' and 'y' keys containing double values.
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  /// Creates a copy of this [DataPoint] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  DataPoint copyWith({
    double? x,
    double? y,
  }) {
    return DataPoint(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'DataPoint(x: $x, y: $y)';
}
