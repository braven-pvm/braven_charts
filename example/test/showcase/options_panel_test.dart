import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildPanel() => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 360,
        height: 700,
        child: OptionsPanel(
          children: [
            OptionSection(
              title: 'Shape',
              initiallyExpanded: false,
              children: [
                SliderOption(
                  label: 'Corner radius',
                  value: 6,
                  min: 0,
                  max: 20,
                  onChanged: (_) {},
                ),
              ],
            ),
            OptionSection(
              title: 'Interaction',
              children: [
                BoolOption(label: 'Enable pan', value: true, onChanged: (_) {}),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('search matches descriptions and restores section expansion', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.text('Corner radius').hitTestable(), findsNothing);

    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'rounded',
    );
    await tester.pumpAndSettle();

    expect(find.text('Corner radius').hitTestable(), findsOneWidget);
    expect(find.text('Enable pan').hitTestable(), findsNothing);
    expect(find.text('1 matching property'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('options-panel-search-clear')));
    await tester.pumpAndSettle();

    expect(find.text('Corner radius').hitTestable(), findsNothing);
    expect(find.text('Enable pan').hitTestable(), findsOneWidget);
  });

  testWidgets('property help is available on demand', (tester) async {
    await tester.pumpWidget(buildPanel());
    await tester.tap(find.text('Shape'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-panel-help-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('option-help-corner-radius')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Controls how strongly eligible element corners are rounded.'),
      findsOneWidget,
    );
  });

  testWidgets('all sections can be expanded and collapsed together', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.text('Corner radius').hitTestable(), findsNothing);
    expect(find.text('Enable pan').hitTestable(), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('options-panel-section-actions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expand all sections'));
    await tester.pumpAndSettle();

    expect(find.text('Corner radius').hitTestable(), findsOneWidget);
    expect(find.text('Enable pan').hitTestable(), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('options-panel-section-actions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collapse all sections'));
    await tester.pumpAndSettle();

    expect(find.text('Corner radius').hitTestable(), findsNothing);
    expect(find.text('Enable pan').hitTestable(), findsNothing);
  });

  testWidgets('unknown query shows an actionable empty state', (tester) async {
    await tester.pumpWidget(buildPanel());

    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'does-not-exist',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('options-panel-empty-search')),
      findsOneWidget,
    );
    expect(find.text('0 matching properties'), findsOneWidget);
  });

  testWidgets('legacy color options use the universal palette and clear', (
    tester,
  ) async {
    const defaultColor = Colors.blue;
    Color selectedColor = Colors.red;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 360,
              child: ColorOption(
                label: 'Series color',
                value: selectedColor,
                colors: const <Color>[defaultColor, Colors.red],
                clearValue: defaultColor,
                onChanged: (color) => setState(() => selectedColor = color),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('showcase-color-series-color-custom')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('showcase-color-series-color-clear')),
    );
    await tester.pump();

    expect(selectedColor, defaultColor);
  });

  testWidgets('compact options sheet preserves search and help', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartPageLayout(
            title: 'Compact chart',
            chart: const ColoredBox(color: Colors.white),
            optionsChildren: [
              OptionSection(
                title: 'Interaction',
                children: [
                  BoolOption(
                    label: 'Enable pan',
                    value: true,
                    aliases: const <String>['drag navigation'],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('chart-page-options-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-panel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('options-panel-search')),
      'drag navigation',
    );
    await tester.pumpAndSettle();

    expect(find.text('Enable pan'), findsOneWidget);
    expect(find.text('1 matching property'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('options-panel-help-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('option-help-enable-pan')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
