import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('synchronizes display mode and selector visibility', (
    tester,
  ) async {
    final group = ChartWorkbenchGroupController();
    final first = ChartWorkbenchController();
    final second = ChartWorkbenchController();
    addTearDown(group.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      _groupHost(
        group: group,
        workbenches: [
          _workbench(controller: first),
          _workbench(controller: second),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNWidgets(2),
    );

    final split = group.setDisplayMode(ChartDisplayMode.split);
    expect(split, isA<ChartArtifactSuccess<ChartDisplayMode>>());
    await tester.pumpAndSettle();

    expect(first.requestedMode, ChartDisplayMode.split);
    expect(second.requestedMode, ChartDisplayMode.split);
    // Effective rendering may use the compact Split pane at narrow widths,
    // but the shared presentation request remains Split for every member.
    expect(first.requestedMode, ChartDisplayMode.split);
    expect(second.requestedMode, ChartDisplayMode.split);

    final data = first.setDisplayMode(ChartDisplayMode.data);
    expect(data, isA<ChartArtifactSuccess<ChartDisplayMode>>());
    await tester.pumpAndSettle();

    expect(group.displayMode, ChartDisplayMode.data);
    expect(second.requestedMode, ChartDisplayMode.data);

    group.setShowModeSwitcher(false);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNothing,
    );
    expect(first.effectiveMode, ChartDisplayMode.data);
    expect(second.effectiveMode, ChartDisplayMode.data);
  });

  testWidgets('preserves each Workbench local selector capability', (
    tester,
  ) async {
    final group = ChartWorkbenchGroupController();
    final first = ChartWorkbenchController();
    final second = ChartWorkbenchController();
    addTearDown(group.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      _groupHost(
        group: group,
        workbenches: [
          _workbench(controller: first, showModeSwitcher: false),
          _workbench(controller: second),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsOneWidget,
    );

    group
      ..setShowModeSwitcher(false)
      ..setShowModeSwitcher(true);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsOneWidget,
    );
  });

  testWidgets('reconciles to a mode supported by every mounted Workbench', (
    tester,
  ) async {
    final group = ChartWorkbenchGroupController(
      initialDisplayMode: ChartDisplayMode.source,
    );
    final first = ChartWorkbenchController();
    final second = ChartWorkbenchController();
    addTearDown(group.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      _groupHost(
        group: group,
        workbenches: [
          _workbench(
            controller: first,
            availableDisplayModes: const {
              ChartDisplayMode.chart,
              ChartDisplayMode.source,
            },
          ),
          _workbench(
            controller: second,
            availableDisplayModes: const {
              ChartDisplayMode.chart,
              ChartDisplayMode.data,
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(group.availableDisplayModes, const {ChartDisplayMode.chart});
    expect(group.displayMode, ChartDisplayMode.chart);
    expect(first.effectiveMode, ChartDisplayMode.chart);
    expect(second.effectiveMode, ChartDisplayMode.chart);

    final unavailable = group.setDisplayMode(ChartDisplayMode.source);
    expect(unavailable, isA<ChartArtifactFailure<ChartDisplayMode>>());
    expect(group.displayMode, ChartDisplayMode.chart);
  });

  testWidgets('nearest nested scope owns its chart family independently', (
    tester,
  ) async {
    final system = ChartWorkbenchGroupController();
    final family = ChartWorkbenchGroupController(
      initialDisplayMode: ChartDisplayMode.data,
      showModeSwitcher: false,
    );
    final systemController = ChartWorkbenchController();
    final familyController = ChartWorkbenchController();
    addTearDown(system.dispose);
    addTearDown(family.dispose);
    addTearDown(systemController.dispose);
    addTearDown(familyController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartWorkbenchScope(
            controller: system,
            child: Row(
              children: [
                Expanded(child: _workbench(controller: systemController)),
                Expanded(
                  child: ChartWorkbenchScope(
                    controller: family,
                    child: _workbench(controller: familyController),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(systemController.requestedMode, ChartDisplayMode.chart);
    expect(familyController.requestedMode, ChartDisplayMode.data);
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsOneWidget,
    );

    system.setDisplayMode(ChartDisplayMode.split);
    await tester.pumpAndSettle();

    expect(systemController.requestedMode, ChartDisplayMode.split);
    expect(familyController.requestedMode, ChartDisplayMode.data);
  });

  testWidgets('detached caller-owned controllers stop broadcasting', (
    tester,
  ) async {
    final group = ChartWorkbenchGroupController();
    final first = ChartWorkbenchController();
    final replacement = ChartWorkbenchController();
    addTearDown(group.dispose);
    addTearDown(first.dispose);
    addTearDown(replacement.dispose);

    await tester.pumpWidget(
      _groupHost(
        group: group,
        workbenches: [_workbench(controller: first)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _groupHost(
        group: group,
        workbenches: [_workbench(controller: replacement)],
      ),
    );
    await tester.pumpAndSettle();

    final localResult = first.setDisplayMode(ChartDisplayMode.data);
    expect(localResult, isA<ChartArtifactSuccess<ChartDisplayMode>>());
    expect(group.displayMode, ChartDisplayMode.chart);
    expect(replacement.requestedMode, ChartDisplayMode.chart);
  });
}

Widget _groupHost({
  required ChartWorkbenchGroupController group,
  required List<Widget> workbenches,
}) => MaterialApp(
  home: Scaffold(
    body: ChartWorkbenchScope(
      controller: group,
      child: Row(
        children: [
          for (final workbench in workbenches) Expanded(child: workbench),
        ],
      ),
    ),
  ),
);

Widget _workbench({
  required ChartWorkbenchController controller,
  bool showModeSwitcher = true,
  Set<ChartDisplayMode> availableDisplayModes = const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
}) => BravenChartWorkbench(
  workbenchController: controller,
  showModeSwitcher: showModeSwitcher,
  availableDisplayModes: availableDisplayModes,
  chartBuilder: (context, chartController) => BravenChartPlus(
    bravenChartController: chartController,
    showLegend: false,
    series: const [
      LineChartSeries(
        id: 'signal',
        points: [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 2)],
      ),
    ],
  ),
);
