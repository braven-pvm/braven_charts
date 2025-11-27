# Multi-Axis Golden Tests

This directory contains golden (screenshot comparison) tests for the multi-axis normalization feature.

## Test Coverage

Golden tests will be added for:

### US1: Multi-Scale Visualization
- `multi_axis_left_right_test.dart` - Left and right axis rendering
- `multi_axis_dual_left_test.dart` - Two left axes (leftOuter + left)
- `multi_axis_dual_right_test.dart` - Two right axes (right + rightOuter)
- `multi_axis_quad_test.dart` - All four axis positions

### US2: Auto-Detection & Normalization
- `normalization_auto_test.dart` - Automatic normalization visual
- `normalization_per_series_test.dart` - Per-series normalization visual

### US3: Color-Coded Axes
- `color_coded_labels_test.dart` - Series-matched axis label colors
- `color_coded_ticks_test.dart` - Series-matched tick colors

### US4: Crosshair Multi-Value
- `crosshair_single_axis_test.dart` - Crosshair with one axis
- `crosshair_multi_axis_test.dart` - Crosshair with multiple axes

## Running Golden Tests

```bash
# Generate goldens
flutter test --update-goldens test/golden/multi_axis/

# Run golden tests
flutter test test/golden/multi_axis/
```

## Platform Considerations

Golden images are platform-specific. This project uses Windows as the primary platform.
If golden mismatches occur on different platforms, regenerate with `--update-goldens`.
