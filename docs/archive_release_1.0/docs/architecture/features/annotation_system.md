# Annotation System - Detailed Feature Specification

## 📝 Overview

The Annotation System is the most sophisticated feature of Braven Charts, providing five distinct annotation types designed through user research and feedback. Each type serves a specific purpose in data analysis and storytelling.

## 🎯 Design Philosophy

### Core Principles
1. **Simplicity**: Each annotation type has a clear, distinct purpose
2. **Consistency**: Unified styling and interaction patterns
3. **Performance**: Optimized for large numbers of annotations
4. **Accessibility**: Full keyboard navigation and screen reader support
5. **Persistence**: Reliable save/restore across sessions

### User-Centered Design
The five annotation types were selected based on:
- User research with data analysts and business professionals
- Analysis of common data visualization needs
- Elimination of redundant and overlapping functionality
- Focus on high-value, frequently-used annotation patterns

## 📊 Five Core Annotation Types

### 1. Text Annotations 📍

**Purpose**: Free-floating text labels at arbitrary chart coordinates

#### Key Features
- **Positioning**: Any coordinate within chart area (data, screen, or percentage coordinates)
- **Free Movement**: Not tied to specific data points
- **In-Place Editing**: Click to edit text directly
- **Drag Repositioning**: Drag annotation to new location
- **No Snapping**: Maintains exact positioned coordinates

#### Technical Specifications
```dart
class TextAnnotation extends ChartAnnotation {
  final MarkerPosition position;        // Flexible positioning system
  final String text;                   // Display text
  final bool allowDragging;            // Enable/disable dragging
  final bool allowEditing;             // Enable/disable in-place editing
  final TextEditingMode editingMode;   // Single/multi-line editing
  
  // Style composition
  final MarkerStyle? markerStyle;      // Optional visual marker
  final TitleStyle titleStyle;         // Text container styling
  final TooltipStyle? tooltipStyle;    // Optional hover information
}

enum TextEditingMode {
  singleLine,    // Basic single-line text
  multiLine,     // Multi-line text with word wrap
  richText,      // Future: Rich text formatting
}
```

#### Use Cases
- **Chart Labels**: Custom labels for chart regions
- **Explanatory Notes**: Context and explanations
- **Titles and Headers**: Section headings within charts
- **Callouts**: Drawing attention to specific areas

#### Interaction Workflow
1. **Creation**: Click anywhere on chart to place text
2. **Editing**: Double-click or press Enter to edit in-place
3. **Moving**: Drag to reposition anywhere on chart
4. **Styling**: Right-click for style options

### 2. Point Annotations 📌

**Purpose**: Mark and annotate specific data points from chart series

#### Key Features
- **Data Point Association**: Always linked to actual data points
- **Automatic Snapping**: Snaps to nearest data point on creation
- **Data Context**: Full access to data point information
- **Dynamic Updates**: Moves with data point during updates
- **Zoom/Pan Stability**: Maintains position during chart transformations

#### Technical Specifications
```dart
class PointAnnotation extends ChartAnnotation {
  final String seriesId;               // Target data series
  final int dataPointIndex;            // Specific data point index
  final Offset visualOffset;           // Offset from data point
  final SnapBehavior snapBehavior;     // Update behavior
  final DataPointBinding binding;      // How annotation relates to data
  
  // Style composition
  final MarkerStyle markerStyle;       // Required visual marker
  final TitleStyle? titleStyle;        // Optional permanent text
  final TooltipStyle tooltipStyle;     // Hover/click information
}

enum SnapBehavior {
  stickToPoint,      // Move with data point updates
  stickToCoordinate, // Stay at original coordinate
  smartSnap,         // Re-snap to nearest point
}

class DataPointBinding {
  final bool includeValue;             // Show data value
  final bool includeSeriesName;        // Show series name
  final bool includeTimestamp;         // Show timestamp if available
  final bool includeMetadata;          // Show custom metadata
  final String? customLabel;           // Override default label
}
```

#### Use Cases
- **Data Highlights**: Marking significant data points
- **Outlier Identification**: Flagging unusual values
- **Milestone Markers**: Important events or achievements
- **Comparison Points**: Marking points for comparison

#### Interaction Workflow
1. **Creation**: Click near data point (auto-snaps to nearest)
2. **Information**: Hover for detailed tooltip
3. **Editing**: Right-click to modify text or styling
4. **Moving**: Drag to different data point (re-snaps)

### 3. Range Annotations 📊

**Purpose**: Highlight rectangular areas representing time periods, value ranges, or data clusters

#### Key Features
- **Flexible Creation**: Click-and-drag or corner specification
- **Resizing**: Corner and edge handles for adjustment
- **Vertical Reference Lines**: Optional full-height lines at X boundaries
- **Smart Text Positioning**: Automatic label placement
- **Viewport Handling**: Proper rendering when extending beyond view

#### Technical Specifications
```dart
class RangeAnnotation extends ChartAnnotation {
  final MarkerPosition startPosition;    // Top-left corner
  final MarkerPosition endPosition;      // Bottom-right corner
  final bool showVerticalLines;          // Reference lines feature
  final bool allowResizing;              // Enable resize handles
  final TextPositioning textPositioning; // Label placement strategy
  
  // Style composition
  final RangeStyle rangeStyle;           // Area fill and border
  final TitleStyle? titleStyle;          // Optional text label
  final ConnectorStyle? verticalLineStyle; // Reference line styling
}

class RangeStyle {
  final Color fillColor;                 // Interior color
  final double fillOpacity;              // Transparency (0.0-1.0)
  final Color borderColor;               // Border color
  final double borderWidth;              // Border thickness
  final BorderRadius? borderRadius;      // Rounded corners
  final List<double>? dashPattern;       // Dashed border
  final BlendMode? blendMode;            // Color blending mode
}

class VerticalReferenceLines {
  final bool enabled;                    // Show reference lines
  final Color lineColor;                 // Line color
  final double lineWidth;                // Line thickness
  final List<double>? dashPattern;       // Dash pattern
  final double opacity;                  // Line transparency
  final bool extendFullHeight;           // Span entire chart height
}
```

#### Use Cases
- **Time Periods**: Highlighting date/time ranges
- **Value Ranges**: Showing acceptable value ranges
- **Data Clusters**: Identifying grouped data
- **Event Periods**: Marking duration of events

#### Interaction Workflow
1. **Creation**: Click and drag to define rectangular area
2. **Resizing**: Drag corner/edge handles to adjust size
3. **Moving**: Drag interior to reposition entire range
4. **Reference Lines**: Toggle vertical lines in style options

### 4. Trend Line Annotations 📈

**Purpose**: User-created mathematical trend lines through anchor points

#### Key Features
- **Multiple Algorithms**: 6 mathematical trend line types
- **Interactive Creation**: Click to place 2-10 anchor points
- **Real-time Preview**: Show trend line during creation
- **Statistical Information**: R², equation, standard error
- **Extrapolation**: Extend beyond anchor points

#### Technical Specifications
```dart
class TrendLineAnnotation extends ChartAnnotation {
  final List<MarkerPosition> anchorPoints; // 2-10 anchor points
  final TrendLineType trendType;           // Mathematical model
  final bool showEquation;                 // Display equation
  final bool showRSquared;                 // Display R² value
  final bool showConfidenceBands;          // Statistical confidence
  final ExtrapolationConfig extrapolation; // Beyond anchor points
  
  // Style composition
  final MarkerStyle anchorMarkerStyle;     // Anchor point markers
  final LineStyle trendLineStyle;          // Trend line appearance
  final TitleStyle? equationStyle;         // Equation display
  final BandStyle? confidenceBandStyle;    // Confidence band styling
}

enum TrendLineType {
  linear,              // y = mx + b
  polynomial2,         // y = ax² + bx + c
  polynomial3,         // y = ax³ + bx² + cx + d
  exponential,         // y = ae^(bx)
  logarithmic,         // y = a ln(x) + b
  movingAverage,       // Configurable window size
}

class TrendLineCalculation {
  final List<double> coefficients;        // Mathematical coefficients
  final double rSquared;                  // Goodness of fit (0.0-1.0)
  final double standardError;             // Prediction accuracy
  final String equation;                  // Human-readable equation
  final List<double>? confidenceIntervals; // Statistical confidence
}
```

#### Mathematical Implementation
```dart
class TrendLineCalculator {
  static TrendLineResult calculateLinear(List<Point> points) {
    // Least squares linear regression
    final n = points.length;
    final sumX = points.fold(0.0, (sum, p) => sum + p.x);
    final sumY = points.fold(0.0, (sum, p) => sum + p.y);
    final sumXY = points.fold(0.0, (sum, p) => sum + p.x * p.y);
    final sumX2 = points.fold(0.0, (sum, p) => sum + p.x * p.x);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    final rSquared = _calculateRSquared(points, slope, intercept);
    final equation = 'y = ${slope.toStringAsFixed(3)}x + ${intercept.toStringAsFixed(3)}';
    
    return TrendLineResult(
      coefficients: [slope, intercept],
      rSquared: rSquared,
      equation: equation,
    );
  }
}
```

#### Use Cases
- **Data Analysis**: Understanding data patterns and trends
- **Forecasting**: Predicting future values
- **Performance Analysis**: Tracking progress over time
- **Correlation Studies**: Identifying relationships between variables

### 5. Series Selection Annotations 🎯

**Purpose**: Select and annotate segments of existing data series

#### Key Features
- **Multi-Series Support**: Select across different data series
- **Flexible Selection**: Click start/end points or drag selection
- **Visual Highlighting**: Distinctive styling for selected segments
- **Segment Information**: Automatic statistics for selected range
- **Zoom Persistence**: Maintain selection across zoom levels

#### Technical Specifications
```dart
class SeriesSelectionAnnotation extends ChartAnnotation {
  final List<SeriesSelection> selections;   // Multi-series support
  final SelectionMode mode;                 // How selection works
  final bool showStatistics;                // Display selection stats
  final bool allowExtension;                // Extend after creation
  
  // Style composition
  final SelectionStyle selectionStyle;      // Highlight styling
  final MarkerStyle boundaryMarkerStyle;    // Start/end markers
  final TitleStyle? titleStyle;             // Selection label
  final TooltipStyle? statisticsStyle;      // Statistics display
}

class SeriesSelection {
  final String seriesId;                    // Target series
  final int startIndex;                     // Start data point
  final int endIndex;                       // End data point
  final SelectionStatistics statistics;     // Calculated statistics
}

class SelectionStatistics {
  final double min;                         // Minimum value in selection
  final double max;                         // Maximum value in selection
  final double average;                     // Average value
  final double sum;                         // Sum of values
  final int count;                          // Number of data points
  final double standardDeviation;           // Statistical spread
  final double percentChange;               // Change from start to end
}

class SelectionStyle {
  final Color highlightColor;               // Selection overlay
  final double highlightOpacity;            // Transparency
  final double lineWidthMultiplier;         // Line thickness increase
  final SelectionPattern pattern;           // Visual pattern
  final bool showGradient;                  // Gradient highlight
}
```

#### Use Cases
- **Performance Analysis**: Analyzing specific time periods
- **Comparison Studies**: Comparing different segments
- **Trend Analysis**: Identifying patterns in segments
- **Quality Control**: Monitoring specific data ranges

## 🎨 Unified Styling System

### AnnotationStyle Architecture

All annotations use a composition-based styling system:

```dart
class AnnotationStyle {
  // Component styles (used as needed by each annotation type)
  final MarkerStyle? markerStyle;          // Visual markers
  final TitleStyle? titleStyle;            // Text displays
  final TooltipStyle? tooltipStyle;        // Hover information
  final RangeStyle? rangeStyle;            // Area fills
  final ConnectorStyle? connectorStyle;    // Connecting lines
  final SelectionStyle? selectionStyle;    // Selection highlights
  
  // Factory constructors for each annotation type
  factory AnnotationStyle.text({...}) => // Text-specific configuration
  factory AnnotationStyle.point({...}) => // Point-specific configuration  
  factory AnnotationStyle.range({...}) => // Range-specific configuration
  factory AnnotationStyle.trendLine({...}) => // Trend-specific configuration
  factory AnnotationStyle.seriesSelection({...}) => // Selection-specific configuration
}
```

### Theme Integration

```dart
class AnnotationTheme {
  // Default styles for each annotation type
  final AnnotationStyle defaultTextStyle;
  final AnnotationStyle defaultPointStyle;
  final AnnotationStyle defaultRangeStyle;
  final AnnotationStyle defaultTrendLineStyle;
  final AnnotationStyle defaultSelectionStyle;
  
  // State-specific overrides
  final Map<AnnotationState, AnnotationStyle> stateOverrides;
  
  // Integration with chart theme
  static AnnotationTheme fromChartTheme(ChartTheme chartTheme) {
    return AnnotationTheme(
      defaultTextStyle: AnnotationStyle.text(
        titleStyle: TitleStyle(
          textStyle: chartTheme.axisLabelTextStyle,
          backgroundColor: chartTheme.backgroundColor.withOpacity(0.8),
        ),
      ),
      // ... other type configurations
    );
  }
}
```

## 🔄 Interaction System

### Unified Interaction Patterns

All annotations follow consistent interaction patterns:

#### Mouse Interactions
- **Left Click**: Select annotation
- **Double Click**: Enter edit mode (where applicable)
- **Right Click**: Show context menu
- **Drag**: Move or resize annotation
- **Hover**: Show tooltip/preview

#### Keyboard Interactions
- **Tab**: Navigate between annotations
- **Enter**: Edit selected annotation
- **Escape**: Cancel current operation
- **Delete**: Remove selected annotation
- **Arrow Keys**: Fine-tune position

#### Touch Interactions
- **Tap**: Select annotation
- **Double Tap**: Enter edit mode
- **Long Press**: Show context menu
- **Drag**: Move or resize
- **Pinch**: Zoom (chart-level)

### State Management

```dart
enum AnnotationState {
  normal,          // Default state
  hovered,         // Mouse hover
  selected,        // User selected
  editing,         // In edit mode
  dragging,        // Being moved
  resizing,        // Being resized
  creating,        // Being created
}

class AnnotationStateManager {
  void transitionState(
    String annotationId, 
    AnnotationState newState,
  ) {
    // Validate state transition
    // Animate visual changes
    // Notify listeners
  }
}
```

## 💾 Persistence System

### Complete Data Persistence

```dart
class AnnotationPersistence {
  // Save all annotations with full state
  Future<void> saveAnnotations(
    String chartId,
    List<ChartAnnotation> annotations,
  ) async {
    final data = {
      'version': '1.0.0',
      'chartId': chartId,
      'savedAt': DateTime.now().toIso8601String(),
      'annotations': annotations.map((a) => {
        'id': a.id,
        'type': a.type.name,
        'data': a.toJson(),
        'style': a.style.toJson(),
        'metadata': a.metadata,
      }).toList(),
    };
    
    await _storage.save('annotations_$chartId', data);
  }
  
  // Load with version migration support
  Future<List<ChartAnnotation>> loadAnnotations(String chartId) async {
    final data = await _storage.load('annotations_$chartId');
    if (data == null) return [];
    
    // Handle version migration
    final migratedData = await _migrationManager.migrate(data);
    
    return _deserializeAnnotations(migratedData['annotations']);
  }
}
```

### Export/Import Support

```dart
class AnnotationExporter {
  // Export to various formats
  Future<String> exportToJson(List<ChartAnnotation> annotations) async {
    return jsonEncode(annotations.map((a) => a.toJson()).toList());
  }
  
  Future<Uint8List> exportToPng(
    List<ChartAnnotation> annotations,
    Size canvasSize,
  ) async {
    // Render annotations to PNG for sharing
  }
  
  // Import with validation
  Future<List<ChartAnnotation>> importFromJson(String jsonData) async {
    final data = jsonDecode(jsonData) as List;
    return _deserializeAnnotations(data);
  }
}
```

---

**Feature Status**: ✅ Fully Specified and User Validated  
**Implementation Priority**: High - Core Differentiating Feature  
**User Feedback**: Extremely Positive - Solves Real Problems  
**Technical Complexity**: High - Requires Careful Architecture  
**Last Updated**: October 2025