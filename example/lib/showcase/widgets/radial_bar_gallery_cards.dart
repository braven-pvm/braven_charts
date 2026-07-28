// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Product-shaped Radial Bar compositions used by the public Gallery.
const radialBarGalleryCards = <Widget>[
  JourneyProgressRadialBarGalleryCard(),
  SignedDriversRadialBarGalleryCard(),
  RegionalProfileRadialBarGalleryCard(),
];

/// Progress against one explicit target with value callouts.
class JourneyProgressRadialBarGalleryCard extends StatelessWidget {
  const JourneyProgressRadialBarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RadialBarGalleryCard(
    key: const ValueKey('gallery-radial-bar-journey-progress'),
    title: 'Customer journey',
    subtitle: 'Explicit 0–100 domain · target · value callouts',
    series: RadialBarChartSeries.fromMap(
      id: 'gallery-radial-bar-journey',
      name: 'Journey progress',
      unit: '%',
      values: const {
        'Activation': 92,
        'Retention': 78,
        'Adoption': 66,
        'Satisfaction': 84,
        'Expansion': 57,
      },
      barColors: const {
        'Activation': Color(0xFF2563EB),
        'Retention': Color(0xFF0891B2),
        'Adoption': Color(0xFF0D9488),
        'Satisfaction': Color(0xFF16A34A),
        'Expansion': Color(0xFFF59E0B),
      },
      radialBarStyle: const RadialBarStyle(
        cornerRadius: 8,
        trackOpacity: 0.1,
        gradient: RadialBarGradientStyle(
          type: RadialBarGradientType.sweep,
          startLightnessShift: 0.12,
          endLightnessShift: -0.12,
        ),
        dataLabels: RadialBarDataLabelConfig(
          position: RadialBarDataLabelPosition.outsideCallout,
          content: RadialBarDataLabelContent.categoryAndValue,
          colorMode: RadialBarDataLabelColorMode.fixed,
          textStyle: PolarLabelStyle(
            color: Color(0xFF172033),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          showPanel: true,
          connectorLength: 16,
        ),
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.06,
        liftOffset: 4,
        backdropBlur: 1,
      ),
    ),
    config: const RadialBarChartConfig(
      pane: PolarPaneConfig(innerRadiusFactor: 0.22, outerRadiusFactor: 0.72),
      trackGap: 6,
      showCategoryLabels: false,
      thresholds: [
        RadialBarThreshold(
          value: 75,
          label: 'Target',
          color: Color(0xFF0EA5E9),
        ),
      ],
    ),
  );
}

/// Signed contribution drivers around a shared zero baseline.
class SignedDriversRadialBarGalleryCard extends StatelessWidget {
  const SignedDriversRadialBarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    return _RadialBarGalleryCard(
      key: const ValueKey('gallery-radial-bar-signed-drivers'),
      title: 'Growth drivers',
      subtitle: 'Signed baseline · partial pane · compact legend',
      theme: base.copyWith(
        backgroundColor: const Color(0xFF111827),
        legendStyle: base.legendStyle.copyWith(
          position: LegendPosition.bottomCenter,
          orientation: LegendOrientation.horizontal,
          markerShape: LegendMarkerShape.line,
          markerSize: 9,
          itemSpacing: 4,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          textStyle: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 9),
        ),
      ),
      showLegend: true,
      series: RadialBarChartSeries.fromMap(
        id: 'gallery-radial-bar-signed',
        name: 'Contribution',
        unit: 'pts',
        minimum: -100,
        maximum: 100,
        baseline: 0,
        values: const {
          'Acquisition': 64,
          'Support': -36,
          'Reliability': 82,
          'Churn': -52,
        },
        barColors: const {
          'Acquisition': Color(0xFF38BDF8),
          'Support': Color(0xFFFB7185),
          'Reliability': Color(0xFF34D399),
          'Churn': Color(0xFFFBBF24),
        },
        radialBarStyle: const RadialBarStyle(
          cornerRadius: 9,
          trackOpacity: 0.16,
          gradient: RadialBarGradientStyle(
            type: RadialBarGradientType.radial,
            startLightnessShift: 0.16,
            endLightnessShift: -0.1,
          ),
          dataLabels: RadialBarDataLabelConfig(
            position: RadialBarDataLabelPosition.insideEnd,
            content: RadialBarDataLabelContent.value,
          ),
        ),
      ),
      config: const RadialBarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -135,
          sweepAngleDegrees: 270,
          innerRadiusFactor: 0.22,
          outerRadiusFactor: 0.74,
        ),
        trackGap: 7,
        categoryLabels: RadialBarCategoryLabelConfig(
          position: RadialBarCategoryLabelPosition.startGap,
          offset: 8,
          textStyle: PolarLabelStyle(color: Color(0xFFE2E8F0), fontSize: 9),
        ),
        showScaleLabels: false,
        thresholds: [
          RadialBarThreshold(value: 50, label: '+50', color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

/// Dense category tracks that exercise collision-aware category labels.
class RegionalProfileRadialBarGalleryCard extends StatelessWidget {
  const RegionalProfileRadialBarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _RadialBarGalleryCard(
    key: const ValueKey('gallery-radial-bar-regional-profile'),
    title: 'Regional operating profile',
    subtitle: '12 tracks · rotated start · collision-aware categories',
    series: RadialBarChartSeries.fromMap(
      id: 'gallery-radial-bar-regions',
      name: 'Regional score',
      unit: '%',
      values: const {
        'North': 91,
        'North-east': 74,
        'East': 86,
        'South-east': 69,
        'South': 82,
        'South-west': 63,
        'West': 78,
        'North-west': 56,
        'Central': 72,
        'Remote': 48,
        'Partner': 61,
        'Direct': 39,
      },
      radialBarStyle: const RadialBarStyle(
        cornerRadius: 5,
        trackOpacity: 0.09,
        showDataLabels: false,
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.04,
        liftOffset: 5,
        backdropBlur: 0.5,
      ),
    ),
    config: const RadialBarChartConfig(
      pane: PolarPaneConfig(
        startAngleDegrees: -70,
        innerRadiusFactor: 0.1,
        outerRadiusFactor: 0.82,
      ),
      trackGap: 3,
      categoryLabels: RadialBarCategoryLabelConfig(
        position: RadialBarCategoryLabelPosition.outsideCallout,
        offset: 4,
        textStyle: PolarLabelStyle(fontSize: 9),
        connectorLength: 12,
        connectorWidth: 1,
      ),
      showScaleLabels: false,
      tickCount: 4,
    ),
  );
}

class _RadialBarGalleryCard extends StatelessWidget {
  const _RadialBarGalleryCard({
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
  final RadialBarChartSeries series;
  final RadialBarChartConfig config;
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
                radialBarChartConfig: config,
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
