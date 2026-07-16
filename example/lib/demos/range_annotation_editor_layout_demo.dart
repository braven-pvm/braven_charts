// ignore_for_file: implementation_imports

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/widgets/dialogs/chord_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/pin_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/point_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/range_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/text_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/threshold_annotation_dialog.dart';
import 'package:braven_charts/src/widgets/dialogs/trend_annotation_dialog.dart';
import 'package:flutter/material.dart';

void main() => runApp(const RangeAnnotationEditorLayoutDemo());

class RangeAnnotationEditorLayoutDemo extends StatelessWidget {
  const RangeAnnotationEditorLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Range annotation editor prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        useMaterial3: true,
      ),
      home: const RangeAnnotationEditorLayoutPage(),
    );
  }
}

class RangeAnnotationEditorLayoutPage extends StatefulWidget {
  const RangeAnnotationEditorLayoutPage({super.key});

  @override
  State<RangeAnnotationEditorLayoutPage> createState() =>
      _RangeAnnotationEditorLayoutPageState();
}

class _RangeAnnotationEditorLayoutPageState
    extends State<RangeAnnotationEditorLayoutPage> {
  static const _series = LineChartSeries(
    id: 'power',
    name: 'Power',
    color: Color(0xFF2563EB),
    unit: 'W',
    strokeWidth: 2.5,
    interpolation: LineInterpolation.monotone,
    points: [
      ChartDataPoint(x: 0, y: 168),
      ChartDataPoint(x: 1, y: 174),
      ChartDataPoint(x: 2, y: 171),
      ChartDataPoint(x: 3, y: 186),
      ChartDataPoint(x: 4, y: 191),
      ChartDataPoint(x: 5, y: 184),
      ChartDataPoint(x: 6, y: 198),
      ChartDataPoint(x: 7, y: 202),
      ChartDataPoint(x: 8, y: 194),
      ChartDataPoint(x: 9, y: 208),
    ],
  );

  late RangeAnnotation _range;
  bool _openedInitialEditor = false;

  @override
  void initState() {
    super.initState();
    _range = RangeAnnotation(
      id: 'analysis-window',
      label: 'Analysis window',
      startX: 2,
      endX: 7,
      fillColor: const Color(0x334F46E5),
      borderColor: const Color(0xFF4F46E5),
      labelPosition: AnnotationLabelPosition.centerRight,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_openedInitialEditor) return;
    _openedInitialEditor = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
  }

  Future<void> _openEditor() async {
    final updated = await showDialog<RangeAnnotation>(
      context: context,
      builder: (context) => RangeAnnotationDialog(
        annotation: _range,
        availableSeries: const [_series],
      ),
    );
    if (updated != null && mounted) {
      setState(() => _range = updated);
    }
  }

  Future<void> _showEditor(Widget dialog) {
    return showDialog<void>(context: context, builder: (context) => dialog);
  }

  Widget _editorButton(String label, Widget dialog) {
    return OutlinedButton(
      onPressed: () => _showEditor(dialog),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annotation editor modal review',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open any native editor to compare its sticky header, '
                    'actions, scrolling, and shared controls.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _editorButton(
                        'Point',
                        const PointAnnotationDialog(
                          seriesId: 'power',
                          dataPointIndex: 2,
                        ),
                      ),
                      _editorButton(
                        'Pin',
                        const PinAnnotationDialog(initialX: 4, initialY: 180),
                      ),
                      _editorButton(
                        'Text',
                        const TextAnnotationDialog(clickPosition: Offset.zero),
                      ),
                      _editorButton(
                        'Threshold',
                        const ThresholdAnnotationDialog(
                          initialYValue: 190,
                          availableSeries: [_series],
                        ),
                      ),
                      _editorButton(
                        'Trend',
                        const TrendAnnotationDialog(availableSeries: ['power']),
                      ),
                      _editorButton(
                        'Chord',
                        const ChordAnnotationDialog(availableSeries: [_series]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Power session',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Current label anchor: '
                                        '${_range.labelPosition.name}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: _openEditor,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit range'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: BravenChartPlus(
                                series: const [_series],
                                annotations: [_range],
                                interactiveAnnotations: true,
                                xAxisConfig: const XAxisConfig(
                                  label: 'Session elapsed time',
                                  min: 0,
                                  max: 9,
                                  tickCount: 10,
                                ),
                                yAxis: YAxisConfig(
                                  position: YAxisPosition.left,
                                  label: 'Power',
                                  unit: 'W',
                                  min: 150,
                                  max: 220,
                                  color: const Color(0xFF2563EB),
                                ),
                                grid: const GridConfig(
                                  horizontal: true,
                                  vertical: false,
                                ),
                                showLegend: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
