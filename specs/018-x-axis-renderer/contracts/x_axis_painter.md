# Contract: XAxisPainter

**Version**: 1.0.0  
**Type**: Rendering Component

## Signature

`dart
class XAxisPainter {
  XAxisPainter({
    required this.config,
    required this.axisBounds,
    this.series,
    required this.labelStyle,
  });

  final XAxisConfig config;
  final DataRange axisBounds;
  final List<ChartSeries>? series;
  final TextStyle labelStyle;

  /// Main paint method - MUST be called for axis to render
  void paint(Canvas canvas, Rect chartArea, Rect plotArea);

  /// Generate nice tick values for the axis
  List<double> generateTicks(DataRange bounds, {int? maxTicks});

  /// Format a tick value with optional unit
  String formatTickLabel(double value);

  /// Resolve axis color from config, series, or theme fallback
  Color resolveAxisColor();
}
`

## Invariants

1. `paint()` MUST render axis elements when `config.visible == true`
2. `paint()` MUST NOT render when `config.visible == false`
3. All visual elements MUST use `resolveAxisColor()` for consistent theming
4. Tick generation MUST use nice-number algorithm for human-readable values
5. Text elements MUST use cached TextPainters for performance

## CRITICAL Integration Contract

**These invariants prevent the NO-OP failure from sprint 017:**

1. `paint()` MUST be invoked from `ChartRenderBox.paint()`
2. `paint()` MUST actually draw to the canvas (not be an empty stub)
3. The legacy `XAxisRenderer` MUST NOT be used for X-axis painting
4. `config` changes MUST trigger re-paint via `markNeedsPaint()`

## Dependencies

- `dart:ui` for `Canvas`, `Color`, `Rect`
- `XAxisConfig` value object
- `DataRange` from coordinate system
- `TextPainter` for label rendering

## Rendering Contract

When `paint()` is called with valid parameters:

1. If `config.visible == false`, return immediately
2. Paint axis line if `config.showAxisLine == true`
3. Generate ticks from `axisBounds`
4. For each tick:
   - Paint tick mark if `config.showTicks == true`
   - Paint tick label at appropriate position
5. Paint axis title if `config.label != null` and display mode includes label

## Test Contract

`dart
void testXAxisPainter() {
  // Setup
  final config = XAxisConfig(color: Colors.green, label: 'Time', unit: 's');
  final painter = XAxisPainter(
    config: config,
    axisBounds: DataRange(0, 100),
    labelStyle: TextStyle(fontSize: 12),
  );

  // Painting contract - MUST call drawLine for axis
  final mockCanvas = MockCanvas();
  painter.paint(mockCanvas, chartArea, plotArea);
  verify(mockCanvas.drawLine(any, any, any)).called(greaterThan(0));

  // Color resolution contract
  expect(painter.resolveAxisColor(), Colors.green);

  // Tick generation contract
  final ticks = painter.generateTicks(DataRange(0, 100));
  expect(ticks, isNotEmpty);
  expect(ticks.first, greaterThanOrEqualTo(0));
  expect(ticks.last, lessThanOrEqualTo(100));
}
`

## Performance Contract

1. TextPainter instances MUST be cached and reused
2. Cache MUST be invalidated when `axisBounds` or `labelStyle` changes
3. `paint()` MUST complete within 2ms for typical axis (10-12 ticks)
