import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ThresholdAxisBoundsDemo());

class ThresholdAxisBoundsDemo extends StatelessWidget {
  const ThresholdAxisBoundsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Threshold axis-bound regression',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: const ThresholdAxisBoundsPage(),
    );
  }
}

class ThresholdAxisBoundsPage extends StatefulWidget {
  const ThresholdAxisBoundsPage({super.key});

  @override
  State<ThresholdAxisBoundsPage> createState() =>
      _ThresholdAxisBoundsPageState();
}

class _ThresholdAxisBoundsPageState extends State<ThresholdAxisBoundsPage> {
  static const _heartRateThreshold = 147.0;
  static const _heartRateAxisMin = 105.0;
  static const _heartRateAxisMax = 160.0;

  static const _dates = <String>[
    '21 Jun',
    '23 Jun',
    '25 Jun',
    '27 Jun',
    '29 Jun',
    '1 Jul',
    '3 Jul',
    '5 Jul',
    '6 Jul',
  ];

  static const _power = <double>[211, 167, 195, 171, 211, 172, 206, 236, 126];
  static const _heartRate = <double>[
    136,
    118,
    132,
    119,
    136,
    113,
    133,
    135,
    106,
  ];
  static const _compressedHeartRate = <double>[
    124,
    121,
    126,
    122,
    128,
    123,
    127,
    125,
    120,
  ];
  static const _cadence = <double>[76, 70, 81, 74, 77, 73, 80, 75, 71];

  bool _compressSamples = false;

  List<ChartDataPoint> _points(List<double> values) => [
    for (var index = 0; index < values.length; index++)
      ChartDataPoint(x: index.toDouble(), y: values[index]),
  ];

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
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Threshold axis-bound regression',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The HR LT1 value is 147 bpm. Its red line must use the '
                    'displayed HR axis, not the raw HR sample range.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _FactCard(
                        label: 'LT1 threshold',
                        value: '147 bpm',
                        icon: Icons.horizontal_rule,
                        color: Color(0xFFDC2626),
                      ),
                      _FactCard(
                        label: 'Displayed HR axis',
                        value: '105–160 bpm',
                        icon: Icons.straighten,
                        color: Color(0xFFDC2626),
                      ),
                      _FactCard(
                        label: 'Expected position',
                        value: 'Just below 150',
                        icon: Icons.check_circle_outline,
                        color: Color(0xFF15803D),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      title: const Text('Compress the raw HR sample range'),
                      subtitle: const Text(
                        'The threshold line must not move because the displayed '
                        'HR axis remains fixed at 105–160 bpm.',
                      ),
                      secondary: const Icon(Icons.compress),
                      value: _compressSamples,
                      onChanged: (value) {
                        setState(() => _compressSamples = value);
                      },
                    ),
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
                            'Session averages over time',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Power, heart rate, and cadence use independent axes.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 480,
                            child: BravenChartPlus(
                              series: [
                                LineChartSeries(
                                  id: 'session_average_power',
                                  name: 'Power session average',
                                  points: _points(_power),
                                  color: const Color(0xFFF97316),
                                  unit: 'W',
                                  strokeWidth: 2.5,
                                  showDataPointMarkers: true,
                                  dataPointMarkerRadius: 4,
                                  interpolation: LineInterpolation.bezier,
                                  tension: 0.2,
                                  yAxisConfig: YAxisConfig(
                                    position: YAxisPosition.left,
                                    color: const Color(0xFFF97316),
                                    label: 'Power',
                                    unit: 'W',
                                    min: 100,
                                    max: 265,
                                    showMinorTicks: true,
                                    minorTickCount: 4,
                                  ),
                                ),
                                LineChartSeries(
                                  id: 'session_average_heart_rate',
                                  name: 'Heart rate session average',
                                  points: _points(
                                    _compressSamples
                                        ? _compressedHeartRate
                                        : _heartRate,
                                  ),
                                  color: const Color(0xFFDC2626),
                                  unit: 'bpm',
                                  strokeWidth: 2.5,
                                  showDataPointMarkers: true,
                                  dataPointMarkerRadius: 4,
                                  interpolation: LineInterpolation.bezier,
                                  tension: 0.2,
                                  yAxisConfig: YAxisConfig(
                                    position: YAxisPosition.left,
                                    color: const Color(0xFFDC2626),
                                    label: 'Heart rate',
                                    unit: 'bpm',
                                    min: _heartRateAxisMin,
                                    max: _heartRateAxisMax,
                                    showMinorTicks: true,
                                    minorTickCount: 4,
                                  ),
                                ),
                                LineChartSeries(
                                  id: 'session_average_cadence',
                                  name: 'Cadence session average',
                                  points: _points(_cadence),
                                  color: const Color(0xFF0F9488),
                                  unit: 'rpm',
                                  strokeWidth: 2.5,
                                  showDataPointMarkers: true,
                                  dataPointMarkerRadius: 4,
                                  interpolation: LineInterpolation.bezier,
                                  tension: 0.2,
                                  yAxisConfig: YAxisConfig(
                                    position: YAxisPosition.right,
                                    color: const Color(0xFF0F9488),
                                    label: 'Cadence',
                                    unit: 'rpm',
                                    min: 68,
                                    max: 85,
                                    showMinorTicks: true,
                                    minorTickCount: 4,
                                  ),
                                ),
                              ],
                              annotations: [
                                ThresholdAnnotation(
                                  id: 'heart_rate_lt1_147',
                                  axis: AnnotationAxis.y,
                                  value: _heartRateThreshold,
                                  seriesId: 'session_average_heart_rate',
                                  label: 'Heart rate LT1 · 147 bpm',
                                  lineColor: const Color(0xFFDC2626),
                                  lineWidth: 2.5,
                                  elevation: 5,
                                  labelPosition:
                                      AnnotationLabelPosition.bottomLeft,
                                  allowDragging: false,
                                  allowEditing: false,
                                ),
                              ],
                              xAxisConfig: XAxisConfig(
                                label: 'Session date',
                                min: -0.25,
                                max: (_dates.length - 1).toDouble() + 0.25,
                                tickCount: _dates.length,
                                labelFormatter: (value) {
                                  final index = value.round();
                                  if (index < 0 || index >= _dates.length) {
                                    return '';
                                  }
                                  return _dates[index];
                                },
                              ),
                              normalizationMode: NormalizationMode.perSeries,
                              grid: const GridConfig(
                                horizontal: true,
                                vertical: false,
                              ),
                              showLegend: true,
                              legendStyle: const LegendStyle(
                                position: LegendPosition.topRight,
                                orientation: LegendOrientation.vertical,
                                allowDragging: false,
                              ),
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
                        Icon(
                          Icons.fact_check_outlined,
                          color: Color(0xFF166534),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Check: the red LT1 line stays just below the 150 bpm '
                            'tick before and after toggling the HR sample range.',
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
      width: 220,
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
