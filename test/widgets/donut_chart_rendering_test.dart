import 'dart:ui' show SemanticsAction, Tristate;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a first-class Donut through BravenChartPlus', (
    tester,
  ) async {
    ChartDataPoint? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              key: const ValueKey('donut-chart'),
              showLegend: false,
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              onPointTap: (point, _) => tapped = point,
              series: [
                DonutChartSeries.fromMap(
                  id: 'registrations',
                  values: const {
                    'EV': 24,
                    'Hybrid': 13,
                    'Diesel': 37,
                    'Petrol': 26,
                  },
                  donutStyle: const DonutChartStyle(
                    innerRadiusFactor: 0.58,
                    sweepAngleDegrees: 360,
                    sliceGap: 0,
                    cornerRadius: 6,
                  ),
                  dataLabels: const PieDataLabelConfig(isVisible: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final chart = find.byKey(const ValueKey('donut-chart'));
    final rect = tester.getRect(chart);
    await tester.tapAt(rect.center);
    await tester.pump();
    expect(tapped, isNull);

    await tester.tapAt(rect.center + const Offset(120, 0));
    await tester.pump();
    expect(tapped?.label, isNotNull);
    expect(tester.takeException(), isNull);
  });

  test('Donut geometry uses the radial element contract', () {
    final element = PieSeriesElement(
      series: DonutChartSeries.fromMap(id: 'ring', values: const {'A': 1}),
      size: const Size.square(200),
      theme: ChartTheme.light,
    );

    expect(element.geometry.innerRadius, greaterThan(0));
    expect(element.dataHitAt(element.geometry.center), isNull);
    expect(
      element.dataHitAt(element.geometry.slices.single.tooltipAnchor),
      isNotNull,
    );
  });

  test(
    'lifted Donut selection scales, offsets, and remains hit-testable in bounds',
    () {
      final series = DonutChartSeries.fromMap(
        id: 'lifted-ring',
        values: const {'Selected': 42, 'Other': 58},
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.58,
          radiusFactor: 0.78,
          sliceGap: 4,
          selectedElevation: PieElevationStyle(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
          animationMode: PieAnimationMode.none,
        ),
        selectionStyle: const RadialSelectionStyle(
          effect: RadialSelectionEffect.lift,
          liftScale: 1.12,
          liftOffset: 8,
          backdropBlur: 1.5,
        ),
        dataLabels: const PieDataLabelConfig(isVisible: false),
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(220),
        theme: ChartTheme.light,
        selectedPointIndices: const {0},
      );
      final unselectedElement = PieSeriesElement(
        series: series,
        size: const Size.square(220),
        theme: ChartTheme.light,
      );

      final selected = element.geometry.slices.first;
      expect(selected.isSelected, isTrue);
      expect(selected.selectionScale, closeTo(1.12, 1e-9));
      expect(selected.liftOffset.distance, closeTo(8, 1e-9));
      expect(selected.explodeOffset, Offset.zero);
      expect(
        element.dataHitAt(selected.tooltipAnchor)?.pointIndex,
        selected.pointIndex,
      );
      expect(selected.path.getBounds().left, greaterThanOrEqualTo(0));
      expect(selected.path.getBounds().top, greaterThanOrEqualTo(0));
      expect(selected.path.getBounds().right, lessThanOrEqualTo(220));
      expect(selected.path.getBounds().bottom, lessThanOrEqualTo(220));
      expect(element.geometry.center, unselectedElement.geometry.center);
    },
  );

  testWidgets(
    'center content follows legend and controller selection with one summary node',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 420,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: true,
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                series: [
                  DonutChartSeries.fromMap(
                    id: 'center-selection',
                    unit: 'USD',
                    values: const {'Subscriptions': 42, 'Services': 58},
                    centerContent: const DonutCenterContent(
                      label: 'Current',
                      valueMode: DonutCenterValueMode.selectedOrTotal,
                    ),
                    donutStyle: const DonutChartStyle(
                      innerRadiusFactor: 0.62,
                      sliceGap: 0,
                      animationMode: PieAnimationMode.none,
                    ),
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel(
          'Donut center, Current, 100 USD, total fallback',
        ),
        findsOne,
      );

      await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'center-selection', pointIndex: 0),
      });
      final legendSelectedSummary = find.semantics.byLabel(
        'Donut center, Current, 42 USD, selected slice Subscriptions',
      );
      expect(legendSelectedSummary, findsOne);
      expect(
        legendSelectedSummary.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isFalse,
      );

      final revision = controller.effectiveDocumentRevision.value!;
      final result = controller.selectPoint(
        const ChartPointRef(seriesId: 'center-selection', pointIndex: 1),
        revision: revision,
      );
      expect(result, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel(
          'Donut center, Current, 58 USD, selected slice Services',
        ),
        findsOne,
      );
      expect(find.semantics.byLabel(RegExp(r'^Donut center,')), findsOne);
      semantics.dispose();
    },
  );

  testWidgets(
    'runtime center builder receives selection and package-owned activation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      DonutCenterData? activated;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 420,
              child: BravenChartPlus(
                bravenChartController: controller,
                showLegend: true,
                theme: ChartTheme.light.copyWith(
                  pieChartTheme: const PieChartTheme(
                    animationMode: PieAnimationMode.none,
                  ),
                ),
                donutCenterBuilder: (context, center) => Center(
                  key: const ValueKey('custom-donut-center'),
                  child: Text(
                    center.selectedCategory ?? 'All categories',
                    style: center.defaultValueStyle.copyWith(fontSize: 14),
                  ),
                ),
                onDonutCenterTap: (center) => activated = center,
                series: [
                  DonutChartSeries.fromMap(
                    id: 'custom-center',
                    unit: 'USD',
                    values: const {'Subscriptions': 42, 'Services': 58},
                    centerContent: const DonutCenterContent(
                      label: 'Current',
                      valueMode: DonutCenterValueMode.selectedOrTotal,
                    ),
                    donutStyle: const DonutChartStyle(
                      innerRadiusFactor: 0.64,
                      sliceGap: 0,
                      animationMode: PieAnimationMode.none,
                    ),
                    dataLabels: const PieDataLabelConfig(isVisible: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom-donut-center')), findsOneWidget);
      expect(find.text('All categories'), findsOneWidget);
      expect(find.semantics.byLabel(RegExp(r'^Donut center,')), findsOne);
      final summary = find.semantics.byLabel(
        'Donut center, Current, 100 USD, total fallback',
      );
      expect(
        summary.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('custom-donut-center')));
      await tester.pump();
      expect(activated?.seriesId, 'custom-center');
      expect(activated?.total, 100);
      expect(activated?.hasSelection, isFalse);
      expect(activated?.availableDiameter, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
      await tester.pumpAndSettle();
      expect(find.text('Subscriptions'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('custom-donut-center')));
      await tester.pump();
      expect(activated?.selectedCategory, 'Subscriptions');
      expect(activated?.selectedValue, 42);
      expect(activated?.selectedShare, closeTo(0.42, 0.0001));
      expect(activated?.selectedSourcePointIndices, [0]);
      expect(activated?.selectedSourcePoints.single.label, 'Subscriptions');
      semantics.dispose();
    },
  );

  testWidgets(
    'large-text high-contrast Donut stays bounded and keeps semantic meaning',
    (tester) async {
      tester.view.physicalSize = const Size(520, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.8),
              highContrast: true,
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: SizedBox(
            width: 520,
            height: 420,
            child: BravenChartPlus(
              showLegend: false,
              theme: ChartTheme.highContrast,
              series: [
                DonutChartSeries.fromMap(
                  id: 'accessible-donut',
                  unit: 'requests',
                  values: const {
                    'Subscriptions': 42,
                    'Professional services': 28,
                    'Hardware integrations': 16,
                    'Training': 9,
                    'Other': 5,
                  },
                  donutStyle: const DonutChartStyle(
                    innerRadiusFactor: 0.62,
                    sliceGap: 2,
                    cornerRadius: 6,
                  ),
                  centerContent: const DonutCenterContent(
                    label: 'Total requests',
                    valueMode: DonutCenterValueMode.total,
                  ),
                  dataLabels: const PieDataLabelConfig(
                    position: PieDataLabelPosition.outside,
                    content: PieDataLabelContent.categoryAndPercentage,
                    minimumShare: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel('Donut center, Total requests, 100 requests'),
        findsOne,
      );
      expect(
        find.semantics.byLabel(
          'Subscriptions, 42.00 requests, 42.0 percent, slice 1 of 5, '
          'not selected',
        ),
        findsOne,
      );
      expect(
        tester.getSize(find.byType(BravenChartPlus)),
        const Size(520, 420),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('Donut entrance animation respects reduced motion', (
    tester,
  ) async {
    Widget build({
      required bool disableAnimations,
      required PieAnimationMode animationMode,
    }) {
      return MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: SizedBox(
          width: 360,
          height: 280,
          child: BravenChartPlus(
            key: ValueKey(
              'animated-donut-${animationMode.name}-$disableAnimations',
            ),
            showLegend: false,
            theme: ChartTheme.light,
            series: [
              DonutChartSeries.fromMap(
                id: 'animated-donut-${animationMode.name}',
                values: const {'A': 2, 'B': 1},
                donutStyle: DonutChartStyle(animationMode: animationMode),
                centerContent: const DonutCenterContent(
                  valueMode: DonutCenterValueMode.total,
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (final mode in const [
      PieAnimationMode.grow,
      PieAnimationMode.sweep,
      PieAnimationMode.fade,
    ]) {
      await tester.pumpWidget(
        build(disableAnimations: false, animationMode: mode),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue, reason: mode.name);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        build(disableAnimations: true, animationMode: mode),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse, reason: mode.name);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('generic controller replays Donut sweep entrance', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    Widget build({bool disableAnimations = false}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: SizedBox(
        width: 360,
        height: 280,
        child: BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: [
            DonutChartSeries.fromMap(
              id: 'replay-sweep',
              values: const {'A': 2, 'B': 1},
              donutStyle: const DonutChartStyle(
                innerRadiusFactor: 0.55,
                animationMode: PieAnimationMode.sweep,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    controller.replaySeriesEntrance();
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    await tester.pumpWidget(build(disableAnimations: true));
    await tester.pump();
    controller.replaySeriesEntrance();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'changing only the radial animation mode starts the new entrance',
    (tester) async {
      Widget build(PieAnimationMode mode) => MaterialApp(
        home: SizedBox(
          width: 360,
          height: 280,
          child: BravenChartPlus(
            showLegend: false,
            series: [
              DonutChartSeries.fromMap(
                id: 'mode-change',
                values: const {'A': 2, 'B': 1},
                donutStyle: DonutChartStyle(
                  innerRadiusFactor: 0.55,
                  animationMode: mode,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(build(PieAnimationMode.grow));
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(PieAnimationMode.fade));
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native Donut table selection updates the same center summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final controller = BravenChartController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _DonutTableSelectionHost(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'table-donut', pointIndex: 1),
    });
    expect(
      find.semantics.byLabel(
        'Donut center, Services, 58 USD, selected slice Services',
      ),
      findsOne,
    );
    expect(find.byKey(const ValueKey('table-donut:1')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'grouped Donut selection expands to every original table row and controller ref',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _DonutTableSelectionHost(
              controller: controller,
              grouped: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'table-donut', pointIndex: 1),
        const ChartPointRef(seriesId: 'table-donut', pointIndex: 2),
        const ChartPointRef(seriesId: 'table-donut', pointIndex: 3),
      });
      expect(
        find.semantics.byLabel(
          'Donut center, Other, 20 USD, selected slice Other',
        ),
        findsOne,
      );
      for (final index in <int>[1, 2, 3]) {
        expect(
          tester
              .getSemantics(find.byKey(ValueKey<String>('table-donut:$index')))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'grouped legend activation reports one visible point and original selection points',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      ChartDataPoint? tappedPoint;
      List<ChartDataPoint> selectedPoints = const <ChartDataPoint>[];

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 520,
            height: 420,
            child: BravenChartPlus(
              bravenChartController: controller,
              showLegend: true,
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              interactionConfig: InteractionConfig(
                onSelectionChanged: (points) => selectedPoints = points,
              ),
              onPointTap: (point, _) => tappedPoint = point,
              series: [
                DonutChartSeries.fromMap(
                  id: 'group-callbacks',
                  unit: 'tickets',
                  values: const {
                    'Core': 80,
                    'Email': 8,
                    'Chat': 7,
                    'Other source': 5,
                  },
                  sliceGroupingConfig: const RadialSliceGroupingConfig(
                    minimumShare: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('pie-legend-item-1-2-3')),
      );
      await tester.pumpAndSettle();

      expect(tappedPoint?.label, 'Other');
      expect(tappedPoint?.y, 20);
      expect(
        selectedPoints.map((point) => point.label),
        orderedEquals(<String?>['Email', 'Chat', 'Other source']),
      );
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'group-callbacks', pointIndex: 1),
        const ChartPointRef(seriesId: 'group-callbacks', pointIndex: 2),
        const ChartPointRef(seriesId: 'group-callbacks', pointIndex: 3),
      });
      expect(
        find.semantics.byLabel(
          'Other, 20.00 tickets, 20.0 percent, 3 grouped categories, slice 2 of 2, selected',
        ),
        findsOne,
      );
      semantics.dispose();
    },
  );
}

class _DonutTableSelectionHost extends StatelessWidget {
  const _DonutTableSelectionHost({
    required this.controller,
    this.grouped = false,
  });

  final BravenChartController controller;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final series = DonutChartSeries.fromMap(
      id: 'table-donut',
      unit: 'USD',
      values: grouped
          ? const {'Core': 80, 'Email': 8, 'Chat': 7, 'Other source': 5}
          : const {'Subscriptions': 42, 'Services': 58},
      sliceGroupingConfig: grouped
          ? const RadialSliceGroupingConfig(minimumShare: 0.1)
          : null,
      centerContent: const DonutCenterContent(
        valueMode: DonutCenterValueMode.selectedOrTotal,
      ),
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.62,
        sliceGap: 0,
        animationMode: PieAnimationMode.none,
      ),
      dataLabels: const PieDataLabelConfig(isVisible: false),
    );
    final seriesDocument =
        (ChartSeriesDocumentCodec.encode(series)
                as ChartArtifactSuccess<ChartSeriesDocument>)
            .value;
    final model = ChartTableModel.fromDocument(
      ChartDocument(
        documentId: 'donut-table-selection',
        revision: 1,
        series: [seriesDocument],
        xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
        axes: const [],
        theme:
            (ChartThemeDocumentCodec.encode(ChartTheme.light)
                    as ChartArtifactSuccess<ChartThemeDocument>)
                .value,
        interaction:
            (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                    as ChartArtifactSuccess<ChartInteractionDocument>)
                .value,
      ),
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: BravenChartPlus(
              bravenChartController: controller,
              showLegend: false,
              theme: ChartTheme.light.copyWith(
                pieChartTheme: const PieChartTheme(
                  animationMode: PieAnimationMode.none,
                ),
              ),
              series: [series],
            ),
          ),
          Expanded(
            child: ChartDataTable(
              model: model,
              selectedPointRefs: controller.selectedPointRefs,
              onRowActivated: (points) {
                final revision = controller.effectiveDocumentRevision.value;
                if (revision == null) return;
                controller.selectPoints(points, revision: revision);
              },
            ),
          ),
        ],
      ),
    );
  }
}
