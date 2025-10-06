# Data Model: Chart Types

**Feature**: Chart Types (Layer 4)  
**Date**: 2025-10-06  
**Status**: Complete

---

## Model Overview

This document defines all data structures for the Chart Types feature. All entities are immutable with `copyWith()` methods for updates. Validation occurs in constructors with clear error messages.

---

## 1. Line Chart Models

### LineChartConfig

**Purpose**: Configuration for line chart rendering

**Fields**:
```dart
class LineChartConfig {
  /// Line style (straight, smooth bezier, stepped)
  final LineStyle lineStyle;
  
  /// Marker shape (circle, square, triangle, diamond, cross, plus, none)
  final MarkerShape markerShape;
  
  /// Marker size in logical pixels
  final double markerSize;
  
  /// Whether to show markers (if false, markerShape ignored)
  final bool showMarkers;
  
  /// Line width in logical pixels
  final double lineWidth;
  
  /// Line dash pattern (null = solid line)
  final List<double>? dashPattern;
  
  /// Whether to connect null values (false = break line at nulls)
  final bool connectNulls;
}
```

**Validation Rules**:
- `markerSize > 0` (must be positive)
- `lineWidth > 0` (must be positive)
- `dashPattern == null || dashPattern.length.isEven` (dash pattern needs on/off pairs)

**Relationships**:
- Used by `LineChartLayer`
- Inherits theme defaults from `SeriesTheme`
- Can be overridden per series

---

### LineStyle

**Purpose**: Enum for line rendering styles

**Values**:
```dart
enum LineStyle {
  /// Linear interpolation between points
  straight,
  
  /// Catmull-Rom spline converted to cubic bezier curves
  smooth,
  
  /// Constant value interpolation (horizontal then vertical)
  stepped,
}
```

---

### MarkerShape

**Purpose**: Enum for data point marker shapes (shared with scatter chart)

**Values**:
```dart
enum MarkerShape {
  circle,    // Filled circle
  square,    // Filled square
  triangle,  // Equilateral triangle pointing up
  diamond,   // 45-degree rotated square
  cross,     // Plus sign rotated 45 degrees
  plus,      // Vertical and horizontal lines
  none,      // No marker (line only)
}
```

---

## 2. Area Chart Models

### AreaChartConfig

**Purpose**: Configuration for area chart rendering

**Fields**:
```dart
class AreaChartConfig {
  /// Fill style (solid, gradient, pattern)
  final AreaFillStyle fillStyle;
  
  /// Baseline configuration
  final AreaBaseline baseline;
  
  /// Whether to stack multiple series
  final bool stacked;
  
  /// Fill opacity (0.0 = transparent, 1.0 = opaque)
  final double fillOpacity;
  
  /// Whether to draw line on top of fill
  final bool showLine;
  
  /// Line configuration (if showLine is true)
  final LineChartConfig? lineConfig;
}
```

**Validation Rules**:
- `fillOpacity >= 0.0 && fillOpacity <= 1.0` (valid opacity range)
- `showLine == true implies lineConfig != null` (need line config if showing line)
- `stacked == true implies all series have same X coordinates` (required for stacking)

**Relationships**:
- Used by `AreaChartLayer`
- Optionally contains `LineChartConfig` for line overlay
- Inherits fill colors from `SeriesTheme`

---

### AreaFillStyle

**Purpose**: Enum for area fill rendering styles

**Values**:
```dart
enum AreaFillStyle {
  /// Solid color fill
  solid,
  
  /// Linear gradient (vertical interpolation by default)
  gradient,
  
  /// Custom pattern (future extension)
  pattern,
}
```

---

### AreaBaseline

**Purpose**: Configuration for area chart baseline

**Fields**:
```dart
class AreaBaseline {
  /// Baseline type
  final AreaBaselineType type;
  
  /// Fixed Y value (used when type is fixed)
  final double? fixedValue;
  
  /// Series ID to use as baseline (used when type is series)
  final String? seriesId;
}
```

**Validation Rules**:
- `type == AreaBaselineType.fixed implies fixedValue != null`
- `type == AreaBaselineType.series implies seriesId != null`

**Values**:
```dart
enum AreaBaselineType {
  /// Y = 0 baseline
  zero,
  
  /// Fixed Y value
  fixed,
  
  /// Another series as baseline
  series,
}
```

---

## 3. Bar Chart Models

### BarChartConfig

**Purpose**: Configuration for bar chart rendering

**Fields**:
```dart
class BarChartConfig {
  /// Chart orientation (vertical columns or horizontal bars)
  final BarOrientation orientation;
  
  /// Grouping mode (grouped side-by-side or stacked)
  final BarGroupingMode groupingMode;
  
  /// Bar width as percentage of category width (0.0 to 1.0)
  final double barWidthRatio;
  
  /// Spacing between bars in a group (logical pixels)
  final double barSpacing;
  
  /// Spacing between groups (logical pixels)
  final double groupSpacing;
  
  /// Corner radius for rounded corners (0 = sharp corners)
  final double cornerRadius;
  
  /// Border width (0 = no border)
  final double borderWidth;
  
  /// Border color (null = use series color)
  final Color? borderColor;
  
  /// Whether to apply gradient fill
  final bool useGradient;
  
  /// Gradient start color (null = use series color)
  final Color? gradientStart;
  
  /// Gradient end color (null = lighter series color)
  final Color? gradientEnd;
}
```

**Validation Rules**:
- `barWidthRatio > 0.0 && barWidthRatio <= 1.0` (valid percentage)
- `barSpacing >= 0.0` (non-negative)
- `groupSpacing >= 0.0` (non-negative)
- `cornerRadius >= 0.0` (non-negative)
- `borderWidth >= 0.0` (non-negative)
- `useGradient == true implies gradientStart != null || gradientEnd != null`

**Relationships**:
- Used by `BarChartLayer`
- Inherits bar colors from `SeriesTheme`

---

### BarOrientation

**Purpose**: Enum for bar chart orientation

**Values**:
```dart
enum BarOrientation {
  /// Vertical bars (column chart)
  vertical,
  
  /// Horizontal bars
  horizontal,
}
```

---

### BarGroupingMode

**Purpose**: Enum for multi-series bar grouping

**Values**:
```dart
enum BarGroupingMode {
  /// Bars side-by-side (compare same category across series)
  grouped,
  
  /// Bars stacked vertically (show total and composition)
  stacked,
}
```

---

## 4. Scatter Chart Models

### ScatterChartConfig

**Purpose**: Configuration for scatter plot rendering

**Fields**:
```dart
class ScatterChartConfig {
  /// Marker shape (circle, square, triangle, diamond, cross, plus)
  final MarkerShape markerShape;
  
  /// Marker sizing mode
  final MarkerSizingMode sizingMode;
  
  /// Fixed marker size (used when sizingMode is fixed)
  final double? fixedSize;
  
  /// Minimum marker size (used when sizingMode is dataDriven)
  final double? minSize;
  
  /// Maximum marker size (used when sizingMode is dataDriven)
  final double? maxSize;
  
  /// Marker style (filled, outlined, both)
  final MarkerStyle markerStyle;
  
  /// Border width for outlined markers
  final double borderWidth;
  
  /// Whether to enable clustering for dense data
  final bool enableClustering;
  
  /// Cluster threshold (min points to form cluster)
  final int clusterThreshold;
}
```

**Validation Rules**:
- `sizingMode == MarkerSizingMode.fixed implies fixedSize != null && fixedSize > 0`
- `sizingMode == MarkerSizingMode.dataDriven implies minSize != null && maxSize != null && minSize < maxSize`
- `borderWidth >= 0.0`
- `clusterThreshold >= 2` (need at least 2 points to cluster)

**Relationships**:
- Used by `ScatterChartLayer`
- Shares `MarkerShape` enum with line charts
- Inherits marker colors from `SeriesTheme`

---

### MarkerSizingMode

**Purpose**: Enum for marker size determination

**Values**:
```dart
enum MarkerSizingMode {
  /// All markers same size (use fixedSize)
  fixed,
  
  /// Marker size represents third variable (use minSize/maxSize)
  /// Size determined by ChartDataPoint.metadata['size']
  dataDriven,
}
```

---

### MarkerStyle

**Purpose**: Enum for marker rendering style

**Values**:
```dart
enum MarkerStyle {
  /// Filled marker with series color
  filled,
  
  /// Outlined marker with border color
  outlined,
  
  /// Both filled and outlined
  both,
}
```

---

## 5. Common Models

### ChartAnimationConfig

**Purpose**: Configuration for data update animations (shared across all chart types)

**Fields**:
```dart
class ChartAnimationConfig {
  /// Whether animations are enabled
  final bool enabled;
  
  /// Animation duration
  final Duration duration;
  
  /// Animation easing curve
  final Curve curve;
  
  /// Minimum change threshold to trigger animation (prevent micro-updates)
  final double changeThreshold;
}
```

**Validation Rules**:
- `duration.inMilliseconds >= 0` (non-negative)
- `changeThreshold >= 0.0` (non-negative)

**Defaults** (from `AnimationTheme`):
- `enabled = true`
- `duration = Duration(milliseconds: 300)`
- `curve = Curves.easeInOut`
- `changeThreshold = 0.01` (1% change)

---

### ChartSeriesStyle

**Purpose**: Per-series style overrides (optional, defaults from theme)

**Fields**:
```dart
class ChartSeriesStyle {
  /// Override color (null = use theme color)
  final Color? color;
  
  /// Override line width (null = use theme width)
  final double? lineWidth;
  
  /// Override marker size (null = use config default)
  final double? markerSize;
  
  /// Override fill opacity (area charts only)
  final double? fillOpacity;
  
  /// Override bar width ratio (bar charts only)
  final double? barWidthRatio;
}
```

**Validation Rules**:
- `lineWidth == null || lineWidth > 0`
- `markerSize == null || markerSize > 0`
- `fillOpacity == null || (fillOpacity >= 0.0 && fillOpacity <= 1.0)`
- `barWidthRatio == null || (barWidthRatio > 0.0 && barWidthRatio <= 1.0)`

**Relationships**:
- Attached to `ChartSeries` via `series.style` property
- Overrides theme defaults when non-null

---

## 6. Internal Models (not exposed in public API)

### InterpolatedPoint

**Purpose**: Intermediate point during smooth line interpolation

**Fields**:
```dart
class InterpolatedPoint {
  final Offset position;
  final Offset controlPoint1;  // First bezier control point
  final Offset controlPoint2;  // Second bezier control point
  final bool isControlPoint;   // True if this is a control point, false if data point
}
```

**Usage**: Internal to `LineInterpolator` for bezier curve generation

---

### BarLayoutInfo

**Purpose**: Calculated bar positions and dimensions

**Fields**:
```dart
class BarLayoutInfo {
  final String seriesId;
  final int categoryIndex;
  final Rect bounds;           // Bar rectangle in screen coordinates
  final double value;          // Original data value
  final bool isNegative;       // True if value < 0
}
```

**Usage**: Internal to `BarPositioner` for rendering

---

### ClusterInfo

**Purpose**: Information about a clustered group of points (scatter chart)

**Fields**:
```dart
class ClusterInfo {
  final Offset center;              // Cluster center position
  final int pointCount;             // Number of points in cluster
  final List<int> pointIndices;    // Indices of clustered points
  final double radius;              // Cluster radius (visual indicator)
}
```

**Usage**: Internal to `ScatterClusterer` for dense data visualization

---

## State Transitions

### Chart Data Updates

```
Initial State: Empty chart (no data)
    ↓
    | setData(series)
    ↓
Rendering State: Chart displaying current data
    ↓
    | updateData(newSeries)
    ↓
Animating State: Lerp between old and new data (if animations enabled)
    ↓
    | Animation completes
    ↓
Rendering State: Chart displaying new data
```

**Invariants**:
- Chart always renders valid data (validation in constructor)
- Animation progress always in range [0.0, 1.0]
- Viewport always contains valid bounds (width > 0, height > 0)

---

## Validation Summary

All models enforce validation rules in constructors:

```dart
class LineChartConfig {
  LineChartConfig({
    required this.lineStyle,
    required this.markerShape,
    required this.markerSize,
    required this.showMarkers,
    required this.lineWidth,
    this.dashPattern,
    this.connectNulls = false,
  }) {
    if (markerSize <= 0) {
      throw ArgumentError('markerSize must be positive');
    }
    if (lineWidth <= 0) {
      throw ArgumentError('lineWidth must be positive');
    }
    if (dashPattern != null && dashPattern.length.isOdd) {
      throw ArgumentError('dashPattern must have even length (on/off pairs)');
    }
  }
  
  // copyWith() method for immutability
  LineChartConfig copyWith({
    LineStyle? lineStyle,
    MarkerShape? markerShape,
    double? markerSize,
    bool? showMarkers,
    double? lineWidth,
    List<double>? dashPattern,
    bool? connectNulls,
  }) {
    return LineChartConfig(
      lineStyle: lineStyle ?? this.lineStyle,
      markerShape: markerShape ?? this.markerShape,
      markerSize: markerSize ?? this.markerSize,
      showMarkers: showMarkers ?? this.showMarkers,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      connectNulls: connectNulls ?? this.connectNulls,
    );
  }
}
```

---

## Default Values

All configs have sensible defaults (typically from theme):

- **LineChartConfig**: `lineStyle = straight`, `markerShape = circle`, `markerSize = 6.0`, `showMarkers = true`, `lineWidth = 2.0`
- **AreaChartConfig**: `fillStyle = solid`, `baseline = zero`, `stacked = false`, `fillOpacity = 0.3`, `showLine = true`
- **BarChartConfig**: `orientation = vertical`, `groupingMode = grouped`, `barWidthRatio = 0.8`, `barSpacing = 4.0`, `groupSpacing = 16.0`, `cornerRadius = 0.0`
- **ScatterChartConfig**: `markerShape = circle`, `sizingMode = fixed`, `fixedSize = 6.0`, `markerStyle = filled`, `enableClustering = false`

---

## Summary

**Total Models**: 
- 4 main config classes (Line, Area, Bar, Scatter)
- 7 enums (LineStyle, MarkerShape, AreaFillStyle, AreaBaselineType, BarOrientation, BarGroupingMode, MarkerSizingMode, MarkerStyle)
- 4 supporting classes (AreaBaseline, ChartAnimationConfig, ChartSeriesStyle)
- 3 internal classes (InterpolatedPoint, BarLayoutInfo, ClusterInfo)

All models are immutable, validated, and documented. Ready for contract generation.
