import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/value_summary_layout.dart';
import 'package:braven_charts/src/elements/value_summary_overlay_element.dart';
import 'package:braven_charts/src/interaction/core/element_types.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// A canvas double that records the name of every draw call.
///
/// Only the members the summary painter actually uses are exercised;
/// everything routes through [noSuchMethod] so the recorder stays in sync
/// with the Canvas API without implementing it.
class _RecordingCanvas implements Canvas {
  final List<String> calls = [];

  int count(String member) => calls.where((call) => call == member).length;

  bool get paintedNoSurface =>
      count('drawRect') == 0 &&
      count('drawRRect') == 0 &&
      count('drawDRRect') == 0 &&
      count('drawPath') == 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      final name = invocation.memberName.toString();
      // Symbol("drawRect") -> drawRect
      calls.add(name.substring(8, name.length - 2));
    }
    return null;
  }
}

const _opaqueStyle = ResolvedValueSummaryStyle(
  backgroundColor: Color(0xFFFFFFFF),
  backgroundOpacity: 1.0,
  borderColor: Color(0xFF9E9E9E),
  borderWidth: 1.0,
  borderRadius: BorderRadius.all(Radius.circular(4)),
  padding: EdgeInsets.all(8),
  titleStyle: TextStyle(
    color: Color(0xFF212121),
    fontSize: 12,
    fontWeight: FontWeight.w600,
  ),
  labelStyle: TextStyle(color: Color(0xFF616161), fontSize: 11),
  valueStyle: TextStyle(
    color: Color(0xFF212121),
    fontSize: 11,
    fontWeight: FontWeight.w500,
  ),
  accentVisible: true,
  accentSize: 8.0,
  minWidth: 0.0,
  maxWidth: 280.0,
  rowGap: 4.0,
);

const _bareStyle = ResolvedValueSummaryStyle(
  padding: EdgeInsets.all(8),
  titleStyle: TextStyle(color: Color(0xFF212121), fontSize: 12),
  labelStyle: TextStyle(color: Color(0xFF616161), fontSize: 11),
  valueStyle: TextStyle(color: Color(0xFF212121), fontSize: 11),
  accentVisible: false,
  accentSize: 8.0,
  rowGap: 4.0,
);

CartesianValueSummaryContentModel _singleSeriesModel() =>
    const CartesianValueSummaryContentModel(
      title: 'ACME Corp',
      subtitle: 'Session 14',
      rows: [
        CartesianValueSummaryRow(label: 'Open', value: '104.20'),
        CartesianValueSummaryRow(label: 'Close', value: '107.45'),
        CartesianValueSummaryRow(label: 'Change', value: '+3.12%'),
      ],
    );

void main() {
  group('ResolvedValueSummaryStyle.resolve', () {
    const theme = CartesianValueSummaryTheme.light;

    test('inherit resolves every field to the theme default', () {
      final resolved = ResolvedValueSummaryStyle.resolve(
        const CartesianValueSummaryStyle(),
        theme,
      );

      expect(resolved.backgroundColor, theme.background);
      expect(resolved.backgroundOpacity, theme.backgroundOpacity);
      expect(resolved.borderColor, theme.border);
      expect(resolved.borderWidth, theme.borderWidth);
      expect(resolved.borderRadius, theme.borderRadius);
      expect(resolved.padding, theme.padding);
      expect(resolved.titleStyle, theme.titleStyle);
      expect(resolved.labelStyle, theme.labelStyle);
      expect(resolved.valueStyle, theme.valueStyle);
      expect(resolved.accentSize, theme.accentSize);
      expect(resolved.shadow, theme.shadow);
      expect(resolved.minWidth, theme.minWidth);
      expect(resolved.maxWidth, theme.maxWidth);
      expect(resolved.rowGap, theme.rowGap);
      // No theme preset packs rows: the null default keeps the spread layout.
      expect(resolved.labelValueGap, isNull);
      // Inherited accent color defers to the content model's series color.
      expect(resolved.accentColor, isNull);
      expect(resolved.accentVisible, isTrue);
    });

    test('explicit values override the theme default', () {
      const background = Color(0xFF123456);
      const accent = Color(0xFF654321);
      final resolved = ResolvedValueSummaryStyle.resolve(
        const CartesianValueSummaryStyle(
          backgroundColor: ChartStyleValue.value(background),
          borderWidth: ChartStyleValue.value(3.0),
          accentColor: ChartStyleValue.value(accent),
          minWidth: ChartStyleValue.value(220.0),
          labelValueGap: ChartStyleValue.value(16.0),
        ),
        theme,
      );

      expect(resolved.backgroundColor, background);
      expect(resolved.borderWidth, 3.0);
      expect(resolved.accentColor, accent);
      expect(resolved.accentVisible, isTrue);
      expect(resolved.minWidth, 220.0);
      expect(resolved.labelValueGap, 16.0);
      // Untouched fields still inherit.
      expect(resolved.borderColor, theme.border);
    });

    test('none clears the field with no theme fallback', () {
      final resolved = ResolvedValueSummaryStyle.resolve(
        const CartesianValueSummaryStyle(
          backgroundColor: ChartStyleValue.none(),
          backgroundOpacity: ChartStyleValue.none(),
          borderColor: ChartStyleValue.none(),
          borderWidth: ChartStyleValue.none(),
          borderRadius: ChartStyleValue.none(),
          padding: ChartStyleValue.none(),
          shadow: ChartStyleValue.none(),
          accentColor: ChartStyleValue.none(),
          minWidth: ChartStyleValue.none(),
          maxWidth: ChartStyleValue.none(),
          rowGap: ChartStyleValue.none(),
          labelValueGap: ChartStyleValue.none(),
        ),
        theme,
      );

      expect(resolved.backgroundColor, isNull);
      expect(resolved.backgroundOpacity, isNull);
      expect(resolved.borderColor, isNull);
      expect(resolved.borderWidth, isNull);
      expect(resolved.borderRadius, isNull);
      expect(resolved.padding, isNull);
      expect(resolved.shadow, isNull);
      expect(resolved.accentVisible, isFalse);
      expect(resolved.minWidth, isNull);
      expect(resolved.maxWidth, isNull);
      expect(resolved.rowGap, isNull);
      expect(resolved.labelValueGap, isNull);
    });

    test('equal inputs resolve to equal values', () {
      final a = ResolvedValueSummaryStyle.resolve(
        const CartesianValueSummaryStyle(
          borderColor: ChartStyleValue.none(),
        ),
        theme,
      );
      final b = ResolvedValueSummaryStyle.resolve(
        const CartesianValueSummaryStyle(
          borderColor: ChartStyleValue.none(),
        ),
        theme,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ValueSummaryLayout cache', () {
    test('identical inputs return the same result instance', () {
      final layout = ValueSummaryLayout();
      final first = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );
      final second = layout.layout(
        _singleSeriesModel(), // equal but not identical model instance
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      expect(identical(first, second), isTrue);
    });

    test('changing scale, direction, or maxWidth misses the cache', () {
      final layout = ValueSummaryLayout();
      final base = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      final scaled = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 2.0,
        textDirection: TextDirection.ltr,
      );
      final rtl = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.rtl,
      );
      final narrow = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 120,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      expect(identical(base, scaled), isFalse);
      expect(identical(base, rtl), isFalse);
      expect(identical(base, narrow), isFalse);
    });

    test('holds the last four results and evicts the oldest', () {
      final layout = ValueSummaryLayout();
      CartesianValueSummaryContentModel model(int index) =>
          CartesianValueSummaryContentModel(
            title: 'Model $index',
            rows: [
              CartesianValueSummaryRow(label: 'Value', value: '$index'),
            ],
          );

      ValueSummaryLayoutResult lay(int index) => layout.layout(
        model(index),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      final first = lay(1);
      lay(2);
      lay(3);
      // Still cached within capacity.
      expect(identical(lay(1), first), isTrue);

      // Four newer distinct entries push model 1 out.
      lay(4);
      lay(5);
      lay(6);
      lay(7);
      expect(identical(lay(1), first), isFalse);
    });
  });

  group('ValueSummaryLayout painting', () {
    test('cleared background and border paint no surface at all', () {
      final layout = ValueSummaryLayout();
      final result = layout.layout(
        _singleSeriesModel(),
        _bareStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      final canvas = _RecordingCanvas();
      result.paint(canvas, Offset.zero);

      expect(canvas.paintedNoSurface, isTrue,
          reason: 'none background/border must not draw any surface');
      expect(canvas.count('drawParagraph'), greaterThan(0),
          reason: 'text still paints on a cleared surface');
    });

    test('opaque style paints surface and border', () {
      final layout = ValueSummaryLayout();
      final result = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      final canvas = _RecordingCanvas();
      result.paint(canvas, Offset.zero);

      // Background fill + border stroke.
      expect(canvas.count('drawRRect'), greaterThanOrEqualTo(2));
    });

    test('empty rows produce a zero-size result that paints nothing', () {
      final layout = ValueSummaryLayout();
      final result = layout.layout(
        const CartesianValueSummaryContentModel(title: 'Orphan title'),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      expect(result.size, Size.zero);

      final canvas = _RecordingCanvas();
      result.paint(canvas, Offset.zero);
      expect(canvas.calls, isEmpty);
    });
  });

  group('ValueSummaryLayout metrics', () {
    test('minWidth is honored when content is narrower', () {
      final layout = ValueSummaryLayout();
      final style = _opaqueStyle.copyWith(minWidth: 200.0);
      final result = layout.layout(
        _singleSeriesModel(),
        style,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      expect(result.size.width, 200.0);
    });

    test('maxWidth caps the panel and overflowing text is ellipsized', () {
      final layout = ValueSummaryLayout();
      const model = CartesianValueSummaryContentModel(
        title: 'An extremely long panel title that cannot possibly fit',
        rows: [
          CartesianValueSummaryRow(
            label: 'A very verbose row label',
            value: '123456789.123456789 units of measure',
          ),
        ],
      );
      final style = _opaqueStyle.copyWith(maxWidth: 140.0);
      final result = layout.layout(
        model,
        style,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      expect(result.size.width, 140.0);
      for (final placed in result.placedTexts) {
        expect(
          placed.offset.dx + placed.size.width,
          lessThanOrEqualTo(140.0 - 8.0 + 0.001),
          reason: 'every text stays inside the padded content area',
        );
      }
    });

    test('the layout maxWidth argument caps the panel below style maxWidth',
        () {
      final layout = ValueSummaryLayout();
      const model = CartesianValueSummaryContentModel(
        rows: [
          CartesianValueSummaryRow(
            label: 'A very verbose row label',
            value: '123456789.123456789 units of measure',
          ),
        ],
      );
      final result = layout.layout(
        model,
        _opaqueStyle,
        maxWidth: 120,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      expect(result.size.width, lessThanOrEqualTo(120.0));
    });

    test('rowGap separates every stacked line', () {
      final layout = ValueSummaryLayout();
      const model = CartesianValueSummaryContentModel(
        rows: [
          CartesianValueSummaryRow(label: 'One', value: '1'),
          CartesianValueSummaryRow(label: 'Two', value: '2'),
          CartesianValueSummaryRow(label: 'Three', value: '3'),
        ],
      );

      final tight = layout.layout(
        model,
        _opaqueStyle.copyWith(rowGap: 0.0),
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );
      final spaced = layout.layout(
        model,
        _opaqueStyle.copyWith(rowGap: 10.0),
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      // Three rows -> two gap slots.
      expect(spaced.size.height - tight.size.height, closeTo(20.0, 0.001));
    });

    test('text scale 2.0 grows the laid-out panel', () {
      final layout = ValueSummaryLayout();
      final base = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );
      final scaled = layout.layout(
        _singleSeriesModel(),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 2.0,
        textDirection: TextDirection.ltr,
      );

      expect(scaled.size.width, greaterThan(base.size.width));
      expect(scaled.size.height, greaterThan(base.size.height));
    });
  });

  group('ValueSummaryLayout rows', () {
    test('values are right-aligned to the content edge in LTR', () {
      final layout = ValueSummaryLayout();
      final result = layout.layout(
        const CartesianValueSummaryContentModel(
          rows: [CartesianValueSummaryRow(label: 'Close', value: '107.45')],
        ),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      final value = result.placedTexts
          .singleWhere((placed) => placed.role == ValueSummaryTextRole.value);
      // padding.right == 8 in _opaqueStyle, no accent (model has no color).
      expect(
        value.offset.dx + value.size.width,
        closeTo(result.size.width - 8.0, 0.001),
      );
    });

    test('RTL mirrors the row: value leads on the left', () {
      final layout = ValueSummaryLayout();
      final result = layout.layout(
        const CartesianValueSummaryContentModel(
          rows: [CartesianValueSummaryRow(label: 'Close', value: '107.45')],
        ),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.rtl,
      );

      final value = result.placedTexts
          .singleWhere((placed) => placed.role == ValueSummaryTextRole.value);
      final label = result.placedTexts
          .singleWhere((placed) => placed.role == ValueSummaryTextRole.label);
      expect(value.offset.dx, lessThan(label.offset.dx));
      expect(value.offset.dx, closeTo(8.0, 0.001));
    });

    test('section-header rows render as titles without a blank value', () {
      final layout = ValueSummaryLayout();
      final result = layout.layout(
        const CartesianValueSummaryContentModel(
          rows: [
            CartesianValueSummaryRow(
              label: 'Heart rate',
              value: '',
              color: Color(0xFFDE8F05),
            ),
            CartesianValueSummaryRow(
              label: 'HR',
              value: '162 bpm',
              color: Color(0xFFDE8F05),
            ),
          ],
        ),
        _opaqueStyle,
        maxWidth: 400,
        textScale: 1.0,
        textDirection: TextDirection.ltr,
      );

      final sectionHeaders = result.placedTexts
          .where((placed) => placed.role == ValueSummaryTextRole.sectionHeader)
          .toList();
      final labels = result.placedTexts
          .where((placed) => placed.role == ValueSummaryTextRole.label)
          .toList();
      final values = result.placedTexts
          .where((placed) => placed.role == ValueSummaryTextRole.value)
          .toList();

      expect(sectionHeaders, hasLength(1));
      expect(sectionHeaders.single.text, 'Heart rate');
      expect(labels, hasLength(1));
      expect(labels.single.text, 'HR');
      expect(values, hasLength(1));
      expect(values.single.text, '162 bpm');
    });
  });

  group('ValueSummaryLayout packed rows', () {
    const packedModel = CartesianValueSummaryContentModel(
      rows: [
        CartesianValueSummaryRow(label: 'Open', value: '104.20'),
        CartesianValueSummaryRow(label: 'Change', value: '+3.1%'),
      ],
    );

    ValueSummaryLayoutResult lay(
      ResolvedValueSummaryStyle style, {
      CartesianValueSummaryContentModel model = packedModel,
      TextDirection textDirection = TextDirection.ltr,
      double maxWidth = 400,
    }) => ValueSummaryLayout().layout(
      model,
      style,
      maxWidth: maxWidth,
      textScale: 1.0,
      textDirection: textDirection,
    );

    List<ValueSummaryPlacedText> byRole(
      ValueSummaryLayoutResult result,
      ValueSummaryTextRole role,
    ) => result.placedTexts.where((placed) => placed.role == role).toList();

    double widestLabel(ValueSummaryLayoutResult result) =>
        byRole(result, ValueSummaryTextRole.label)
            .map((placed) => placed.size.width)
            .reduce(math.max);

    test('the value column starts at the widest label plus the gap', () {
      final result = lay(_opaqueStyle.copyWith(labelValueGap: 16.0));

      final values = byRole(result, ValueSummaryTextRole.value);
      expect(values, hasLength(2));
      // padding.left == 8, no accent (model has no color), no swatches.
      final columnStart = 8.0 + widestLabel(result) + 16.0;
      for (final value in values) {
        expect(value.offset.dx, closeTo(columnStart, 0.001));
      }
    });

    test('packed intrinsic width is labels + gap + widest value + chrome', () {
      final result = lay(_opaqueStyle.copyWith(labelValueGap: 16.0));

      final widestValue = byRole(result, ValueSummaryTextRole.value)
          .map((placed) => placed.size.width)
          .reduce(math.max);
      // minWidth 0 in _opaqueStyle: the panel tightens to its packed content
      // plus horizontal padding (8 + 8).
      expect(
        result.size.width,
        closeTo(16.0 + widestLabel(result) + 16.0 + widestValue, 0.001),
      );
    });

    test('packed width still clamps at minWidth, values stay in the column',
        () {
      final result = lay(
        _opaqueStyle.copyWith(labelValueGap: 12.0, minWidth: 220.0),
      );

      expect(result.size.width, 220.0);
      final columnStart = 8.0 + widestLabel(result) + 12.0;
      for (final value in byRole(result, ValueSummaryTextRole.value)) {
        expect(value.offset.dx, closeTo(columnStart, 0.001));
        // Left-aligned in the packed column, not pushed to the right edge.
        expect(
          value.offset.dx + value.size.width,
          lessThan(220.0 - 8.0),
        );
      }
    });

    test('packed width clamps at maxWidth and long values ellipsize', () {
      const model = CartesianValueSummaryContentModel(
        rows: [
          CartesianValueSummaryRow(
            label: 'Close',
            value: '203.81 USD with a very long trailing note',
          ),
        ],
      );
      final result = lay(
        _opaqueStyle.copyWith(labelValueGap: 12.0, maxWidth: 120.0),
        model: model,
      );

      expect(result.size.width, 120.0);
      for (final placed in result.placedTexts) {
        expect(
          placed.offset.dx + placed.size.width,
          lessThanOrEqualTo(120.0 - 8.0 + 0.001),
          reason: 'every packed run stays inside the padded content area',
        );
      }
    });

    test('a null labelValueGap keeps the spread layout under minWidth', () {
      final result = lay(_opaqueStyle.copyWith(minWidth: 220.0));

      expect(result.size.width, 220.0);
      for (final value in byRole(result, ValueSummaryTextRole.value)) {
        // Spread mode: values right-align to the padded content edge.
        expect(
          value.offset.dx + value.size.width,
          closeTo(220.0 - 8.0, 0.001),
        );
      }
    });

    test('RTL mirrors the packed value column', () {
      final result = lay(
        _opaqueStyle.copyWith(labelValueGap: 16.0),
        textDirection: TextDirection.rtl,
      );

      final columnStart = widestLabel(result) + 16.0;
      for (final label in byRole(result, ValueSummaryTextRole.label)) {
        expect(
          label.offset.dx + label.size.width,
          closeTo(result.size.width - 8.0, 0.001),
        );
      }
      for (final value in byRole(result, ValueSummaryTextRole.value)) {
        expect(
          value.offset.dx + value.size.width,
          closeTo(result.size.width - 8.0 - columnStart, 0.001),
        );
      }
    });

    test('swatch extents join the label column; section headers stay put', () {
      const sectioned = CartesianValueSummaryContentModel(
        rows: [
          CartesianValueSummaryRow(
            label: 'Speed',
            value: '',
            color: Color(0xFF0173B2),
          ),
          CartesianValueSummaryRow(
            label: 'Avg',
            value: '14.2 km/h',
            color: Color(0xFF0173B2),
          ),
          CartesianValueSummaryRow(
            label: 'Maximum',
            value: '41 km/h',
            color: Color(0xFF0173B2),
          ),
        ],
      );
      final result = lay(
        _opaqueStyle.copyWith(labelValueGap: 16.0),
        model: sectioned,
      );

      // Swatch extent = accentSize 8 + swatch-text gap 6.
      const swatchExtent = 8.0 + 6.0;
      final labelColumn = swatchExtent + widestLabel(result);
      final values = byRole(result, ValueSummaryTextRole.value);
      expect(values, hasLength(2));
      for (final value in values) {
        expect(value.offset.dx, closeTo(8.0 + labelColumn + 16.0, 0.001));
      }

      // The section header keeps its swatch-led start, unaffected by the
      // packed value column.
      final header = byRole(result, ValueSummaryTextRole.sectionHeader).single;
      expect(header.offset.dx, closeTo(8.0 + swatchExtent, 0.001));
    });
  });

  group('ValueSummaryOverlayElement', () {
    final plotRect = const Rect.fromLTWH(40, 20, 360, 240);
    final style = ResolvedValueSummaryStyle.resolve(
      const CartesianValueSummaryStyle(),
      CartesianValueSummaryTheme.light,
    );

    ValueSummaryOverlayElement pumpElement({
      ChartOverlayPlacement placement = ChartOverlayPlacement.topLeft,
      TextDirection textDirection = TextDirection.ltr,
      CartesianValueSummaryContentModel? model,
    }) {
      final element = ValueSummaryOverlayElement(placement: placement);
      element.updateEnvironment(
        plotRect: plotRect,
        textDirection: textDirection,
      );
      element.updateContent(model ?? _singleSeriesModel(), style);
      return element;
    }

    test('is a passive, pass-through foreground element', () {
      final element = pumpElement();
      element.paint(_RecordingCanvas(), const Size(440, 280));

      expect(element.hitTest(element.bounds.center), isFalse);
      expect(element.isSelectable, isFalse);
      expect(element.isDraggable, isFalse);
      expect(element.renderOrder, RenderOrder.valueSummary);
      expect(element.renderOrder, greaterThan(RenderOrder.legend));
    });

    test('updateContent reports a repaint only when content changes', () {
      final element = pumpElement();
      element.paint(_RecordingCanvas(), const Size(440, 280));
      expect(element.needsRepaint, isFalse);

      // Equal (but not identical) model and style: no change.
      expect(element.updateContent(_singleSeriesModel(), style), isFalse);
      expect(element.needsRepaint, isFalse);

      final changed = const CartesianValueSummaryContentModel(
        title: 'ACME Corp',
        subtitle: 'Session 15',
        rows: [CartesianValueSummaryRow(label: 'Close', value: '108.00')],
      );
      expect(element.updateContent(changed, style), isTrue);
      expect(element.needsRepaint, isTrue);
    });

    test('anchors the panel to the plot rect with the placement inset', () {
      final element = pumpElement();
      element.paint(_RecordingCanvas(), const Size(440, 280));

      expect(element.bounds.left, closeTo(plotRect.left + 12, 0.001));
      expect(element.bounds.top, closeTo(plotRect.top + 12, 0.001));
    });

    test('bottomRight anchor insets the panel from the far corner', () {
      final element = pumpElement(
        placement: const ChartOverlayPlacement(
          anchor: Alignment.bottomRight,
          offset: Offset(12, 12),
        ),
      );
      element.paint(_RecordingCanvas(), const Size(440, 280));

      expect(element.bounds.right, closeTo(plotRect.right - 12, 0.001));
      expect(element.bounds.bottom, closeTo(plotRect.bottom - 12, 0.001));
    });

    test('RTL resolves a topLeft anchor to the top-right corner', () {
      final element = pumpElement(textDirection: TextDirection.rtl);
      element.paint(_RecordingCanvas(), const Size(440, 280));

      expect(element.bounds.right, closeTo(plotRect.right - 12, 0.001));
      expect(element.bounds.top, closeTo(plotRect.top + 12, 0.001));
    });

    test('paints nothing without content or with empty rows', () {
      final element = ValueSummaryOverlayElement();
      element.updateEnvironment(
        plotRect: plotRect,
        textDirection: TextDirection.ltr,
      );

      final canvas = _RecordingCanvas();
      element.paint(canvas, const Size(440, 280));
      expect(canvas.calls, isEmpty);
      expect(element.bounds, Rect.zero);

      element.updateContent(
        const CartesianValueSummaryContentModel(title: 'Empty'),
        style,
      );
      element.paint(canvas, const Size(440, 280));
      expect(canvas.calls, isEmpty);
      expect(element.bounds, Rect.zero);
    });
  });
}
