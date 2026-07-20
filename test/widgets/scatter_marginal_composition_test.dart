import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lays out independent main, X, Y, and corner slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 400,
            child: ScatterMarginalComposition(
              xMarginalExtent: 100,
              yMarginalExtent: 120,
              gap: 10,
              scatter: ColoredBox(
                key: ValueKey('main-slot'),
                color: Colors.blue,
              ),
              xMarginal: ColoredBox(
                key: ValueKey('x-slot'),
                color: Colors.green,
              ),
              yMarginal: ColoredBox(
                key: ValueKey('y-slot'),
                color: Colors.orange,
              ),
              corner: ColoredBox(
                key: ValueKey('corner-slot'),
                color: Colors.purple,
              ),
            ),
          ),
        ),
      ),
    );

    final mainRect = tester.getRect(find.byKey(const ValueKey('main-slot')));
    final xRect = tester.getRect(find.byKey(const ValueKey('x-slot')));
    final yRect = tester.getRect(find.byKey(const ValueKey('y-slot')));
    final cornerRect = tester.getRect(
      find.byKey(const ValueKey('corner-slot')),
    );

    expect(xRect.height, 100);
    expect(yRect.width, 120);
    expect(cornerRect.size, const Size(120, 100));
    expect(mainRect.right + 10, yRect.left);
    expect(xRect.bottom + 10, mainRect.top);
    expect(mainRect.size, const Size(470, 290));
  });
}
