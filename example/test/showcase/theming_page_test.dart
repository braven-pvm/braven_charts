import 'package:braven_charts_example/showcase/pages/theming_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theming exposes presets and component-level controls', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThemingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Theme anatomy'), findsOneWidget);
    expect(find.text('Series Palette'), findsOneWidget);

    final options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Grid & Axes'),
      300,
      scrollable: options,
    );
    expect(find.text('Grid Width'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Typography'),
      300,
      scrollable: options,
    );
    expect(find.text('Base Font Size'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('ChartTheme.copyWith'),
      300,
      scrollable: options,
    );
    expect(find.textContaining('TypographyTheme copyWith'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compare-themes')),
      -300,
      scrollable: options,
    );
    await tester.drag(options, const Offset(0, 100));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('compare-themes')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Light'), findsWidgets);
    expect(find.text('High Contrast'), findsOneWidget);
    expect(find.text('Colorblind Friendly'), findsOneWidget);
  });
}
