// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Radial lowering: channel→series mapping, config parity and diagnostics.
library;

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
Object fruitBlank(Fruit row) => '';
double sampleX(Fruit row) => row.count;
double sampleY(Fruit row) => row.mass;

const fruits = <Fruit>[
  Fruit(name: 'Apple', count: 30, mass: 5, basket: 'A'),
  Fruit(name: 'Pear', count: 20, mass: 3, basket: 'A'),
  Fruit(name: 'Plum', count: 10, mass: 2, basket: 'B'),
];

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  group('lowering plumbing', () {
    test('a Cartesian spec is not radial and lowers with null radial configs',
        () {
      const spec = PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[LineMark<Fruit>(x: sampleX, y: sampleY)],
      );
      expect(spec.isRadial, isFalse);
      final lowered = spec.lower();
      expect(lowered.concentricDonutConfig, isNull);
      expect(lowered.polarChartConfig, isNull);
    });

    test('a spec with a radial mark reports isRadial', () {
      const spec = PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(category: fruitName, value: fruitCount),
        ],
      );
      expect(spec.isRadial, isTrue);
    });
  });

  group('radial diagnostic factories', () {
    test('every radial diagnostic names its code and remedy', () {
      final mixed = GrammarSpecException.mixedCoordinateSystems('pie', ['ln']);
      expect(mixed.code, GrammarDiagnosticCode.mixedCoordinateSystems);
      expect(mixed.toString(), contains('mixedCoordinateSystems'));
      expect(mixed.message, contains('pie'));
      expect(mixed.message, contains('ln'));

      final many = GrammarSpecException.multipleRadialGeoms(['a', 'b']);
      expect(many.code, GrammarDiagnosticCode.multipleRadialGeoms);
      expect(many.message, contains('a'));
      expect(many.message, contains('b'));

      final axis = GrammarSpecException.axisOptionOnRadialSpec('grid');
      expect(axis.code, GrammarDiagnosticCode.axisOptionOnRadialSpec);
      expect(axis.message, contains('grid'));

      final empty = GrammarSpecException.emptyRadialCategories('pie');
      expect(empty.code, GrammarDiagnosticCode.emptyRadialCategories);
      expect(empty.message, contains('pie'));

      final facet = GrammarSpecException.facetedRadialUnsupported('pie');
      expect(facet.code, GrammarDiagnosticCode.facetedRadialUnsupported);
      expect(facet.message, contains('pie'));
    });
  });
}
