import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final categorical in [false, true]) {
    testWidgets(
      'financial touch pan keeps the initialized window during host rebuilds '
      '(categorical=$categorical)',
      (tester) async {
        if (categorical) {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        final group = ChartInteractionGroupController();
        addTearDown(group.dispose);
        final callbacks = <Map<String, double>>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _FinancialHost(
                group: group,
                categorical: categorical,
                onViewportChanged: callbacks.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        List<ChartRenderBox> boxes() => find
            .byWidgetPredicate(
              (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
            )
            .evaluate()
            .map((element) => element.renderObject! as ChartRenderBox)
            .toList();

        expect(boxes(), hasLength(2));
        expect(boxes().first.transform!.dataXMin, closeTo(250, 1e-7));
        expect(boxes().first.transform!.dataXMax, closeTo(350, 1e-7));
        for (var pane = 0; pane < 2; pane++) {
          final chart = find.byType(BravenChartPlus).at(pane);
          for (var pass = 0; pass < 3; pass++) {
            final gesture = await tester.startGesture(
              tester.getCenter(chart) - const Offset(80, 0),
              kind: PointerDeviceKind.touch,
            );
            await gesture.moveBy(const Offset(24, 0));
            await tester.pump();
            for (var step = 0; step < 10; step++) {
              final previous = boxes()[pane].transform!;
              await gesture.moveBy(Offset(pass.isEven ? 8 : -8, 0));
              await tester.pump(const Duration(milliseconds: 16));
              final current = boxes()[pane].transform!;
              expect(current.dataXRange, closeTo(100, 1e-7));
              expect(
                (current.dataXMin - previous.dataXMin).abs(),
                lessThan(10),
              );
              expect(
                boxes()[1 - pane].transform!.dataXMin,
                closeTo(current.dataXMin, 1e-7),
              );
            }
            await gesture.up();
            await tester.pumpAndSettle();
            expect(boxes().first.transform!.dataXRange, closeTo(100, 1e-7));
            expect(
              boxes().last.transform!.dataXMin,
              closeTo(boxes().first.transform!.dataXMin, 1e-7),
            );
          }
        }
        expect(callbacks, isNotEmpty);
        for (final callback in callbacks) {
          expect(callback['maxX']! - callback['minX']!, closeTo(100, 1e-7));
          expect(callback['minX'], greaterThan(150));
        }
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'changing explicit price Y bounds preserves the shared X window',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final hostKey = GlobalKey<_FinancialHostState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _FinancialHost(
              key: hostKey,
              group: group,
              categorical: false,
              onViewportChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      hostKey.currentState!.setPriceBounds(100, 110);
      await tester.pumpAndSettle();
      hostKey.currentState!.setPriceBounds(150, 160);
      await tester.pump();
      final boxes = find
          .byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_ChartRenderWidget',
          )
          .evaluate()
          .map((e) => e.renderObject! as ChartRenderBox)
          .toList();
      expect(boxes.first.transform!.dataXMin, closeTo(250, 1e-7));
      expect(boxes.first.transform!.dataXMax, closeTo(350, 1e-7));
      expect(boxes.first.transform!.dataYMin, closeTo(150, 1e-7));
      expect(boxes.first.transform!.dataYMax, closeTo(160, 1e-7));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'pinch-to-pan handoff and data refresh preserve the financial window',
    (tester) async {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final hostKey = GlobalKey<_FinancialHostState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _FinancialHost(
              key: hostKey,
              group: group,
              categorical: false,
              onViewportChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      ChartRenderBox box(int index) =>
          find
                  .byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_ChartRenderWidget',
                  )
                  .evaluate()
                  .elementAt(index)
                  .renderObject!
              as ChartRenderBox;
      final center = tester.getCenter(find.byType(BravenChartPlus).first);
      final first = await tester.startGesture(
        center - const Offset(40, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(40, 0),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(-25, 0));
      await second.moveBy(const Offset(25, 0));
      await tester.pump();
      await first.moveBy(const Offset(-25, 0));
      await second.moveBy(const Offset(25, 0));
      await tester.pump();
      final pinched = box(0).transform!;
      expect(pinched.dataXRange, lessThan(100));
      expect(pinched.dataXRange, greaterThan(30));
      hostKey.currentState!.refreshPoints();
      await tester.pump();
      expect(box(0).transform!.dataXMin, closeTo(pinched.dataXMin, 1e-7));
      expect(box(0).transform!.dataXMax, closeTo(pinched.dataXMax, 1e-7));
      await first.up();
      await tester.pump();
      await second.moveBy(const Offset(24, 0));
      await tester.pump();
      expect(box(0).transform!.dataXRange, closeTo(pinched.dataXRange, 1e-7));
      expect(
        (box(0).transform!.dataXMin - pinched.dataXMin).abs(),
        lessThan(10),
      );
      expect(
        box(1).transform!.dataXMin,
        closeTo(box(0).transform!.dataXMin, 1e-7),
      );
      await second.up();
      await tester.pumpAndSettle();
      expect(box(0).transform!.dataXRange, closeTo(pinched.dataXRange, 1e-7));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

class _FinancialHost extends StatefulWidget {
  const _FinancialHost({
    super.key,
    required this.group,
    required this.categorical,
    required this.onViewportChanged,
  });
  final ChartInteractionGroupController group;
  final bool categorical;
  final ValueChanged<Map<String, double>> onViewportChanged;

  @override
  State<_FinancialHost> createState() => _FinancialHostState();
}

class _FinancialHostState extends State<_FinancialHost> {
  double? yMin;
  double? yMax;

  void setPriceBounds(double minimum, double maximum) {
    setState(() {
      yMin = minimum;
      yMax = maximum;
    });
  }

  void refreshPoints() {
    setState(() {
      points = [
        for (final point in points)
          point.copyWith(
            open: point.open + 1,
            high: point.high + 1,
            low: point.low + 1,
            close: point.close + 1,
          ),
      ];
    });
  }

  var points = [
    for (var i = 0; i < 400; i++)
      CandlestickDataPoint(
        x: i.toDouble(),
        open: 100 + (i % 20).toDouble(),
        high: 103 + (i % 20).toDouble(),
        low: 97 + (i % 20).toDouble(),
        close: 101 + (i % 20).toDouble(),
      ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.group.setViewport(const ChartXViewport(min: 250, max: 350));
      setState(() {});
    });
  }

  void changed(Map<String, double> bounds) {
    widget.onViewportChanged(bounds);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categorical
        ? CategoryAxisConfig(
            categories: [for (var i = 0; i < 400; i++) 'Bar $i'],
            autoViewport: true,
          )
        : null;
    final interaction = InteractionConfig(
      touch: const TouchInteractionConfig(
        profile: TouchInteractionProfile.explore,
      ),
      onViewportChanged: changed,
    );
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: BravenChartPlus(
            series: [
              CandlestickChartSeries(
                id: 'price',
                name: 'Price',
                points: points,
              ),
            ],
            xAxisConfig: XAxisConfig(
              min: -0.5,
              max: 399.5,
              categoryAxis: categories,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.right,
              min: yMin,
              max: yMax,
            ),
            interactionConfig: interaction,
            interactionGroupController: widget.group,
          ),
        ),
        Expanded(
          flex: 3,
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'osc',
                points: [for (final p in points) ChartDataPoint(x: p.x, y: 50)],
              ),
            ],
            xAxisConfig: XAxisConfig(
              min: -0.5,
              max: 399.5,
              showTickLabels: false,
              categoryAxis: categories,
            ),
            yAxis: YAxisConfig(position: YAxisPosition.right, min: 0, max: 100),
            interactionConfig: interaction,
            interactionGroupController: widget.group,
          ),
        ),
      ],
    );
  }
}
