// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Product-shaped Polar Column compositions used by the Gallery and media.
const polarColumnGalleryCards = <Widget>[
  ChannelMagnitudePolarGalleryCard(),
  SeasonalRoseGalleryCard(),
  LifecycleArcPolarGalleryCard(),
];

/// Deterministic, navigation-free panel for package and pub.dev media capture.
class PolarColumnGalleryMediaPanel extends StatelessWidget {
  const PolarColumnGalleryMediaPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final (index, card) in polarColumnGalleryCards.indexed) ...[
              if (index > 0) const SizedBox(width: 16),
              Expanded(child: card),
            ],
          ],
        ),
      ),
    );
  }
}

/// A direct category-magnitude comparison on a complete linear radial scale.
class ChannelMagnitudePolarGalleryCard extends StatelessWidget {
  const ChannelMagnitudePolarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _PolarGalleryCard(
    key: const ValueKey('gallery-polar-channel-magnitude'),
    title: 'Channel demand',
    subtitle: 'Linear radius · category axis · exact values',
    series: PolarColumnChartSeries.fromMap(
      id: 'gallery-polar-channel-series',
      name: 'Requests',
      unit: 'k requests',
      values: const {
        'Search': 86,
        'Social': 58,
        'Partners': 72,
        'Email': 44,
        'Events': 65,
        'Direct': 92,
        'Referral': 54,
        'Other': 36,
      },
      columnColors: const {
        'Search': Color(0xFF2563EB),
        'Social': Color(0xFF0284C7),
        'Partners': Color(0xFF0891B2),
        'Email': Color(0xFF0D9488),
        'Events': Color(0xFF16A34A),
        'Direct': Color(0xFFF59E0B),
        'Referral': Color(0xFFF97316),
        'Other': Color(0xFFE11D48),
      },
      polarStyle: const PolarColumnStyle(
        cornerRadius: 5,
        opacity: 0.95,
        borderColor: Color(0xFF334155),
        borderWidth: 0.75,
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.06,
        liftOffset: 5,
        backdropBlur: 0.8,
      ),
    ),
    config: const PolarChartConfig(
      pane: PolarPaneConfig(outerRadiusFactor: 0.82),
      angularAxis: PolarCategoryAxisConfig(innerPadding: 0.12),
      radialAxis: PolarNumericAxisConfig(
        maximum: 100,
        scaleMode: PolarRadialScaleMode.linear,
        tickCount: 5,
      ),
    ),
  );
}

/// A Nightingale/Rose view where sector area—not raw radius—tracks magnitude.
class SeasonalRoseGalleryCard extends StatelessWidget {
  const SeasonalRoseGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    return _PolarGalleryCard(
      key: const ValueKey('gallery-polar-seasonal-rose'),
      title: 'Seasonal request profile',
      subtitle: 'Nightingale rose · area-correct scale · 12 months',
      theme: base.copyWith(backgroundColor: const Color(0xFF111827)),
      series: PolarColumnChartSeries.rose(
        id: 'gallery-polar-seasonal-series',
        name: 'Monthly volume',
        unit: 'k requests',
        values: const {
          'Jan': 42,
          'Feb': 58,
          'Mar': 76,
          'Apr': 63,
          'May': 88,
          'Jun': 54,
          'Jul': 97,
          'Aug': 82,
          'Sep': 69,
          'Oct': 74,
          'Nov': 49,
          'Dec': 61,
        },
        columnColors: const {
          'Jan': Color(0xFF38BDF8),
          'Feb': Color(0xFF22D3EE),
          'Mar': Color(0xFF2DD4BF),
          'Apr': Color(0xFF34D399),
          'May': Color(0xFFA3E635),
          'Jun': Color(0xFFFACC15),
          'Jul': Color(0xFFFB923C),
          'Aug': Color(0xFFFB7185),
          'Sep': Color(0xFFE879F9),
          'Oct': Color(0xFFC084FC),
          'Nov': Color(0xFF818CF8),
          'Dec': Color(0xFF60A5FA),
        },
        polarStyle: const PolarColumnStyle(
          cornerRadius: 7,
          opacity: 0.94,
          borderColor: Color(0xFFCBD5E1),
          borderWidth: 0.6,
          showDataLabels: false,
        ),
      ),
      config: const PolarChartConfig(
        pane: PolarPaneConfig(innerRadiusFactor: 0.08, outerRadiusFactor: 0.84),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: 0.08,
          outerPadding: 0,
          showLabels: true,
          showGridLines: false,
        ),
        radialAxis: PolarNumericAxisConfig(
          maximum: 100,
          scaleMode: PolarRadialScaleMode.areaCorrect,
          tickCount: 4,
          showLabels: false,
          showGridLines: true,
        ),
      ),
    );
  }
}

/// A partial annular pane that demonstrates start, sweep, and direction.
class LifecycleArcPolarGalleryCard extends StatelessWidget {
  const LifecycleArcPolarGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _PolarGalleryCard(
    key: const ValueKey('gallery-polar-lifecycle-arc'),
    title: 'Lifecycle conversion',
    subtitle: '240° sweep · annular baseline · lifted selection',
    series: PolarColumnChartSeries.fromMap(
      id: 'gallery-polar-lifecycle-series',
      name: 'Stage completion',
      unit: '%',
      values: const {
        'Discover': 84,
        'Evaluate': 62,
        'Trial': 73,
        'Adopt': 91,
        'Expand': 66,
        'Renew': 79,
      },
      columnColors: const {
        'Discover': Color(0xFF4F46E5),
        'Evaluate': Color(0xFF7C3AED),
        'Trial': Color(0xFF9333EA),
        'Adopt': Color(0xFFE11D48),
        'Expand': Color(0xFFF97316),
        'Renew': Color(0xFFF59E0B),
      },
      polarStyle: const PolarColumnStyle(
        cornerRadius: 9,
        opacity: 0.96,
        borderColor: Color(0xFF312E81),
        borderWidth: 0.8,
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.07,
        liftOffset: 7,
        backdropBlur: 1,
      ),
    ),
    config: const PolarChartConfig(
      pane: PolarPaneConfig(
        startAngleDegrees: 150,
        sweepAngleDegrees: 240,
        innerRadiusFactor: 0.28,
        outerRadiusFactor: 0.88,
      ),
      angularAxis: PolarCategoryAxisConfig(
        innerPadding: 0.14,
        outerPadding: 0.08,
      ),
      radialAxis: PolarNumericAxisConfig(
        maximum: 100,
        scaleMode: PolarRadialScaleMode.linear,
        tickCount: 5,
      ),
    ),
  );
}

class _PolarGalleryCard extends StatelessWidget {
  const _PolarGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.series,
    required this.config,
    this.theme,
  });

  final String title;
  final String subtitle;
  final PolarColumnChartSeries series;
  final PolarChartConfig config;
  final ChartTheme? theme;

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
                polarChartConfig: config,
                theme: resolvedTheme,
                showLegend: false,
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
