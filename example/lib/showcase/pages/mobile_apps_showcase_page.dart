// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Finished mobile-app compositions rendered with live Braven Charts widgets.
///
/// This page is deliberately separate from the responsive chart-family
/// browser. It lets a desktop visitor inspect phone-native product
/// layouts while remaining directly useful on a real phone.
class MobileAppsShowcasePage extends StatelessWidget {
  const MobileAppsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      key: const ValueKey('mobile-apps-showcase'),
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          key: const ValueKey('mobile-apps-showcase-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      children: [
                        Text(
                          'Charts that belong in your hand',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Explore focused sports and wellness experiences built with the same native renderer. These are live Flutter widgets, not screenshots of a desktop dashboard.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FeaturePill(
                              icon: Icons.phone_iphone_rounded,
                              label: 'Phone-native layouts',
                            ),
                            _FeaturePill(
                              icon: Icons.view_agenda_rounded,
                              label: 'Adaptive layouts',
                            ),
                            _FeaturePill(
                              icon: Icons.flutter_dash_rounded,
                              label: 'Live Flutter widgets',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final phoneWidth = constraints.maxWidth < 400
                        ? constraints.maxWidth
                        : 344.0;
                    final rowWidth = phoneWidth * 3 + 56;
                    return Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: rowWidth),
                          child: Wrap(
                            key: const ValueKey('mobile-app-device-gallery'),
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 28,
                            runSpacing: 32,
                            children: [
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel:
                                      'Endurance activity mobile app',
                                  surfaceColor: Color(0xFFF7FAFC),
                                  child: _EnduranceExperience(),
                                ),
                              ),
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel:
                                      'Recovery readiness mobile app',
                                  surfaceColor: Color(0xFF0B1220),
                                  dark: true,
                                  child: _RecoveryExperience(),
                                ),
                              ),
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel: 'Live match mobile app',
                                  surfaceColor: Color(0xFFF8F7FC),
                                  child: _MatchExperience(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 64),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            children: [
                              Text(
                                'More ways charts become products',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Training ranges, habit streaks, and live urban density—each composed for a glance, a thumb, and a real mobile workflow.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: rowWidth),
                          child: Wrap(
                            key: const ValueKey(
                              'mobile-app-device-gallery-more',
                            ),
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 28,
                            runSpacing: 32,
                            children: [
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel:
                                      'Training load range mobile app',
                                  surfaceColor: Color(0xFF10131E),
                                  dark: true,
                                  child: _TrainingLoadExperience(),
                                ),
                              ),
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel: 'Habit streak heatmap app',
                                  surfaceColor: Color(0xFFF3FBF7),
                                  child: _HabitStreakExperience(),
                                ),
                              ),
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel:
                                      'Urban pickup density mobile app',
                                  surfaceColor: Color(0xFF090A0E),
                                  dark: true,
                                  child: _PickupDensityExperience(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneExperience extends StatelessWidget {
  const _PhoneExperience({
    required this.semanticLabel,
    required this.surfaceColor,
    required this.child,
    this.dark = false,
  });

  final String semanticLabel;
  final Color surfaceColor;
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final onSurface = dark ? const Color(0xFFF8FAFC) : const Color(0xFF172033);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF171922),
          borderRadius: BorderRadius.circular(42),
          border: Border.all(color: const Color(0xFF343743), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x240F172A),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: ColoredBox(
              color: surfaceColor,
              child: SizedBox(
                height: 680,
                child: IconTheme(
                  data: IconThemeData(color: onSurface),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: onSurface),
                    child: Column(
                      children: [
                        _PhoneStatusBar(dark: dark),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  const _PhoneStatusBar({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? const Color(0xFFDCE5F4) : const Color(0xFF273247);
    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(Icons.signal_cellular_alt_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Icon(Icons.wifi_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Icon(Icons.battery_full_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _EnduranceExperience extends StatelessWidget {
  const _EnduranceExperience();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF172033);
    const muted = Color(0xFF697386);
    const blue = Color(0xFF246BFD);
    final chartTheme = ChartTheme.light.copyWith(
      backgroundColor: const Color(0xFFF7FAFC),
      seriesTheme: ChartTheme.light.seriesTheme.copyWith(
        colors: const [blue, Color(0xFF77B5FF)],
      ),
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AppMark(
                    background: blue,
                    icon: Icons.directions_run_rounded,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stride',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Tuesday activity',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(icon: Icons.more_horiz_rounded, color: ink),
                ],
              ),
              SizedBox(height: 24),
              Text('Morning run', style: TextStyle(color: muted, fontSize: 12)),
              SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '8.42',
                            style: TextStyle(
                              color: ink,
                              fontSize: 38,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 4),
                            child: Text(
                              'km',
                              style: TextStyle(
                                color: muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _TrendBadge(label: '6% farther'),
                ],
              ),
              SizedBox(height: 18),
              _RangeTabs(labels: ['Pace', 'Heart rate', 'Elevation']),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: const ValueKey('mobile-app-endurance-chart'),
          height: 190,
          child: BravenChartPlus(
            series: const [
              AreaChartSeries(
                id: 'pace-area',
                name: 'Pace',
                color: Color(0xFF77B5FF),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 0,
                fillOpacity: 0.18,
                points: [
                  ChartDataPoint(x: 0, y: 5.4),
                  ChartDataPoint(x: 1, y: 5.2),
                  ChartDataPoint(x: 2, y: 5.35),
                  ChartDataPoint(x: 3, y: 4.95),
                  ChartDataPoint(x: 4, y: 5.1),
                  ChartDataPoint(x: 5, y: 4.82),
                  ChartDataPoint(x: 6, y: 4.9),
                  ChartDataPoint(x: 7, y: 4.58),
                  ChartDataPoint(x: 8, y: 4.7),
                ],
              ),
              LineChartSeries(
                id: 'pace-line',
                name: 'Pace',
                color: blue,
                interpolation: LineInterpolation.monotone,
                strokeWidth: 3,
                showDataPointMarkers: true,
                dataPointMarkerRadius: 2.5,
                points: [
                  ChartDataPoint(x: 0, y: 5.4),
                  ChartDataPoint(x: 1, y: 5.2),
                  ChartDataPoint(x: 2, y: 5.35),
                  ChartDataPoint(x: 3, y: 4.95),
                  ChartDataPoint(x: 4, y: 5.1),
                  ChartDataPoint(x: 5, y: 4.82),
                  ChartDataPoint(x: 6, y: 4.9),
                  ChartDataPoint(x: 7, y: 4.58),
                  ChartDataPoint(x: 8, y: 4.7),
                ],
              ),
            ],
            theme: chartTheme,
            showLegend: false,
            grid: const GridConfig(horizontal: false, vertical: false),
            xAxisConfig: const XAxisConfig(visible: false),
            yAxis: YAxisConfig(position: YAxisPosition.hidden),
            interactionConfig: InteractionConfig.none(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _Metric(label: 'Avg pace', value: '4:59', unit: '/km'),
              ),
              _MetricDivider(),
              Expanded(
                child: _Metric(label: 'Heart rate', value: '148', unit: 'bpm'),
              ),
              _MetricDivider(),
              Expanded(
                child: _Metric(label: 'Duration', value: '42:03', unit: ''),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 1,
          dark: false,
          items: [
            (Icons.home_rounded, 'Home'),
            (Icons.query_stats_rounded, 'Activity'),
            (Icons.route_rounded, 'Routes'),
            (Icons.person_rounded, 'You'),
          ],
        ),
      ],
    );
  }
}

class _RecoveryExperience extends StatelessWidget {
  const _RecoveryExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF0B1220);
    const text = Color(0xFFF8FAFC);
    const muted = Color(0xFF8D9AAF);
    const mint = Color(0xFF4ADEB5);
    final chartTheme = ChartTheme.dark.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.dark.seriesTheme.copyWith(
        colors: const [
          mint,
          Color(0xFF263449),
          Color(0xFF8B7CFF),
          Color(0xFF22D3EE),
        ],
      ),
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  _AppMark(
                    background: Color(0xFF153C35),
                    icon: Icons.eco_rounded,
                    iconColor: mint,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pulse',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Daily recovery',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(
                    icon: Icons.calendar_today_rounded,
                    color: text,
                    dark: true,
                  ),
                ],
              ),
              SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ready for quality work',
                  style: TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sleep and HRV are above your 30-day baseline.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0x244ADEB5), Color(0x000B1220)],
              radius: 0.62,
            ),
          ),
          key: const ValueKey('mobile-app-recovery-chart'),
          child: SizedBox(
            height: 220,
            child: BravenChartPlus(
              concentricDonutConfig: const ConcentricDonutConfig(
                innerRadiusFactor: 0.30,
                outerRadiusFactor: 0.90,
                ringGap: 5,
                ringWeights: {
                  'readiness-ring': 1.35,
                  'sleep-ring': 0.92,
                  'strain-ring': 0.78,
                },
                centerContent: DonutCenterContent(
                  label: 'RECOVERY',
                  valueMode: DonutCenterValueMode.custom,
                  customValue: '86',
                  labelStyle: LabelStyle(
                    textStyle: TextStyle(
                      color: muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    backgroundColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    borderRadius: 0,
                    padding: EdgeInsets.zero,
                  ),
                  valueStyle: LabelStyle(
                    textStyle: TextStyle(
                      color: text,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                    backgroundColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    borderRadius: 0,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              series: [
                _recoveryRing(
                  id: 'readiness-ring',
                  name: 'Readiness',
                  value: 86,
                  color: mint,
                  remainingColor: const Color(0xFF233147),
                  startAngle: -90,
                ),
                _recoveryRing(
                  id: 'sleep-ring',
                  name: 'Sleep',
                  value: 91,
                  color: const Color(0xFF8B7CFF),
                  remainingColor: const Color(0xFF202B43),
                  startAngle: -68,
                ),
                _recoveryRing(
                  id: 'strain-ring',
                  name: 'Strain',
                  value: 72,
                  color: const Color(0xFF22D3EE),
                  remainingColor: const Color(0xFF1B2940),
                  startAngle: -46,
                ),
              ],
              theme: chartTheme,
              showLegend: false,
              grid: const GridConfig(horizontal: false, vertical: false),
              xAxisConfig: const XAxisConfig(visible: false),
              yAxis: YAxisConfig(position: YAxisPosition.hidden),
              interactionConfig: InteractionConfig.none(),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _RecoveryMetric(
                  icon: Icons.bedtime_rounded,
                  iconColor: Color(0xFF8B9CFF),
                  label: 'Sleep',
                  value: '8h 12m',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _RecoveryMetric(
                  icon: Icons.monitor_heart_rounded,
                  iconColor: mint,
                  label: 'HRV',
                  value: '72 ms',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF111D2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        '7-day balance',
                        style: TextStyle(
                          color: text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Optimal',
                        style: TextStyle(
                          color: mint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 0.74,
                      minHeight: 8,
                      color: mint,
                      backgroundColor: Color(0xFF27364A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: true,
          items: [
            (Icons.insights_rounded, 'Today'),
            (Icons.nights_stay_rounded, 'Sleep'),
            (Icons.fitness_center_rounded, 'Train'),
            (Icons.person_rounded, 'You'),
          ],
        ),
      ],
    );
  }
}

DonutChartSeries _recoveryRing({
  required String id,
  required String name,
  required double value,
  required Color color,
  required Color remainingColor,
  required double startAngle,
}) => DonutChartSeries.fromMap(
  id: id,
  name: name,
  values: {'$name score': value, '$name remaining': 100 - value},
  sliceColors: {'$name score': color, '$name remaining': remainingColor},
  donutStyle: DonutChartStyle(
    innerRadiusFactor: 0.34,
    startAngleDegrees: startAngle,
    sliceGap: 2.4,
    borderWidth: 0.8,
    borderColorMode: PieBorderColorMode.slice,
    borderLightnessShift: -0.24,
    gradient: const PieGradientStyle(
      type: PieGradientType.radial,
      startLightnessShift: 0.30,
      endLightnessShift: -0.18,
    ),
    cornerRadius: 8,
    cornerTreatment: PieCornerTreatment.roundAll,
    shadow: const PieElevationStyle(
      blurRadius: 14,
      spreadRadius: 1.5,
      opacity: 0.42,
    ),
    animationMode: PieAnimationMode.sweep,
  ),
  dataLabels: const PieDataLabelConfig(isVisible: false),
);

class _MatchExperience extends StatelessWidget {
  const _MatchExperience();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF211B30);
    const muted = Color(0xFF776F84);
    const violet = Color(0xFF6D48E5);
    const amber = Color(0xFFF5A524);
    final chartTheme = ChartTheme.light.copyWith(
      backgroundColor: const Color(0xFFF8F7FC),
      seriesTheme: ChartTheme.light.seriesTheme.copyWith(
        colors: const [violet],
      ),
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  _AppMark(
                    background: violet,
                    icon: Icons.sports_soccer_rounded,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Touchline',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Premier division',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _LiveBadge(),
                ],
              ),
              SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TeamMark(label: 'RIV', color: violet),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '2  –  1',
                            style: TextStyle(
                              color: ink,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        Text(
                          '72:18',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14),
                  _TeamMark(label: 'NTH', color: amber),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Momentum',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _LegendDot(color: violet, label: 'River'),
                  SizedBox(width: 7),
                  _LegendDot(color: amber, label: 'North'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          key: const ValueKey('mobile-app-match-chart'),
          height: 190,
          child: BravenChartPlus(
            series: const [
              AreaChartSeries(
                id: 'match-momentum',
                name: 'Momentum',
                color: violet,
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2.5,
                fillOpacity: 0.24,
                baselineValue: 0,
                aboveBaselineFillColor: Color(0x556D48E5),
                belowBaselineFillColor: Color(0x55F5A524),
                points: [
                  ChartDataPoint(x: 0, y: -0.2),
                  ChartDataPoint(x: 8, y: 0.15),
                  ChartDataPoint(x: 16, y: 0.52),
                  ChartDataPoint(x: 24, y: 0.28),
                  ChartDataPoint(x: 32, y: -0.38),
                  ChartDataPoint(x: 40, y: -0.62),
                  ChartDataPoint(x: 48, y: -0.1),
                  ChartDataPoint(x: 56, y: 0.34),
                  ChartDataPoint(x: 64, y: 0.82),
                  ChartDataPoint(x: 72, y: 0.58),
                  ChartDataPoint(x: 80, y: 0.9),
                  ChartDataPoint(x: 90, y: 0.42),
                ],
              ),
            ],
            theme: chartTheme,
            showLegend: false,
            grid: const GridConfig(horizontal: false, vertical: false),
            xAxisConfig: const XAxisConfig(visible: false),
            yAxis: YAxisConfig(position: YAxisPosition.hidden, min: -1, max: 1),
            interactionConfig: InteractionConfig.none(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _PossessionBar(),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _MatchEvent(),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: false,
          activeColor: violet,
          items: [
            (Icons.sports_soccer_rounded, 'Live'),
            (Icons.calendar_month_rounded, 'Fixtures'),
            (Icons.emoji_events_rounded, 'Table'),
            (Icons.star_rounded, 'Following'),
          ],
        ),
      ],
    );
  }
}

class _TrainingLoadExperience extends StatelessWidget {
  const _TrainingLoadExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF10131E);
    const text = Color(0xFFF8FAFC);
    const muted = Color(0xFF9299AA);
    const coral = Color(0xFFFF6B5E);
    const gold = Color(0xFFFFC857);
    final chartTheme = ChartTheme.dark.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.dark.seriesTheme.copyWith(
        colors: const [coral, gold],
      ),
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AppMark(
                    background: Color(0xFF3A211F),
                    icon: Icons.bolt_rounded,
                    iconColor: coral,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summit',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Adaptive training',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(icon: Icons.tune_rounded, color: text, dark: true),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Weekly load window',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '486',
                    style: TextStyle(
                      color: text,
                      fontSize: 36,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5, bottom: 3),
                    child: Text(
                      'TSS',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Spacer(),
                  _StatusPill(
                    label: 'Optimal',
                    color: gold,
                    background: Color(0xFF342D1B),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  _ChartLegendLine(color: coral, label: 'Target range'),
                  SizedBox(width: 14),
                  _ChartLegendLine(color: gold, label: 'Peak load'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          key: const ValueKey('mobile-app-training-range-chart'),
          height: 252,
          child: BravenChartPlus(
            series: const [
              BarChartSeries(
                id: 'load-range',
                name: 'Load range',
                color: coral,
                barWidthPercent: 0.58,
                rangeStartValues: [32, 42, 38, 54, 48, 61, 44],
                barStyle: BarChartStyle(
                  cornerRadius: 9,
                  cornerRadiusPolicy: BarCornerRadiusPolicy.all,
                  gradient: BarGradient(
                    colors: [Color(0xFFFF6B5E), gold],
                    stops: [0, 1],
                  ),
                  border: BarBorderStyle(color: Color(0x66FFF1CC), width: 1),
                  motion: BarMotionStyle(
                    order: BarAnimationOrder.centerOut,
                    staggerFraction: 0.46,
                  ),
                ),
                points: [
                  ChartDataPoint(x: 0, y: 58),
                  ChartDataPoint(x: 1, y: 72),
                  ChartDataPoint(x: 2, y: 68),
                  ChartDataPoint(x: 3, y: 88),
                  ChartDataPoint(x: 4, y: 83),
                  ChartDataPoint(x: 5, y: 98),
                  ChartDataPoint(x: 6, y: 75),
                ],
              ),
            ],
            theme: chartTheme,
            showLegend: false,
            grid: const GridConfig(horizontal: true, vertical: false),
            xAxisConfig: const XAxisConfig(visible: false),
            yAxis: YAxisConfig(
              position: YAxisPosition.hidden,
              min: 20,
              max: 110,
            ),
            interactionConfig: InteractionConfig.none(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Text(
                  day,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _DarkMetric(label: 'Ramp', value: '+7%', color: coral),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DarkMetric(label: 'Form', value: '+12', color: gold),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DarkMetric(
                  label: 'Recovery',
                  value: '31h',
                  color: Color(0xFF8B7CFF),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 1,
          dark: true,
          activeColor: coral,
          items: [
            (Icons.home_rounded, 'Home'),
            (Icons.stacked_bar_chart_rounded, 'Load'),
            (Icons.calendar_month_rounded, 'Plan'),
            (Icons.person_rounded, 'You'),
          ],
        ),
      ],
    );
  }
}

class _HabitStreakExperience extends StatelessWidget {
  const _HabitStreakExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF3FBF7);
    const ink = Color(0xFF15342A);
    const muted = Color(0xFF6C8078);
    const green = Color(0xFF12A66A);
    final chartTheme = ChartTheme.light.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.light.seriesTheme.copyWith(colors: const [green]),
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AppMark(
                    background: Color(0xFFDCF7E9),
                    icon: Icons.local_fire_department_rounded,
                    iconColor: green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loop',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Daily movement',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(icon: Icons.add_rounded, color: ink),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Your consistency is compounding',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'You moved on 24 of the last 28 days.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
              SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '19',
                            style: TextStyle(
                              color: ink,
                              fontSize: 36,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 3),
                            child: Text(
                              'day streak',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _StatusPill(
                    label: 'Best: 23',
                    color: Color(0xFF087A4C),
                    background: Color(0xFFDCF7E9),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDECE5)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
              child: SizedBox(
                key: const ValueKey('mobile-app-habit-heatmap-chart'),
                height: 228,
                child: BravenChartPlus(
                  series: [
                    HeatmapChartSeries(
                      id: 'movement-streak',
                      name: 'Movement minutes',
                      points: _habitHeatmapPoints(),
                      colorScale: HeatmapColorScale.sequential(
                        colors: const [
                          Color(0xFFEAF5EF),
                          Color(0xFFBCEBD2),
                          Color(0xFF60D59B),
                          green,
                          Color(0xFF08623F),
                        ],
                        minimumValue: 0,
                        maximumValue: 4,
                        showLegend: false,
                      ),
                      gapFraction: 0.18,
                      borderColor: const Color(0x2215342A),
                      borderWidth: 0.5,
                      cornerRadius: 4,
                    ),
                  ],
                  theme: chartTheme,
                  showLegend: false,
                  grid: const GridConfig(horizontal: false, vertical: false),
                  xAxisConfig: const XAxisConfig(visible: false),
                  yAxis: YAxisConfig(position: YAxisPosition.hidden),
                  interactionConfig: InteractionConfig.none(),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Row(
            children: [
              _HeatLevel(color: Color(0xFFEAF5EF), label: 'Rest'),
              SizedBox(width: 10),
              _HeatLevel(color: Color(0xFF60D59B), label: 'Goal'),
              SizedBox(width: 10),
              _HeatLevel(color: Color(0xFF08623F), label: 'Peak'),
              Spacer(),
              Text('10 weeks', style: TextStyle(color: muted, fontSize: 9)),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: false,
          activeColor: green,
          items: [
            (Icons.grid_view_rounded, 'Today'),
            (Icons.flag_rounded, 'Goals'),
            (Icons.people_rounded, 'Teams'),
            (Icons.person_rounded, 'You'),
          ],
        ),
      ],
    );
  }
}

class _PickupDensityExperience extends StatelessWidget {
  const _PickupDensityExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF090A0E);
    const text = Color(0xFFF8F5E8);
    const muted = Color(0xFF979388);
    const gold = Color(0xFFFFC400);
    final chartTheme = ChartTheme.dark.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.dark.seriesTheme.copyWith(colors: const [gold]),
    );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AppMark(
                    background: Color(0xFF332A08),
                    icon: Icons.local_taxi_rounded,
                    iconColor: gold,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Citypulse',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Live demand network',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    label: 'LIVE',
                    color: gold,
                    background: Color(0xFF332A08),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Pickup demand is building',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Hexagonal bins preserve every request while revealing hotspots.',
                style: TextStyle(color: muted, fontSize: 11, height: 1.35),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  _DarkMetric(label: 'Active', value: '214', color: gold),
                  SizedBox(width: 10),
                  _DarkMetric(
                    label: 'Peak',
                    value: '18:20',
                    color: Color(0xFFF8F5E8),
                  ),
                  Spacer(),
                  _StatusPill(
                    label: '+18%',
                    color: Color(0xFF75F0B5),
                    background: Color(0xFF123125),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0x263F3400), Color(0x00090A0E)],
                radius: 0.78,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2B281D)),
            ),
            child: SizedBox(
              key: const ValueKey('mobile-app-pickup-hexbin-chart'),
              height: 264,
              child: BravenChartPlus(
                series: [
                  ScatterChartSeries(
                    id: 'pickup-density',
                    name: 'Pickup requests',
                    color: gold,
                    points: _pickupDensityPoints(),
                    isXOrdered: false,
                    markerRadius: 2,
                    renderMode: ScatterRenderMode.hexbin,
                    binConfig: const ScatterBinConfig(
                      cellSize: 22,
                      gap: 1.5,
                      minimumPointCount: 1,
                      minimumOpacity: 0.16,
                      maximumOpacity: 0.96,
                      aggregate: ScatterBinAggregate.count,
                    ),
                  ),
                ],
                theme: chartTheme,
                showLegend: false,
                grid: const GridConfig(horizontal: false, vertical: false),
                xAxisConfig: const XAxisConfig(visible: false),
                yAxis: YAxisConfig(
                  position: YAxisPosition.hidden,
                  min: 8,
                  max: 92,
                ),
                interactionConfig: InteractionConfig.none(),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              _HeatLevel(color: Color(0x33FFC400), label: 'Fewer'),
              SizedBox(width: 10),
              _HeatLevel(color: gold, label: 'More'),
              Spacer(),
              Icon(Icons.schedule_rounded, size: 13, color: muted),
              SizedBox(width: 4),
              Text('Updated now', style: TextStyle(color: muted, fontSize: 9)),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: true,
          activeColor: gold,
          items: [
            (Icons.hexagon_rounded, 'Demand'),
            (Icons.map_rounded, 'Zones'),
            (Icons.route_rounded, 'Trips'),
            (Icons.person_rounded, 'You'),
          ],
        ),
      ],
    );
  }
}

List<HeatmapDataPoint> _habitHeatmapPoints() => [
  for (var week = 0; week < 10; week++)
    for (var day = 0; day < 7; day++)
      HeatmapDataPoint(
        x: week.toDouble(),
        y: day.toDouble(),
        value: ((week * 11 + day * 7 + (week + day) * 3) % 5).toDouble(),
        pointKey: 'habit-$week-$day',
      ),
];

List<ChartDataPoint> _pickupDensityPoints() {
  const centers = [(27.0, 34.0), (67.0, 58.0), (48.0, 78.0)];
  final points = <ChartDataPoint>[];
  for (var index = 0; index < 840; index++) {
    final center = centers[index % centers.length];
    final u = (((index * 37) % 997) + 1) / 998;
    final v = (((index * 61) % 991) + 1) / 992;
    final radius = math.sqrt(-2 * math.log(u)) * (index % 3 == 1 ? 7.8 : 6.4);
    final angle = 2 * math.pi * v;
    points.add(
      ChartDataPoint(
        x: center.$1 + math.cos(angle) * radius,
        y: center.$2 + math.sin(angle) * radius * 0.76,
      ),
    );
  }
  return points;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),
  );
}

class _ChartLegendLine extends StatelessWidget {
  const _ChartLegendLine({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.45), color],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const SizedBox(width: 18, height: 4),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF9299AA), fontSize: 9),
      ),
    ],
  );
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF181D2B),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF272E40)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9299AA), fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeatLevel extends StatelessWidget {
  const _HeatLevel({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.65)),
        ),
        child: const SizedBox(width: 10, height: 10),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF6C8078), fontSize: 9),
      ),
    ],
  );
}

class _AppMark extends StatelessWidget {
  const _AppMark({
    required this.background,
    required this.icon,
    this.iconColor = Colors.white,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(11),
    ),
    child: SizedBox(
      width: 36,
      height: 36,
      child: Icon(icon, size: 20, color: iconColor),
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.color,
    this.dark = false,
  });

  final IconData icon;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF152237) : const Color(0xFFECEFF5),
      shape: BoxShape.circle,
    ),
    child: SizedBox(
      width: 34,
      height: 34,
      child: Icon(icon, size: 18, color: color),
    ),
  );
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE7F8F1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            size: 12,
            color: Color(0xFF137A5B),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF137A5B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, label) in labels.indexed) ...[
        if (index > 0) const SizedBox(width: 5),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: index == 0 ? const Color(0xFF172033) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: index == 0 ? Colors.white : const Color(0xFF697386),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFF697386), fontSize: 10),
      ),
      const SizedBox(height: 4),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit.isNotEmpty)
              TextSpan(
                text: ' $unit',
                style: const TextStyle(color: Color(0xFF697386), fontSize: 9),
              ),
          ],
        ),
      ),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 34,
    width: 20,
    child: VerticalDivider(color: Color(0xFFDDE3EC), thickness: 1),
  );
}

class _RecoveryMetric extends StatelessWidget {
  const _RecoveryMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF111D2E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8D9AAF), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFFE8EC),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: Color(0xFFE64461)),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFB92543),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TeamMark extends StatelessWidget {
  const _TeamMark({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12),
          ],
        ),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.shield_rounded, color: Colors.white, size: 22),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF776F84),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox(width: 6, height: 6),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF776F84), fontSize: 9),
      ),
    ],
  );
}

class _PossessionBar extends StatelessWidget {
  const _PossessionBar();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Row(
        children: [
          Text(
            '58%',
            style: TextStyle(
              color: Color(0xFF6D48E5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Spacer(),
          Text(
            'Possession',
            style: TextStyle(color: Color(0xFF776F84), fontSize: 10),
          ),
          Spacer(),
          Text(
            '42%',
            style: TextStyle(
              color: Color(0xFFD8870D),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: const Row(
          children: [
            Expanded(
              flex: 58,
              child: ColoredBox(
                color: Color(0xFF6D48E5),
                child: SizedBox(height: 7),
              ),
            ),
            Expanded(
              flex: 42,
              child: ColoredBox(
                color: Color(0xFFF5A524),
                child: SizedBox(height: 7),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MatchEvent extends StatelessWidget {
  const _MatchEvent();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E2EF)),
    ),
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFEFEAFC),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 17,
                color: Color(0xFF6D48E5),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal · A. Mensah',
                  style: TextStyle(
                    color: Color(0xFF211B30),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'River takes the lead',
                  style: TextStyle(color: Color(0xFF776F84), fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            "64'",
            style: TextStyle(
              color: Color(0xFF6D48E5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhoneNav extends StatelessWidget {
  const _PhoneNav({
    required this.activeIndex,
    required this.dark,
    required this.items,
    this.activeColor = const Color(0xFF246BFD),
  });

  final int activeIndex;
  final bool dark;
  final List<(IconData, String)> items;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final muted = dark ? const Color(0xFF738198) : const Color(0xFF8B93A3);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0E1828) : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? const Color(0xFF1B293C) : const Color(0xFFE5E9F0),
          ),
        ),
      ),
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            for (final (index, item) in items.indexed)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      size: 19,
                      color: index == activeIndex ? activeColor : muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: index == activeIndex ? activeColor : muted,
                        fontSize: 9,
                        fontWeight: index == activeIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
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
}
