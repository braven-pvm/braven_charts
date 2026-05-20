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
  double _labelFontSize = 11.0;
  FontWeight _labelFontWeight = FontWeight.w500;
  bool _customLabelColor = false;
  Color _labelColor = Colors.white;
  bool _labelBackground = false;
  Color _labelBackgroundColor = Colors.white;
  double _labelBackgroundOpacity = 0.85;

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

  SeriesInlineLabelConfig _buildLabelConfig(String text, Color seriesColor) =>
      SeriesInlineLabelConfig(
        text: text,
        position: _labelPosition,
        offsetY: _labelOffsetY,
        color: _customLabelColor ? _labelColor : seriesColor,
        fontSize: _labelFontSize,
        fontWeight: _labelFontWeight,
        background: _labelBackground
            ? SeriesLabelBackground(
                color: _labelBackgroundColor,
                opacity: _labelBackgroundOpacity,
              )
            : null,
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
                      onChanged: (v) => setState(() => _labelPosition = v),
                    ),
                    SliderOption(
                      label: 'Offset Y',
                      value: _labelOffsetY,
                      min: -40.0,
                      max: 40.0,
                      divisions: 16,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _labelOffsetY = v),
                    ),
                    SliderOption(
                      label: 'Font Size',
                      value: _labelFontSize,
                      min: 8.0,
                      max: 18.0,
                      divisions: 10,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _labelFontSize = v),
                    ),
                    EnumOption<FontWeight>(
                      label: 'Font Weight',
                      value: _labelFontWeight,
                      values: const [
                        FontWeight.w400,
                        FontWeight.w500,
                        FontWeight.w600,
                        FontWeight.w700,
                      ],
                      labelBuilder: (w) => switch (w) {
                        FontWeight.w400 => '400',
                        FontWeight.w500 => '500',
                        FontWeight.w600 => '600',
                        FontWeight.w700 => '700',
                        _ => w.toString(),
                      },
                      onChanged: (v) => setState(() => _labelFontWeight = v),
                    ),
                    BoolOption(
                      label: 'Custom Text Color',
                      value: _customLabelColor,
                      onChanged: (v) => setState(() => _customLabelColor = v),
                    ),
                    if (_customLabelColor)
                      ColorOption(
                        label: 'Text Color',
                        value: _labelColor,
                        colors: const [
                          Colors.white,
                          Colors.black87,
                          Color(0xFF6366F1),
                          Color(0xFFEF4444),
                          Color(0xFF10B981),
                          Color(0xFFF59E0B),
                        ],
                        onChanged: (c) => setState(() => _labelColor = c),
                      ),
                    BoolOption(
                      label: 'Background Pill',
                      value: _labelBackground,
                      onChanged: (v) => setState(() => _labelBackground = v),
                    ),
                    if (_labelBackground) ...[
                      ColorOption(
                        label: 'Background Color',
                        value: _labelBackgroundColor,
                        colors: const [
                          Colors.white,
                          Color(0xFFF3F4F6),
                          Color(0xFFFEF9C3),
                          Color(0xFFDCFCE7),
                          Color(0xFFDBEAFE),
                          Colors.black,
                        ],
                        onChanged: (c) =>
                            setState(() => _labelBackgroundColor = c),
                      ),
                      SliderOption(
                        label: 'Background Opacity',
                        value: _labelBackgroundOpacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        suffix: '',
                        decimalPlaces: 1,
                        onChanged: (v) =>
                            setState(() => _labelBackgroundOpacity = v),
                      ),
                    ],
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
