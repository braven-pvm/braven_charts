import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MultiAxisCrosshairLabelsDemo());

class MultiAxisCrosshairLabelsDemo extends StatelessWidget {
  const MultiAxisCrosshairLabelsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-axis crosshair labels',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: const MultiAxisCrosshairLabelsPage(),
    );
  }
}

class MultiAxisCrosshairLabelsPage extends StatelessWidget {
  const MultiAxisCrosshairLabelsPage({super.key});

  static const _power = <double>[162, 177, 151, 188, 173, 196, 184, 205, 192];
  static const _heartRate = <double>[
    122,
    128,
    133,
    127,
    141,
    146,
    139,
    153,
    148,
  ];
  static const _cadence = <double>[74, 78, 81, 77, 84, 88, 85, 91, 89];

  List<ChartDataPoint> _points(List<double> values) => [
    for (var index = 0; index < values.length; index++)
      ChartDataPoint(x: index.toDouble(), y: values[index]),
  ];

  List<ChartSeries> _series({required bool stackOnLeft}) => [
    LineChartSeries(
      id: '${stackOnLeft ? 'left' : 'right'}_power',
      name: 'Power',
      points: _points(_power),
      color: const Color(0xFFF97316),
      unit: 'W',
      strokeWidth: 2.5,
      interpolation: LineInterpolation.monotone,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        color: const Color(0xFFF97316),
        label: 'Power',
        unit: 'W',
        min: 140,
        max: 220,
      ),
    ),
    LineChartSeries(
      id: '${stackOnLeft ? 'left' : 'right'}_cadence',
      name: 'Cadence',
      points: _points(_cadence),
      color: const Color(0xFF0F9488),
      unit: 'rpm',
      strokeWidth: 2.5,
      interpolation: LineInterpolation.monotone,
      yAxisConfig: YAxisConfig(
        position: stackOnLeft ? YAxisPosition.left : YAxisPosition.right,
        color: const Color(0xFF0F9488),
        label: 'Cadence',
        unit: 'rpm',
        min: 65,
        max: 100,
      ),
    ),
    LineChartSeries(
      id: '${stackOnLeft ? 'left' : 'right'}_heart_rate',
      name: 'Heart rate',
      points: _points(_heartRate),
      color: const Color(0xFFDC2626),
      unit: 'bpm',
      strokeWidth: 2.5,
      interpolation: LineInterpolation.monotone,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.right,
        color: const Color(0xFFDC2626),
        label: 'Heart rate',
        unit: 'bpm',
        min: 110,
        max: 170,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-axis crosshair labels',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hover each chart. Every coloured value label should sit '
                    'over its matching Y-axis strip without overlap.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ScenarioCard(
                    title: 'Two axes on the left',
                    subtitle:
                        'Power and cadence labels separate on the left; heart rate stays on the right.',
                    series: _series(stackOnLeft: true),
                  ),
                  const SizedBox(height: 24),
                  _ScenarioCard(
                    title: 'Two axes on the right',
                    subtitle:
                        'Cadence and heart-rate labels separate on the right; power stays on the left.',
                    series: _series(stackOnLeft: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.title,
    required this.subtitle,
    required this.series,
  });

  final String title;
  final String subtitle;
  final List<ChartSeries> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: BravenChartPlus(
                series: series,
                normalizationMode: NormalizationMode.perSeries,
                xAxisConfig: const XAxisConfig(
                  label: 'Session',
                  min: -0.25,
                  max: 8.25,
                  tickCount: 9,
                ),
                grid: const GridConfig(horizontal: true, vertical: false),
                showLegend: true,
                legendStyle: const LegendStyle(
                  position: LegendPosition.topRight,
                  orientation: LegendOrientation.vertical,
                  allowDragging: false,
                ),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    displayMode: CrosshairDisplayMode.standard,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
