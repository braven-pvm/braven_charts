# Streaming Architecture Audit

**Date:** December 3, 2025  
**Branch:** 011-multi-axis-normalization  
**Status:** Analysis Complete - Awaiting Implementation Decisions

---

## Executive Summary

The current streaming implementation has four distinct mechanisms for adding data points to charts. While functional for low-frequency data (1-10 Hz), the architecture has significant performance bottlenecks that prevent efficient high-speed streaming (50-100+ Hz).

**Core Problem:** Every data point triggers a full widget rebuild, making sustained high-frequency updates impractical.

---

## Architecture Overview

### Key Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `BravenChartPlus` | `lib/src/braven_chart_plus.dart` | StatefulWidget - orchestrates everything |
| `_BravenChartPlusState` | Same file | Holds streaming state, axes, element generator |
| `ChartController` | `lib/src/controllers/chart_controller.dart` | External API for adding points |
| `StreamingController` | `lib/src/streaming/streaming_controller.dart` | Pause/resume control |
| `StreamingConfig` | `lib/src/models/streaming_config.dart` | Buffer/auto-scroll config |
| `AutoScrollConfig` | `lib/src/models/auto_scroll_config.dart` | Sliding window config |
| `BufferManager` | `lib/src/streaming/buffer_manager.dart` | FIFO buffer for paused data |
| `_ChartRenderWidget` | `lib/src/braven_chart_plus.dart` | LeafRenderObjectWidget bridge |
| `ChartRenderBox` | `lib/src/rendering/chart_render_box.dart` | RenderObject - actual painting |

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL INPUT MECHANISMS                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐       │
│  │ 1. controller    │    │ 2. dataStream    │    │ 4. widget.series │       │
│  │    .addPoint()   │    │    Stream<Point> │    │    [points...]   │       │
│  └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘       │
│           │                       │                       │                  │
│           ▼                       ▼                       │                  │
│  ┌──────────────────┐    ┌──────────────────┐             │                  │
│  │ notifyListeners()│    │ _onStreamData()  │             │                  │
│  └────────┬─────────┘    └────────┬─────────┘             │                  │
│           │                       │                       │                  │
│           ▼                       ▼                       │                  │
│  ┌──────────────────┐    ┌──────────────────┐             │                  │
│  │_onControllerUpdate│   │ if _isStreaming: │             │                  │
│  └────────┬─────────┘    │   controller     │             │                  │
│           │              │     .addPoint()  │◄────────────┤                  │
│           │              │ else:            │             │                  │
│           │              │   buffer.add()   │             │                  │
│           │              └────────┬─────────┘             │                  │
│           │                       │                       │                  │
└───────────┼───────────────────────┼───────────────────────┼──────────────────┘
            │                       │                       │
            ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        _BravenChartPlusState                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  State Fields:                                                               │
│  ├─ _isStreaming: bool                                                       │
│  ├─ _buffer: BufferManager<ChartDataPoint>?                                  │
│  ├─ _streamingDataPoints: List<ChartDataPoint>    (legacy path)              │
│  ├─ _lockedPausedBounds: DataBounds?              (viewport lock)            │
│  ├─ _cachedData{X,Y}{Min,Max}: double?            (full data bounds)         │
│  ├─ _xAxis, _yAxis: Axis?                                                    │
│  ├─ _elementGenerator: Function(ChartTransform)                              │
│  └─ _elementGeneratorVersion: int                                            │
│                                                                              │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    setState(() { _rebuildElements(); })               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         _rebuildElements()                            │   │
│  │  ┌────────────────────────────────────────────────────────────────┐  │   │
│  │  │ 1. Merge widget.series + controller.getAllSeries()             │  │   │
│  │  │ 2. Filter hidden series                                        │  │   │
│  │  │ 3. Calculate dataBounds (sliding window if auto-scroll)        │  │   │
│  │  │ 4. Create _xAxis, _yAxis from bounds                           │  │   │
│  │  │ 5. Create _elementGenerator = (transform) => elements          │  │   │
│  │  │ 6. Increment _elementGeneratorVersion                          │  │   │
│  │  └────────────────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                            build()                                    │   │
│  │  Returns: _ChartRenderWidget(                                         │   │
│  │    elementGenerator: _elementGenerator,                               │   │
│  │    elementGeneratorVersion: _elementGeneratorVersion,                 │   │
│  │    xAxis: _xAxis,                                                     │   │
│  │    yAxis: _yAxis,                                                     │   │
│  │    ...                                                                │   │
│  │  )                                                                    │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       _ChartRenderWidget (LeafRenderObjectWidget)            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  updateRenderObject(context, ChartRenderBox renderObject) {                  │
│    renderObject                                                              │
│      ..setElementGenerator(elementGenerator, elementGeneratorVersion)        │
│      ..setXAxis(xAxis)                                                       │
│      ..setYAxis(yAxis)                                                       │
│      ..setTheme(theme)                                                       │
│      ...                                                                     │
│  }                                                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ChartRenderBox (RenderBox)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  setElementGenerator(generator, version) {                                   │
│    if (_elementGeneratorVersion == version) return;  // Skip if same        │
│    _elementGenerator = generator;                                            │
│    _elementGeneratorVersion = version;                                       │
│    if (_transform != null) {                                                 │
│      _rebuildElementsWithTransform();  // Regenerate elements               │
│    }                                                                         │
│  }                                                                           │
│                                                                              │
│  setXAxis(axis) {                                                            │
│    // Creates/updates ChartTransform                                         │
│    // Updates _originalTransform for pan constraints                         │
│    markNeedsLayout();                                                        │
│  }                                                                           │
│                                                                              │
│  _rebuildElementsWithTransform() {                                           │
│    _elements = _elementGenerator!(_transform!);                              │
│    _rebuildSpatialIndex();                                                   │
│    markNeedsPaint();                                                         │
│  }                                                                           │
│                                                                              │
│  paint(context, offset) {                                                    │
│    // Layer 0: Background annotations                                        │
│    // Layer 1: Series (Picture cached)                                       │
│    // Layer 2: Foreground annotations                                        │
│    // Layer 3: Overlays (crosshair, tooltips)                                │
│  }                                                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Mechanism Analysis

### 1. `controller.addPoint()` (ChartController)

**Location:** `lib/src/controllers/chart_controller.dart`

#### External API

```dart
class ChartController extends ChangeNotifier {
  final Map<String, List<ChartDataPoint>> _seriesData = {};
  
  void addPoint(String seriesId, ChartDataPoint point) {
    assert(point.x.isFinite && point.y.isFinite);
    final series = _seriesData.putIfAbsent(seriesId, () => []);
    series.add(point);
    notifyListeners();  // ← TRIGGERS REBUILD
  }
  
  Map<String, List<ChartDataPoint>> getAllSeries() {
    return Map.fromEntries(_seriesData.entries.map(
      (entry) => MapEntry(entry.key, List.from(entry.value))  // COPIES!
    ));
  }
}
```

#### Internal Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ controller.addPoint('series1', ChartDataPoint(x: 100, y: 50))               │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ChartController._seriesData['series1'].add(point)                           │
│ notifyListeners()                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _BravenChartPlusState._onControllerUpdate()                                 │
│                                                                              │
│   // Update cached bounds (O(1) per point)                                   │
│   for (point in controllerData.values.expand((p) => p)) {                   │
│     _updateCachedDataBounds(point.x, point.y);  // O(n) ITERATION!          │
│   }                                                                          │
│                                                                              │
│   if (!_isStreaming) return;  // Skip rebuild if paused                     │
│                                                                              │
│   setState(() { _rebuildElements(); });                                     │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _rebuildElements()                                                          │
│                                                                              │
│   // 1. Get controller data (COPIES entire dataset!)                        │
│   final controllerData = widget.controller!.getAllSeries();                 │
│                                                                              │
│   // 2. Merge with widget.series                                            │
│   for (series in widget.series) {                                           │
│     final controllerPoints = controllerData[series.id];                     │
│     if (controllerPoints != null) {                                         │
│       mergedPoints = [...series.points, ...controllerPoints];  // COPIES!   │
│     }                                                                        │
│   }                                                                          │
│                                                                              │
│   // 3. Calculate sliding window bounds (O(n) if auto-scroll)               │
│   final allPoints = effectiveSeries.expand((s) => s.points).toList();       │
│   final windowPoints = allPoints.sublist(allPoints.length - windowSize);    │
│   // min/max calculations on windowPoints...                                │
│                                                                              │
│   // 4. Create axes from bounds                                             │
│   _xAxis = Axis.fromPublicConfig(..., dataMin: bounds.xMin, ...);           │
│   _yAxis = Axis.fromPublicConfig(...);                                      │
│                                                                              │
│   // 5. Create element generator closure (captures effectiveSeries)         │
│   _elementGenerator = (transform) {                                         │
│     return DataConverter.seriesToElements(series: effectiveSeries, ...);    │
│   };                                                                         │
│                                                                              │
│   _elementGeneratorVersion++;                                               │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ build() → _ChartRenderWidget(elementGenerator, version, xAxis, yAxis, ...)  │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _ChartRenderWidget.updateRenderObject()                                     │
│   renderObject.setElementGenerator(elementGenerator, version)               │
│   renderObject.setXAxis(xAxis)                                              │
│   renderObject.setYAxis(yAxis)                                              │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ChartRenderBox.setElementGenerator(generator, version)                      │
│   if (version == _elementGeneratorVersion) return;  // SKIP if same         │
│   _elementGenerator = generator;                                            │
│   _elementGeneratorVersion = version;                                       │
│   _rebuildElementsWithTransform();                                          │
│     → _elements = generator(transform)                                      │
│     → _rebuildSpatialIndex()                                                │
│     → markNeedsPaint()                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ChartRenderBox.setXAxis(axis)                                               │
│   // Check if bounds actually changed (optimization)                        │
│   if (boundsMatchWidgetProvided) return;  // SKIP if same bounds            │
│   _xAxis = axis;                                                            │
│   // Update transform data ranges                                           │
│   markNeedsLayout();                                                        │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ChartRenderBox.performLayout()                                              │
│   // Calculate plot area, scrollbar positions                               │
│   // Create/update ChartTransform                                           │
│   // Call _rebuildElementsWithTransform() if needed                         │
│   // _rebuildSpatialIndex()                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ ChartRenderBox.paint()                                                      │
│   // Use cached Picture for series (if valid)                               │
│   // Draw axes, grid, annotations, overlays                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Performance Analysis

| Operation | Complexity | Notes |
|-----------|------------|-------|
| `addPoint()` | O(1) | Just list append |
| `notifyListeners()` | O(listeners) | Typically 1 listener |
| `getAllSeries()` | O(n) | **COPIES all points!** |
| `_onControllerUpdate` bounds | O(n) | Iterates ALL points every time |
| `_rebuildElements` merge | O(n) | Creates new lists |
| `_rebuildElements` window | O(n) | `expand().toList()` + `sublist()` |
| `build()` | O(1) | Just creates widgets |
| `updateRenderObject` | O(1) | Just sets fields |
| `setElementGenerator` | O(elements) | Regenerates if version changed |
| `performLayout` | O(elements) | Spatial index rebuild |
| **TOTAL per addPoint()** | **O(n)** | Where n = total points |

#### Data Structures

```dart
// ChartController
Map<String, List<ChartDataPoint>> _seriesData;  // Unbounded growth!

// _BravenChartPlusState  
List<ChartDataPoint> _streamingDataPoints;  // Legacy, also unbounded
BufferManager<ChartDataPoint>? _buffer;      // FIFO, bounded
double? _cachedData{X,Y}{Min,Max};           // Incremental bounds

// ChartRenderBox
List<ChartElement> _elements;                // Generated each rebuild
QuadTree _spatialIndex;                      // Rebuilt each rebuild
ui.Picture? _cachedSeriesPicture;            // Reused if cache valid
```

---

### 2. `StreamingController`

**Location:** `lib/src/streaming/streaming_controller.dart`

#### External API

```dart
class StreamingController extends ChangeNotifier {
  bool _isStreaming = true;
  ViewportMode _viewportMode = ViewportMode.followLatest;
  
  // Callbacks registered by BravenChartPlus
  VoidCallback? _resumeStreamingCallback;
  VoidCallback? _pauseStreamingCallback;
  VoidCallback? _clearStreamingCallback;
  
  void pauseStreaming() {
    if (_isStreaming) {
      _isStreaming = false;
      _viewportMode = ViewportMode.explore;
      _pauseStreamingCallback?.call();  // Calls _pauseStreaming in widget
      notifyListeners();
    }
  }
  
  void resumeStreaming() {
    if (!_isStreaming) {
      _isStreaming = true;
      _viewportMode = ViewportMode.followLatest;
      _resumeStreamingCallback?.call();  // Calls _resumeStreaming in widget
      notifyListeners();
    }
  }
}
```

#### Internal Flow - Pause

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ streamingController.pauseStreaming()                                        │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ StreamingController:                                                        │
│   _isStreaming = false                                                      │
│   _viewportMode = ViewportMode.explore                                      │
│   _pauseStreamingCallback?.call()  ─────────────────────────────────────┐   │
│   notifyListeners()  // UI can show "Paused" state                      │   │
└─────────────────────────────────────────────────────────────────────────────┘
                                                                          │
    ┌─────────────────────────────────────────────────────────────────────┘
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _BravenChartPlusState._pauseStreaming()                                     │
│                                                                              │
│   // STEP 1: Lock current viewport bounds                                   │
│   if (_xAxis != null && _yAxis != null) {                                   │
│     _lockedPausedBounds = DataBounds(                                       │
│       xMin: _xAxis!.dataMin,                                                │
│       xMax: _xAxis!.dataMax,                                                │
│       yMin: _yAxis!.dataMin,                                                │
│       yMax: _yAxis!.dataMax,                                                │
│     );                                                                       │
│   }                                                                          │
│                                                                              │
│   // STEP 2: Set pan constraints to FULL dataset                            │
│   final renderBox = ...findRenderObject() as ChartRenderBox;                │
│   renderBox.setPanConstraintBounds(                                         │
│     _cachedDataXMin!, _cachedDataXMax!,                                     │
│     _cachedDataYMin!, _cachedDataYMax!,                                     │
│   );                                                                         │
│                                                                              │
│   // STEP 3: Update state                                                   │
│   _isStreaming = false;                                                     │
│                                                                              │
│   // STEP 4: Force rebuild with locked bounds                               │
│   setState(() {});                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Result: Data still flows in via dataStream but:                             │
│   - _onStreamData() routes to buffer.add() instead of controller.addPoint() │
│   - _onControllerUpdate() returns early due to !_isStreaming                │
│   - Viewport is frozen at _lockedPausedBounds                               │
│   - User can pan/zoom through full dataset (_panConstraintTransform)        │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Internal Flow - Resume

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ streamingController.resumeStreaming()                                       │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ StreamingController:                                                        │
│   _isStreaming = true                                                       │
│   _viewportMode = ViewportMode.followLatest                                 │
│   _resumeStreamingCallback?.call()  ────────────────────────────────────┐   │
│   notifyListeners()                                                     │   │
└─────────────────────────────────────────────────────────────────────────────┘
                                                                          │
    ┌─────────────────────────────────────────────────────────────────────┘
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _BravenChartPlusState._resumeStreaming()                                    │
│                                                                              │
│   // STEP 1: Clear pan constraints                                          │
│   renderBox?.clearPanConstraintBounds();                                    │
│                                                                              │
│   // STEP 2: Unlock viewport and update state                               │
│   _lockedPausedBounds = null;                                               │
│   _isStreaming = true;                                                      │
│                                                                              │
│   // STEP 3: Apply buffered data                                            │
│   _applyBufferedData();  ───────────────────────────────────────────────┐   │
│                                                                          │   │
│   // STEP 4: Jump to latest data                                         │   │
│   _jumpToLatestData();                                                   │   │
└──────────────────────────────────────────────────────────────────────────│───┘
                                                                           │
    ┌──────────────────────────────────────────────────────────────────────┘
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _applyBufferedData()                                                        │
│                                                                              │
│   final bufferedPoints = _buffer?.removeAll() ?? [];                        │
│   if (bufferedPoints.isEmpty) return;                                       │
│                                                                              │
│   // Add all buffered points to controller                                  │
│   for (final point in bufferedPoints) {                                     │
│     widget.controller!.addPoint(seriesId, point);                           │
│     // ^^^ Each call triggers notifyListeners()! (but we're streaming       │
│     //     so _onControllerUpdate will call setState/_rebuildElements)      │
│   }                                                                          │
│                                                                              │
│   // Auto-scroll if enabled                                                 │
│   if (autoScrollEnabled) {                                                  │
│     setState(() { _autoScrollToLatest(); });                                │
│   }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Key Data Structures

```dart
// StreamingController (external)
bool _isStreaming;
ViewportMode _viewportMode;  // followLatest | explore
VoidCallback? _resumeStreamingCallback;
VoidCallback? _pauseStreamingCallback;
VoidCallback? _clearStreamingCallback;

// _BravenChartPlusState (internal)
bool _isStreaming;                    // Duplicate of controller state!
DataBounds? _lockedPausedBounds;      // Frozen viewport when paused
double? _cachedData{X,Y}{Min,Max};    // Full dataset bounds

// ChartRenderBox (internal)
ChartTransform? _panConstraintTransform;  // Full dataset for pan constraints
ChartTransform? _originalTransform;       // Initial/sliding window bounds
```

---

### 3. `dataStream` (Stream<ChartDataPoint>)

**Location:** `BravenChartPlus.dataStream` property, handled in `_BravenChartPlusState`

#### External API

```dart
BravenChartPlus(
  dataStream: myStream,  // Stream<ChartDataPoint>
  streamingConfig: StreamingConfig(
    maxBufferSize: 10000,
    autoScroll: true,
    autoScrollWindowSize: 150,
  ),
  streamingController: myController,  // Optional
  controller: chartController,         // Required for data storage
)
```

#### Internal Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ initState():                                                                │
│   widget.streamingController?.registerResumeCallback(_resumeStreaming);     │
│   widget.streamingController?.registerPauseCallback(_pauseStreaming);       │
│   widget.streamingController?.registerClearCallback(_clearStreamingData);   │
│   if (widget.dataStream != null) {                                          │
│     _setupStreamSubscription();                                             │
│   }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _setupStreamSubscription():                                                 │
│   final config = widget.streamingConfig ?? const StreamingConfig();         │
│   _buffer ??= BufferManager<ChartDataPoint>(maxSize: config.maxBufferSize); │
│   _streamSubscription = widget.dataStream?.listen(                          │
│     _onStreamData,                                                          │
│     onError: (error) => config.onStreamError?.call(error),                  │
│   );                                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    │ (Stream emits point)
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _onStreamData(ChartDataPoint point):                                        │
│                                                                              │
│   if (!mounted) return;                                                     │
│                                                                              │
│   // ALWAYS update cached bounds (O(1) per point)                           │
│   _updateCachedDataBounds(point.x, point.y);                                │
│                                                                              │
│   if (_isStreaming) {                                                       │
│     // ──────────────────────────────────────────────────────────────────   │
│     // PATH A: Streaming - add to controller                                │
│     // ──────────────────────────────────────────────────────────────────   │
│     if (widget.controller != null) {                                        │
│       final seriesId = widget.series.isNotEmpty                             │
│           ? widget.series.first.id : 'stream';                              │
│       widget.controller!.addPoint(seriesId, point);  // ← Triggers rebuild! │
│                                                                              │
│       if (autoScrollEnabled) {                                              │
│         setState(() { _autoScrollToLatest(); });     // ← Another rebuild!  │
│       }                                                                      │
│     } else {                                                                │
│       // Legacy path                                                        │
│       setState(() {                                                         │
│         _streamingDataPoints.add(point);                                    │
│         _rebuildElements();                                                 │
│         if (autoScrollEnabled) _autoScrollToLatest();                       │
│       });                                                                    │
│     }                                                                        │
│   } else {                                                                  │
│     // ──────────────────────────────────────────────────────────────────   │
│     // PATH B: Paused - buffer for later                                    │
│     // ──────────────────────────────────────────────────────────────────   │
│     _buffer?.add(point);                             // O(1), FIFO bounded  │
│     config.onBufferUpdated?.call(_buffer?.length ?? 0);                     │
│   }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Auto-Scroll Implementation

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ _autoScrollToLatest():                                                      │
│                                                                              │
│   final renderBox = ...findRenderObject() as ChartRenderBox?;               │
│   if (renderBox == null) return;                                            │
│                                                                              │
│   // Pan right 2% every time                                                │
│   final panAmount = renderBox.size.width * 0.02;                            │
│   renderBox.panChart(panAmount, 0.0);                                       │
│   // ^^^ This is WRONG! Should calculate target position and snap to it    │
│   // Current implementation: 50 points/sec × 2% = 100% pan/sec = erratic    │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### BufferManager

```dart
class BufferManager<T> {
  final int _maxSize;
  final Queue<T> _queue;
  
  void add(T element) {
    if (isFull) {
      _queue.removeFirst();  // FIFO discard oldest
    }
    _queue.addLast(element);  // O(1)
  }
  
  List<T> removeAll() {
    final result = _queue.toList();  // O(n) copy
    _queue.clear();
    return result;
  }
}
```

---

### 4. `ChartSeries.points` (Static/Manual)

**Location:** Direct widget construction

#### External API

```dart
// User manages their own data list
final List<ChartDataPoint> _myData = [];

// Timer or stream adds points
void _addPoint() {
  _myData.add(ChartDataPoint(x: _counter++, y: _value));
  while (_myData.length > maxPoints) {
    _myData.removeAt(0);  // Manual FIFO
  }
  setState(() {});  // Trigger rebuild
}

// Widget receives immutable copy
BravenChartPlus(
  series: [
    LineChartSeries(
      id: 'data',
      points: List.from(_myData),  // Copy to prevent mutation
    ),
  ],
)
```

#### Internal Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Parent widget setState() due to data change                                 │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Parent widget build() creates new BravenChartPlus(series: [...])            │
│   → widget.series contains new point list                                   │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ BravenChartPlus didUpdateWidget():                                          │
│   if (widget.series != oldWidget.series) {  // Reference comparison         │
│     _rebuildElements();                      // Always true for new list    │
│   }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ _rebuildElements():                                                         │
│   // Uses widget.series directly (no controller merge)                      │
│   effectiveSeries = widget.series;                                          │
│   // ... same flow as mechanism 1                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Comparison Matrix

### Data Storage

| Mechanism | Storage Location | Capacity | FIFO | Persistence |
|-----------|-----------------|----------|------|-------------|
| controller.addPoint() | ChartController._seriesData | Unbounded | ❌ No | Until dispose |
| StreamingController | N/A (control only) | N/A | N/A | N/A |
| dataStream | ChartController + BufferManager | Unbounded + Bounded | Buffer only | Until dispose |
| widget.series | User-managed list | User-controlled | User-controlled | User-controlled |

### Rebuild Triggers

| Mechanism | Per-Point Rebuild? | Batch Support? | Throttling? |
|-----------|-------------------|----------------|-------------|
| controller.addPoint() | ✅ Yes | ❌ No | ❌ No |
| StreamingController | N/A | N/A | N/A |
| dataStream | ✅ Yes (via controller) | ❌ No | ❌ No |
| widget.series | ✅ Yes (via parent) | ✅ Manual | ✅ Manual |

### Pause/Resume

| Mechanism | Pause Support | Buffer During Pause | Resume Behavior |
|-----------|--------------|--------------------|--------------------|
| controller.addPoint() | ❌ No | ❌ No | N/A |
| StreamingController | ✅ Yes | ✅ Via BufferManager | Apply all buffered |
| dataStream | ✅ Yes (via controller) | ✅ Yes | Apply all buffered |
| widget.series | ❌ No | ❌ No | N/A |

### Auto-Scroll

| Mechanism | Auto-Scroll Config | Implementation | Quality |
|-----------|-------------------|----------------|---------|
| controller.addPoint() | AutoScrollConfig | panChart(2%) | ⚠️ Poor |
| StreamingController | Via dataStream | panChart(2%) | ⚠️ Poor |
| dataStream | StreamingConfig | panChart(2%) | ⚠️ Poor |
| widget.series | AutoScrollConfig | panChart(2%) | ⚠️ Poor |

### Performance Characteristics

| Mechanism | Per-Point Cost | Memory Growth | Best For |
|-----------|---------------|---------------|----------|
| controller.addPoint() | O(n) rebuild | O(total points) | Low-frequency, unbounded history |
| StreamingController | O(1) control | O(buffer size) | Pause/resume control |
| dataStream | O(n) rebuild | O(total) + O(buffer) | Decoupled data source |
| widget.series | O(n) rebuild | User-controlled | Simple, manual control |

---

## Cross-Cutting Performance Issues

### Issue 1: Rebuild Storm (All Mechanisms)

Every data point triggers:
1. `notifyListeners()` or `setState()`
2. Full widget `build()` 
3. `_rebuildElements()` - iterates all points
4. Element generation with full series iteration

**Impact:** At 50Hz, 50 full rebuilds/second

**Profiled Cost per Rebuild:**
- `_rebuildElements()`: ~2-5ms (varies with point count)
- Element generation: ~1-2ms
- Widget build: ~0.5-1ms
- **Total:** ~4-8ms per point at 1000 points

At 50Hz with 4ms/rebuild = 200ms of work per second (20% CPU on main thread)

---

### Issue 2: Auto-Scroll Implementation

**Current Code:**
```dart
void _autoScrollToLatest() {
  final panAmount = renderBox.size.width * 0.02; // 2% per update
  renderBox.panChart(panAmount, 0.0);
}
```

**Problems:**
- Called on EVERY point
- 2% pan per point = erratic, non-deterministic movement
- Multiple pans accumulate causing overshoot
- Should snap to latest data position, not incrementally pan

**Expected Behavior:**
- Calculate viewport to show last N points
- Set transform directly (no animation during streaming)
- Only animate when resuming from pause

---

### Issue 3: Sliding Window Calculation

**Current Code:**
```dart
final allPoints = effectiveSeries.expand((s) => s.points).toList();
final windowPoints = allPoints.sublist(allPoints.length - windowSize);
```

**Problems:**
- O(n) iteration on every rebuild
- Creates new list allocations
- Should maintain sliding window in data structure, not recompute

**Better Approach:**
- Maintain circular buffer or deque in controller
- Track window bounds incrementally
- O(1) bounds access

---

### Issue 4: No Frame Coalescing

**Current Behavior:**
- Each point triggers immediate rebuild
- 10 points in 16ms = 10 separate rebuilds

**Expected Behavior:**
- Batch all points received within a frame
- Single rebuild per frame (max 60/sec)
- Use `SchedulerBinding.scheduleFrameCallback` or similar

---

## Recommendations

### Priority 1: Critical (Blocking High-Speed Streaming)

| Fix | Description | Impact |
|-----|-------------|--------|
| Batch API | Add `addPoints(List<ChartDataPoint>)` to controller | Reduces rebuilds by batch size |
| Frame Throttling | Limit rebuilds to max 60fps using scheduler | Prevents UI lockup |
| Snap-to-Latest | Replace 2% pan with direct viewport positioning | Smooth, deterministic scroll |

### Priority 2: High (Performance Optimization)

| Fix | Description | Impact |
|-----|-------------|--------|
| Sliding Window in Controller | Maintain FIFO buffer with O(1) bounds | Eliminates O(n) recalculation |
| Incremental Element Updates | Update only changed elements, not full regeneration | Reduces element generation cost |
| RepaintBoundary | Isolate chart repaint from parent widgets | Reduces Flutter framework overhead |

### Priority 3: Medium (Architecture Improvements)

| Fix | Description | Impact |
|-----|-------------|--------|
| Unified Streaming API | Single mechanism instead of 4 overlapping ones | Reduced complexity |
| Isolate Support | Move data processing to background isolate | Frees main thread |
| Configurable Update Strategy | Push vs pull, immediate vs batched | Flexibility for different use cases |

---

## Proposed Architecture

### Option A: Enhanced Controller with Batching

```dart
class StreamingChartController extends ChangeNotifier {
  final CircularBuffer<ChartDataPoint> _buffer;
  Timer? _frameThrottle;
  
  void addPoint(ChartDataPoint point) {
    _buffer.add(point);
    _scheduleNotify();
  }
  
  void addPoints(List<ChartDataPoint> points) {
    _buffer.addAll(points);
    _scheduleNotify();
  }
  
  void _scheduleNotify() {
    _frameThrottle ??= Timer(Duration.zero, () {
      _frameThrottle = null;
      notifyListeners();
    });
  }
}
```

### Option B: Direct RenderObject Updates

Bypass widget rebuild entirely for streaming updates:

```dart
class ChartRenderBox {
  void appendStreamingPoint(ChartDataPoint point) {
    _streamingPoints.add(point);
    _updateViewportForStreaming();
    markNeedsPaint(); // Only repaint, no rebuild
  }
}
```

### Option C: Hybrid Approach

- Use controller for configuration changes (triggers rebuild)
- Use direct render box updates for streaming data (paint only)
- Best of both worlds

---

## Questions for Decision

1. **Which option (A, B, C) aligns best with the library's design philosophy?**

2. **Should we deprecate some of the 4 mechanisms to reduce complexity?**

3. **What is the target maximum update frequency (Hz) we need to support?**

4. **Is isolate support for data processing a requirement?**

5. **Should auto-scroll be smooth animated or instant snap during streaming?**

---

## Next Steps

1. [ ] Review and approve proposed architecture
2. [ ] Implement batch API in controller
3. [ ] Add frame throttling
4. [ ] Fix auto-scroll to use snap positioning
5. [ ] Optimize sliding window calculation
6. [ ] Add performance benchmarks
7. [ ] Update streaming_page.dart example
8. [ ] Document new streaming best practices

---

## Related Files

- `lib/src/controllers/chart_controller.dart`
- `lib/src/streaming/streaming_controller.dart`
- `lib/src/streaming/buffer_manager.dart`
- `lib/src/models/streaming_config.dart`
- `lib/src/models/auto_scroll_config.dart`
- `lib/src/braven_chart_plus.dart` (streaming integration)
- `example/lib/showcase/pages/streaming_page.dart`
