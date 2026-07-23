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

  group('pie channel to series mapping', () {
    test('values lower to angle-share slices in row order', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(category: fruitName, value: fruitCount),
        ],
      )).lower();

      final series = lowered.series.single as PieChartSeries;
      expect(series.id, 'mark-0');
      expect(series.points.map((p) => p.label), ['Apple', 'Pear', 'Plum']);
      expect(series.points.map((p) => p.y), [30, 20, 10]);
      expect(series.points.map((p) => p.x), [0, 1, 2]);
      expect(series.total, 60);
      // Angle-share = y / total.
      expect(series.points.first.y / series.total, 0.5);
      expect(lowered.concentricDonutConfig, isNull);
      expect(lowered.polarChartConfig, isNull);
      expect(lowered.yAxes, isEmpty);
      expect(lowered.annotations, isEmpty);
    });

    test('the radius channel lowers to variable slice radii', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PieChartSeries;
      expect(series.sliceRadiusConfig, isNotNull);
      expect(series.points.map((p) => p.pointStyle?.size), [5, 3, 2]);
    });
  });

  group('pie config parity', () {
    test('a lowered pie equals the hand-built PieChartSeries.fromMap', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            id: 'fruit',
            name: 'Fruit',
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PieChartSeries.fromMap(
          id: 'fruit',
          name: 'Fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
        ),
      );
    });

    test('the radius channel parity uses radiusValues', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
            id: 'fruit',
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PieChartSeries.fromMap(
          id: 'fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
          radiusValues: const {'Apple': 5, 'Pear': 3, 'Plum': 2},
        ),
      );
    });
  });

  group('radial coordinate-system diagnostics', () {
    test('a pie plus a line raises mixedCoordinateSystems', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
            LineMark<Fruit>(x: sampleX, y: sampleY),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.mixedCoordinateSystems),
      );
    });

    test('two pies raise multipleRadialGeoms', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount, id: 'a'),
            PieMark<Fruit>(category: fruitName, value: fruitCount, id: 'b'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.multipleRadialGeoms),
      );
    });

    test('a grid on a radial spec raises axisOptionOnRadialSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          grid: GridConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });

    test('a transposed radial spec raises axisOptionOnRadialSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          transposed: true,
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });

    test('an xAxis on a radial spec raises axisOptionOnRadialSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          xAxis: XAxisConfig(label: 'x'),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });

    test('all-blank category labels raise emptyRadialCategories', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitBlank, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyRadialCategories),
      );
    });

    test('empty radial data raises emptyData (so BravenPlot can swallow it)',
        () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });

    test('a structural radial error beats the empty-data guard', () {
      // axisOptionOnRadialSpec must fire even against empty data, so BravenPlot
      // only ever swallows an otherwise well-formed empty spec.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          grid: GridConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });
  });

  group('donut channel to series mapping and parity', () {
    test('a single donut lowers to one DonutChartSeries, no concentric config',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(category: fruitName, value: fruitCount, id: 'fruit'),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as DonutChartSeries;
      expect(series.id, 'fruit');
      expect(series.points.map((p) => p.label), ['Apple', 'Pear', 'Plum']);
      expect(series.points.map((p) => p.y), [30, 20, 10]);
      expect(lowered.concentricDonutConfig, isNull);
      expect(lowered.polarChartConfig, isNull);
    });

    test('a lowered donut equals the hand-built DonutChartSeries.fromMap', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            id: 'fruit',
            center: DonutCenterContent(label: 'Total'),
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        DonutChartSeries.fromMap(
          id: 'fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
          centerContent: const DonutCenterContent(label: 'Total'),
        ),
      );
    });
  });

  group('concentric donut (ring channel)', () {
    test('rings partition rows in first-seen order with a ConcentricDonutConfig',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
          ),
        ],
      )).lower();

      // baskets in first-seen order: A (Apple, Pear), B (Plum).
      expect(lowered.series, hasLength(2));
      expect(lowered.series.map((s) => s.id), ['fruit-A', 'fruit-B']);
      final ringA = lowered.series.first as DonutChartSeries;
      final ringB = lowered.series.last as DonutChartSeries;
      expect(ringA.points.map((p) => p.label), ['Apple', 'Pear']);
      expect(ringA.points.map((p) => p.y), [30, 20]);
      expect(ringB.points.map((p) => p.label), ['Plum']);
      expect(ringB.points.map((p) => p.y), [10]);
      expect(lowered.concentricDonutConfig, const ConcentricDonutConfig());
      expect(lowered.polarChartConfig, isNull);
    });

    test('each ring donut parity + shared center goes to the config', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            center: DonutCenterContent(label: 'All'),
          ),
        ],
      )).lower();

      expect(
        lowered.series.first,
        DonutChartSeries.fromMap(
          id: 'fruit-A',
          name: 'A',
          values: const {'Apple': 30, 'Pear': 20},
          centerContent: DonutCenterContent.hidden,
        ),
      );
      expect(
        lowered.concentricDonutConfig,
        const ConcentricDonutConfig(
          centerContent: DonutCenterContent(label: 'All'),
        ),
      );
    });

    test('a single-value ring collapses to one ring donut (not an error)', () {
      const oneBasket = <Fruit>[
        Fruit(name: 'Apple', count: 30, basket: 'A'),
        Fruit(name: 'Pear', count: 20, basket: 'A'),
      ];
      final lowered = (const PlotSpec<Fruit>(
        data: oneBasket,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(lowered.series.single.id, 'fruit-A');
      expect(lowered.concentricDonutConfig, const ConcentricDonutConfig());
    });
  });
}
