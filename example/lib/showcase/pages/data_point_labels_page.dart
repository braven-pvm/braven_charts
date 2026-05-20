// Copyright 2025 Braven Charts - Data Point Labels Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';

/// Showcase page demonstrating data-point label rendering.
class DataPointLabelsPage extends StatefulWidget {
  const DataPointLabelsPage({super.key});

  @override
  State<DataPointLabelsPage> createState() => _DataPointLabelsPageState();
}

class _DataPointLabelsPageState extends State<DataPointLabelsPage> {
  DataPointLabelPosition _position = DataPointLabelPosition.above;
  double _fontSize = 10.0;
  FontWeight _fontWeight = FontWeight.w600;
  bool _showUnit = false;
  DataPointMarkerStyle _markerStyle = DataPointMarkerStyle.filled;
  bool _showBackground = false;
  Color _backgroundColor = Colors.white;
  bool _customLabelColor = false;
  Color _labelColor = Colors.black87;
  bool _customFormatter = false;

  static const _points = [
    ChartDataPoint(x: 0, y: 3.4),
    ChartDataPoint(x: 10, y: 7.2),
    ChartDataPoint(x: 20, y: 12.8),
    ChartDataPoint(x: 30, y: 18.5),
    ChartDataPoint(x: 40, y: 22.1),
    ChartDataPoint(x: 50, y: 16.7),
    ChartDataPoint(x: 60, y: 9.3),
  ];

  static const _hrPoints = [
    ChartDataPoint(x: 0, y: 128),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 158),
    ChartDataPoint(x: 30, y: 171),
    ChartDataPoint(x: 40, y: 164),
    ChartDataPoint(x: 50, y: 152),
    ChartDataPoint(x: 60, y: 138),
  ];

  DataPointLabelConfig _buildConfig() => DataPointLabelConfig(
        show: true,
        position: _position,
        fontSize: _fontSize,
        fontWeight: _fontWeight,
        showUnit: _showUnit,
        labelColor: _customLabelColor ? _labelColor : null,
        formatter: _customFormatter ? (p) => '${p.y.toStringAsFixed(1)}!' : null,
        background: _showBackground ? _backgroundColor : null,
        backgroundOpacity: 0.88,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Point Labels')),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChartCard(
                  title: 'Configurable Labels',
                  subtitle: 'Position, font size, unit and background all live',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'lactate',
                        name: 'Lactate',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.0,
                        showDataPointMarkers: true,
                        dataPointMarkerRadius: 4.0,
                        dataPointMarkerStyle: _markerStyle,
                        unit: 'mmol/L',
                        dataPointLabels: _buildConfig(),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Lactate', unit: 'mmol/L', min: 0, max: 28),
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Integer Values + Background Pill',
                  subtitle: 'HR series — integers with white pill',
                  child: BravenChartPlus(
                    series: const [
                      LineChartSeries(
                        id: 'hr',
                        name: 'Heart Rate',
                        points: _hrPoints,
                        color: Color(0xFFEF4444),
                        strokeWidth: 2.0,
                        showDataPointMarkers: true,
                        dataPointMarkerRadius: 4.0,
                        unit: 'bpm',
                        dataPointLabels: DataPointLabelConfig(
                          show: true,
                          position: DataPointLabelPosition.above,
                          showUnit: true,
                          background: Colors.white,
                          backgroundOpacity: 0.9,
                          fontSize: 9.0,
                        ),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(position: YAxisPosition.left, label: 'HR', unit: 'bpm', min: 100, max: 200),
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Area Series Labels',
                  subtitle: 'AreaChartSeries with position: below',
                  child: BravenChartPlus(
                    series: const [
                      AreaChartSeries(
                        id: 'fat',
                        name: 'Fat Oxidation',
                        points: _points,
                        color: Color(0xFF10B981),
                        strokeWidth: 2.0,
                        fillOpacity: 0.18,
                        showDataPointMarkers: true,
                        dataPointMarkerRadius: 4.0,
                        unit: 'g/min',
                        dataPointLabels: DataPointLabelConfig(
                          show: true,
                          position: DataPointLabelPosition.below,
                          labelColor: Color(0xFF065F46),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(label: 'Intensity', min: -5, max: 65),
                    yAxis: YAxisConfig(position: YAxisPosition.left, label: 'g/min', min: 0, max: 30),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: OptionsPanel(
              title: 'Label Options',
              children: [
                OptionSection(
                  title: 'Configurable Labels',
                  icon: Icons.tune,
                  children: [
                    EnumOption<DataPointLabelPosition>(
                      label: 'Position',
                      value: _position,
                      values: DataPointLabelPosition.values,
                      labelBuilder: (p) => p.name,
                      onChanged: (v) => setState(() => _position = v),
                    ),
                    SliderOption(
                      label: 'Font Size',
                      value: _fontSize,
                      min: 7.0,
                      max: 16.0,
                      divisions: 9,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                    EnumOption<FontWeight>(
                      label: 'Font Weight',
                      value: _fontWeight,
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
                      onChanged: (v) => setState(() => _fontWeight = v),
                    ),
                    EnumOption<DataPointMarkerStyle>(
                      label: 'Marker Style',
                      value: _markerStyle,
                      values: DataPointMarkerStyle.values,
                      labelBuilder: (s) => s.name,
                      onChanged: (v) => setState(() => _markerStyle = v),
                    ),
                    BoolOption(
                      label: 'Show Unit',
                      value: _showUnit,
                      onChanged: (v) => setState(() => _showUnit = v),
                    ),
                    BoolOption(
                      label: 'Background Pill',
                      value: _showBackground,
                      onChanged: (v) => setState(() => _showBackground = v),
                    ),
                    if (_showBackground)
                      ColorOption(
                        label: 'Background Color',
                        value: _backgroundColor,
                        colors: const [
                          Colors.white,
                          Color(0xFFF3F4F6),
                          Color(0xFFFEF9C3),
                          Color(0xFFDCFCE7),
                          Color(0xFFDBEAFE),
                          Color(0xFFFFE4E6),
                          Colors.black,
                        ],
                        onChanged: (c) => setState(() => _backgroundColor = c),
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
                          Colors.black87,
                          Colors.white,
                          Color(0xFF6366F1),
                          Color(0xFFEF4444),
                          Color(0xFF10B981),
                          Color(0xFFF59E0B),
                          Color(0xFF0EA5E9),
                        ],
                        onChanged: (c) => setState(() => _labelColor = c),
                      ),
                    BoolOption(
                      label: 'Custom Formatter',
                      subtitle: 'y.toStringAsFixed(1) + "!"',
                      value: _customFormatter,
                      onChanged: (v) => setState(() => _customFormatter = v),
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
