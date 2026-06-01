// Copyright 2025 Braven Charts - Baseline Area Fill Demo Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Demonstrates the baseline area fill feature of [AreaChartSeries].
///
/// Three charts are shown:
/// 1. Two-color baseline fill — green above threshold, red below.
/// 2. Single-color deviation shading — orange on both sides.
/// 3. Standard fill (no baseline) for comparison.
class BaselineAreaDemoPage extends StatelessWidget {
  const BaselineAreaDemoPage({super.key});

  static const double _baseline = 120.0;

  static const List<ChartDataPoint> _points = [
    ChartDataPoint(x: 0, y: 80),
    ChartDataPoint(x: 1, y: 140),
    ChartDataPoint(x: 2, y: 155),
    ChartDataPoint(x: 3, y: 110),
    ChartDataPoint(x: 4, y: 95),
    ChartDataPoint(x: 5, y: 130),
    ChartDataPoint(x: 6, y: 160),
    ChartDataPoint(x: 7, y: 105),
    ChartDataPoint(x: 8, y: 85),
    ChartDataPoint(x: 9, y: 145),
    ChartDataPoint(x: 10, y: 125),
    ChartDataPoint(x: 11, y: 90),
    ChartDataPoint(x: 12, y: 115),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baseline Area Fill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Chart 1: Two-color baseline fill ────────────────────────────
            const _SectionLabel(
              title: 'Baseline Fill — Two Colors',
              description:
                  'Green = above 120 W threshold, Red = below. '
                  'A ThresholdAnnotation marks the baseline at y = 120.',
            ),
            const SizedBox(height: 8),
            _ChartContainer(
              child: BravenChartPlus(
                series: const [
                  AreaChartSeries(
                    id: 'power_two_color',
                    name: 'Power',
                    points: _points,
                    color: Color(0xFF4CAF50),
                    strokeWidth: 2.0,
                    fillOpacity: 0.35,
                    baselineValue: _baseline,
                    aboveBaselineFillColor: Color.fromRGBO(76, 175, 80, 0.35),
                    belowBaselineFillColor: Color.fromRGBO(244, 67, 54, 0.35),
                  ),
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'threshold_line',
                    axis: AnnotationAxis.y,
                    value: _baseline,
                    label: '120 W',
                    lineColor: Colors.orange,
                    lineWidth: 1.5,
                    dashPattern: const [6, 4],
                    labelPosition: AnnotationLabelPosition.topRight,
                  ),
                ],
                xAxisConfig: const XAxisConfig(label: 'Time (s)', min: -0.5, max: 12.5),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                  min: 60,
                  max: 180,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Chart 2: Single-color deviation shading ──────────────────────
            const _SectionLabel(
              title: 'Baseline Fill — Single Color',
              description:
                  'Both sides of the baseline use orange fill. '
                  'Useful for highlighting any deviation from a target.',
            ),
            const SizedBox(height: 8),
            _ChartContainer(
              child: BravenChartPlus(
                series: const [
                  AreaChartSeries(
                    id: 'power_single_color',
                    name: 'Power',
                    points: _points,
                    color: Color(0xFFFF9800),
                    strokeWidth: 2.0,
                    fillOpacity: 0.35,
                    baselineValue: _baseline,
                    aboveBaselineFillColor: Color.fromRGBO(255, 152, 0, 0.35),
                    belowBaselineFillColor: Color.fromRGBO(255, 152, 0, 0.35),
                  ),
                ],
                xAxisConfig: const XAxisConfig(label: 'Time (s)', min: -0.5, max: 12.5),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                  min: 60,
                  max: 180,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Chart 3: Standard fill (no baseline) ─────────────────────────
            const _SectionLabel(
              title: 'Standard Fill (no baseline)',
              description:
                  'No baselineValue set — the area fills to the bottom of the '
                  'chart as in original behavior. Shown for comparison.',
            ),
            const SizedBox(height: 8),
            _ChartContainer(
              child: BravenChartPlus(
                series: const [
                  AreaChartSeries(
                    id: 'power_standard',
                    name: 'Power',
                    points: _points,
                    color: Color(0xFF5C6BC0),
                    strokeWidth: 2.0,
                    fillOpacity: 0.25,
                  ),
                ],
                xAxisConfig: const XAxisConfig(label: 'Time (s)', min: -0.5, max: 12.5),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                  min: 60,
                  max: 180,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

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
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ChartContainer extends StatelessWidget {
  const _ChartContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
