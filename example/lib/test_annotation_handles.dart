import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Annotation Handles Test',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Annotation Handles Test - Hover to See Clean Handles')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: BravenChart(
            chartType: ChartType.line,
            series: [
              ChartSeries(
                id: 'test',
                points: List.generate(
                  10,
                  (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
                ),
                color: Colors.blue,
                annotations: [
                  RangeAnnotation(
                    id: 'test_range_x',
                    label: 'X Range',
                    startX: 3,
                    endX: 7,
                    fillColor: Colors.blue.withValues(alpha: 0.2),
                    borderColor: Colors.blue,
                    snapToValue: true,
                    snapIncrement: 1.0,
                  ),
                  RangeAnnotation(
                    id: 'test_range_y',
                    label: 'Y Range',
                    startY: 6,
                    endY: 14,
                    fillColor: Colors.green.withValues(alpha: 0.2),
                    borderColor: Colors.green,
                    snapToValue: true,
                    snapIncrement: 2.0,
                  ),
                ],
              ),
            ],
            width: 800,
            height: 400,
            interactiveAnnotations: true,
            interactionConfig: InteractionConfig(
              enablePan: true,
              en
            ),
          ),
        ),
      ),
    );
  }
}
