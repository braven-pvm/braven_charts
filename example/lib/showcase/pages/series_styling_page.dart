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
  SeriesLabelPosition _labelPosition = SeriesLabelPosition.right;
  double _labelOffsetY = 0.0;
  bool _labelBackground = false;

  static const _points = [
    ChartDataPoint(x: 0, y: 120),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 132),
    ChartDataPoint(x: 30, y: 168),
    ChartDataPoint(x: 40, y: 155),
    ChartDataPoint(x: 50, y: 178),
    ChartDataPoint(x: 60, y: 161),
  ];

  static const _twoSeriesPoints = [
    ChartDataPoint(x: 0, y: 80),
    ChartDataPoint(x: 10, y: 95),
    ChartDataPoint(x: 20, y: 110),
    ChartDataPoint(x: 30, y: 98),
    ChartDataPoint(x: 40, y: 115),
    ChartDataPoint(x: 50, y: 102),
    ChartDataPoint(x: 60, y: 120),
  ];

  SeriesInlineLabelConfig _buildLabelConfig(String text, Color color) =>
      SeriesInlineLabelConfig(
        text: text,
        position: _labelPosition,
        offsetY: _labelOffsetY,
        color: color,
        background:
            _labelBackground ? const SeriesLabelBackground(color: Colors.white) : null,
      );

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
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Series Inline Labels',
                  subtitle: 'Label anchored to the series line',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'power',
                        name: 'Power',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.0,
                        inlineLabel: _buildLabelConfig(
                            'Power', const Color(0xFF6366F1)),
                      ),
                      LineChartSeries(
                        id: 'hr',
                        name: 'HR',
                        points: _twoSeriesPoints,
                        color: const Color(0xFFEF4444),
                        strokeWidth: 2.0,
                        inlineLabel: _buildLabelConfig(
                            'HR', const Color(0xFFEF4444)),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                        label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Value',
                        min: 60,
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
                OptionSection(
                  title: 'Inline Label',
                  icon: Icons.label_outline,
                  children: [
                    EnumOption<SeriesLabelPosition>(
                      label: 'Position',
                      value: _labelPosition,
                      values: SeriesLabelPosition.values,
                      labelBuilder: (p) => p.name,
                      onChanged: (v) =>
                          setState(() => _labelPosition = v),
                    ),
                    SliderOption(
                      label: 'Offset Y',
                      value: _labelOffsetY,
                      min: -40.0,
                      max: 40.0,
                      divisions: 16,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) =>
                          setState(() => _labelOffsetY = v),
                    ),
                    BoolOption(
                      label: 'Background Pill',
                      value: _labelBackground,
                      onChanged: (v) =>
                          setState(() => _labelBackground = v),
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
