// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// A production-shaped Bar composition shared by the Gallery and pub.dev media.
class BarTargetsGalleryCard extends StatelessWidget {
  const BarTargetsGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Channel performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Grouped bars · benchmark markers · durable point selection',
              style: TextStyle(fontSize: 12, color: labelColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  BarChartSeries(
                    id: 'forecast',
                    name: 'Forecast',
                    unit: '%',
                    points: [
                      ChartDataPoint(x: 0, y: 64, label: 'Web'),
                      ChartDataPoint(x: 1, y: 72, label: 'Retail'),
                      ChartDataPoint(x: 2, y: 70, label: 'Partner'),
                      ChartDataPoint(x: 3, y: 83, label: 'Direct'),
                      ChartDataPoint(x: 4, y: 61, label: 'Enterprise'),
                      ChartDataPoint(x: 5, y: 79, label: 'Event'),
                    ],
                    color: Color(0xFF60A5FA),
                    barWidthPercent: 0.66,
                    barGap: 3,
                    barStyle: BarChartStyle(
                      cornerRadius: 6,
                      gradient: BarGradient(
                        colors: [Color(0xFF93C5FD), Color(0xFF2563EB)],
                      ),
                      interaction: BarInteractionStyle(dimmedOpacity: 0.38),
                    ),
                    labelStyle: BarLabelStyle(show: false),
                  ),
                  BarChartSeries(
                    id: 'actual',
                    name: 'Actual',
                    unit: '%',
                    points: [
                      ChartDataPoint(x: 0, y: 69, label: 'Web'),
                      ChartDataPoint(x: 1, y: 84, label: 'Retail'),
                      ChartDataPoint(x: 2, y: 77, label: 'Partner'),
                      ChartDataPoint(x: 3, y: 91, label: 'Direct'),
                      ChartDataPoint(x: 4, y: 58, label: 'Enterprise'),
                      ChartDataPoint(x: 5, y: 88, label: 'Event'),
                    ],
                    color: Color(0xFF14B8A6),
                    barWidthPercent: 0.66,
                    barGap: 3,
                    targetValues: [72, 80, 75, 88, 70, 85],
                    targetMarkerStyle: BarTargetMarkerStyle(
                      color: Color(0xFFF97316),
                      width: 2.5,
                      lengthFactor: 1.45,
                    ),
                    barStyle: BarChartStyle(
                      cornerRadius: 6,
                      gradient: BarGradient(
                        colors: [Color(0xFF5EEAD4), Color(0xFF0F766E)],
                      ),
                      interaction: BarInteractionStyle(dimmedOpacity: 0.38),
                    ),
                    labelStyle: BarLabelStyle(show: false),
                  ),
                ],
                theme: isDark ? ChartTheme.dark : ChartTheme.light,
                showLegend: true,
                legendStyle: const LegendStyle(
                  position: LegendPosition.topRight,
                  orientation: LegendOrientation.horizontal,
                  allowDragging: false,
                ),
                xAxisConfig: const XAxisConfig(
                  label: 'Channel',
                  min: -0.5,
                  max: 5.5,
                  tickCount: 6,
                ),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Attainment',
                  unit: '%',
                  min: 0,
                  max: 105,
                ),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                  tooltip: TooltipConfig(
                    enabled: true,
                    triggerMode: TooltipTriggerMode.hover,
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
