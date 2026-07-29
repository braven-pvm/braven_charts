// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

const heatmapGalleryCards = <Widget>[
  _ActivityHeatmapGalleryCard(),
  _TemperatureHeatmapGalleryCard(),
  _ServiceHeatmapGalleryCard(),
];

class _ActivityHeatmapGalleryCard extends StatelessWidget {
  const _ActivityHeatmapGalleryCard();

  @override
  Widget build(BuildContext context) {
    const values = <List<double>>[
      [18, 26, 44, 61, 78, 66, 31],
      [14, 23, 36, 55, 83, 72, 28],
      [11, 19, 31, 48, 69, 63, 25],
      [16, 25, 39, 58, 76, 70, 34],
      [21, 32, 47, 67, 88, 79, 40],
    ];
    final series = HeatmapChartSeries(
      id: 'gallery-heatmap-activity',
      name: 'Engagement',
      points: _matrixPoints('activity', values),
      colorScale: HeatmapColorScale.sequential(
        colors: const [
          Color(0xFFE0F2FE),
          Color(0xFF67E8F9),
          Color(0xFF0891B2),
          Color(0xFF164E63),
        ],
        minimumValue: 0,
        maximumValue: 100,
        label: 'Engagement',
        unit: '%',
      ),
      showCellLabels: true,
      cellLabelFontSize: 10,
      gapFraction: 0.10,
      cornerRadius: 3,
    );
    return _HeatmapGalleryCard(
      key: const ValueKey('gallery-heatmap-activity'),
      title: 'Weekly activity',
      subtitle: 'Recurring engagement windows across day and time',
      series: series,
      columns: const ['06', '09', '12', '15', '18', '21', '24'],
      rows: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      xLabel: 'Time',
      yLabel: 'Day',
    );
  }
}

class _TemperatureHeatmapGalleryCard extends StatelessWidget {
  const _TemperatureHeatmapGalleryCard();

  @override
  Widget build(BuildContext context) {
    const values = <List<double>>[
      [14, 13, 12, 16, 22, 25, 21, 17],
      [15, 14, 13, 17, 24, 27, 23, 18],
      [13, 12, 11, 16, 23, 26, 22, 16],
      [16, 15, 14, 18, 25, 29, 24, 19],
      [17, 16, 15, 20, 27, 30, 26, 21],
    ];
    final series = HeatmapChartSeries(
      id: 'gallery-heatmap-temperature',
      name: 'Temperature',
      unit: '°C',
      points: _matrixPoints('temperature', values),
      colorScale: HeatmapColorScale.diverging(
        lowColor: const Color(0xFF2563EB),
        midpointColor: const Color(0xFFFFF7D6),
        highColor: const Color(0xFFEA580C),
        midpoint: 20,
        minimumValue: 10,
        maximumValue: 30,
        label: 'Temperature',
        unit: '°C',
      ),
      gapFraction: 0.05,
      cornerRadius: 1,
    );
    return _HeatmapGalleryCard(
      key: const ValueKey('gallery-heatmap-temperature'),
      title: 'Temperature rhythm',
      subtitle: 'Cool and warm periods around a stable comfort midpoint',
      series: series,
      columns: const ['00', '03', '06', '09', '12', '15', '18', '21'],
      rows: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      xLabel: 'Hour',
      yLabel: 'Day',
    );
  }
}

class _ServiceHeatmapGalleryCard extends StatelessWidget {
  const _ServiceHeatmapGalleryCard();

  @override
  Widget build(BuildContext context) {
    const values = <List<double?>>[
      [99.9, 99.8, 98.9, 99.7, 99.9, 99.6],
      [99.7, 98.4, 97.8, 99.2, 99.8, 99.4],
      [99.8, 99.6, null, 98.8, 99.7, 99.5],
      [99.9, 99.9, 99.6, 99.8, 98.6, 99.7],
    ];
    final points = <HeatmapDataPoint>[
      for (var row = 0; row < values.length; row++)
        for (var column = 0; column < values[row].length; column++)
          if (values[row][column] == null)
            HeatmapDataPoint.missing(
              x: column.toDouble(),
              y: row.toDouble(),
              pointKey: 'gallery-service-$row-$column',
              label: 'No sample',
            )
          else
            HeatmapDataPoint(
              x: column.toDouble(),
              y: row.toDouble(),
              value: values[row][column]!,
              pointKey: 'gallery-service-$row-$column',
              label: '${values[row][column]!.toStringAsFixed(1)}%',
            ),
    ];
    final series = HeatmapChartSeries(
      id: 'gallery-heatmap-service',
      name: 'Availability',
      unit: '%',
      points: points,
      colorScale: HeatmapColorScale.threshold(
        thresholds: const [98, 99.5],
        colors: const [Color(0xFFDC2626), Color(0xFFF59E0B), Color(0xFF16A34A)],
        bandLabels: const ['Degraded', 'Watch', 'Healthy'],
        missingColor: const Color(0xFFE2E8F0),
        label: 'Availability',
        unit: '%',
      ),
      showCellLabels: true,
      cellLabelFontSize: 9.5,
      gapFraction: 0.12,
      cornerRadius: 5,
    );
    return _HeatmapGalleryCard(
      key: const ValueKey('gallery-heatmap-service'),
      title: 'Service health',
      subtitle: 'Operational thresholds with an explicit missing sample',
      series: series,
      columns: const ['Login', 'Search', 'Pay', 'Sync', 'API', 'Jobs'],
      rows: const ['Web', 'API', 'Jobs', 'Store'],
      xLabel: 'Check',
      yLabel: 'Service',
    );
  }
}

class _HeatmapGalleryCard extends StatelessWidget {
  const _HeatmapGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.series,
    required this.columns,
    required this.rows,
    required this.xLabel,
    required this.yLabel,
  });

  final String title;
  final String subtitle;
  final HeatmapChartSeries series;
  final List<String> columns;
  final List<String> rows;
  final String xLabel;
  final String yLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BravenChartPlus(
                series: [series],
                showLegend: false,
                grid: const GridConfig(horizontal: false, vertical: false),
                xAxisConfig: XAxisConfig(
                  label: xLabel,
                  categoryAxis: CategoryAxisConfig(
                    categories: columns,
                    minimumCategoryExtent: 34,
                    maximumLabelExtent: 52,
                  ),
                ),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: yLabel,
                  maxWidth: 72,
                  categoryAxis: CategoryAxisConfig(
                    categories: rows,
                    minimumCategoryExtent: 30,
                    maximumLabelExtent: 58,
                  ),
                ),
                interactionConfig: const InteractionConfig(
                  tooltip: TooltipConfig(enabled: true),
                ),
              ),
            ),
            const SizedBox(height: 8),
            HeatmapColorLegend(series: series),
          ],
        ),
      ),
    );
  }
}

List<HeatmapDataPoint> _matrixPoints(
  String prefix,
  List<List<double>> values,
) => [
  for (var row = 0; row < values.length; row++)
    for (var column = 0; column < values[row].length; column++)
      HeatmapDataPoint(
        x: column.toDouble(),
        y: row.toDouble(),
        value: values[row][column],
        pointKey: 'gallery-$prefix-$row-$column',
      ),
];
