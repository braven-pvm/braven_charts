# Task Context: Multi-Axis Normalization Sprint

## Sprint Progress

**Phase**: Interaction (Tasks 12-14)  
**Status**: Task 11 complete, preparing Task 12

### Completed Phases
- ✅ **Foundation** (Tasks 1-5): Models, enums, configs
- ✅ **Core Logic** (Tasks 6-8): Normalizers, auto-detection
- ✅ **Rendering** (Tasks 9-11): Painters, widget integration
- 🔄 **Interaction** (Tasks 12-14): Tooltips, crosshair, constraints

---

## What We're Building

A multi-axis normalization feature for BravenChartPlus that allows displaying multiple data series with vastly different Y-ranges on the same chart. Each series gets its own Y-axis showing original values.

**Example use case**: Display Power (0-300W) and Tidal Volume (0.5-4L) on the same chart, each using full vertical space.

---

## Current Codebase State (After Task 11)

### New Files Created This Sprint

```
lib/src/
├── axis/
│   ├── series_axis_resolver.dart  ✅ Task 11 - Series-to-axis binding resolution
│   └── normalization_detector.dart ✅ Task 7 - Auto-detection
├── models/
│   ├── y_axis_position.dart       ✅ Task 1 - Position enum
│   ├── y_axis_config.dart         ✅ Task 2 - Axis configuration
│   ├── series_axis_binding.dart   ✅ Task 3 - Series-to-axis binding
│   ├── normalization_mode.dart    ✅ Task 4 - Mode enum
│   └── multi_axis_config.dart     ✅ Task 5 - Container for all config
└── rendering/
    ├── multi_axis_painter.dart    ✅ Task 9 - Axis painter
    ├── multi_axis_normalizer.dart ✅ Task 6 - Normalization logic
    └── axis_color_resolver.dart   ✅ Task 10 - Color from series

test/unit/multi_axis/           (210 tests)
test/widget/multi_axis/         (13 tests) ✅ Task 11
test/integration/               (9 multi-axis tests)
```

**Total tests**: 210 unit + 13 widget + 9 integration = 232

---

## Key Classes to Know

### MultiAxisConfig (Task 5)
Container holding all axis configuration:
```dart
final config = MultiAxisConfig(
  yAxes: [leftAxis, rightAxis],
  bindings: [powerBinding, tidalBinding],
  mode: NormalizationMode.perAxis,
);
```

### MultiAxisNormalizer (Task 9)
Facade for all normalization logic:
```dart
final normalizer = MultiAxisNormalizer(config);
final normalized = normalizer.normalize(seriesData);
// Returns data in 0.0-1.0 range for each axis
```

### MultiAxisPainter (Task 9)
Renders axes with correct positioning:
```dart
// Uses MultiAxisNormalizer.normalize() for data transformation
// Renders left/right axes with labels
```

### AxisColorResolver (Task 10)
Resolves axis colors from bound series:
```dart
final color = resolver.resolveColor(axisId, seriesMap);
// Returns first bound series' color, or default
```

---

## Existing Widget: BravenChartPlus

**Location**: `lib/src/braven_chart_plus.dart` (2475 lines)

### Current State
The widget already has some multi-axis awareness:
```dart
// Existing fields (from prior work)
final bool _normalizationNeeded;
final Map<String, YRange> _seriesYRanges;
```

### What's Available Now (Task 11 added)
```dart
// Widget parameters now available:
BravenChartPlus(
  yAxes: [leftAxis, rightAxis],
  normalizationMode: NormalizationMode.perAxis,
  axisBindings: [powerBinding, hrBinding],
  // ...
);
```

### SeriesAxisResolver (Task 11)
Resolves which axis a series should use:
```dart
final axisId = SeriesAxisResolver.resolveAxisId(seriesId, bindings, axes);
final axis = SeriesAxisResolver.resolveAxis(seriesId, bindings, axes);
```

---

## Patterns Established

### Test Structure
```dart
void main() {
  group('ClassName', () {
    group('constructor', () { ... });
    group('methodName', () { ... });
  });
}
```

### Normalization Pattern
All normalization goes through `MultiAxisNormalizer.normalize()` - never inline calculations.

### Color Resolution
Axis colors derive from their bound series via `AxisColorResolver`.

---

## Your Role

You're implementing one task at a time. Focus only on the current task in `current-task.md`. The infrastructure above is already tested and working - you'll be building on it.
