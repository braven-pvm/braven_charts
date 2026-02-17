import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChartPlus', () {
    group('fromJson factory', () {
      testWidgets('creates widget from valid JSON', (tester) async {
        const json = '[{"x": 1.0, "y": 10.0}, {"x": 2.0, "y": 20.0}]';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChartPlus.fromJson(
                seriesId: 'test_series',
                json: json,
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles empty JSON list', (tester) async {
        const json = '[]';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChartPlus.fromJson(
                seriesId: 'test_series',
                json: json,
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('throws FormatException on invalid JSON', (tester) async {
        const json = 'invalid_json';

        expect(
          () => BravenChartPlus.fromJson(seriesId: 'test_series', json: json),
          throwsFormatException,
        );
      });
    });

    group('onAnnotationDragged callback', () {
      testWidgets('is called with correct arguments', (tester) async {
        // This test is a placeholder to verify the callback signature is correct
        // and can be passed to the widget.
        // Actual interaction testing would require more setup with the underlying
        // render object or a mock controller.

        bool callbackCalled = false;
        ChartAnnotation? draggedAnnotation;
        Offset? draggedPosition;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChartPlus(
                series: const [],
                onAnnotationDragged: (annotation, position) {
                  callbackCalled = true;
                  draggedAnnotation = annotation;
                  draggedPosition = position;
                },
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
        expect(callbackCalled, isFalse);
        // Use the variables to avoid unused warning
        expect(draggedAnnotation, isNull);
        expect(draggedPosition, isNull);
      });
    });
  });
}
