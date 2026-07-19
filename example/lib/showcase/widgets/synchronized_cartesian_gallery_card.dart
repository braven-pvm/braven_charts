// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Three independently scaled charts sharing a data-X cursor and viewport.
///
/// The card is intentionally reusable in the Gallery and release-media
/// harness so the public screenshot exercises the same composition as the
/// live showcase.
class SynchronizedCartesianGalleryCard extends StatefulWidget {
  const SynchronizedCartesianGalleryCard({super.key});

  @override
  State<SynchronizedCartesianGalleryCard> createState() =>
      _SynchronizedCartesianGalleryCardState();
}

class _SynchronizedCartesianGalleryCardState
    extends State<SynchronizedCartesianGalleryCard> {
  final _interactionGroup = ChartInteractionGroupController();

  @override
  void dispose() {
    _interactionGroup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Synchronized route profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '3 local Y scales · shared distance cursor · synchronized X viewport',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _metricChart(
                      series: const LineChartSeries(
                        id: 'sync-speed',
                        name: 'Speed',
                        unit: 'km/h',
                        color: Color(0xFF0891B2),
                        interpolation: LineInterpolation.monotone,
                        strokeWidth: 2.5,
                        points: _speedPoints,
                      ),
                      label: 'Speed',
                      unit: 'km/h',
                      color: const Color(0xFF0891B2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _metricChart(
                      series: const AreaChartSeries(
                        id: 'sync-elevation',
                        name: 'Elevation',
                        unit: 'm',
                        color: Color(0xFF059669),
                        interpolation: LineInterpolation.monotone,
                        strokeWidth: 2,
                        fillOpacity: 0.18,
                        points: _elevationPoints,
                      ),
                      label: 'Elevation',
                      unit: 'm',
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _metricChart(
                      series: const LineChartSeries(
                        id: 'sync-heart-rate',
                        name: 'Heart rate',
                        unit: 'bpm',
                        color: Color(0xFFE11D48),
                        interpolation: LineInterpolation.monotone,
                        strokeWidth: 2.5,
                        points: _heartRatePoints,
                      ),
                      label: 'Heart rate',
                      unit: 'bpm',
                      color: const Color(0xFFE11D48),
                      showXAxis: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChart({
    required ChartSeries series,
    required String label,
    required String unit,
    required Color color,
    bool showXAxis = false,
  }) => BravenChartPlus(
    interactionGroupController: _interactionGroup,
    interactionGroupOptions: const ChartInteractionGroupOptions(
      synchronizeCursor: true,
      synchronizeViewport: true,
    ),
    series: [series],
    showLegend: false,
    theme: ChartTheme.light.copyWith(
      seriesTheme: ChartTheme.light.seriesTheme.copyWith(colors: [color]),
    ),
    grid: const GridConfig(horizontal: true, vertical: false),
    xAxisConfig: XAxisConfig(
      visible: showXAxis,
      label: showXAxis ? 'Distance' : null,
      unit: showXAxis ? 'km' : null,
      minHeight: showXAxis ? 42 : 0,
      maxHeight: showXAxis ? 42 : 0,
      showCrosshairLabel: false,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: label,
      unit: unit,
      minWidth: 64,
      maxWidth: 64,
      showCrosshairLabel: false,
    ),
    interactionConfig: const InteractionConfig(
      enableZoom: true,
      enablePan: true,
      crosshair: CrosshairConfig(
        enabled: true,
        mode: CrosshairMode.both,
        displayMode: CrosshairDisplayMode.tracking,
        interpolateValues: true,
        showTrackingTooltip: false,
        showCoordinateLabels: false,
        showIntersectionMarkers: true,
        intersectionMarkerRadius: 3.5,
      ),
      tooltip: TooltipConfig(enabled: true),
    ),
  );
}

const _speedPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 22),
  ChartDataPoint(x: 2, y: 28),
  ChartDataPoint(x: 4, y: 31),
  ChartDataPoint(x: 6, y: 27),
  ChartDataPoint(x: 8, y: 34),
  ChartDataPoint(x: 10, y: 36),
  ChartDataPoint(x: 12, y: 32),
  ChartDataPoint(x: 14, y: 38),
  ChartDataPoint(x: 16, y: 35),
  ChartDataPoint(x: 18, y: 41),
  ChartDataPoint(x: 20, y: 39),
];

const _elevationPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 310),
  ChartDataPoint(x: 2, y: 345),
  ChartDataPoint(x: 4, y: 420),
  ChartDataPoint(x: 6, y: 510),
  ChartDataPoint(x: 8, y: 470),
  ChartDataPoint(x: 10, y: 390),
  ChartDataPoint(x: 12, y: 445),
  ChartDataPoint(x: 14, y: 560),
  ChartDataPoint(x: 16, y: 615),
  ChartDataPoint(x: 18, y: 520),
  ChartDataPoint(x: 20, y: 460),
];

const _heartRatePoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 118),
  ChartDataPoint(x: 2, y: 126),
  ChartDataPoint(x: 4, y: 138),
  ChartDataPoint(x: 6, y: 147),
  ChartDataPoint(x: 8, y: 154),
  ChartDataPoint(x: 10, y: 149),
  ChartDataPoint(x: 12, y: 158),
  ChartDataPoint(x: 14, y: 166),
  ChartDataPoint(x: 16, y: 171),
  ChartDataPoint(x: 18, y: 164),
  ChartDataPoint(x: 20, y: 157),
];
