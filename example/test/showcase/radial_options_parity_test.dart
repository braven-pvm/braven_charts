import 'package:braven_charts_example/showcase/pages/concentric_donut_page.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Pie exposes the canonical radial option workflow', (
    tester,
  ) async {
    await _pumpPage(tester, const PieChartsPage());
    _expectSectionOrder(tester, const [
      'Chart theme',
      'Data labels',
      'Pie geometry',
      'Slice appearance',
      'Selection',
      'Motion',
      'Small categories',
      'Legend',
      'Interaction',
      'Demo data',
    ]);
    await _expectCompleteCommonEditors(tester, 'pie');
  });

  testWidgets('Donut exposes the canonical radial option workflow', (
    tester,
  ) async {
    await _pumpPage(tester, const DonutChartsPage());
    _expectSectionOrder(tester, const [
      'Chart theme',
      'Data labels',
      'Donut geometry',
      'Slice appearance',
      'Selection',
      'Motion',
      'Small categories',
      'Center content',
      'Legend',
      'Interaction',
      'Demo data',
    ]);
    await _expectCompleteCommonEditors(tester, 'donut');
  });

  testWidgets('Concentric Donut exposes the canonical radial option workflow', (
    tester,
  ) async {
    await _pumpPage(tester, const ConcentricDonutPage());
    _expectSectionOrder(tester, const [
      'Chart theme',
      'Data labels',
      'Composition geometry',
      'Shared angular frame',
      'Slice appearance',
      'Selection',
      'Motion',
      'Small categories',
      'Center content',
      'Legend',
      'Interaction',
      'Demo data',
    ]);
    await _expectCompleteCommonEditors(tester, 'concentric');
  });
}

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1600, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  await tester.pumpAndSettle();
}

void _expectSectionOrder(WidgetTester tester, List<String> expected) {
  final layout = tester.widget<ChartPageLayout>(find.byType(ChartPageLayout));
  final titles = layout.optionsChildren
      .map(
        (widget) => switch (widget) {
          OptionSection(:final title) => title,
          StandardChartOptions(:final sectionTitle) => sectionTitle,
          _ => null,
        },
      )
      .whereType<String>()
      .toList(growable: false);
  expect(titles, expected);
}

Future<void> _expectCompleteCommonEditors(
  WidgetTester tester,
  String prefix,
) async {
  for (final suffix in const [
    'theme',
    'palette',
    'show-labels',
    'label-layout',
    'label-minimum-share',
    'label-minimum-sweep',
    'label-padding',
    'gradient',
    'fixed-gradient-colors',
    'opacity',
    'slice-gap',
    'border-width',
    'border-color',
    'corner-radius',
    'corner-treatment',
    'slice-shadow',
    'selected-glow',
    'glow-color',
    'glow-blur',
    'glow-spread',
    'glow-opacity',
    'glow-offset',
    'selection-effect',
    'animation-mode',
    'data-transition-mode',
    'show-legend',
    'show-tooltips',
    'data-point-count',
  ]) {
    expect(
      _hasOption(tester, '$prefix-$suffix'),
      isTrue,
      reason: '$prefix must expose $suffix',
    );
  }

  final dynamic labelLayout = _option(tester, '$prefix-label-layout');
  labelLayout.onChanged(labelLayout.values.last);
  await tester.pump();

  _option<BoolOption>(tester, '$prefix-custom-connector-color').onChanged(true);
  _option<BoolOption>(tester, '$prefix-fixed-gradient-colors').onChanged(true);
  final dynamic borderColor = _option(tester, '$prefix-border-color');
  borderColor.onChanged(borderColor.values.last);
  _option<BoolOption>(tester, '$prefix-show-legend').onChanged(true);
  await tester.pump();

  final labelStyleKey = prefix == 'concentric'
      ? 'concentric-callout-style'
      : '$prefix-primary-label-style';
  for (final key in [
    labelStyleKey,
    '$prefix-inside-share-style',
    '$prefix-label-inside-offset',
    '$prefix-label-collision',
    '$prefix-label-outside-offset',
    '$prefix-connector-length',
    '$prefix-connector-width',
    '$prefix-custom-connector-color',
    '$prefix-connector-color',
    '$prefix-gradient-start-color',
    '$prefix-gradient-end-color',
    '$prefix-fixed-border-color',
    '$prefix-legend-content',
    '$prefix-legend-position',
    '$prefix-legend-orientation',
    '$prefix-legend-marker-shape',
    '$prefix-legend-marker-size',
    '$prefix-legend-font-size',
    '$prefix-legend-opacity',
    '$prefix-tooltip-style',
    '$prefix-tooltip-position',
    '$prefix-tooltip-follow-cursor',
    '$prefix-tooltip-offset',
  ]) {
    expect(
      _hasOption(tester, key),
      isTrue,
      reason: '$prefix must expose $key when its feature is enabled',
    );
  }
  expect(tester.takeException(), isNull);
}

bool _hasOption(WidgetTester tester, String key) =>
    _allOptionWidgets(tester).any((widget) => widget.key == ValueKey(key));

T _option<T extends Widget>(WidgetTester tester, String key) =>
    _allOptionWidgets(
      tester,
    ).whereType<T>().singleWhere((widget) => widget.key == ValueKey(key));

Iterable<Widget> _allOptionWidgets(WidgetTester tester) sync* {
  final layout = tester.widget<ChartPageLayout>(find.byType(ChartPageLayout));
  for (final child in layout.optionsChildren) {
    yield child;
    if (child is OptionSection) {
      yield* child.children;
    } else if (child is StandardChartOptions) {
      yield* child.additionalOptions ?? const <Widget>[];
      if (child.themeOptionKey != null) {
        yield _KeySentinel(key: child.themeOptionKey!);
      }
    }
  }
}

class _KeySentinel extends StatelessWidget {
  const _KeySentinel({required super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
