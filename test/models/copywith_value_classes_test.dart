import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bar value-class copyWith', () {
    test('BarChartStyle copyWith replaces one field, preserves the rest', () {
      const base = BarChartStyle(cornerRadius: 2, opacity: 0.9);
      final next = base.copyWith(opacity: 0.5);
      expect(next.opacity, 0.5);
      expect(next.cornerRadius, 2);
      expect(base.copyWith(), equals(base)); // identity
    });

    test('BarChartStyle clear flag unsets a nullable nested field', () {
      const base = BarChartStyle(border: BarBorderStyle(color: Color(0xFF000000)));
      expect(base.copyWith(clearBorder: true).border, isNull);
      expect(base.copyWith().border, isNotNull); // no-op preserves
    });

    test('BarTrackStyle clear flag unsets nullable value', () {
      const base = BarTrackStyle(color: Color(0xFF112233), value: 10);
      expect(base.copyWith(clearValue: true).value, isNull);
      expect(base.copyWith(value: 20).value, 20);
    });
  });

  group('candlestick + scatter value-class copyWith', () {
    test('CandlestickChartStyle clears a nullable colour, preserves others', () {
      const base = CandlestickChartStyle(
        risingBodyFillColor: Color(0xFF00FF00),
        bodyWidthFactor: 0.5,
      );
      expect(base.copyWith(clearRisingBodyFillColor: true).risingBodyFillColor, isNull);
      expect(base.copyWith(clearRisingBodyFillColor: true).bodyWidthFactor, 0.5);
      expect(base.copyWith(bodyWidthFactor: 0.6).bodyWidthFactor, 0.6);
    });

    test('ScatterClusterConfig copyWith replaces one field', () {
      const base = ScatterClusterConfig(cellSize: 40, maximumRadius: 24);
      expect(base.copyWith(cellSize: 50).cellSize, 50);
      expect(base.copyWith(cellSize: 50).maximumRadius, 24);
      expect(base.copyWith(), equals(base));
    });

    test('ScatterBinConfig + ScatterDensityConfig copyWith identity', () {
      const bin = ScatterBinConfig(cellSize: 36);
      const density = ScatterDensityConfig(bandwidth: 32);
      expect(bin.copyWith(), equals(bin));
      expect(density.copyWith(contourCount: 8).contourCount, 8);
    });
  });
}
