// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

const _compactDonutCalloutStyle = LabelStyle(
  textStyle: TextStyle(fontSize: 10),
  backgroundColor: Colors.transparent,
  borderColor: Colors.transparent,
  borderWidth: 0,
  borderRadius: 0,
  padding: EdgeInsets.zero,
);

/// Reusable Donut compositions shown in the public Gallery and package media.
const donutGalleryCards = <Widget>[
  RevenueRingGalleryCard(),
  DeliveryProgressGalleryCard(),
  CampaignReachGalleryCard(),
];

/// Reusable Concentric Donut compositions shown in the Gallery and media.
const concentricDonutGalleryCards = <Widget>[
  ConcentricMixGalleryCard(),
  ConcentricHealthGalleryCard(),
  ConcentricPortfolioGalleryCard(),
];

/// A deterministic, navigation-free panel for pub.dev media capture.
class DonutGalleryMediaPanel extends StatelessWidget {
  const DonutGalleryMediaPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final (index, card) in donutGalleryCards.indexed) ...[
              if (index > 0) const SizedBox(width: 16),
              Expanded(child: card),
            ],
          ],
        ),
      ),
    );
  }
}

/// A deterministic, navigation-free Concentric Donut media panel.
class ConcentricDonutGalleryMediaPanel extends StatelessWidget {
  const ConcentricDonutGalleryMediaPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final (index, card)
                in concentricDonutGalleryCards.indexed) ...[
              if (index > 0) const SizedBox(width: 16),
              Expanded(child: card),
            ],
          ],
        ),
      ),
    );
  }
}

/// A subscription mix whose center follows durable selection.
class RevenueRingGalleryCard extends StatelessWidget {
  const RevenueRingGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.corporateBlue;
    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-revenue'),
      title: 'Subscription MRR',
      subtitle: 'Plan mix · selection-aware center',
      showLegend: false,
      theme: base.copyWith(
        seriesTheme: base.seriesTheme.copyWith(
          colors: const [
            Color(0xFF2563EB),
            Color(0xFF0F9F92),
            Color(0xFF7C3AED),
            Color(0xFFF59E0B),
            Color(0xFF64748B),
          ],
        ),
      ),
      series: DonutChartSeries.fromMap(
        id: 'gallery-donut-revenue-series',
        name: 'Monthly recurring revenue',
        unit: 'k USD',
        values: const {
          'Starter': 18,
          'Teams': 29,
          'Business': 43,
          'Enterprise': 38,
        },
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.7,
          radiusFactor: 0.82,
          sliceGap: 2,
          cornerRadius: 7,
          borderWidth: 1,
          borderColorMode: PieBorderColorMode.slice,
          gradient: PieGradientStyle(type: PieGradientType.radial),
        ),
        centerContent: const DonutCenterContent(
          label: 'MRR',
          valueMode: DonutCenterValueMode.selectedOrTotal,
          labelStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFF64748B), fontSize: 10),
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
          valueStyle: LabelStyle(
            textStyle: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.outside,
          content: PieDataLabelContent.categoryAndPercentage,
          minimumShare: 0.1,
          calloutStyle: _compactDonutCalloutStyle,
        ),
      ),
    );
  }
}

/// A partial Donut that uses the center as a portable readiness summary.
class DeliveryProgressGalleryCard extends StatelessWidget {
  const DeliveryProgressGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    final theme = base.copyWith(
      backgroundColor: const Color(0xFF111827),
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFF34D399),
          Color(0xFF38BDF8),
          Color(0xFFFBBF24),
          Color(0xFFFB7185),
        ],
      ),
    );
    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-progress'),
      title: 'Release readiness',
      subtitle: '270° status sweep · compact callouts',
      theme: theme,
      showLegend: false,
      series: DonutChartSeries.fromMap(
        id: 'gallery-donut-progress-series',
        name: 'Release checks',
        unit: '%',
        values: const {
          'Ready': 68,
          'In review': 17,
          'At risk': 10,
          'Blocked': 5,
        },
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.66,
          startAngleDegrees: 135,
          sweepAngleDegrees: 270,
          radiusFactor: 0.84,
          sliceGap: 3,
          cornerRadius: 10,
          gradient: PieGradientStyle(
            type: PieGradientType.linear,
            angleDegrees: -45,
          ),
        ),
        centerContent: const DonutCenterContent(
          label: 'Release',
          valueMode: DonutCenterValueMode.custom,
          customValue: '85% ready',
          labelStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            backgroundColor: Color(0x00000000),
            borderColor: Color(0x00000000),
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
          valueStyle: LabelStyle(
            textStyle: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Color(0x00000000),
            borderColor: Color(0x00000000),
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.09,
          calloutStyle: _compactDonutCalloutStyle,
        ),
      ),
    );
  }
}

/// Angle communicates conversions while radius communicates audience reach.
class CampaignReachGalleryCard extends StatelessWidget {
  const CampaignReachGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.light;
    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-reach'),
      title: 'Channel efficiency',
      subtitle: 'Angle = orders · radius = audience reach',
      showLegend: false,
      theme: base.copyWith(
        seriesTheme: base.seriesTheme.copyWith(
          colors: const [
            Color(0xFF0E7490),
            Color(0xFF0891B2),
            Color(0xFF06B6D4),
            Color(0xFF22D3EE),
            Color(0xFF67E8F9),
          ],
        ),
      ),
      series: DonutChartSeries.fromMap(
        id: 'gallery-donut-reach-series',
        name: 'Channels',
        unit: 'orders',
        values: const {
          'Search': 816,
          'Partners': 600,
          'Events': 432,
          'Social': 360,
          'Email': 192,
        },
        radiusValues: const {
          'Search': 78,
          'Partners': 92,
          'Events': 52,
          'Social': 66,
          'Email': 44,
        },
        sliceRadiusConfig: const RadialSliceRadiusConfig(
          minimumFactor: 0.42,
          label: 'Audience reach',
          unit: 'k users',
        ),
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.32,
          radiusFactor: 0.88,
          sliceGap: 3,
          cornerRadius: 9,
          cornerTreatment: PieCornerTreatment.circularCenter,
          gradient: PieGradientStyle(type: PieGradientType.radial),
        ),
        centerContent: const DonutCenterContent(
          label: 'Orders',
          valueMode: DonutCenterValueMode.custom,
          customValue: '2.4k',
          labelStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFF64748B), fontSize: 10),
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
          valueStyle: LabelStyle(
            textStyle: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.category,
          minimumShare: 0.07,
          calloutStyle: _compactDonutCalloutStyle,
        ),
      ),
    );
  }
}

/// Three independent period totals sharing one compact radial comparison.
class ConcentricMixGalleryCard extends StatelessWidget {
  const ConcentricMixGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.corporateBlue;
    final theme = base.copyWith(
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFF2563EB),
          Color(0xFF14B8A6),
          Color(0xFFF59E0B),
          Color(0xFF8B5CF6),
        ],
      ),
    );
    const hiddenLabels = PieDataLabelConfig(isVisible: false);
    const ringStyle = DonutChartStyle(
      sliceGap: 2,
      cornerRadius: 5,
      borderWidth: 1,
      borderColorMode: PieBorderColorMode.slice,
      gradient: PieGradientStyle(type: PieGradientType.radial),
    );

    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-concentric'),
      title: 'Revenue mix over time',
      subtitle: '3 independent totals · weighted concentric rings',
      showLegend: false,
      theme: theme,
      concentricDonutConfig: const ConcentricDonutConfig(
        innerRadiusFactor: 0.28,
        outerRadiusFactor: 0.88,
        ringGap: 4,
        ringWeights: {
          'gallery-concentric-current': 1.2,
          'gallery-concentric-prior': 1,
          'gallery-concentric-baseline': 0.8,
        },
        centerContent: DonutCenterContent(
          label: 'Comparison',
          valueMode: DonutCenterValueMode.custom,
          customValue: '3 rings',
        ),
      ),
      concentricSeries: [
        DonutChartSeries.fromMap(
          id: 'gallery-concentric-current',
          name: 'Current quarter',
          unit: 'k USD',
          values: const {'Direct': 58, 'Partners': 27, 'Expansion': 15},
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
        DonutChartSeries.fromMap(
          id: 'gallery-concentric-prior',
          name: 'Previous quarter',
          unit: 'k USD',
          values: const {'Direct': 49, 'Partners': 33, 'Expansion': 18},
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
        DonutChartSeries.fromMap(
          id: 'gallery-concentric-baseline',
          name: 'Last year',
          unit: 'k USD',
          values: const {'Direct': 42, 'Partners': 38, 'Expansion': 20},
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
      ],
    );
  }
}

/// Three service regions compared as compact, partial status rings.
class ConcentricHealthGalleryCard extends StatelessWidget {
  const ConcentricHealthGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.light;
    final theme = base.copyWith(
      backgroundColor: const Color(0xFFFFFBF5),
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [Color(0xFF16A34A), Color(0xFFF59E0B), Color(0xFFEF4444)],
      ),
    );
    const hiddenLabels = PieDataLabelConfig(isVisible: false);
    const ringStyle = DonutChartStyle(
      startAngleDegrees: 135,
      sweepAngleDegrees: 270,
      sliceGap: 3,
      cornerRadius: 8,
      borderWidth: 1,
      borderColorMode: PieBorderColorMode.slice,
      gradient: PieGradientStyle(
        type: PieGradientType.linear,
        angleDegrees: -35,
      ),
    );

    return _DonutGalleryCard(
      key: const ValueKey('gallery-concentric-health'),
      title: 'Service-level health',
      subtitle: '3 regions · 270° status rings · shared categories',
      showLegend: false,
      theme: theme,
      concentricDonutConfig: const ConcentricDonutConfig(
        innerRadiusFactor: 0.3,
        outerRadiusFactor: 0.88,
        ringGap: 5,
        centerContent: DonutCenterContent(
          label: 'SLO status',
          valueMode: DonutCenterValueMode.custom,
          customValue: '3 zones',
        ),
      ),
      concentricSeries: [
        DonutChartSeries.fromMap(
          id: 'gallery-health-core',
          name: 'Core platform',
          unit: '%',
          values: const {'Healthy': 91, 'Watch': 7, 'Breach': 2},
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
        DonutChartSeries.fromMap(
          id: 'gallery-health-data',
          name: 'Data services',
          unit: '%',
          values: const {'Healthy': 78, 'Watch': 16, 'Breach': 6},
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
        DonutChartSeries.fromMap(
          id: 'gallery-health-edge',
          name: 'Edge delivery',
          unit: '%',
          values: const {'Healthy': 84, 'Watch': 11, 'Breach': 5},
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
      ],
    );
  }
}

/// Weighted rings compare allocation across independent investment mandates.
class ConcentricPortfolioGalleryCard extends StatelessWidget {
  const ConcentricPortfolioGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    final theme = base.copyWith(
      backgroundColor: const Color(0xFF101827),
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFF22D3EE),
          Color(0xFFA78BFA),
          Color(0xFF34D399),
          Color(0xFFFBBF24),
        ],
      ),
    );
    const hiddenLabels = PieDataLabelConfig(isVisible: false);
    const ringStyle = DonutChartStyle(
      sliceGap: 2.5,
      cornerRadius: 7,
      borderWidth: 1,
      borderColorMode: PieBorderColorMode.slice,
      gradient: PieGradientStyle(type: PieGradientType.radial),
      shadow: PieElevationStyle(
        color: Color(0x5538BDF8),
        blurRadius: 8,
        spreadRadius: 1,
        opacity: 0.55,
      ),
    );

    return _DonutGalleryCard(
      key: const ValueKey('gallery-concentric-portfolio'),
      title: 'Portfolio allocation',
      subtitle: 'Weighted rings · independent mandates · dark theme',
      showLegend: false,
      theme: theme,
      concentricDonutConfig: const ConcentricDonutConfig(
        innerRadiusFactor: 0.26,
        outerRadiusFactor: 0.89,
        ringGap: 5,
        ringWeights: {
          'gallery-portfolio-growth': 1.25,
          'gallery-portfolio-balanced': 1,
          'gallery-portfolio-income': 0.78,
        },
        centerContent: DonutCenterContent(
          label: 'Capital',
          valueMode: DonutCenterValueMode.custom,
          customValue: '3 funds',
        ),
      ),
      concentricSeries: [
        DonutChartSeries.fromMap(
          id: 'gallery-portfolio-growth',
          name: 'Growth',
          unit: '%',
          values: const {
            'Equity': 58,
            'Credit': 14,
            'Real assets': 18,
            'Cash': 10,
          },
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
        DonutChartSeries.fromMap(
          id: 'gallery-portfolio-balanced',
          name: 'Balanced',
          unit: '%',
          values: const {
            'Equity': 42,
            'Credit': 28,
            'Real assets': 20,
            'Cash': 10,
          },
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
        DonutChartSeries.fromMap(
          id: 'gallery-portfolio-income',
          name: 'Income',
          unit: '%',
          values: const {
            'Equity': 24,
            'Credit': 48,
            'Real assets': 16,
            'Cash': 12,
          },
          donutStyle: ringStyle,
          dataLabels: hiddenLabels,
        ),
      ],
    );
  }
}

class _DonutGalleryCard extends StatelessWidget {
  const _DonutGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.series,
    this.concentricSeries,
    this.showLegend = true,
    this.concentricDonutConfig = const ConcentricDonutConfig(),
  }) : assert(series != null || concentricSeries != null),
       assert(series == null || concentricSeries == null);

  final String title;
  final String subtitle;
  final DonutChartSeries? series;
  final List<DonutChartSeries>? concentricSeries;
  final ChartTheme theme;
  final bool showLegend;
  final ConcentricDonutConfig concentricDonutConfig;

  @override
  Widget build(BuildContext context) {
    final isDark =
        ThemeData.estimateBrightnessForColor(theme.backgroundColor) ==
        Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFE5E7EB)
        : Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      color: isDark ? theme.backgroundColor : null,
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
                series: concentricSeries ?? [series!],
                concentricDonutConfig: concentricDonutConfig,
                theme: theme,
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
