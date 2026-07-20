// Copyright 2025 Braven Charts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

CandlestickInteractionDetails _candlestick({
  double open = 100,
  double close = 104,
  DateTime? timestamp,
  int sourceCount = 1,
}) {
  final change = close - open;
  final changePercent = open == 0 ? 0.0 : change / open * 100;
  return CandlestickInteractionDetails(
    open: open,
    high: close + 2,
    low: open - 2,
    close: close,
    formattedOpen: open.toStringAsFixed(2),
    formattedHigh: (close + 2).toStringAsFixed(2),
    formattedLow: (open - 2).toStringAsFixed(2),
    formattedClose: close.toStringAsFixed(2),
    change: change,
    changePercent: changePercent,
    formattedChange: change.toStringAsFixed(2),
    direction: change >= 0
        ? CandlestickDirection.rising
        : CandlestickDirection.falling,
    sourceCount: sourceCount,
    timestamp: timestamp ?? DateTime.utc(2026, 7, 20, 9, 30),
    formattedTimestamp: '09:30',
  );
}

CartesianTrackedSeriesValue _value({
  String seriesId = 'power',
  int dataPointIndex = 3,
  bool isTrend = false,
  String formattedY = '245 W',
  CandlestickInteractionDetails? candlestick,
}) {
  return CartesianTrackedSeriesValue(
    seriesId: seriesId,
    seriesName: 'Power',
    seriesColor: const Color(0xFF2196F3),
    x: 12.5,
    y: 245,
    dataPointIndex: dataPointIndex,
    isInterpolated: false,
    isTrend: isTrend,
    candlestick: candlestick,
    formattedX: '12.5 s',
    formattedY: formattedY,
    unitLabel: 'W',
  );
}

CartesianTrackingSnapshot _snapshot({
  List<CartesianTrackedSeriesValue>? values,
  CartesianTrackingOrigin origin = CartesianTrackingOrigin.pointer,
  ChartPointRef? primaryPoint,
}) {
  return CartesianTrackingSnapshot(
    dataX: 12.5,
    plotX: 180,
    values: values ?? [_value()],
    origin: origin,
    primaryPoint: primaryPoint,
  );
}

void main() {
  group('CartesianTrackingSnapshot construction', () {
    test('stores core fields', () {
      final snapshot = _snapshot(
        primaryPoint: const ChartPointRef(seriesId: 'power', pointIndex: 3),
      );

      expect(snapshot.dataX, 12.5);
      expect(snapshot.plotX, 180);
      expect(snapshot.values, hasLength(1));
      expect(snapshot.origin, CartesianTrackingOrigin.pointer);
      expect(
        snapshot.primaryPoint,
        const ChartPointRef(seriesId: 'power', pointIndex: 3),
      );
    });

    test('values list is unmodifiable', () {
      final snapshot = _snapshot();

      expect(() => snapshot.values.add(_value()), throwsUnsupportedError);
      expect(() => snapshot.values.removeAt(0), throwsUnsupportedError);
      expect(() => snapshot.values[0] = _value(), throwsUnsupportedError);
      expect(() => snapshot.values.clear(), throwsUnsupportedError);
    });

    test('values list is defensively copied from the constructor argument', () {
      final source = [_value()];
      final snapshot = CartesianTrackingSnapshot(
        dataX: 12.5,
        plotX: 180,
        values: source,
        origin: CartesianTrackingOrigin.pointer,
      );

      source.add(_value(seriesId: 'cadence'));

      expect(snapshot.values, hasLength(1));
    });

    test('every origin is preserved', () {
      for (final origin in CartesianTrackingOrigin.values) {
        expect(_snapshot(origin: origin).origin, origin);
      }
    });

    test('origin enum covers the five tracking sources', () {
      expect(CartesianTrackingOrigin.values, const [
        CartesianTrackingOrigin.pointer,
        CartesianTrackingOrigin.keyboard,
        CartesianTrackingOrigin.synchronized,
        CartesianTrackingOrigin.pinned,
        CartesianTrackingOrigin.fallback,
      ]);
    });
  });

  group('CartesianTrackingSnapshot.sameIdentityAs', () {
    test('true for identical datum identity and formatted values', () {
      final a = _snapshot();
      final b = _snapshot();

      expect(a.sameIdentityAs(b), isTrue);
      expect(b.sameIdentityAs(a), isTrue);
    });

    test('true even when non-identity fields differ', () {
      final a = _snapshot();
      final b = CartesianTrackingSnapshot(
        dataX: 12.75,
        plotX: 184,
        values: [_value()],
        origin: CartesianTrackingOrigin.synchronized,
      );

      expect(a.sameIdentityAs(b), isTrue);
    });

    test('false when dataPointIndex differs', () {
      final a = _snapshot();
      final b = _snapshot(values: [_value(dataPointIndex: 4)]);

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('false when formattedY differs', () {
      final a = _snapshot();
      final b = _snapshot(values: [_value(formattedY: '246 W')]);

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('false when seriesId differs', () {
      final a = _snapshot();
      final b = _snapshot(values: [_value(seriesId: 'cadence')]);

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('false when isTrend differs', () {
      final a = _snapshot();
      final b = _snapshot(values: [_value(isTrend: true)]);

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('false when value counts differ', () {
      final a = _snapshot();
      final b = _snapshot(
        values: [
          _value(),
          _value(seriesId: 'cadence'),
        ],
      );

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('true when candlestick identity matches', () {
      final a = _snapshot(values: [_value(candlestick: _candlestick())]);
      final b = _snapshot(values: [_value(candlestick: _candlestick())]);

      expect(a.sameIdentityAs(b), isTrue);
    });

    test('false when candlestick timestamp differs', () {
      final a = _snapshot(values: [_value(candlestick: _candlestick())]);
      final b = _snapshot(
        values: [
          _value(
            candlestick: _candlestick(
              timestamp: DateTime.utc(2026, 7, 20, 9, 35),
            ),
          ),
        ],
      );

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('false when candlestick close differs', () {
      final a = _snapshot(values: [_value(candlestick: _candlestick())]);
      final b = _snapshot(
        values: [_value(candlestick: _candlestick(close: 108))],
      );

      expect(a.sameIdentityAs(b), isFalse);
    });

    test('false when only one side carries candlestick details', () {
      final a = _snapshot(values: [_value(candlestick: _candlestick())]);
      final b = _snapshot();

      expect(a.sameIdentityAs(b), isFalse);
      expect(b.sameIdentityAs(a), isFalse);
    });
  });

  group('CartesianTrackedSeriesValue.fromCrosshairValue', () {
    test('copies every CrosshairSeriesValue field and adds formatting', () {
      final candlestick = _candlestick();
      final source = CrosshairSeriesValue(
        seriesId: 'watts',
        seriesName: 'Watts',
        seriesColor: const Color(0xFFE91E63),
        x: 42.5,
        y: 318.25,
        dataPointIndex: 7,
        sourcePointIndices: const [12, 13, 14],
        isInterpolated: true,
        linkedSeriesId: 'watts-raw',
        isTrend: true,
        pointLabel: 'Interval 3',
        magnitudeValue: 88.5,
        formattedMagnitudeValue: '88.5 kg',
        magnitudeLabel: 'Mass',
        colorValue: 0.62,
        formattedColorValue: '62%',
        colorLabel: 'Effort',
        opacityValue: 0.4,
        formattedOpacityValue: '40%',
        opacityLabel: 'Confidence',
        candlestick: candlestick,
        categoryValue: 'Threshold',
        categoryLabel: 'Zone',
      );

      final tracked = CartesianTrackedSeriesValue.fromCrosshairValue(
        source,
        formattedX: '42.5 min',
        formattedY: '318.25 W',
        unitLabel: 'W',
      );

      expect(tracked.seriesId, source.seriesId);
      expect(tracked.seriesName, source.seriesName);
      expect(tracked.seriesColor, source.seriesColor);
      expect(tracked.x, source.x);
      expect(tracked.y, source.y);
      expect(tracked.dataPointIndex, source.dataPointIndex);
      expect(tracked.sourcePointIndices, source.sourcePointIndices);
      expect(tracked.isInterpolated, source.isInterpolated);
      expect(tracked.linkedSeriesId, source.linkedSeriesId);
      expect(tracked.isTrend, source.isTrend);
      expect(tracked.pointLabel, source.pointLabel);
      expect(tracked.magnitudeValue, source.magnitudeValue);
      expect(tracked.formattedMagnitudeValue, source.formattedMagnitudeValue);
      expect(tracked.magnitudeLabel, source.magnitudeLabel);
      expect(tracked.colorValue, source.colorValue);
      expect(tracked.formattedColorValue, source.formattedColorValue);
      expect(tracked.colorLabel, source.colorLabel);
      expect(tracked.opacityValue, source.opacityValue);
      expect(tracked.formattedOpacityValue, source.formattedOpacityValue);
      expect(tracked.opacityLabel, source.opacityLabel);
      expect(tracked.candlestick, same(candlestick));
      expect(tracked.categoryValue, source.categoryValue);
      expect(tracked.categoryLabel, source.categoryLabel);
      expect(tracked.formattedX, '42.5 min');
      expect(tracked.formattedY, '318.25 W');
      expect(tracked.unitLabel, 'W');
    });

    test('preserves defaults for optional fields', () {
      const source = CrosshairSeriesValue(
        seriesId: 'hr',
        seriesName: 'Heart rate',
        seriesColor: Color(0xFF4CAF50),
        x: 5,
        y: 132,
        dataPointIndex: 2,
        isInterpolated: false,
      );

      final tracked = CartesianTrackedSeriesValue.fromCrosshairValue(
        source,
        formattedX: '5 s',
        formattedY: '132 bpm',
      );

      expect(tracked.sourcePointIndices, isEmpty);
      expect(tracked.linkedSeriesId, isNull);
      expect(tracked.isTrend, isFalse);
      expect(tracked.pointLabel, isNull);
      expect(tracked.magnitudeValue, isNull);
      expect(tracked.formattedMagnitudeValue, isNull);
      expect(tracked.magnitudeLabel, isNull);
      expect(tracked.colorValue, isNull);
      expect(tracked.formattedColorValue, isNull);
      expect(tracked.colorLabel, isNull);
      expect(tracked.opacityValue, isNull);
      expect(tracked.formattedOpacityValue, isNull);
      expect(tracked.opacityLabel, isNull);
      expect(tracked.candlestick, isNull);
      expect(tracked.categoryValue, isNull);
      expect(tracked.categoryLabel, isNull);
      expect(tracked.unitLabel, isNull);
    });

    test('axisSeriesId resolves the linked series for trends', () {
      const linked = CrosshairSeriesValue(
        seriesId: 'trend-1',
        seriesName: 'Trend',
        seriesColor: Color(0xFF9C27B0),
        x: 1,
        y: 2,
        dataPointIndex: 0,
        isInterpolated: false,
        linkedSeriesId: 'power',
        isTrend: true,
      );

      final tracked = CartesianTrackedSeriesValue.fromCrosshairValue(
        linked,
        formattedX: '1',
        formattedY: '2',
      );

      expect(tracked.axisSeriesId, 'power');
      expect(_value().axisSeriesId, 'power');
    });
  });
}
