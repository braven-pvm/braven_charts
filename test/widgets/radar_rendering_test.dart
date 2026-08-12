import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radar_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_renderer.dart';
import 'package:flutter/gestures.dart' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders compatible Radar profiles through BravenChartPlus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              radarChartConfig: const RadarChartConfig(
                radialAxis: RadarNumericAxisConfig(maximum: 50),
              ),
              series: [
                RadarChartSeries.fromMap(
                  id: 'allocated',
                  name: 'Allocated budget',
                  values: const {
                    'Sales': 42,
                    'Marketing': 18,
                    'Development': 35,
                    'Support': 22,
                    'Technology': 14,
                    'Administration': 10,
                  },
                ),
                RadarChartSeries.fromMap(
                  id: 'actual',
                  name: 'Actual spending',
                  values: const {
                    'Sales': 47,
                    'Marketing': 31,
                    'Development': 29,
                    'Support': 18,
                    'Technology': 21,
                    'Administration': 14,
                  },
                ),
              ],
              theme: ChartTheme.light,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final elements = renderBox.debugElements.whereType<RadarSeriesElement>();
    expect(elements, hasLength(2));
    expect(elements.first.numericScale.maximum, 50);
    expect(elements.last.numericScale.maximum, 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard traverses Radar categories and profiles with durable identity',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 420,
              child: BravenChartPlus(
                key: const ValueKey('radar-keyboard'),
                bravenChartController: controller,
                interactionConfig: const InteractionConfig(
                  selection: ChartSelectionConfig(
                    scope: ChartSelectionScope.category,
                  ),
                ),
                series: [
                  RadarChartSeries.fromMap(
                    id: 'allocated',
                    values: const {
                      'Sales': 42,
                      'Marketing': 18,
                      'Development': 35,
                    },
                  ),
                  RadarChartSeries.fromMap(
                    id: 'actual',
                    values: const {
                      'Sales': 47,
                      'Marketing': 31,
                      'Development': 29,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final chart = find.byKey(const ValueKey('radar-keyboard'));
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: tester.getTopLeft(chart));
      await mouse.moveTo(tester.getCenter(chart));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'allocated', pointIndex: 1),
        const ChartPointRef(seriesId: 'actual', pointIndex: 1),
      });
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    },
  );

  testWidgets('hover tracks the same Radar category across every profile', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              bravenChartController: controller,
              interactionConfig: const InteractionConfig(
                tooltip: TooltipConfig(
                  showDelay: Duration.zero,
                  hideDelay: Duration.zero,
                ),
              ),
              series: [
                RadarChartSeries.fromMap(
                  id: 'allocated',
                  name: 'Allocated budget',
                  unit: 'USD',
                  values: const {
                    'Sales': 42,
                    'Marketing': 18,
                    'Development': 35,
                  },
                ),
                RadarChartSeries.fromMap(
                  id: 'actual',
                  name: 'Actual spending',
                  unit: 'USD',
                  values: const {
                    'Sales': 47,
                    'Marketing': 31,
                    'Development': 29,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderFinder = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
    );
    final renderBox = tester.renderObject<ChartRenderBox>(renderFinder);
    final allocated = renderBox.debugElements
        .whereType<RadarSeriesElement>()
        .first;
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    final target =
        tester.getTopLeft(renderFinder) +
        renderBox.plotToWidget(allocated.profile.vertices[1]);
    await mouse.addPointer(location: tester.getTopLeft(renderFinder));
    await mouse.moveTo(target);
    await tester.pump(const Duration(milliseconds: 250));

    expect(controller.focusedPointRefs, {
      const ChartPointRef(seriesId: 'allocated', pointIndex: 1),
      const ChartPointRef(seriesId: 'actual', pointIndex: 1),
    });
    final tooltipText = const TooltipRenderer().buildRadarCategoryTooltipText(
      dataHit: allocated.dataHitForPointIndex(1)!,
      elements: renderBox.debugElements,
    );
    expect(
      tooltipText,
      'Marketing\nAllocated budget: 18 USD\nActual spending: 31 USD',
    );
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });

  testWidgets('exposes Radar profile and vertex semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 420,
            child: BravenChartPlus(
              series: [
                RadarChartSeries.fromMap(
                  id: 'allocated',
                  name: 'Allocated budget',
                  unit: 'USD',
                  values: const {
                    'Sales': 42,
                    'Marketing': 18,
                    'Development': 35,
                  },
                ),
                RadarChartSeries.fromMap(
                  id: 'actual',
                  name: 'Actual spending',
                  unit: 'USD',
                  values: const {
                    'Sales': 47,
                    'Marketing': 31,
                    'Development': 29,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.semantics.byLabel(
        'Radar chart with 3 categories, 2 profiles, and 6 values',
      ),
      findsOneWidget,
    );
    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final firstHit = renderBox.debugElements
        .whereType<RadarSeriesElement>()
        .first
        .semanticDataHits
        .first;
    expect(firstHit.semanticLabel, startsWith('Allocated budget, Sales,'));
    expect(find.semantics.byLabel(firstHit.semanticLabel), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Radar radial entrance grows monotonically from the baseline', (
    tester,
  ) async {
    final base = ChartTheme.light;
    final theme = base.copyWith(
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 420,
          child: _RadarAnimationHarness(theme: theme),
        ),
      ),
    );

    RadarSeriesElement element() => tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<RadarSeriesElement>()
        .single;

    await tester.pump();
    expect(element().revealProgress, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(element().revealProgress, closeTo(0.5, 0.02));
    await tester.pumpAndSettle();
    expect(element().revealProgress, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radar fade and none modes preserve final geometry', (
    tester,
  ) async {
    final base = ChartTheme.light;
    final theme = base.copyWith(
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 420,
          child: _RadarAnimationHarness(
            theme: theme,
            animationMode: RadarAnimationMode.fade,
          ),
        ),
      ),
    );

    RadarSeriesElement element() => tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<RadarSeriesElement>()
        .single;

    await tester.pump();
    expect(element().revealProgress, 1);
    expect(element().fadeProgress, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(element().fadeProgress, closeTo(0.5, 0.02));
    await tester.pumpAndSettle();
    expect(element().fadeProgress, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 420,
          child: _RadarAnimationHarness(
            theme: theme,
            animationMode: RadarAnimationMode.none,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(element().revealProgress, 1);
    expect(element().fadeProgress, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Radar value updates interpolate by category identity', (
    tester,
  ) async {
    final key = GlobalKey<_RadarAnimationHarnessState>();
    final base = ChartTheme.light;
    final theme = base.copyWith(
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 420,
          child: _RadarAnimationHarness(key: key, theme: theme),
        ),
      ),
    );
    await tester.pumpAndSettle();

    RadarSeriesElement renderedElement() => tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<RadarSeriesElement>()
        .single;
    RadarChartSeries rendered() => renderedElement().series;

    key.currentState!.setValues(const {'C': 70, 'A': 60, 'B': 40});
    await tester.pump();
    await tester.pump();
    final targetScaleMaximum = renderedElement().numericScale.maximum;
    await tester.pump(const Duration(milliseconds: 200));
    expect(rendered().categories, ['C', 'A', 'B']);
    expect(rendered().points.map((point) => point.y), [60, 40, 60]);
    expect(renderedElement().numericScale.maximum, targetScaleMaximum);
    await tester.pumpAndSettle();
    expect(rendered().points.map((point) => point.y), [70, 60, 40]);
  });

  testWidgets(
    'Radar topology changes reveal final categories without morphing',
    (tester) async {
      final key = GlobalKey<_RadarAnimationHarnessState>();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.square(
            dimension: 420,
            child: _RadarAnimationHarness(key: key, theme: ChartTheme.light),
          ),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.setValues(const {'North': 75, 'East': 55, 'South': 35});
      await tester.pump();
      await tester.pump();

      final element = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single
          .debugElements
          .whereType<RadarSeriesElement>()
          .single;
      expect(element.series.categories, ['North', 'East', 'South']);
      expect(element.revealProgress, lessThan(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Radar replay respects reduced motion', (tester) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: SizedBox.square(
          dimension: 420,
          child: _RadarAnimationHarness(
            theme: ChartTheme.light,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();
    controller.replaySeriesEntrance();
    await tester.pump();

    final element = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<RadarSeriesElement>()
        .single;
    expect(element.revealProgress, 1);
    expect(element.fadeProgress, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

class _RadarAnimationHarness extends StatefulWidget {
  const _RadarAnimationHarness({
    super.key,
    required this.theme,
    this.controller,
    this.animationMode = RadarAnimationMode.radial,
  });

  final ChartTheme theme;
  final BravenChartController? controller;
  final RadarAnimationMode animationMode;

  @override
  State<_RadarAnimationHarness> createState() => _RadarAnimationHarnessState();
}

class _RadarAnimationHarnessState extends State<_RadarAnimationHarness> {
  Map<String, num> values = const {'A': 20, 'B': 80, 'C': 50};

  void setValues(Map<String, num> next) => setState(() => values = next);

  @override
  Widget build(BuildContext context) => BravenChartPlus(
    bravenChartController: widget.controller,
    showLegend: false,
    theme: widget.theme,
    radarChartConfig: const RadarChartConfig(
      radialAxis: RadarNumericAxisConfig(minimum: 0),
    ),
    series: [
      RadarChartSeries.fromMap(
        id: 'animated-radar',
        values: values,
        radarStyle: RadarSeriesStyle(animationMode: widget.animationMode),
      ),
    ],
  );
}
