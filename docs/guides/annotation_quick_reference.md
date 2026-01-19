# Annotation Quick Reference

## Setup

```dart
final controller = AnnotationController();

BravenChartPlus(
  annotationController: controller,
  interactiveAnnotations: true,
)
```

## CRUD Operations

| Operation | Code | Result |
|-----------|------|--------|
| **Add** | `controller.addAnnotation(annotation)` | Adds single annotation |
| **Add Multiple** | `controller.addAll([a1, a2, a3])` | Batch add (efficient) |
| **Update** | `controller.updateAnnotation(id, updated)` | Updates annotation |
| **Update Multiple** | `controller.updateAll({id: updated})` | Batch update |
| **Remove** | `controller.removeAnnotation(id)` | Removes by ID |
| **Remove Multiple** | `controller.removeAll([id1, id2])` | Batch remove |
| **Replace All** | `controller.replaceAll([annotations])` | Atomic replacement |
| **Clear All** | `controller.clearAnnotations()` | Removes all |

## Queries

| Query | Code | Returns |
|-------|------|---------|
| **Get All** | `controller.annotations` | `List<ChartAnnotation>` |
| **Get by ID** | `controller.getAnnotation(id)` | `ChartAnnotation?` |
| **Get by Type** | `controller.getAnnotationsByType<T>()` | `List<T>` |
| **Filter** | `controller.where((a) => condition)` | `List<ChartAnnotation>` |
| **Count** | `controller.length` | `int` |
| **Is Empty** | `controller.isEmpty` | `bool` |
| **Contains** | `controller.containsId(id)` | `bool` |

## Selection

| Action | Code | Result |
|--------|------|--------|
| **Select** | `controller.selectAnnotation(id)` | Sets selected annotation |
| **Clear Selection** | `controller.clearSelection()` | Deselects all |
| **Get Selected ID** | `controller.selectedAnnotationId` | `String?` |
| **Get Selected** | `controller.selectedAnnotation` | `ChartAnnotation?` |

## Annotation Types

| Type | Drag Behavior | Resize | Snap | Use Case |
|------|---------------|--------|------|----------|
| **Point** | Snap to data points | ❌ | ✅ Auto | Mark important data points |
| **Range** | Free move (maintains size) | ✅ 8 handles | ✅ Optional | Highlight regions/timeframes |
| **Text** | Free move (screen coords) | ❌ | ❌ | Labels, titles, notes |
| **Threshold** | Axis-constrained | ❌ | ❌ | Reference lines (targets, limits) |
| **Trend** | ❌ Not draggable | ❌ | ❌ | Statistical overlays |

## Drag Permissions

```dart
// Enable drag but not resize
allowDragging: true,
allowEditing: false,

// Enable both
allowDragging: true,
allowEditing: true,

// Read-only
allowDragging: false,
allowEditing: false,
```

## Snap Configuration

```dart
RangeAnnotation(
  snapToValue: true,       // Enable snapping
  snapIncrement: 1.0,      // Snap to integers
  snapTolerance: 0.05,     // 5% of viewport
)
```

| Increment | Effect | Example |
|-----------|--------|---------|
| `0.1` | Tenths | 2.3, 2.4, 2.5 |
| `0.5` | Halves | 2.0, 2.5, 3.0 |
| `1.0` | Integers | 2, 3, 4 |
| `10.0` | Tens | 10, 20, 30 |

## Listening to Changes

```dart
controller.addListener(() {
  print('Annotations changed: ${controller.length}');
});
```

## Common Patterns

### Pattern 1: Dynamic Add/Remove

```dart
// Add annotation
void addWeekendRange() {
  controller.addAnnotation(RangeAnnotation(
    id: 'weekend-${DateTime.now().millisecondsSinceEpoch}',
    startX: 5.0,
    endX: 7.0,
    allowDragging: true,
  ));
}

// Remove annotation
void removeWeekendRange(String id) {
  controller.removeAnnotation(id);
}
```

### Pattern 2: Update on Drag

```dart
BravenChartPlus(
  onAnnotationDragged: (annotation, position) {
    // Validation
    if (annotation is RangeAnnotation) {
      final width = annotation.endX - annotation.startX;
      if (width < 1.0) {
        _showError('Range too narrow');
      }
    }
  },
)
```

### Pattern 3: Batch Operations

```dart
// Efficient: Single notification
controller.updateAll({
  'weekend': updatedWeekend,
  'target': updatedTarget,
});

// Inefficient: Multiple notifications
controller.updateAnnotation('weekend', updatedWeekend);
controller.updateAnnotation('target', updatedTarget);
```

### Pattern 4: Filter by Type

```dart
// Get all ranges
final ranges = controller.getAnnotationsByType<RangeAnnotation>();

// Get draggable annotations
final draggable = controller.where((a) => a.allowDragging);

// Get visible in viewport
final visible = controller.where((a) {
  // Custom logic
  return isInViewport(a);
});
```

### Pattern 5: State Persistence

```dart
// Save to storage
void saveAnnotations() {
  final json = controller.annotations
    .map((a) => a.toJson())
    .toList();
  storage.write('annotations', json);
}

// Load from storage
void loadAnnotations() {
  final json = storage.read('annotations');
  final annotations = json
    .map((j) => ChartAnnotation.fromJson(j))
    .toList();
  controller.replaceAll(annotations);
}
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `ArgumentError: already exists` | Duplicate ID in `addAnnotation` | Use unique IDs or `updateAnnotation` |
| `ArgumentError: not found` | ID not in controller | Check with `containsId(id)` first |
| `ArgumentError: ID mismatch` | `updated.id != id` | Ensure IDs match in `updateAnnotation` |
| Annotations reset after drag | Using `annotations` property | Use `annotationController` instead |

## Performance Tips

✅ **Do**: Use batch operations
```dart
controller.addAll([a1, a2, a3]);  // 1 notification
```

❌ **Don't**: Loop with single operations
```dart
for (final a in annotations) {
  controller.addAnnotation(a);  // N notifications
}
```

✅ **Do**: Dispose controller
```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

❌ **Don't**: Forget to remove listeners
```dart
// Memory leak!
controller.addListener(callback);
// Missing: controller.removeListener(callback);
```

## Testing

```dart
test('annotation persistence', () {
  final controller = AnnotationController();
  
  // Add annotation
  controller.addAnnotation(RangeAnnotation(
    id: 'test',
    startX: 0,
    endX: 10,
  ));
  
  expect(controller.length, 1);
  
  // Update annotation
  final updated = controller.getAnnotation('test')!.copyWith(
    startX: 5,
  );
  controller.updateAnnotation('test', updated);
  
  final result = controller.getAnnotation('test') as RangeAnnotation;
  expect(result.startX, 5);
  
  controller.dispose();
});
```

## See Also

- [Full Persistence Guide](./annotation_persistence_guide.md)
- [Annotation Types Guide](./annotation_types_guide.md)
- [API Reference](../../lib/src_plus/controllers/annotation_controller.dart)
