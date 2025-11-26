// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'package:flutter/painting.dart';

import '../../models/annotation_style.dart';
import '../styles/label_style.dart';
import 'series_theme.dart'; // For MarkerShape enum

/// Theming for chart annotations with state-based styling.
///
/// Provides default styling for all 5 annotation types:
/// - Point annotations (markers on data points)
/// - Range annotations (highlighted regions)
/// - Text annotations (labels/titles)
/// - Threshold annotations (horizontal/vertical lines)
/// - Trend annotations (trend lines/regression)
///
/// Each annotation type has state-specific styling:
/// - Normal: Default appearance
/// - Selected: When clicked/focused
/// - Hovered: When mouse is over annotation
/// - Dragging: While being dragged
/// - Ghost: Original position during drag
/// - Preview: Target position during drag
///
/// Example:
/// ```dart
/// final theme = AnnotationTheme(
///   pointDefaults: PointAnnotationDefaults(
///     markerShape: MarkerShape.circle,
///     markerSize: 8.0,
///     normalColor: Colors.blue,
///     selectedColor: Colors.blue.withOpacity(1.0),
///     hoveredColor: Colors.blue.withOpacity(0.7),
///   ),
/// );
/// ```
class AnnotationTheme {
  const AnnotationTheme({
    required this.pointDefaults,
    required this.rangeDefaults,
    required this.textDefaults,
    required this.thresholdDefaults,
    required this.trendDefaults,
  });

  /// Default styling for point annotations.
  final PointAnnotationDefaults pointDefaults;

  /// Default styling for range annotations.
  final RangeAnnotationDefaults rangeDefaults;

  /// Default styling for text annotations.
  final TextAnnotationDefaults textDefaults;

  /// Default styling for threshold annotations.
  final ThresholdAnnotationDefaults thresholdDefaults;

  /// Default styling for trend annotations.
  final TrendAnnotationDefaults trendDefaults;

  // ========== Predefined Themes ==========

  static const AnnotationTheme defaultLight = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.defaultLight,
    rangeDefaults: RangeAnnotationDefaults.defaultLight,
    textDefaults: TextAnnotationDefaults.defaultLight,
    thresholdDefaults: ThresholdAnnotationDefaults.defaultLight,
    trendDefaults: TrendAnnotationDefaults.defaultLight,
  );

  static const AnnotationTheme defaultDark = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.defaultDark,
    rangeDefaults: RangeAnnotationDefaults.defaultDark,
    textDefaults: TextAnnotationDefaults.defaultDark,
    thresholdDefaults: ThresholdAnnotationDefaults.defaultDark,
    trendDefaults: TrendAnnotationDefaults.defaultDark,
  );

  static const AnnotationTheme corporateBlue = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.corporateBlue,
    rangeDefaults: RangeAnnotationDefaults.corporateBlue,
    textDefaults: TextAnnotationDefaults.corporateBlue,
    thresholdDefaults: ThresholdAnnotationDefaults.corporateBlue,
    trendDefaults: TrendAnnotationDefaults.corporateBlue,
  );

  static const AnnotationTheme vibrant = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.vibrant,
    rangeDefaults: RangeAnnotationDefaults.vibrant,
    textDefaults: TextAnnotationDefaults.vibrant,
    thresholdDefaults: ThresholdAnnotationDefaults.vibrant,
    trendDefaults: TrendAnnotationDefaults.vibrant,
  );

  static const AnnotationTheme minimal = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.minimal,
    rangeDefaults: RangeAnnotationDefaults.minimal,
    textDefaults: TextAnnotationDefaults.minimal,
    thresholdDefaults: ThresholdAnnotationDefaults.minimal,
    trendDefaults: TrendAnnotationDefaults.minimal,
  );

  static const AnnotationTheme highContrast = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.highContrast,
    rangeDefaults: RangeAnnotationDefaults.highContrast,
    textDefaults: TextAnnotationDefaults.highContrast,
    thresholdDefaults: ThresholdAnnotationDefaults.highContrast,
    trendDefaults: TrendAnnotationDefaults.highContrast,
  );

  static const AnnotationTheme colorblindFriendly = AnnotationTheme(
    pointDefaults: PointAnnotationDefaults.colorblindFriendly,
    rangeDefaults: RangeAnnotationDefaults.colorblindFriendly,
    textDefaults: TextAnnotationDefaults.colorblindFriendly,
    thresholdDefaults: ThresholdAnnotationDefaults.colorblindFriendly,
    trendDefaults: TrendAnnotationDefaults.colorblindFriendly,
  );

  // ========== Methods ==========

  AnnotationTheme copyWith({
    PointAnnotationDefaults? pointDefaults,
    RangeAnnotationDefaults? rangeDefaults,
    TextAnnotationDefaults? textDefaults,
    ThresholdAnnotationDefaults? thresholdDefaults,
    TrendAnnotationDefaults? trendDefaults,
  }) {
    return AnnotationTheme(
      pointDefaults: pointDefaults ?? this.pointDefaults,
      rangeDefaults: rangeDefaults ?? this.rangeDefaults,
      textDefaults: textDefaults ?? this.textDefaults,
      thresholdDefaults: thresholdDefaults ?? this.thresholdDefaults,
      trendDefaults: trendDefaults ?? this.trendDefaults,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnotationTheme &&
        pointDefaults == other.pointDefaults &&
        rangeDefaults == other.rangeDefaults &&
        textDefaults == other.textDefaults &&
        thresholdDefaults == other.thresholdDefaults &&
        trendDefaults == other.trendDefaults;
  }

  @override
  int get hashCode => Object.hash(
        pointDefaults,
        rangeDefaults,
        textDefaults,
        thresholdDefaults,
        trendDefaults,
      );
}

/// Default styling for point annotations with state-based colors.
class PointAnnotationDefaults {
  const PointAnnotationDefaults({
    required this.markerShape,
    required this.markerSize,
    required this.normalColor,
    required this.selectedColor,
    required this.hoveredColor,
    required this.draggingColor,
    required this.ghostOpacity,
    required this.previewOpacity,
    required this.previewScale,
    required this.labelStyle,
  });

  final MarkerShape markerShape;
  final double markerSize;
  final Color normalColor;
  final Color selectedColor;
  final Color hoveredColor;
  final Color draggingColor;
  final double ghostOpacity;
  final double previewOpacity;
  final double previewScale;
  final LabelStyle labelStyle;

  static const PointAnnotationDefaults defaultLight = PointAnnotationDefaults(
    markerShape: MarkerShape.circle,
    markerSize: 8.0,
    normalColor: Color(0xFF2196F3), // Blue
    selectedColor: Color(0xFF1976D2), // Darker blue
    hoveredColor: Color(0xFF64B5F6), // Light blue
    draggingColor: Color(0xFF1976D2),
    ghostOpacity: 0.3,
    previewOpacity: 0.8,
    previewScale: 1.2,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF212121),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xF0FFFFFF), // 94% white
      borderColor: Color(0xFF2196F3),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const PointAnnotationDefaults defaultDark = PointAnnotationDefaults(
    markerShape: MarkerShape.circle,
    markerSize: 8.0,
    normalColor: Color(0xFF64B5F6), // Light blue
    selectedColor: Color(0xFF90CAF9), // Lighter blue
    hoveredColor: Color(0xFF42A5F5),
    draggingColor: Color(0xFF90CAF9),
    ghostOpacity: 0.3,
    previewOpacity: 0.8,
    previewScale: 1.2,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xE6212121), // 90% dark grey
      borderColor: Color(0xFF64B5F6),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const PointAnnotationDefaults corporateBlue = PointAnnotationDefaults(
    markerShape: MarkerShape.square,
    markerSize: 8.0,
    normalColor: Color(0xFF1976D2), // Corporate blue
    selectedColor: Color(0xFF1565C0),
    hoveredColor: Color(0xFF2196F3),
    draggingColor: Color(0xFF1565C0),
    ghostOpacity: 0.3,
    previewOpacity: 0.8,
    previewScale: 1.2,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Arial',
        color: Color(0xFF1565C0),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF1976D2),
      borderWidth: 0.5,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const PointAnnotationDefaults vibrant = PointAnnotationDefaults(
    markerShape: MarkerShape.star,
    markerSize: 10.0,
    normalColor: Color(0xFFE91E63), // Pink
    selectedColor: Color(0xFFC2185B),
    hoveredColor: Color(0xFFF06292),
    draggingColor: Color(0xFFC2185B),
    ghostOpacity: 0.3,
    previewOpacity: 0.9,
    previewScale: 1.3,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 13.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF880E4F),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFE91E63),
      borderWidth: 0.5,
      borderRadius: 6.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const PointAnnotationDefaults minimal = PointAnnotationDefaults(
    markerShape: MarkerShape.circle,
    markerSize: 6.0,
    normalColor: Color(0xFF757575), // Grey
    selectedColor: Color(0xFF616161),
    hoveredColor: Color(0xFF9E9E9E),
    draggingColor: Color(0xFF616161),
    ghostOpacity: 0.2,
    previewOpacity: 0.7,
    previewScale: 1.1,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 11.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF424242),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xF5F5F5F5), // 96% grey
      borderColor: Color(0xFF757575),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const PointAnnotationDefaults highContrast = PointAnnotationDefaults(
    markerShape: MarkerShape.square,
    markerSize: 12.0,
    normalColor: Color(0xFFFF0000), // Red
    selectedColor: Color(0xFFD32F2F),
    hoveredColor: Color(0xFFFF5252),
    draggingColor: Color(0xFFD32F2F),
    ghostOpacity: 0.4,
    previewOpacity: 1.0,
    previewScale: 1.4,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Arial',
        color: Color(0xFF000000),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFFFF0000),
      borderWidth: 1.0,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const PointAnnotationDefaults colorblindFriendly = PointAnnotationDefaults(
    markerShape: MarkerShape.diamond,
    markerSize: 9.0,
    normalColor: Color(0xFF0173B2), // Blue (Okabe-Ito)
    selectedColor: Color(0xFF005A8C),
    hoveredColor: Color(0xFF3399CC),
    draggingColor: Color(0xFF005A8C),
    ghostOpacity: 0.3,
    previewOpacity: 0.8,
    previewScale: 1.2,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF000000),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF0173B2),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  PointAnnotationDefaults copyWith({
    MarkerShape? markerShape,
    double? markerSize,
    Color? normalColor,
    Color? selectedColor,
    Color? hoveredColor,
    Color? draggingColor,
    double? ghostOpacity,
    double? previewOpacity,
    double? previewScale,
    LabelStyle? labelStyle,
  }) {
    return PointAnnotationDefaults(
      markerShape: markerShape ?? this.markerShape,
      markerSize: markerSize ?? this.markerSize,
      normalColor: normalColor ?? this.normalColor,
      selectedColor: selectedColor ?? this.selectedColor,
      hoveredColor: hoveredColor ?? this.hoveredColor,
      draggingColor: draggingColor ?? this.draggingColor,
      ghostOpacity: ghostOpacity ?? this.ghostOpacity,
      previewOpacity: previewOpacity ?? this.previewOpacity,
      previewScale: previewScale ?? this.previewScale,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PointAnnotationDefaults &&
        markerShape == other.markerShape &&
        markerSize == other.markerSize &&
        normalColor == other.normalColor &&
        selectedColor == other.selectedColor &&
        hoveredColor == other.hoveredColor &&
        draggingColor == other.draggingColor &&
        ghostOpacity == other.ghostOpacity &&
        previewOpacity == other.previewOpacity &&
        previewScale == other.previewScale &&
        labelStyle == other.labelStyle;
  }

  @override
  int get hashCode => Object.hash(
        markerShape,
        markerSize,
        normalColor,
        selectedColor,
        hoveredColor,
        draggingColor,
        ghostOpacity,
        previewOpacity,
        previewScale,
        labelStyle,
      );
}

/// Default styling for range annotations with state-based colors.
class RangeAnnotationDefaults {
  const RangeAnnotationDefaults({
    required this.normalFillColor,
    required this.selectedFillColor,
    required this.hoveredFillColor,
    required this.draggingFillColor,
    required this.normalBorderColor,
    required this.selectedBorderColor,
    required this.hoveredBorderColor,
    required this.draggingBorderColor,
    required this.borderWidth,
    required this.labelStyle,
  });

  final Color normalFillColor;
  final Color selectedFillColor;
  final Color hoveredFillColor;
  final Color draggingFillColor;
  final Color normalBorderColor;
  final Color selectedBorderColor;
  final Color hoveredBorderColor;
  final Color draggingBorderColor;
  final double borderWidth;
  final LabelStyle labelStyle;

  /// Convert theme defaults to AnnotationStyle for label styling
  AnnotationStyle toAnnotationStyle({Color? borderColor}) {
    return AnnotationStyle(
      textStyle: labelStyle.textStyle,
      backgroundColor: labelStyle.backgroundColor,
      borderColor: borderColor ?? normalBorderColor,
      borderWidth: labelStyle.borderWidth,
      borderRadius: BorderRadius.circular(labelStyle.borderRadius),
      padding: labelStyle.padding,
    );
  }

  static const RangeAnnotationDefaults defaultLight = RangeAnnotationDefaults(
    normalFillColor: Color(0x332196F3), // 20% blue
    selectedFillColor: Color(0x4D2196F3), // 30% blue
    hoveredFillColor: Color(0x4064B5F6), // 25% light blue
    draggingFillColor: Color(0x4D1976D2), // 30% darker blue
    normalBorderColor: Color(0xFF2196F3),
    selectedBorderColor: Color(0xFF1976D2),
    hoveredBorderColor: Color(0xFF64B5F6),
    draggingBorderColor: Color(0xFF1976D2),
    borderWidth: 1.5,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF212121),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF2196F3),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const RangeAnnotationDefaults defaultDark = RangeAnnotationDefaults(
    normalFillColor: Color(0x3364B5F6), // 20% light blue
    selectedFillColor: Color(0x4D64B5F6), // 30% light blue
    hoveredFillColor: Color(0x4090CAF9), // 25% lighter blue
    draggingFillColor: Color(0x4D90CAF9), // 30% lighter blue
    normalBorderColor: Color(0xFF64B5F6),
    selectedBorderColor: Color(0xFF90CAF9),
    hoveredBorderColor: Color(0xFF42A5F5),
    draggingBorderColor: Color(0xFF90CAF9),
    borderWidth: 1.5,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xE6212121),
      borderColor: Color(0xFF64B5F6),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const RangeAnnotationDefaults corporateBlue = RangeAnnotationDefaults(
    normalFillColor: Color(0x331976D2), // 20% corporate blue
    selectedFillColor: Color(0x4D1976D2), // 30% corporate blue
    hoveredFillColor: Color(0x402196F3), // 25% blue
    draggingFillColor: Color(0x4D1565C0), // 30% darker blue
    normalBorderColor: Color(0xFF1976D2),
    selectedBorderColor: Color(0xFF1565C0),
    hoveredBorderColor: Color(0xFF2196F3),
    draggingBorderColor: Color(0xFF1565C0),
    borderWidth: 2.0,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Arial',
        color: Color(0xFF1565C0),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF1976D2),
      borderWidth: 0.5,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const RangeAnnotationDefaults vibrant = RangeAnnotationDefaults(
    normalFillColor: Color(0x33E91E63), // 20% pink
    selectedFillColor: Color(0x4DE91E63), // 30% pink
    hoveredFillColor: Color(0x40F06292), // 25% light pink
    draggingFillColor: Color(0x4DC2185B), // 30% darker pink
    normalBorderColor: Color(0xFFE91E63),
    selectedBorderColor: Color(0xFFC2185B),
    hoveredBorderColor: Color(0xFFF06292),
    draggingBorderColor: Color(0xFFC2185B),
    borderWidth: 2.5,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 13.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF880E4F),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFE91E63),
      borderWidth: 0.5,
      borderRadius: 6.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const RangeAnnotationDefaults minimal = RangeAnnotationDefaults(
    normalFillColor: Color(0x1A757575), // 10% grey
    selectedFillColor: Color(0x33757575), // 20% grey
    hoveredFillColor: Color(0x269E9E9E), // 15% light grey
    draggingFillColor: Color(0x33616161), // 20% dark grey
    normalBorderColor: Color(0xFF757575),
    selectedBorderColor: Color(0xFF616161),
    hoveredBorderColor: Color(0xFF9E9E9E),
    draggingBorderColor: Color(0xFF616161),
    borderWidth: 1.0,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 11.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF424242),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xF5F5F5F5),
      borderColor: Color(0xFF757575),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const RangeAnnotationDefaults highContrast = RangeAnnotationDefaults(
    normalFillColor: Color(0x4DFFFF00), // 30% yellow
    selectedFillColor: Color(0x80FFFF00), // 50% yellow
    hoveredFillColor: Color(0x66FFFF00), // 40% yellow
    draggingFillColor: Color(0x80FFFF00), // 50% yellow
    normalBorderColor: Color(0xFF000000),
    selectedBorderColor: Color(0xFFFF0000),
    hoveredBorderColor: Color(0xFF0000FF),
    draggingBorderColor: Color(0xFFFF0000),
    borderWidth: 3.0,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Arial',
        color: Color(0xFF000000),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFF000000),
      borderWidth: 1.0,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const RangeAnnotationDefaults colorblindFriendly = RangeAnnotationDefaults(
    normalFillColor: Color(0x33DE8F05), // 20% orange (Okabe-Ito)
    selectedFillColor: Color(0x4DDE8F05), // 30% orange
    hoveredFillColor: Color(0x40F0A030), // 25% light orange
    draggingFillColor: Color(0x4DC07004), // 30% darker orange
    normalBorderColor: Color(0xFFDE8F05),
    selectedBorderColor: Color(0xFFC07004),
    hoveredBorderColor: Color(0xFFF0A030),
    draggingBorderColor: Color(0xFFC07004),
    borderWidth: 2.0,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF000000),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFDE8F05),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  RangeAnnotationDefaults copyWith({
    Color? normalFillColor,
    Color? selectedFillColor,
    Color? hoveredFillColor,
    Color? draggingFillColor,
    Color? normalBorderColor,
    Color? selectedBorderColor,
    Color? hoveredBorderColor,
    Color? draggingBorderColor,
    double? borderWidth,
    LabelStyle? labelStyle,
  }) {
    return RangeAnnotationDefaults(
      normalFillColor: normalFillColor ?? this.normalFillColor,
      selectedFillColor: selectedFillColor ?? this.selectedFillColor,
      hoveredFillColor: hoveredFillColor ?? this.hoveredFillColor,
      draggingFillColor: draggingFillColor ?? this.draggingFillColor,
      normalBorderColor: normalBorderColor ?? this.normalBorderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      hoveredBorderColor: hoveredBorderColor ?? this.hoveredBorderColor,
      draggingBorderColor: draggingBorderColor ?? this.draggingBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeAnnotationDefaults &&
        normalFillColor == other.normalFillColor &&
        selectedFillColor == other.selectedFillColor &&
        hoveredFillColor == other.hoveredFillColor &&
        draggingFillColor == other.draggingFillColor &&
        normalBorderColor == other.normalBorderColor &&
        selectedBorderColor == other.selectedBorderColor &&
        hoveredBorderColor == other.hoveredBorderColor &&
        draggingBorderColor == other.draggingBorderColor &&
        borderWidth == other.borderWidth &&
        labelStyle == other.labelStyle;
  }

  @override
  int get hashCode => Object.hash(
        normalFillColor,
        selectedFillColor,
        hoveredFillColor,
        draggingFillColor,
        normalBorderColor,
        selectedBorderColor,
        hoveredBorderColor,
        draggingBorderColor,
        borderWidth,
        labelStyle,
      );
}

/// Default styling for text annotations.
class TextAnnotationDefaults {
  const TextAnnotationDefaults({
    required this.textStyle,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
  });

  final TextStyle textStyle;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;

  /// Convert theme defaults to AnnotationStyle for use with annotations
  AnnotationStyle toAnnotationStyle() {
    return AnnotationStyle(
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: BorderRadius.circular(borderRadius),
      padding: padding,
    );
  }

  static const TextAnnotationDefaults defaultLight = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 14.0,
      fontFamily: 'Roboto',
      color: Color(0xFF212121),
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Color(0xF0FFFFFF),
    borderColor: Color(0xFFBDBDBD),
    borderWidth: 0.5,
    borderRadius: 4.0,
    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  );

  static const TextAnnotationDefaults defaultDark = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 14.0,
      fontFamily: 'Roboto',
      color: Color(0xFFFFFFFF),
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Color(0xE6212121),
    borderColor: Color(0xFF616161),
    borderWidth: 0.5,
    borderRadius: 4.0,
    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  );

  static const TextAnnotationDefaults corporateBlue = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 14.0,
      fontFamily: 'Arial',
      color: Color(0xFF1565C0),
      fontWeight: FontWeight.w600,
    ),
    backgroundColor: Color(0xF0FFFFFF),
    borderColor: Color(0xFF1976D2),
    borderWidth: 0.5,
    borderRadius: 4.0,
    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
  );

  static const TextAnnotationDefaults vibrant = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 15.0,
      fontFamily: 'Helvetica',
      color: Color(0xFF880E4F),
      fontWeight: FontWeight.bold,
    ),
    backgroundColor: Color(0xF0FFFFFF),
    borderColor: Color(0xFFE91E63),
    borderWidth: 0.5,
    borderRadius: 4.0,
    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
  );

  static const TextAnnotationDefaults minimal = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 12.0,
      fontFamily: 'Helvetica',
      color: Color(0xFF424242),
      fontWeight: FontWeight.normal,
    ),
    backgroundColor: Color(0xF5F5F5F5),
    borderColor: Color(0xFF9E9E9E),
    borderWidth: 0.5,
    borderRadius: 3.0,
    padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
  );

  static const TextAnnotationDefaults highContrast = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 16.0,
      fontFamily: 'Arial',
      color: Color(0xFF000000),
      fontWeight: FontWeight.bold,
    ),
    backgroundColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFF000000),
    borderWidth: 0.5,
    borderRadius: 4.0,
    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
  );

  static const TextAnnotationDefaults colorblindFriendly = TextAnnotationDefaults(
    textStyle: TextStyle(
      fontSize: 14.0,
      fontFamily: 'Roboto',
      color: Color(0xFF000000),
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Color(0xF0FFFFFF),
    borderColor: Color(0xFF0173B2),
    borderWidth: 0.5,
    borderRadius: 4.0,
    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  );

  TextAnnotationDefaults copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    EdgeInsets? padding,
  }) {
    return TextAnnotationDefaults(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextAnnotationDefaults &&
        textStyle == other.textStyle &&
        backgroundColor == other.backgroundColor &&
        borderColor == other.borderColor &&
        borderWidth == other.borderWidth &&
        borderRadius == other.borderRadius &&
        padding == other.padding;
  }

  @override
  int get hashCode => Object.hash(
        textStyle,
        backgroundColor,
        borderColor,
        borderWidth,
        borderRadius,
        padding,
      );
}

/// Default styling for threshold annotations (horizontal/vertical lines).
class ThresholdAnnotationDefaults {
  const ThresholdAnnotationDefaults({
    required this.lineColor,
    required this.lineWidth,
    required this.dashPattern,
    required this.labelStyle,
  });

  final Color lineColor;
  final double lineWidth;
  final List<double> dashPattern;
  final LabelStyle labelStyle;

  /// Convert theme defaults to AnnotationStyle for label styling
  AnnotationStyle toAnnotationStyle() {
    return AnnotationStyle(
      textStyle: labelStyle.textStyle,
      backgroundColor: labelStyle.backgroundColor,
      borderColor: lineColor,
      borderWidth: labelStyle.borderWidth,
      borderRadius: BorderRadius.circular(labelStyle.borderRadius),
      padding: labelStyle.padding,
    );
  }

  static const ThresholdAnnotationDefaults defaultLight = ThresholdAnnotationDefaults(
    lineColor: Color(0xFFF44336), // Red
    lineWidth: 2.0,
    dashPattern: [5.0, 3.0],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFFF44336),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFF44336),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const ThresholdAnnotationDefaults defaultDark = ThresholdAnnotationDefaults(
    lineColor: Color(0xFFEF5350), // Light red
    lineWidth: 2.0,
    dashPattern: [5.0, 3.0],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFFEF5350),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xE6212121),
      borderColor: Color(0xFFEF5350),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const ThresholdAnnotationDefaults corporateBlue = ThresholdAnnotationDefaults(
    lineColor: Color(0xFFD32F2F), // Dark red
    lineWidth: 2.5,
    dashPattern: [6.0, 3.0],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Arial',
        color: Color(0xFFD32F2F),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFD32F2F),
      borderWidth: 0.5,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const ThresholdAnnotationDefaults vibrant = ThresholdAnnotationDefaults(
    lineColor: Color(0xFFFF5722), // Deep orange
    lineWidth: 3.0,
    dashPattern: [8.0, 4.0],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 13.0,
        fontFamily: 'Helvetica',
        color: Color(0xFFBF360C),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFFF5722),
      borderWidth: 0.5,
      borderRadius: 6.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const ThresholdAnnotationDefaults minimal = ThresholdAnnotationDefaults(
    lineColor: Color(0xFF757575), // Grey
    lineWidth: 1.5,
    dashPattern: [4.0, 2.0],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 11.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF616161),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xF5F5F5F5),
      borderColor: Color(0xFF757575),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const ThresholdAnnotationDefaults highContrast = ThresholdAnnotationDefaults(
    lineColor: Color(0xFFFF0000), // Pure red
    lineWidth: 4.0,
    dashPattern: [],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Arial',
        color: Color(0xFF000000),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFFFF0000),
      borderWidth: 2.0,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const ThresholdAnnotationDefaults colorblindFriendly = ThresholdAnnotationDefaults(
    lineColor: Color(0xFFCC78BC), // Pink (Okabe-Ito)
    lineWidth: 2.5,
    dashPattern: [6.0, 3.0],
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF9C4B99),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFCC78BC),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  ThresholdAnnotationDefaults copyWith({
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    LabelStyle? labelStyle,
  }) {
    return ThresholdAnnotationDefaults(
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThresholdAnnotationDefaults &&
        lineColor == other.lineColor &&
        lineWidth == other.lineWidth &&
        _listEquals(dashPattern, other.dashPattern) &&
        labelStyle == other.labelStyle;
  }

  @override
  int get hashCode => Object.hash(
        lineColor,
        lineWidth,
        Object.hashAll(dashPattern),
        labelStyle,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Default styling for trend annotations (trend lines/regression).
class TrendAnnotationDefaults {
  const TrendAnnotationDefaults({
    required this.lineColor,
    required this.lineWidth,
    required this.dashPattern,
    required this.confidenceBandColor,
    required this.confidenceBandOpacity,
    required this.labelStyle,
  });

  final Color lineColor;
  final double lineWidth;
  final List<double> dashPattern;
  final Color confidenceBandColor;
  final double confidenceBandOpacity;
  final LabelStyle labelStyle;

  /// Convert theme defaults to AnnotationStyle for label styling
  AnnotationStyle toAnnotationStyle() {
    return AnnotationStyle(
      textStyle: labelStyle.textStyle,
      backgroundColor: labelStyle.backgroundColor,
      borderColor: lineColor,
      borderWidth: labelStyle.borderWidth,
      borderRadius: BorderRadius.circular(labelStyle.borderRadius),
      padding: labelStyle.padding,
    );
  }

  static const TrendAnnotationDefaults defaultLight = TrendAnnotationDefaults(
    lineColor: Color(0xFF4CAF50), // Green
    lineWidth: 2.0,
    dashPattern: [5.0, 5.0],
    confidenceBandColor: Color(0xFF4CAF50),
    confidenceBandOpacity: 0.1,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF2E7D32),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF4CAF50),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const TrendAnnotationDefaults defaultDark = TrendAnnotationDefaults(
    lineColor: Color(0xFF66BB6A), // Light green
    lineWidth: 2.0,
    dashPattern: [5.0, 5.0],
    confidenceBandColor: Color(0xFF66BB6A),
    confidenceBandOpacity: 0.1,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF81C784),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xE6212121),
      borderColor: Color(0xFF66BB6A),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const TrendAnnotationDefaults corporateBlue = TrendAnnotationDefaults(
    lineColor: Color(0xFF388E3C), // Dark green
    lineWidth: 2.5,
    dashPattern: [6.0, 4.0],
    confidenceBandColor: Color(0xFF388E3C),
    confidenceBandOpacity: 0.15,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Arial',
        color: Color(0xFF1B5E20),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF388E3C),
      borderWidth: 0.5,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const TrendAnnotationDefaults vibrant = TrendAnnotationDefaults(
    lineColor: Color(0xFFCDDC39), // Lime
    lineWidth: 3.0,
    dashPattern: [8.0, 4.0],
    confidenceBandColor: Color(0xFFCDDC39),
    confidenceBandOpacity: 0.2,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 13.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF827717),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFCDDC39),
      borderWidth: 0.5,
      borderRadius: 6.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const TrendAnnotationDefaults minimal = TrendAnnotationDefaults(
    lineColor: Color(0xFF9E9E9E), // Light grey
    lineWidth: 1.5,
    dashPattern: [4.0, 4.0],
    confidenceBandColor: Color(0xFF9E9E9E),
    confidenceBandOpacity: 0.05,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 11.0,
        fontFamily: 'Helvetica',
        color: Color(0xFF757575),
        fontWeight: FontWeight.normal,
      ),
      backgroundColor: Color(0xF5F5F5F5),
      borderColor: Color(0xFF9E9E9E),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const TrendAnnotationDefaults highContrast = TrendAnnotationDefaults(
    lineColor: Color(0xFF0000FF), // Blue
    lineWidth: 4.0,
    dashPattern: [],
    confidenceBandColor: Color(0xFF0000FF),
    confidenceBandOpacity: 0.3,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Arial',
        color: Color(0xFF000000),
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFF0000FF),
      borderWidth: 2.0,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  static const TrendAnnotationDefaults colorblindFriendly = TrendAnnotationDefaults(
    lineColor: Color(0xFF029E73), // Teal (Okabe-Ito)
    lineWidth: 2.5,
    dashPattern: [6.0, 4.0],
    confidenceBandColor: Color(0xFF029E73),
    confidenceBandOpacity: 0.15,
    labelStyle: LabelStyle(
      textStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        color: Color(0xFF017A5A),
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF029E73),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    ),
  );

  TrendAnnotationDefaults copyWith({
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    Color? confidenceBandColor,
    double? confidenceBandOpacity,
    LabelStyle? labelStyle,
  }) {
    return TrendAnnotationDefaults(
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      confidenceBandColor: confidenceBandColor ?? this.confidenceBandColor,
      confidenceBandOpacity: confidenceBandOpacity ?? this.confidenceBandOpacity,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendAnnotationDefaults &&
        lineColor == other.lineColor &&
        lineWidth == other.lineWidth &&
        _listEquals(dashPattern, other.dashPattern) &&
        confidenceBandColor == other.confidenceBandColor &&
        confidenceBandOpacity == other.confidenceBandOpacity &&
        labelStyle == other.labelStyle;
  }

  @override
  int get hashCode => Object.hash(
        lineColor,
        lineWidth,
        Object.hashAll(dashPattern),
        confidenceBandColor,
        confidenceBandOpacity,
        labelStyle,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
