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
    test('default opacity is 0.85', () {
      const bg = SeriesLabelBackground(color: Colors.white);
      expect(bg.opacity, 0.85);
    });

    test('equality', () {
      const a = SeriesLabelBackground(color: Colors.white, opacity: 0.9);
      const b = SeriesLabelBackground(color: Colors.white, opacity: 0.9);
      expect(a, equals(b));
    });

    test('inequality when color differs', () {
      const a = SeriesLabelBackground(color: Colors.white);
      const b = SeriesLabelBackground(color: Colors.black);
      expect(a, isNot(equals(b)));
    });

    test('copyWith changes color', () {
      const bg = SeriesLabelBackground(color: Colors.white, opacity: 0.9);
      final copy = bg.copyWith(color: Colors.black);
      expect(copy.color, Colors.black);
      expect(copy.opacity, 0.9);
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
