import 'package:braven_charts/src/models/annotation_style.dart';
import 'package:braven_charts/src/widgets/dialogs/annotation_style_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clicking selected optional style colors clears them', (
    tester,
  ) async {
    AnnotationStyle? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnnotationStyleEditor(
              initialStyle: const AnnotationStyle(
                backgroundColor: Colors.red,
                borderColor: Colors.blue,
              ),
              showTextControls: false,
              onStyleChanged: (style) => result = style,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Styling'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey('annotation-style-background-color-${Colors.red.toARGB32()}'),
      ),
    );
    await tester.pump();

    expect(result, isNotNull);
    expect(result!.backgroundColor, isNull);
    expect(result!.borderColor, Colors.blue);

    await tester.tap(
      find.byKey(
        ValueKey('annotation-style-border-color-${Colors.blue.toARGB32()}'),
      ),
    );
    await tester.pump();

    expect(result!.backgroundColor, isNull);
    expect(result!.borderColor, isNull);
  });
}
