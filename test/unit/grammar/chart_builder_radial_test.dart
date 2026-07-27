// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// The chained facade's radial verbs equal the hand-written PlotSpec.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Fruit {
  const Fruit({required this.name, required this.count, this.mass = 0, this.basket = ''});
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

const fruits = <Fruit>[
  Fruit(name: 'Apple', count: 30, mass: 5, basket: 'A'),
  Fruit(name: 'Pear', count: 20, mass: 3, basket: 'A'),
  Fruit(name: 'Plum', count: 10, mass: 2, basket: 'B'),
];

void main() {
  group('geomPie equals the hand-written spec', () {
    test('geomPie appends a PieMark with its channels and style', () {
      final spec = BravenChart.of(fruits)
          .geomPie(
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
            name: 'Fruit',
            color: const Color(0xFF2563EB),
            style: const PieChartStyle(radiusFactor: 0.8),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              radius: fruitMass,
              name: 'Fruit',
              color: Color(0xFF2563EB),
              style: PieChartStyle(radiusFactor: 0.8),
            ),
          ],
        ),
      );
    });
  });

  group('geomDonut equals the hand-written spec', () {
    test('geomDonut appends a DonutMark with its channels and center', () {
      final spec = BravenChart.of(fruits)
          .geomDonut(
            category: fruitName,
            value: fruitCount,
            name: 'Fruit',
            center: const DonutCenterContent(label: 'Total'),
            style: const DonutChartStyle(innerRadiusFactor: 0.5),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              name: 'Fruit',
              center: DonutCenterContent(label: 'Total'),
              style: DonutChartStyle(innerRadiusFactor: 0.5),
            ),
          ],
        ),
      );
    });
  });

  group('geomDonut carries a concentric composition', () {
    test('geomDonut appends a DonutMark with its concentric config', () {
      final spec = BravenChart.of(fruits)
          .geomDonut(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            concentric: const ConcentricDonutConfig(
              ringGap: 12,
              order: ConcentricRingOrder.innerToOuter,
            ),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              concentric: ConcentricDonutConfig(
                ringGap: 12,
                order: ConcentricRingOrder.innerToOuter,
              ),
            ),
          ],
        ),
      );
    });
  });

  group('geomPolar equals the hand-written spec', () {
    test('geomPolar appends a PolarMark with its channels and style', () {
      final spec = BravenChart.of(fruits)
          .geomPolar(
            category: fruitName,
            value: fruitCount,
            name: 'Fruit',
            style: const PolarColumnStyle(cornerRadius: 6),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              name: 'Fruit',
              style: PolarColumnStyle(cornerRadius: 6),
            ),
          ],
        ),
      );
    });

    test('geomPolar rose: true selects the rose preset', () {
      final spec = BravenChart.of(fruits)
          .geomPolar(category: fruitName, value: fruitCount, rose: true)
          .toSpec();
      final mark = spec.marks.single as PolarMark<Fruit>;
      expect(mark.preset, PolarColumnPreset.rose);
    });

    test('geomPolar defaults to the standard preset', () {
      final spec = BravenChart.of(fruits)
          .geomPolar(category: fruitName, value: fruitCount)
          .toSpec();
      final mark = spec.marks.single as PolarMark<Fruit>;
      expect(mark.preset, PolarColumnPreset.standard);
    });

    test('geomPolar forwards the advanced per-series channels and styles', () {
      final spec = BravenChart.of(fruits)
          .geomPolar(
            category: fruitName,
            value: fruitCount,
            columnColor: fruitColumnColor,
            target: fruitTarget,
            targetMarkerStyle: const PolarColumnTargetMarkerStyle(width: 3),
            intervalLow: fruitLow,
            intervalHigh: fruitHigh,
            intervalStyle: const PolarColumnIntervalStyle(width: 2),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              columnColor: fruitColumnColor,
              target: fruitTarget,
              targetMarkerStyle: PolarColumnTargetMarkerStyle(width: 3),
              intervalLow: fruitLow,
              intervalHigh: fruitHigh,
              intervalStyle: PolarColumnIntervalStyle(width: 2),
            ),
          ],
        ),
      );
    });
  });
}
