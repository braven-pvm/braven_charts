// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Product-shaped Radar compositions used by the public Gallery and media.
const radarGalleryCards = <Widget>[
  BudgetComparisonRadarGalleryCard(),
  CapabilityRadarGalleryCard(),
  ServiceHealthRadarGalleryCard(),
];

/// Two aligned profiles on the conventional polygon Spider web.
class BudgetComparisonRadarGalleryCard extends StatelessWidget {
  const BudgetComparisonRadarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RadarGalleryCard(
    key: const ValueKey('gallery-radar-budget-comparison'),
    title: 'Budget vs spending',
    subtitle: '6 departments · shared 0–100 scale · polygon web',
    series: [
      RadarChartSeries.fromMap(
        id: 'gallery-radar-budget',
        name: 'Allocated budget',
        unit: '%',
        color: const Color(0xFF0EA5E9),
        values: const {
          'Sales': 78,
          'Marketing': 46,
          'Development': 84,
          'Support': 58,
          'Technology': 67,
          'Administration': 42,
        },
        radarStyle: const RadarSeriesStyle(
          strokeWidth: 2.4,
          fillOpacity: 0.14,
          showMarkers: true,
          markerRadius: 3,
        ),
      ),
      RadarChartSeries.fromMap(
        id: 'gallery-radar-spending',
        name: 'Actual spending',
        unit: '%',
        color: const Color(0xFF4F46E5),
        values: const {
          'Sales': 69,
          'Marketing': 78,
          'Development': 74,
          'Support': 52,
          'Technology': 38,
          'Administration': 31,
        },
        radarStyle: const RadarSeriesStyle(
          strokeWidth: 2.2,
          strokeDashPattern: [6, 4],
          fillOpacity: 0.08,
          showMarkers: true,
          markerRadius: 3,
        ),
      ),
    ],
    config: const RadarChartConfig(
      pane: PolarPaneConfig(outerRadiusFactor: 0.68),
      categoryAxis: RadarCategoryAxisConfig(
        labelOffset: 8,
        labelStyle: PolarLabelStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      radialAxis: RadarNumericAxisConfig(
        maximum: 100,
        tickCount: 5,
        showLabels: false,
        gridShape: RadarGridShape.polygon,
      ),
    ),
  );
}

/// Three team profiles on a circular web and a dark analytical canvas.
class CapabilityRadarGalleryCard extends StatelessWidget {
  const CapabilityRadarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    return _RadarGalleryCard(
      key: const ValueKey('gallery-radar-capability'),
      title: 'Capability profile',
      subtitle: '3 teams · circular web · compact legend',
      theme: base.copyWith(
        backgroundColor: const Color(0xFF101827),
        legendStyle: base.legendStyle.copyWith(
          position: LegendPosition.bottomCenter,
          orientation: LegendOrientation.horizontal,
          markerShape: LegendMarkerShape.line,
          markerSize: 9,
          itemSpacing: 5,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          textStyle: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 9),
        ),
      ),
      showLegend: true,
      legendStyle: const LegendStyle(
        position: LegendPosition.bottomCenter,
        orientation: LegendOrientation.horizontal,
        markerShape: LegendMarkerShape.line,
        markerSize: 9,
        itemSpacing: 5,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        textStyle: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Color(0xE61E293B),
        borderColor: Color(0xFF475569),
        borderWidth: 0.8,
      ),
      series: [
        _profile(
          id: 'gallery-radar-north',
          name: 'North',
          color: const Color(0xFF38BDF8),
          values: const [84, 72, 78, 66, 80, 70],
        ),
        _profile(
          id: 'gallery-radar-central',
          name: 'Central',
          color: const Color(0xFF34D399),
          values: const [68, 86, 72, 82, 64, 76],
          dashed: true,
        ),
        _profile(
          id: 'gallery-radar-south',
          name: 'South',
          color: const Color(0xFFFBBF24),
          values: const [74, 64, 88, 70, 72, 82],
        ),
      ],
      config: const RadarChartConfig(
        pane: PolarPaneConfig(startAngleDegrees: -60, outerRadiusFactor: 0.64),
        categoryAxis: RadarCategoryAxisConfig(
          labelOffset: 7,
          labelStyle: PolarLabelStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        radialAxis: RadarNumericAxisConfig(
          maximum: 100,
          tickCount: 4,
          showLabels: false,
          gridShape: RadarGridShape.circle,
        ),
      ),
    );
  }
}

/// A denser operational profile that exercises labels and exact values.
class ServiceHealthRadarGalleryCard extends StatelessWidget {
  const ServiceHealthRadarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RadarGalleryCard(
    key: const ValueKey('gallery-radar-service-health'),
    title: 'Service health',
    subtitle: '8 dimensions · value labels · constrained pane',
    series: [
      RadarChartSeries.fromMap(
        id: 'gallery-radar-service-current',
        name: 'Current window',
        unit: '%',
        color: const Color(0xFF0F766E),
        values: const {
          'Availability': 88,
          'Latency': 66,
          'Throughput': 74,
          'Recovery': 62,
          'Security': 82,
          'Coverage': 76,
          'Automation': 58,
          'Satisfaction': 72,
        },
        radarStyle: const RadarSeriesStyle(
          strokeWidth: 2.6,
          fillOpacity: 0.17,
          showMarkers: true,
          markerRadius: 3.2,
          showDataLabels: true,
        ),
      ),
      RadarChartSeries.fromMap(
        id: 'gallery-radar-service-target',
        name: 'Target profile',
        unit: '%',
        color: const Color(0xFFF97316),
        values: const {
          'Availability': 94,
          'Latency': 84,
          'Throughput': 86,
          'Recovery': 82,
          'Security': 92,
          'Coverage': 88,
          'Automation': 80,
          'Satisfaction': 90,
        },
        radarStyle: const RadarSeriesStyle(
          strokeWidth: 1.8,
          strokeDashPattern: [4, 4],
          fillOpacity: 0.03,
          showMarkers: false,
        ),
      ),
    ],
    config: const RadarChartConfig(
      pane: PolarPaneConfig(outerRadiusFactor: 0.62),
      categoryAxis: RadarCategoryAxisConfig(
        labelOffset: 5,
        maximumVisibleLabels: 8,
        labelStyle: PolarLabelStyle(fontSize: 9),
      ),
      radialAxis: RadarNumericAxisConfig(
        maximum: 100,
        tickCount: 5,
        showLabels: false,
        gridShape: RadarGridShape.polygon,
      ),
    ),
  );
}

RadarChartSeries _profile({
  required String id,
  required String name,
  required Color color,
  required List<num> values,
  bool dashed = false,
}) {
  const categories = [
    'Discovery',
    'Delivery',
    'Quality',
    'Collaboration',
    'Reliability',
    'Learning',
  ];
  return RadarChartSeries.fromMap(
    id: id,
    name: name,
    unit: '%',
    color: color,
    values: {
      for (var index = 0; index < categories.length; index++)
        categories[index]: values[index],
    },
    radarStyle: RadarSeriesStyle(
      strokeWidth: 2.1,
      strokeDashPattern: dashed ? const [5, 4] : const [],
      fillOpacity: 0.07,
      showMarkers: true,
      markerRadius: 2.6,
    ),
  );
}

class _RadarGalleryCard extends StatelessWidget {
  const _RadarGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.series,
    required this.config,
    this.theme,
    this.showLegend = false,
    this.legendStyle,
  });

  final String title;
  final String subtitle;
  final List<RadarChartSeries> series;
  final RadarChartConfig config;
  final ChartTheme? theme;
  final bool showLegend;
  final LegendStyle? legendStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? ChartTheme.light;
    final isDark =
        ThemeData.estimateBrightnessForColor(resolvedTheme.backgroundColor) ==
        Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF8FAFC)
        : Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark
        ? const Color(0xFFCBD5E1)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      color: isDark ? resolvedTheme.backgroundColor : null,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: subtitleColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: series,
                radarChartConfig: config,
                theme: resolvedTheme,
                showLegend: showLegend,
                legendStyle: legendStyle,
                grid: const GridConfig(horizontal: false, vertical: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(enabled: false),
                  tooltip: TooltipConfig(
                    enabled: true,
                    triggerMode: TooltipTriggerMode.both,
                  ),
                  enableZoom: false,
                  enablePan: false,
                  enableSelection: true,
                  showFocusBorder: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
