import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/widgets/dialogs/range_annotation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves a new spatial label position from the native editor', (
    tester,
  ) async {
    RangeAnnotation? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showDialog<RangeAnnotation>(
                    context: context,
                    builder: (context) => RangeAnnotationDialog(
                      annotation: RangeAnnotation(
                        id: 'review-range',
                        label: 'Analysis window',
                        startX: 1,
                        endX: 3,
                      ),
                    ),
                  );
                },
                child: const Text('Open editor'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Range Annotation'), findsOneWidget);
    expect(find.text('Analysis window'), findsWidgets);

    final updateButton = find.widgetWithText(FilledButton, 'Update');
    final headerButtonTop = tester.getTopLeft(updateButton).dy;
    final updateStyle = tester.widget<FilledButton>(updateButton).style!;
    final updateShape =
        updateStyle.shape!.resolve({}) as RoundedRectangleBorder;
    expect(updateShape.borderRadius, BorderRadius.circular(6));
    final header = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('range-dialog-sticky-header')),
            matching: find.byType(Container),
          )
          .first,
    );
    final headerDecoration = header.decoration! as BoxDecoration;
    expect(
      headerDecoration.color,
      isNot(Theme.of(tester.element(updateButton)).colorScheme.surface),
    );
    final centerRight = find.byKey(
      const ValueKey('annotation-label-position-centerRight'),
    );
    await tester.scrollUntilVisible(
      centerRight,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(centerRight);
    await tester.pump();

    expect(find.text('Center right'), findsOneWidget);
    expect(tester.getTopLeft(updateButton).dy, headerButtonTop);

    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.labelPosition, AnnotationLabelPosition.centerRight);
  });

  testWidgets('clicking selected range colors clears them', (tester) async {
    final fillColor = Colors.red.withOpacity(0.2);
    const borderColor = Colors.blue;
    RangeAnnotation? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<RangeAnnotation>(
                  context: context,
                  builder: (context) => RangeAnnotationDialog(
                    annotation: RangeAnnotation(
                      id: 'color-toggle-range',
                      startX: 1,
                      endX: 3,
                      fillColor: fillColor,
                      borderColor: borderColor,
                    ),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    final fillSwatch = find.byKey(
      ValueKey('range-fill-color-${fillColor.toARGB32()}'),
    );
    final borderSwatch = find.byKey(
      ValueKey('range-border-color-${borderColor.toARGB32()}'),
    );
    await tester.scrollUntilVisible(
      fillSwatch,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fillSwatch);
    await tester.tap(borderSwatch);
    await tester.pump();

    final updateButton = find.widgetWithText(FilledButton, 'Update');
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.fillColor, isNull);
    expect(result!.borderColor, isNull);
  });
}
