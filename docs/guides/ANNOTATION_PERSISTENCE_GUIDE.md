# Annotation Persistence Guide

## Overview

BravenChartPlus provides a complete annotation system with automatic persistence through the `AnnotationController`. All annotation edits (drag, resize, etc.) are automatically saved and synced across your application.

## Architecture

```
User Interaction (drag/resize)
        ↓
ChartRenderBox.handleEvent()
        ↓
_handlePointerUp() detects drag end
        ↓
onAnnotationChanged callback
        ↓
BravenChartPlus._handleAnnotationChanged()
        ↓
AnnotationController.updateAnnotation()
        ↓
ChangeNotifier.notifyListeners()
        ↓
UI rebuilds with updated annotation
```

## Features

### ✅ Fully Implemented

1. **Automatic Persistence**: All drag/resize operations automatically update the controller
2. **Real-time Sync**: Changes propagate immediately through ChangeNotifier pattern
3. **All Annotation Types Supported**:
   - ✅ **PointAnnotation**: Drag to move between data points (snap-to-point behavior)
   - ✅ **RangeAnnotation**: Drag to move, resize handles to adjust bounds
   - ✅ **TextAnnotation**: Drag to reposition anywhere on chart
   - ✅ **ThresholdAnnotation**: Drag along axis to adjust value
   - ✅ **TrendAnnotation**: Read-only (calculated from data)

4. **Snapping Support**: Annotations can snap to nearest data values when dragged
5. **Selection Management**: Selected annotation tracked through controller
6. **Batch Operations**: Update multiple annotations efficiently

## Usage

### Basic Setup

```dart
class MyChartScreen extends StatefulWidget {
  @override
  State<MyChartScreen> createState() => _MyChartScreenState();
}

class _MyChartScreenState extends State<MyChartScreen> {
  late final AnnotationController _annotationController;

  @override
  void initState() {
    super.initState();
    
    // Initialize controller with annotations
    _annotationController = AnnotationController(
      initialAnnotations: [
        RangeAnnotation(
          id: 'weekend',
          startX: 5.0,
          endX: 7.0,
          fillColor: Colors.grey.withOpacity(0.2),
          label: 'Weekend',
          allowDragging: true,  // Enable drag
          allowEditing: true,   // Enable resize
          snapToValue: true,    // Snap to data values
        ),
        ThresholdAnnotation(
          id: 'target',
          axis: AnnotationAxis.y,
          value: 100.0,
          lineColor: Colors.green,
          label: 'Target',
          allowDragging: true,
        ),
      ],
    );
    
    // Optional: Listen to changes for UI feedback
    _annotationController.addListener(_onAnnotationsChanged);
  }

  void _onAnnotationsChanged() {
    print('Annotations updated: ${_annotationController.length}');
    setState(() {}); // Rebuild UI with latest annotations
  }

  @override
  void dispose() {
    _annotationController.removeListener(_onAnnotationsChanged);
    _annotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BravenChartPlus(
      series: myData,
      annotationController: _annotationController,
      // ... other properties
    );
  }
}
```

### Adding Annotations Dynamically

```dart
// Add single annotation
_annotationController.addAnnotation(
  PointAnnotation(
    id: 'peak',
    seriesId: 'temperature',
    dataPointIndex: 42,
    markerColor: Colors.red,
    allowDragging: true,
  ),
);

// Add multiple annotations
_annotationController.addAll([
  annotation1,
  annotation2,
  annotation3,
]);
```

### Updating Annotations Programmatically

```dart
// Update single annotation
final currentAnnotation = _annotationController.getAnnotation('weekend');
if (currentAnnotation is RangeAnnotation) {
  _annotationController.updateAnnotation(
    'weekend',
    currentAnnotation.copyWith(
      startX: 10.0,
      endX: 15.0,
    ),
  );
}

// Update multiple annotations
_annotationController.updateAll({
  'weekend': updatedWeekendAnnotation,
  'target': updatedTargetAnnotation,
});
```

### Removing Annotations

```dart
// Remove single annotation
_annotationController.removeAnnotation('weekend');

// Remove multiple annotations
_annotationController.removeAll(['weekend', 'target', 'peak']);

// Clear all annotations
_annotationController.clearAnnotations();
```

### Selection Management

```dart
// Select annotation
_annotationController.selectAnnotation('weekend');

// Get selected annotation
final selected = _annotationController.selectedAnnotation;
print('Selected: ${selected?.id}');

// Clear selection
_annotationController.clearSelection();
```

### Querying Annotations

```dart
// Get all annotations
final all = _annotationController.annotations;

// Get annotations by type
final ranges = _annotationController.getAnnotationsByType<RangeAnnotation>();

// Query with predicate
final draggable = _annotationController.where((a) => a.allowDragging);

// Check existence
if (_annotationController.containsId('weekend')) {
  print('Weekend annotation exists');
}
```

## Annotation Types & Editing Behavior

### PointAnnotation
- **Drag Behavior**: Moves to nearest data point on the series
- **Visual Feedback**: Ghost marker at original position, preview at target position
- **Persistence**: Updates `dataPointIndex` property
- **Snapping**: Automatically snaps to nearest data point

```dart
PointAnnotation(
  id: 'peak',
  seriesId: 'temperature',
  dataPointIndex: 42,
  markerShape: MarkerShape.star,
  markerSize: 16.0,
  markerColor: Colors.red,
  allowDragging: true,  // Enable drag-to-move
)
```

### RangeAnnotation
- **Drag Behavior**: Moves entire range (maintains width/height)
- **Resize Behavior**: 8 resize handles (4 corners + 4 edges)
- **Visual Feedback**: Live preview during drag/resize with value labels
- **Persistence**: Updates `startX`, `endX`, `startY`, `endY` properties
- **Snapping**: Optional snap to data values with `snapToValue: true`

```dart
RangeAnnotation(
  id: 'weekend',
  startX: 5.0,
  endX: 7.0,
  startY: 80.0,
  endY: 120.0,
  fillColor: Colors.orange.withOpacity(0.2),
  borderColor: Colors.orange,
  allowDragging: true,   // Enable drag-to-move
  allowEditing: true,    // Enable resize handles
  snapToValue: true,     // Snap to data values
  snapIncrement: 1.0,    // Snap to integers
  snapTolerance: 0.05,   // 5% of viewport
)
```

### TextAnnotation
- **Drag Behavior**: Free-form repositioning anywhere on chart
- **Visual Feedback**: Moves smoothly with pointer
- **Persistence**: Updates `position` property (screen coordinates)
- **Anchoring**: Position relative to anchor point (topLeft, center, etc.)

```dart
TextAnnotation(
  id: 'title',
  text: 'Important Note',
  position: Offset(100, 50),
  anchor: AnnotationAnchor.topLeft,
  backgroundColor: Colors.white.withOpacity(0.9),
  allowDragging: true,
)
```

### ThresholdAnnotation
- **Drag Behavior**: Constrained to axis direction (horizontal/vertical only)
- **Visual Feedback**: Halo effect + real-time value label during drag
- **Persistence**: Updates `value` property
- **Axis Types**:
  - `AnnotationAxis.y`: Horizontal line (drag up/down)
  - `AnnotationAxis.x`: Vertical line (drag left/right)

```dart
ThresholdAnnotation(
  id: 'target',
  axis: AnnotationAxis.y,
  value: 100.0,
  lineColor: Colors.green,
  lineWidth: 2.0,
  dashPattern: [5, 5],
  allowDragging: true,  // Enable drag along axis
)
```

### TrendAnnotation
- **Drag Behavior**: Not draggable (calculated from data)
- **Edit Behavior**: Not directly editable
- **Use Case**: Statistical overlays (linear regression, moving average, etc.)

```dart
TrendAnnotation(
  id: 'trend',
  seriesId: 'sales',
  trendType: TrendType.linear,
  lineColor: Colors.red.withOpacity(0.7),
  allowDragging: false,  // Trends are read-only
)
```

## Advanced Features

### Snap-to-Value Configuration

```dart
RangeAnnotation(
  id: 'precise-range',
  startX: 10.0,
  endX: 20.0,
  snapToValue: true,        // Enable snapping
  snapIncrement: 0.5,       // Snap to 0.5 intervals (10.0, 10.5, 11.0, ...)
  snapTolerance: 0.05,      // Snap within 5% of viewport
)
```

**Snap Increments**:
- `0.1`: Snap to tenths (2.3, 2.4, 2.5)
- `0.5`: Snap to halves (2.0, 2.5, 3.0) - default
- `1.0`: Snap to integers (2, 3, 4)
- `10.0`: Snap to tens (10, 20, 30)

**Snap Tolerance**: Percentage of visible viewport range (0.0-1.0)
- `0.05`: Snap within 5% of viewport (default)
- `0.1`: Snap within 10% of viewport (more lenient)
- `0.02`: Snap within 2% of viewport (stricter)

### Custom Callbacks

```dart
BravenChartPlus(
  annotationController: _controller,
  
  // Called when annotation is dragged/resized
  onAnnotationDragged: (annotation, position) {
    print('Annotation ${annotation.id} moved to $position');
    
    // Custom validation
    if (annotation is RangeAnnotation) {
      if (annotation.endX - annotation.startX < 1.0) {
        _showError('Range too narrow');
      }
    }
  },
)
```

### Batch Updates with Transaction Pattern

```dart
// Efficient batch update - notifies listeners only once
final updates = {
  'weekend': weekendAnnotation.copyWith(startX: 10.0),
  'target': targetAnnotation.copyWith(value: 120.0),
  'peak': peakAnnotation.copyWith(dataPointIndex: 50),
};

_annotationController.updateAll(updates);
```

### Replace All Annotations

```dart
// Atomic replacement - preserves selection if ID exists
_annotationController.replaceAll([
  newAnnotation1,
  newAnnotation2,
  newAnnotation3,
]);
```

## Best Practices

### 1. Always Use AnnotationController for Persistence

❌ **Don't** pass annotations directly to widget:
```dart
BravenChartPlus(
  annotations: [myAnnotation],  // Changes won't persist!
)
```

✅ **Do** use controller:
```dart
BravenChartPlus(
  annotationController: _controller,  // Persistence works!
)
```

### 2. Listen to Controller Changes for UI Feedback

```dart
class _MyChartState extends State<MyChart> {
  late final AnnotationController _controller;
  int _changeCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnnotationController();
    _controller.addListener(_onAnnotationsChanged);
  }

  void _onAnnotationsChanged() {
    setState(() => _changeCount++);
    _showSnackBar('Annotation updated! Total changes: $_changeCount');
  }
}
```

### 3. Enable Appropriate Permissions

```dart
// Enable drag but not resize
RangeAnnotation(
  id: 'region',
  allowDragging: true,   // Can move
  allowEditing: false,   // Cannot resize
)

// Enable both drag and resize
RangeAnnotation(
  id: 'flexible',
  allowDragging: true,   // Can move
  allowEditing: true,    // Can resize
)

// Read-only
RangeAnnotation(
  id: 'static',
  allowDragging: false,
  allowEditing: false,
)
```

### 4. Validate Annotation Changes

```dart
BravenChartPlus(
  onAnnotationDragged: (annotation, position) {
    // Validate range width
    if (annotation is RangeAnnotation) {
      final width = annotation.endX - annotation.startX;
      if (width < 1.0) {
        // Revert invalid change
        _controller.updateAnnotation(
          annotation.id,
          annotation.copyWith(endX: annotation.startX + 1.0),
        );
        _showWarning('Minimum range width is 1.0');
      }
    }
  },
)
```

### 5. Use Unique IDs for Annotations

```dart
// ❌ Bad: Duplicate IDs will throw ArgumentError
_controller.addAnnotation(RangeAnnotation(id: 'range'));
_controller.addAnnotation(RangeAnnotation(id: 'range'));  // ERROR!

// ✅ Good: Unique IDs
_controller.addAnnotation(RangeAnnotation(id: 'weekend'));
_controller.addAnnotation(RangeAnnotation(id: 'holiday'));

// ✅ Good: Auto-generate IDs
_controller.addAnnotation(RangeAnnotation(
  id: ChartAnnotation.generateId(),  // 'annotation_0', 'annotation_1', ...
));
```

## Example: Complete Implementation

See `example/lib/showcase_plus/pages/annotations_page.dart` for a complete working example with:
- ✅ All 5 annotation types demonstrated
- ✅ Real-time persistence feedback
- ✅ Change counter showing live updates
- ✅ Annotation list with current values
- ✅ Interactive toggles for visibility and permissions
- ✅ Visual indicators for selected annotations

## Troubleshooting

### Annotations Don't Persist After Drag

**Problem**: Dragged annotations reset to original position
**Solution**: Ensure you're using `annotationController`, not `annotations` property

```dart
// ✅ Correct
BravenChartPlus(annotationController: myController)

// ❌ Wrong
BravenChartPlus(annotations: myList)
```

### Selection State Not Updating

**Problem**: Selected annotation not highlighted after click
**Solution**: Controller automatically tracks selection, ensure chart has `interactiveAnnotations: true`

```dart
BravenChartPlus(
  annotationController: myController,
  interactiveAnnotations: true,  // Required for interaction
)
```

### Annotations Not Visible

**Problem**: Annotations exist in controller but don't render
**Solution**: Check z-index ordering and ensure series data is loaded

```dart
RangeAnnotation(
  zIndex: 10,  // Higher values render on top
)
```

### Performance Issues with Many Annotations

**Problem**: Chart slow with 100+ annotations
**Solution**: Use batch operations and limit visible annotations

```dart
// Efficient batch add
_controller.addAll(hundreds of annotations);  // One notification

// Instead of
for (final annotation in hundreds) {
  _controller.addAnnotation(annotation);  // Hundreds of notifications!
}
```

## API Reference

See:
- `lib/src_plus/controllers/annotation_controller.dart` - Full AnnotationController API
- `lib/src_plus/models/chart_annotation.dart` - Annotation models with all properties
- `lib/src_plus/elements/annotation_elements.dart` - Rendering and interaction implementation

## Related Guides

- [Annotation Types Guide](./ANNOTATION_TYPES_GUIDE.md) - Detailed explanation of each type
- [Interaction System Guide](./INTERACTION_SYSTEM_GUIDE.md) - How interaction modes work
- [Custom Annotations Guide](./CUSTOM_ANNOTATIONS_GUIDE.md) - Creating custom annotation types
