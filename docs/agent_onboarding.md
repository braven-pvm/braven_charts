# Agent Onboarding Guide — braven_charts

> **Purpose**: Get any AI agent or new developer productive in this codebase within minutes.
> Read this FIRST before touching any code.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack & Constraints](#tech-stack--constraints)
3. [Directory Structure](#directory-structure)
4. [Architecture Overview](#architecture-overview)
5. [The Widget → RenderBox Pipeline](#the-widget--renderbox-pipeline)
6. [Coordinate System & ChartTransform](#coordinate-system--charttransform)
7. [Rendering Pipeline (Paint Order)](#rendering-pipeline-paint-order)
8. [Series Cache & GPU Acceleration](#series-cache--gpu-acceleration)
9. [Interaction System](#interaction-system)
10. [Hit Testing & Spatial Index (QuadTree)](#hit-testing--spatial-index-quadtree)
11. [Multi-Axis Normalization](#multi-axis-normalization)
12. [Streaming Architecture](#streaming-architecture)
13. [Data Model Reference](#data-model-reference)
14. [Theming System](#theming-system)
15. [Annotation System](#annotation-system)
16. [Key Files Quick Reference](#key-files-quick-reference)
17. [Common Tasks](#common-tasks)
18. [Performance Budget & Rules](#performance-budget--rules)
19. [Testing](#testing)
20. [Gotchas & Pitfalls](#gotchas--pitfalls)

---

## Project Overview

**braven_charts** (package name: `braven_charts`) is a high-performance, interactive charting library for Flutter. It renders to a custom `RenderBox` (not CustomPainter) for maximum control over layout, painting, and hit testing.

**Key capabilities:**

- Line, area, bar, scatter chart types with bezier/monotone/stepped interpolation
- Multi-axis support with independent Y-axis scales and per-series normalization
- Interactive annotations: point, range, text, threshold, trend, pin, legend
- Crosshair with standard and tracking modes, per-axis labels
- Pan/zoom with animated transitions and viewport constraints
- Real-time streaming at 50Hz+ via `LiveStreamController` (direct RenderBox path)
- GPU-accelerated series layer caching (~170× speedup for hover/overlay)
- QuadTree spatial index for O(log n) hit testing
- Dual scrollbars for pan + zoom
- Full keyboard navigation

**The main public API is a single widget:** `BravenChartPlus`

---

## Tech Stack & Constraints

| Item             | Value                                                                            |
| ---------------- | -------------------------------------------------------------------------------- |
| Language         | Dart 3.10+                                                                       |
| Framework        | Flutter SDK 3.38.6                                                               |
| External deps    | **NONE for core rendering** — pure `dart:ui`, `dart:math`, Flutter standard libs |
| Min Flutter      | 3.10.0                                                                           |
| Platform targets | Web (primary), macOS, Windows                                                    |

**CRITICAL**: No external packages are allowed in the core rendering pipeline. All chart math, rendering, spatial indexing, and interaction logic is implemented from scratch.

---

## Directory Structure

```
lib/
├── braven_charts.dart          # Public barrel export (import this)
└── src/
    ├── braven_chart_plus.dart  # ★ Main widget (StatefulWidget, 2600 lines)
    ├── ai/                     # AI agent interface for natural language chart building
    ├── axis/                   # Axis model, scale, tick generation, rendering
    │   ├── axis.dart           # Axis class (wraps LinearScale + TickGenerator)
    │   ├── linear_scale.dart   # Data↔pixel mapping
    │   ├── tick_generator.dart # Nice-number tick generation
    │   └── x_axis_renderer.dart
    ├── controllers/            # Imperative controllers
    │   ├── chart_controller.dart      # Programmatic data updates
    │   └── annotation_controller.dart # CRUD for annotations
    ├── coordinates/
    │   └── chart_transform.dart # ★ Universal data↔plot coordinate converter
    ├── elements/               # ChartElement implementations
    │   ├── series_element.dart        # ★ Series rendering (line/area/bar/scatter)
    │   ├── annotation_elements.dart   # All annotation element types
    │   ├── resize_handle_element.dart # Drag handles for annotations
    │   └── simulated_*.dart           # Test harness elements
    ├── formatting/             # Value formatters for multi-axis labels
    ├── interaction/
    │   ├── core/
    │   │   ├── chart_element.dart     # ★ Base interface all elements implement
    │   │   ├── coordinator.dart       # ★ Central interaction state machine
    │   │   ├── interaction_mode.dart  # Mode enum with priorities
    │   │   ├── element_types.dart     # Element type enum + priority table
    │   │   ├── hit_test_strategy.dart # Point/line/rect hit strategies
    │   │   └── crosshair_tracker.dart # Nearest-point interpolation
    │   └── recognizers/
    │       ├── priority_pan_recognizer.dart  # Coordinator-aware pan
    │       └── priority_tap_recognizer.dart  # Coordinator-aware tap
    ├── layout/                 # Multi-axis layout computation
    ├── models/                 # ★ All data models (immutable value objects)
    │   ├── chart_series.dart          # Series hierarchy (Line/Area/Bar/Scatter)
    │   ├── chart_data_point.dart      # (x,y) with optional metadata
    │   ├── chart_annotation.dart      # Sealed annotation hierarchy
    │   ├── interaction_config.dart    # Full interaction configuration
    │   ├── x_axis_config.dart         # X-axis configuration
    │   ├── y_axis_config.dart         # Y-axis configuration
    │   └── ...                        # Theme, grid, streaming configs
    ├── rendering/
    │   ├── chart_render_box.dart      # ★ Custom RenderBox (2639 lines) — THE engine
    │   ├── spatial_index.dart         # QuadTree for hit testing
    │   ├── grid_renderer.dart         # Grid line painting
    │   ├── multi_axis_painter.dart    # Y-axis tick/label painting
    │   ├── multi_axis_normalizer.dart # Normalization math
    │   ├── x_axis_painter.dart        # X-axis painting
    │   └── modules/                   # ★ RenderBox is decomposed into modules:
    │       ├── event_handler_manager.dart   # All pointer event routing
    │       ├── crosshair_renderer.dart      # Crosshair + tracking mode
    │       ├── tooltip_renderer.dart        # Smart tooltip positioning
    │       ├── tooltip_animator.dart        # Show/hide animation timing
    │       ├── series_cache_manager.dart    # GPU Picture caching
    │       ├── multi_axis_manager.dart      # Multi-axis state & rendering
    │       ├── scrollbar_manager.dart       # Dual scrollbar state
    │       ├── streaming_manager.dart       # Live data viewport management
    │       ├── annotation_drag_handler.dart # Annotation move/resize logic
    │       ├── viewport_constraints.dart    # Zoom/pan limit enforcement
    │       └── zoom_animator.dart           # Smooth zoom with easing
    ├── streaming/
    │   ├── live_stream_controller.dart   # ★ High-perf streaming (recommended)
    │   ├── streaming_buffer.dart         # Circular buffer, zero alloc
    │   ├── streaming_controller.dart     # Legacy streaming controller
    │   └── buffer_manager.dart           # Pause-mode FIFO buffer
    ├── theming/                # Visual theme components
    │   ├── components/        # SeriesTheme, AxisStyle, GridStyle, etc.
    │   └── styles/            # Reusable label/text styles
    ├── utils/
    │   └── data_converter.dart # Series→Element conversion
    └── widgets/               # Supporting Flutter widgets
        ├── chart_legend.dart  # Widget-based legend (legacy)
        ├── web_context_menu.dart # Right-click context menu
        ├── scrollbar/         # Scrollbar widgets
        └── dialogs/           # Annotation creation/edit dialogs
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   BravenChartPlus (StatefulWidget)           │
│                                                              │
│  _BravenChartPlusState                                       │
│  ├── _rebuildElements()  → closure that generates elements   │
│  ├── Manages streaming subscriptions                         │
│  ├── Handles widget lifecycle (didUpdateWidget, dispose)     │
│  └── build() → RawGestureDetector + _ChartRenderWidget       │
│                                                              │
│  _ChartRenderWidget (LeafRenderObjectWidget)                 │
│  └── Creates / Updates ChartRenderBox                        │
└─────────────┬───────────────────────────────────────────────┘
              │ createRenderObject / updateRenderObject
              ▼
┌─────────────────────────────────────────────────────────────┐
│                   ChartRenderBox (RenderBox)                  │
│                                                              │
│  THE rendering engine. Everything flows through here.        │
│                                                              │
│  ┌──────────────┐  ┌───────────────────┐  ┌──────────────┐ │
│  │ performLayout │  │     paint()       │  │ handleEvent  │ │
│  │ • Plot area   │  │ • Grid → Axes    │  │ • Pointer    │ │
│  │ • Transform   │  │ • Series (cached) │  │   routing    │ │
│  │ • Spatial idx │  │ • Annotations    │  │ • Hit test   │ │
│  │ • Axis sync   │  │ • Overlays       │  │ • Drag/pan   │ │
│  └──────────────┘  │ • Scrollbars     │  └──────────────┘ │
│                     └───────────────────┘                    │
│  Modules (delegate pattern):                                 │
│  ├── EventHandlerManager    ├── CrosshairRenderer            │
│  ├── SeriesCacheManager     ├── TooltipRenderer              │
│  ├── MultiAxisManager       ├── ScrollbarManager             │
│  ├── StreamingManager       ├── AnnotationDragHandler        │
│  ├── ViewportConstraints    └── ZoomAnimator                 │
│                                                              │
│  State:                                                      │
│  ├── _transform (ChartTransform)  — current viewport         │
│  ├── _originalTransform           — initial for constraints   │
│  ├── _elements (List<ChartElement>) — all renderable items   │
│  ├── _spatialIndex (QuadTree)     — O(log n) hit testing     │
│  ├── coordinator (ChartInteractionCoordinator)               │
│  └── _seriesCacheManager          — GPU Picture cache        │
└─────────────────────────────────────────────────────────────┘
              │ data flow
              ▼
┌─────────────────────────────────────────────────────────────┐
│  ChartElement (interface) — unified element model            │
│  ├── SeriesElement      — renders line/area/bar/scatter      │
│  ├── *AnnotationElement — renders each annotation type       │
│  └── ResizeHandleElement — drag handles on annotations       │
│                                                              │
│  Each element provides:                                      │
│  • bounds (Rect) for spatial indexing                        │
│  • hitTest(Offset) for precise detection                    │
│  • paint(Canvas, Size) for rendering                        │
│  • priority for hit-test conflict resolution                │
│  • renderOrder for z-index paint ordering                   │
└─────────────────────────────────────────────────────────────┘
```

---

## The Widget → RenderBox Pipeline

### Data Flow (from user API to pixels)

```
1. User creates BravenChartPlus(series: [...], annotations: [...])
                    │
2. _BravenChartPlusState.initState()
   └── _rebuildElements()
       ├── Merges series + controller data + streaming data
       ├── Computes data bounds (x/y min/max)
       ├── Runs normalization detection
       ├── Creates Axis objects from XAxisConfig/YAxisConfig
       └── Builds _elementGenerator closure:
           (ChartTransform) → List<ChartElement>
                    │
3. build() creates _ChartRenderWidget → ChartRenderBox
   └── updateRenderObject() calls:
       ├── setElementGenerator(closure, version)
       ├── setXAxis(axis), setYAxis(axis)
       ├── setTheme(theme), setInteractionConfig(config)
       └── ...other setters
                    │
4. ChartRenderBox.performLayout()
   ├── Computes plot area (margins for axes, scrollbars)
   ├── Creates ChartTransform from data bounds + plot dimensions
   ├── Calls _elementGenerator(transform) → List<ChartElement>
   ├── Builds QuadTree spatial index from elements
   └── Stores _originalTransform for zoom/pan constraints
                    │
5. ChartRenderBox.paint()
   └── Paints layers in order (see Rendering Pipeline)
```

### Element Regeneration

Elements are regenerated (via `_elementGenerator`) when:

- Series data changes
- Theme changes
- Annotations change
- Zoom/pan completes (deferred, not during drag)
- Chart is resized

Elements are **NOT** regenerated during:

- Hover events (only overlay repaints)
- Active panning (deferred to pan end for performance)
- Tooltip display

---

## Coordinate System & ChartTransform

`ChartTransform` (`lib/src/coordinates/chart_transform.dart`) is the **universal bidirectional converter** between two coordinate spaces:

| Space          | Description             | Example Values                            |
| -------------- | ----------------------- | ----------------------------------------- |
| **Data Space** | Logical data values     | x=1609459200 (timestamp), y=250 (watts)   |
| **Plot Space** | Pixels within plot area | x=365.0, y=270.0 (0,0 = top-left of plot) |

### Key Operations

```dart
// Data → Plot (for rendering)
Offset plotPos = transform.dataToPlot(dataX, dataY);

// Plot → Data (for hit testing, tooltips)
Offset dataPos = transform.plotToData(plotX, plotY);

// Viewport manipulation (returns new immutable instance)
ChartTransform zoomed = transform.zoom(2.0, plotCenter);
ChartTransform panned = transform.pan(deltaX, deltaY);

// Visibility culling
bool visible = transform.isDataPointVisible(dataX, dataY);
```

### Coordinate Relationships

```
Widget Space (Flutter logical pixels)
├── Title area
├── Subtitle area
├── Chart area
│   ├── Left Y-axis labels (leftMargin)
│   ├── Plot area ← ChartTransform operates HERE
│   │   └── (0,0) top-left, (plotWidth, plotHeight) bottom-right
│   │       Y is INVERTED: dataY=max at top, dataY=min at bottom
│   └── Right Y-axis labels (rightMargin)
├── X-axis labels (bottomMargin)
└── Scrollbar area
```

### Transform Lifecycle

- **`_transform`**: Current viewport (modified by zoom/pan)
- **`_originalTransform`**: Frozen at initial layout — used for zoom limits and scrollbar sizing
- **`_panConstraintTransform`**: Optional override for paused streaming (full dataset pan bounds)

The transform is **immutable**. Every zoom/pan creates a new instance via `copyWith()`, `zoom()`, or `pan()`.

---

## Rendering Pipeline (Paint Order)

`ChartRenderBox.paint()` renders in strict layer order (back to front):

```
1. BACKGROUND
   └── Fill with theme.backgroundColor

2. GRID (behind everything)
   ├── Vertical grid lines at X-axis tick positions
   └── Horizontal grid lines at Y-axis tick positions

3. AXES (in margin areas, outside plot clip)
   ├── MultiAxisPainter → all Y-axes (left + right side)
   └── XAxisPainter → X-axis (bottom)

4. [canvas.save() + translate to plot origin + clip to plot area]

5. BACKGROUND ANNOTATIONS (renderOrder < series)
   └── Range annotations, etc. painted behind data

6. SERIES LAYER (GPU-cached)
   ├── Cache HIT  → draw cached Picture (~0.1ms)
   └── Cache MISS → generate Picture via PictureRecorder (~17ms)
       ├── For each SeriesElement (sorted by priority):
       │   ├── Resolve per-axis transform (multi-axis mode)
       │   ├── series.updateTransform(currentTransform)
       │   └── series.paint(canvas, size)
       └── Store Picture in SeriesCacheManager

7. STREAMING ELEMENTS (uncached, fresh every frame)
   └── Live data elements painted directly

8. FOREGROUND ANNOTATIONS (renderOrder >= series)
   └── Point, text, threshold, trend, pin annotations

9. [canvas.restore() — removes clip]

10. OVERLAY LAYER (saveLayer only when active content exists)
    ├── Box selection rectangle
    ├── Range creation rubber-band
    ├── Crosshair lines + coordinate labels
    └── Tooltips with animation

11. SCROLLBARS (outside all clipping)
    └── Horizontal + vertical scrollbar handles
```

**Critical optimization**: Steps 5–8 happen inside a `canvas.save()/restore()` block that translates the origin to the plot area's top-left corner and clips to its bounds. All element coordinates are in **plot-local space** (0,0 = plot area origin).

---

## Series Cache & GPU Acceleration

`SeriesCacheManager` (`lib/src/rendering/modules/series_cache_manager.dart`) provides the single biggest performance win:

| Scenario        | Without Cache | With Cache   | Speedup  |
| --------------- | ------------- | ------------ | -------- |
| Hover/crosshair | ~17ms/frame   | ~0.1ms/frame | **170×** |

### How It Works

1. On first paint (or after invalidation), series are rendered into a `PictureRecorder`
2. The recorded `Picture` is a GPU-accelerated display list
3. Subsequent frames just `canvas.drawPicture(cachedPicture)` — near-instant
4. Cache is invalidated when data/theme/transform changes

### Cache Invalidation Triggers

| Event              | Invalidates? | Why                                |
| ------------------ | ------------ | ---------------------------------- |
| Series data change | ✅ Yes       | Different paths to draw            |
| Theme change       | ✅ Yes       | Different colors/styles            |
| Zoom/pan complete  | ✅ Yes       | Need to regenerate at new viewport |
| Hover              | ❌ No        | Only overlay layer repaints        |
| Crosshair move     | ❌ No        | Only overlay layer repaints        |
| Annotation drag    | ❌ No        | Annotation layer != series layer   |
| Box selection      | ❌ No        | Only overlay layer repaints        |

The cache uses a **content hash** (element count + IDs + point counts) plus **transform bounds comparison** to detect staleness.

---

## Interaction System

### ChartInteractionCoordinator

Central state machine (`lib/src/interaction/core/coordinator.dart`) that prevents gesture conflicts. **Only one interaction mode is active at a time.**

### Interaction Modes (priority order, highest first)

| Priority | Mode                         | Trigger                            |
| -------- | ---------------------------- | ---------------------------------- |
| 10       | `contextMenuOpen`            | Right-click (MODAL — blocks all)   |
| 10       | `rangeAnnotationCreation`    | Context menu → "Add Range" (MODAL) |
| 9        | `resizingAnnotation`         | Drag resize handle                 |
| 9        | `editingAnnotation`          | Double-click annotation            |
| 8        | `draggingAnnotation`         | Drag annotation body               |
| 7        | `draggingDataPoint`          | Drag a data point                  |
| 6        | `selecting` / `boxSelecting` | Click / drag on empty space        |
| 4        | `scrollbarDragging`          | Drag scrollbar handle              |
| 3        | `panning`                    | Middle-click drag                  |
| 1        | `zooming`                    | Mouse wheel                        |
| 0        | `hovering` / `idle`          | Passive states                     |

### Conflict Resolution Rules

- Higher priority modes can interrupt lower priority
- Modal modes (priority 10) block everything
- `coordinator.claimMode(requestedMode)` returns `true` if claimed, `false` if blocked
- `coordinator.releaseMode()` returns to idle (except modal — needs `force: true`)

### Event Routing

All pointer events flow through `EventHandlerManager` (delegate pattern):

```
PointerEvent → ChartRenderBox.handleEvent()
    → _eventHandlerManager.handleEvent()
        ├── Check modal state
        ├── PointerDown:
        │   ├── Test scrollbar hit (highest priority)
        │   ├── Test resize handle hit
        │   ├── Middle button → claim panning mode
        │   ├── Right button → context menu
        │   └── Left button → prepare potential drag (5px threshold)
        ├── PointerMove:
        │   ├── Active drag → update annotation/pan position
        │   ├── Potential drag → check threshold → promote to active
        │   └── Hover → hit test → update cursor + tooltip
        ├── PointerUp:
        │   ├── Complete drag → finalize annotation position
        │   ├── <5px movement → treat as click (select/deselect)
        │   └── Release interaction mode → idle
        └── PointerScroll:
            └── Zoom at cursor position (with constraints)
```

### Drag Threshold

All drags use a **5px threshold** — movement below 5px is treated as a click/tap, not a drag. This prevents accidental drags during clicks.

---

## Hit Testing & Spatial Index (QuadTree)

`QuadTree` (`lib/src/rendering/spatial_index.dart`) provides O(log n) hit testing:

### Structure

- Recursively divides 2D space into 4 quadrants
- Max 4 elements per node before splitting
- Max depth 8 to prevent infinite recursion
- Elements spanning 3+ quadrants stay at parent level (prevents exponential duplication)
- Uses `Set<ChartElement>` for results to deduplicate

### Hit Test Flow

```
1. Pointer position (widget space)
2. Convert to plot-local space
3. QuadTree.query(position, radius: hitRadius)
4. Filter: element.hitTest(position) for precise check
5. Sort by element.priority (highest wins)
6. Return top-priority hit
```

### Hit Priority Table

| Element Type    | Priority | Hit Zone                                  |
| --------------- | -------- | ----------------------------------------- |
| Resize handle   | 7        | 8×8px squares at annotation corners/edges |
| Annotation body | 5        | Filled rectangle/polygon                  |
| Data point      | 4        | Circle with configurable radius           |
| Series line     | 3        | Line path ± stroke width / 2              |
| Background      | 0        | Entire plot area                          |

Higher priority wins when elements overlap at the same pixel.

### Spatial Index Rebuild

The QuadTree is rebuilt when:

- Elements are regenerated (`updateElements()`)
- Selection changes that affect element bounds
- Layout changes

Deferred rebuild: `_spatialIndexDirty = true` delays the expensive rebuild until the next actual query or paint, avoiding 2s freezes when many charts are on screen.

---

## Multi-Axis Normalization

When series have vastly different Y ranges (e.g., Power 0–400W vs Heart Rate 60–200bpm), the multi-axis system normalizes them to a shared [0,1] range for rendering.

### Modes (`NormalizationMode`)

| Mode        | Behavior                                                               |
| ----------- | ---------------------------------------------------------------------- |
| `auto`      | Auto-detect when Y ranges differ by >10× (via `NormalizationDetector`) |
| `perSeries` | Always normalize each axis independently                               |
| `none`      | Never normalize — use global Y scale                                   |

### How It Works

```
1. Each series has a yAxisConfig (inline) or yAxisId (shared reference)
2. MultiAxisManager groups series by axis
3. For each axis, compute data range (min, max)
4. MultiAxisNormalizer.normalize(value, min, max) → [0,1]
5. Series are rendered in normalized [0,1] Y space
6. Y-axis labels display ORIGINAL values via denormalize()
7. Crosshair labels show original values per axis
```

### Key Classes

- `MultiAxisNormalizer` — stateless math (normalize, denormalize, computeAxisBounds)
- `MultiAxisManager` — module on RenderBox managing axis state/caching
- `MultiAxisPainter` — renders Y-axis ticks/labels in original value space
- `SeriesAxisBinding` — maps series ID → axis ID
- `NormalizationDetector` — auto-detection logic with configurable ratio threshold

---

## Streaming Architecture

### Two Streaming Paths

| Path            | Controller                           | Performance                    | Use Case                              |
| --------------- | ------------------------------------ | ------------------------------ | ------------------------------------- |
| **Recommended** | `LiveStreamController`               | 50Hz+, bypasses widget rebuild | Real-time sensor data, high-frequency |
| **Legacy**      | `StreamingController` + `dataStream` | Lower, triggers setState       | Simple low-frequency updates          |

### LiveStreamController Data Flow

```
Source (sensor, API, etc.)
    │
    ▼  addPoint(ChartDataPoint)
┌──────────────────────────────┐
│   LiveStreamController       │
│   ├── StreamingBuffer        │  ← Circular buffer, O(1) add
│   │   (zero alloc, pre-allocd)│     with sliding window eviction
│   ├── Frame coalescing       │  ← Batches all points per vsync
│   └── addPostFrameCallback   │
└──────────┬───────────────────┘
           │  (bypasses State/build entirely)
           ▼
┌──────────────────────────────┐
│   ChartRenderBox             │
│   .setStreamingData()        │  ← Direct reference to buffer
│   .markNeedsPaint()          │  ← Only repaint, no relayout
└──────────────────────────────┘
```

### Key Properties of StreamingBuffer

- **Circular buffer** with pre-allocated `List<ChartDataPoint>`
- **Zero steady-state allocations** — only initial alloc
- **Incremental bounds tracking** — O(1) per add, with throttled full recalc
- **Version counter** for efficient change detection

### Pause/Resume

- **Pause**: viewport freezes, incoming data goes to `BufferManager` (FIFO)
- **Resume**: bulk-apply buffered data, flush to RenderBox, unlock viewport
- **Pan constraints when paused**: `_panConstraintTransform` provides full dataset bounds for exploration

---

## Data Model Reference

### ChartSeries Hierarchy

```dart
ChartSeries (base)           // id, name, points, color, yAxisConfig, yAxisId, unit
├── LineChartSeries           // interpolation, strokeWidth, tension, showDataPointMarkers
├── AreaChartSeries           // interpolation, strokeWidth, fillOpacity
├── BarChartSeries            // barWidthPercent or barWidthPixels
└── ScatterChartSeries        // markerRadius
```

### ChartDataPoint

```dart
ChartDataPoint(
  x: 1.0,           // required double
  y: 42.0,          // required double
  timestamp: dt,     // optional DateTime
  label: 'Peak',    // optional String (tooltip)
  metadata: {...},   // optional Map (excluded from equality)
  segmentStyle: ..., // optional per-segment color override
  pointStyle: ...,   // optional per-point style override
)
```

### ChartAnnotation (sealed class)

```dart
sealed class ChartAnnotation
├── PointAnnotation       // marks a specific data point
├── RangeAnnotation       // rectangular region highlight
├── TextAnnotation        // text at screen coordinates (supports rich text)
├── ThresholdAnnotation   // horizontal/vertical reference line
├── PinAnnotation         // marker at arbitrary x,y (not tied to series)
├── TrendAnnotation       // statistical trend line (linear, polynomial, MA, EMA)
└── LegendAnnotation      // draggable canvas legend
```

All types support `toJson()`, `copyWith()`, and exhaustive `switch` matching.

### InteractionConfig

```dart
InteractionConfig(
  crosshair: CrosshairConfig(enabled: true, mode: CrosshairMode.both),
  tooltip: TooltipConfig(enabled: true, triggerMode: TooltipTriggerMode.hover),
  gesture: GestureConfig(tapTimeout: 200),
  keyboard: KeyboardConfig(enabled: true),
  enableZoom: true,
  enablePan: true,
)
```

---

## Theming System

Located in `lib/src/theming/`:

```
theming/
├── components/
│   ├── series_theme.dart       # Colors, line widths, marker shapes (cycling lists)
│   ├── axis_style.dart         # Axis line, ticks, labels
│   ├── grid_style.dart         # Grid line colors, widths
│   ├── interaction_theme.dart  # Crosshair, tooltip, selection colors
│   ├── annotation_theme.dart   # Annotation visual defaults
│   ├── animation_theme.dart    # Animation durations/curves
│   ├── scrollbar_config.dart   # Scrollbar visual/behavior config
│   └── typography_theme.dart   # Font styles
└── styles/
    └── label_style.dart        # Reusable label styling (background, border, padding)
```

`ChartTheme` (`lib/src/models/chart_theme.dart`) aggregates these into a single theme object.

---

## Annotation System

Annotations are managed via `AnnotationController` or passed as static list:

```dart
// Reactive (recommended for editable annotations)
final controller = AnnotationController();
controller.addAnnotation(RangeAnnotation(...));
BravenChartPlus(annotationController: controller, ...)

// Static (auto-wrapped in internal controller for drag support)
BravenChartPlus(annotations: [ThresholdAnnotation(...)], ...)
```

### Annotation Rendering

Each annotation type has a corresponding element class:

- `PointAnnotation` → `PointAnnotationElement`
- `RangeAnnotation` → `RangeAnnotationElement`
- `TextAnnotation` → `TextAnnotationElement`
- etc.

Element conversion happens in `_rebuildElements()` via exhaustive `switch` on the sealed `ChartAnnotation` class.

### Drag/Resize

- Annotations with `allowDragging: true` can be moved and resized
- Resize handles appear when selected (8 handles: 4 corners + 4 edges)
- Drag state managed by `AnnotationDragHandler` module
- Changes fire `onAnnotationChanged` callback and update via `AnnotationController`

---

## Key Files Quick Reference

| When you need to...          | Look at                                                                              |
| ---------------------------- | ------------------------------------------------------------------------------------ |
| Understand the public API    | `lib/braven_charts.dart` (barrel export)                                             |
| Modify the main widget       | `lib/src/braven_chart_plus.dart`                                                     |
| Change rendering behavior    | `lib/src/rendering/chart_render_box.dart`                                            |
| Fix coordinate bugs          | `lib/src/coordinates/chart_transform.dart`                                           |
| Fix interaction/gesture bugs | `lib/src/rendering/modules/event_handler_manager.dart`                               |
| Fix hit testing              | `lib/src/rendering/spatial_index.dart`                                               |
| Fix crosshair/tooltip        | `lib/src/rendering/modules/crosshair_renderer.dart` / `tooltip_renderer.dart`        |
| Add/modify chart types       | `lib/src/elements/series_element.dart`                                               |
| Add/modify annotation types  | `lib/src/elements/annotation_elements.dart` + `lib/src/models/chart_annotation.dart` |
| Fix multi-axis rendering     | `lib/src/rendering/modules/multi_axis_manager.dart`                                  |
| Fix streaming                | `lib/src/streaming/live_stream_controller.dart`                                      |
| Add axis features            | `lib/src/axis/axis.dart` + `lib/src/rendering/multi_axis_painter.dart`               |
| Run example app              | `example/lib/main.dart`                                                              |

---

## Common Tasks

### Adding a New Chart Type

1. Add variant to `ChartType` enum in `lib/src/models/chart_type.dart`
2. Create new `XxxChartSeries` subclass in `lib/src/models/chart_series.dart`
3. Add rendering logic in `SeriesElement.paint()` (`lib/src/elements/series_element.dart`)
4. Handle in `DataConverter.seriesToElements()` (`lib/src/utils/data_converter.dart`)

### Adding a New Annotation Type

1. Add to sealed class hierarchy in `lib/src/models/chart_annotation.dart`
2. Create `XxxAnnotationElement` in `lib/src/elements/annotation_elements.dart`
3. Add conversion case in `_BravenChartPlusState._rebuildElements()`
4. Add drag support in `EventHandlerManager` if needed

### Modifying Zoom/Pan Behavior

1. Zoom constraints: `lib/src/rendering/modules/viewport_constraints.dart`
2. Zoom animation: `lib/src/rendering/modules/zoom_animator.dart`
3. Pan clamping: `ChartRenderBox._clampPanDelta()`
4. Keyboard zoom: `EventHandlerManager._handleKeyboardZoom()`

### Debugging Rendering Issues

1. Enable `showDebugInfo: true` on the widget for overlay diagnostics
2. Check `ChartTransform` values — most visual bugs are wrong coordinate transforms
3. Verify `_plotArea` rect in `performLayout()` — margin calculation errors cause misalignment
4. Check render order — elements with wrong `renderOrder` paint in wrong layer

---

## Performance Budget & Rules

### Frame Budget

| Target        | Budget                      |
| ------------- | --------------------------- |
| 60fps         | 16.6ms per frame            |
| Paint (hover) | <1ms (with series cache)    |
| Paint (full)  | <17ms (series regeneration) |
| Hit test      | <1ms (QuadTree)             |
| Layout        | <5ms                        |

### Critical Performance Rules

1. **NEVER regenerate elements during pan drag** — defer to pan end
2. **NEVER rebuild spatial index on hover** — use dirty flag + deferred rebuild
3. **NEVER invalidate series cache for overlay-only changes** (hover, crosshair, selection)
4. **NEVER use `setState()` in hot paths** — streaming uses direct RenderBox path
5. **Hit test throttling**: 50ms debounce on hover to avoid per-pixel QuadTree queries
6. **Overlay saveLayer is conditional** — only allocated when active overlay content exists (avoids GPU texture allocation on idle charts in galleries with 21+ charts)
7. **Deferred selection clear** — `clearSelection()` is deferred to pointer-up to avoid ~2s synchronous rebuild during pointer-down

### Memory

- Series cache: ~170KB typical (5 series × 1000 points)
- StreamingBuffer: Pre-allocated, zero steady-state GC pressure
- QuadTree: Proportional to element count, capped at depth 8

---

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/some_test.dart

# Run with coverage
flutter test --coverage

# Run analyzer (must pass with "No issues found!")
flutter analyze

# Format code
dart format .
```

### Test Structure

```
test/
├── unit/          # Pure logic tests (transforms, normalization, models)
├── widget/        # Widget rendering tests
├── golden/        # Visual regression tests
├── integration/   # Full chart interaction tests
├── performance/   # Benchmark tests
├── web/           # ChromeDriver web tests
├── contract/      # API contract tests
├── fixtures/      # Shared test data
└── mocks/         # Mock implementations
```

### YOU TOUCH IT, YOU OWN IT

Per project rules: if you modify ANY file, you must run `flutter analyze` and fix **ALL** issues (errors, warnings, AND infos) in that file. Zero tolerance — "pre-existing" is not an excuse.

---

## Gotchas & Pitfalls

### 1. Widget-Provided vs Zoomed Bounds

The RenderBox tracks TWO bounds concepts:

- `_widgetProvidedXMin/XMax/YMin/YMax` — FULL data range from the widget (never zoomed)
- `_originalTransform` — initial transform (can evolve during chart switches)

When annotations change, the widget rebuilds with full data range. The `setXAxis()`/`setYAxis()` methods detect if bounds match widget-provided and **skip transform updates** to preserve zoom/pan state. Getting this wrong causes "zoom reset on annotation edit" bugs.

### 2. Plot-Local vs Widget-Local Coordinates

During `paint()`, after `canvas.save() + translate`, all coordinates are **plot-local** (0,0 = plot area origin). Elements store bounds in plot space. But pointer events arrive in **widget space** and must be converted via `widgetToPlot()`.

### 3. Series Element Transform Updates

`SeriesElement` stores both an initial `transform` (for bounds computation) and a `_currentTransform` (for painting). Call `series.updateTransform(currentTransform)` before `series.paint()` to handle zoom/pan correctly.

### 4. Coordinator Must Be Checked Before Claiming

Always check `coordinator.canStartInteraction(mode)` before calling `claimMode()`. Modal states (context menu open, annotation editing) silently reject claims.

### 5. Multi-Axis Bounds Are Viewport-Aware

`_computeAxisBounds(forPainting: true)` returns bounds matching the VISIBLE viewport (for correct series rendering during zoom). `_computeAxisBounds(forceFullBounds: true)` returns full data bounds (for axis label range computation).

### 6. \_spatialIndexDirty

The QuadTree rebuild is deferred. When you modify elements, set `_spatialIndexDirty = true` instead of calling `_rebuildSpatialIndex()` directly. The rebuild happens lazily on the next query/paint.

### 7. Series Cache Invalidation

If you change anything that affects how SERIES are drawn (not overlays), remember to call `_seriesCacheManager.invalidate()`. Forgetting this causes stale rendering.

### 8. The 2617 + 2639 Line Files

`braven_chart_plus.dart` (2617 lines) and `chart_render_box.dart` (2639 lines) are the two largest files. The RenderBox is decomposed into **modules** in `rendering/modules/` via the delegate pattern to manage complexity. When adding features, prefer extending a module or creating a new one over adding more code to these files.

---

## Related Documentation

- [docs/development.md](../development.md) — Development setup, TDD workflow, code standards
- [docs/api.md](../api.md) — Public API reference
- [docs/guides/coordinate-system.md](../guides/coordinate-system.md) — Full coordinate space theory
- [docs/guides/chart-types.md](../guides/chart-types.md) — Chart type rendering details
- [docs/guides/theming-usage.md](../guides/theming-usage.md) — Theming guide
- [docs/guides/annotation_quick_reference.md](../guides/annotation_quick_reference.md) — Annotation types
- [docs/technical_debt.md](../technical_debt.md) — Known debt and TODOs
