import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/widgets/dialogs/chord_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/pin_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/point_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/text_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/threshold_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/trend_annotation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all native annotation editors use the shared sticky header', (
    tester,
  ) async {
    final cases = <({Widget dialog, String headerKey, String title})>[
      (
        dialog: const PointAnnotationDialog(
          seriesId: 'series',
          dataPointIndex: 0,
        ),
        headerKey: 'point-dialog-sticky-header',
        title: 'Add Point Annotation',
      ),
      (
        dialog: const PinAnnotationDialog(initialX: 1, initialY: 2),
        headerKey: 'pin-dialog-sticky-header',
        title: 'Add Pin Annotation',
      ),
      (
        dialog: const TextAnnotationDialog(clickPosition: Offset.zero),
        headerKey: 'text-dialog-sticky-header',
        title: 'Add Text Annotation',
      ),
      (
        dialog: const ThresholdAnnotationDialog(initialYValue: 10),
        headerKey: 'threshold-dialog-sticky-header',
        title: 'Add Threshold',
      ),
      (
        dialog: const TrendAnnotationDialog(availableSeries: ['series']),
        headerKey: 'trend-dialog-sticky-header',
        title: 'Add Trend',
      ),
      (
        dialog: const ChordAnnotationDialog(
          availableSeries: [ChartSeries(id: 'series', points: [])],
        ),
        headerKey: 'chord-dialog-sticky-header',
        title: 'Add Chord',
      ),
    ];

    for (final testCase in cases) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: testCase.dialog)),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey(testCase.headerKey)),
        findsOneWidget,
        reason: testCase.title,
      );
      expect(find.text(testCase.title), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      final primary = find.widgetWithText(FilledButton, 'Add');
      expect(primary, findsOneWidget);
      final shape =
          tester.widget<FilledButton>(primary).style!.shape!.resolve({})
              as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(6));
    }
  });

  testWidgets('trend and threshold use the shared color palette', (
    tester,
  ) async {
    final cases = <({Widget dialog, String customKey})>[
      (
        dialog: const ThresholdAnnotationDialog(initialYValue: 10),
        customKey: 'threshold-line-color-custom',
      ),
      (
        dialog: const TrendAnnotationDialog(availableSeries: ['series']),
        customKey: 'trend-line-color-custom',
      ),
    ];

    for (final testCase in cases) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: testCase.dialog)),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey(testCase.customKey)),
        findsOneWidget,
        reason: testCase.customKey,
      );
    }
  });

  testWidgets('trend editor progressively exposes and saves LOESS controls', (
    tester,
  ) async {
    TrendAnnotation? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                saved = await showDialog<TrendAnnotation>(
                  context: context,
                  builder: (_) => const TrendAnnotationDialog(
                    availableSeries: ['observed'],
                  ),
                );
              },
              child: const Text('Open trend editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open trend editor'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trend-loess-span')), findsNothing);
    expect(find.byKey(const ValueKey('trend-show-equation')), findsOneWidget);

    await tester.ensureVisible(find.text('LOESS'));
    await tester.tap(find.text('LOESS'));
    await tester.pump();

    final span = find.byKey(const ValueKey('trend-loess-span'));
    final robustness = find.byKey(const ValueKey('trend-loess-robustness'));
    final samples = find.byKey(const ValueKey('trend-loess-samples'));
    expect(span, findsOneWidget);
    expect(robustness, findsOneWidget);
    expect(samples, findsOneWidget);
    expect(find.byKey(const ValueKey('trend-show-equation')), findsNothing);
    tester
        .widget<Slider>(
          find.descendant(of: span, matching: find.byType(Slider)),
        )
        .onChanged
        ?.call(0.7);
    tester
        .widget<Slider>(
          find.descendant(of: robustness, matching: find.byType(Slider)),
        )
        .onChanged
        ?.call(3);
    tester
        .widget<Slider>(
          find.descendant(of: samples, matching: find.byType(Slider)),
        )
        .onChanged
        ?.call(160);
    await tester.pump();

    for (final key in const [
      'trend-show-r-squared',
      'trend-show-sample-count',
      'trend-show-pearson',
      'trend-show-spearman',
    ]) {
      final chip = find.byKey(ValueKey(key));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(saved?.trendType, TrendType.loess);
    expect(saved?.loessSpan, 0.7);
    expect(saved?.loessRobustnessIterations, 3);
    expect(saved?.loessSampleCount, 160);
    expect(saved?.showEquation, isFalse);
    expect(saved?.showRSquared, isTrue);
    expect(saved?.showSampleCount, isTrue);
    expect(saved?.showPearsonCorrelation, isTrue);
    expect(saved?.showSpearmanCorrelation, isTrue);
  });

  testWidgets('trend editor documents and saves linear uncertainty bands', (
    tester,
  ) async {
    TrendAnnotation? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                saved = await showDialog<TrendAnnotation>(
                  context: context,
                  builder: (_) => const TrendAnnotationDialog(
                    availableSeries: ['observed'],
                  ),
                );
              },
              child: const Text('Open uncertainty editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open uncertainty editor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OLS bands assume'), findsOneWidget);
    for (final key in const [
      'trend-confidence-band',
      'trend-prediction-band',
    ]) {
      final chip = find.byKey(ValueKey(key));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }
    final level = find.byKey(const ValueKey('trend-confidence-level'));
    await tester.ensureVisible(level);
    tester.widget<SegmentedButton<double>>(level).onSelectionChanged?.call({
      0.99,
    });
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(saved?.showConfidenceBand, isTrue);
    expect(saved?.showPredictionBand, isTrue);
    expect(saved?.confidenceLevel, 0.99);
  });

  testWidgets('every chord color field uses the shared color palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChordAnnotationDialog(
            availableSeries: [ChartSeries(id: 'series', points: [])],
          ),
        ),
      ),
    );
    await tester.pump();

    for (final key in const [
      'chord-label-text-color-custom',
      'chord-label-background-color-custom',
      'chord-line-color-custom',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }

    final perpendicularToggle = find.byType(Switch);
    await tester.ensureVisible(perpendicularToggle);
    await tester.tap(perpendicularToggle);
    await tester.pump();

    for (final key in const [
      'chord-perpendicular-label-text-color-custom',
      'chord-perpendicular-label-background-color-custom',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }

    final separateStylingToggle = find.byType(SwitchListTile);
    await tester.ensureVisible(separateStylingToggle);
    await tester.tap(separateStylingToggle);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('chord-perpendicular-line-color-custom')),
      findsOneWidget,
    );
  });

  testWidgets('text editor hides its internal anchor implementation detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TextAnnotationDialog(clickPosition: Offset.zero)),
      ),
    );
    await tester.pump();

    expect(find.text('Anchor point'), findsNothing);
    expect(
      find.byKey(const ValueKey('text-annotation-anchor-center')),
      findsNothing,
    );
    expect(find.text('Allow Dragging'), findsOneWidget);
  });

  testWidgets('text editor preserves an existing hidden anchor on update', (
    tester,
  ) async {
    final original = TextAnnotation(
      id: 'text',
      text: 'Existing text',
      position: const Offset(120, 80),
      anchor: AnnotationAnchor.bottomRight,
    );
    TextAnnotation? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('open-text-editor'),
            onPressed: () async {
              result = await showDialog<TextAnnotation>(
                context: context,
                builder: (context) => TextAnnotationDialog(
                  annotation: original,
                  clickPosition: original.position,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-text-editor')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.anchor, AnnotationAnchor.bottomRight);
    expect(result!.position, original.position);
  });
}
