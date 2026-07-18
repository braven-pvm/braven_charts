// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// The production-shaped Bar compositions shown in the Gallery and package
/// media. Each card isolates a distinct geometry or comparison strategy.
const barGalleryCards = <Widget>[
  BarTargetsGalleryCard(),
  BarCapacityGalleryCard(),
  BarWaterfallGalleryCard(),
  BarRangeGalleryCard(),
  BarHorizontalGalleryCard(),
  BarNormalizedGalleryCard(),
  BarOverlayGalleryCard(),
  BarRodsGalleryCard(),
  BarGradientGalleryCard(),
  BarSignedGalleryCard(),
  BarOffsetGalleryCard(),
  BarAxesGalleryCard(),
  BarStackedGalleryCard(),
];

String _weekdayLabel(double value) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if ((value - value.round()).abs() > 0.001) return '';
  final index = value.round();
  return index >= 0 && index < labels.length ? labels[index] : '';
}

String _quarterLabel(double value) {
  const labels = ['Q1', 'Q2', 'Q3', 'Q4'];
  if ((value - value.round()).abs() > 0.001) return '';
  final index = value.round();
  return index >= 0 && index < labels.length ? labels[index] : '';
}

String _waterfallLabel(double value) {
  const labels = [
    'Opening',
    'Sales',
    'Expansion',
    'Churn',
    'Costs',
    'Other',
    'Net',
  ];
  if ((value - value.round()).abs() > 0.001) return '';
  final index = value.round();
  return index >= 0 && index < labels.length ? labels[index] : '';
}

String _channelLabel(double value) {
  const labels = ['Enterprise', 'Online', 'Partners', 'Mid-market', 'Retail'];
  if ((value - value.round()).abs() > 0.001) return '';
  final index = value.round();
  return index >= 0 && index < labels.length ? labels[index] : '';
}

String _performanceChannelLabel(double value) {
  const labels = ['Web', 'Retail', 'Partner', 'Direct', 'Enterprise', 'Event'];
  if ((value - value.round()).abs() > 0.001) return '';
  final index = value.round();
  return index >= 0 && index < labels.length ? labels[index] : '';
}

String _regionLabel(double value) {
  const labels = ['Nordic', 'Alpine', 'Pacific', 'Atlantic', 'Central'];
  if ((value - value.round()).abs() > 0.001) return '';
  final index = value.round();
  return index >= 0 && index < labels.length ? labels[index] : '';
}

class _BarGalleryCard extends StatelessWidget {
  const _BarGalleryCard({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    this.showLegend = true,
    this.dark = false,
    this.normalizationMode,
    this.maxAxesPerSide = 2,
    this.interactionConfig = const InteractionConfig(
      tooltip: TooltipConfig(),
      crosshair: CrosshairConfig(
        enabled: true,
        mode: CrosshairMode.vertical,
        snapToDataPoint: true,
      ),
    ),
  });

  final String title;
  final String subtitle;
  final List<ChartSeries> series;
  final XAxisConfig xAxis;
  final YAxisConfig yAxis;
  final bool showLegend;
  final bool dark;
  final NormalizationMode? normalizationMode;
  final int maxAxesPerSide;
  final InteractionConfig interactionConfig;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chartTheme = dark ? ChartTheme.dark : ChartTheme.light;
    final cardColor = dark ? const Color(0xFF111827) : colorScheme.surface;
    final titleColor = dark ? const Color(0xFFF8FAFC) : colorScheme.onSurface;
    final subtitleColor = dark
        ? const Color(0xFFCBD5E1)
        : colorScheme.onSurfaceVariant;

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
            Text(
              subtitle,
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BravenChartPlus(
                series: series,
                theme: chartTheme,
                normalizationMode: normalizationMode,
                maxAxesPerSide: maxAxesPerSide,
                showLegend: showLegend,
                legendStyle: LegendStyle(
                  position: LegendPosition.topRight,
                  orientation: LegendOrientation.horizontal,
                  allowDragging: false,
                  textStyle: TextStyle(
                    color: dark
                        ? const Color(0xFFE2E8F0)
                        : colorScheme.onSurface,
                    fontSize: 11,
                  ),
                ),
                xAxisConfig: xAxis,
                yAxis: yAxis,
                interactionConfig: interactionConfig,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                    errorLowerValues: [64, 77, 70, 86, 51, 82],
                    errorUpperValues: [75, 90, 83, 97, 66, 94],
                    errorBarStyle: BarErrorBarStyle(
                      color: Color(0xFF334155),
                      width: 1.75,
                      capLengthFactor: 0.65,
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
                  renderMin: 0,
                  renderMax: 5,
                  tickCount: 6,
                  labelFormatter: _performanceChannelLabel,
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

/// Capacity tracks keep the available headroom visible without manufacturing
/// a second "remaining" series.
class BarCapacityGalleryCard extends StatelessWidget {
  const BarCapacityGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Delivery capacity',
    subtitle: 'Grouped values · capacity tracks · rounded geometry',
    series: const [
      BarChartSeries(
        id: 'capacity-planned',
        name: 'Planned',
        unit: '%',
        points: [
          ChartDataPoint(x: 0, y: 42, label: 'Mon'),
          ChartDataPoint(x: 1, y: 61, label: 'Tue'),
          ChartDataPoint(x: 2, y: 88, label: 'Wed'),
          ChartDataPoint(x: 3, y: 55, label: 'Thu'),
          ChartDataPoint(x: 4, y: 74, label: 'Fri'),
          ChartDataPoint(x: 5, y: 91, label: 'Sat'),
          ChartDataPoint(x: 6, y: 68, label: 'Sun'),
        ],
        color: Color(0xFF2563EB),
        barWidthPercent: 0.68,
        barGap: 4,
        barStyle: BarChartStyle(cornerRadius: 6),
        trackStyle: BarTrackStyle(
          color: Color(0xFFDBEAFE),
          value: 100,
          cornerRadius: 6,
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'capacity-delivered',
        name: 'Delivered',
        unit: '%',
        points: [
          ChartDataPoint(x: 0, y: 31, label: 'Mon'),
          ChartDataPoint(x: 1, y: 69, label: 'Tue'),
          ChartDataPoint(x: 2, y: 81, label: 'Wed'),
          ChartDataPoint(x: 3, y: 62, label: 'Thu'),
          ChartDataPoint(x: 4, y: 64, label: 'Fri'),
          ChartDataPoint(x: 5, y: 86, label: 'Sat'),
          ChartDataPoint(x: 6, y: 72, label: 'Sun'),
        ],
        color: Color(0xFF14B8A6),
        barWidthPercent: 0.68,
        barGap: 4,
        barStyle: BarChartStyle(cornerRadius: 6),
        trackStyle: BarTrackStyle(
          color: Color(0xFFCCFBF1),
          value: 100,
          cornerRadius: 6,
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Day',
      min: -0.6,
      max: 6.6,
      renderMin: 0,
      renderMax: 6,
      tickCount: 7,
      labelFormatter: _weekdayLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Capacity used',
      unit: '%',
      min: 0,
      max: 105,
    ),
  );
}

/// Sequential deltas, connector lines, and a resolved total in one semantic
/// series.
class BarWaterfallGalleryCard extends StatelessWidget {
  const BarWaterfallGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Cash-flow bridge',
    subtitle: 'Waterfall deltas · connectors · resolved total',
    showLegend: false,
    series: const [
      BarChartSeries(
        id: 'cash-flow',
        name: 'Cash flow',
        unit: r'$k',
        layoutMode: BarLayoutMode.waterfall,
        points: [
          ChartDataPoint(x: 0, y: 82, label: 'Opening'),
          ChartDataPoint(x: 1, y: 28, label: 'Sales'),
          ChartDataPoint(x: 2, y: 16, label: 'Expansion'),
          ChartDataPoint(x: 3, y: -18, label: 'Churn'),
          ChartDataPoint(x: 4, y: -24, label: 'Costs'),
          ChartDataPoint(x: 5, y: 7, label: 'Other'),
          ChartDataPoint(x: 6, y: 0, label: 'Net'),
        ],
        color: Color(0xFF168AAD),
        barWidthPercent: 0.62,
        waterfallTotalIndices: {6},
        waterfallStyle: BarWaterfallStyle(
          increaseColor: Color(0xFF16A085),
          decreaseColor: Color(0xFFE15B64),
          totalColor: Color(0xFF5B4BC4),
          connector: BarWaterfallConnectorStyle(
            show: true,
            color: Color(0xFF94A3B8),
            width: 1.25,
          ),
        ),
        barStyle: BarChartStyle(cornerRadius: 5),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Stage',
      min: -0.6,
      max: 6.6,
      renderMin: 0,
      renderMax: 6,
      tickCount: 7,
      labelFormatter: _waterfallLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Cash flow',
      unit: r'$k',
    ),
  );
}

/// Floating bars expose explicit low/high intervals and label both ends.
class BarRangeGalleryCard extends StatelessWidget {
  const BarRangeGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Temperature windows',
    subtitle: 'Floating ranges · paired forecasts · gradients',
    series: const [
      BarChartSeries(
        id: 'temperature-observed',
        name: 'Observed',
        unit: '°C',
        points: [
          ChartDataPoint(x: 0, y: 25, label: 'Mon'),
          ChartDataPoint(x: 1, y: 29, label: 'Tue'),
          ChartDataPoint(x: 2, y: 27, label: 'Wed'),
          ChartDataPoint(x: 3, y: 31, label: 'Thu'),
          ChartDataPoint(x: 4, y: 28, label: 'Fri'),
          ChartDataPoint(x: 5, y: 24, label: 'Sat'),
          ChartDataPoint(x: 6, y: 26, label: 'Sun'),
        ],
        rangeStartValues: [14, 17, 15, 19, 16, 13, 14],
        color: Color(0xFFF97316),
        barWidthPercent: 0.62,
        barGap: 7,
        barStyle: BarChartStyle(
          cornerRadius: 8,
          cornerRadiusPolicy: BarCornerRadiusPolicy.all,
          gradient: BarGradient(colors: [Color(0xFFFED7AA), Color(0xFFEA580C)]),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'temperature-forecast',
        name: 'Forecast',
        unit: '°C',
        points: [
          ChartDataPoint(x: 0, y: 23, label: 'Mon'),
          ChartDataPoint(x: 1, y: 27, label: 'Tue'),
          ChartDataPoint(x: 2, y: 30, label: 'Wed'),
          ChartDataPoint(x: 3, y: 29, label: 'Thu'),
          ChartDataPoint(x: 4, y: 26, label: 'Fri'),
          ChartDataPoint(x: 5, y: 25, label: 'Sat'),
          ChartDataPoint(x: 6, y: 28, label: 'Sun'),
        ],
        rangeStartValues: [12, 16, 18, 17, 15, 14, 17],
        color: Color(0xFF0EA5E9),
        barWidthPercent: 0.62,
        barGap: 7,
        barStyle: BarChartStyle(
          cornerRadius: 8,
          cornerRadiusPolicy: BarCornerRadiusPolicy.all,
          gradient: BarGradient(colors: [Color(0xFFBAE6FD), Color(0xFF0284C7)]),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Day',
      min: -0.6,
      max: 6.6,
      renderMin: 0,
      renderMax: 6,
      tickCount: 7,
      labelFormatter: _weekdayLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Temperature',
      unit: '°C',
    ),
  );
}

/// Horizontal bars prioritize long category labels and retain ordinary
/// grouping, labels, tooltips, and keyboard focus.
class BarHorizontalGalleryCard extends StatelessWidget {
  const BarHorizontalGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Revenue ranking',
    subtitle: 'Horizontal grouping · long categories · ranked comparison',
    series: const [
      BarChartSeries(
        id: 'revenue-current',
        name: 'Current',
        unit: r'$k',
        orientation: BarOrientation.horizontal,
        points: [
          ChartDataPoint(x: 0, y: 96, label: 'Enterprise'),
          ChartDataPoint(x: 1, y: 84, label: 'Online'),
          ChartDataPoint(x: 2, y: 73, label: 'Partners'),
          ChartDataPoint(x: 3, y: 61, label: 'Mid-market'),
          ChartDataPoint(x: 4, y: 49, label: 'Retail'),
        ],
        color: Color(0xFF2563EB),
        barWidthPercent: 0.7,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'revenue-target',
        name: 'Target',
        unit: r'$k',
        orientation: BarOrientation.horizontal,
        points: [
          ChartDataPoint(x: 0, y: 88, label: 'Enterprise'),
          ChartDataPoint(x: 1, y: 79, label: 'Online'),
          ChartDataPoint(x: 2, y: 68, label: 'Partners'),
          ChartDataPoint(x: 3, y: 57, label: 'Mid-market'),
          ChartDataPoint(x: 4, y: 44, label: 'Retail'),
        ],
        color: Color(0xFFF59E0B),
        barWidthPercent: 0.7,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Channel',
      min: -1,
      max: 5,
      renderMin: 0,
      renderMax: 4,
      tickCount: 5,
      labelFormatter: _channelLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Revenue',
      unit: r'$k',
      min: 0,
    ),
    interactionConfig: const InteractionConfig(
      tooltip: TooltipConfig(),
      crosshair: CrosshairConfig(
        enabled: true,
        mode: CrosshairMode.both,
        displayMode: CrosshairDisplayMode.tracking,
        snapToDataPoint: true,
      ),
    ),
  );
}

/// Two named stacks normalize independently while retaining the raw values in
/// tooltips and table projection.
class BarNormalizedGalleryCard extends StatelessWidget {
  const BarNormalizedGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Channel composition',
    subtitle: 'Two named 100% stacks · raw-value tooltips · dark theme',
    dark: true,
    series: const [
      BarChartSeries(
        id: 'actual-organic',
        name: 'Actual organic',
        layoutMode: BarLayoutMode.normalizedStacked,
        groupId: 'actual',
        points: [
          ChartDataPoint(x: 0, y: 52, label: 'Q1'),
          ChartDataPoint(x: 1, y: 47, label: 'Q2'),
          ChartDataPoint(x: 2, y: 61, label: 'Q3'),
          ChartDataPoint(x: 3, y: 56, label: 'Q4'),
        ],
        color: Color(0xFF22D3EE),
        barWidthPercent: 0.8,
        barStyle: BarChartStyle(cornerRadius: 5),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'actual-paid',
        name: 'Actual paid',
        layoutMode: BarLayoutMode.normalizedStacked,
        groupId: 'actual',
        points: [
          ChartDataPoint(x: 0, y: 48, label: 'Q1'),
          ChartDataPoint(x: 1, y: 53, label: 'Q2'),
          ChartDataPoint(x: 2, y: 39, label: 'Q3'),
          ChartDataPoint(x: 3, y: 44, label: 'Q4'),
        ],
        color: Color(0xFF6366F1),
        barWidthPercent: 0.8,
        barStyle: BarChartStyle(cornerRadius: 5),
        labelStyle: BarLabelStyle(
          position: BarLabelPosition.insideCenter,
          valueMode: BarLabelValueMode.percentage,
        ),
      ),
      BarChartSeries(
        id: 'plan-organic',
        name: 'Plan organic',
        layoutMode: BarLayoutMode.normalizedStacked,
        groupId: 'plan',
        points: [
          ChartDataPoint(x: 0, y: 58, label: 'Q1'),
          ChartDataPoint(x: 1, y: 55, label: 'Q2'),
          ChartDataPoint(x: 2, y: 64, label: 'Q3'),
          ChartDataPoint(x: 3, y: 60, label: 'Q4'),
        ],
        color: Color(0xFF34D399),
        barWidthPercent: 0.8,
        barStyle: BarChartStyle(cornerRadius: 5),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'plan-paid',
        name: 'Plan paid',
        layoutMode: BarLayoutMode.normalizedStacked,
        groupId: 'plan',
        points: [
          ChartDataPoint(x: 0, y: 42, label: 'Q1'),
          ChartDataPoint(x: 1, y: 45, label: 'Q2'),
          ChartDataPoint(x: 2, y: 36, label: 'Q3'),
          ChartDataPoint(x: 3, y: 40, label: 'Q4'),
        ],
        color: Color(0xFFF59E0B),
        barWidthPercent: 0.8,
        barStyle: BarChartStyle(cornerRadius: 5),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Quarter',
      min: -0.6,
      max: 3.6,
      renderMin: 0,
      renderMax: 3,
      tickCount: 4,
      labelFormatter: _quarterLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Channel share',
      unit: '%',
      min: 0,
      max: 100,
    ),
  );
}

/// Wide plan bars remain legible behind narrower actual values while both
/// series retain their own hit targets and table columns.
class BarOverlayGalleryCard extends StatelessWidget {
  const BarOverlayGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Plan versus actual',
    subtitle: 'Overlaid geometry · independent widths · shared categories',
    series: const [
      BarChartSeries(
        id: 'overlay-plan',
        name: 'Plan',
        layoutMode: BarLayoutMode.overlaid,
        groupId: 'comparison',
        overlayWidthFactor: 1,
        points: [
          ChartDataPoint(x: 0, y: 72, label: 'Mon'),
          ChartDataPoint(x: 1, y: 78, label: 'Tue'),
          ChartDataPoint(x: 2, y: 84, label: 'Wed'),
          ChartDataPoint(x: 3, y: 68, label: 'Thu'),
          ChartDataPoint(x: 4, y: 88, label: 'Fri'),
          ChartDataPoint(x: 5, y: 91, label: 'Sat'),
          ChartDataPoint(x: 6, y: 76, label: 'Sun'),
        ],
        color: Color(0xFFC7D2FE),
        barWidthPercent: 0.76,
        barStyle: BarChartStyle(
          cornerRadius: 7,
          border: BarBorderStyle(color: Color(0xFF818CF8), width: 1),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'overlay-actual',
        name: 'Actual',
        layoutMode: BarLayoutMode.overlaid,
        groupId: 'comparison',
        overlayWidthFactor: 0.52,
        points: [
          ChartDataPoint(x: 0, y: 64, label: 'Mon'),
          ChartDataPoint(x: 1, y: 82, label: 'Tue'),
          ChartDataPoint(x: 2, y: 76, label: 'Wed'),
          ChartDataPoint(x: 3, y: 73, label: 'Thu'),
          ChartDataPoint(x: 4, y: 79, label: 'Fri'),
          ChartDataPoint(x: 5, y: 86, label: 'Sat'),
          ChartDataPoint(x: 6, y: 81, label: 'Sun'),
        ],
        color: Color(0xFF4F46E5),
        barWidthPercent: 0.76,
        barStyle: BarChartStyle(
          cornerRadius: 7,
          interaction: BarInteractionStyle(dimmedOpacity: 0.3),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Day',
      min: -0.6,
      max: 6.6,
      renderMin: 0,
      renderMax: 6,
      tickCount: 7,
      labelFormatter: _weekdayLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Completion',
      unit: '%',
      min: 0,
      max: 100,
    ),
  );
}

/// Slim fully-rounded bars compare distribution percentiles without the
/// visual weight of ordinary columns.
class BarRodsGalleryCard extends StatelessWidget {
  const BarRodsGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Service latency distribution',
    subtitle: 'Three percentiles · capsule rods · compact grouping',
    series: const [
      BarChartSeries(
        id: 'latency-p50',
        name: 'P50',
        unit: 'ms',
        points: [
          ChartDataPoint(x: 0, y: 34),
          ChartDataPoint(x: 1, y: 57),
          ChartDataPoint(x: 2, y: 46),
          ChartDataPoint(x: 3, y: 69),
          ChartDataPoint(x: 4, y: 81),
          ChartDataPoint(x: 5, y: 96),
          ChartDataPoint(x: 6, y: 62),
        ],
        color: Color(0xFF2563EB),
        barWidthPercent: 0.34,
        barGap: 10,
        barStyle: BarChartStyle(
          cornerRadius: 32,
          cornerRadiusPolicy: BarCornerRadiusPolicy.all,
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'latency-p95',
        name: 'P95',
        unit: 'ms',
        points: [
          ChartDataPoint(x: 0, y: 46),
          ChartDataPoint(x: 1, y: 39),
          ChartDataPoint(x: 2, y: 71),
          ChartDataPoint(x: 3, y: 53),
          ChartDataPoint(x: 4, y: 88),
          ChartDataPoint(x: 5, y: 72),
          ChartDataPoint(x: 6, y: 90),
        ],
        color: Color(0xFF8B5CF6),
        barWidthPercent: 0.34,
        barGap: 10,
        barStyle: BarChartStyle(
          cornerRadius: 32,
          cornerRadiusPolicy: BarCornerRadiusPolicy.all,
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'latency-p99',
        name: 'P99',
        unit: 'ms',
        points: [
          ChartDataPoint(x: 0, y: 58),
          ChartDataPoint(x: 1, y: 74),
          ChartDataPoint(x: 2, y: 83),
          ChartDataPoint(x: 3, y: 66),
          ChartDataPoint(x: 4, y: 94),
          ChartDataPoint(x: 5, y: 87),
          ChartDataPoint(x: 6, y: 78),
        ],
        color: Color(0xFF14B8A6),
        barWidthPercent: 0.34,
        barGap: 10,
        barStyle: BarChartStyle(
          cornerRadius: 32,
          cornerRadiusPolicy: BarCornerRadiusPolicy.all,
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Day',
      min: -0.6,
      max: 6.6,
      renderMin: 0,
      renderMax: 6,
      tickCount: 7,
      labelFormatter: _weekdayLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Latency',
      unit: 'ms',
      min: 0,
      max: 105,
    ),
  );
}

/// Multiple product stages use related gradients while retaining ordinary
/// grouped-bar semantics and hit targets.
class BarGradientGalleryCard extends StatelessWidget {
  const BarGradientGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Pipeline by stage',
    subtitle: 'Four grouped series · vertical gradients · rounded ends',
    series: const [
      BarChartSeries(
        id: 'pipeline-discovery',
        name: 'Discovery',
        unit: r'$k',
        points: [
          ChartDataPoint(x: 0, y: 42),
          ChartDataPoint(x: 1, y: 55),
          ChartDataPoint(x: 2, y: 61),
          ChartDataPoint(x: 3, y: 72),
        ],
        color: Color(0xFF2563EB),
        barWidthPercent: 0.68,
        barGap: 4,
        barStyle: BarChartStyle(
          cornerRadius: 10,
          gradient: BarGradient(colors: [Color(0xFFBFDBFE), Color(0xFF2563EB)]),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'pipeline-qualified',
        name: 'Qualified',
        unit: r'$k',
        points: [
          ChartDataPoint(x: 0, y: 36),
          ChartDataPoint(x: 1, y: 48),
          ChartDataPoint(x: 2, y: 67),
          ChartDataPoint(x: 3, y: 76),
        ],
        color: Color(0xFF14B8A6),
        barWidthPercent: 0.68,
        barGap: 4,
        barStyle: BarChartStyle(
          cornerRadius: 10,
          gradient: BarGradient(colors: [Color(0xFF99F6E4), Color(0xFF0F766E)]),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'pipeline-proposal',
        name: 'Proposal',
        unit: r'$k',
        points: [
          ChartDataPoint(x: 0, y: 29),
          ChartDataPoint(x: 1, y: 44),
          ChartDataPoint(x: 2, y: 58),
          ChartDataPoint(x: 3, y: 69),
        ],
        color: Color(0xFFF59E0B),
        barWidthPercent: 0.68,
        barGap: 4,
        barStyle: BarChartStyle(
          cornerRadius: 10,
          gradient: BarGradient(colors: [Color(0xFFFDE68A), Color(0xFFD97706)]),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'pipeline-won',
        name: 'Won',
        unit: r'$k',
        points: [
          ChartDataPoint(x: 0, y: 21),
          ChartDataPoint(x: 1, y: 38),
          ChartDataPoint(x: 2, y: 49),
          ChartDataPoint(x: 3, y: 63),
        ],
        color: Color(0xFFF43F5E),
        barWidthPercent: 0.68,
        barGap: 4,
        barStyle: BarChartStyle(
          cornerRadius: 10,
          gradient: BarGradient(colors: [Color(0xFFFECDD3), Color(0xFFE11D48)]),
        ),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Quarter',
      min: -0.6,
      max: 3.6,
      renderMin: 0,
      renderMax: 3,
      tickCount: 4,
      labelFormatter: _quarterLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Pipeline value',
      unit: r'$k',
      min: 0,
    ),
  );
}

/// Positive and negative values share a true zero baseline and use point-level
/// colors to reinforce direction without requiring a second legend.
class BarSignedGalleryCard extends StatelessWidget {
  const BarSignedGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Forecast variance',
    subtitle: 'Diverging values · zero baseline · per-point color',
    showLegend: false,
    series: const [
      BarChartSeries(
        id: 'forecast-variance',
        name: 'Variance',
        unit: '%',
        points: [
          ChartDataPoint(
            x: 0,
            y: 38,
            pointStyle: PointStyle.color(Color(0xFF10B981)),
          ),
          ChartDataPoint(
            x: 1,
            y: -24,
            pointStyle: PointStyle.color(Color(0xFFEF4444)),
          ),
          ChartDataPoint(
            x: 2,
            y: 52,
            pointStyle: PointStyle.color(Color(0xFF10B981)),
          ),
          ChartDataPoint(
            x: 3,
            y: -38,
            pointStyle: PointStyle.color(Color(0xFFEF4444)),
          ),
          ChartDataPoint(
            x: 4,
            y: 71,
            pointStyle: PointStyle.color(Color(0xFF10B981)),
          ),
          ChartDataPoint(
            x: 5,
            y: 26,
            pointStyle: PointStyle.color(Color(0xFF10B981)),
          ),
          ChartDataPoint(
            x: 6,
            y: -18,
            pointStyle: PointStyle.color(Color(0xFFEF4444)),
          ),
        ],
        color: Color(0xFF10B981),
        barWidthPercent: 0.58,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 7),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Day',
      min: -0.6,
      max: 6.6,
      renderMin: 0,
      renderMax: 6,
      tickCount: 7,
      labelFormatter: _weekdayLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Variance',
      unit: '%',
      min: -50,
      max: 80,
    ),
  );
}

/// Equal-width layers are shifted around each category center to compare a
/// neutral benchmark with individually styled current results.
class BarOffsetGalleryCard extends StatelessWidget {
  const BarOffsetGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Qualification shift',
    subtitle: 'Offset overlays · shared baseline · per-point identity',
    series: const [
      BarChartSeries(
        id: 'qualification-reference',
        name: 'Reference',
        layoutMode: BarLayoutMode.overlaid,
        groupId: 'qualification',
        overlayOffsetFactor: -0.18,
        points: [
          ChartDataPoint(x: 0, y: 68),
          ChartDataPoint(x: 1, y: 74),
          ChartDataPoint(x: 2, y: 63),
          ChartDataPoint(x: 3, y: 79),
          ChartDataPoint(x: 4, y: 71),
        ],
        color: Color(0xFFCBD5E1),
        barWidthPercent: 0.68,
        barGap: 5,
        barStyle: BarChartStyle(cornerRadius: 3),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'qualification-current',
        name: 'Current',
        layoutMode: BarLayoutMode.overlaid,
        groupId: 'qualification',
        overlayOffsetFactor: 0.18,
        points: [
          ChartDataPoint(
            x: 0,
            y: 76,
            pointStyle: PointStyle.color(Color(0xFF2563EB)),
          ),
          ChartDataPoint(
            x: 1,
            y: 82,
            pointStyle: PointStyle.color(Color(0xFF8B5CF6)),
          ),
          ChartDataPoint(
            x: 2,
            y: 69,
            pointStyle: PointStyle.color(Color(0xFF14B8A6)),
          ),
          ChartDataPoint(
            x: 3,
            y: 86,
            pointStyle: PointStyle.color(Color(0xFFF59E0B)),
          ),
          ChartDataPoint(
            x: 4,
            y: 80,
            pointStyle: PointStyle.color(Color(0xFFF43F5E)),
          ),
        ],
        color: Color(0xFF2563EB),
        barWidthPercent: 0.68,
        barGap: 5,
        barStyle: BarChartStyle(cornerRadius: 3),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Region',
      min: -0.6,
      max: 4.6,
      renderMin: 0,
      renderMax: 4,
      tickCount: 5,
      labelFormatter: _regionLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Qualification score',
      unit: 'pts',
      min: 0,
      max: 100,
    ),
  );
}

/// Four unrelated business measures remain readable through per-series
/// normalization and independent visible axes.
class BarAxesGalleryCard extends StatelessWidget {
  const BarAxesGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Channel operating profile',
    subtitle: 'Four independent axes · per-series normalization · horizontal',
    normalizationMode: NormalizationMode.perSeries,
    maxAxesPerSide: 3,
    series: [
      // YAxisConfig is intentionally runtime-configured and is not const.
      // ignore: prefer_const_constructors
      BarChartSeries(
        id: 'channel-revenue',
        name: 'Revenue',
        unit: r'$k',
        orientation: BarOrientation.horizontal,
        points: const [
          ChartDataPoint(x: 0, y: 96),
          ChartDataPoint(x: 1, y: 84),
          ChartDataPoint(x: 2, y: 73),
          ChartDataPoint(x: 3, y: 61),
          ChartDataPoint(x: 4, y: 49),
        ],
        color: const Color(0xFF2563EB),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          color: const Color(0xFF2563EB),
          label: 'Revenue',
          unit: r'$k',
          min: 0,
          max: 110,
          tickCount: 5,
        ),
        barWidthPercent: 0.76,
        barGap: 4,
        barStyle: const BarChartStyle(cornerRadius: 5),
        labelStyle: const BarLabelStyle(show: false),
      ),
      // ignore: prefer_const_constructors
      BarChartSeries(
        id: 'channel-orders',
        name: 'Orders',
        unit: 'orders',
        orientation: BarOrientation.horizontal,
        points: const [
          ChartDataPoint(x: 0, y: 420),
          ChartDataPoint(x: 1, y: 385),
          ChartDataPoint(x: 2, y: 352),
          ChartDataPoint(x: 3, y: 316),
          ChartDataPoint(x: 4, y: 274),
        ],
        color: const Color(0xFFF59E0B),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          color: const Color(0xFFF59E0B),
          label: 'Orders',
          unit: 'orders',
          min: 0,
          max: 500,
          tickCount: 5,
        ),
        barWidthPercent: 0.76,
        barGap: 4,
        barStyle: const BarChartStyle(cornerRadius: 5),
        labelStyle: const BarLabelStyle(show: false),
      ),
      // ignore: prefer_const_constructors
      BarChartSeries(
        id: 'channel-conversion',
        name: 'Conversion',
        unit: '%',
        orientation: BarOrientation.horizontal,
        points: const [
          ChartDataPoint(x: 0, y: 82),
          ChartDataPoint(x: 1, y: 74),
          ChartDataPoint(x: 2, y: 68),
          ChartDataPoint(x: 3, y: 61),
          ChartDataPoint(x: 4, y: 58),
        ],
        color: const Color(0xFF14B8A6),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          color: const Color(0xFF14B8A6),
          label: 'Conversion',
          unit: '%',
          min: 0,
          max: 100,
          tickCount: 5,
        ),
        barWidthPercent: 0.76,
        barGap: 4,
        barStyle: const BarChartStyle(cornerRadius: 5),
        labelStyle: const BarLabelStyle(show: false),
      ),
      // ignore: prefer_const_constructors
      BarChartSeries(
        id: 'channel-margin',
        name: 'Margin',
        unit: '%',
        orientation: BarOrientation.horizontal,
        points: const [
          ChartDataPoint(x: 0, y: 36),
          ChartDataPoint(x: 1, y: 33),
          ChartDataPoint(x: 2, y: 29),
          ChartDataPoint(x: 3, y: 24),
          ChartDataPoint(x: 4, y: 21),
        ],
        color: const Color(0xFFF43F5E),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.left,
          color: const Color(0xFFF43F5E),
          label: 'Margin',
          unit: '%',
          min: 0,
          max: 50,
          tickCount: 5,
        ),
        barWidthPercent: 0.76,
        barGap: 4,
        barStyle: const BarChartStyle(cornerRadius: 5),
        labelStyle: const BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Channel',
      min: -0.6,
      max: 4.6,
      renderMin: 0,
      renderMax: 4,
      tickCount: 5,
      labelFormatter: _channelLabel,
    ),
    yAxis: YAxisConfig(position: YAxisPosition.left, min: 0),
  );
}

/// Two named stacks retain absolute totals while exposing their component
/// makeup, complementing the normalized-stack example above.
class BarStackedGalleryCard extends StatelessWidget {
  const BarStackedGalleryCard({super.key});

  @override
  Widget build(BuildContext context) => _BarGalleryCard(
    title: 'Revenue mix',
    subtitle: 'Two named stacks · absolute totals · three components',
    series: const [
      BarChartSeries(
        id: 'actual-platform',
        name: 'Actual platform',
        layoutMode: BarLayoutMode.stacked,
        groupId: 'actual',
        points: [
          ChartDataPoint(x: 0, y: 38),
          ChartDataPoint(x: 1, y: 45),
          ChartDataPoint(x: 2, y: 52),
          ChartDataPoint(x: 3, y: 58),
        ],
        color: Color(0xFF2563EB),
        barWidthPercent: 0.78,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'actual-services',
        name: 'Actual services',
        layoutMode: BarLayoutMode.stacked,
        groupId: 'actual',
        points: [
          ChartDataPoint(x: 0, y: 24),
          ChartDataPoint(x: 1, y: 29),
          ChartDataPoint(x: 2, y: 34),
          ChartDataPoint(x: 3, y: 37),
        ],
        color: Color(0xFF14B8A6),
        barWidthPercent: 0.78,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'actual-support',
        name: 'Actual support',
        layoutMode: BarLayoutMode.stacked,
        groupId: 'actual',
        points: [
          ChartDataPoint(x: 0, y: 16),
          ChartDataPoint(x: 1, y: 18),
          ChartDataPoint(x: 2, y: 21),
          ChartDataPoint(x: 3, y: 25),
        ],
        color: Color(0xFF8B5CF6),
        barWidthPercent: 0.78,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'plan-platform',
        name: 'Plan platform',
        layoutMode: BarLayoutMode.stacked,
        groupId: 'plan',
        points: [
          ChartDataPoint(x: 0, y: 42),
          ChartDataPoint(x: 1, y: 48),
          ChartDataPoint(x: 2, y: 55),
          ChartDataPoint(x: 3, y: 61),
        ],
        color: Color(0xFF93C5FD),
        barWidthPercent: 0.78,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'plan-services',
        name: 'Plan services',
        layoutMode: BarLayoutMode.stacked,
        groupId: 'plan',
        points: [
          ChartDataPoint(x: 0, y: 26),
          ChartDataPoint(x: 1, y: 31),
          ChartDataPoint(x: 2, y: 35),
          ChartDataPoint(x: 3, y: 40),
        ],
        color: Color(0xFF5EEAD4),
        barWidthPercent: 0.78,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
      BarChartSeries(
        id: 'plan-support',
        name: 'Plan support',
        layoutMode: BarLayoutMode.stacked,
        groupId: 'plan',
        points: [
          ChartDataPoint(x: 0, y: 18),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 2, y: 24),
          ChartDataPoint(x: 3, y: 27),
        ],
        color: Color(0xFFC4B5FD),
        barWidthPercent: 0.78,
        barGap: 6,
        barStyle: BarChartStyle(cornerRadius: 6),
        labelStyle: BarLabelStyle(show: false),
      ),
    ],
    xAxis: const XAxisConfig(
      label: 'Quarter',
      min: -0.6,
      max: 3.6,
      renderMin: 0,
      renderMax: 3,
      tickCount: 4,
      labelFormatter: _quarterLabel,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Revenue',
      unit: r'$k',
      min: 0,
    ),
  );
}
