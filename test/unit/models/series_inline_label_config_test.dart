import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesLabelPosition', () {
    test('has left, center, right values', () {
      expect(SeriesLabelPosition.values,
          containsAll([SeriesLabelPosition.left, SeriesLabelPosition.center, SeriesLabelPosition.right]));
    });
  });

  group('SeriesLabelBackground', () {
    test('default cornerRadius is null (auto-pill)', () {
      const bg = SeriesLabelBackground(color: Colors.white);
      expect(bg.cornerRadius, isNull);
    });

    test('default padding is symmetric(horizontal: 4, vertical: 2)', () {
      const bg = SeriesLabelBackground(color: Colors.white);
      expect(bg.padding,
          const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0));
    });

    test('default borderColor is null', () {
      const bg = SeriesLabelBackground(color: Colors.white);
      expect(bg.borderColor, isNull);
    });

    test('default borderWidth is 1.0', () {
      const bg = SeriesLabelBackground(color: Colors.white);
      expect(bg.borderWidth, 1.0);
    });

    test('equality', () {
      const a = SeriesLabelBackground(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0));
      const b = SeriesLabelBackground(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0));
      expect(a, equals(b));
    });

    test('inequality when color differs', () {
      const a = SeriesLabelBackground(color: Colors.white);
      const b = SeriesLabelBackground(color: Colors.black);
      expect(a, isNot(equals(b)));
    });

    test('inequality when cornerRadius differs', () {
      const a = SeriesLabelBackground(color: Colors.white, cornerRadius: 4.0);
      const b = SeriesLabelBackground(color: Colors.white, cornerRadius: 8.0);
      expect(a, isNot(equals(b)));
    });

    test('inequality when borderColor differs', () {
      const a = SeriesLabelBackground(color: Colors.white, borderColor: Colors.black);
      const b = SeriesLabelBackground(color: Colors.white);
      expect(a, isNot(equals(b)));
    });

    test('copyWith changes color, preserves other fields', () {
      const bg = SeriesLabelBackground(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0));
      final copy = bg.copyWith(color: Colors.black);
      expect(copy.color, Colors.black);
      expect(copy.padding,
          const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0));
    });

    test('copyWith can set cornerRadius to null', () {
      const bg = SeriesLabelBackground(color: Colors.white, cornerRadius: 4.0);
      final copy = bg.copyWith(cornerRadius: null);
      expect(copy.cornerRadius, isNull);
    });

    test('copyWith can set borderColor to null', () {
      const bg = SeriesLabelBackground(
          color: Colors.white, borderColor: Colors.black);
      final copy = bg.copyWith(borderColor: null);
      expect(copy.borderColor, isNull);
    });
  });

  group('SeriesInlineLabelConfig', () {
    test('requires text', () {
      const config = SeriesInlineLabelConfig(text: 'Power');
      expect(config.text, 'Power');
    });

    test('default position is right', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.position, SeriesLabelPosition.right);
    });

    test('default offsetY is 0.0', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.offsetY, 0.0);
    });

    test('default color is null (inherits series color)', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.color, isNull);
    });

    test('default fontSize is 11.0', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.fontSize, 11.0);
    });

    test('default fontWeight is w500', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.fontWeight, FontWeight.w500);
    });

    test('default background is null', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.background, isNull);
    });

    test('copyWith changes text', () {
      const config = SeriesInlineLabelConfig(text: 'old');
      final copy = config.copyWith(text: 'new');
      expect(copy.text, 'new');
      expect(copy.position, config.position);
    });

    test('copyWith changes position', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      final copy = config.copyWith(position: SeriesLabelPosition.center);
      expect(copy.position, SeriesLabelPosition.center);
    });

    test('equality', () {
      const a = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      const b = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      expect(a, equals(b));
    });

    test('inequality when text differs', () {
      const a = SeriesInlineLabelConfig(text: 'Power');
      const b = SeriesInlineLabelConfig(text: 'HR');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      const b = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('LineChartSeries.inlineLabel integration', () {
    test('defaults to null', () {
      const s = LineChartSeries(
        id: 'test',
        points: [],
      );
      expect(s.inlineLabel, isNull);
    });

    test('accepts SeriesInlineLabelConfig', () {
      const config = SeriesInlineLabelConfig(text: 'Power');
      const s = LineChartSeries(
        id: 'test',
        points: [],
        inlineLabel: config,
      );
      expect(s.inlineLabel, equals(config));
    });

    test('copyWith preserves inlineLabel', () {
      const config = SeriesInlineLabelConfig(text: 'Power');
      const s = LineChartSeries(id: 'test', points: [], inlineLabel: config);
      final copy = s.copyWith(strokeWidth: 3.0);
      expect(copy.inlineLabel, equals(config));
    });
  });

  group('AreaChartSeries.inlineLabel integration', () {
    test('defaults to null', () {
      const s = AreaChartSeries(id: 'test', points: []);
      expect(s.inlineLabel, isNull);
    });

    test('accepts SeriesInlineLabelConfig', () {
      const config = SeriesInlineLabelConfig(text: 'Fat Ox.');
      const s = AreaChartSeries(id: 'test', points: [], inlineLabel: config);
      expect(s.inlineLabel, equals(config));
    });
  });
}
