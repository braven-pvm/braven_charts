import 'package:equatable/equatable.dart';

/// Configuration for chart visual styling.
///
/// Provides optional settings for colors, fonts, and padding.
/// All properties are nullable since styling is completely optional.
/// Uses [EquatableMixin] for value equality comparisons.
///
/// ## Example
///
/// ```dart
/// final style = ChartStyleConfig(
///   backgroundColor: '#FFFFFF',
///   gridColor: '#E0E0E0',
///   fontFamily: 'Roboto',
///   fontSize: 12.0,
///   paddingTop: 16.0,
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = style.toJson();
/// final restored = ChartStyleConfig.fromJson(json);
/// ```
class ChartStyleConfig with EquatableMixin {
  /// Background color for the chart (hex string or named color).
  final String? backgroundColor;

  /// Color for grid lines (hex string or named color).
  final String? gridColor;

  /// Color for axis lines and labels (hex string or named color).
  final String? axisColor;

  /// Font family for text elements.
  final String? fontFamily;

  /// Font size in pixels for text elements.
  final double? fontSize;

  /// Padding from the top edge in pixels.
  final double? paddingTop;

  /// Padding from the bottom edge in pixels.
  final double? paddingBottom;

  /// Padding from the left edge in pixels.
  final double? paddingLeft;

  /// Padding from the right edge in pixels.
  final double? paddingRight;

  /// Creates a [ChartStyleConfig] with the given parameters.
  ///
  /// All parameters are optional with no defaults.
  const ChartStyleConfig({
    this.backgroundColor,
    this.gridColor,
    this.axisColor,
    this.fontFamily,
    this.fontSize,
    this.paddingTop,
    this.paddingBottom,
    this.paddingLeft,
    this.paddingRight,
  });

  /// Creates a [ChartStyleConfig] from a JSON map.
  ///
  /// Parses all nullable fields appropriately.
  factory ChartStyleConfig.fromJson(Map<String, dynamic> json) {
    return ChartStyleConfig(
      backgroundColor: json['backgroundColor'] as String?,
      gridColor: json['gridColor'] as String?,
      axisColor: json['axisColor'] as String?,
      fontFamily: json['fontFamily'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      paddingTop: (json['paddingTop'] as num?)?.toDouble(),
      paddingBottom: (json['paddingBottom'] as num?)?.toDouble(),
      paddingLeft: (json['paddingLeft'] as num?)?.toDouble(),
      paddingRight: (json['paddingRight'] as num?)?.toDouble(),
    );
  }

  /// Converts this [ChartStyleConfig] to a JSON map.
  ///
  /// Returns a map with only non-null fields.
  Map<String, dynamic> toJson() {
    return {
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (gridColor != null) 'gridColor': gridColor,
      if (axisColor != null) 'axisColor': axisColor,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontSize != null) 'fontSize': fontSize,
      if (paddingTop != null) 'paddingTop': paddingTop,
      if (paddingBottom != null) 'paddingBottom': paddingBottom,
      if (paddingLeft != null) 'paddingLeft': paddingLeft,
      if (paddingRight != null) 'paddingRight': paddingRight,
    };
  }

  /// Creates a copy of this [ChartStyleConfig] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  ChartStyleConfig copyWith({
    String? backgroundColor,
    String? gridColor,
    String? axisColor,
    String? fontFamily,
    double? fontSize,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
  }) {
    return ChartStyleConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      axisColor: axisColor ?? this.axisColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
    );
  }

  @override
  List<Object?> get props => [
        backgroundColor,
        gridColor,
        axisColor,
        fontFamily,
        fontSize,
        paddingTop,
        paddingBottom,
        paddingLeft,
        paddingRight,
      ];

  @override
  String toString() =>
      'ChartStyleConfig(backgroundColor: $backgroundColor, fontFamily: $fontFamily)';
}
