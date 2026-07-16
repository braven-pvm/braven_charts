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
