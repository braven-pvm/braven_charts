import 'package:braven_charts/src/widgets/dialogs/annotation_color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('always clears preset and custom color selections', (
    tester,
  ) async {
    Color? selected = const Color(0xFF123456);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: StatefulBuilder(
              builder: (context, setState) => AnnotationColorPalette(
                value: selected,
                keyPrefix: 'test-color',
                onChanged: (color) => setState(() => selected = color),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('test-color-clear')), findsOneWidget);
    expect(find.byKey(const ValueKey('test-color-custom')), findsOneWidget);
    expect(find.text('Custom'), findsNothing);
    final redSwatch = find.byKey(
      ValueKey('test-color-${Colors.red.toARGB32()}'),
    );
    final orangeSwatch = find.byKey(
      ValueKey('test-color-${Colors.orange.toARGB32()}'),
    );
    expect(tester.getRect(redSwatch).right, tester.getRect(orangeSwatch).left);
    expect(
      tester.getSize(redSwatch).width,
      greaterThan(tester.getSize(redSwatch).height),
    );
    expect(tester.widget<InkWell>(redSwatch).borderRadius, BorderRadius.zero);
    final swatchContainer = tester.widget<Container>(
      find.descendant(of: redSwatch, matching: find.byType(Container)),
    );
    expect(swatchContainer.decoration, isNull);

    await tester.tap(find.byKey(const ValueKey('test-color-clear')));
    await tester.pump();
    expect(selected, isNull);

    await tester.tap(redSwatch);
    await tester.pump();
    expect(selected, Colors.red);

    await tester.tap(redSwatch);
    await tester.pump();
    expect(selected, isNull);
  });
}
