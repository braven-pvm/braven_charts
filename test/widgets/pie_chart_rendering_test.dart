import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/widgets/pie_chart_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders one pie series through BravenChartPlus', (tester) async {
    await tester.pumpWidget(
      _host(
        PieChartSeries.fromMap(
          id: 'revenue-share',
          values: const {'Subscriptions': 42, 'Services': 31, 'Hardware': 27},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.text('Revenue mix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all-zero pie data uses the configured empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PieChartSeries.fromMap(id: 'empty', values: const {'A': 0, 'B': 0}),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('braven_chart_empty_state')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects Cartesian annotations on a radial chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BravenChartPlus(
          series: [
            PieChartSeries.fromMap(id: 'annotated', values: const {'A': 1}),
          ],
          annotations: [
            ThresholdAnnotation(
              id: 'threshold',
              axis: AnnotationAxis.y,
              value: 1,
            ),
          ],
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        contains('do not support Cartesian annotations'),
      ),
    );
  });

  testWidgets('honors a vertical center-right legend layout', (tester) async {
    final theme = ChartTheme.light.copyWith(
      legendStyle: ChartTheme.light.legendStyle.copyWith(
        position: LegendPosition.centerRight,
        orientation: LegendOrientation.vertical,
        markerShape: LegendMarkerShape.diamond,
      ),
      pieChartTheme: const PieChartTheme(animationMode: PieAnimationMode.none),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              height: 360,
              child: BravenChartPlus(
                showLegend: true,
                theme: theme,
                series: [
                  PieChartSeries.fromMap(
                    id: 'legend',
                    values: const {'A': 4, 'B': 3, 'C': 2},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chartRect = tester.getRect(find.byType(BravenChartPlus));
    final legendRect = tester.getRect(find.byType(PieChartLegend));
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final plotRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    expect(legendRect.center.dx, greaterThan(chartRect.center.dx));
    expect(legendRect.width, lessThan(chartRect.width * 0.36));
    expect(plotRect.width, greaterThan(chartRect.width * 0.64));
    expect(chartRect.right - legendRect.right, lessThanOrEqualTo(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom legend uses intrinsic height and leaves the chart bulk', (
    tester,
  ) async {
    final theme = ChartTheme.light.copyWith(
      legendStyle: ChartTheme.light.legendStyle.copyWith(
        position: LegendPosition.bottomCenter,
        orientation: LegendOrientation.horizontal,
        markerShape: LegendMarkerShape.circle,
      ),
      pieChartTheme: const PieChartTheme(animationMode: PieAnimationMode.none),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 420,
          child: BravenChartPlus(
            showLegend: true,
            theme: theme,
            series: [
              PieChartSeries.fromMap(
                id: 'bottom-legend',
                values: const {
                  'Subscriptions': 42,
                  'Services': 28,
                  'Hardware': 16,
                  'Training': 9,
                  'Other': 5,
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chartRect = tester.getRect(find.byType(BravenChartPlus));
    final legendRect = tester.getRect(find.byType(PieChartLegend));
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final plotRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    expect(legendRect.height, lessThan(chartRect.height * 0.25));
    expect(plotRect.height, greaterThan(chartRect.height * 0.70));
    expect(chartRect.bottom - legendRect.bottom, lessThanOrEqualTo(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pie grow animation runs and respects reduced motion', (
    tester,
  ) async {
    Widget build({required bool disableAnimations}) {
      return MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: SizedBox(
          width: 320,
          height: 240,
          child: BravenChartPlus(
            theme: ChartTheme.light,
            series: [
              PieChartSeries.fromMap(
                id: 'animated',
                values: const {'A': 2, 'B': 1},
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(disableAnimations: false));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(build(disableAnimations: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'elastic Pie entrance paints outside labels only after completion',
    (tester) async {
      const labelSurface = Color(0xFFFF00FF);
      const duration = Duration(milliseconds: 600);
      final base = ChartTheme.vibrant;
      final theme = base.copyWith(
        animationTheme: base.animationTheme.copyWith(
          dataUpdateDuration: duration,
          dataUpdateCurve: Curves.elasticOut,
        ),
        pieChartTheme: const PieChartTheme(
          animationMode: PieAnimationMode.grow,
          calloutStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFF111827), fontSize: 12),
            backgroundColor: labelSurface,
            borderColor: Color(0x00000000),
            borderWidth: 0,
            borderRadius: 4,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 640,
            height: 420,
            child: BravenChartPlus(
              showLegend: false,
              theme: theme,
              series: [
                PieChartSeries.fromMap(
                  id: 'project-effort',
                  values: const {
                    'Build': 46,
                    'Discovery': 18,
                    'Design': 14,
                    'Testing': 12,
                    'Launch': 7,
                    'Support': 3,
                  },
                  dataLabels: const PieDataLabelConfig(
                    position: PieDataLabelPosition.outside,
                    content: PieDataLabelContent.categoryAndPercentage,
                    minimumShare: 0.03,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      PieSeriesElement currentPieElement() {
        final renderBox = tester.allRenderObjects
            .whereType<ChartRenderBox>()
            .single;
        return renderBox.debugElements.whereType<PieSeriesElement>().single;
      }

      for (var elapsed = 50; elapsed < duration.inMilliseconds; elapsed += 50) {
        await tester.pump(const Duration(milliseconds: 50));
        final element = currentPieElement();
        expect(
          element.shouldPaintDataLabels,
          isFalse,
          reason: 'outside labels must not flash at ${elapsed}ms',
        );
      }

      await tester.pump(const Duration(milliseconds: 50));
      final completedElement = currentPieElement();
      expect(completedElement.isEntranceAnimationComplete, isTrue);
      expect(completedElement.shouldPaintDataLabels, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pointer selection has no accent outline but keyboard focus keeps a ring',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final base = ChartTheme.light;
      final theme = base.copyWith(
        animationTheme: base.animationTheme.copyWith(
          dataUpdateDuration: Duration.zero,
          themeChangeDuration: Duration.zero,
          interactionDuration: Duration.zero,
        ),
        pieChartTheme: const PieChartTheme(
          selectedElevation: PieElevationStyle(),
          animationMode: PieAnimationMode.none,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  theme: theme,
                  interactionConfig: const InteractionConfig(
                    showFocusBorder: false,
                    tooltip: TooltipConfig(enabled: false),
                  ),
                  series: [
                    PieChartSeries.fromMap(
                      id: 'pointer-selection',
                      values: const {'A': 2, 'B': 1},
                      pieStyle: const PieChartStyle(
                        radiusFactor: 0.8,
                        sliceGap: 0,
                        borderWidth: 0,
                        selectionExplodeOffset: 0,
                        selectedElevation: PieElevationStyle(),
                        animationMode: PieAnimationMode.none,
                      ),
                      dataLabels: const PieDataLabelConfig(isVisible: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      final firstHit = renderBox.dataHitForPointIndex('pointer-selection', 0)!;
      await tester.tapAt(
        renderBox.localToGlobal(renderBox.plotToWidget(firstHit.plotPosition)),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'pointer-selection', pointIndex: 0),
      });
      expect(
        find.semantics
            .byLabel(RegExp(r'^A,'))
            .evaluate()
            .every(
              (node) =>
                  node.getSemanticsData().flagsCollection.isFocused !=
                  ui.Tristate.isTrue,
            ),
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        find.semantics
            .byLabel(RegExp(r'^B,'))
            .evaluate()
            .any(
              (node) =>
                  node.getSemanticsData().flagsCollection.isFocused ==
                  ui.Tristate.isTrue,
            ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('all Pie legend anchors remain bounded', (tester) async {
    for (final position in LegendPosition.values) {
      final vertical =
          position == LegendPosition.centerLeft ||
          position == LegendPosition.centerRight;
      final theme = ChartTheme.light.copyWith(
        legendStyle: ChartTheme.light.legendStyle.copyWith(
          position: position,
          orientation: vertical
              ? LegendOrientation.vertical
              : LegendOrientation.horizontal,
        ),
        pieChartTheme: const PieChartTheme(
          animationMode: PieAnimationMode.none,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 420,
            height: 320,
            child: BravenChartPlus(
              showLegend: true,
              theme: theme,
              series: [
                PieChartSeries.fromMap(
                  id: 'positions',
                  values: const {
                    'One': 8,
                    'Two': 7,
                    'Three': 6,
                    'Four': 5,
                    'Five': 4,
                    'Six': 3,
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(PieChartLegend),
        findsOneWidget,
        reason: position.name,
      );
      final chartRect = tester.getRect(find.byType(BravenChartPlus));
      final legendRect = tester.getRect(find.byType(PieChartLegend));
      expect(
        chartRect.inflate(0.1).contains(legendRect.topLeft),
        isTrue,
        reason: '${position.name} top-left',
      );
      expect(
        chartRect.inflate(0.1).contains(legendRect.bottomRight),
        isTrue,
        reason: '${position.name} bottom-right',
      );
      switch (position) {
        case LegendPosition.topLeft:
        case LegendPosition.bottomLeft:
        case LegendPosition.centerLeft:
          expect(
            legendRect.left - chartRect.left,
            lessThanOrEqualTo(16),
            reason: position.name,
          );
        case LegendPosition.topRight:
        case LegendPosition.bottomRight:
        case LegendPosition.centerRight:
          expect(
            chartRect.right - legendRect.right,
            lessThanOrEqualTo(16),
            reason: position.name,
          );
        case LegendPosition.topCenter:
        case LegendPosition.center:
        case LegendPosition.bottomCenter:
          expect(
            (legendRect.center.dx - chartRect.center.dx).abs(),
            lessThanOrEqualTo(1),
            reason: position.name,
          );
      }
      expect(tester.takeException(), isNull, reason: position.name);
    }
  });
}

Widget _host(PieChartSeries series) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          height: 320,
          child: BravenChartPlus(
            title: 'Revenue mix',
            series: [series],
            theme: ChartTheme.light,
          ),
        ),
      ),
    ),
  );
}
