import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _wideSize = Size(1100, 620);
const _compactSize = Size(520, 700);
const _pixelTolerance = 0.025;

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('chart_workbench_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  for (final mode in ChartDisplayMode.values) {
    testWidgets('workbench ${mode.name} wide golden', (tester) async {
      final workbenchController = ChartWorkbenchController();
      addTearDown(workbenchController.dispose);
      await _pumpSurface(
        tester,
        _host(
          size: _wideSize,
          workbenchController: workbenchController,
          initialMode: mode,
        ),
        settle: mode != ChartDisplayMode.chart,
      );

      await _expectGolden(tester, 'goldens/workbench_wide_${mode.name}.png');
    });
  }

  testWidgets('workbench compact split golden', (tester) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);
    await _pumpSurface(
      tester,
      _host(
        size: _compactSize,
        workbenchController: workbenchController,
        initialMode: ChartDisplayMode.split,
        splitBreakpoint: 700,
      ),
      settle: true,
    );

    await _expectGolden(tester, 'goldens/workbench_compact_split.png');
  });

  testWidgets('workbench initial loading golden', (tester) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);
    await _pumpSurface(
      tester,
      _host(
        size: _wideSize,
        workbenchController: workbenchController,
        initialMode: ChartDisplayMode.data,
      ),
      settle: false,
    );

    await _expectGolden(tester, 'goldens/workbench_loading.png');
    await tester.pumpAndSettle();
  });

  testWidgets('workbench recoverable failure golden', (tester) async {
    final chartController = _GoldenExtractionController(failNext: true);
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);
    await _pumpSurface(
      tester,
      _host(
        size: _wideSize,
        chartController: chartController,
        workbenchController: workbenchController,
        initialMode: ChartDisplayMode.data,
      ),
      settle: true,
    );

    await _expectGolden(tester, 'goldens/workbench_failure.png');
  });

  testWidgets('workbench warning golden', (tester) async {
    final chartController = _GoldenExtractionController(warnNext: true);
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);
    await _pumpSurface(
      tester,
      _host(
        size: _wideSize,
        chartController: chartController,
        workbenchController: workbenchController,
        initialMode: ChartDisplayMode.data,
      ),
      settle: true,
    );

    await _expectGolden(tester, 'goldens/workbench_warning.png');
  });

  testWidgets('workbench stale table golden', (tester) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);
    await _pumpSurface(
      tester,
      _host(
        size: _wideSize,
        chartController: chartController,
        workbenchController: workbenchController,
        initialMode: ChartDisplayMode.data,
        refreshPolicy: ChartTableRefreshPolicy.manual,
        chartValue: 10,
      ),
      settle: true,
    );
    await tester.pumpWidget(
      _host(
        size: _wideSize,
        chartController: chartController,
        workbenchController: workbenchController,
        initialMode: ChartDisplayMode.data,
        refreshPolicy: ChartTableRefreshPolicy.manual,
        chartValue: 42,
      ),
    );
    await tester.pump();

    await _expectGolden(tester, 'goldens/workbench_stale.png');
  });

  testWidgets('workbench large text high contrast focus golden', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);
    await _pumpSurface(
      tester,
      _host(
        size: _wideSize,
        workbenchController: workbenchController,
        textScaler: const TextScaler.linear(1.6),
        highContrast: true,
      ),
      settle: true,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    await _expectGolden(
      tester,
      'goldens/workbench_high_contrast_large_text_focus.png',
    );
  });
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget host, {
  required bool settle,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(host);
  if (settle) await tester.pumpAndSettle();
}

Future<void> _expectGolden(WidgetTester tester, String path) => expectLater(
  find.byKey(const ValueKey('workbench-golden-surface')),
  matchesGoldenFile(path),
);

Widget _host({
  required Size size,
  required ChartWorkbenchController workbenchController,
  BravenChartController? chartController,
  ChartDisplayMode initialMode = ChartDisplayMode.chart,
  ChartTableRefreshPolicy refreshPolicy = ChartTableRefreshPolicy.onModeEntry,
  double splitBreakpoint = 700,
  double chartValue = 10,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
}) {
  final scheme = highContrast
      ? const ColorScheme.highContrastLight()
      : ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5));
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: scheme,
      fontFamily: 'Ahem',
      useMaterial3: true,
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, highContrast: highContrast),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: const ValueKey('workbench-golden-surface'),
          child: ColoredBox(
            color: scheme.surface,
            child: SizedBox.fromSize(
              size: size,
              child: BravenChartWorkbench(
                chartController: chartController,
                workbenchController: workbenchController,
                initialDisplayMode: initialMode,
                splitBreakpoint: splitBreakpoint,
                tableRefreshPolicy: refreshPolicy,
                chartBuilder: (context, controller) => BravenChartPlus(
                  bravenChartController: controller,
                  showLegend: false,
                  theme: ChartTheme.light.copyWith(
                    typographyTheme: ChartTheme.light.typographyTheme.copyWith(
                      fontFamily: 'Ahem',
                    ),
                    animationTheme: ChartTheme.light.animationTheme.copyWith(
                      dataUpdateDuration: Duration.zero,
                      themeChangeDuration: Duration.zero,
                      interactionDuration: Duration.zero,
                    ),
                  ),
                  xAxisConfig: const XAxisConfig(label: 'Sample'),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Value',
                  ),
                  series: [
                    LineChartSeries(
                      id: 'signal',
                      name: 'Signal',
                      points: [
                        ChartDataPoint(x: 0, y: chartValue),
                        ChartDataPoint(x: 1, y: chartValue + 2),
                        ChartDataPoint(x: 2, y: chartValue + 1),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _GoldenExtractionController extends BravenChartController {
  _GoldenExtractionController({this.failNext = false, this.warnNext = false});

  bool failNext;
  bool warnNext;

  @override
  ChartArtifactResult<ChartDocumentSnapshot> extractDocument([
    ChartDocumentExtractOptions options = const ChartDocumentExtractOptions(),
  ]) {
    if (failNext) {
      failNext = false;
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.tableProjectionFailed,
          message: 'The chart data could not be prepared. Retry the table.',
        ),
      );
    }
    final result = super.extractDocument(options);
    if (!warnNext) return result;
    warnNext = false;
    return switch (result) {
      ChartArtifactSuccess<ChartDocumentSnapshot>() => ChartArtifactSuccess(
        value: result.value,
        warnings: const [
          ChartArtifactWarning(
            code: 'golden_demo_warning',
            message: 'Some values use a safe display fallback.',
          ),
        ],
      ),
      ChartArtifactFailure<ChartDocumentSnapshot>() => result,
    };
  }
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
