// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Production-shaped Scatter compositions shared by the Gallery and release
/// media. Each card demonstrates a different quantitative encoding.
const scatterGalleryCards = <Widget>[
  MarketOpportunityScatterCard(),
  AthleteReadinessScatterCard(),
  EquipmentRiskScatterCard(),
];

class _ScatterGalleryCard extends StatelessWidget {
  const _ScatterGalleryCard({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    this.annotations = const [],
    this.dark = false,
  });

  final String title;
  final String subtitle;
  final List<ScatterChartSeries> series;
  final XAxisConfig xAxis;
  final YAxisConfig yAxis;
  final List<ChartAnnotation> annotations;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardColor = dark ? const Color(0xFF111827) : colors.surface;
    final titleColor = dark ? const Color(0xFFF8FAFC) : colors.onSurface;
    final subtitleColor = dark
        ? const Color(0xFFCBD5E1)
        : colors.onSurfaceVariant;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: series,
                annotations: annotations,
                theme: dark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                legendStyle: LegendStyle(
                  position: LegendPosition.topRight,
                  orientation: LegendOrientation.horizontal,
                  allowDragging: false,
                  textStyle: TextStyle(color: titleColor, fontSize: 10),
                ),
                xAxisConfig: xAxis,
                yAxis: yAxis,
                interactionConfig: const InteractionConfig(
                  tooltip: TooltipConfig(enabled: true),
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Revenue growth and retention locate each market; active accounts determine
/// marker area while shape keeps market type legible without colour.
class MarketOpportunityScatterCard extends StatelessWidget {
  const MarketOpportunityScatterCard({super.key});

  @override
  Widget build(BuildContext context) => _ScatterGalleryCard(
    title: 'Market opportunity map',
    subtitle: 'Position · bubble area · market-type shape · size legend',
    xAxis: const XAxisConfig(label: 'Revenue growth', unit: '%'),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Retention',
      unit: '%',
      min: 68,
      max: 100,
    ),
    annotations: [
      ThresholdAnnotation(
        id: 'retention-target',
        axis: AnnotationAxis.y,
        value: 88,
        label: 'Retention target',
        lineColor: const Color(0xFF64748B),
        dashPattern: const [6, 4],
      ),
    ],
    series: const [
      ScatterChartSeries(
        id: 'established',
        name: 'Established',
        color: Color(0xFF2563EB),
        markerShape: SeriesMarkerShape.circle,
        markerStyle: ScatterMarkerStyle(
          strokeColor: Color(0xFF1E3A8A),
          strokeWidth: 1.5,
          opacity: 0.82,
        ),
        sizeEncoding: ScatterSizeEncoding(
          minimumRadius: 6,
          maximumRadius: 22,
          maximumValue: 18000,
          label: 'Active accounts',
        ),
        points: [
          ChartDataPoint(
            x: 7,
            y: 94,
            magnitude: 16400,
            label: 'Northern enterprise',
          ),
          ChartDataPoint(
            x: 11,
            y: 90,
            magnitude: 9800,
            label: 'Central business',
          ),
          ChartDataPoint(
            x: 15,
            y: 86,
            magnitude: 7200,
            label: 'Pacific accounts',
          ),
          ChartDataPoint(
            x: 19,
            y: 92,
            magnitude: 12100,
            label: 'Atlantic portfolio',
          ),
        ],
      ),
      ScatterChartSeries(
        id: 'growth',
        name: 'Growth',
        color: Color(0xFFF97316),
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: ScatterMarkerStyle(
          strokeColor: Color(0xFF9A3412),
          strokeWidth: 1.5,
          opacity: 0.84,
          rotationDegrees: 4,
        ),
        sizeEncoding: ScatterSizeEncoding(
          minimumRadius: 6,
          maximumRadius: 22,
          maximumValue: 18000,
          label: 'Active accounts',
        ),
        points: [
          ChartDataPoint(x: 18, y: 78, magnitude: 4100, label: 'Launch cohort'),
          ChartDataPoint(
            x: 24,
            y: 84,
            magnitude: 6900,
            label: 'Partner growth',
          ),
          ChartDataPoint(
            x: 30,
            y: 89,
            magnitude: 11300,
            label: 'Digital expansion',
          ),
          ChartDataPoint(x: 36, y: 96, magnitude: 15300, label: 'New category'),
        ],
      ),
    ],
  );
}

/// A continuous colour channel carries recovery readiness independently from
/// each athlete's load and power coordinates.
class AthleteReadinessScatterCard extends StatelessWidget {
  const AthleteReadinessScatterCard({super.key});

  @override
  Widget build(BuildContext context) => _ScatterGalleryCard(
    title: 'Athlete readiness map',
    subtitle: 'Training load · power · continuous readiness colour',
    xAxis: const XAxisConfig(label: 'Weekly training load', unit: 'AU'),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: '20-minute power',
      unit: 'W',
    ),
    series: const [
      ScatterChartSeries(
        id: 'build',
        name: 'Build block',
        markerShape: SeriesMarkerShape.triangle,
        markerStyle: ScatterMarkerStyle(
          strokeColor: Color(0xFF334155),
          strokeWidth: 1.25,
          width: 14,
          height: 14,
        ),
        colorEncoding: ScatterColorEncoding(
          colors: [Color(0xFFE11D48), Color(0xFFF59E0B), Color(0xFF10B981)],
          minimumValue: 45,
          maximumValue: 95,
          label: 'Readiness',
          unit: '%',
        ),
        points: [
          ChartDataPoint(x: 340, y: 248, colorValue: 91, label: 'A. Singh'),
          ChartDataPoint(x: 405, y: 262, colorValue: 82, label: 'B. Mensah'),
          ChartDataPoint(x: 470, y: 276, colorValue: 73, label: 'C. Novak'),
          ChartDataPoint(x: 535, y: 287, colorValue: 66, label: 'D. Silva'),
          ChartDataPoint(x: 610, y: 294, colorValue: 55, label: 'E. Chen'),
        ],
      ),
      ScatterChartSeries(
        id: 'recovery',
        name: 'Recovery block',
        markerShape: SeriesMarkerShape.circle,
        markerStyle: ScatterMarkerStyle(
          strokeColor: Color(0xFF334155),
          strokeWidth: 1.25,
          width: 13,
          height: 13,
        ),
        colorEncoding: ScatterColorEncoding(
          colors: [Color(0xFFE11D48), Color(0xFFF59E0B), Color(0xFF10B981)],
          minimumValue: 45,
          maximumValue: 95,
          label: 'Readiness',
          unit: '%',
        ),
        points: [
          ChartDataPoint(x: 280, y: 235, colorValue: 88, label: 'F. Okafor'),
          ChartDataPoint(x: 365, y: 254, colorValue: 78, label: 'G. Meyer'),
          ChartDataPoint(x: 445, y: 269, colorValue: 69, label: 'H. Park'),
          ChartDataPoint(x: 520, y: 279, colorValue: 60, label: 'I. Torres'),
          ChartDataPoint(x: 585, y: 284, colorValue: 49, label: 'J. Williams'),
        ],
      ),
    ],
  );
}

/// Explicit operating bands make threshold equality and risk categories
/// inspectable in the chart, legend, tooltip, table, artifact, and source.
class EquipmentRiskScatterCard extends StatelessWidget {
  const EquipmentRiskScatterCard({super.key});

  @override
  Widget build(BuildContext context) => _ScatterGalleryCard(
    title: 'Equipment risk map',
    subtitle: 'Vibration · temperature · explicit risk bands',
    dark: true,
    xAxis: const XAxisConfig(
      color: Color(0xFF67E8F9),
      label: 'Vibration',
      unit: 'mm/s',
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      color: const Color(0xFFCBD5E1),
      label: 'Bearing temperature',
      unit: '°C',
    ),
    annotations: [
      ThresholdAnnotation(
        id: 'temperature-review',
        axis: AnnotationAxis.y,
        value: 78,
        label: 'Review zone',
        style: const AnnotationStyle(
          textStyle: TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
        ),
        lineColor: const Color(0xFFF59E0B),
        dashPattern: const [5, 4],
      ),
    ],
    series: const [
      ScatterChartSeries(
        id: 'equipment',
        name: 'Assets',
        markerShape: SeriesMarkerShape.diamond,
        markerStyle: ScatterMarkerStyle(
          strokeColor: Color(0xFFF8FAFC),
          strokeWidth: 1.25,
          width: 14,
          height: 14,
          opacity: 0.92,
        ),
        colorEncoding: ScatterColorEncoding(
          colors: [Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFFB7185)],
          scaleType: ScatterColorScaleType.piecewise,
          thresholds: [35, 70],
          bandLabels: ['Stable', 'Watch', 'Critical'],
          minimumValue: 0,
          maximumValue: 100,
          label: 'Risk score',
        ),
        points: [
          ChartDataPoint(x: 1.4, y: 52, colorValue: 18, label: 'Pump A'),
          ChartDataPoint(x: 2.1, y: 58, colorValue: 28, label: 'Pump B'),
          ChartDataPoint(x: 2.8, y: 64, colorValue: 35, label: 'Fan C'),
          ChartDataPoint(x: 3.6, y: 69, colorValue: 48, label: 'Motor D'),
          ChartDataPoint(x: 4.2, y: 75, colorValue: 62, label: 'Fan E'),
          ChartDataPoint(x: 4.9, y: 79, colorValue: 70, label: 'Motor F'),
          ChartDataPoint(x: 5.7, y: 86, colorValue: 84, label: 'Pump G'),
          ChartDataPoint(x: 6.4, y: 91, colorValue: 96, label: 'Motor H'),
        ],
      ),
    ],
  );
}
