import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BaselineFillAlignmentDemo());

class BaselineFillAlignmentDemo extends StatelessWidget {
  const BaselineFillAlignmentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baseline fill alignment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891B2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: const BaselineFillAlignmentPage(),
    );
  }
}

class BaselineFillAlignmentPage extends StatefulWidget {
  const BaselineFillAlignmentPage({super.key});

  @override
  State<BaselineFillAlignmentPage> createState() =>
      _BaselineFillAlignmentPageState();
}

class _BaselineFillAlignmentPageState extends State<BaselineFillAlignmentPage> {
  static const _baseline = 120.0;
  static const _points = <ChartDataPoint>[
    ChartDataPoint(x: 0, y: 105),
    ChartDataPoint(x: 1, y: 138),
    ChartDataPoint(x: 2, y: 155),
    ChartDataPoint(x: 3, y: 148),
    ChartDataPoint(x: 4, y: 112),
    ChartDataPoint(x: 5, y: 88),
    ChartDataPoint(x: 6, y: 75),
    ChartDataPoint(x: 7, y: 118),
    ChartDataPoint(x: 8, y: 145),
    ChartDataPoint(x: 9, y: 162),
    ChartDataPoint(x: 10, y: 130),
    ChartDataPoint(x: 11, y: 95),
    ChartDataPoint(x: 12, y: 82),
  ];

  LineInterpolation _interpolation = LineInterpolation.monotone;

  String get _interpolationLabel => switch (_interpolation) {
    LineInterpolation.monotone => 'Monotone',
    LineInterpolation.bezier => 'Bezier',
    _ => 'Curved',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                    'Baseline fill alignment',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The fill boundary must follow the exact rendered curve '
                    'through every 120 W crossing.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _FactCard(
                        label: 'Interpolation',
                        value: _interpolationLabel,
                        icon: Icons.gesture,
                        color: const Color(0xFF0891B2),
                      ),
                      const _FactCard(
                        label: 'Baseline',
                        value: '120 W',
                        icon: Icons.horizontal_rule,
                        color: Color(0xFFEA580C),
                      ),
                      const _FactCard(
                        label: 'Expected result',
                        value: 'No gaps or halos',
                        icon: Icons.check_circle_outline,
                        color: Color(0xFF15803D),
                      ),
                      _ControlGroup(
                        label: 'Curve type',
                        child: SegmentedButton<LineInterpolation>(
                          segments: const [
                            ButtonSegment(
                              value: LineInterpolation.monotone,
                              icon: Icon(Icons.show_chart),
                              label: Text('Monotone'),
                            ),
                            ButtonSegment(
                              value: LineInterpolation.bezier,
                              icon: Icon(Icons.gesture),
                              label: Text('Bezier'),
                            ),
                          ],
                          selected: {_interpolation},
                          onSelectionChanged: (selection) {
                            setState(() => _interpolation = selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Power relative to baseline',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cyan fills above 120 W; red fills below it.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 520,
                            child: BravenChartPlus(
                              series: [
                                AreaChartSeries(
                                  id: 'baseline_alignment',
                                  name: 'Power',
                                  points: _points,
                                  interpolation: _interpolation,
                                  tension: 0.25,
                                  color: const Color(0xFF0891B2),
                                  strokeWidth: 2.5,
                                  baselineValue: _baseline,
                                  aboveBaselineFillColor: const Color.fromRGBO(
                                    6,
                                    182,
                                    212,
                                    0.38,
                                  ),
                                  belowBaselineFillColor: const Color.fromRGBO(
                                    239,
                                    68,
                                    68,
                                    0.30,
                                  ),
                                ),
                              ],
                              annotations: [
                                ThresholdAnnotation(
                                  id: 'baseline_120',
                                  axis: AnnotationAxis.y,
                                  value: _baseline,
                                  label: 'Baseline · 120 W',
                                  lineColor: const Color(0xFFEA580C),
                                  lineWidth: 2,
                                  dashPattern: const [7, 5],
                                  labelPosition:
                                      AnnotationLabelPosition.topRight,
                                  allowDragging: false,
                                  allowEditing: false,
                                ),
                              ],
                              xAxisConfig: const XAxisConfig(
                                label: 'Sample',
                                min: -0.25,
                                max: 12.25,
                                tickCount: 7,
                              ),
                              yAxis: YAxisConfig(
                                position: YAxisPosition.left,
                                label: 'Power',
                                unit: 'W',
                                min: 60,
                                max: 180,
                                color: const Color(0xFF0891B2),
                                showMinorTicks: true,
                                minorTickCount: 1,
                              ),
                              grid: const GridConfig(
                                horizontal: true,
                                vertical: true,
                              ),
                              showLegend: false,
                              interactionConfig: const InteractionConfig(
                                crosshair: CrosshairConfig(
                                  enabled: true,
                                  displayMode: CrosshairDisplayMode.tracking,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF3),
                      border: Border.all(color: const Color(0xFF86C99A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.zoom_in, color: Color(0xFF166534)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Check every baseline crossing: the coloured fill '
                            'must meet the cyan stroke with no wedge, gap, or '
                            'straight-line edge.',
                            style: TextStyle(
                              color: Color(0xFF14532D),
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 208,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
