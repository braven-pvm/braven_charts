// Copyright 2025 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

const _powerOrange = Color(0xFFF97316);
const _heartRateBlue = Color(0xFF3B82F6);
const _vo2Indigo = Color(0xFF2563EB);
const _lactateRed = Color(0xFFFF4D5A);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _cadenceTeal = Color(0xFF0F9F8F);

/// Selects which analytical composition the package hero renders.
enum PerformanceIntelligenceHeroPanel { both, sessionProfile, powerDuration }

/// Two visually distinct analytical compositions for the package hero.
class PerformanceIntelligenceGalleryHero extends StatelessWidget {
  const PerformanceIntelligenceGalleryHero({
    super.key,
    this.panel = PerformanceIntelligenceHeroPanel.both,
    this.showTracking = true,
  });

  final PerformanceIntelligenceHeroPanel panel;
  final bool showTracking;

  static const _nightCyan = Color(0xFF22D3EE);
  static const _nightMint = Color(0xFF34D399);
  static const _nightViolet = Color(0xFFA78BFA);
  static const _nightBlue = Color(0xFF60A5FA);
  static const _darkAnnotationStyle = AnnotationStyle(
    textStyle: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE2E8F0),
    ),
    backgroundColor: Color(0xCC111827),
    borderColor: Color(0xFF475569),
    borderWidth: 0.8,
    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  );

  static const _sessionPower = [
    ChartDataPoint(x: 0, y: 126),
    ChartDataPoint(x: 1, y: 142),
    ChartDataPoint(x: 2, y: 158),
    ChartDataPoint(x: 3, y: 184),
    ChartDataPoint(x: 4, y: 208),
    ChartDataPoint(x: 5, y: 226),
    ChartDataPoint(x: 6, y: 214),
    ChartDataPoint(x: 7, y: 192),
    ChartDataPoint(x: 8, y: 168),
    ChartDataPoint(x: 9, y: 146),
    ChartDataPoint(x: 10, y: 132),
  ];

  static const _sessionHeartRate = [
    ChartDataPoint(x: 0, y: 104),
    ChartDataPoint(x: 1, y: 112),
    ChartDataPoint(x: 2, y: 124),
    ChartDataPoint(x: 3, y: 139),
    ChartDataPoint(x: 4, y: 151),
    ChartDataPoint(x: 5, y: 162),
    ChartDataPoint(x: 6, y: 168),
    ChartDataPoint(x: 7, y: 164),
    ChartDataPoint(x: 8, y: 152),
    ChartDataPoint(x: 9, y: 136),
    ChartDataPoint(x: 10, y: 120),
  ];

  static final _shortDuration = _distributionCurve(
    center: 74,
    spread: 34,
    amplitude: 34,
    ripple: 4.5,
  );
  static final _thresholdDuration = _distributionCurve(
    center: 205,
    spread: 52,
    amplitude: 46,
    ripple: 2.2,
  );
  static final _enduranceDuration = _distributionCurve(
    center: 285,
    spread: 68,
    amplitude: 31,
    ripple: 1.6,
  );
  static final _sessionContextA = _distributionCurve(
    center: 172,
    spread: 44,
    amplitude: 37,
    ripple: 6.0,
    phase: 0.7,
  );
  static final _sessionContextB = _distributionCurve(
    center: 248,
    spread: 39,
    amplitude: 41,
    ripple: 5.2,
    phase: 1.8,
  );
  static final _readinessDelta = List<ChartDataPoint>.generate(41, (index) {
    final x = index * 10.0;
    final y =
        (13 * sin((x - 30) / 54)) -
        (8 * exp(-pow((x - 205) / 62, 2))) -
        ((x - 210) * 0.025);
    return ChartDataPoint(x: x, y: y.toDouble());
  });

  static List<ChartDataPoint> _distributionCurve({
    required double center,
    required double spread,
    required double amplitude,
    required double ripple,
    double phase = 0,
  }) {
    return List<ChartDataPoint>.generate(41, (index) {
      final x = index * 10.0;
      final gaussian = amplitude * exp(-pow((x - center) / spread, 2));
      final texture = ripple * sin((x / 23) + phase) * exp(-x / 520);
      return ChartDataPoint(x: x, y: max(0.5, 2.5 + gaussian + texture));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (panel == PerformanceIntelligenceHeroPanel.sessionProfile) {
      return _buildSessionProfileChart();
    }
    if (panel == PerformanceIntelligenceHeroPanel.powerDuration) {
      return _buildDurationModelChart();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 960;
        final charts = [
          Expanded(child: _buildSessionProfileChart()),
          Expanded(child: _buildDurationModelChart()),
        ];
        if (compact) {
          return Column(
            children: [charts.first, const SizedBox(height: 16), charts.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [charts.first, const SizedBox(width: 16), charts.last],
        );
      },
    );
  }

  Widget _buildSessionProfileChart() {
    return _FlagshipCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Training load and response',
      subtitle:
          'Power area, heart-rate response, stage bands, threshold, and tracking',
      badges: const ['Line + area', '2 axes', 'Stages', 'Tracking'],
      interactionHint: 'Hover to compare both signals · drag to pan',
      surfaceColor: const Color(0xFFF8FAFC),
      child: BravenChartPlus(
        series: [
          AreaChartSeries(
            id: 'session-power',
            name: 'Power',
            unit: 'W',
            points: _sessionPower,
            color: _powerOrange,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.25,
            fillOpacity: 0.13,
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
              color: _powerOrange,
              min: 110,
              max: 240,
            ),
          ),
          LineChartSeries(
            id: 'session-heart-rate',
            name: 'Heart rate',
            unit: 'bpm',
            points: _sessionHeartRate,
            color: _heartRateBlue,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.5,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 2.75,
            lineGlow: 1.5,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Heart rate',
              position: SeriesLabelPosition.right,
              offsetY: -8,
              color: _heartRateBlue,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Heart rate',
              unit: 'bpm',
              color: _heartRateBlue,
              min: 95,
              max: 175,
            ),
          ),
        ],
        annotations: [
          RangeAnnotation(
            id: 'session-warm-up',
            startX: 0,
            endX: 2.5,
            label: 'Warm-up',
            fillColor: const Color(0x103B82F6),
            borderColor: const Color(0x223B82F6),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'session-work',
            startX: 2.5,
            endX: 7.5,
            label: 'Work block',
            fillColor: const Color(0x10F97316),
            borderColor: const Color(0x22F97316),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'session-recovery',
            startX: 7.5,
            endX: 10,
            label: 'Recovery',
            fillColor: const Color(0x1010B981),
            borderColor: const Color(0x2210B981),
            allowDragging: false,
            allowEditing: false,
          ),
          ThresholdAnnotation(
            id: 'session-threshold',
            axis: AnnotationAxis.y,
            value: 200,
            seriesId: 'session-power',
            label: 'Target · 200 W',
            lineColor: _powerOrange,
            lineWidth: 1.2,
            dashPattern: const [5, 4],
            allowDragging: false,
            allowEditing: false,
          ),
          PointAnnotation(
            id: 'session-peak',
            seriesId: 'session-heart-rate',
            dataPointIndex: 6,
            label: 'Peak · 168 bpm',
            markerShape: MarkerShape.star,
            markerSize: 8,
            markerColor: _heartRateBlue,
            allowDragging: false,
            allowEditing: false,
          ),
        ],
        theme: ChartTheme.light,
        showLegend: true,
        legendStyle: const LegendStyle(
          position: LegendPosition.topRight,
          orientation: LegendOrientation.horizontal,
          textStyle: TextStyle(fontSize: 9, color: Color(0xFF475569)),
          backgroundColor: Color(0xDFFFFFFF),
          markerSize: 11,
          itemSpacing: 8,
          allowDragging: false,
        ),
        normalizationMode: NormalizationMode.perSeries,
        xAxisConfig: const XAxisConfig(
          label: 'Session time',
          min: -0.15,
          max: 10.15,
        ),
        yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
        interactionConfig: InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(
            enabled: showTracking,
            mode: CrosshairMode.both,
            snapToDataPoint: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          tooltip: TooltipConfig(enabled: showTracking),
        ),
      ),
    );
  }

  Widget _buildDurationModelChart() {
    YAxisConfig hiddenShareAxis() =>
        YAxisConfig(position: YAxisPosition.hidden, min: 0, max: 55);

    return _FlagshipCard(
      icon: Icons.multiline_chart,
      title: 'Adaptive power-duration model',
      subtitle:
          'Cohort distributions, baseline delta, duration sections, glow, and LT1',
      badges: const ['Dark theme', '6 curves', 'Baseline fill', 'Glow'],
      interactionHint: 'Drag to pan · synchronized scrollbar follows',
      darkSurface: true,
      child: BravenChartPlus(
        series: [
          AreaChartSeries(
            id: 'readiness-delta',
            name: 'Readiness delta',
            unit: '%',
            points: _readinessDelta,
            color: _nightCyan,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.5,
            fillOpacity: 0.06,
            baselineValue: 0,
            aboveBaselineFillColor: const Color(0x4434D399),
            belowBaselineFillColor: const Color(0x44FB7185),
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Readiness Δ',
              position: SeriesLabelPosition.right,
              offsetY: -9,
              color: _nightCyan,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Readiness',
              unit: '%',
              color: _nightCyan,
              min: -24,
              max: 24,
            ),
          ),
          LineChartSeries(
            id: 'session-context-a',
            name: 'Session 04',
            unit: '%',
            points: _sessionContextA,
            color: _nightBlue.withValues(alpha: 0.42),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.0,
            yAxisConfig: hiddenShareAxis(),
          ),
          LineChartSeries(
            id: 'session-context-b',
            name: 'Session 11',
            unit: '%',
            points: _sessionContextB,
            color: _nightViolet.withValues(alpha: 0.40),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.0,
            yAxisConfig: hiddenShareAxis(),
          ),
          AreaChartSeries(
            id: 'short-duration-load',
            name: 'Short duration',
            unit: '%',
            points: _shortDuration,
            color: _nightBlue,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.8,
            fillOpacity: 0.07,
            lineGlow: 3,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Short',
              position: SeriesLabelPosition.center,
              offsetY: -8,
              color: _nightBlue,
            ),
            yAxisConfig: hiddenShareAxis(),
          ),
          AreaChartSeries(
            id: 'threshold-duration-load',
            name: 'Threshold duration',
            unit: '%',
            points: _thresholdDuration,
            color: _nightViolet,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.8,
            fillOpacity: 0.13,
            lineGlow: 6,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Threshold',
              position: SeriesLabelPosition.center,
              offsetY: -10,
              color: _nightViolet,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Session share',
              unit: '%',
              color: _nightViolet,
              min: 0,
              max: 55,
            ),
          ),
          AreaChartSeries(
            id: 'endurance-duration-load',
            name: 'Endurance duration',
            unit: '%',
            points: _enduranceDuration,
            color: _nightMint,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.0,
            fillOpacity: 0.08,
            lineGlow: 3.5,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Endurance',
              position: SeriesLabelPosition.right,
              offsetY: -8,
              color: _nightMint,
            ),
            yAxisConfig: hiddenShareAxis(),
          ),
        ],
        annotations: [
          RangeAnnotation(
            id: 'duration-neuromuscular',
            startX: 0,
            endX: 120,
            label: 'Neuromuscular',
            style: _darkAnnotationStyle,
            fillColor: const Color(0x1422D3EE),
            borderColor: const Color(0x3322D3EE),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'duration-threshold',
            startX: 120,
            endX: 250,
            label: 'Threshold',
            style: _darkAnnotationStyle,
            fillColor: const Color(0x14A78BFA),
            borderColor: const Color(0x33A78BFA),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'duration-endurance',
            startX: 250,
            endX: 400,
            label: 'Endurance',
            style: _darkAnnotationStyle,
            fillColor: const Color(0x1434D399),
            borderColor: const Color(0x3334D399),
            allowDragging: false,
            allowEditing: false,
          ),
          ThresholdAnnotation(
            id: 'duration-lt1',
            axis: AnnotationAxis.x,
            value: 199,
            label: 'LT1 · 199 W',
            style: _darkAnnotationStyle,
            lineColor: const Color(0xFFFACC15),
            lineWidth: 1.4,
            dashPattern: const [5, 4],
            labelPosition: AnnotationLabelPosition.bottomLeft,
            elevation: 3,
            allowDragging: false,
            allowEditing: false,
          ),
          PointAnnotation(
            id: 'duration-peak',
            seriesId: 'threshold-duration-load',
            dataPointIndex: 20,
            label: 'Peak share',
            style: _darkAnnotationStyle,
            markerShape: MarkerShape.diamond,
            markerSize: 8,
            markerColor: _nightViolet,
            allowDragging: false,
            allowEditing: false,
          ),
        ],
        theme: ChartTheme.dark,
        showLegend: false,
        showXScrollbar: true,
        scrollbarTheme: ScrollbarConfig.defaultDark.copyWith(autoHide: false),
        normalizationMode: NormalizationMode.perSeries,
        xAxisConfig: const XAxisConfig(
          label: 'Power',
          unit: 'W',
          min: -5,
          max: 405,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Session share',
        ),
        interactionConfig: InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(
            enabled: showTracking,
            mode: CrosshairMode.both,
            snapToDataPoint: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          tooltip: TooltipConfig(enabled: showTracking),
        ),
      ),
    );
  }
}

/// Flagship composition inspired by real multi-sensor performance analysis.
class PhysiologySessionGalleryCard extends StatelessWidget {
  const PhysiologySessionGalleryCard({super.key});

  static const _power = [
    ChartDataPoint(x: 0, y: 186),
    ChartDataPoint(x: 2, y: 166),
    ChartDataPoint(x: 4, y: 173),
    ChartDataPoint(x: 6, y: 136),
    ChartDataPoint(x: 8, y: 126),
    ChartDataPoint(x: 10, y: 132),
    ChartDataPoint(x: 12, y: 113),
    ChartDataPoint(x: 14, y: 104),
    ChartDataPoint(x: 16, y: 96),
    ChartDataPoint(x: 18, y: 92),
    ChartDataPoint(x: 20, y: 100),
    ChartDataPoint(x: 22, y: 106),
    ChartDataPoint(x: 24, y: 112),
  ];

  static const _heartRate = [
    ChartDataPoint(x: 0, y: 158),
    ChartDataPoint(x: 2, y: 146),
    ChartDataPoint(x: 4, y: 151),
    ChartDataPoint(x: 6, y: 132),
    ChartDataPoint(x: 8, y: 127),
    ChartDataPoint(x: 10, y: 130),
    ChartDataPoint(x: 12, y: 119),
    ChartDataPoint(x: 14, y: 108),
    ChartDataPoint(x: 16, y: 104),
    ChartDataPoint(x: 18, y: 99),
    ChartDataPoint(x: 20, y: 101),
    ChartDataPoint(x: 22, y: 107),
    ChartDataPoint(x: 24, y: 111),
  ];

  static const _vo2 = [
    ChartDataPoint(x: 6, y: 34.6),
    ChartDataPoint(x: 12, y: 30.5),
    ChartDataPoint(x: 18, y: 24.2),
    ChartDataPoint(x: 24, y: 30.2),
  ];

  static const _lactate = [
    ChartDataPoint(x: 6, y: 2.2),
    ChartDataPoint(x: 12, y: 1.3),
    ChartDataPoint(x: 18, y: 1.4),
    ChartDataPoint(x: 24, y: 2.7),
  ];

  static final _powerSignal = _sampleSignal(
    _power,
    amplitude: 8.5,
    frequency: 1.85,
    ripple: 3.5,
  );

  static final _heartRateSignal = _sampleSignal(
    _heartRate,
    amplitude: 5.0,
    frequency: 1.55,
    ripple: 2.4,
    phase: 0.65,
  );

  static final _cadence = List<ChartDataPoint>.generate(49, (index) {
    final x = index / 2;
    final stageDrift = x < 6
        ? 4.5
        : x < 12
        ? 1.0
        : x < 18
        ? -5.0
        : 0.5;
    final y = 56 + stageDrift + 5.5 * sin(x * 1.7) + 3.5 * cos(x * 3.35 + 0.4);
    return ChartDataPoint(x: x, y: y.clamp(42, 68).toDouble());
  });

  static List<ChartDataPoint> _sampleSignal(
    List<ChartDataPoint> anchors, {
    required double amplitude,
    required double frequency,
    required double ripple,
    double phase = 0,
  }) {
    return List<ChartDataPoint>.generate(97, (index) {
      final x = index / 4;
      final anchorIndex = (x / 2).floor().clamp(0, anchors.length - 2);
      final start = anchors[anchorIndex];
      final end = anchors[anchorIndex + 1];
      final fraction = (x - start.x) / (end.x - start.x);
      final baseline = start.y + ((end.y - start.y) * fraction);
      final noise =
          amplitude * sin((x * frequency) + phase) +
          ripple * cos((x * frequency * 2.45) + phase + 0.8);
      return ChartDataPoint(x: x, y: baseline + noise);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 1100;

    return _FlagshipCard(
      icon: Icons.monitor_heart_outlined,
      title: 'Integrated endurance analysis',
      subtitle:
          'Seven signals across five axes with raw context, stage bands, trends, thresholds, and tracking',
      badges: const [
        '7 series',
        '5 Y axes',
        'Stage bands',
        'Trend + threshold',
        'Tracking',
      ],
      interactionHint: 'Hover to track · Shift + wheel to zoom · drag to pan',
      child: BravenChartPlus(
        series: [
          LineChartSeries(
            id: 'session-power-signal',
            name: 'Power signal',
            unit: 'W',
            points: _powerSignal,
            color: _powerOrange.withValues(alpha: 0.42),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.05,
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.hidden,
              label: 'Power signal',
              unit: 'W',
              min: 80,
              max: 200,
            ),
          ),
          AreaChartSeries(
            id: 'session-power',
            name: 'Power (20m avg)',
            unit: 'W',
            points: _power,
            color: _powerOrange,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.8,
            fillOpacity: 0.09,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Power',
              position: SeriesLabelPosition.center,
              offsetY: -8,
              color: _powerOrange,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
              color: _powerOrange,
              min: 80,
              max: 200,
            ),
          ),
          LineChartSeries(
            id: 'session-heart-rate-signal',
            name: 'Heart-rate signal',
            unit: 'bpm',
            points: _heartRateSignal,
            color: _heartRateBlue.withValues(alpha: 0.40),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.0,
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.hidden,
              label: 'Heart-rate signal',
              unit: 'bpm',
              min: 95,
              max: 165,
            ),
          ),
          LineChartSeries(
            id: 'session-heart-rate',
            name: 'Heart rate (20m avg)',
            unit: 'bpm',
            points: _heartRate,
            color: _heartRateBlue,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.8,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Heart rate',
              position: SeriesLabelPosition.left,
              offsetY: 10,
              color: _heartRateBlue,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Heart rate',
              unit: 'bpm',
              color: _heartRateBlue,
              min: 95,
              max: 165,
            ),
          ),
          LineChartSeries(
            id: 'session-cadence',
            name: 'Cadence',
            unit: 'rpm',
            points: _cadence,
            color: _cadenceTeal,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.35,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Cadence',
              position: SeriesLabelPosition.right,
              offsetY: -7,
              color: _cadenceTeal,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Cadence',
              unit: 'rpm',
              color: _cadenceTeal,
              min: 42,
              max: 68,
            ),
          ),
          LineChartSeries(
            id: 'session-vo2',
            name: 'VO₂ avg',
            unit: 'mL/kg/min',
            points: _vo2,
            color: _vo2Indigo,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.8,
            lineGlow: 4,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 4,
            dataPointMarkerStyle: DataPointMarkerStyle.hollow,
            dataPointLabels: const DataPointLabelConfig(
              show: true,
              position: DataPointLabelPosition.above,
              labelColor: _vo2Indigo,
              fontSize: 9,
            ),
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'VO₂ avg',
              position: SeriesLabelPosition.center,
              offsetY: 12,
              color: _vo2Indigo,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'VO₂ avg',
              unit: 'mL/kg/min',
              color: _vo2Indigo,
              min: 20,
              max: 40,
            ),
          ),
          LineChartSeries(
            id: 'session-lactate',
            name: 'Lactate',
            unit: 'mmol/L',
            points: _lactate,
            color: _lactateRed,
            interpolation: LineInterpolation.linear,
            strokeWidth: 2.8,
            lineGlow: 5,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 4,
            dataPointMarkerStyle: DataPointMarkerStyle.hollow,
            dataPointLabels: const DataPointLabelConfig(
              show: true,
              position: DataPointLabelPosition.above,
              labelColor: _lactateRed,
              fontSize: 9,
            ),
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Lactate',
              position: SeriesLabelPosition.center,
              offsetY: -10,
              color: _lactateRed,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Lactate',
              unit: 'mmol/L',
              color: _lactateRed,
              min: 0.5,
              max: 3.2,
            ),
          ),
        ],
        annotations: [
          RangeAnnotation(
            id: 'session-warm-up',
            startX: 0,
            endX: 6,
            label: 'Warm-up',
            fillColor: const Color(0x10F97316),
            borderColor: const Color(0x28F97316),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'session-aerobic',
            startX: 6,
            endX: 12,
            label: 'Aerobic block',
            fillColor: const Color(0x103B82F6),
            borderColor: const Color(0x283B82F6),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'session-recovery',
            startX: 12,
            endX: 18,
            label: 'Recovery',
            fillColor: const Color(0x1410B981),
            borderColor: const Color(0x3210B981),
            allowDragging: false,
            allowEditing: false,
          ),
          RangeAnnotation(
            id: 'session-progression',
            startX: 18,
            endX: 24,
            label: 'Progression',
            fillColor: const Color(0x10FF4D5A),
            borderColor: const Color(0x28FF4D5A),
            allowDragging: false,
            allowEditing: false,
          ),
          for (final stage in const [6.0, 12.0, 18.0])
            ThresholdAnnotation(
              id: 'stage-$stage',
              axis: AnnotationAxis.x,
              value: stage,
              label: compact ? null : '${stage.toInt()} h',
              lineColor: _violet,
              lineWidth: 1.2,
              dashPattern: const [4, 3],
              elevation: 3,
              allowDragging: false,
              allowEditing: false,
            ),
          TrendAnnotation(
            id: 'session-power-trend',
            seriesId: 'session-power-signal',
            trendType: TrendType.polynomial,
            degree: 2,
            label: compact ? null : 'Power trend',
            lineColor: _powerOrange,
            lineWidth: 1.25,
            dashPattern: const [6, 4],
            allowDragging: false,
            allowEditing: false,
          ),
          ThresholdAnnotation(
            id: 'session-lt1',
            axis: AnnotationAxis.y,
            value: 145,
            seriesId: 'session-power',
            label: compact ? 'LT1' : 'LT1 · 145 W',
            lineColor: const Color(0xFF64748B),
            lineWidth: 1.15,
            dashPattern: const [5, 4],
            labelPosition: AnnotationLabelPosition.bottomLeft,
            allowDragging: false,
            allowEditing: false,
          ),
        ],
        theme: isDark ? ChartTheme.dark : ChartTheme.light,
        showLegend: MediaQuery.sizeOf(context).width >= 1100,
        legendStyle: LegendStyle(
          position: LegendPosition.topRight,
          orientation: LegendOrientation.horizontal,
          backgroundColor: (isDark ? Colors.black : Colors.white).withValues(
            alpha: 0.72,
          ),
          textStyle: TextStyle(
            fontSize: 9,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
          itemSpacing: 5,
          markerSize: 12,
          markerLineWidth: 2.5,
          allowDragging: false,
        ),
        showXScrollbar: true,
        scrollbarTheme:
            (isDark
                    ? ScrollbarConfig.defaultDark
                    : ScrollbarConfig.defaultLight)
                .copyWith(autoHide: false),
        normalizationMode: NormalizationMode.perSeries,
        xAxisConfig: const XAxisConfig(
          label: 'Time',
          unit: 'h',
          min: 0,
          max: 24,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
        ),
        interactionConfig: const InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(
            enabled: true,
            mode: CrosshairMode.both,
            snapToDataPoint: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
          tooltip: TooltipConfig(enabled: true),
        ),
      ),
    );
  }
}

/// Baseline fill combined with normalized companion series.
class BaselineResponseGalleryCard extends StatelessWidget {
  const BaselineResponseGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const delta = [
      ChartDataPoint(x: 0, y: 16),
      ChartDataPoint(x: 2, y: 8),
      ChartDataPoint(x: 4, y: 19),
      ChartDataPoint(x: 6, y: 9),
      ChartDataPoint(x: 8, y: 12),
      ChartDataPoint(x: 10, y: 5),
      ChartDataPoint(x: 12, y: -3),
      ChartDataPoint(x: 14, y: -9),
      ChartDataPoint(x: 16, y: -6),
      ChartDataPoint(x: 18, y: -27),
      ChartDataPoint(x: 20, y: -12),
      ChartDataPoint(x: 22, y: -7),
      ChartDataPoint(x: 24, y: -4),
    ];
    const power = [
      ChartDataPoint(x: 0, y: 178),
      ChartDataPoint(x: 4, y: 164),
      ChartDataPoint(x: 8, y: 133),
      ChartDataPoint(x: 12, y: 116),
      ChartDataPoint(x: 16, y: 101),
      ChartDataPoint(x: 20, y: 99),
      ChartDataPoint(x: 24, y: 112),
    ];
    const heartRate = [
      ChartDataPoint(x: 0, y: 157),
      ChartDataPoint(x: 4, y: 146),
      ChartDataPoint(x: 8, y: 129),
      ChartDataPoint(x: 12, y: 119),
      ChartDataPoint(x: 16, y: 105),
      ChartDataPoint(x: 20, y: 101),
      ChartDataPoint(x: 24, y: 111),
    ];

    return _FlagshipCard(
      icon: Icons.vertical_align_center,
      title: 'Baseline response',
      subtitle:
          'Positive and negative deviation fill around zero, layered with independently scaled signals',
      badges: const ['Baseline fill', 'Multi-axis', 'Inline labels'],
      child: BravenChartPlus(
        series: [
          AreaChartSeries(
            id: 'response-delta',
            name: 'HR delta',
            unit: '%',
            points: delta,
            color: _violet,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.2,
            lineGlow: 4,
            baselineValue: 0,
            aboveBaselineFillColor: const Color(0x44FB7185),
            belowBaselineFillColor: const Color(0x3310B981),
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'HR delta',
              position: SeriesLabelPosition.right,
              color: _violet,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'HR delta',
              unit: '%',
              color: _violet,
              min: -30,
              max: 25,
            ),
          ),
          LineChartSeries(
            id: 'response-power',
            name: 'Power avg',
            unit: 'W',
            points: power,
            color: _powerOrange,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.8,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Power',
              position: SeriesLabelPosition.center,
              offsetY: -9,
              color: _powerOrange,
            ),
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
              color: _powerOrange,
            ),
          ),
          LineChartSeries(
            id: 'response-hr',
            name: 'Heart rate avg',
            unit: 'bpm',
            points: heartRate,
            color: _heartRateBlue,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.8,
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Heart rate',
              unit: 'bpm',
              color: _heartRateBlue,
            ),
          ),
        ],
        theme: isDark ? ChartTheme.dark : ChartTheme.light,
        showLegend: true,
        normalizationMode: NormalizationMode.perSeries,
        xAxisConfig: const XAxisConfig(
          label: 'Time',
          unit: 'h',
          min: 0,
          max: 24,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
        ),
        interactionConfig: const InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(
            enabled: true,
            mode: CrosshairMode.vertical,
            snapToDataPoint: true,
            displayMode: CrosshairDisplayMode.tracking,
          ),
        ),
      ),
    );
  }
}

/// Stage window, thresholds, and a glowing summary line over raw samples.
class Vo2StageGalleryCard extends StatelessWidget {
  const Vo2StageGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = List.generate(34, (index) {
      final x = 40 + index * 0.12;
      final stage = index < 8 ? 49.3 : (index < 25 ? 51.2 : 52.0);
      final noise = sin(index * 1.45) * 1.2 + cos(index * 0.55) * 0.55;
      return ChartDataPoint(x: x, y: stage + noise);
    });

    return _FlagshipCard(
      icon: Icons.stacked_line_chart,
      title: 'VO₂ stage analysis',
      subtitle:
          'Raw signal, stage average, target window, threshold lines, and a highlighted VO₂max event',
      badges: const ['Range bands', 'Thresholds', 'Glow', 'Raw + summary'],
      child: BravenChartPlus(
        series: [
          LineChartSeries(
            id: 'vo2-raw',
            name: 'Raw VO₂',
            unit: 'mL/kg/min',
            points: raw,
            color: const Color(0xFF93C5FD),
            interpolation: LineInterpolation.linear,
            strokeWidth: 1.2,
          ),
          const LineChartSeries(
            id: 'vo2-stage',
            name: 'Stage avg VO₂',
            unit: 'mL/kg/min',
            points: [
              ChartDataPoint(x: 40, y: 49.0),
              ChartDataPoint(x: 41, y: 49.0),
              ChartDataPoint(x: 41, y: 51.7),
              ChartDataPoint(x: 43.1, y: 51.7),
              ChartDataPoint(x: 43.1, y: 49.9),
              ChartDataPoint(x: 44, y: 49.9),
            ],
            color: _vo2Indigo,
            interpolation: LineInterpolation.stepped,
            strokeWidth: 2.5,
            lineGlow: 3,
            inlineLabel: SeriesInlineLabelConfig(
              text: 'Stage avg',
              position: SeriesLabelPosition.center,
              offsetY: -9,
              color: _vo2Indigo,
            ),
          ),
        ],
        annotations: [
          RangeAnnotation(
            id: 'vo2-stage-window',
            startX: 41,
            endX: 44,
            startY: 49.8,
            endY: 51.8,
            label: 'Target window',
            fillColor: const Color(0x183B82F6),
            borderColor: const Color(0x553B82F6),
            allowDragging: false,
            allowEditing: false,
          ),
          ThresholdAnnotation(
            id: 'vo2max-event',
            axis: AnnotationAxis.x,
            value: 43.1,
            label: 'VO₂max 61.7',
            lineColor: _vo2Indigo,
            lineWidth: 2,
            dashPattern: const [5, 3],
            elevation: 4,
            allowDragging: false,
            allowEditing: false,
          ),
          ThresholdAnnotation(
            id: 'vo2-target',
            axis: AnnotationAxis.y,
            value: 51.7,
            label: '51.7 target',
            lineColor: const Color(0xFF60A5FA),
            lineWidth: 1.2,
            dashPattern: const [4, 3],
            allowDragging: false,
            allowEditing: false,
          ),
        ],
        theme: isDark ? ChartTheme.dark : ChartTheme.light,
        showLegend: true,
        xAxisConfig: const XAxisConfig(
          label: 'Time',
          unit: 'min',
          min: 40,
          max: 44.15,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'VO₂',
          unit: 'mL/kg/min',
          min: 46,
          max: 55,
          color: _vo2Indigo,
        ),
        interactionConfig: const InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(enabled: true, mode: CrosshairMode.both),
        ),
      ),
    );
  }
}

/// Makes line glow and inline series identity an obvious first-class feature.
class GlowSignalGalleryCard extends StatelessWidget {
  const GlowSignalGalleryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final signal = List.generate(
      20,
      (i) => ChartDataPoint(
        x: i.toDouble(),
        y: 45 + sin(i * 0.72) * 14 + cos(i * 0.21) * 8,
      ),
    );
    final envelope = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 48 + sin(i * 0.38) * 6),
    );

    return _FlagshipCard(
      icon: Icons.blur_on,
      title: 'Signal glow and identity',
      subtitle:
          'A luminous focus series, soft context area, inline labels, and threshold emphasis',
      badges: const ['Line glow', 'Inline labels', 'Area context'],
      darkSurface: true,
      child: BravenChartPlus(
        series: [
          AreaChartSeries(
            id: 'glow-envelope',
            name: 'Expected range',
            points: envelope,
            color: const Color(0xFF22D3EE),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.2,
            fillOpacity: 0.13,
          ),
          LineChartSeries(
            id: 'glow-signal',
            name: 'Live signal',
            points: signal,
            color: const Color(0xFFA78BFA),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 3,
            lineGlow: 8,
            inlineLabel: const SeriesInlineLabelConfig(
              text: 'Live signal',
              position: SeriesLabelPosition.right,
              offsetY: -10,
              color: Color(0xFFC4B5FD),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        annotations: [
          ThresholdAnnotation(
            id: 'glow-threshold',
            axis: AnnotationAxis.y,
            value: 60,
            label: 'Upper threshold',
            lineColor: const Color(0xFFFBBF24),
            lineWidth: 1.5,
            dashPattern: const [5, 4],
            elevation: 5,
            allowDragging: false,
            allowEditing: false,
          ),
        ],
        theme: ChartTheme.dark,
        showLegend: false,
        xAxisConfig: const XAxisConfig(label: 'Sample'),
        yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Signal'),
        interactionConfig: const InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(
            enabled: true,
            mode: CrosshairMode.vertical,
            displayMode: CrosshairDisplayMode.tracking,
          ),
        ),
      ),
    );
  }
}

/// Two related charts in one gallery card, matching real method-comparison UX.
class LactateComparisonGalleryCard extends StatelessWidget {
  const LactateComparisonGalleryCard({super.key});

  static const _method = [
    ChartDataPoint(x: 80, y: 1.0),
    ChartDataPoint(x: 110, y: 1.1),
    ChartDataPoint(x: 140, y: 1.0),
    ChartDataPoint(x: 170, y: 1.15),
    ChartDataPoint(x: 200, y: 1.8),
    ChartDataPoint(x: 230, y: 3.0),
    ChartDataPoint(x: 260, y: 7.5),
  ];

  static const _session = [
    ChartDataPoint(x: 120, y: 1.0),
    ChartDataPoint(x: 145, y: 1.25),
    ChartDataPoint(x: 170, y: 1.4),
    ChartDataPoint(x: 195, y: 2.0),
    ChartDataPoint(x: 220, y: 3.9),
    ChartDataPoint(x: 250, y: 8.1),
  ];

  @override
  Widget build(BuildContext context) {
    return _FlagshipCard(
      icon: Icons.science_outlined,
      title: 'Lactate method comparison',
      subtitle:
          'Reusable chart configuration shown across reference and current-session views',
      badges: const ['Small multiples', 'Baseline', 'LT1'],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final charts = [
            const Expanded(child: _LactateMiniChart(method: true)),
            const SizedBox(width: 12, height: 12),
            const Expanded(child: _LactateMiniChart(method: false)),
          ];
          return constraints.maxWidth >= 620
              ? Row(children: charts)
              : Column(children: charts);
        },
      ),
    );
  }
}

class _LactateMiniChart extends StatelessWidget {
  const _LactateMiniChart({required this.method});

  final bool method;

  @override
  Widget build(BuildContext context) {
    final points = method
        ? LactateComparisonGalleryCard._method
        : LactateComparisonGalleryCard._session;
    final threshold = method ? 200.0 : 195.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          method ? 'Reference method' : 'This session',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: method ? 'lactate-method' : 'lactate-session',
                name: 'Blood lactate',
                unit: 'mmol/L',
                points: points,
                color: const Color(0xFF6366F1),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2.4,
                lineGlow: 3,
                showDataPointMarkers: true,
                dataPointMarkerRadius: 4,
              ),
            ],
            annotations: [
              ThresholdAnnotation(
                id: 'baseline-${method ? 'method' : 'session'}',
                axis: AnnotationAxis.y,
                value: 1.1,
                label: 'baseline +1.1',
                lineColor: _emerald,
                dashPattern: const [4, 3],
                allowDragging: false,
                allowEditing: false,
              ),
              ThresholdAnnotation(
                id: 'lt1-${method ? 'method' : 'session'}',
                axis: AnnotationAxis.x,
                value: threshold,
                label: 'LT1',
                lineColor: _emerald,
                dashPattern: const [4, 3],
                allowDragging: false,
                allowEditing: false,
              ),
            ],
            showLegend: false,
            xAxisConfig: const XAxisConfig(label: 'Power', unit: 'W'),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Lactate',
              unit: 'mmol/L',
              min: 0,
              max: 9,
              color: const Color(0xFF6366F1),
            ),
            interactionConfig: const InteractionConfig(
              crosshair: CrosshairConfig(
                enabled: true,
                mode: CrosshairMode.both,
                snapToDataPoint: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A real live stream: the series updates through [LiveStreamController]
/// without rebuilding the gallery page for every sample.
class LiveStreamGalleryCard extends StatefulWidget {
  const LiveStreamGalleryCard({super.key});

  @override
  State<LiveStreamGalleryCard> createState() => _LiveStreamGalleryCardState();
}

class _LiveStreamGalleryCardState extends State<LiveStreamGalleryCard> {
  late final LiveStreamController _controller;
  Timer? _timer;
  int _sample = 0;

  @override
  void initState() {
    super.initState();
    _controller = LiveStreamController(
      seriesId: 'gallery-live',
      maxPoints: 180,
      autoScroll: true,
      viewportDataPoints: 64,
      maxVisiblePoints: 72,
    );
    for (var i = 0; i < 72; i++) {
      _addSample();
    }
    _timer = Timer.periodic(const Duration(milliseconds: 240), (_) {
      _addSample();
    });
  }

  void _addSample() {
    final value =
        52 +
        sin(_sample * 0.19) * 15 +
        cos(_sample * 0.047) * 7 +
        sin(_sample * 0.83) * 2;
    _controller.addPoint(
      ChartDataPoint(x: _sample.toDouble(), y: value.clamp(20, 85).toDouble()),
    );
    _sample++;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _FlagshipCard(
      icon: Icons.sensors,
      title: 'Live sensor stream',
      subtitle:
          'Direct-to-renderer ingestion, bounded buffering, follow-latest viewport, pan, zoom, and scrollbar',
      badges: const ['LIVE', '4 Hz', 'Auto-scroll', 'Bounded buffer'],
      live: true,
      child: BravenChartPlus(
        series: const [
          LineChartSeries(
            id: 'gallery-live',
            name: 'Live sensor',
            points: [],
            color: Color(0xFF14B8A6),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2.5,
            lineGlow: 4,
          ),
        ],
        liveStreamController: _controller,
        theme: isDark ? ChartTheme.dark : ChartTheme.light,
        showLegend: false,
        showXScrollbar: true,
        scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
        xAxisConfig: const XAxisConfig(label: 'Sample'),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Signal',
          min: 20,
          max: 85,
          color: const Color(0xFF14B8A6),
        ),
        interactionConfig: const InteractionConfig(
          enableZoom: true,
          enablePan: true,
          crosshair: CrosshairConfig(
            enabled: true,
            mode: CrosshairMode.vertical,
            displayMode: CrosshairDisplayMode.tracking,
          ),
        ),
      ),
    );
  }
}

class _FlagshipCard extends StatelessWidget {
  const _FlagshipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.child,
    this.interactionHint,
    this.darkSurface = false,
    this.live = false,
    this.surfaceColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> badges;
  final Widget child;
  final String? interactionHint;
  final bool darkSurface;
  final bool live;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = darkSurface ? Colors.white : theme.colorScheme.onSurface;
    final muted = darkSurface
        ? Colors.white70
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      color: darkSurface ? const Color(0xFF111827) : surfaceColor,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: live
                        ? const Color(0x2010B981)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: live
                        ? _emerald
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: badges
                  .map(
                    (badge) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge == 'LIVE'
                            ? const Color(0x2010B981)
                            : (darkSurface
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : theme.colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: badge == 'LIVE' ? _emerald : muted,
                          fontWeight: badge == 'LIVE'
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (interactionHint != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.mouse_outlined, size: 16, color: muted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      interactionHint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
