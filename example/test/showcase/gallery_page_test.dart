import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gallery leads with flagship analysis and mounts live data', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: GalleryPage()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('One chart, the complete analytical story'),
      findsOneWidget,
    );
    expect(find.text('Endurance session profile'), findsOneWidget);
    expect(find.text('4 Y axes'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1900));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Live sensor stream'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsAtLeastNWidgets(1));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('The building blocks'), findsOneWidget);
  });
}
