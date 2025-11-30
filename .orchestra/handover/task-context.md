# Task Context: Multi-Axis Normalization Sprint

## Sprint Progress

**Phase**: Rendering (Tasks 9-12)  
**Status**: Task 10 complete, preparing Task 11

### Completed Phases
- ✅ **Foundation** (Tasks 1-5): Models, enums, configs
- ✅ **Core Logic** (Tasks 6-8): Normalizers, auto-detection
- 🔄 **Rendering** (Tasks 9-12): Painters, widget integration

---

## What We're Building

A multi-axis normalization feature for BravenChartPlus that allows displaying multiple data series with vastly different Y-ranges on the same chart. Each series gets its own Y-axis showing original values.

**Example use case**: Display Power (0-300W) and Tidal Volume (0.5-4L) on the same chart, each using full vertical space.

---

## Current Codebase State (After Task 10)

### New Files Created This Sprint

```
lib/src/
├── axis/
│   ├── y_axis_position.dart       ✅ Task 1 - Position enum
│   ├── y_axis_config.dart         ✅ Task 2 - Axis configuration
│   ├── series_axis_binding.dart   ✅ Task 3 - Series-to-axis binding
│   └── multi_axis_config.dart     ✅ Task 5 - Container for all config
├── normalization/
│   ├── normalization_mode.dart    ✅ Task 4 - Mode enum
│   ├── axis_normalizer.dart       ✅ Task 6 - Core normalizer
│   ├── group_normalizer.dart      ✅ Task 7 - Group normalization
│   ├── normalization_detector.dart ✅ Task 8 - Auto-detection
│   └── multi_axis_normalizer.dart ✅ Task 9 - Facade
└── rendering/
    ├── multi_axis_painter.dart    ✅ Task 9 - Axis painter
    └── axis_color_resolver.dart   ✅ Task 10 - Color from series

test/unit/multi_axis/
├── y_axis_position_test.dart      (14 tests)
├── y_axis_config_test.dart        (25 tests)
├── series_axis_binding_test.dart  (14 tests)
├── normalization_mode_test.dart   (11 tests)
├── multi_axis_config_test.dart    (23 tests)
├── axis_normalizer_test.dart      (18 tests)
├── group_normalizer_test.dart     (12 tests)
├── normalization_detector_test.dart (18 tests)
├── multi_axis_normalizer_test.dart  (41 tests)
├── multi_axis_painter_test.dart     (21 tests)
└── axis_color_resolver_test.dart    (13 tests)
```

**Total tests**: 210+

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

### What's Missing (Task 11 will add)
```dart
// Parameters to add:
final List<YAxisConfig>? yAxes;
final NormalizationMode? normalizationMode;
// OR unified:
final MultiAxisConfig? multiAxisConfig;
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
