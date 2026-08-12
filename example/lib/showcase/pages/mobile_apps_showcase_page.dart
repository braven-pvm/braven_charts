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
                        const SizedBox(height: 64),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            children: [
                              Text(
                                'Markets, forecasts, and smart systems',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Financial movement, forecast uncertainty, and household energy—three more production-shaped mobile stories, rendered live.',
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
                              'mobile-app-device-gallery-systems',
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
                                      'Personal investing mobile app',
                                  surfaceColor: Color(0xFF0D1524),
                                  dark: true,
                                  child: _MarketExperience(),
                                ),
                              ),
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel: 'Weather forecast mobile app',
                                  surfaceColor: Color(0xFFF4F9FF),
                                  child: _ForecastExperience(),
                                ),
                              ),
                              SizedBox(
                                width: phoneWidth,
                                child: const _PhoneExperience(
                                  semanticLabel: 'Smart home energy mobile app',
                                  surfaceColor: Color(0xFFFCFAF4),
                                  child: _EnergyExperience(),
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

/// Compact live preview used to make the mobile showcase visible from Gallery.
///
/// The preview deliberately reuses the real phone compositions rather than a
/// screenshot. Narrow layouts focus on the recovery experience; wider layouts
/// show three distinct mobile products together.
class MobileAppsGalleryPreview extends StatelessWidget {
  const MobileAppsGalleryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final phoneCount = compact ? 1 : 3;
        final canvasWidth = phoneCount * 344.0 + (phoneCount - 1) * 24.0;

        final phones = compact
            ? const <Widget>[
                SizedBox(
                  width: 344,
                  child: _PhoneExperience(
                    semanticLabel: 'Recovery readiness mobile app',
                    surfaceColor: Color(0xFF0B1220),
                    dark: true,
                    child: _RecoveryExperience(),
                  ),
                ),
              ]
            : const <Widget>[
                SizedBox(
                  width: 344,
                  child: _PhoneExperience(
                    semanticLabel: 'Endurance activity mobile app',
                    surfaceColor: Color(0xFFF7FAFC),
                    child: _EnduranceExperience(),
                  ),
                ),
                SizedBox(width: 24),
                SizedBox(
                  width: 344,
                  child: _PhoneExperience(
                    semanticLabel: 'Recovery readiness mobile app',
                    surfaceColor: Color(0xFF0B1220),
                    dark: true,
                    child: _RecoveryExperience(),
                  ),
                ),
                SizedBox(width: 24),
                SizedBox(
                  width: 344,
                  child: _PhoneExperience(
                    semanticLabel: 'Live match mobile app',
                    surfaceColor: Color(0xFFF8F7FC),
                    child: _MatchExperience(),
                  ),
                ),
              ];

        return SizedBox(
          key: const ValueKey('gallery-mobile-apps-live-preview'),
          height: compact ? 420 : 440,
          child: Semantics(
            image: true,
            label:
                'Live preview of Braven Charts inside focused Flutter mobile apps',
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: canvasWidth,
                    height: 694,
                    child: Row(children: phones),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
              series: [
                DonutChartSeries(
                  id: 'donut-contribution',
                  name: 'Recovery drivers',
                  points: const [
                    ChartDataPoint(
                      x: 0,
                      y: 36,
                      label: 'Sleep',
                      pointStyle: PointStyle(color: Color(0xFF2563EB)),
                    ),
                    ChartDataPoint(
                      x: 1,
                      y: 34,
                      label: 'HRV',
                      pointStyle: PointStyle(color: Color(0xFF0D9488)),
                    ),
                    ChartDataPoint(
                      x: 2,
                      y: 30,
                      label: 'Load',
                      pointStyle: PointStyle(color: Color(0xFF7C3AED)),
                    ),
                  ],
                  unit: '%',
                  donutStyle: const DonutChartStyle(
                    innerRadiusFactor: 0.52,
                    sweepAngleDegrees: 330,
                    startAngleDegrees: 30,
                    radiusFactor: 0.94,
                    sliceGap: 3,
                    borderColorMode: PieBorderColorMode.slice,
                    borderHueShiftDegrees: 0,
                    borderLightnessShift: -0.18,
                    selectionExplodeOffset: 10,
                    opacity: 0.98,
                    cornerRadius: 5,
                    cornerTreatment: PieCornerTreatment.roundAll,
                    animationMode: PieAnimationMode.grow,
                    gradient: PieGradientStyle(
                      startLightnessShift: 0.14,
                      endLightnessShift: -0.08,
                      angleDegrees: -30,
                    ),
                  ),
                  selectionStyle: const RadialSelectionStyle(
                    effect: RadialSelectionEffect.lift,
                    liftScale: 1.1,
                  ),
                  centerContent: const DonutCenterContent(
                    label: 'RECOVERY',
                    valueMode: DonutCenterValueMode.custom,
                    customValue: '86',
                    labelStyle: LabelStyle(
                      textStyle: TextStyle(
                        color: Color(0xFF8D9AAF),
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
                        color: Color(0xFFF8FAFC),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
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
                    minimumShare: 0,
                    minimumSweepDegrees: 0,
                    padding: 0,
                    insideOffset: -6,
                    outsideOffset: 4,
                    connectorLength: 12,
                    connectorColor: Color(0xFF0D9488),
                    calloutStyle: LabelStyle(
                      textStyle: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      borderRadius: 0,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
              xAxisConfig: const XAxisConfig(visible: false),
              yAxis: YAxisConfig(position: YAxisPosition.hidden),
              theme: chartTheme.copyWith(
                backgroundColor: const Color(0xFF0B1220),
                gridStyle: const GridStyle(
                  majorColor: Color(0xFF0B1220),
                  majorWidth: 1,
                  majorDashPattern: [],
                  minorDashPattern: [],
                  showMinor: false,
                ),
                axisStyle: const AxisStyle(
                  lineColor: Color(0xFF000000),
                  lineWidth: 1,
                  labelStyle: TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                  titleStyle: TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                  showTicks: true,
                  tickLength: 6,
                  tickColor: Color(0xFF000000),
                  tickWidth: 1,
                ),
                seriesTheme: SeriesTheme(
                  colors: [
                    const Color(0xFF2563EB),
                    const Color(0xFF0D9488),
                    const Color(0xFF06B6D4),
                    const Color(0xFF7C3AED),
                    const Color(0xFF64748B),
                  ],
                  lineWidths: [2],
                  markerSizes: [6],
                  markerShapes: [SeriesMarkerShape.circle],
                ),
                interactionTheme: const InteractionTheme(
                  crosshairColor: Color(0xFF757575),
                  crosshairWidth: 1,
                  crosshairDashPattern: [5, 3],
                  crosshairBandColor: Color(0x00000000),
                  crosshairBandWidth: 0,
                  crosshairLabelStyle: LabelStyle(
                    textStyle: TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 10,
                    ),
                    backgroundColor: Color(0xFF0B1220),
                    borderColor: Color(0xFFBDBDBD),
                    borderWidth: 0.5,
                    borderRadius: 3,
                    padding: EdgeInsets.fromLTRB(4, 2, 4, 2),
                  ),
                  tooltipStyle: LabelStyle(
                    textStyle: TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 12,
                    ),
                    backgroundColor: Color(0xE6FFFFFF),
                    borderColor: Color(0xFFBDBDBD),
                    borderWidth: 1,
                    borderRadius: 4,
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                    shadowColor: Color(0x33000000),
                    shadowBlurRadius: 4,
                  ),
                  selectionColor: Color(0x4D2196F3),
                ),
                typographyTheme: TypographyTheme(
                  fontFamily: 'Roboto',
                  baseFontSize: 12,
                  scaleFactorMobile: 0.9,
                  scaleFactorTablet: 1,
                  scaleFactorDesktop: 1.1,
                  titleMultiplier: 1.4,
                  labelMultiplier: 1,
                ),
                animationTheme: AnimationTheme(
                  dataUpdateDuration: const Duration(microseconds: 400000),
                  dataUpdateCurve: Curves.easeInOutCubic,
                  themeChangeDuration: const Duration(microseconds: 300000),
                  themeChangeCurve: Curves.easeOut,
                  interactionDuration: const Duration(microseconds: 150000),
                  interactionCurve: Curves.easeOut,
                ),
                annotationTheme: const AnnotationTheme(
                  pointDefaults: PointAnnotationDefaults(
                    markerShape: SeriesMarkerShape.circle,
                    markerSize: 8,
                    normalColor: Color(0xFF2196F3),
                    selectedColor: Color(0xFF1976D2),
                    hoveredColor: Color(0xFF64B5F6),
                    draggingColor: Color(0xFF1976D2),
                    ghostOpacity: 0.3,
                    previewOpacity: 0.8,
                    previewScale: 1.2,
                    labelStyle: LabelStyle(
                      textStyle: TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Roboto',
                      ),
                      backgroundColor: Color(0xF0FFFFFF),
                      borderColor: Color(0xFF2196F3),
                      borderWidth: 0.5,
                      borderRadius: 4,
                      padding: EdgeInsets.fromLTRB(6, 3, 6, 3),
                    ),
                  ),
                  rangeDefaults: RangeAnnotationDefaults(
                    normalFillColor: Color(0x332196F3),
                    selectedFillColor: Color(0x4D2196F3),
                    hoveredFillColor: Color(0x4064B5F6),
                    draggingFillColor: Color(0x4D1976D2),
                    normalBorderColor: Color(0xFF2196F3),
                    selectedBorderColor: Color(0xFF1976D2),
                    hoveredBorderColor: Color(0xFF64B5F6),
                    draggingBorderColor: Color(0xFF1976D2),
                    borderWidth: 1.5,
                    labelStyle: LabelStyle(
                      textStyle: TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                      backgroundColor: Color(0xF0FFFFFF),
                      borderColor: Color(0xFF2196F3),
                      borderWidth: 0.5,
                      borderRadius: 4,
                      padding: EdgeInsets.fromLTRB(6, 3, 6, 3),
                    ),
                  ),
                  textDefaults: TextAnnotationDefaults(
                    textStyle: TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    ),
                    backgroundColor: Color(0xF0FFFFFF),
                    borderColor: Color(0xFFBDBDBD),
                    borderWidth: 0.5,
                    borderRadius: 4,
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                  ),
                  thresholdDefaults: ThresholdAnnotationDefaults(
                    lineColor: Color(0xFFF44336),
                    lineWidth: 2,
                    dashPattern: [5, 3],
                    labelStyle: LabelStyle(
                      textStyle: TextStyle(
                        color: Color(0xFFF44336),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                      backgroundColor: Color(0xF0FFFFFF),
                      borderColor: Color(0xFFF44336),
                      borderWidth: 0.5,
                      borderRadius: 4,
                      padding: EdgeInsets.fromLTRB(6, 3, 6, 3),
                    ),
                  ),
                  trendDefaults: TrendAnnotationDefaults(
                    lineColor: Color(0xFF4CAF50),
                    lineWidth: 2,
                    dashPattern: [5, 5],
                    confidenceBandColor: Color(0xFF4CAF50),
                    confidenceBandOpacity: 0.1,
                    labelStyle: LabelStyle(
                      textStyle: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                      backgroundColor: Color(0xF0FFFFFF),
                      borderColor: Color(0xFF4CAF50),
                      borderWidth: 0.5,
                      borderRadius: 4,
                      padding: EdgeInsets.fromLTRB(6, 3, 6, 3),
                    ),
                  ),
                ),
                scrollbarConfig: const ScrollbarConfig(
                  thickness: 11.5,
                  minHandleSize: 23,
                  trackColor: Color(0xFFF5F5F5),
                  handleColor: Color(0xFFBDBDBD),
                  handleHoverColor: Color(0xFF9E9E9E),
                  edgeZoneColor: Color(0xFFD0D0D0),
                  edgeHoverColor: Color(0xFF2196F3),
                  handleActiveColor: Color(0xFF757575),
                  handleDisabledColor: Color(0xFFEEEEEE),
                  trackHoverColor: Color(0xFFE0E0E0),
                  borderRadius: 4,
                  edgeGripWidth: 40,
                  showGripIndicator: true,
                  gripIndicatorColor: Color(0xFF757575),
                  autoHide: true,
                  autoHideDelay: Duration(microseconds: 2000000),
                  fadeDuration: Duration(microseconds: 200000),
                  enableResizeHandles: true,
                  minZoomRatio: 0.01,
                  maxZoomRatio: 1,
                  padding: 4,
                  forcedColorsMode: false,
                  prefersReducedMotion: false,
                ),
                legendStyle: const LegendStyle(
                  position: LegendPosition.bottomCenter,
                  textStyle: TextStyle(color: Color(0xDD000000), fontSize: 10),
                  backgroundColor: Color(0x99FFFFFF),
                  markerSize: 10,
                  markerShape: LegendMarkerShape.circle,
                ),
                pieChartTheme: const PieChartTheme(
                  opacity: 1,
                  cornerRadius: 0,
                  cornerTreatment: PieCornerTreatment.roundAll,
                  shadow: PieElevationStyle(),
                  selectedElevation: PieElevationStyle(
                    blurRadius: 10,
                    spreadRadius: 1,
                    opacity: 0.38,
                  ),
                  borderColorMode: PieBorderColorMode.chartTheme,
                  borderHueShiftDegrees: 0,
                  borderSaturationShift: 0,
                  borderLightnessShift: -0.12,
                  animationMode: PieAnimationMode.grow,
                ),
                candlestickTheme: const CandlestickTheme(
                  risingBodyFillColor: Color(0xFFCCFBF1),
                  fallingBodyFillColor: Color(0xFFEF4444),
                  dojiBodyFillColor: Color(0xFF64748B),
                  risingBorderColor: Color(0xFF0F766E),
                  fallingBorderColor: Color(0xFFB91C1C),
                  dojiBorderColor: Color(0xFF475569),
                  risingWickColor: Color(0xFF0F766E),
                  fallingWickColor: Color(0xFFB91C1C),
                  dojiWickColor: Color(0xFF475569),
                  selectionColor: Color(0xFF2563EB),
                  focusColor: Color(0xFF334155),
                ),
                rangeAreaTheme: const RangeAreaTheme(
                  fillOpacity: 0.26,
                  boundaryOpacity: 0.92,
                  boundaryWidth: 1.5,
                  markerFillColor: Color(0xFFFFFFFF),
                  markerStrokeColor: Color(0xFF2563EB),
                  markerStrokeWidth: 1.5,
                  selectionColor: Color(0xFF2563EB),
                  focusColor: Color(0xFF334155),
                ),
                focusBorderColor: const Color(0xFF2196F3),
                focusBorderWidth: 2,
                focusBorderRadius: 0,
              ),
              interactionConfig: const InteractionConfig(
                enableZoom: false,
                enablePan: false,
                crosshair: CrosshairConfig(enabled: false),
                tooltip: TooltipConfig(triggerMode: TooltipTriggerMode.both),
              ),
              showLegend: false,
              legendStyle: const LegendStyle(
                position: LegendPosition.bottomCenter,
                textStyle: TextStyle(color: Color(0xDD000000), fontSize: 10),
                backgroundColor: Color(0x99FFFFFF),
                markerSize: 10,
                markerShape: LegendMarkerShape.circle,
              ),
              backgroundColor: surface,
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
                unit: 'TSS',
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
                labelStyle: BarLabelStyle(
                  show: true,
                  position: BarLabelPosition.rangeEnds,
                  valueMode: BarLabelValueMode.range,
                  color: Color(0xFFF8FAFC),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  padding: 3,
                  collisionPolicy: BarLabelCollisionPolicy.reposition,
                  collisionPadding: 2,
                  backgroundColor: Color(0xCC10131E),
                  borderColor: Color(0x55FFC857),
                  borderWidth: 0.6,
                  borderRadius: 4,
                  backgroundPadding: 2,
                ),
                points: [
                  ChartDataPoint(x: 0, y: 58, label: 'Monday'),
                  ChartDataPoint(x: 1, y: 72, label: 'Tuesday'),
                  ChartDataPoint(x: 2, y: 68, label: 'Wednesday'),
                  ChartDataPoint(x: 3, y: 88, label: 'Thursday'),
                  ChartDataPoint(x: 4, y: 83, label: 'Friday'),
                  ChartDataPoint(x: 5, y: 98, label: 'Saturday'),
                  ChartDataPoint(x: 6, y: 75, label: 'Sunday'),
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
      axisStyle: ChartTheme.light.axisStyle.copyWith(
        lineColor: Colors.transparent,
        lineWidth: 0,
        labelStyle: const TextStyle(
          color: muted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
        showTicks: false,
        tickLength: 0,
        tickColor: Colors.transparent,
        tickWidth: 0,
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
                      emptyValueStyle: const HeatmapEmptyValueStyle(
                        fillColor: Color(0xFFEAF5EF),
                        showInLegend: false,
                        legendLabel: 'Rest day',
                      ),
                    ),
                  ],
                  theme: chartTheme,
                  showLegend: false,
                  grid: const GridConfig(horizontal: false, vertical: false),
                  xAxisConfig: const XAxisConfig(
                    showAxisLine: false,
                    showTicks: false,
                    minHeight: 24,
                    maxHeight: 24,
                    tickLabelPadding: 2,
                    axisMargin: 0,
                    categoryAxis: CategoryAxisConfig(
                      categories: [
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                        '9',
                        '10',
                      ],
                      minimumCategoryExtent: 20,
                      maximumLabelExtent: 20,
                    ),
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
                    showAxisLine: false,
                    showTicks: false,
                    minWidth: 30,
                    maxWidth: 30,
                    tickLabelPadding: 3,
                    axisMargin: 0,
                    categoryAxis: const CategoryAxisConfig(
                      categories: [
                        'Sun',
                        'Sat',
                        'Fri',
                        'Thu',
                        'Wed',
                        'Tue',
                        'Mon',
                      ],
                      minimumCategoryExtent: 24,
                      maximumLabelExtent: 28,
                    ),
                  ),
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

List<HeatmapDataPoint> _habitHeatmapPoints() {
  const weeklyActivity = <List<double>>[
    [0, 2, 4, 3, 0, 1, 3],
    [3, 0, 2, 4, 3, 0, 2],
    [1, 4, 3, 0, 2, 4, 0],
    [4, 2, 0, 3, 4, 1, 2],
    [2, 3, 4, 1, 0, 3, 4],
    [0, 1, 2, 0, 3, 4, 2],
    [4, 3, 2, 4, 3, 2, 4],
    [3, 0, 4, 3, 2, 4, 3],
    [2, 4, 3, 0, 4, 3, 2],
    [4, 3, 0, 4, 3, 2, 0],
  ];

  return [
    for (final (week, days) in weeklyActivity.indexed)
      for (final (day, value) in days.indexed)
        HeatmapDataPoint(
          x: week.toDouble(),
          y: day.toDouble(),
          value: value,
          pointKey: 'habit-$week-$day',
        ),
  ];
}

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

class _MarketExperience extends StatelessWidget {
  const _MarketExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF0D1524);
    const text = Color(0xFFF8FAFC);
    const muted = Color(0xFF8D9AAF);
    const mint = Color(0xFF35D0A0);
    const coral = Color(0xFFFF6B7A);
    final chartTheme = ChartTheme.dark.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.dark.seriesTheme.copyWith(
        colors: const [mint, coral, Color(0xFF7AA2FF)],
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
                    background: Color(0xFF14372F),
                    icon: Icons.candlestick_chart_rounded,
                    iconColor: mint,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ledger',
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Personal investing',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    label: 'OPEN',
                    color: mint,
                    background: Color(0xFF14372F),
                  ),
                ],
              ),
              SizedBox(height: 22),
              Text(
                'Portfolio value',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        '\$24,680',
                        style: TextStyle(
                          color: text,
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  _StatusPill(
                    label: '+4.8%',
                    color: mint,
                    background: Color(0xFF14372F),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _ChartLegendLine(
                color: Color(0xFF7AA2FF),
                label: '20-day average',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          key: const ValueKey('mobile-app-market-chart'),
          height: 235,
          child: BravenChartPlus(
            series: [
              CandlestickChartSeries(
                id: 'mobile-market-price',
                name: 'Price',
                candlestickStyle: const CandlestickChartStyle(
                  risingBodyFillColor: mint,
                  risingBorderColor: mint,
                  risingWickColor: mint,
                  fallingBodyFillColor: coral,
                  fallingBorderColor: coral,
                  fallingWickColor: coral,
                  bodyFillMode: CandlestickBodyFillMode.filled,
                  bodyCornerRadius: 2,
                ),
                points: [
                  CandlestickDataPoint(
                    x: 1,
                    open: 42,
                    high: 48,
                    low: 40,
                    close: 46,
                  ),
                  CandlestickDataPoint(
                    x: 2,
                    open: 46,
                    high: 50,
                    low: 44,
                    close: 48,
                  ),
                  CandlestickDataPoint(
                    x: 3,
                    open: 48,
                    high: 49,
                    low: 42,
                    close: 44,
                  ),
                  CandlestickDataPoint(
                    x: 4,
                    open: 44,
                    high: 52,
                    low: 43,
                    close: 50,
                  ),
                  CandlestickDataPoint(
                    x: 5,
                    open: 50,
                    high: 56,
                    low: 48,
                    close: 54,
                  ),
                  CandlestickDataPoint(
                    x: 6,
                    open: 54,
                    high: 55,
                    low: 50,
                    close: 51,
                  ),
                  CandlestickDataPoint(
                    x: 7,
                    open: 51,
                    high: 59,
                    low: 50,
                    close: 57,
                  ),
                  CandlestickDataPoint(
                    x: 8,
                    open: 57,
                    high: 62,
                    low: 55,
                    close: 60,
                  ),
                  CandlestickDataPoint(
                    x: 9,
                    open: 60,
                    high: 61,
                    low: 54,
                    close: 56,
                  ),
                  CandlestickDataPoint(
                    x: 10,
                    open: 56,
                    high: 64,
                    low: 55,
                    close: 62,
                  ),
                ],
              ),
              const LineChartSeries(
                id: 'mobile-market-average',
                name: 'Average',
                color: Color(0xFF7AA2FF),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2,
                points: [
                  ChartDataPoint(x: 1, y: 44),
                  ChartDataPoint(x: 2, y: 45),
                  ChartDataPoint(x: 3, y: 45.5),
                  ChartDataPoint(x: 4, y: 47),
                  ChartDataPoint(x: 5, y: 49),
                  ChartDataPoint(x: 6, y: 50.5),
                  ChartDataPoint(x: 7, y: 53),
                  ChartDataPoint(x: 8, y: 55.5),
                  ChartDataPoint(x: 9, y: 57),
                  ChartDataPoint(x: 10, y: 59),
                ],
              ),
            ],
            theme: chartTheme,
            showLegend: false,
            grid: const GridConfig(horizontal: true, vertical: false),
            xAxisConfig: const XAxisConfig(visible: false),
            yAxis: YAxisConfig(position: YAxisPosition.hidden),
            interactionConfig: InteractionConfig.none(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Day high',
                  value: '\$64.20',
                  unit: '',
                  dark: true,
                ),
              ),
              _MetricDivider(dark: true),
              Expanded(
                child: _Metric(
                  label: 'Volume',
                  value: '1.8M',
                  unit: '',
                  dark: true,
                ),
              ),
              _MetricDivider(dark: true),
              Expanded(
                child: _Metric(
                  label: 'Risk',
                  value: 'Low',
                  unit: '',
                  dark: true,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: true,
          activeColor: mint,
          items: [
            (Icons.show_chart_rounded, 'Markets'),
            (Icons.pie_chart_rounded, 'Portfolio'),
            (Icons.receipt_long_rounded, 'Orders'),
            (Icons.person_rounded, 'You'),
          ],
        ),
      ],
    );
  }
}

class _ForecastExperience extends StatelessWidget {
  const _ForecastExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF4F9FF);
    const ink = Color(0xFF17324D);
    const muted = Color(0xFF6A7D91);
    const blue = Color(0xFF3689FF);
    const sky = Color(0xFF8BD3FF);
    final chartTheme = ChartTheme.light.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.light.seriesTheme.copyWith(
        colors: const [sky, blue],
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
                    background: Color(0xFFDDEEFF),
                    icon: Icons.cloud_rounded,
                    iconColor: blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skyline',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Cape Town forecast',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(icon: Icons.location_on_rounded, color: ink),
                ],
              ),
              SizedBox(height: 22),
              Text(
                'A clearer afternoon',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The forecast band narrows after midday.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '23°',
                    style: TextStyle(
                      color: ink,
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Feels like 22°',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          key: const ValueKey('mobile-app-forecast-chart'),
          height: 220,
          child: BravenChartPlus(
            series: [
              RangeAreaChartSeries(
                id: 'mobile-weather-range',
                name: 'Expected range',
                color: sky,
                interpolation: LineInterpolation.monotone,
                fillOpacity: 0.34,
                points: [
                  RangeAreaDataPoint(x: 6, low: 14, high: 18),
                  RangeAreaDataPoint(x: 8, low: 15, high: 20),
                  RangeAreaDataPoint(x: 10, low: 17, high: 22),
                  RangeAreaDataPoint(x: 12, low: 19, high: 24),
                  RangeAreaDataPoint(x: 14, low: 20, high: 25),
                  RangeAreaDataPoint(x: 16, low: 19, high: 24),
                  RangeAreaDataPoint(x: 18, low: 18, high: 22),
                  RangeAreaDataPoint(x: 20, low: 16, high: 20),
                ],
              ),
              const LineChartSeries(
                id: 'mobile-weather-centre',
                name: 'Forecast',
                color: blue,
                interpolation: LineInterpolation.monotone,
                strokeWidth: 3,
                showDataPointMarkers: true,
                dataPointMarkerRadius: 2.5,
                points: [
                  ChartDataPoint(x: 6, y: 16),
                  ChartDataPoint(x: 8, y: 17.5),
                  ChartDataPoint(x: 10, y: 19.5),
                  ChartDataPoint(x: 12, y: 21.5),
                  ChartDataPoint(x: 14, y: 23),
                  ChartDataPoint(x: 16, y: 22),
                  ChartDataPoint(x: 18, y: 20),
                  ChartDataPoint(x: 20, y: 18),
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
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _Metric(label: 'Rain', value: '12', unit: '%'),
              ),
              _MetricDivider(),
              Expanded(
                child: _Metric(label: 'Wind', value: '18', unit: 'km/h'),
              ),
              _MetricDivider(),
              Expanded(
                child: _Metric(label: 'UV', value: '5', unit: 'moderate'),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: false,
          activeColor: blue,
          items: [
            (Icons.wb_sunny_rounded, 'Today'),
            (Icons.calendar_view_week_rounded, '10 day'),
            (Icons.map_rounded, 'Map'),
            (Icons.tune_rounded, 'Details'),
          ],
        ),
      ],
    );
  }
}

class _EnergyExperience extends StatelessWidget {
  const _EnergyExperience();

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFFCFAF4);
    const ink = Color(0xFF253027);
    const muted = Color(0xFF738077);
    const green = Color(0xFF2E9E62);
    const amber = Color(0xFFF6B73C);
    final chartTheme = ChartTheme.light.copyWith(
      backgroundColor: surface,
      seriesTheme: ChartTheme.light.seriesTheme.copyWith(
        colors: const [green, amber, Color(0xFFEF6A5B)],
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
                    background: Color(0xFFE3F4E8),
                    icon: Icons.bolt_rounded,
                    iconColor: green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Watt',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Smart home energy',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    label: 'LIVE',
                    color: green,
                    background: Color(0xFFE3F4E8),
                  ),
                ],
              ),
              SizedBox(height: 22),
              Text(
                'Running below target',
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Live household load against today’s efficiency goal.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: const ValueKey('mobile-app-energy-gauge-chart'),
          height: 285,
          child: BravenChartPlus(
            series: [
              GaugeChartSeries.needle(
                id: 'mobile-energy-load',
                name: 'Household load',
                metric: 'Live load',
                unit: 'kW',
                value: 3.2,
                minimum: 0,
                maximum: 6,
                color: green,
                target: const GaugeTarget(
                  value: 4,
                  label: 'Target',
                  color: amber,
                ),
                zones: const [
                  GaugeZone(
                    from: 0,
                    to: 3.5,
                    status: 'Efficient',
                    color: green,
                  ),
                  GaugeZone(from: 3.5, to: 4.5, status: 'Watch', color: amber),
                  GaugeZone(
                    from: 4.5,
                    to: 6,
                    status: 'High',
                    color: Color(0xFFEF6A5B),
                  ),
                ],
                style: const NeedleGaugeStyle(
                  needleColor: green,
                  pivotColor: green,
                  axisColor: Color(0xFFE2DED2),
                  axisThickness: 14,
                ),
              ),
            ],
            theme: chartTheme,
            showLegend: false,
            grid: const GridConfig(horizontal: false, vertical: false),
            xAxisConfig: const XAxisConfig(visible: false),
            yAxis: YAxisConfig(position: YAxisPosition.hidden),
            gaugeChartConfig: const GaugeChartConfig(
              pane: PolarPaneConfig(
                startAngleDegrees: -135,
                sweepAngleDegrees: 270,
                innerRadiusFactor: 0.5,
                outerRadiusFactor: 0.92,
              ),
              tickCount: 7,
              showTickLabels: true,
              center: GaugeCenterConfig(
                showMetric: true,
                showValue: true,
                showTarget: true,
                showStatus: true,
              ),
            ),
            interactionConfig: InteractionConfig.none(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _Metric(label: 'Solar', value: '2.1', unit: 'kW'),
              ),
              _MetricDivider(),
              Expanded(
                child: _Metric(label: 'Grid', value: '1.1', unit: 'kW'),
              ),
              _MetricDivider(),
              Expanded(
                child: _Metric(label: 'Saved', value: '18', unit: '%'),
              ),
            ],
          ),
        ),
        const Spacer(),
        const _PhoneNav(
          activeIndex: 0,
          dark: false,
          activeColor: green,
          items: [
            (Icons.bolt_rounded, 'Live'),
            (Icons.solar_power_rounded, 'Solar'),
            (Icons.insights_rounded, 'History'),
            (Icons.settings_rounded, 'Home'),
          ],
        ),
      ],
    );
  }
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
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    this.dark = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool dark;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: dark ? const Color(0xFF8D9AAF) : const Color(0xFF697386),
          fontSize: 10,
        ),
      ),
      const SizedBox(height: 4),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: dark ? const Color(0xFFF8FAFC) : const Color(0xFF172033),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit.isNotEmpty)
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: dark
                      ? const Color(0xFF8D9AAF)
                      : const Color(0xFF697386),
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    width: 20,
    child: VerticalDivider(
      color: dark ? const Color(0xFF273449) : const Color(0xFFDDE3EC),
      thickness: 1,
    ),
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
