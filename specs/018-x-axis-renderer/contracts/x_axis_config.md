# Contract: XAxisConfig

**Version**: 1.0.0  
**Type**: Value Object (Immutable Configuration)

## Signature

`dart
@immutable
class XAxisConfig {
  const XAxisConfig({
    this.color,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showCrosshairLabel = true,
    this.labelDisplay = AxisLabelDisplay.labelWithUnit,
    this.minHeight = 0.0,
    this.maxHeight = 60.0,
    this.tickLabelPadding = 4.0,
    this.axisLabelPadding = 5.0,
    this.axisMargin = 8.0,
    this.tickCount,
    this.labelFormatter,
  });

  final Color? color;
  final String? label;
  final String? unit;
  final double? min;
  final double? max;
  final bool visible;
  final bool showAxisLine;
  final bool showTicks;
  final bool showCrosshairLabel;
  final AxisLabelDisplay labelDisplay;
  final double minHeight;
  final double maxHeight;
  final double tickLabelPadding;
  final double axisLabelPadding;
  final double axisMargin;
  final int? tickCount;
  final XAxisLabelFormatter? labelFormatter;

  // Computed properties
  bool get shouldShowAxisLabel;
  bool get shouldShowTickLabels;
  bool get shouldShowTickUnit;
  bool get shouldAppendUnitToLabel;

  // Copy method for immutability
  XAxisConfig copyWith({...});
}
`

## Invariants

1. `minHeight >= 0`
2. `maxHeight >= minHeight`
3. If `min != null && max != null` then `min < max`
4. If `tickCount != null` then `tickCount >= 2`
5. Object is immutable after construction

## Type Aliases

`dart
typedef XAxisLabelFormatter = String Function(double value);
`

## Dependencies

- `dart:ui` for `Color`
- `AxisLabelDisplay` enum (existing, from y_axis_config.dart)

## Test Contract

`dart
void testXAxisConfig() {
  // Default construction
  const config = XAxisConfig();
  expect(config.visible, true);
  expect(config.showAxisLine, true);
  expect(config.showTicks, true);
  expect(config.labelDisplay, AxisLabelDisplay.labelWithUnit);

  // Themed construction
  const themedConfig = XAxisConfig(
    color: Colors.blue,
    label: 'Time',
    unit: 's',
  );
  expect(themedConfig.color, Colors.blue);
  expect(themedConfig.label, 'Time');
  expect(themedConfig.unit, 's');

  // CopyWith preserves values
  final copied = themedConfig.copyWith(visible: false);
  expect(copied.color, Colors.blue);  // Preserved
  expect(copied.visible, false);       // Changed
}
`
