import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Chart families used to prove that artifacts and Workbench presentations are
/// family-neutral.
enum PortableShowcaseChartKind {
  line,
  area,
  bar,
  scatter,
  mixed,
  rangeArea,
  pie,
  donut,
}

/// A complete, deterministic chart story used by the artifact and Workbench
/// public showcases.
///
/// This is deliberately a showcase data factory, not a second chart model.
/// Every value is expressed through the same public series and theme types a
/// package user supplies to [BravenChartPlus].
class PortableShowcaseChartStory {
  const PortableShowcaseChartStory({
    required this.seed,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.explanation,
    required this.series,
    required this.pointCount,
    required this.annotations,
    required this.theme,
    required this.showLegend,
    this.xAxisConfig,
    this.yAxis,
  });

  final int seed;
  final PortableShowcaseChartKind kind;
  final String title;
  final String subtitle;
  final String explanation;
  final List<ChartSeries> series;
  final int pointCount;
  final List<ChartAnnotation> annotations;
  final ChartTheme theme;
  final bool showLegend;
  final XAxisConfig? xAxisConfig;
  final YAxisConfig? yAxis;

  bool get isRadial =>
      kind == PortableShowcaseChartKind.pie ||
      kind == PortableShowcaseChartKind.donut;

  String get kindLabel => switch (kind) {
    PortableShowcaseChartKind.line => 'Line',
    PortableShowcaseChartKind.area => 'Area',
    PortableShowcaseChartKind.bar => 'Bar',
    PortableShowcaseChartKind.scatter => 'Scatter',
    PortableShowcaseChartKind.mixed => 'Mixed',
    PortableShowcaseChartKind.rangeArea => 'Range Area',
    PortableShowcaseChartKind.pie => 'Pie',
    PortableShowcaseChartKind.donut => 'Donut',
  };

  String get summary =>
      '$kindLabel · ${series.length} ${series.length == 1 ? 'series' : 'series'} · $pointCount ${isRadial ? 'categories' : 'points'}';
}

class PortableChartShowcaseGenerator {
  PortableChartShowcaseGenerator._();

  static const _palettes = <List<Color>>[
    [
      Color(0xFF2563EB),
      Color(0xFFDC2626),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
    ],
    [
      Color(0xFF0891B2),
      Color(0xFF0F766E),
      Color(0xFF65A30D),
      Color(0xFFF59E0B),
      Color(0xFFEA580C),
    ],
    [
      Color(0xFFDB2777),
      Color(0xFFF97316),
      Color(0xFFFACC15),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ],
    [
      Color(0xFF38BDF8),
      Color(0xFF818CF8),
      Color(0xFFC084FC),
      Color(0xFFF472B6),
      Color(0xFFFB7185),
    ],
  ];

  static PortableShowcaseChartStory generate(
    int seed, {
    PortableShowcaseChartKind? kind,
  }) {
    final random = math.Random(seed);
    kind ??= PortableShowcaseChartKind
        .values[random.nextInt(PortableShowcaseChartKind.values.length)];
    final palette = _palettes[random.nextInt(_palettes.length)];
    final dark = random.nextInt(5) == 0;
    final theme = (dark ? ChartTheme.dark : ChartTheme.light).copyWith(
      seriesTheme: (dark ? ChartTheme.dark : ChartTheme.light).seriesTheme
          .copyWith(colors: palette),
    );

    return switch (kind) {
      PortableShowcaseChartKind.pie => _radialStory(
        seed: seed,
        random: random,
        palette: palette,
        theme: theme,
        donut: false,
      ),
      PortableShowcaseChartKind.donut => _radialStory(
        seed: seed,
        random: random,
        palette: palette,
        theme: theme,
        donut: true,
      ),
      PortableShowcaseChartKind.rangeArea => _rangeStory(
        seed: seed,
        random: random,
        palette: palette,
        theme: theme,
      ),
      _ => _cartesianStory(
        seed: seed,
        kind: kind,
        random: random,
        palette: palette,
        theme: theme,
      ),
    };
  }

  static PortableShowcaseChartStory _cartesianStory({
    required int seed,
    required PortableShowcaseChartKind kind,
    required math.Random random,
    required List<Color> palette,
    required ChartTheme theme,
  }) {
    final pointCount = 12 + random.nextInt(13);
    final seriesCount = kind == PortableShowcaseChartKind.mixed
        ? 3
        : 1 + random.nextInt(3);
    final base = 45 + random.nextDouble() * 90;
    final amplitude = 12 + random.nextDouble() * 28;
    final slope = (random.nextDouble() - 0.5) * 2.4;
    final phase = random.nextDouble() * math.pi;
    final series = <ChartSeries>[];

    for (var seriesIndex = 0; seriesIndex < seriesCount; seriesIndex++) {
      final points = <ChartDataPoint>[];
      for (var pointIndex = 0; pointIndex < pointCount; pointIndex++) {
        final wave = math.sin(pointIndex / (2.1 + seriesIndex * 0.55) + phase);
        final noise = (random.nextDouble() - 0.5) * amplitude * 0.42;
        final y = math.max(
          2,
          base +
              seriesIndex * 18 +
              wave * amplitude +
              slope * pointIndex +
              noise,
        );
        points.add(
          ChartDataPoint(
            x: pointIndex.toDouble(),
            y: y.toDouble(),
            label: pointIndex % 5 == 0 ? 'Sample ${pointIndex + 1}' : null,
          ),
        );
      }
      final seriesKind = kind == PortableShowcaseChartKind.mixed
          ? const [
              PortableShowcaseChartKind.bar,
              PortableShowcaseChartKind.line,
              PortableShowcaseChartKind.scatter,
            ][seriesIndex]
          : kind;
      series.add(
        _cartesianSeries(
          seriesKind,
          id: 'portable-$seed-series-$seriesIndex',
          name: _seriesName(seriesIndex),
          color: palette[seriesIndex % palette.length],
          points: points,
          random: random,
        ),
      );
    }

    final titleStem = switch (kind) {
      PortableShowcaseChartKind.line => 'Signal response',
      PortableShowcaseChartKind.area => 'Cumulative demand',
      PortableShowcaseChartKind.bar => 'Interval comparison',
      PortableShowcaseChartKind.scatter => 'Sample distribution',
      PortableShowcaseChartKind.mixed => 'Operational overview',
      _ => throw StateError('Unsupported Cartesian story kind: $kind'),
    };
    final explanation = switch (kind) {
      PortableShowcaseChartKind.line =>
        'A continuous trend with resolved interpolation and marker state.',
      PortableShowcaseChartKind.area =>
        'A filled magnitude story whose styling travels with the data.',
      PortableShowcaseChartKind.bar =>
        'Category-aligned columns with one exact table row per sample.',
      PortableShowcaseChartKind.scatter =>
        'Independent observations with durable point identity.',
      PortableShowcaseChartKind.mixed =>
        'Different series types sharing one portable coordinate system.',
      _ => '',
    };
    return PortableShowcaseChartStory(
      seed: seed,
      kind: kind,
      title: '$titleStem ${seed % 1000}',
      subtitle: '$seriesCount series · $pointCount samples',
      explanation: explanation,
      series: series,
      pointCount: pointCount * seriesCount,
      annotations: [
        ThresholdAnnotation(
          id: 'portable-threshold-$seed',
          axis: AnnotationAxis.y,
          value: base + amplitude * 0.45,
          label: 'Reference',
        ),
      ],
      theme: theme,
      showLegend: seriesCount > 1,
      xAxisConfig: XAxisConfig(
        label: 'Sample',
        min: 0,
        max: (pointCount - 1).toDouble(),
      ),
      yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Value'),
    );
  }

  static ChartSeries _cartesianSeries(
    PortableShowcaseChartKind kind, {
    required String id,
    required String name,
    required Color color,
    required List<ChartDataPoint> points,
    required math.Random random,
  }) => switch (kind) {
    PortableShowcaseChartKind.line => LineChartSeries(
      id: id,
      name: name,
      unit: 'units',
      color: color,
      points: points,
      interpolation: random.nextBool()
          ? LineInterpolation.bezier
          : LineInterpolation.monotone,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 2.5 + random.nextDouble() * 1.5,
    ),
    PortableShowcaseChartKind.area => AreaChartSeries(
      id: id,
      name: name,
      unit: 'units',
      color: color,
      points: points,
      interpolation: random.nextBool()
          ? LineInterpolation.bezier
          : LineInterpolation.monotone,
      fillOpacity: 0.18 + random.nextDouble() * 0.2,
    ),
    PortableShowcaseChartKind.bar => BarChartSeries(
      id: id,
      name: name,
      unit: 'units',
      color: color,
      points: points,
      barWidthPercent: 0.48 + random.nextDouble() * 0.28,
    ),
    PortableShowcaseChartKind.scatter => ScatterChartSeries(
      id: id,
      name: name,
      unit: 'units',
      color: color,
      points: points,
      markerRadius: 3 + random.nextDouble() * 2.5,
    ),
    _ => throw StateError('Unsupported Cartesian series kind: $kind'),
  };

  static PortableShowcaseChartStory _rangeStory({
    required int seed,
    required math.Random random,
    required List<Color> palette,
    required ChartTheme theme,
  }) {
    final pointCount = 14 + random.nextInt(9);
    final base = 62 + random.nextDouble() * 28;
    final points = List<RangeAreaDataPoint>.generate(pointCount, (index) {
      final midpoint =
          base +
          math.sin(index / 2.8 + seed * 0.01) * 12 +
          index * (0.45 + random.nextDouble() * 0.2);
      final halfSpan = 5 + random.nextDouble() * 7;
      return RangeAreaDataPoint(
        x: index.toDouble(),
        low: midpoint - halfSpan,
        high: midpoint + halfSpan,
      );
    });
    return PortableShowcaseChartStory(
      seed: seed,
      kind: PortableShowcaseChartKind.rangeArea,
      title: 'Forecast confidence ${seed % 1000}',
      subtitle: '1 interval series · $pointCount forecast windows',
      explanation:
          'The low, high, midpoint, span, gradient, and boundaries remain source-preserving.',
      series: [
        RangeAreaChartSeries(
          id: 'portable-range-$seed',
          name: 'Forecast interval',
          unit: '%',
          points: points,
          color: palette.first,
          interpolation: LineInterpolation.monotone,
          fillOpacity: 0.3,
          fillGradient: AreaGradient(
            colors: [palette.first.withValues(alpha: 0.32), palette[1]],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          upperBoundaryStyle: RangeAreaBoundaryStyle(
            color: palette.first,
            strokeWidth: 1.8,
          ),
          lowerBoundaryStyle: RangeAreaBoundaryStyle(
            color: palette[1],
            strokeWidth: 1.4,
          ),
        ),
      ],
      pointCount: pointCount,
      annotations: const [],
      theme: theme,
      showLegend: true,
      xAxisConfig: XAxisConfig(
        label: 'Forecast horizon',
        min: 0,
        max: (pointCount - 1).toDouble(),
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Confidence',
        unit: '%',
      ),
    );
  }

  static PortableShowcaseChartStory _radialStory({
    required int seed,
    required math.Random random,
    required List<Color> palette,
    required ChartTheme theme,
    required bool donut,
  }) {
    const labels = [
      'Subscriptions',
      'Services',
      'Hardware',
      'Training',
      'Other',
      'Partners',
    ];
    final categoryCount = 4 + random.nextInt(3);
    final values = <String, double>{
      for (var index = 0; index < categoryCount; index++)
        labels[index]: 8 + random.nextInt(38).toDouble(),
    };
    final colors = <String, Color>{
      for (var index = 0; index < categoryCount; index++)
        labels[index]: palette[index % palette.length],
    };
    final series = donut
        ? DonutChartSeries.fromMap(
            id: 'portable-donut-$seed',
            name: 'Contribution',
            unit: 'USD',
            values: values,
            sliceColors: colors,
            donutStyle: DonutChartStyle(
              innerRadiusFactor: 0.48 + random.nextDouble() * 0.18,
              radiusFactor: 0.82 + random.nextDouble() * 0.12,
              sliceGap: 2 + random.nextDouble() * 3,
              cornerRadius: random.nextBool() ? 6 : 0,
            ),
          )
        : PieChartSeries.fromMap(
            id: 'portable-pie-$seed',
            name: 'Contribution',
            unit: 'USD',
            values: values,
            sliceColors: colors,
            pieStyle: PieChartStyle(
              radiusFactor: 0.82 + random.nextDouble() * 0.12,
              sliceGap: 2 + random.nextDouble() * 3,
              cornerRadius: random.nextBool() ? 6 : 0,
            ),
          );
    final kind = donut
        ? PortableShowcaseChartKind.donut
        : PortableShowcaseChartKind.pie;
    return PortableShowcaseChartStory(
      seed: seed,
      kind: kind,
      title: donut
          ? 'Revenue ring ${seed % 1000}'
          : 'Revenue contribution ${seed % 1000}',
      subtitle: '$categoryCount categories · category-native data projection',
      explanation: donut
          ? 'Annular geometry, center opening, category values, and shares travel together.'
          : 'Category meaning and calculated share stay intact without exposing fake X values.',
      series: [series],
      pointCount: categoryCount,
      annotations: const [],
      theme: theme,
      showLegend: true,
    );
  }

  static String _seriesName(int index) => switch (index) {
    0 => 'Observed',
    1 => 'Benchmark',
    _ => 'Forecast',
  };
}
