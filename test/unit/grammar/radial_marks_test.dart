// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Fruit {
  const Fruit({
    required this.name,
    required this.count,
    this.mass = 0,
    this.basket = '',
  });
  final String name;
  final double count;
  final double mass;
  final String basket;
}

Object fruitName(Fruit row) => row.name;
double fruitCount(Fruit row) => row.count;
double fruitMass(Fruit row) => row.mass;
Object fruitBasket(Fruit row) => row.basket;
Color? fruitColumnColor(Fruit row) => const Color(0xFF112233);
Color? fruitSliceColor(Fruit row) => const Color(0xFFFF0000);
num? fruitTarget(Fruit row) => row.mass;
num? fruitLow(Fruit row) => row.mass - 1;
num? fruitHigh(Fruit row) => row.mass + 1;

void main() {
  group('radial marks are const and value-equal', () {
    test('PieMark is const-constructible and value-equal', () {
      const a = PieMark<Fruit>(category: fruitName, value: fruitCount);
      const b = PieMark<Fruit>(category: fruitName, value: fruitCount);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isA<RadialMark<Fruit>>());
      expect(a, isA<Mark<Fruit>>());
    });

    test('PieMark distinguishes its optional radius accessor', () {
      const withRadius = PieMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        radius: fruitMass,
      );
      const without = PieMark<Fruit>(category: fruitName, value: fruitCount);
      expect(withRadius == without, isFalse);
    });

    test('sliceColor participates in PieMark and DonutMark equality', () {
      const pieA = PieMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        sliceColor: fruitSliceColor,
      );
      const pieB = PieMark<Fruit>(category: fruitName, value: fruitCount);
      expect(pieA == pieB, isFalse);
      expect(pieA.hashCode == pieB.hashCode, isFalse);
      expect(pieA.sliceColor, same(fruitSliceColor));
      expect(pieB.sliceColor, isNull);
      expect(
        pieA,
        const PieMark<Fruit>(
          category: fruitName,
          value: fruitCount,
          sliceColor: fruitSliceColor,
        ),
      );

      const donutA = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        sliceColor: fruitSliceColor,
      );
      const donutB = DonutMark<Fruit>(category: fruitName, value: fruitCount);
      expect(donutA == donutB, isFalse);
      expect(donutA.hashCode == donutB.hashCode, isFalse);
      expect(donutA.sliceColor, same(fruitSliceColor));
      expect(donutB.sliceColor, isNull);
      expect(
        donutA,
        const DonutMark<Fruit>(
          category: fruitName,
          value: fruitCount,
          sliceColor: fruitSliceColor,
        ),
      );
    });

    test('DonutMark carries a ring accessor and center content', () {
      const mark = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        center: DonutCenterContent(label: 'Total'),
      );
      expect(mark.ring, same(fruitBasket));
      expect(mark.center, const DonutCenterContent(label: 'Total'));
      expect(mark, isA<RadialMark<Fruit>>());
    });

    test('DonutMark carries a concentric config in equality', () {
      const withConfig = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        concentric: ConcentricDonutConfig(ringGap: 12),
      );
      const without = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
      );
      expect(withConfig == without, isFalse);
      expect(withConfig.hashCode == without.hashCode, isFalse);
      expect(withConfig.concentric, const ConcentricDonutConfig(ringGap: 12));
      expect(without.concentric, isNull);
      expect(
        withConfig,
        const DonutMark<Fruit>(
          category: fruitName,
          value: fruitCount,
          ring: fruitBasket,
          concentric: ConcentricDonutConfig(ringGap: 12),
        ),
      );
    });

    test('dataLabelsByRing participates in DonutMark equality', () {
      const outer = PieDataLabelConfig(position: PieDataLabelPosition.inside);
      const withOverrides = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        dataLabelsByRing: {'outer': outer},
      );
      const without = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
      );
      expect(withOverrides == without, isFalse);
      expect(withOverrides.hashCode == without.hashCode, isFalse);
      expect(withOverrides.dataLabelsByRing, const {'outer': outer});
      expect(without.dataLabelsByRing, isNull);
      expect(
        withOverrides,
        const DonutMark<Fruit>(
          category: fruitName,
          value: fruitCount,
          ring: fruitBasket,
          dataLabelsByRing: {'outer': outer},
        ),
      );
    });

    test('dataLabelsByRing equality compares entries, not map order', () {
      // Two maps with the same entries in a different insertion order are the
      // same override set, so the marks must be equal AND hash alike.
      const outer = PieDataLabelConfig(position: PieDataLabelPosition.inside);
      const inner = PieDataLabelConfig(isVisible: false);
      final forwards = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        dataLabelsByRing: <String, PieDataLabelConfig>{
          'outer': outer,
          'inner': inner,
        },
      );
      final backwards = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        dataLabelsByRing: <String, PieDataLabelConfig>{
          'inner': inner,
          'outer': outer,
        },
      );
      expect(forwards, backwards);
      expect(forwards.hashCode, backwards.hashCode);

      // A different VALUE for the same key is a different mark.
      final swapped = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        dataLabelsByRing: <String, PieDataLabelConfig>{
          'outer': inner,
          'inner': outer,
        },
      );
      expect(forwards == swapped, isFalse);
    });

    test('PolarMark holds a polar style', () {
      const mark = PolarMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        style: PolarColumnStyle(cornerRadius: 6),
      );
      expect(mark.style, const PolarColumnStyle(cornerRadius: 6));
    });

    test('PolarMark carries advanced fields in equality', () {
      const a = PolarMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        preset: PolarColumnPreset.rose,
        targetMarkerStyle: PolarColumnTargetMarkerStyle(width: 3),
      );
      const b = PolarMark<Fruit>(category: fruitName, value: fruitCount);
      expect(a == b, isFalse);
      expect(a.preset, PolarColumnPreset.rose);
      expect(b.preset, PolarColumnPreset.standard);
      expect(b.targetMarkerStyle, isNull);
    });

    test('PolarMark distinguishes its per-row advanced channels', () {
      const base = PolarMark<Fruit>(category: fruitName, value: fruitCount);
      const withColumnColor = PolarMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        columnColor: fruitColumnColor,
      );
      const withTarget = PolarMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        target: fruitTarget,
      );
      const withInterval = PolarMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        intervalLow: fruitLow,
        intervalHigh: fruitHigh,
        intervalStyle: PolarColumnIntervalStyle(width: 2),
      );

      expect(base == withColumnColor, isFalse);
      expect(base == withTarget, isFalse);
      expect(base == withInterval, isFalse);
      expect(withColumnColor.columnColor, same(fruitColumnColor));
      expect(withTarget.target, same(fruitTarget));
      expect(withInterval.intervalLow, same(fruitLow));
      expect(withInterval.intervalHigh, same(fruitHigh));
      expect(
        withInterval.intervalStyle,
        const PolarColumnIntervalStyle(width: 2),
      );
      expect(base.hashCode == withInterval.hashCode, isFalse);
      expect(
        withInterval,
        const PolarMark<Fruit>(
          category: fruitName,
          value: fruitCount,
          intervalLow: fruitLow,
          intervalHigh: fruitHigh,
          intervalStyle: PolarColumnIntervalStyle(width: 2),
        ),
      );
    });

    // `preset` is the one PolarMark field that changes what the series MEANS
    // (linear-radius columns vs an equal-angle rose), so a debug print that
    // omits it renders two marks with different geometry identically. Two
    // marks differing ONLY in preset must therefore describe themselves
    // differently.
    test('PolarMark.toString names its preset', () {
      const standard = PolarMark<Fruit>(
        id: 'wind',
        name: 'Wind',
        category: fruitName,
        value: fruitCount,
      );
      const rose = PolarMark<Fruit>(
        id: 'wind',
        name: 'Wind',
        category: fruitName,
        value: fruitCount,
        preset: PolarColumnPreset.rose,
      );

      expect(
        standard.toString(),
        'PolarMark(id: wind, name: Wind, preset: standard)',
      );
      expect(rose.toString(), 'PolarMark(id: wind, name: Wind, preset: rose)');
      expect(standard.toString() == rose.toString(), isFalse);
    });
  });
}
