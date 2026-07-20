import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/value_summary_layout.dart';
import 'package:braven_charts/src/elements/value_summary_overlay_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _surfaceKey = ValueKey('value-summary-golden-surface');
const _surfaceSize = Size(440, 300);
const _plotRect = Rect.fromLTWH(48, 16, 356, 252);

const _singleSeriesModel = CartesianValueSummaryContentModel(
  title: 'ACME Corp',
  subtitle: 'Session 14',
  accentColor: Color(0xFF4F46E5),
  rows: [
    CartesianValueSummaryRow(label: 'Open', value: '104.20'),
    CartesianValueSummaryRow(label: 'High', value: '108.75'),
    CartesianValueSummaryRow(label: 'Low', value: '103.90'),
    CartesianValueSummaryRow(label: 'Close', value: '107.45'),
    CartesianValueSummaryRow(label: 'Change', value: '+3.12%'),
  ],
);

const _multiSeriesModel = CartesianValueSummaryContentModel(
  title: 'Session 14',
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
      label: 'Heart rate',
      value: '',
      color: Color(0xFFDE8F05),
    ),
    CartesianValueSummaryRow(
      label: 'Avg',
      value: '162 bpm',
      color: Color(0xFFDE8F05),
    ),
  ],
);

void main() {
  group('anchors x light/dark', () {
    const anchors = <String, Alignment>{
      'top_left': Alignment.topLeft,
      'top_right': Alignment.topRight,
      'bottom_left': Alignment.bottomLeft,
      'bottom_right': Alignment.bottomRight,
    };
    const themes = <String, CartesianValueSummaryTheme>{
      'light': CartesianValueSummaryTheme.light,
      'dark': CartesianValueSummaryTheme.dark,
    };

    for (final theme in themes.entries) {
      for (final anchor in anchors.entries) {
        testWidgets('overlay ${anchor.key} ${theme.key}', (tester) async {
          await _pumpOverlay(
            tester,
            dark: theme.key == 'dark',
            element: _element(
              placement: ChartOverlayPlacement(
                anchor: anchor.value,
                offset: const Offset(12, 12),
              ),
              summaryTheme: theme.value,
            ),
          );

          await _expectGolden(
            tester,
            'goldens/overlay_${anchor.key}_${theme.key}.png',
          );
        });
      }
    }
  });

  testWidgets('cleared background and border keep only text', (tester) async {
    await _pumpOverlay(
      tester,
      dark: false,
      element: _element(
        placement: ChartOverlayPlacement.topLeft,
        summaryTheme: CartesianValueSummaryTheme.light,
        style: const CartesianValueSummaryStyle(
          backgroundColor: ChartStyleValue.none(),
          borderColor: ChartStyleValue.none(),
          shadow: ChartStyleValue.none(),
        ),
      ),
    );

    await _expectGolden(tester, 'goldens/overlay_none_background.png');
  });

  testWidgets('text scale 2.0 keeps the panel legible', (tester) async {
    await _pumpOverlay(
      tester,
      dark: false,
      element: _element(
        placement: ChartOverlayPlacement.topLeft,
        summaryTheme: CartesianValueSummaryTheme.light,
        textScale: 2.0,
      ),
    );

    await _expectGolden(tester, 'goldens/overlay_text_scale_2x.png');
  });

  testWidgets('RTL flips the anchor and mirrors sectioned rows', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      dark: false,
      element: _element(
        placement: ChartOverlayPlacement.topLeft,
        summaryTheme: CartesianValueSummaryTheme.light,
        textDirection: TextDirection.rtl,
        model: _multiSeriesModel,
      ),
    );

    await _expectGolden(tester, 'goldens/overlay_rtl_sections.png');
  });
}

ValueSummaryOverlayElement _element({
  required ChartOverlayPlacement placement,
  required CartesianValueSummaryTheme summaryTheme,
  CartesianValueSummaryStyle style = const CartesianValueSummaryStyle(),
  CartesianValueSummaryContentModel model = _singleSeriesModel,
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1.0,
}) {
  final element = ValueSummaryOverlayElement(placement: placement);
  element.updateEnvironment(
    plotRect: _plotRect,
    textDirection: textDirection,
    textScale: textScale,
  );
  element.updateContent(
    model,
    ResolvedValueSummaryStyle.resolve(style, summaryTheme),
  );
  return element;
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required ValueSummaryOverlayElement element,
  required bool dark,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: dark ? const Color(0xFF000000) : const Color(0xFFEEEEEE),
        body: Center(
          child: RepaintBoundary(
            key: _surfaceKey,
            child: CustomPaint(
              size: _surfaceSize,
              painter: _OverlaySurfacePainter(element: element, dark: dark),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Future<void> _expectGolden(WidgetTester tester, String path) async {
  await expectLater(find.byKey(_surfaceKey), matchesGoldenFile(path));
}

/// Paints a stand-in chart surface (page background + plot rect) and then the
/// overlay element itself, exactly as the render box would in its element
/// paint pass.
class _OverlaySurfacePainter extends CustomPainter {
  const _OverlaySurfacePainter({required this.element, required this.dark});

  final ValueSummaryOverlayElement element;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    canvas.drawRect(Offset.zero & size, background);

    final plotFill = Paint()
      ..color = dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA);
    canvas.drawRect(_plotRect, plotFill);

    final plotBorder = Paint()
      ..color = dark ? const Color(0xFF3A3A3A) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke;
    canvas.drawRect(_plotRect, plotBorder);

    element.paint(canvas, size);
  }

  @override
  bool shouldRepaint(_OverlaySurfacePainter oldDelegate) =>
      element != oldDelegate.element || dark != oldDelegate.dark;
}
