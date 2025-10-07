# Research: Chart Widgets with Annotations

**Feature**: 006-chart-widgets  
**Phase**: Phase 0 - Outline & Research  
**Date**: October 6, 2025

---

## Research Objectives

1. **Flutter StatefulWidget Patterns**: Best practices for widget lifecycle, resource management, hot reload support
2. **Controller Pattern**: How Flutter controllers work (TextEditingController, ScrollController, AnimationController)
3. **Stream Integration**: Stream-based data updates with throttling and backpressure handling
4. **Annotation Rendering**: Integration with existing annotation architecture or simple overlay approach
5. **Axis Configuration**: Comprehensive yet simple API for axis customization
6. **Performance Optimization**: Widget-level optimizations beyond Layer 4

---

## Decision 1: StatefulWidget vs StatelessWidget

**Problem**: Should BravenChart be stateful or stateless?

**Research**:
- **StatelessWidget**: Simpler, no lifecycle, all data from constructor
  - Pros: Easier to understand, immutable, predictable
  - Cons: No resource lifecycle management, no controller binding, no stream subscription
  
- **StatefulWidget**: Has lifecycle methods (initState, dispose, didUpdateWidget)
  - Pros: Resource management (dispose pipelines/pools), controller integration, stream subscriptions, hot reload support
  - Cons: More complex, mutable state

**Decision**: **StatefulWidget**

**Rationale**:
- **Resource Management**: Must dispose RenderPipeline, ObjectPools, Stream subscriptions on unmount
- **Controller Binding**: ChartController needs lifecycle to attach/detach listeners
- **Stream Integration**: StreamSubscription needs proper disposal
- **Hot Reload**: didUpdateWidget() enables configuration updates without memory leaks
- **Performance**: Can cache computed values in State (e.g., axis ranges)

**Alternatives Considered**:
- StatelessWidget with InheritedWidget for lifecycle: Too complex, not idiomatic
- External resource manager: Doesn't integrate with Flutter lifecycle

---

## Decision 2: Controller Pattern Design

**Problem**: How should ChartController work for programmatic updates?

**Research**:
- **TextEditingController Pattern**: 
  - Extends ChangeNotifier
  - Holds mutable state
  - Widget listens via addListener()
  - Dispose required
  
- **ScrollController Pattern**:
  - Similar to TextEditingController
  - Can be created internally or passed externally
  - jumpTo(), animateTo() methods
  
- **AnimationController Pattern**:
  - Requires TickerProvider (complex for widgets)
  - Not suitable for data updates

**Decision**: **TextEditingController-style ChangeNotifier**

**Rationale**:
- Familiar pattern for Flutter developers
- Simple state management (notify listeners on change)
- Widget subscribes in initState(), unsubscribes in dispose()
- Methods: addPoint(), removePoint(), addAnnotation(), removeAnnotation(), updateAnnotation()
- Can be created internally (default) or passed externally (advanced)

**API Design**:
```dart
class ChartController extends ChangeNotifier {
  // Data management
  void addPoint(String seriesId, ChartDataPoint point);
  void removeOldestPoint(String seriesId);
  void clearSeries(String seriesId);
  
  // Annotation management
  String addAnnotation(ChartAnnotation annotation); // returns ID
  void removeAnnotation(String annotationId);
  void updateAnnotation(String annotationId, ChartAnnotation annotation);
  ChartAnnotation? getAnnotation(String annotationId);
  List<ChartAnnotation> getAllAnnotations();
  void clearAnnotations();
  List<ChartAnnotation> findAnnotationsAt(Offset position);
  
  // Internal state
  final Map<String, List<ChartDataPoint>> _seriesData = {};
  final Map<String, ChartAnnotation> _annotations = {};
}
```

**Alternatives Considered**:
- ValueNotifier<ChartData>: Too simple, doesn't handle complex updates
- StreamController-based: Over-engineered, async not needed
- Custom event system: Reinventing the wheel

---

## Decision 3: Stream Integration Strategy

**Problem**: How to handle real-time data streams efficiently?

**Research**:
- **Direct Stream Binding**: Widget subscribes directly to Stream<ChartDataPoint>
  - Pros: Simple, idiomatic Flutter
  - Cons: No throttling, no backpressure, can overwhelm renderer
  
- **StreamTransformer Throttling**: Use built-in throttleTime transformer
  - Pros: Flutter standard, efficient, handles backpressure
  - Cons: Requires dart:async understanding
  
- **Custom Debouncing**: Manual timer-based throttling
  - Pros: Full control
  - Cons: Reinventing the wheel, error-prone

**Decision**: **StreamTransformer with throttleTime (16ms = 60 FPS)**

**Rationale**:
- Built-in Flutter solution (no custom code)
- Automatic backpressure handling (drops intermediate frames)
- Guarantees max 60 FPS update rate
- Simple to understand and test
- Integrates cleanly with widget lifecycle (cancel subscription in dispose)

**Implementation Pattern**:
```dart
class _BravenChartState extends State<BravenChart> {
  StreamSubscription? _dataSubscription;
  
  @override
  void initState() {
    super.initState();
    if (widget.dataStream != null) {
      _dataSubscription = widget.dataStream!
        .transform(StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            // Throttle to 60 FPS (16ms)
            sink.add(data);
          },
        ))
        .throttleTime(Duration(milliseconds: 16))
        .listen((point) {
          setState(() {
            _addPointToSeries(point);
          });
        });
    }
  }
  
  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
```

**Alternatives Considered**:
- No throttling: Unacceptable, would cause dropped frames
- Custom timer: Complex, error-prone, not idiomatic
- AnimationController-based: Over-engineered for this use case

---

## Decision 4: Annotation Rendering Approach

**Problem**: How to render annotations on top of chart data?

**Research**:
- **Layer 7 Integration**: Wait for full Annotation System implementation
  - Pros: Fully featured, consistent with architecture
  - Cons: Blocks this feature, complex dependency
  
- **Simple Overlay Pattern**: Render annotations as additional CustomPaint layer
  - Pros: Simple, no dependencies, sufficient for v1
  - Cons: Less sophisticated than Layer 7
  
- **Hybrid Approach**: Simple implementation now, migrate to Layer 7 later
  - Pros: Unblocks feature, clear migration path
  - Cons: Potential rework

**Decision**: **Simple Overlay with Layer 7 Migration Path**

**Rationale**:
- Layer 7 not yet implemented (blocks timeline)
- Simple overlay meets all 40 requirements
- Clear architecture: annotations rendered AFTER chart data (z-order)
- Migration path documented: When Layer 7 ready, replace overlay with AnnotationLayer
- 5 annotation types implementable with basic Canvas operations:
  - TextAnnotation: drawParagraph()
  - PointAnnotation: drawCircle() with text
  - RangeAnnotation: drawRect() with semi-transparent fill
  - ThresholdAnnotation: drawLine()
  - TrendAnnotation: drawPath() for regression line

**Implementation Strategy**:
```dart
void paint(Canvas canvas, Size size) {
  // 1. Render chart data (existing Layer 4)
  _chartLayer.render(canvas, size, context);
  
  // 2. Render annotations (simple overlay)
  for (final annotation in annotations) {
    annotation.render(canvas, size, transformer);
  }
}
```

**Migration Path**:
- Phase 1: Simple overlay (sufficient for v1)
- Phase 2 (future): Replace with AnnotationLayer from Layer 7
- No API changes required (internal implementation only)

**Alternatives Considered**:
- Wait for Layer 7: Blocks feature for months
- Complex custom system: Reinventing what Layer 7 will provide

---

## Decision 5: AxisConfig Design Pattern

**Problem**: How to make axes highly customizable yet simple to use?

**Research**:
- **Builder Pattern**: Fluent API with chaining
  - Pros: Discoverable, flexible
  - Cons: Mutable, verbose in Dart
  
- **Named Constructor Pattern**: Multiple factory constructors
  - Pros: Idiomatic Flutter, immutable
  - Cons: Limited combinations
  
- **Value Object with Defaults**: All properties optional with sensible defaults
  - Pros: Simple, copyWith() support, immutable
  - Cons: Long constructor signature

**Decision**: **Value Object with Factory Presets**

**Rationale**:
- Immutable value object (Flutter best practice)
- All properties optional with sensible defaults
- Factory constructors for common patterns: defaults(), hidden(), minimal(), gridOnly()
- copyWith() for customization
- 45+ properties organized into logical groups

**API Design**:
```dart
class AxisConfig {
  // Visibility
  final bool showAxis;
  final bool showGrid;
  final bool showTicks;
  final bool showLabels;
  
  // Range
  final AxisRange? range; // null = auto-calculate
  final bool allowZoom;
  final bool allowPan;
  
  // Styling
  final Color? axisColor;
  final double axisWidth;
  final Color? gridColor;
  final double gridWidth;
  final List<double>? gridDashPattern;
  
  // Labels
  final String? label;
  final AxisLabelFormatter? labelFormatter;
  final int? maxLabels;
  final double labelRotation;
  
  // ... 45+ properties total
  
  // Factory presets
  factory AxisConfig.defaults() => AxisConfig();
  factory AxisConfig.hidden() => AxisConfig(
    showAxis: false, showGrid: false, showTicks: false, showLabels: false);
  factory AxisConfig.minimal() => AxisConfig(
    showAxis: false, showGrid: false, showTicks: false);
  factory AxisConfig.gridOnly() => AxisConfig(
    showAxis: false, showTicks: false, showLabels: false);
  
  AxisConfig copyWith({...});
}
```

**Alternatives Considered**:
- Separate classes per preset: Too many classes, not flexible
- Builder pattern: Not idiomatic Dart, mutable
- Single mega-config: Overwhelming, not organized

---

## Decision 6: Resource Lifecycle Management

**Problem**: How to ensure zero memory leaks with RenderPipeline, ObjectPools, Streams?

**Research**:
- **Manual Management**: Developer responsible for dispose
  - Pros: Explicit control
  - Cons: Error-prone, defeats simplicity goal
  
- **Widget Lifecycle Integration**: Automatic in initState/dispose
  - Pros: Automatic, zero effort for user
  - Cons: Requires StatefulWidget
  
- **Finalizer-based**: Dart 3.0 finalizers for cleanup
  - Pros: Automatic, works with StatelessWidget
  - Cons: Non-deterministic, can't rely on timing

**Decision**: **Widget Lifecycle Integration (StatefulWidget)**

**Rationale**:
- Deterministic cleanup in dispose()
- Zero effort for developers (widget handles it)
- Idiomatic Flutter pattern
- Hot reload friendly (recreate in didUpdateWidget)
- Constitutional requirement: zero memory leaks

**Implementation Pattern**:
```dart
class _BravenChartState extends State<BravenChart> {
  late RenderPipeline _pipeline;
  late ObjectPool<Paint> _paintPool;
  late ObjectPool<Path> _pathPool;
  StreamSubscription? _dataSubscription;
  
  @override
  void initState() {
    super.initState();
    _createResources();
  }
  
  @override
  void didUpdateWidget(BravenChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hot reload support: recreate if config changed
    if (widget.config != oldWidget.config) {
      _disposeResources();
      _createResources();
    }
  }
  
  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }
  
  void _createResources() {
    _paintPool = ObjectPool<Paint>(factory: () => Paint(), reset: (p) {});
    _pathPool = ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset());
    _pipeline = RenderPipeline(paintPool: _paintPool, pathPool: _pathPool);
  }
  
  void _disposeResources() {
    _dataSubscription?.cancel();
    _pipeline.dispose();
    _paintPool.dispose();
    _pathPool.dispose();
  }
}
```

**Alternatives Considered**:
- Finalizers: Non-deterministic, can't guarantee cleanup timing
- External manager: Not idiomatic, adds complexity
- Manual dispose: Defeats simplicity goal

---

## Decision 7: Performance Optimizations Beyond Layer 4

**Problem**: What widget-level optimizations can we add beyond Layer 4's viewport culling?

**Research**:
- **RepaintBoundary**: Isolates repaints to subtree
  - Pros: Reduces repaint cost when surrounding widgets update
  - Cons: Adds layer, slight memory overhead
  
- **const Widgets**: Compile-time constants
  - Pros: Zero rebuild cost
  - Cons: Limited applicability (data changes)
  
- **shouldRepaint Optimization**: Only repaint when necessary
  - Pros: Skips unnecessary repaints
  - Cons: Requires careful equality checking
  
- **Cached Paint Objects**: Reuse Paint/Path between frames
  - Pros: Reduces allocations
  - Cons: Already done by Layer 1 (object pooling)

**Decision**: **RepaintBoundary + shouldRepaint Optimization**

**Rationale**:
- RepaintBoundary: Chart isolated from parent widget rebuilds (e.g., surrounding UI updates)
- shouldRepaint: Skip repaint if data/config unchanged (equality check)
- Layer 1 object pooling handles allocations (no duplication needed)
- Combined: Minimal repaints, maximum performance

**Implementation Pattern**:
```dart
class BravenChart extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ChartPainter(
          series: series,
          chartType: chartType,
          config: config,
        ),
        size: Size(width, height),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final ChartType chartType;
  final dynamic config;
  
  @override
  bool shouldRepaint(_ChartPainter oldDelegate) {
    return series != oldDelegate.series ||
           chartType != oldDelegate.chartType ||
           config != oldDelegate.config;
  }
}
```

**Alternatives Considered**:
- No optimizations: Unnecessary repaints
- Custom caching layer: Duplicates Layer 1 functionality
- Aggressive const: Not applicable (data changes frequently)

---

## Best Practices Summary

### Flutter StatefulWidget Patterns
- **Lifecycle**: initState for setup, dispose for cleanup, didUpdateWidget for hot reload
- **Resource Management**: Always dispose resources (streams, controllers, pipelines, pools)
- **Hot Reload**: Support configuration updates without memory leaks
- **Performance**: Use RepaintBoundary, shouldRepaint optimization
- **Testing**: Widget tests, golden tests, hot reload tests

### Controller Pattern
- **Extend ChangeNotifier**: Standard Flutter pattern
- **Methods**: Data updates (add/remove) + Annotation management (CRUD)
- **Lifecycle**: Widget subscribes in initState, unsubscribes in dispose
- **Optional**: Can be created internally or passed externally
- **Disposal**: Must be disposed by creator

### Stream Integration
- **Throttling**: Use StreamTransformer with 16ms interval (60 FPS)
- **Backpressure**: Built-in handling (drop intermediate frames)
- **Subscription**: Cancel in dispose() to prevent leaks
- **Error Handling**: onError callback to handle stream failures
- **Testing**: Mock streams for unit tests

### Annotation Rendering
- **Simple Overlay**: Sufficient for v1, no Layer 7 dependency
- **Z-Order**: Annotations rendered AFTER chart data (foreground)
- **Migration Path**: Replace with Layer 7 AnnotationLayer when ready
- **5 Types**: Text, Point, Range, Threshold, Trend (all implementable with Canvas)
- **Performance**: Spatial indexing for 500+ annotations

### Axis Configuration
- **Value Object**: Immutable, all properties optional
- **Factory Presets**: defaults(), hidden(), minimal(), gridOnly()
- **copyWith**: For customization
- **45+ Properties**: Organized into logical groups (visibility, range, styling, labels)
- **Auto-Calculation**: Null range = auto-calculate from data

---

## Dependencies & Integration Points

### Layer 0 (Foundation)
- **ChartSeries**: Data container (used directly)
- **ChartDataPoint**: Single observation (used directly)
- **ObjectPool**: Paint/Path pooling (created in State)
- **ViewportCuller**: Off-screen optimization (passed to pipeline)

### Layer 1 (Core Rendering)
- **RenderPipeline**: Rendering orchestration (created in State)
- **RenderLayer**: Interface for chart layers (used via Layer 4)
- **RenderContext**: Rendering state (created per paint)

### Layer 2 (Coordinate System)
- **UniversalCoordinateTransformer**: Data-to-screen transformations (passed to layers)
- **AxisBounds**: Auto-calculation of axis ranges (computed in State)

### Layer 3 (Theming)
- **ChartTheme**: Visual styling (passed from widget or Theme.of(context))
- **SeriesTheme**: Per-series colors (auto-generated or explicit)
- **Dark Mode**: Theme.of(context).brightness integration

### Layer 4 (Chart Types)
- **LineChartLayer**: Line chart rendering (instantiated based on chartType)
- **AreaChartLayer**: Area chart rendering (instantiated based on chartType)
- **BarChartLayer**: Bar chart rendering (instantiated based on chartType)
- **ScatterChartLayer**: Scatter chart rendering (instantiated based on chartType)

### External Dependencies
- **dart:async**: Stream, StreamSubscription, StreamTransformer
- **dart:ui**: Canvas, Paint, Path, Offset, Size, Rect
- **flutter/widgets**: StatefulWidget, State, CustomPaint, RepaintBoundary

---

## Performance Targets

### Rendering Performance
- **Frame Time**: <16ms per frame (60 FPS)
- **Data Points**: 10,000 points without degradation
- **Annotations**: 500 annotations without degradation
- **Throttling**: Stream updates capped at 60 FPS (16ms interval)

### Controller Performance
- **Update Latency**: <100ms from controller method call to screen update
- **Memory**: Zero memory leaks in 24-hour streaming test
- **Hot Reload**: <1 second to apply configuration changes

### Resource Usage
- **Object Pooling**: >90% hit rate (measured via Layer 1)
- **Viewport Culling**: <1ms overhead (measured via Layer 0)
- **Stream Backpressure**: No UI blocking under high data rate

---

## Testing Strategy

### Contract Tests
- **BravenChart API**: All constructor parameters, callbacks, factory constructors
- **ChartController API**: All methods (data + annotations), ChangeNotifier behavior
- **AxisConfig API**: All factory presets, copyWith(), property validation

### Widget Tests
- **Lifecycle**: initState, dispose, didUpdateWidget behavior
- **Controller Binding**: Subscription, updates, unsubscription
- **Stream Integration**: Throttling, backpressure, cancellation
- **Hot Reload**: Configuration updates without leaks

### Golden Tests
- **Chart Types**: All 4 types (line, area, bar, scatter)
- **Axis Configurations**: defaults, hidden, minimal, gridOnly
- **Annotations**: All 5 types on same chart
- **Themes**: Light, dark, custom

### Integration Tests
- **End-to-End**: Create chart → stream data → add annotations → interact
- **Performance**: 10,000 point rendering, 60 FPS streaming, memory leak detection
- **Real-World**: Dashboard scenario, financial chart scenario, IoT scenario

### Unit Tests
- **AxisConfig**: Factory methods, copyWith(), validation
- **Controller**: State management, notification, annotation CRUD
- **Helpers**: Data binding utilities (fromValues, fromMap, fromJson)

---

## Risks & Mitigations

### Risk 1: Layer 7 Dependency
- **Risk**: Annotation system may require Layer 7 features not yet implemented
- **Mitigation**: Simple overlay approach sufficient for v1, clear migration path documented

### Risk 2: Stream Performance
- **Risk**: High-frequency streams (>60 FPS) could overwhelm renderer
- **Mitigation**: Built-in throttling at 16ms (60 FPS max), backpressure handling, performance tests

### Risk 3: Resource Leaks
- **Risk**: Complex lifecycle could lead to memory leaks
- **Mitigation**: Comprehensive lifecycle tests, 24-hour streaming test, hot reload tests

### Risk 4: API Complexity
- **Risk**: 40 FRs could lead to overwhelming API surface
- **Mitigation**: Single widget entry point, factory presets, sensible defaults, comprehensive examples

### Risk 5: Test Coverage
- **Risk**: 100% coverage target may be difficult with widget tests
- **Mitigation**: Contract tests, widget tests, golden tests, integration tests, unit tests (5-layer strategy)

---

## Unknowns Resolved

✅ All NEEDS CLARIFICATION items from Technical Context resolved:
- Language/Version: Dart 3.10.0-227.0.dev ✓
- Dependencies: Flutter SDK 3.37.0-1.0.pre-216 ✓
- Testing: Flutter test framework ✓
- Platform: Flutter Web (primary) ✓
- Performance Goals: 60 FPS, <16ms, <100ms controller ✓
- Constraints: Single widget, pure Flutter, zero leaks ✓
- Scale: 1 widget, 4 types, 5 annotations, 40 FRs ✓

✅ All technical decisions made:
- StatefulWidget pattern ✓
- TextEditingController-style controller ✓
- StreamTransformer throttling ✓
- Simple annotation overlay ✓
- Value object AxisConfig ✓
- Widget lifecycle resource management ✓
- RepaintBoundary + shouldRepaint optimization ✓

---

## Next Steps (Phase 1)

Phase 0 Complete ✅ → Ready for Phase 1:

1. **data-model.md**: Document entities (ChartSeries, ChartDataPoint, ChartAnnotation, AxisConfig, ChartController)
2. **contracts/**: Generate API contracts for all public interfaces
3. **quickstart.md**: 5-minute guide to first chart
4. **Contract Tests**: Failing tests for all APIs (TDD red phase)
5. **Update copilot-instructions.md**: Add Layer 5 context

**Estimated Duration**: Phase 1 = 4-6 hours
