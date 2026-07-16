import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/widgets/dialogs/annotation_label_position_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the complete spatial label-position control', (
    tester,
  ) async {
    var selected = AnnotationLabelPosition.topLeft;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AnnotationLabelPositionSelector(
                value: selected,
                onChanged: (value) => setState(() => selected = value),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Label position'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);
    expect(find.text('Top left'), findsOneWidget);

    for (final position in AnnotationLabelPosition.values) {
      final target = find.byKey(
        ValueKey('annotation-label-position-${position.name}'),
      );
      expect(target, findsOneWidget);
      expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    }
    expect(
      tester.getSize(
        find.byKey(const ValueKey('annotation-label-position-topLeft-visual')),
      ),
      const Size(36, 32),
    );

    await tester.tap(
      find.byKey(const ValueKey('annotation-label-position-bottomCenter')),
    );
    await tester.pump();

    expect(selected, AnnotationLabelPosition.bottomCenter);
    expect(find.text('Bottom center'), findsOneWidget);
  });

  testWidgets('keeps compact geometry in a narrow editor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: AnnotationLabelPositionSelector(
                value: AnnotationLabelPosition.center,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('annotation-label-position-center')),
          )
          .width,
      88,
    );
  });
}
