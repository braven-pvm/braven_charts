## [Unreleased]

### Added

- Per-segment color and style overrides for line chart series (012-segment-colors)
  - `SegmentStyle` class with `color` and `strokeWidth` properties
  - `segmentStyle` field on `ChartDataPoint` for per-segment styling
  - Helper extensions: `withSegmentStyles()`, `withSegmentColors()`, `withStyleInRange()`, `withColorWhere()`
  - Sharp color transitions at data points with smooth bezier curve continuity
  - Performance optimized: fast-path when no overrides, batches consecutive same-style segments
- Multi-axis Y normalization for displaying series with vastly different scales
  - Each series uses full vertical height with its own Y-axis
  - Up to 4 Y-axes supported (left, leftOuter, right, rightOuter)
  - Color-coded axes match their bound series
  - Tooltips and crosshair display original (non-normalized) values
- Automatic normalization detection when series ranges differ >10x
- New `yAxisId` and `unit` fields on `ChartSeries` for direct axis binding
- `YAxisConfig` class for configuring additional Y-axes
- `NormalizationMode` enum: `none`, `auto`, `perSeries`
- `SeriesAxisBinding` class for explicit series-to-axis bindings
- `SeriesAxisResolver` utility for resolving axis bindings
- `NormalizationDetector` for automatic range ratio analysis

### Changed

- `BravenChartPlus` widget now accepts `yAxes`, `normalizationMode`, and `axisBindings` parameters

---

## 0.0.1

### Dual-Mode Streaming (009-dual-mode-streaming)

**Breaking Changes**
- Added required `ChartMode` enum to support streaming/interactive mode transitions
- Added optional `StreamingConfig` parameter to `BravenChart` widget
- Added optional `StreamingController` parameter for manual mode control
- Charts with `dataStream` now default to `ChartMode.streaming` mode

**Migration Guide**

If you were using real-time data streams:

```dart
// Before (v0.0.0):
BravenChart(
  chartType: ChartType.line,
  // No streaming support - manual data updates only
  data: ChartSeries(...),
)

// After (v0.0.1):
BravenChart(
  chartType: ChartType.line,
  dataStream: myDataStream,  // NEW: Stream<ChartDataPoint> support
  streamingConfig: StreamingConfig(),  // NEW: Dual-mode behavior
)
```

If you were NOT using streaming, no migration needed - existing code works unchanged.

**Core Infrastructure**

**Models & Configuration**
- Added `ChartMode` enum - Defines chart operating modes (streaming, interactive)
- Added `StreamingConfig` class - Configurable dual-mode streaming behavior
  * `autoResumeTimeout` - Auto-resume after inactivity (default: 10s)
  * `maxBufferSize` - Buffer limit for interactive mode (default: 10,000 points)
  * `pauseOnFirstInteraction` - Auto-pause on user interaction (default: true)
  * `onModeChanged` - Callback when mode transitions occur
  * `onBufferUpdated` - Callback when data buffered in interactive mode
  * `onReturnToLive` - Callback when chart enters interactive mode
  * `onStreamError` - Callback for stream error handling (no automatic retry)

**Controller API**
- Added `StreamingController` class - Manual mode control API
  * `pauseStreaming()` - Programmatically pause streaming mode
  * `resumeStreaming()` - Programmatically resume to streaming mode
  * `currentMode` - ValueNotifier<ChartMode> for reactive mode tracking

**Widget Integration**
- Updated `BravenChart` widget with streaming support
  * `dataStream` parameter - Stream<ChartDataPoint> for real-time data
  * `streamingConfig` parameter - Optional streaming configuration
  * `streamingController` parameter - Optional manual control
- Automatic stream subscription management (lifecycle-aware)
- Hot reload handling (resets to streaming mode on hot reload)

**User Stories Implemented**

**US1: Real-Time Streaming Mode** (Priority 1)
- 60fps rendering with <16ms frame time (SC-001, SC-004)
- Zero-latency data updates in streaming mode (SC-002)
- Smooth transitions without visible gaps (SC-005)

**US2: Interactive Mode with Auto-Pause** (Priority 2)
- Automatic pause on first user interaction (hover, click, zoom, pan)
- Silent data buffering during interactive mode (SC-008)
- Visual mode indicator support via callbacks

**US3: Automatic Resume** (Priority 2)
- Configurable inactivity timeout (1-60s recommended)
- Timer reset on any user interaction
- Smooth buffer application (<500ms for 10K points - SC-007)

**US4: Manual Mode Control** (Priority 3)
- StreamingController API for programmatic mode control
- Imperative pause/resume methods
- Reactive mode tracking via ValueNotifier

**US5: Buffer Status Visibility** (Priority 3)
- Real-time buffer count via `onBufferUpdated` callback
- Force-resume on buffer overflow (maxBufferSize reached)
- Developer-controlled buffer status UI

**Error Handling & Edge Cases**
- Stream error callback (`onStreamError`) with graceful degradation
- No automatic retry (developer responsibility per FR-017b)
- Robust handling of: no stream, rapid mode switches, stream ends, buffer overflow, rapid interactions
- Hot reload handling via `reassemble()` override
- All 36 integration tests passing (100% success rate)

**Performance Characteristics**
- 60fps streaming with <16ms frame time (SC-001, SC-004)
- Zero-latency updates in streaming mode (SC-002)
- <50ms mode transitions (SC-003)
- <500ms buffer application for 10K points (SC-007)
- Memory-safe operation for 1-hour sessions (SC-009)
- All performance benchmarks validated

**Documentation & Examples**
- Comprehensive README.md section with quick start and advanced patterns
- Three progressive examples:
  * `basic_streaming_example.dart` - Minimal zero-configuration setup
  * `advanced_streaming_example.dart` - All callbacks, manual control, event log
  * `buffer_status_example.dart` - Buffer tracking with "Return to Live" button
- Inline documentation with usage examples for all APIs
- ChartMode, StreamingConfig, StreamingController fully documented

**Test Coverage**
- 36 integration tests (100% passing)
  * Auto-resume: 8/8 passing
  * Manual resume: 5/5 passing
  * Buffer status: 5/5 passing
  * Stream errors: 6/6 passing
  * Edge cases: 6/6 passing
  * Performance: 6/6 passing

**Constitutional Compliance**
- ValueNotifier pattern for reactive state (Constitution II)
- No setState during interactions (optimized rendering)
- RepaintBoundary isolation for chart widget
- Zero external dependencies (Dart stdlib + Flutter SDK only)

---

### Foundation Layer (001-foundation)

**Data Models**
- Added `ChartDataPoint` - Immutable (x, y) coordinate with copyWith
- Added `ChartSeries` - Data series with ordering validation
- Added `DataRange` - Min/max with automatic calculation
- Added `TimeSeriesData` - Time-based data with temporal querying
- Added `RawChartData` - Multi-series container

**Performance Primitives**
- Added `ObjectPool<T>` - Generic object pooling (>90% hit rate target)
- Added `ViewportCuller` - O(n) point filtering (<3ms for 10K points)
- Added `BatchProcessor` - Configurable batch processing with cancellation

**Type System**
- Added `ChartResult<T, E>` - Railway-oriented error handling
- Added `ChartError` - Hierarchical error types (validation, rendering, data, network)
- Added `ValidationUtils` - Common validation helpers

**Math Utilities**
- Added `StatisticalFunctions` - Mean, median, mode, std dev, variance, percentiles
- Added `Interpolation` - Linear, polynomial, spline, step interpolation
- Added `CurveFitting` - Linear/exponential regression with R²

**Test Coverage**: 37 tasks, 52 integration tests, all performance targets met

### Core Rendering Engine (002-core-rendering)

**Layer Architecture**
- Added `RenderLayer` - Base interface for composable rendering layers
- Added `RenderContext` - Immutable dependency injection container
- Added `RenderPipeline` - Layer orchestration with z-ordering
- Added `GridLayer` - Background grid example layer
- Added `DataSeriesLayer` - Line chart visualization with culling
- Added `AnnotationLayer` - Text labels with caching

**Performance Optimization**
- Object pooling integration (Paint, Path, TextPainter pools)
- Viewport culling integration (<3ms for 10K points)
- Text layout caching with LRU eviction (>70% hit rate target)
- isEmpty short-circuit optimization (>1.5x speedup)

**Performance Monitoring**
- Added `PerformanceMonitor` - Frame timing and jank detection
- Added `PerformanceMetrics` - Comprehensive frame metrics
- Added `StopwatchPerformanceMonitor` - Production implementation

**Validation**
- 38 unit tests (layer management, viewport updates, pool integration)
- 12 integration tests (RenderPipeline end-to-end)
- 6 performance benchmarks (all NFRs validated: <8ms avg, <16ms p99)
- 6 edge case tests (rapid pan, extreme zoom, overlapping layers, text overflow, pool exhaustion, cache overflow)

**Performance Targets Met**:
- ✅ Average frame time: <8ms
- ✅ P99 frame time: <16ms
- ✅ Paint pool hit rate: >90%
- ✅ Text cache hit rate: >70%
- ✅ Viewport culling: <3ms for 10K points
- ✅ Layer sorting overhead: <0.1ms per layer
- ✅ isEmpty optimization: >1.5x speedup

**Test Coverage**: 45 tasks (93.8% complete), 62 tests total

### Coordinate System (003-coordinate-system)

**8-Space Transformation**
- Added `UniversalCoordinateTransformer` - Sub-pixel accurate coordinate transformations
- Added `TransformMatrix` - Efficient 3x3 matrix operations
- Added `TransformContext` - Stateful transformation context
- Added `ViewportState` - Immutable viewport configuration

**Test Coverage**: All coordinate transformations validated with round-trip accuracy

### Theming System (004-theming-system)

**Core Theme Infrastructure**
- Added `ChartTheme` - Root theme class with 7 component themes
- Added `ChartThemeBuilder` - Fluent API for custom theme creation
- Added `RenderContextThemeExtension` - Theme management on RenderContext

**Component Themes** (6 total)
- `GridStyle` - Grid lines, background colors, spacing
- `AxisStyle` - Axis lines, labels, ticks, title styles
- `SeriesTheme` - Data series colors, line styles, point markers
- `InteractionTheme` - Hover, selection, tooltip styles
- `TypographyTheme` - Font families, sizes, weights with responsive scaling
- `AnimationTheme` - Duration, curves for theme transitions

**Predefined Themes** (7 total)
- `defaultLight` - Clean white background, 5-color palette, 400ms animations
- `defaultDark` - Material Design dark (#121212), light colors, 350ms animations
- `corporateBlue` - Professional blue scheme on #FAFAFA, 500ms animations
- `vibrant` - Bold colors with bright palette, 600ms animations
- `minimal` - Grayscale borderless design, compact 11px fonts, 250ms animations
- `highContrast` - WCAG AAA (21:1 contrast), 14px fonts for accessibility
- `colorblindFriendly` - Okabe-Ito palette (7 scientifically validated colors)

**Utilities**
- `ColorUtils` - WCAG contrast calculation, colorblind simulation (protanopia, deuteranopia, tritanopia)
- `StyleCache` - LRU caching with >95% hit rate, <0.1ms lookup
- `ThemeChangeSet` - Intelligent theme diffing for selective cache invalidation
- `ThemeVersion` - Semantic versioning for theme compatibility

**Accessibility**
- WCAG 2.1 AA/AAA compliance verification
- Contrast ratio calculations (4.5:1 AA, 7:1 AAA for text)
- Colorblind-safe palette design (Okabe-Ito scientifically validated)
- Responsive typography (mobile 0.9x, tablet 1.0x, desktop 1.1x scaling)

**Performance**
- Theme switching: <100ms with automatic diffing
- Style cache: >95% hit rate, <0.1ms lookup time
- Selective invalidation: Only changed components trigger re-render

**JSON Serialization**
- Save/load themes with semantic versioning
- Backwards-compatible theme migration

**Documentation**
- Comprehensive Dartdoc in all 34 source files
- Usage guide: 884 lines, 9 sections (quick start → advanced patterns)
- Accessibility guide: 740 lines, 8 sections (WCAG 2.1 → testing procedures)

**Test Coverage**: 48 tasks (100%), 261 tests (8 contract, 218 unit, 35 integration)

---

**Constitutional Compliance**: Zero external dependencies (Dart stdlib + Flutter SDK only), comprehensive TDD coverage, all performance targets validated.