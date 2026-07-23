// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Pure partition/range/layout helpers behind faceting.
///
/// These are the only genuinely new computations faceting adds; everything
/// downstream is unchanged `PlotSpec.lower()`. They are tested in isolation,
/// out of the widget.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/grammar/facet_partition.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({
    required this.time,
    required this.power,
    required this.zone,
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.close = 0,
  });
  final double time;
  final double power;
  final Object? zone;
  final double open;
  final double high;
  final double low;
  final double close;
}

double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
Object? sampleZone(Sample row) => row.zone;
double sampleOpen(Sample row) => row.open;
double sampleHigh(Sample row) => row.high;
double sampleLow(Sample row) => row.low;
double sampleClose(Sample row) => row.close;

const rows = <Sample>[
  Sample(time: 0, power: 180, zone: 'easy'),
  Sample(time: 1, power: 260, zone: 'hard'),
  Sample(time: 2, power: 220, zone: 'easy'),
  Sample(time: 3, power: 300, zone: null),
];

void main() {
  group('distinctFacetValues', () {
    test('returns first-seen order and dedups, including a null value', () {
      expect(distinctFacetValues(rows, sampleZone), <Object?>['easy', 'hard', null]);
    });

    test('an empty row list yields no values', () {
      expect(distinctFacetValues(const <Sample>[], sampleZone), isEmpty);
    });
  });

  group('globalRange', () {
    test('spans the min/max of the y accessor across ALL rows', () {
      const spec = PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      );
      final range = globalRange(spec, rows, FacetAxis.y);
      expect(range, isNotNull);
      expect(range!.min, 180);
      expect(range.max, 300);
    });

    test('spans the min/max of the x accessor', () {
      const spec = PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      );
      final range = globalRange(spec, rows, FacetAxis.x)!;
      expect(range.min, 0);
      expect(range.max, 3);
    });

    test('candlestick y-range spans low..high across rows', () {
      const candles = <Sample>[
        Sample(time: 0, power: 0, zone: 'a', open: 10, high: 14, low: 9, close: 12),
        Sample(time: 1, power: 0, zone: 'a', open: 12, high: 18, low: 8, close: 15),
      ];
      const spec = PlotSpec<Sample>(
        data: candles,
        marks: <Mark<Sample>>[
          CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
          ),
        ],
      );
      final range = globalRange(spec, candles, FacetAxis.y)!;
      expect(range.min, 8);
      expect(range.max, 18);
    });

    test('reference-only marks contribute no range (null)', () {
      const spec = PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[ThresholdMark<Sample>(value: 250)],
      );
      expect(globalRange(spec, rows, FacetAxis.y), isNull);
    });

    test('non-finite values are skipped', () {
      const gapped = <Sample>[
        Sample(time: 0, power: 180, zone: 'a'),
        Sample(time: 1, power: double.nan, zone: 'a'),
        Sample(time: 2, power: 260, zone: 'a'),
      ];
      const spec = PlotSpec<Sample>(
        data: gapped,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      );
      final range = globalRange(spec, gapped, FacetAxis.y)!;
      expect(range.min, 180);
      expect(range.max, 260);
    });
  });

  group('autoColumns', () {
    test('is ceil(sqrt(n)), and never less than one', () {
      expect(autoColumns(1), 1);
      expect(autoColumns(2), 2);
      expect(autoColumns(3), 2);
      expect(autoColumns(4), 2);
      expect(autoColumns(5), 3);
      expect(autoColumns(9), 3);
      expect(autoColumns(10), 4);
    });
  });
}
