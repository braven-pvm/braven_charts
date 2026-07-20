import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('50k-candle nearest-X tracking stays comfortably interactive', () {
    final series = CandlestickChartSeries(
      id: 'price',
      points: [
        for (var index = 0; index < 50000; index++)
          CandlestickDataPoint(
            x: index.toDouble(),
            open: 100,
            high: 102,
            low: 98,
            close: index.isEven ? 101 : 99,
          ),
      ],
    );
    final watch = Stopwatch()..start();
    CrosshairTrackingState? lastState;
    for (var query = 0; query < 1000; query++) {
      lastState = CrosshairTracker.calculateTrackingState(
        screenX: (query % 1000).toDouble(),
        chartBounds: const Rect.fromLTWH(0, 0, 1000, 500),
        xMin: 0,
        xMax: 49999,
        seriesList: [series],
        interpolate: false,
      );
    }
    watch.stop();
    // Generous regression guard; the implementation uses binary search and is
    // normally orders of magnitude below this ceiling.
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(lastState?.seriesValues.single.candlestick, isNotNull);
    // ignore: avoid_print
    print(
      'Candlestick nearest-X: ${watch.elapsedMicroseconds / 1000} ms / 1,000 queries',
    );
  });

  test('10k active-candle revisions keep one point and fixed capacity', () {
    final controller = LiveStreamController(seriesId: 'price', maxPoints: 64);
    addTearDown(controller.dispose);
    final watch = Stopwatch()..start();
    for (var revision = 0; revision < 10000; revision++) {
      final close = 100.0 + (revision % 10);
      controller.upsertLatestCandlestick(
        CandlestickDataPoint(
          x: 1,
          open: 100,
          high: close + 1,
          low: 99,
          close: close,
        ),
      );
    }
    watch.stop();

    expect(controller.pointCount, 1);
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    // ignore: avoid_print
    print(
      'Candlestick latest upsert: ${watch.elapsedMicroseconds / 1000} ms / 10,000 revisions',
    );
  });

  test('50k grouped crosshair tracking stays comfortably interactive', () {
    final series = CandlestickChartSeries(
      id: 'grouped-price',
      densityGrouping: const CandlestickDensityGrouping(enabled: true),
      points: [
        for (var index = 0; index < 50000; index++)
          CandlestickDataPoint(
            x: index.toDouble(),
            open: 100,
            high: 102 + (index % 3),
            low: 96 - (index % 2),
            close: index.isEven ? 101 : 99,
          ),
      ],
    );
    final watch = Stopwatch()..start();
    CrosshairTrackingState? lastState;
    for (var query = 0; query < 1000; query++) {
      lastState = CrosshairTracker.calculateTrackingState(
        screenX: (query % 1000).toDouble(),
        chartBounds: const Rect.fromLTWH(0, 0, 1000, 500),
        xMin: 0,
        xMax: 49999,
        seriesList: [series],
        interpolate: false,
      );
    }
    watch.stop();

    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(lastState?.seriesValues.single.sourcePointIndices.length, 250);
    // ignore: avoid_print
    print(
      'Grouped Candlestick tracking: '
      '${watch.elapsedMicroseconds / 1000} ms / 1,000 queries',
    );
  });
}
