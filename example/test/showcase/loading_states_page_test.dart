import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/loading_states_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading workbench presents the complete lifecycle ribbon', (
    tester,
  ) async {
    _setWideViewport(tester);
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Choose a lifecycle presentation'), findsOneWidget);
    expect(find.byKey(const ValueKey('loading-state-ribbon')), findsOneWidget);
    expect(find.byKey(const ValueKey('loading-state-guide')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('loading-state-main-stage')),
      findsOneWidget,
    );

    for (final name in [
      'animatedChart',
      'spinner',
      'progressBar',
      'empty',
      'loaded',
    ]) {
      expect(
        find.byKey(ValueKey('loading-state-pattern-$name')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('loading-state-preview-$name')),
        findsOneWidget,
      );
    }

    final chart = _mainChart(tester, 'animatedChart');
    expect(chart.isLoading, isTrue);
    expect(chart.loadingConfig.indicator, ChartLoadingIndicator.skeleton);
    expect(chart.loadingConfig.semanticLabel, 'Loading power samples');
    expect(chart.loadingConfig.skeletonStyle.motionIntensity, 1);
    expect(chart.loadingConfig.skeletonStyle.edgeFadeFraction, 0.12);

    expect(find.text('Lifecycle State'), findsOneWidget);
    expect(find.text('Loading Content'), findsOneWidget);
    expect(find.text('Animated Chart'), findsOneWidget);
  });

  testWidgets(
    'spinner and progress patterns expose indeterminate and known work',
    (tester) async {
      _setWideViewport(tester);
      await tester.pumpWidget(_testApp());
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(
        find.byKey(const ValueKey('loading-state-pattern-spinner')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      var chart = _mainChart(tester, 'spinner');
      expect(chart.isLoading, isTrue);
      expect(chart.loadingConfig.indicator, ChartLoadingIndicator.circular);
      expect(chart.loadingConfig.progress, isNull);
      expect(find.text('Determinate Progress'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('loading-state-pattern-progressBar')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      chart = _mainChart(tester, 'progressBar');
      expect(chart.loadingConfig.indicator, ChartLoadingIndicator.linear);
      expect(chart.loadingConfig.progress, 0.58);
      expect(find.text('Progress'), findsWidgets);
      expect(find.text('Presentation Source'), findsOneWidget);
    },
  );

  testWidgets('empty and loaded patterns resolve within the same viewport', (
    tester,
  ) async {
    _setWideViewport(tester);
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byKey(const ValueKey('loading-state-pattern-empty')));
    await tester.pump(const Duration(milliseconds: 250));
    var chart = _mainChart(tester, 'empty');
    expect(chart.isLoading, isFalse);
    expect(chart.series, isEmpty);
    expect(chart.emptyStateConfig.title, 'No workout samples');
    expect(find.text('No workout samples'), findsWidgets);
    expect(find.text('Empty State'), findsWidgets);
    expect(find.text('Custom Action State'), findsOneWidget);

    final options = find
        .descendant(
          of: find.byType(OptionsPanel),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Custom Action State'),
      260,
      scrollable: options,
    );
    tester
        .widget<BoolOption>(find.byKey(const ValueKey('custom-empty-action')))
        .onChanged(true);
    await tester.pump(const Duration(milliseconds: 250));
    chart = _mainChart(tester, 'empty');
    expect(chart.emptyStateConfig.customBuilder, isNotNull);
    expect(find.text('Import workout'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('loading-state-pattern-loaded')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    chart = _mainChart(tester, 'loaded');
    expect(chart.isLoading, isFalse);
    expect(chart.series, hasLength(1));
    expect(chart.series.single.points, hasLength(8));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('loading-state-main-chart-loaded')),
        matching: find.byKey(
          const ValueKey<String>('braven_chart_empty_state'),
        ),
      ),
      findsNothing,
    );
  });
}

Widget _testApp() {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const Scaffold(body: LoadingStatesPage()),
  );
}

void _setWideViewport(WidgetTester tester) {
  final pixelRatio = tester.view.devicePixelRatio;
  tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

BravenChartPlus _mainChart(WidgetTester tester, String pattern) {
  return tester.widget<BravenChartPlus>(
    find.byKey(ValueKey('loading-state-main-chart-$pattern')),
  );
}
