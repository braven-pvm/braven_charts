// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Production-shaped Candlestick composition used by the Gallery and release
/// media harness.
class CandlestickMarketGalleryCard extends StatelessWidget {
  const CandlestickMarketGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final candles = _marketCandles;
    return Card(
      color: const Color(0xFF101827),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Candlestick market structure',
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Typed OHLC · moving average · event window · tracking',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BravenChartPlus(
                series: [
                  CandlestickChartSeries(
                    id: 'market-price',
                    name: 'Price',
                    points: candles,
                    candlestickStyle: const CandlestickChartStyle(
                      bodyFillMode: CandlestickBodyFillMode.filled,
                      bodyWidthFactor: 0.66,
                      maxBodyWidth: 14,
                      bodyCornerRadius: 2,
                    ),
                  ),
                  LineChartSeries(
                    id: 'market-average',
                    name: 'MA 5',
                    points: _movingAverage(candles, 5),
                    color: const Color(0xFFFBBF24),
                    interpolation: LineInterpolation.monotone,
                    strokeWidth: 2,
                  ),
                ],
                annotations: [
                  RangeAnnotation(
                    id: 'earnings-window',
                    startX: 14,
                    endX: 18,
                    label: 'Earnings window',
                    fillColor: const Color(0x2222D3EE),
                    borderColor: const Color(0xFF22D3EE),
                    style: const AnnotationStyle(
                      textStyle: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Color(0xCC0F172A),
                    ),
                  ),
                  ThresholdAnnotation(
                    id: 'breakout-level',
                    axis: AnnotationAxis.y,
                    value: 118,
                    label: 'Breakout',
                    lineColor: const Color(0xFFA78BFA),
                    dashPattern: [6, 4],
                    style: const AnnotationStyle(
                      textStyle: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Color(0xCC0F172A),
                    ),
                  ),
                ],
                theme: ChartTheme.dark.copyWith(
                  backgroundColor: const Color(0xFF101827),
                ),
                showLegend: true,
                grid: const GridConfig(
                  horizontal: true,
                  vertical: true,
                  horizontalColor: Color(0x1FFFFFFF),
                  verticalColor: Color(0x12FFFFFF),
                ),
                xAxisConfig: const XAxisConfig(label: 'Session'),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Price',
                  unit: 'USD',
                ),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.both,
                    snapToDataPoint: true,
                    displayMode: CrosshairDisplayMode.tracking,
                  ),
                  tooltip: TooltipConfig(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent, family-aware value summary composition used by the Gallery and
/// release media harness.
class ValueSummaryGalleryCard extends StatelessWidget {
  const ValueSummaryGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Persistent value summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Family-aware rows · latest/tracking policy · independent feedback layers',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BravenChartPlus(
                series: const [
                  AreaChartSeries(
                    id: 'readiness-band',
                    name: 'Readiness',
                    unit: '%',
                    points: _readinessPoints,
                    color: Color(0xFF14B8A6),
                    interpolation: LineInterpolation.monotone,
                    fillOpacity: 0.16,
                    strokeWidth: 2,
                  ),
                  LineChartSeries(
                    id: 'training-load',
                    name: 'Training load',
                    unit: 'AU',
                    points: _loadPoints,
                    color: Color(0xFF6366F1),
                    interpolation: LineInterpolation.monotone,
                    strokeWidth: 3,
                    showDataPointMarkers: true,
                    dataPointMarkerRadius: 3,
                  ),
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'target-readiness',
                    axis: AnnotationAxis.y,
                    value: 62,
                    label: 'Target',
                    lineColor: const Color(0xFFF59E0B),
                    dashPattern: [6, 4],
                  ),
                ],
                theme: ChartTheme.light,
                showLegend: true,
                xAxisConfig: const XAxisConfig(label: 'Day'),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Score',
                ),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(
                    enabled: true,
                    mode: CrosshairMode.vertical,
                    showCoordinateLabels: false,
                    showIntersectionMarkers: true,
                  ),
                  tooltip: TooltipConfig(enabled: false),
                  valueSummary: CartesianValueSummaryConfig(
                    enabled: true,
                    presentation: CartesianValueSummaryPresentation.overlay(
                      placement: ChartOverlayPlacement.topLeft,
                    ),
                    valuePolicy:
                        CartesianValueSummaryValuePolicy.trackingThenLatest,
                    valueMode: CartesianValueSummaryValueMode.dataPoints,
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

final List<CandlestickDataPoint> _marketCandles = List.unmodifiable(
  List.generate(32, (index) {
    final trend = 96 + index * 0.9;
    final wave = math.sin(index * 0.62) * 5.2;
    final open = trend + wave + math.cos(index * 0.37) * 1.4;
    final close = trend + math.sin((index + 0.72) * 0.62) * 5.2;
    final spread = 2.1 + (index % 4) * 0.45;
    return CandlestickDataPoint(
      x: index.toDouble(),
      open: open,
      high: math.max(open, close) + spread,
      low: math.min(open, close) - spread * 0.85,
      close: close,
    );
  }),
);

List<ChartDataPoint> _movingAverage(
  List<CandlestickDataPoint> candles,
  int window,
) => List.generate(candles.length - window + 1, (index) {
  final end = index + window;
  final average =
      candles
          .sublist(index, end)
          .fold<double>(0, (sum, point) => sum + point.close) /
      window;
  return ChartDataPoint(x: candles[end - 1].x, y: average);
});

const _readinessPoints = [
  ChartDataPoint(x: 0, y: 72),
  ChartDataPoint(x: 1, y: 68),
  ChartDataPoint(x: 2, y: 64),
  ChartDataPoint(x: 3, y: 61),
  ChartDataPoint(x: 4, y: 58),
  ChartDataPoint(x: 5, y: 60),
  ChartDataPoint(x: 6, y: 65),
  ChartDataPoint(x: 7, y: 70),
  ChartDataPoint(x: 8, y: 74),
  ChartDataPoint(x: 9, y: 76),
  ChartDataPoint(x: 10, y: 73),
  ChartDataPoint(x: 11, y: 69),
];

const _loadPoints = [
  ChartDataPoint(x: 0, y: 44),
  ChartDataPoint(x: 1, y: 49),
  ChartDataPoint(x: 2, y: 57),
  ChartDataPoint(x: 3, y: 63),
  ChartDataPoint(x: 4, y: 70),
  ChartDataPoint(x: 5, y: 76),
  ChartDataPoint(x: 6, y: 69),
  ChartDataPoint(x: 7, y: 61),
  ChartDataPoint(x: 8, y: 55),
  ChartDataPoint(x: 9, y: 52),
  ChartDataPoint(x: 10, y: 58),
  ChartDataPoint(x: 11, y: 66),
];
