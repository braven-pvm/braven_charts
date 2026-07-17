// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Reusable Donut compositions shown in the public Gallery and package media.
const donutGalleryCards = <Widget>[
  RevenueRingGalleryCard(),
  DeliveryProgressGalleryCard(),
  CampaignReachGalleryCard(),
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

/// A balanced contribution ring whose center follows durable selection.
class RevenueRingGalleryCard extends StatelessWidget {
  const RevenueRingGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.corporateBlue;
    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-revenue'),
      title: 'Recurring revenue',
      subtitle: 'Selection-aware center · outside labels',
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
        name: 'Revenue',
        unit: 'k',
        values: const {
          'Subscriptions': 42,
          'Services': 28,
          'Hardware': 16,
          'Training': 9,
          'Other': 5,
        },
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.66,
          radiusFactor: 0.82,
          sliceGap: 2,
          cornerRadius: 7,
          borderWidth: 1,
          borderColorMode: PieBorderColorMode.slice,
          gradient: PieGradientStyle(type: PieGradientType.radial),
        ),
        centerContent: const DonutCenterContent(
          label: 'Revenue',
          valueMode: DonutCenterValueMode.selectedOrTotal,
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.outside,
          content: PieDataLabelContent.categoryAndPercentage,
          minimumShare: 0.08,
        ),
      ),
    );
  }
}

/// A partial Donut that uses the center as a portable status summary.
class DeliveryProgressGalleryCard extends StatelessWidget {
  const DeliveryProgressGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    final theme = base.copyWith(
      backgroundColor: const Color(0xFF111827),
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFF38BDF8),
          Color(0xFFA78BFA),
          Color(0xFF34D399),
          Color(0xFFFBBF24),
          Color(0xFFFB7185),
        ],
      ),
    );
    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-progress'),
      title: 'Release progress',
      subtitle: '280° sweep · portable center status',
      theme: theme,
      showLegend: false,
      series: DonutChartSeries.fromMap(
        id: 'gallery-donut-progress-series',
        name: 'Delivery',
        unit: 'hours',
        values: const {
          'Build': 46,
          'Discovery': 18,
          'Design': 14,
          'Testing': 12,
          'Launch': 7,
          'Support': 3,
        },
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.66,
          startAngleDegrees: 130,
          sweepAngleDegrees: 280,
          radiusFactor: 0.88,
          sliceGap: 2,
          cornerRadius: 10,
          gradient: PieGradientStyle(
            type: PieGradientType.linear,
            angleDegrees: -45,
          ),
        ),
        centerContent: const DonutCenterContent(
          label: 'Status',
          valueMode: DonutCenterValueMode.custom,
          customValue: 'On track',
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
              fontSize: 18,
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
          minimumShare: 0.1,
        ),
      ),
    );
  }
}

/// Angle communicates contribution while radius communicates audience reach.
class CampaignReachGalleryCard extends StatelessWidget {
  const CampaignReachGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.light;
    return _DonutGalleryCard(
      key: const ValueKey('gallery-donut-reach'),
      title: 'Campaign contribution',
      subtitle: 'Variable radius · compact inside labels',
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
        name: 'Campaigns',
        unit: 'leads',
        values: const {
          'Search': 31,
          'Social': 24,
          'Partners': 19,
          'Events': 15,
          'Email': 11,
        },
        radiusValues: const {
          'Search': 82,
          'Social': 54,
          'Partners': 68,
          'Events': 37,
          'Email': 46,
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
          label: 'Leads',
          valueMode: DonutCenterValueMode.custom,
          customValue: '100',
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.1,
        ),
      ),
    );
  }
}

class _DonutGalleryCard extends StatelessWidget {
  const _DonutGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.series,
    required this.theme,
    this.showLegend = true,
  });

  final String title;
  final String subtitle;
  final DonutChartSeries series;
  final ChartTheme theme;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: [series],
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
