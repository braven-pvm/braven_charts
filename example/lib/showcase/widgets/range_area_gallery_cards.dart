// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Production-shaped Range Area compositions shared by the Gallery and
/// release media. Each card keeps every low/high interval atomic while using
/// ordinary Line series for independent observations or centre estimates.
const rangeAreaGalleryCards = <Widget>[
  TemperatureEnvelopeGalleryCard(),
  ForecastFanGalleryCard(),
  VolatilityEnvelopeGalleryCard(),
];

class _RangeAreaGalleryCard extends StatelessWidget {
  const _RangeAreaGalleryCard({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    this.dark = false,
  });

  final String title;
  final String subtitle;
  final List<ChartSeries> series;
  final XAxisConfig xAxis;
  final YAxisConfig yAxis;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = dark ? const Color(0xFF111827) : scheme.surface;
    final titleColor = dark ? const Color(0xFFF8FAFC) : scheme.onSurface;
    final subtitleColor = dark
        ? const Color(0xFFCBD5E1)
        : scheme.onSurfaceVariant;

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
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: series,
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
                    mode: CrosshairMode.vertical,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                    showTrackingTooltip: true,
                    showIntersectionMarkers: true,
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

/// Weather observations remain an independent Line inside one paired daily
/// minimum/maximum interval.
class TemperatureEnvelopeGalleryCard extends StatelessWidget {
  const TemperatureEnvelopeGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RangeAreaGalleryCard(
    title: 'April temperature envelope',
    subtitle: 'Daily low–high interval · observed mean · gradient fill',
    xAxis: const XAxisConfig(label: 'Day of April'),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Temperature',
      unit: '°C',
    ),
    series: [
      RangeAreaChartSeries(
        id: 'gallery-temperature-range',
        name: 'Daily low–high',
        unit: '°C',
        interpolation: LineInterpolation.monotone,
        color: const Color(0xFF0EA5E9),
        fillOpacity: 0.34,
        fillGradient: const AreaGradient(
          colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        upperBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF0284C7),
          strokeWidth: 1.8,
        ),
        lowerBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF38BDF8),
          strokeWidth: 1.4,
        ),
        showBoundaryMarkers: true,
        markerRadius: 2.6,
        points: [
          RangeAreaDataPoint(x: 1, low: 2.0, high: 12.4),
          RangeAreaDataPoint(x: 2, low: 3.1, high: 13.2),
          RangeAreaDataPoint(x: 3, low: 1.8, high: 11.6),
          RangeAreaDataPoint(x: 4, low: 4.2, high: 15.0),
          RangeAreaDataPoint(x: 5, low: 5.0, high: 16.1),
          RangeAreaDataPoint(x: 6, low: 3.8, high: 14.4),
          RangeAreaDataPoint(x: 7, low: 5.7, high: 17.2),
          RangeAreaDataPoint(x: 8, low: 6.1, high: 18.0),
          RangeAreaDataPoint(x: 9, low: 4.9, high: 16.3),
          RangeAreaDataPoint(x: 10, low: 6.5, high: 18.4),
          RangeAreaDataPoint(x: 11, low: 7.2, high: 19.1),
          RangeAreaDataPoint(x: 12, low: 6.4, high: 18.2),
        ],
      ),
      const LineChartSeries(
        id: 'gallery-temperature-mean',
        name: 'Observed mean',
        unit: '°C',
        color: Color(0xFF2563EB),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.4,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 2.8,
        points: [
          ChartDataPoint(x: 1, y: 7.1),
          ChartDataPoint(x: 2, y: 8.4),
          ChartDataPoint(x: 3, y: 6.9),
          ChartDataPoint(x: 4, y: 9.7),
          ChartDataPoint(x: 5, y: 10.5),
          ChartDataPoint(x: 6, y: 9.0),
          ChartDataPoint(x: 7, y: 11.6),
          ChartDataPoint(x: 8, y: 12.4),
          ChartDataPoint(x: 9, y: 10.8),
          ChartDataPoint(x: 10, y: 12.7),
          ChartDataPoint(x: 11, y: 13.6),
          ChartDataPoint(x: 12, y: 12.9),
        ],
      ),
    ],
  );
}

/// Two interval series express confidence without splitting either boundary
/// into an independently tracked path.
class ForecastFanGalleryCard extends StatelessWidget {
  const ForecastFanGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RangeAreaGalleryCard(
    title: 'Demand forecast fan',
    subtitle: '80% + 50% intervals · widening horizon · median line',
    xAxis: const XAxisConfig(label: 'Forecast horizon'),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Demand',
      unit: 'k',
    ),
    series: [
      RangeAreaChartSeries(
        id: 'gallery-forecast-outer',
        name: '80% interval',
        unit: 'k',
        interpolation: LineInterpolation.monotone,
        color: const Color(0xFF8B5CF6),
        fillOpacity: 0.18,
        upperBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF7C3AED),
          strokeWidth: 1.4,
        ),
        lowerBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFFA78BFA),
          strokeWidth: 1.2,
          dashPattern: [5, 4],
        ),
        points: [
          RangeAreaDataPoint(x: 0, low: 72, high: 84),
          RangeAreaDataPoint(x: 1, low: 73, high: 87),
          RangeAreaDataPoint(x: 2, low: 74, high: 90),
          RangeAreaDataPoint(x: 3, low: 74, high: 93),
          RangeAreaDataPoint(x: 4, low: 75, high: 97),
          RangeAreaDataPoint(x: 5, low: 76, high: 101),
          RangeAreaDataPoint(x: 6, low: 76, high: 106),
          RangeAreaDataPoint(x: 7, low: 77, high: 111),
          RangeAreaDataPoint(x: 8, low: 78, high: 117),
          RangeAreaDataPoint(x: 9, low: 78, high: 123),
        ],
      ),
      RangeAreaChartSeries(
        id: 'gallery-forecast-inner',
        name: '50% interval',
        unit: 'k',
        interpolation: LineInterpolation.monotone,
        color: const Color(0xFF6366F1),
        fillOpacity: 0.3,
        upperBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF4F46E5),
          strokeWidth: 1.5,
        ),
        lowerBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF818CF8),
          strokeWidth: 1.5,
        ),
        points: [
          RangeAreaDataPoint(x: 0, low: 75, high: 82),
          RangeAreaDataPoint(x: 1, low: 76, high: 84),
          RangeAreaDataPoint(x: 2, low: 77, high: 86),
          RangeAreaDataPoint(x: 3, low: 78, high: 89),
          RangeAreaDataPoint(x: 4, low: 80, high: 92),
          RangeAreaDataPoint(x: 5, low: 81, high: 95),
          RangeAreaDataPoint(x: 6, low: 83, high: 99),
          RangeAreaDataPoint(x: 7, low: 84, high: 103),
          RangeAreaDataPoint(x: 8, low: 86, high: 108),
          RangeAreaDataPoint(x: 9, low: 87, high: 113),
        ],
      ),
      const LineChartSeries(
        id: 'gallery-forecast-median',
        name: 'Median',
        unit: 'k',
        color: Color(0xFF312E81),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.4,
        points: [
          ChartDataPoint(x: 0, y: 78),
          ChartDataPoint(x: 1, y: 80),
          ChartDataPoint(x: 2, y: 82),
          ChartDataPoint(x: 3, y: 84),
          ChartDataPoint(x: 4, y: 86),
          ChartDataPoint(x: 5, y: 88),
          ChartDataPoint(x: 6, y: 91),
          ChartDataPoint(x: 7, y: 94),
          ChartDataPoint(x: 8, y: 98),
          ChartDataPoint(x: 9, y: 102),
        ],
      ),
    ],
  );
}

/// A financial composition demonstrates that Range Area remains an ordinary
/// Cartesian series beside an independently tracked close line.
class VolatilityEnvelopeGalleryCard extends StatelessWidget {
  const VolatilityEnvelopeGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RangeAreaGalleryCard(
    title: 'Rolling volatility envelope',
    subtitle: 'Paired price band · close line · typed interval tracking',
    dark: true,
    xAxis: const XAxisConfig(
      label: 'Trading session',
      color: Color(0xFF67E8F9),
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Price',
      unit: 'USD',
      color: const Color(0xFFCBD5E1),
    ),
    series: [
      RangeAreaChartSeries(
        id: 'gallery-volatility-range',
        name: '20-session envelope',
        unit: 'USD',
        interpolation: LineInterpolation.monotone,
        color: const Color(0xFF2DD4BF),
        fillOpacity: 0.22,
        fillGradient: const AreaGradient(
          colors: [Color(0xFF5EEAD4), Color(0xFF0F766E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        upperBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF5EEAD4),
          strokeWidth: 1.5,
        ),
        lowerBoundaryStyle: const RangeAreaBoundaryStyle(
          color: Color(0xFF14B8A6),
          strokeWidth: 1.5,
        ),
        points: [
          RangeAreaDataPoint(x: 0, low: 92, high: 103),
          RangeAreaDataPoint(x: 1, low: 94, high: 106),
          RangeAreaDataPoint(x: 2, low: 96, high: 109),
          RangeAreaDataPoint(x: 3, low: 95, high: 110),
          RangeAreaDataPoint(x: 4, low: 98, high: 113),
          RangeAreaDataPoint(x: 5, low: 101, high: 116),
          RangeAreaDataPoint(x: 6, low: 100, high: 118),
          RangeAreaDataPoint(x: 7, low: 104, high: 122),
          RangeAreaDataPoint(x: 8, low: 108, high: 126),
          RangeAreaDataPoint(x: 9, low: 111, high: 131),
          RangeAreaDataPoint(x: 10, low: 109, high: 133),
          RangeAreaDataPoint(x: 11, low: 114, high: 138),
        ],
      ),
      const LineChartSeries(
        id: 'gallery-volatility-close',
        name: 'Close',
        unit: 'USD',
        color: Color(0xFFF59E0B),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 2.4,
        showDataPointMarkers: true,
        dataPointMarkerRadius: 2.6,
        points: [
          ChartDataPoint(x: 0, y: 98),
          ChartDataPoint(x: 1, y: 101),
          ChartDataPoint(x: 2, y: 104),
          ChartDataPoint(x: 3, y: 102),
          ChartDataPoint(x: 4, y: 108),
          ChartDataPoint(x: 5, y: 112),
          ChartDataPoint(x: 6, y: 109),
          ChartDataPoint(x: 7, y: 116),
          ChartDataPoint(x: 8, y: 121),
          ChartDataPoint(x: 9, y: 119),
          ChartDataPoint(x: 10, y: 126),
          ChartDataPoint(x: 11, y: 132),
        ],
      ),
    ],
  );
}
