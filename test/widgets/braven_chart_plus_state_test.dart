import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildChart({
    List<ChartSeries> series = const <ChartSeries>[],
    bool isLoading = false,
    ChartLoadingConfig loadingConfig = const ChartLoadingConfig.skeleton(),
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
    Widget? loadingWidget,
    String? title,
    LiveStreamController? liveStreamController,
    bool disableAnimations = false,
    ChartTheme? theme,
    double chartHeight = 420,
  }) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: SizedBox(
          width: 640,
          height: chartHeight,
          child: BravenChartPlus(
            series: series,
            isLoading: isLoading,
            loadingConfig: loadingConfig,
            emptyStateConfig: emptyStateConfig,
            loadingWidget: loadingWidget,
            title: title,
            liveStreamController: liveStreamController,
            theme: theme,
            showLegend: false,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the skeleton loading state when isLoading is true', (
    tester,
  ) async {
    await tester.pumpWidget(buildChart(isLoading: true));

    expect(
      find.byKey(const ValueKey<String>('braven_chart_loading_state')),
      findsOneWidget,
    );
    expect(find.text('Loading chart data'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('skeleton becomes static when reduced motion is requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildChart(isLoading: true, disableAnimations: true),
    );
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('skeleton accepts chart theme and per-loader styling', (
    tester,
  ) async {
    const style = ChartLoadingSkeletonStyle(
      seriesColor: Colors.deepPurple,
      secondarySeriesColor: Colors.pink,
      gridColor: Colors.blueGrey,
      animationDuration: Duration(milliseconds: 1800),
      maxWidth: 480,
      widthFactor: 0.7,
      aspectRatio: 2,
      motionIntensity: 0.6,
      showSecondaryTrace: false,
      showGrid: true,
      edgeFadeFraction: 0.18,
    );

    await tester.pumpWidget(
      buildChart(
        isLoading: true,
        theme: ChartTheme.vibrant,
        loadingConfig: const ChartLoadingConfig.skeleton(skeletonStyle: style),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('braven_chart_loading_state')),
      findsOneWidget,
    );
    expect(style.seriesColor, Colors.deepPurple);
    expect(style.motionIntensity, 0.6);
    expect(style.showGrid, isTrue);
    expect(style.edgeFadeFraction, 0.18);
  });

  testWidgets('skeleton and message fit a short chart viewport', (
    tester,
  ) async {
    await tester.pumpWidget(buildChart(isLoading: true, chartHeight: 220));

    expect(find.text('Loading chart data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports circular and determinate loading progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildChart(
        isLoading: true,
        loadingConfig: const ChartLoadingConfig.circular(progress: 0.4),
      ),
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, 0.4);
  });

  testWidgets('supports linear loading progress', (tester) async {
    await tester.pumpWidget(
      buildChart(
        isLoading: true,
        loadingConfig: const ChartLoadingConfig.linear(progress: 0.75),
      ),
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.75);
  });

  testWidgets('existing loadingWidget overrides the configured indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildChart(
        isLoading: true,
        loadingConfig: const ChartLoadingConfig.circular(),
        loadingWidget: const Text('Preparing athlete data'),
      ),
    );

    expect(find.text('Preparing athlete data'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('custom loading builder replaces the built-in presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildChart(
        isLoading: true,
        loadingConfig: ChartLoadingConfig.circular(
          customBuilder: (_) => const Text('Checking the data source'),
        ),
      ),
    );

    expect(find.text('Checking the data source'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a configurable empty state after loading', (tester) async {
    await tester.pumpWidget(
      buildChart(
        emptyStateConfig: const ChartEmptyStateConfig(
          title: 'No samples yet',
          message: 'Import a session to populate this chart.',
          icon: Icons.upload_file_outlined,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('braven_chart_empty_state')),
      findsOneWidget,
    );
    expect(find.text('No samples yet'), findsOneWidget);
    expect(
      find.text('Import a session to populate this chart.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.upload_file_outlined), findsOneWidget);
  });

  testWidgets('loading takes precedence over the empty state', (tester) async {
    await tester.pumpWidget(buildChart(isLoading: true));

    expect(
      find.byKey(const ValueKey<String>('braven_chart_loading_state')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('braven_chart_empty_state')),
      findsNothing,
    );
  });

  testWidgets('custom empty builder replaces the default presentation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildChart(
        emptyStateConfig: ChartEmptyStateConfig(
          customBuilder: (_) => ElevatedButton(
            onPressed: () {},
            child: const Text('Choose another date range'),
          ),
        ),
      ),
    );

    expect(find.text('Choose another date range'), findsOneWidget);
    expect(find.bySemanticsLabel('Choose another date range'), findsOneWidget);
    expect(find.text('No data to display'), findsNothing);
    semantics.dispose();
  });

  testWidgets('loading state exposes a live semantic announcement', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildChart(
        isLoading: true,
        loadingConfig: const ChartLoadingConfig.linear(
          semanticLabel: 'Loading power samples',
        ),
      ),
    );

    expect(find.bySemanticsLabel('Loading power samples'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('data renders the chart instead of the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildChart(
        series: const <ChartSeries>[
          LineChartSeries(
            id: 'power',
            points: <ChartDataPoint>[
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 120),
            ],
          ),
        ],
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('braven_chart_empty_state')),
      findsNothing,
    );
  });

  testWidgets('live streaming keeps the empty render viewport mounted', (
    tester,
  ) async {
    final controller = LiveStreamController(seriesId: 'power');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildChart(
        series: const <ChartSeries>[
          LineChartSeries(id: 'power', points: <ChartDataPoint>[]),
        ],
        liveStreamController: controller,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('braven_chart_empty_state')),
      findsNothing,
    );
  });

  testWidgets('title remains visible while loading', (tester) async {
    await tester.pumpWidget(
      buildChart(isLoading: true, title: 'Power profile'),
    );

    expect(find.text('Power profile'), findsOneWidget);
    expect(find.text('Loading chart data'), findsOneWidget);
  });

  test('loading progress must be between zero and one', () {
    expect(
      () => ChartLoadingConfig.circular(progress: 1.1),
      throwsAssertionError,
    );
  });

  test('skeleton edge fade must stay within the supported range', () {
    expect(const ChartLoadingSkeletonStyle().showGrid, isFalse);
    expect(
      () => ChartLoadingSkeletonStyle(edgeFadeFraction: 0.5),
      throwsAssertionError,
    );
  });
}
