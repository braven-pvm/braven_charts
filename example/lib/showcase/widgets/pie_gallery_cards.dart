// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// The Pie compositions shown together in the public Gallery and package media.
const pieGalleryCards = <Widget>[
  SimpleRevenueGalleryCard(),
  RevenueContributionGalleryCard(),
  ReleaseEffortGalleryCard(),
  SupportMixGalleryCard(),
  PortfolioAllocationGalleryCard(),
];

/// A capture-friendly rendering of the same Pie cards used by the Gallery.
class PieGalleryMediaPanel extends StatelessWidget {
  const PieGalleryMediaPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1200) {
              final cardWidth = (constraints.maxWidth - 32) / 3;
              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        for (final (index, card)
                            in pieGalleryCards.take(3).indexed) ...[
                          if (index > 0) const SizedBox(width: 16),
                          Expanded(child: card),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final (index, card)
                            in pieGalleryCards.skip(3).indexed) ...[
                          if (index > 0) const SizedBox(width: 16),
                          SizedBox(width: cardWidth, child: card),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            return GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: columns == 2 ? 1.62 : 1.36,
              children: pieGalleryCards,
            );
          },
        ),
      ),
    );
  }
}

/// A deliberately simple dark Pie with only dominant values labelled.
class SimpleRevenueGalleryCard extends StatelessWidget {
  const SimpleRevenueGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.dark;
    final theme = base.copyWith(
      backgroundColor: const Color(0xFF1F1F1F),
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFFE63946),
          Color(0xFFF77F00),
          Color(0xFFFCBF49),
          Color(0xFFD62828),
          Color(0xFF9D4EDD),
        ],
      ),
      pieChartTheme: const PieChartTheme(
        cornerRadius: 6,
        borderColorMode: PieBorderColorMode.slice,
        borderLightnessShift: -0.18,
        calloutStyle: LabelStyle(
          textStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: Color(0x00000000),
          borderColor: Color(0x00000000),
          borderWidth: 0,
          borderRadius: 0,
          padding: EdgeInsets.zero,
        ),
      ),
    );
    return _PieGalleryCard(
      key: const ValueKey('gallery-pie-simple-revenue'),
      title: 'Revenue by product',
      subtitle: 'Dark canvas · linear fill · inside values',
      theme: theme,
      showLegend: false,
      series: PieChartSeries.fromMap(
        id: 'gallery-pie-simple-revenue-series',
        name: 'Revenue',
        unit: 'USD',
        values: const {
          'Subscriptions': 42,
          'Services': 28,
          'Hardware': 16,
          'Training': 9,
          'Other': 5,
        },
        pieStyle: const PieChartStyle(
          radiusFactor: 0.92,
          sliceGap: 2,
          borderWidth: 1.5,
          borderColorMode: PieBorderColorMode.slice,
          borderLightnessShift: -0.18,
          gradient: PieGradientStyle(
            type: PieGradientType.linear,
            startLightnessShift: 0.2,
            endLightnessShift: -0.14,
            angleDegrees: -50,
          ),
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.value,
          minimumShare: 0.2,
        ),
      ),
    );
  }
}

/// Outside labels and a restrained product palette for contribution analysis.
class RevenueContributionGalleryCard extends StatelessWidget {
  const RevenueContributionGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.corporateBlue;
    final theme = base.copyWith(
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFF2563EB),
          Color(0xFF14B8A6),
          Color(0xFF7C3AED),
          Color(0xFFF59E0B),
          Color(0xFF64748B),
        ],
      ),
      pieChartTheme: const PieChartTheme(
        cornerRadius: 6,
        borderColorMode: PieBorderColorMode.slice,
        borderLightnessShift: -0.16,
      ),
    );
    return _PieGalleryCard(
      key: const ValueKey('gallery-pie-revenue'),
      title: 'Revenue contribution',
      subtitle: 'Outside labels · slice-derived borders',
      theme: theme,
      showLegend: false,
      series: PieChartSeries.fromMap(
        id: 'gallery-pie-revenue-series',
        name: 'Revenue',
        unit: 'k USD',
        values: const {
          'Subscriptions': 46,
          'Services': 24,
          'Hardware': 15,
          'Training': 9,
          'Other': 6,
        },
        pieStyle: const PieChartStyle(
          radiusFactor: 0.74,
          sliceGap: 3,
          borderWidth: 1,
          borderColorMode: PieBorderColorMode.slice,
          borderLightnessShift: -0.18,
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.outside,
          content: PieDataLabelContent.categoryAndPercentage,
          minimumShare: 0.05,
        ),
      ),
    );
  }
}

/// A dark, compact treatment with labels carried by the slices themselves.
class ReleaseEffortGalleryCard extends StatelessWidget {
  const ReleaseEffortGalleryCard({super.key});

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
      pieChartTheme: const PieChartTheme(
        cornerRadius: 12,
        shadow: PieElevationStyle(
          color: Color(0x73000000),
          blurRadius: 7,
          offset: Offset(0, 3),
          opacity: 0.7,
        ),
        borderColorMode: PieBorderColorMode.slice,
        borderLightnessShift: 0.12,
      ),
    );
    return _PieGalleryCard(
      key: const ValueKey('gallery-pie-effort'),
      title: 'Release effort',
      subtitle: 'Dark theme · inside labels · rounded slices',
      theme: theme,
      showLegend: false,
      series: PieChartSeries.fromMap(
        id: 'gallery-pie-effort-series',
        name: 'Effort',
        unit: 'hours',
        values: const {
          'Build': 44,
          'Test': 24,
          'Design': 15,
          'Launch': 10,
          'Research': 7,
        },
        pieStyle: const PieChartStyle(
          startAngleDegrees: -72,
          radiusFactor: 0.79,
          sliceGap: 5,
          borderWidth: 1,
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.07,
        ),
      ),
    );
  }
}

/// Dense category data exercising collision-aware outside-label placement.
class SupportMixGalleryCard extends StatelessWidget {
  const SupportMixGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.minimal;
    final theme = base.copyWith(
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFF006D77),
          Color(0xFF0A9396),
          Color(0xFF48CAE4),
          Color(0xFF90E0EF),
          Color(0xFF023E8A),
          Color(0xFF0077B6),
          Color(0xFF2A9D8F),
          Color(0xFF94D2BD),
        ],
      ),
      pieChartTheme: const PieChartTheme(
        cornerRadius: 4,
        borderColorMode: PieBorderColorMode.slice,
        borderLightnessShift: -0.14,
      ),
    );
    return _PieGalleryCard(
      key: const ValueKey('gallery-pie-support'),
      title: 'Support request mix',
      subtitle: 'Dense categories · collision-aware callouts',
      theme: theme,
      showLegend: false,
      series: PieChartSeries.fromMap(
        id: 'gallery-pie-support-series',
        name: 'Requests',
        unit: 'tickets',
        values: const {
          'Exports': 28,
          'Integrations': 20,
          'Reporting': 16,
          'Mobile': 12,
          'Security': 9,
          'Accounts': 7,
          'Billing': 5,
          'Other': 3,
        },
        pieStyle: const PieChartStyle(
          radiusFactor: 0.69,
          sliceGap: 2,
          borderWidth: 1,
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.outside,
          content: PieDataLabelContent.category,
          minimumShare: 0.05,
          collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
        ),
      ),
    );
  }
}

/// A warm, elevated treatment demonstrating transparency and selected glow.
class PortfolioAllocationGalleryCard extends StatelessWidget {
  const PortfolioAllocationGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.vibrant;
    final theme = base.copyWith(
      seriesTheme: base.seriesTheme.copyWith(
        colors: const [
          Color(0xFFE11D48),
          Color(0xFFF97316),
          Color(0xFFFBBF24),
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
        ],
      ),
      legendStyle: base.legendStyle.copyWith(
        position: LegendPosition.centerRight,
        orientation: LegendOrientation.vertical,
        markerShape: LegendMarkerShape.circle,
        markerSize: 10,
        markerLabelSpacing: 5,
        itemSpacing: 3,
        textStyle: const TextStyle(fontSize: 10, color: Color(0xFF3F1D2C)),
        backgroundColor: const Color(0x00FFFFFF),
        padding: const EdgeInsets.all(4),
      ),
      pieChartTheme: const PieChartTheme(
        opacity: 0.92,
        cornerRadius: 16,
        shadow: PieElevationStyle(
          color: Color(0x3D7C2D12),
          blurRadius: 9,
          offset: Offset(0, 4),
          opacity: 0.65,
        ),
        selectedElevation: PieElevationStyle(
          blurRadius: 16,
          spreadRadius: 2,
          opacity: 0.48,
        ),
        borderColorMode: PieBorderColorMode.slice,
        borderHueShiftDegrees: 22,
        borderLightnessShift: -0.12,
      ),
    );
    return _PieGalleryCard(
      key: const ValueKey('gallery-pie-portfolio'),
      title: 'Portfolio allocation',
      subtitle: 'Warm palette · radial fill · elevation',
      theme: theme,
      series: PieChartSeries.fromMap(
        id: 'gallery-pie-portfolio-series',
        name: 'Allocation',
        unit: '%',
        values: const {
          'Core': 48,
          'Growth': 22,
          'Income': 14,
          'Alternatives': 10,
          'Cash': 6,
        },
        pieStyle: const PieChartStyle(
          startAngleDegrees: -96,
          radiusFactor: 0.78,
          sliceGap: 7,
          borderWidth: 1.5,
          borderColorMode: PieBorderColorMode.slice,
          borderHueShiftDegrees: 22,
          borderLightnessShift: -0.12,
          gradient: PieGradientStyle(
            type: PieGradientType.radial,
            startLightnessShift: 0.18,
            endLightnessShift: -0.12,
          ),
        ),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.inside,
          content: PieDataLabelContent.percentage,
          minimumShare: 0.06,
        ),
      ),
    );
  }
}

class _PieGalleryCard extends StatelessWidget {
  const _PieGalleryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.series,
    required this.theme,
    this.showLegend = true,
  });

  final String title;
  final String subtitle;
  final PieChartSeries series;
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
