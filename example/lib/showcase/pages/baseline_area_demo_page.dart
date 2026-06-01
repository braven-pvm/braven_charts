import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Demonstrates the [AreaChartSeries.baselineValue] feature.
///
/// Four charts showing:
/// 1. Two-color fill — green above threshold, red below (many crossings).
/// 2. Single-color deviation shading — both sides orange.
/// 3. Stepped interpolation — verifies crossing detection at step edges.
/// 4. Standard fill (no baseline) for comparison.
class BaselineAreaDemoPage extends StatelessWidget {
  const BaselineAreaDemoPage({super.key});

  static const double _baseline = 120.0;

  // Dense oscillating data — many crossings above/below 120 W.
  static const List<ChartDataPoint> _powerData = [
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
    ChartDataPoint(x: 13, y: 108),
    ChartDataPoint(x: 14, y: 133),
    ChartDataPoint(x: 15, y: 158),
    ChartDataPoint(x: 16, y: 142),
    ChartDataPoint(x: 17, y: 117),
    ChartDataPoint(x: 18, y: 91),
    ChartDataPoint(x: 19, y: 78),
    ChartDataPoint(x: 20, y: 102),
    ChartDataPoint(x: 21, y: 125),
    ChartDataPoint(x: 22, y: 147),
    ChartDataPoint(x: 23, y: 165),
    ChartDataPoint(x: 24, y: 135),
  ];

  // Stepped data with clear above/below blocks for stepped-interpolation demo.
  static const List<ChartDataPoint> _steppedData = [
    ChartDataPoint(x: 0, y: 90),
    ChartDataPoint(x: 2, y: 90),
    ChartDataPoint(x: 2, y: 145),
    ChartDataPoint(x: 5, y: 145),
    ChartDataPoint(x: 5, y: 105),
    ChartDataPoint(x: 7, y: 105),
    ChartDataPoint(x: 7, y: 160),
    ChartDataPoint(x: 10, y: 160),
    ChartDataPoint(x: 10, y: 80),
    ChartDataPoint(x: 12, y: 80),
    ChartDataPoint(x: 12, y: 135),
    ChartDataPoint(x: 15, y: 135),
    ChartDataPoint(x: 15, y: 95),
    ChartDataPoint(x: 17, y: 95),
    ChartDataPoint(x: 17, y: 150),
    ChartDataPoint(x: 20, y: 150),
    ChartDataPoint(x: 20, y: 110),
    ChartDataPoint(x: 24, y: 110),
  ];

  static const _xConfig = XAxisConfig(
    label: 'Time (min)',
    min: -0.5,
    max: 24.5,
  );

  static YAxisConfig get _yConfig => YAxisConfig(
        position: YAxisPosition.left,
        label: 'Power',
        unit: 'W',
        min: 60,
        max: 185,
      );

  static ThresholdAnnotation get _thresholdLine => ThresholdAnnotation(
        id: 'baseline',
        axis: AnnotationAxis.y,
        value: _baseline,
        label: '120 W',
        lineColor: Colors.orange,
        lineWidth: 1.5,
        dashPattern: const [6, 4],
        labelPosition: AnnotationLabelPosition.topRight,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header — matches ChartPageLayout style
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Baseline Area Fill',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'AreaChartSeries.baselineValue fills between the series line '
                'and a fixed Y reference — above and below regions use '
                'independent colours.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Scrollable chart list
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Chart 1: Two-color ────────────────────────────────────────
                const _SectionLabel(
                  title: 'Two-color baseline fill',
                  description:
                      'Green above 120 W, red below. The fill polygon splits '
                      'exactly at each crossing point. A dashed threshold '
                      'annotation marks the baseline.',
                ),
                const SizedBox(height: 8),
                _ChartCard(
                  child: BravenChartPlus(
                    series: const [
                      AreaChartSeries(
                        id: 'power_two_color',
                        name: 'Power',
                        points: _powerData,
                        color: Color(0xFF4CAF50),
                        strokeWidth: 1.5,
                        baselineValue: _baseline,
                        aboveBaselineFillColor: Color.fromRGBO(76, 175, 80, 0.40),
                        belowBaselineFillColor: Color.fromRGBO(244, 67, 54, 0.35),
                      ),
                    ],
                    annotations: [_thresholdLine],
                    xAxisConfig: _xConfig,
                    yAxis: _yConfig,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Chart 2: Single-color ─────────────────────────────────────
                const _SectionLabel(
                  title: 'Single-color deviation shading',
                  description:
                      'Same baseline, both sides shaded orange. '
                      'Use this to highlight any deviation from a target '
                      'without implying good/bad directionality.',
                ),
                const SizedBox(height: 8),
                _ChartCard(
                  child: BravenChartPlus(
                    series: const [
                      AreaChartSeries(
                        id: 'power_single_color',
                        name: 'Power',
                        points: _powerData,
                        color: Color(0xFFFF9800),
                        strokeWidth: 1.5,
                        baselineValue: _baseline,
                        aboveBaselineFillColor: Color.fromRGBO(255, 152, 0, 0.35),
                        belowBaselineFillColor: Color.fromRGBO(255, 152, 0, 0.35),
                      ),
                    ],
                    annotations: [_thresholdLine],
                    xAxisConfig: _xConfig,
                    yAxis: _yConfig,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Chart 3: Stepped interpolation ────────────────────────────
                const _SectionLabel(
                  title: 'Stepped interpolation',
                  description:
                      'Crossing detection places the split at the step edge '
                      '(vertical transition at x = next point) rather than '
                      'the linear midpoint — fills align cleanly with step edges.',
                ),
                const SizedBox(height: 8),
                _ChartCard(
                  child: BravenChartPlus(
                    series: const [
                      AreaChartSeries(
                        id: 'power_stepped',
                        name: 'Power',
                        points: _steppedData,
                        interpolation: LineInterpolation.stepped,
                        color: Color(0xFF7C4DFF),
                        strokeWidth: 1.5,
                        baselineValue: _baseline,
                        aboveBaselineFillColor: Color.fromRGBO(124, 77, 255, 0.40),
                        belowBaselineFillColor: Color.fromRGBO(244, 67, 54, 0.30),
                      ),
                    ],
                    annotations: [_thresholdLine],
                    xAxisConfig: _xConfig,
                    yAxis: _yConfig,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Chart 4: Monotone interpolation ───────────────────────────
                const _SectionLabel(
                  title: 'Monotone interpolation',
                  description:
                      'Smooth curves with baseline fill. The crossing is '
                      'detected via linear interpolation between data points — '
                      'works well for smooth data where the curve closely '
                      'tracks the underlying points.',
                ),
                const SizedBox(height: 8),
                _ChartCard(
                  child: BravenChartPlus(
                    series: const [
                      AreaChartSeries(
                        id: 'power_monotone',
                        name: 'Power',
                        points: _powerData,
                        interpolation: LineInterpolation.monotone,
                        color: Color(0xFF00BCD4),
                        strokeWidth: 1.5,
                        baselineValue: _baseline,
                        aboveBaselineFillColor: Color.fromRGBO(0, 188, 212, 0.40),
                        belowBaselineFillColor: Color.fromRGBO(244, 67, 54, 0.30),
                      ),
                    ],
                    annotations: [_thresholdLine],
                    xAxisConfig: _xConfig,
                    yAxis: _yConfig,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Chart 5: Standard fill (comparison) ───────────────────────
                const _SectionLabel(
                  title: 'Standard fill (no baseline)',
                  description:
                      'No baselineValue set — original fill-to-bottom '
                      'behaviour. Shown for comparison.',
                ),
                const SizedBox(height: 8),
                _ChartCard(
                  child: BravenChartPlus(
                    series: const [
                      AreaChartSeries(
                        id: 'power_standard',
                        name: 'Power',
                        points: _powerData,
                        color: Color(0xFF5C6BC0),
                        strokeWidth: 1.5,
                        fillOpacity: 0.25,
                      ),
                    ],
                    xAxisConfig: _xConfig,
                    yAxis: _yConfig,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
