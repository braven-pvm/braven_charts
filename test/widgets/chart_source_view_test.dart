import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const source = '''import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

final chart = BravenChartPlus(
  title: 'Compact source',
  series: [
    LineChartSeries(
      id: 'signal',
      points: [
        ChartDataPoint(x: 0, y: 10),
        ChartDataPoint(x: 1, y: 12),
      ],
    ),
  ],
);''';

  final generated = ChartGeneratedSource(
    source: source,
    revision: ChartDocumentRevision.next(),
    completeness: ChartGeneratedSourceCompleteness.complete,
    warnings: const [],
    seriesCount: 1,
    pointCount: 2,
    omittedPointCount: 0,
  );

  testWidgets('copies the exact generated Dart', (tester) async {
    MethodCall? clipboardCall;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardCall = call;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 480,
            child: ChartSourceView(generated: generated),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Copy code'));
    await tester.pump();

    expect(clipboardCall?.method, 'Clipboard.setData');
    expect(clipboardCall?.arguments, {'text': source});
    expect(find.text('Chart source copied'), findsOneWidget);
  });

  testWidgets('supports wrapping in a compact viewport without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChartSourceView(generated: generated)),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Wrap lines'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Disable line wrapping'), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps only the source window on an accessible dark palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 480,
            child: ChartSourceView(generated: generated),
          ),
        ),
      ),
    );

    final window = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('chart-source-dark-window')),
    );
    final code = tester.widget<Text>(
      find.byKey(const ValueKey('chart-source-code')),
    );

    expect(window.color, const Color(0xFF0F172A));
    expect(code.style?.color, const Color(0xFFE5E7EB));
    expect(find.text('Copy code'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Copy code'))).brightness,
      Brightness.light,
    );
  });
}
