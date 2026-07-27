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
  });
}
