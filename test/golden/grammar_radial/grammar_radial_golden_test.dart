import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.025;

class Fruit {
  const Fruit({required this.name, required this.count, this.basket = ''});
  final String name;
  final double count;
  final String basket;
}

Object fruitName(Fruit row) => row.name;
double fruitCount(Fruit row) => row.count;
Object fruitBasket(Fruit row) => row.basket;

const _fruits = <Fruit>[
  Fruit(name: 'Apple', count: 42, basket: 'Winter'),
  Fruit(name: 'Pear', count: 31, basket: 'Winter'),
  Fruit(name: 'Plum', count: 17, basket: 'Summer'),
  Fruit(name: 'Fig', count: 10, basket: 'Summer'),
];

ChartTheme _goldenTheme() {
  final source = ChartTheme.light;
  return source.copyWith(
    typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
    animationTheme: source.animationTheme.copyWith(
      dataUpdateDuration: Duration.zero,
      themeChangeDuration: Duration.zero,
      interactionDuration: Duration.zero,
    ),
    pieChartTheme: const PieChartTheme(animationMode: PieAnimationMode.none),
  );
}

Future<void> _pump(WidgetTester tester, Widget chart, Size size) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Ahem'),
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('grammar-radial-surface'),
            child: ColoredBox(
              color: ChartTheme.light.backgroundColor,
              child: SizedBox.fromSize(size: size, child: chart),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _expectGolden(WidgetTester tester, String path) => expectLater(
  find.byKey(const ValueKey('grammar-radial-surface')),
  matchesGoldenFile(path),
);

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('grammar_radial_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('grammar-authored pie', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomPie(
          category: fruitName,
          value: fruitCount,
          style: const PieChartStyle(animationMode: PieAnimationMode.none),
        )
        .title('Harvest share')
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 380));
    await _expectGolden(tester, 'goldens/grammar_pie.png');
  });

  testWidgets('grammar-authored donut', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomDonut(
          category: fruitName,
          value: fruitCount,
          center: const DonutCenterContent(label: 'Total'),
          style: const DonutChartStyle(animationMode: PieAnimationMode.none),
        )
        .title('Harvest share')
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 380));
    await _expectGolden(tester, 'goldens/grammar_donut.png');
  });

  testWidgets('grammar-authored concentric donut', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomDonut(
          category: fruitName,
          value: fruitCount,
          ring: fruitBasket,
          style: const DonutChartStyle(animationMode: PieAnimationMode.none),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        )
        .title('Harvest by season')
        .legend(true)
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 460));
    await _expectGolden(tester, 'goldens/grammar_concentric.png');
  });
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : precisionTolerance = precisionTolerance;

  double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
