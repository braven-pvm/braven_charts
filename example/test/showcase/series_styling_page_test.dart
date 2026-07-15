import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/series_styling_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('series styling includes labels, segments, and point controls', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SeriesStylingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Series styling API at a glance'), findsOneWidget);
    expect(find.text('Whole-series appearance'), findsOneWidget);
    expect(find.text('Data-point labels'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsWidgets);

    final options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.text('Series Appearance'),
      300,
      scrollable: options,
    );
    expect(find.text('Glow Radius'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Inline Labels'),
      300,
      scrollable: options,
    );
    expect(find.text('Background Pill'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Data Point Labels'),
      300,
      scrollable: options,
    );
    expect(find.text('Show Labels'), findsOneWidget);
    expect(find.text('Marker Style'), findsOneWidget);
    expect(find.text('Show Unit'), findsOneWidget);
    expect(find.text('Custom Formatter'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Conditional Styling'),
      300,
      scrollable: options,
    );
    expect(find.text('Highlight Color'), findsOneWidget);
    expect(find.text('Threshold Options'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('series-styling-examples')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Conditional segment and point styling'), findsOneWidget);
  });
}
