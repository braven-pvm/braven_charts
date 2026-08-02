// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

// A `RangeAreaDataPoint.gap` is a HOLE in the band, not an observation at zero.
// Its `y` is a finite `0` placeholder only because `ChartDataPoint` has no
// nullable Y, so every filter that admits a point on `y.isFinite` alone drags
// the placeholder into the fit and pulls the line toward the axis.
//
// The assertion with teeth throughout this file is EQUIVALENCE: fitting a band
// that contains a gap must produce exactly the fit obtained from the same band
// with the gap row deleted outright. "Not sloped" or "not zero" would pass for
// a merely-less-wrong filter; equivalence pins the intended semantics.

import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/enums.dart';
import 'package:braven_charts/src/models/range_area_chart_series.dart';
import 'package:braven_charts/src/models/range_area_data_point.dart';
import 'package:braven_charts/src/statistics/linear_regression_intervals.dart';
import 'package:braven_charts/src/statistics/loess_smoother.dart';
import 'package:braven_charts/src/statistics/trend_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

/// A ten-row band flat at midpoint 50, with the x = 5 row either punched out
/// as a gap or deleted outright.
List<RangeAreaDataPoint> _band({required bool keepGapRow}) {
  final points = <RangeAreaDataPoint>[];
  for (var x = 0; x <= 9; x++) {
    if (x == 5) {
      if (keepGapRow) points.add(RangeAreaDataPoint.gap(x: x.toDouble()));
      continue;
    }
    points.add(RangeAreaDataPoint(x: x.toDouble(), low: 40, high: 60));
  }
  return points;
}

/// The band with a gap at x = 5 (the row is present and is a gap).
List<RangeAreaDataPoint> get _gappedBand => _band(keepGapRow: true);

/// The same band with the x = 5 row deleted entirely.
List<RangeAreaDataPoint> get _gapFreeBand => _band(keepGapRow: false);

RangeAreaChartSeries _series(List<RangeAreaDataPoint> points) =>
    RangeAreaChartSeries(id: 'band', points: points);

const _transform = ChartTransform(
  dataXMin: 0,
  dataXMax: 9,
  dataYMin: 0,
  dataYMax: 100,
  plotWidth: 500,
  plotHeight: 320,
);

TrendAnnotationElement _trend(
  List<RangeAreaDataPoint> points, {
  TrendType trendType = TrendType.linear,
  int? windowSize,
}) {
  return TrendAnnotationElement(
    annotation: TrendAnnotation(
      id: 'fit',
      seriesId: 'band',
      trendType: trendType,
      windowSize: windowSize,
      showEquation: true,
      showRSquared: true,
    ),
    series: _series(points),
    transform: _transform,
  );
}

void main() {
  group('a band gap is not an observation at zero', () {
    test('the fitted linear trend matches the gap-free band exactly', () {
      final gapped = _trend(_gappedBand);
      final gapFree = _trend(_gapFreeBand);

      for (var x = 0; x <= 9; x++) {
        expect(
          gapped.evaluateAt(x.toDouble()),
          gapFree.evaluateAt(x.toDouble()),
          reason: 'linear fit diverges from the gap-free band at x=$x',
        );
      }
      // The band's true midline is flat at 50, so the reference fit is too.
      expect(gapFree.evaluateAt(5), closeTo(50, 1e-9));
    });

    test('a moving average does not dip toward zero over the gap', () {
      final gapped = _trend(
        _gappedBand,
        trendType: TrendType.movingAverage,
        windowSize: 3,
      );
      final gapFree = _trend(
        _gapFreeBand,
        trendType: TrendType.movingAverage,
        windowSize: 3,
      );

      for (var x = 0; x <= 9; x++) {
        expect(
          gapped.evaluateAt(x.toDouble()),
          gapFree.evaluateAt(x.toDouble()),
          reason: 'moving average diverges from the gap-free band at x=$x',
        );
      }
    });

    test('a loess fit matches the gap-free band', () {
      final gapped = _trend(_gappedBand, trendType: TrendType.loess);
      final gapFree = _trend(_gapFreeBand, trendType: TrendType.loess);

      for (var x = 0; x <= 9; x++) {
        expect(
          gapped.evaluateAt(x.toDouble()),
          gapFree.evaluateAt(x.toDouble()),
          reason: 'loess diverges from the gap-free band at x=$x',
        );
      }
    });

    test('the reported statistics match the gap-free band', () {
      final gapped = _trend(_gappedBand).statistics;
      final gapFree = _trend(_gapFreeBand).statistics;

      expect(gapped.sampleCount, gapFree.sampleCount);
      expect(gapped.sampleCount, 9);
      expect(gapped.rSquared, gapFree.rSquared);
      expect(gapped.pearsonCorrelation, gapFree.pearsonCorrelation);
      expect(gapped.spearmanCorrelation, gapFree.spearmanCorrelation);
      expect(gapped.equation, gapFree.equation);
    });

    test(
      'TrendStatisticsCalculator ignores gaps when handed band points',
      () {
        double? flat(double x) => 50;
        final gapped = TrendStatisticsCalculator.calculate(
          points: _gappedBand,
          predict: flat,
        );
        final gapFree = TrendStatisticsCalculator.calculate(
          points: _gapFreeBand,
          predict: flat,
        );

        expect(gapped.sampleCount, 9);
        expect(gapped.sampleCount, gapFree.sampleCount);
        expect(gapped.rSquared, gapFree.rSquared);
        expect(gapped.pearsonCorrelation, gapFree.pearsonCorrelation);
      },
    );

    test('LoessSmoother drops gaps from its input', () {
      final gapped = LoessSmoother(span: 0.8).smooth(_gappedBand);
      final gapFree = LoessSmoother(span: 0.8).smooth(_gapFreeBand);

      expect(gapped.length, gapFree.length);
      for (var index = 0; index < gapped.length; index++) {
        expect(gapped[index].x, gapFree[index].x);
        expect(gapped[index].y, gapFree[index].y);
      }
    });

    test('regression bands are computed over real observations only', () {
      final gapped = LinearRegressionIntervalCalculator.calculate(
        points: _gappedBand,
      );
      final gapFree = LinearRegressionIntervalCalculator.calculate(
        points: _gapFreeBand,
      );

      expect(gapped, isNotNull);
      expect(gapFree, isNotNull);
      expect(gapped!.points.length, gapFree!.points.length);
      for (var index = 0; index < gapped.points.length; index++) {
        expect(gapped.points[index].fitted, gapFree.points[index].fitted);
        expect(
          gapped.points[index].confidenceLower,
          gapFree.points[index].confidenceLower,
        );
        expect(
          gapped.points[index].confidenceUpper,
          gapFree.points[index].confidenceUpper,
        );
      }
    });
  });

  group('gap-free bands and plain series are untouched', () {
    test('a band with no gaps fits exactly as before', () {
      final element = _trend([
        for (var x = 0; x <= 9; x++)
          RangeAreaDataPoint(
            x: x.toDouble(),
            low: x.toDouble(),
            high: x.toDouble() + 20,
          ),
      ]);

      // Midpoints are x + 10, so the fit is exactly y = x + 10.
      expect(element.statistics.sampleCount, 10);
      expect(element.statistics.rSquared, closeTo(1, 1e-12));
      for (var x = 0; x <= 9; x++) {
        expect(element.evaluateAt(x.toDouble()), closeTo(x + 10, 1e-9));
      }
      expect(element.bounds, isNot(Rect.zero));
    });

    test('a plain ChartDataPoint at y=0 is still an observation', () {
      const points = <ChartDataPoint>[
        ChartDataPoint(x: 0, y: 0),
        ChartDataPoint(x: 1, y: 1),
        ChartDataPoint(x: 2, y: 2),
      ];
      final statistics = TrendStatisticsCalculator.calculate(
        points: points,
        predict: (x) => x,
      );

      expect(statistics.sampleCount, 3);
      expect(statistics.rSquared, closeTo(1, 1e-12));
    });
  });
}
