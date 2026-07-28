// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Product-shaped Gauge compositions used by the public Gallery.
const gaugeGalleryCards = <Widget>[
  OperationsHealthGaugeGalleryCard(),
  ReleaseConfidenceGaugeGalleryCard(),
  RecoveryWindowGaugeGalleryCard(),
];

/// A needle Gauge with semantic zones and distinct references.
class OperationsHealthGaugeGalleryCard extends StatelessWidget {
  const OperationsHealthGaugeGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _GaugeGalleryCard(
    key: const ValueKey('gallery-gauge-operations-health'),
    title: 'Operations health',
    subtitle: 'Needle · semantic zones · target and alert',
    series: GaugeChartSeries.needle(
      id: 'gallery-gauge-operations',
      name: 'Live operations',
      metric: 'CPU utilization',
      value: 72,
      minimum: 0,
      maximum: 100,
      unit: '%',
      target: const GaugeTarget(value: 65, label: 'Target'),
      thresholds: const [
        GaugeThreshold(value: 90, label: 'Alert', dashPattern: [5, 3]),
      ],
      zones: const [
        GaugeZone(from: 0, to: 60, status: 'Healthy', color: Color(0xFF16A34A)),
        GaugeZone(
          from: 60,
          to: 85,
          status: 'Elevated',
          color: Color(0xFFF59E0B),
        ),
        GaugeZone(
          from: 85,
          to: 100,
          status: 'Critical',
          color: Color(0xFFDC2626),
        ),
      ],
      style: const NeedleGaugeStyle(
        needleWidth: 4,
        pivotRadius: 7,
        axisThickness: 13,
      ),
    ),
    config: const GaugeChartConfig(
      pane: PolarPaneConfig(startAngleDegrees: -150, sweepAngleDegrees: 300),
      center: GaugeCenterConfig(
        showTarget: true,
        valueStyle: PolarLabelStyle(fontSize: 30, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// A portable sweep gradient with a compact informational legend.
class ReleaseConfidenceGaugeGalleryCard extends StatelessWidget {
  const ReleaseConfidenceGaugeGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.corporateBlue;
    return _GaugeGalleryCard(
      key: const ValueKey('gallery-gauge-release-confidence'),
      title: 'Release confidence',
      subtitle: 'Sweep gradient · raised legend · compact dashboard',
      showLegend: true,
      theme: base.copyWith(
        legendStyle: base.legendStyle.copyWith(
          position: LegendPosition.centerRight,
          orientation: LegendOrientation.vertical,
          markerShape: LegendMarkerShape.diamond,
          markerSize: 12,
          backgroundColor: const Color(0xF7FFFFFF),
          borderColor: const Color(0xFFBFDBFE),
          borderWidth: 1,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          textStyle: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 10),
        ),
      ),
      series: GaugeChartSeries.solid(
        id: 'gallery-gauge-release',
        name: 'Release readiness',
        metric: 'Confidence',
        value: 84,
        minimum: 0,
        maximum: 100,
        unit: '%',
        color: const Color(0xFF2563EB),
        target: const GaugeTarget(value: 80, label: 'Ship'),
        zones: const [
          GaugeZone(from: 0, to: 60, status: 'Hold'),
          GaugeZone(from: 60, to: 80, status: 'Review'),
          GaugeZone(from: 80, to: 100, status: 'Ready'),
        ],
        style: const SolidGaugeStyle(
          trackOpacity: 0.08,
          cornerRadius: 14,
          gradient: GaugeGradientStyle(
            type: GaugeGradientType.sweep,
            startColor: Color(0xFF22D3EE),
            endColor: Color(0xFF4F46E5),
          ),
        ),
      ),
      config: const GaugeChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -120,
          sweepAngleDegrees: 240,
          innerRadiusFactor: 0.6,
          outerRadiusFactor: 0.9,
        ),
        showZones: false,
        colorIndicatorByActiveZone: false,
        center: GaugeCenterConfig(showTarget: true),
      ),
    );
  }
}

/// A high-contrast partial Gauge that remains useful without a legend.
class RecoveryWindowGaugeGalleryCard extends StatelessWidget {
  const RecoveryWindowGaugeGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    return _GaugeGalleryCard(
      key: const ValueKey('gallery-gauge-recovery-window'),
      title: 'Recovery window',
      subtitle: 'Partial sweep · dark theme · explicit status',
      theme: base.copyWith(
        backgroundColor: const Color(0xFF111827),
        animationTheme: base.animationTheme.copyWith(
          dataUpdateDuration: const Duration(milliseconds: 650),
          dataUpdateCurve: Curves.easeOutCubic,
        ),
      ),
      series: GaugeChartSeries.solid(
        id: 'gallery-gauge-recovery',
        name: 'Recovery confidence',
        metric: 'Recovery',
        value: 58,
        minimum: 0,
        maximum: 100,
        unit: '%',
        color: const Color(0xFF38BDF8),
        target: const GaugeTarget(
          value: 75,
          label: 'Goal',
          color: Color(0xFFFBBF24),
          width: 4,
        ),
        zones: const [
          GaugeZone(from: 0, to: 45, status: 'Low'),
          GaugeZone(from: 45, to: 75, status: 'Recovering'),
          GaugeZone(from: 75, to: 100, status: 'Ready'),
        ],
        style: const SolidGaugeStyle(
          trackColor: Color(0xFF334155),
          trackOpacity: 0.45,
          cornerRadius: 10,
          borderColor: Color(0xFF7DD3FC),
          borderWidth: 1,
          gradient: GaugeGradientStyle(
            type: GaugeGradientType.radial,
            startLightnessShift: 0.18,
            endLightnessShift: -0.08,
          ),
        ),
      ),
      config: const GaugeChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -90,
          sweepAngleDegrees: 180,
          innerRadiusFactor: 0.58,
          outerRadiusFactor: 0.88,
        ),
        showTickLabels: false,
        showZones: false,
        colorIndicatorByActiveZone: false,
        center: GaugeCenterConfig(
          showTarget: true,
          metricStyle: PolarLabelStyle(color: Color(0xFFBAE6FD)),
          valueStyle: PolarLabelStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          statusStyle: PolarLabelStyle(
            color: Color(0xFFFBBF24),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GaugeGalleryCard extends StatelessWidget {
  const _GaugeGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.series,
    required this.config,
    this.theme,
    this.showLegend = false,
  });

  final String title;
  final String subtitle;
  final GaugeChartSeries series;
  final GaugeChartConfig config;
  final ChartTheme? theme;
  final bool showLegend;

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
                series: [series],
                gaugeChartConfig: config,
                theme: resolvedTheme,
                showLegend: showLegend,
                grid: const GridConfig(horizontal: false, vertical: false),
                interactionConfig: const InteractionConfig(
                  crosshair: CrosshairConfig(enabled: false),
                  tooltip: TooltipConfig(
                    enabled: true,
                    triggerMode: TooltipTriggerMode.both,
                  ),
                  enableZoom: false,
                  enablePan: false,
                  enableSelection: false,
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
