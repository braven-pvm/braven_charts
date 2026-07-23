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
}
