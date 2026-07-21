// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/summary/value_summary_adapters.dart';
import 'package:flutter_test/flutter_test.dart';

const _blue = Color(0xFF2196F3);
const _green = Color(0xFF4CAF50);
const _amber = Color(0xFFFFC107);

CartesianTrackedSeriesValue _lineValue({
  String seriesId = 'power',
  String seriesName = 'Power',
  Color seriesColor = _blue,
  double y = 250,
  String formattedX = '5',
  String formattedY = '250 W',
  String? unitLabel = 'W',
  List<int> sourcePointIndices = const [],
  bool isTrend = false,
}) => CartesianTrackedSeriesValue(
  seriesId: seriesId,
  seriesName: seriesName,
  seriesColor: seriesColor,
  x: 5,
  y: y,
  dataPointIndex: isTrend ? -1 : 4,
  sourcePointIndices: sourcePointIndices,
  isInterpolated: isTrend,
  isTrend: isTrend,
  formattedX: formattedX,
  formattedY: formattedY,
  unitLabel: unitLabel,
);

CartesianTrackingSnapshot _snapshot(List<CartesianTrackedSeriesValue> values) =>
    CartesianTrackingSnapshot(
      dataX: 5,
      plotX: 50,
      values: values,
      origin: CartesianTrackingOrigin.pointer,
    );

const _automatic = CartesianValueSummaryContent.automatic();

CartesianValueSummaryContentModel _build(
  CartesianTrackingSnapshot snapshot, {
  CartesianValueSummaryContent content = _automatic,
  bool showSeriesAccent = true,
}) => ValueSummaryAdapter.build(
  snapshot,
  content: content,
  showSeriesAccent: showSeriesAccent,
);

void main() {
  group('ValueSummaryAdapter line and area', () {
    test('single series produces title, X subtitle, and one value row', () {
      final model = _build(_snapshot([_lineValue()]));
      expect(model.title, 'Power');
      expect(model.subtitle, '5');
      expect(model.accentColor, _blue);
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'Value', value: '250 W'),
      ]);
    });

    test('accent is omitted when showSeriesAccent is false', () {
      final model = _build(_snapshot([_lineValue()]), showSeriesAccent: false);
      expect(model.accentColor, isNull);
      expect(model.rows, hasLength(1));
    });

    test('formattedY is consumed as-is and unitLabel is never re-appended', () {
      final withUnit = _build(
        _snapshot([_lineValue(formattedY: '250 W', unitLabel: 'W')]),
      );
      final withoutUnit = _build(
        _snapshot([_lineValue(formattedY: '250 W', unitLabel: null)]),
      );
      expect(withUnit.rows.single.value, '250 W');
      expect(withoutUnit.rows.single.value, '250 W');
      expect(withUnit, withoutUnit);
    });
  });

  group('ValueSummaryAdapter bar', () {
    test('category context comes from formattedX with the formatted value', () {
      final model = _build(
        _snapshot([
          _lineValue(
            seriesName: 'Revenue',
            formattedX: 'Q3',
            formattedY: '1.2M',
            unitLabel: null,
          ),
        ]),
      );
      expect(model.title, 'Revenue');
      expect(model.subtitle, 'Q3');
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'Value', value: '1.2M'),
      ]);
    });

    test('aggregated samples expose their grouped context', () {
      final model = _build(
        _snapshot([
          _lineValue(
            seriesName: 'Revenue',
            formattedY: '1.2M',
            unitLabel: null,
            sourcePointIndices: const [3, 4, 5],
          ),
        ]),
      );
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'Value', value: '1.2M'),
        CartesianValueSummaryRow(label: 'Grouped', value: '3 points'),
      ]);
    });
  });

  group('ValueSummaryAdapter scatter', () {
    CartesianTrackedSeriesValue scatterValue({
      String? pointLabel = 'Alpha',
      double? magnitudeValue = 12,
      String? formattedMagnitudeValue = '12 kg',
      String? magnitudeLabel = 'Load',
      double? colorValue = 80,
      String? formattedColorValue = '80 %',
      String? colorLabel = 'Effort',
      double? opacityValue = 0.4,
      String? formattedOpacityValue = '0.4',
      String? opacityLabel = 'Confidence',
      String? categoryValue = 'Elite',
      String? categoryLabel = 'Tier',
    }) => CartesianTrackedSeriesValue(
      seriesId: 'athletes',
      seriesName: 'Athletes',
      seriesColor: _amber,
      x: 5,
      y: 42,
      dataPointIndex: 7,
      isInterpolated: false,
      pointLabel: pointLabel,
      magnitudeValue: magnitudeValue,
      formattedMagnitudeValue: formattedMagnitudeValue,
      magnitudeLabel: magnitudeLabel,
      colorValue: colorValue,
      formattedColorValue: formattedColorValue,
      colorLabel: colorLabel,
      opacityValue: opacityValue,
      formattedOpacityValue: formattedOpacityValue,
      opacityLabel: opacityLabel,
      categoryValue: categoryValue,
      categoryLabel: categoryLabel,
      formattedX: '5',
      formattedY: '42',
    );

    test('all encodings produce X/Y plus one labelled row per trio', () {
      final model = _build(_snapshot([scatterValue()]));
      expect(model.title, 'Athletes');
      expect(model.subtitle, 'Alpha');
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'X', value: '5'),
        CartesianValueSummaryRow(label: 'Y', value: '42'),
        CartesianValueSummaryRow(label: 'Load', value: '12 kg'),
        CartesianValueSummaryRow(label: 'Effort', value: '80 %'),
        CartesianValueSummaryRow(label: 'Confidence', value: '0.4'),
        CartesianValueSummaryRow(label: 'Tier', value: 'Elite'),
      ]);
    });

    test('absent encodings produce no rows', () {
      final model = _build(
        _snapshot([
          scatterValue(
            colorValue: null,
            formattedColorValue: null,
            colorLabel: null,
            opacityValue: null,
            formattedOpacityValue: null,
            opacityLabel: null,
            categoryValue: null,
            categoryLabel: null,
          ),
        ]),
      );
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'X', value: '5'),
        CartesianValueSummaryRow(label: 'Y', value: '42'),
        CartesianValueSummaryRow(label: 'Load', value: '12 kg'),
      ]);
    });

    test('encoding rows fall back to the tracking-tooltip labels', () {
      final model = _build(
        _snapshot([
          scatterValue(
            magnitudeLabel: null,
            colorLabel: null,
            opacityLabel: null,
            categoryLabel: null,
          ),
        ]),
      );
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'X', value: '5'),
        CartesianValueSummaryRow(label: 'Y', value: '42'),
        CartesianValueSummaryRow(label: 'Magnitude', value: '12 kg'),
        CartesianValueSummaryRow(label: 'Color value', value: '80 %'),
        CartesianValueSummaryRow(label: 'Opacity value', value: '0.4'),
        CartesianValueSummaryRow(label: 'Category', value: 'Elite'),
      ]);
    });

    test('a labelled point without encodings still reads as scatter', () {
      final model = _build(
        _snapshot([
          scatterValue(
            magnitudeValue: null,
            formattedMagnitudeValue: null,
            magnitudeLabel: null,
            colorValue: null,
            formattedColorValue: null,
            colorLabel: null,
            opacityValue: null,
            formattedOpacityValue: null,
            opacityLabel: null,
            categoryValue: null,
            categoryLabel: null,
          ),
        ]),
      );
      expect(model.subtitle, 'Alpha');
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'X', value: '5'),
        CartesianValueSummaryRow(label: 'Y', value: '42'),
      ]);
    });
  });

  group('ValueSummaryAdapter candlestick', () {
    CartesianTrackedSeriesValue candleValue({
      required CandlestickInteractionDetails details,
    }) => CartesianTrackedSeriesValue(
      seriesId: 'aapl',
      seriesName: 'AAPL',
      seriesColor: _green,
      x: 5,
      y: details.close,
      dataPointIndex: 4,
      isInterpolated: false,
      candlestick: details,
      formattedX: '5',
      formattedY: '105.00',
    );

    const details = CandlestickInteractionDetails(
      open: 100,
      high: 110,
      low: 95,
      close: 105,
      formattedOpen: '100.00 USD',
      formattedHigh: '110.00 USD',
      formattedLow: '95.00 USD',
      formattedClose: '105.00 USD',
      change: 5,
      changePercent: 5,
      formattedChange: '+5.00 USD (+5.00%)',
      direction: CandlestickDirection.rising,
      formattedTimestamp: 'Jan 5, 2026',
    );

    test(
      'OHLC, change, and direction rows use the payload strings verbatim',
      () {
        final model = _build(_snapshot([candleValue(details: details)]));
        expect(model.title, 'AAPL');
        expect(model.subtitle, 'Jan 5, 2026');
        expect(model.accentColor, _green);
        expect(model.rows, const [
          CartesianValueSummaryRow(label: 'Open', value: '100.00 USD'),
          CartesianValueSummaryRow(label: 'High', value: '110.00 USD'),
          CartesianValueSummaryRow(label: 'Low', value: '95.00 USD'),
          CartesianValueSummaryRow(label: 'Close', value: '105.00 USD'),
          CartesianValueSummaryRow(
            label: 'Change',
            value: '+5.00 USD (+5.00%)',
          ),
          CartesianValueSummaryRow(label: 'Direction', value: 'rising'),
        ]);
      },
    );

    test('grouped candles add a grouped row and fall back to formattedX', () {
      const grouped = CandlestickInteractionDetails(
        open: 100,
        high: 110,
        low: 95,
        close: 105,
        formattedOpen: '100.00 USD',
        formattedHigh: '110.00 USD',
        formattedLow: '95.00 USD',
        formattedClose: '105.00 USD',
        change: 5,
        changePercent: 5,
        formattedChange: '+5.00 USD (+5.00%)',
        direction: CandlestickDirection.rising,
        sourceCount: 3,
      );
      final model = _build(_snapshot([candleValue(details: grouped)]));
      expect(model.subtitle, '5');
      expect(
        model.rows.last,
        const CartesianValueSummaryRow(label: 'Grouped', value: '3 candles'),
      );
    });

    test('the factory-formatted change percentage survives unmodified', () {
      final fromPoint = CandlestickInteractionDetails.fromPoint(
        CandlestickDataPoint(x: 1, open: 120, high: 121, low: 116, close: 117),
        unit: 'USD',
      );
      expect(fromPoint.formattedChange, '-3.00 USD (-2.50%)');
      final model = _build(_snapshot([candleValue(details: fromPoint)]));
      final change = model.rows.singleWhere((row) => row.label == 'Change');
      expect(change.value, '-3.00 USD (-2.50%)');
    });
  });

  group('ValueSummaryAdapter multi-series and mixed', () {
    test('two line series collapse to one accented row per series', () {
      final model = _build(
        _snapshot([
          _lineValue(),
          _lineValue(
            seriesId: 'hr',
            seriesName: 'Heart rate',
            seriesColor: _green,
            formattedY: '150 bpm',
            unitLabel: 'bpm',
          ),
        ]),
      );
      expect(model.title, '5');
      expect(model.subtitle, isNull);
      expect(model.accentColor, _blue);
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'Power', value: '250 W', color: _blue),
        CartesianValueSummaryRow(
          label: 'Heart rate',
          value: '150 bpm',
          color: _green,
        ),
      ]);
    });

    test(
      'a multi-row family becomes a grouped section titled by its series',
      () {
        const details = CandlestickInteractionDetails(
          open: 100,
          high: 110,
          low: 95,
          close: 105,
          formattedOpen: '100.00 USD',
          formattedHigh: '110.00 USD',
          formattedLow: '95.00 USD',
          formattedClose: '105.00 USD',
          change: 5,
          changePercent: 5,
          formattedChange: '+5.00 USD (+5.00%)',
          direction: CandlestickDirection.rising,
        );
        final candle = CartesianTrackedSeriesValue(
          seriesId: 'aapl',
          seriesName: 'AAPL',
          seriesColor: _green,
          x: 5,
          y: 105,
          dataPointIndex: 4,
          isInterpolated: false,
          candlestick: details,
          formattedX: '5',
          formattedY: '105.00',
        );
        final model = _build(_snapshot([_lineValue(), candle]));
        expect(model.title, '5');
        expect(model.rows, const [
          CartesianValueSummaryRow(
            label: 'Power',
            value: '250 W',
            color: _blue,
          ),
          CartesianValueSummaryRow(label: 'AAPL', value: '', color: _green),
          CartesianValueSummaryRow(label: 'Open', value: '100.00 USD'),
          CartesianValueSummaryRow(label: 'High', value: '110.00 USD'),
          CartesianValueSummaryRow(label: 'Low', value: '95.00 USD'),
          CartesianValueSummaryRow(label: 'Close', value: '105.00 USD'),
          CartesianValueSummaryRow(
            label: 'Change',
            value: '+5.00 USD (+5.00%)',
          ),
          CartesianValueSummaryRow(label: 'Direction', value: 'rising'),
        ]);
      },
    );
  });

  group('ValueSummaryAdapter trends and hidden series', () {
    test('trend rows are excluded by default', () {
      final model = _build(
        _snapshot([
          _lineValue(),
          _lineValue(
            seriesId: 'trend-1',
            seriesName: 'Linear trend',
            seriesColor: _amber,
            formattedY: '240 W',
            isTrend: true,
          ),
        ]),
      );
      // With the trend excluded a single value remains, so the model uses
      // the single-series shape.
      expect(model.title, 'Power');
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'Value', value: '250 W'),
      ]);
    });

    test('trend rows appear only when includeTrends is true', () {
      final model = _build(
        _snapshot([
          _lineValue(),
          _lineValue(
            seriesId: 'trend-1',
            seriesName: 'Linear trend',
            seriesColor: _amber,
            formattedY: '240 W',
            isTrend: true,
          ),
        ]),
        content: const CartesianValueSummaryContent.automatic(
          includeTrends: true,
        ),
      );
      expect(model.rows, const [
        CartesianValueSummaryRow(label: 'Power', value: '250 W', color: _blue),
        CartesianValueSummaryRow(
          label: 'Linear trend',
          value: '240 W',
          color: _amber,
        ),
      ]);
      // The accent follows the primary (non-trend) value.
      expect(model.accentColor, _blue);
    });

    test('includeHiddenSeries has no adapter-side effect because hidden '
        'series are excluded upstream of the snapshot', () {
      // ResolvedChartData.renderSeries filters hiddenSeriesIds before series
      // elements are built, so a snapshot can never contain hidden-series
      // values for the adapter to re-admit.
      final snapshot = _snapshot([_lineValue()]);
      final without = _build(snapshot);
      final with_ = _build(
        snapshot,
        content: const CartesianValueSummaryContent.automatic(
          includeHiddenSeries: true,
        ),
      );
      expect(with_, without);
    });
  });

  group('ValueSummaryAdapter builder content and edge cases', () {
    test('builder content delegates to the builder with the snapshot', () {
      final snapshot = _snapshot([_lineValue()]);
      CartesianTrackingSnapshot? received;
      const custom = CartesianValueSummaryContentModel(
        title: 'Custom',
        rows: [CartesianValueSummaryRow(label: 'L', value: 'V')],
      );
      final model = _build(
        snapshot,
        content: CartesianValueSummaryContent.builder((s) {
          received = s;
          return custom;
        }),
      );
      expect(received, same(snapshot));
      expect(model, same(custom));
    });

    test('an empty snapshot produces an empty model', () {
      final model = _build(_snapshot(const []));
      expect(model.title, isNull);
      expect(model.subtitle, isNull);
      expect(model.accentColor, isNull);
      expect(model.rows, isEmpty);
    });

    test('identical inputs produce equal models across calls', () {
      final snapshot = _snapshot([_lineValue()]);
      expect(_build(snapshot), _build(snapshot));
    });

    test('structurally identical snapshots produce equal models', () {
      expect(
        _build(_snapshot([_lineValue()])),
        _build(_snapshot([_lineValue()])),
      );
    });
  });
}
