// Copyright 2025 Braven Charts - Series Styling Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';

class SeriesStylingPage extends StatefulWidget {
  const SeriesStylingPage({super.key});

  @override
  State<SeriesStylingPage> createState() => _SeriesStylingPageState();
}

class _SeriesStylingPageState extends State<SeriesStylingPage> {
  double _lineGlow = 0.0;

  static const _points = [
    ChartDataPoint(x: 0, y: 120),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 132),
    ChartDataPoint(x: 30, y: 168),
    ChartDataPoint(x: 40, y: 155),
    ChartDataPoint(x: 50, y: 178),
    ChartDataPoint(x: 60, y: 161),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Series Styling')),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChartCard(
                  title: 'Line Glow',
                  subtitle: 'lineGlow controls blur-halo radius',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'power',
                        name: 'Power',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.5,
                        lineGlow: _lineGlow,
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                        label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'W',
                        min: 100,
                        max: 200),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: OptionsPanel(
              title: 'Styling Options',
              children: [
                OptionSection(
                  title: 'Line Glow',
                  icon: Icons.blur_on,
                  children: [
                    SliderOption(
                      label: 'Glow Radius',
                      value: _lineGlow,
                      min: 0.0,
                      max: 12.0,
                      divisions: 12,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _lineGlow = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}
