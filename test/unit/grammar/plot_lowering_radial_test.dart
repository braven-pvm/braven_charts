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

// Advanced polar per-series channels. Top-level so the marks stay const.
num? fruitTarget(Fruit row) => row.mass;
num? fruitLow(Fruit row) => row.count - 5;
num? fruitHigh(Fruit row) => row.count + 5;
num? fruitSparseTarget(Fruit row) => row.basket == 'A' ? row.mass : null;
Color? fruitColumnColor(Fruit row) =>
    row.basket == 'A' ? const Color(0xFF112233) : null;

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

      final misplaced = GrammarSpecException.polarConfigOnNonPolarSpec('pie');
      expect(misplaced.code, GrammarDiagnosticCode.polarConfigOnNonPolarSpec);
      expect(misplaced.toString(), contains('polarConfigOnNonPolarSpec'));
      expect(misplaced.message, contains('pie'));
      expect(misplaced.message, contains('geomPolar'));

      final interval = GrammarSpecException.incompletePolarInterval('polar');
      expect(interval.code, GrammarDiagnosticCode.incompletePolarInterval);
      expect(interval.toString(), contains('incompletePolarInterval'));
      expect(interval.message, contains('polar'));
      expect(interval.message, contains('intervalLow'));
      expect(interval.message, contains('intervalHigh'));

      final dup = GrammarSpecException.duplicateRadialCategory('Apple');
      expect(dup.code, GrammarDiagnosticCode.duplicateRadialCategory);
      expect(dup.toString(), contains('duplicateRadialCategory'));
      expect(dup.message, contains('Apple'));
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

    test('a yAxes entry on a radial spec raises axisOptionOnRadialSpec', () {
      // yAxes cannot be const (YAxisConfig's public ctor is non-const), so the
      // spec is built non-const while the marks list stays const.
      final spec = PlotSpec<Fruit>(
        data: fruits,
        marks: const <Mark<Fruit>>[
          PieMark<Fruit>(category: fruitName, value: fruitCount),
        ],
        yAxes: <YAxisConfig>[YAxisConfig(position: YAxisPosition.left)],
      );
      expect(
        spec.lower,
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

    test('a single-value ring keeps the mark center on the lone donut', () {
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
            center: DonutCenterContent(label: 'Total'),
          ),
        ],
      )).lower();

      // The render path only reads ConcentricDonutConfig.centerContent when
      // more than one donut series is present, so a collapsed single ring must
      // carry the mark's center on itself — exactly like the ring-less donut
      // path — or the center is silently hidden.
      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as DonutChartSeries;
      expect(series.id, 'fruit-A');
      expect(series.centerContent, const DonutCenterContent(label: 'Total'));
    });

    test('a genuine multi-value ring keeps center on the config (no regression)',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            center: DonutCenterContent(label: 'Total'),
          ),
        ],
      )).lower();

      // Two distinct rings → N series + a ConcentricDonutConfig; each ring's own
      // center stays hidden and the shared center lives on the config.
      expect(lowered.series, hasLength(2));
      for (final ring in lowered.series.cast<DonutChartSeries>()) {
        expect(ring.centerContent, DonutCenterContent.hidden);
      }
      expect(
        lowered.concentricDonutConfig,
        const ConcentricDonutConfig(
          centerContent: DonutCenterContent(label: 'Total'),
        ),
      );
    });
  });

  group('polar column channel to series mapping and parity', () {
    test('category maps to angular position and value to radius', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(category: fruitName, value: fruitCount, id: 'fruit'),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.id, 'fruit');
      expect(series.categories, ['Apple', 'Pear', 'Plum']);
      expect(series.points.map((p) => p.x), [0, 1, 2]);
      expect(series.points.map((p) => p.y), [30, 20, 10]);
      expect(lowered.polarChartConfig, const PolarChartConfig());
      expect(lowered.concentricDonutConfig, isNull);
    });

    test('a lowered polar equals the hand-built PolarColumnChartSeries.fromMap',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            id: 'fruit',
            name: 'Fruit',
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PolarColumnChartSeries.fromMap(
          id: 'fruit',
          name: 'Fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
        ),
      );
    });
  });

  group('polar advanced per-series channels', () {
    test('a target accessor and the rose preset lower to a rose series with '
        'category-ordered targetValues', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            target: fruitTarget,
            preset: PolarColumnPreset.rose,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.preset, PolarColumnPreset.rose);
      expect(series.targetValues, [5.0, 3.0, 2.0]);
    });

    test('an unset target accessor leaves targetValues empty', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.preset, PolarColumnPreset.standard);
      expect(series.targetValues, isEmpty);
      expect(series.intervalLowerValues, isEmpty);
      expect(series.intervalUpperValues, isEmpty);
    });

    test('a target accessor that returns null keeps the category null', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            target: fruitSparseTarget,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.targetValues, [5.0, 3.0, null]);
    });

    test('a columnColor accessor lowers to per-point PointStyle colors', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            columnColor: fruitColumnColor,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.points.map((p) => p.pointStyle?.color), [
        const Color(0xFF112233),
        const Color(0xFF112233),
        null,
      ]);
    });

    test('both interval accessors lower to aligned interval bounds', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            intervalLow: fruitLow,
            intervalHigh: fruitHigh,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.intervalLowerValues, [25.0, 15.0, 5.0]);
      expect(series.intervalUpperValues, [35.0, 25.0, 15.0]);
    });

    test('target and interval styles ride the mark onto the series', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            target: fruitTarget,
            targetMarkerStyle: PolarColumnTargetMarkerStyle(width: 3),
            intervalLow: fruitLow,
            intervalHigh: fruitHigh,
            intervalStyle: PolarColumnIntervalStyle(width: 4),
          ),
        ],
      )).lower();

      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.targetMarkerStyle.width, 3);
      expect(series.intervalStyle.width, 4);
    });

    test('an advanced polar mark equals the hand-built rose series', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            name: 'Fruit',
            category: fruitName,
            value: fruitCount,
            columnColor: fruitColumnColor,
            target: fruitTarget,
            targetMarkerStyle: PolarColumnTargetMarkerStyle(width: 3),
            intervalLow: fruitLow,
            intervalHigh: fruitHigh,
            intervalStyle: PolarColumnIntervalStyle(width: 4),
            preset: PolarColumnPreset.rose,
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PolarColumnChartSeries.rose(
          id: 'fruit',
          name: 'Fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
          columnColors: const {
            'Apple': Color(0xFF112233),
            'Pear': Color(0xFF112233),
          },
          targets: const {'Apple': 5.0, 'Pear': 3.0, 'Plum': 2.0},
          targetMarkerStyle: const PolarColumnTargetMarkerStyle(width: 3),
          intervals: const {
            'Apple': PolarColumnInterval(lower: 25, upper: 35),
            'Pear': PolarColumnInterval(lower: 15, upper: 25),
            'Plum': PolarColumnInterval(lower: 5, upper: 15),
          },
          intervalStyle: const PolarColumnIntervalStyle(width: 4),
        ),
      );
    });

    test('setting only the lower interval bound throws '
        'incompletePolarInterval', () {
      const spec = PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            intervalLow: fruitLow,
          ),
        ],
      );

      expect(
        spec.lower,
        throwsGrammarCode(GrammarDiagnosticCode.incompletePolarInterval),
      );
    });

    test('setting only the upper interval bound throws '
        'incompletePolarInterval', () {
      const spec = PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            intervalHigh: fruitHigh,
          ),
        ],
      );

      expect(
        spec.lower,
        throwsGrammarCode(GrammarDiagnosticCode.incompletePolarInterval),
      );
    });
  });

  group('multi-series polar', () {
    // A non-default composition, so a lowering that dropped the config (or
    // substituted `const PolarChartConfig()`) cannot pass by accident.
    const groupedPolar = PolarChartConfig(
      composition: PolarColumnCompositionConfig(
        mode: PolarColumnCompositionMode.grouped,
        groupInnerPadding: 0.2,
      ),
    );

    // Non-default in pane and radial axis but NOT in composition, so a single
    // polar mark may legally carry it (grouped/stacked need two series) while a
    // lowering that dropped it still cannot pass by accident.
    const customPolarPane = PolarChartConfig(
      pane: PolarPaneConfig(startAngleDegrees: -45, innerRadiusFactor: 0.15),
      radialAxis: PolarNumericAxisConfig(tickCount: 7),
    );

    test('two polar marks lower to two PolarColumnChartSeries with the config',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'cap',
            name: 'Capacity',
            category: fruitName,
            value: fruitCount,
          ),
          PolarMark<Fruit>(
            id: 'obs',
            name: 'Observed',
            category: fruitName,
            value: fruitMass,
          ),
        ],
        polar: groupedPolar,
      )).lower();

      expect(lowered.series, hasLength(2));
      expect(lowered.series.every((s) => s is PolarColumnChartSeries), isTrue);
      expect(lowered.series.map((s) => s.id), ['cap', 'obs']);
      final cap = lowered.series.first as PolarColumnChartSeries;
      final obs = lowered.series.last as PolarColumnChartSeries;
      expect(cap.name, 'Capacity');
      expect(cap.categories, ['Apple', 'Pear', 'Plum']);
      expect(cap.points.map((p) => p.y), [30, 20, 10]);
      expect(obs.name, 'Observed');
      expect(obs.points.map((p) => p.y), [5, 3, 2]);
      expect(lowered.polarChartConfig, groupedPolar);
      expect(lowered.polarChartConfig, isNot(const PolarChartConfig()));
      expect(lowered.concentricDonutConfig, isNull);
    });

    test('a single polar mark still carries the spec-level config', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(category: fruitName, value: fruitCount),
        ],
        polar: customPolarPane,
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(lowered.polarChartConfig, customPolarPane);
      expect(lowered.polarChartConfig, isNot(const PolarChartConfig()));
    });

    test('every polar mark is checked for a visible category', () {
      // The SECOND mark has no visible category. A guard that only inspected
      // the first mark would let it through silently.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(id: 'b', category: fruitBlank, value: fruitMass),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyRadialCategories),
      );
    });

    test('two polar marks plus a line still raise mixedCoordinateSystems', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(id: 'b', category: fruitName, value: fruitMass),
            LineMark<Fruit>(x: sampleX, y: sampleY),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.mixedCoordinateSystems),
      );
    });

    test('a pie and a donut mark still raise multipleRadialGeoms', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(id: 'p', category: fruitName, value: fruitCount),
            DonutMark<Fruit>(id: 'd', category: fruitName, value: fruitMass),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.multipleRadialGeoms),
      );
    });

    test('polarConfig on a pie spec raises polarConfigOnNonPolarSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(id: 'pie', category: fruitName, value: fruitCount),
          ],
          polar: PolarChartConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.polarConfigOnNonPolarSpec),
      );
    });

    test('polarConfig on a concentric donut raises polarConfigOnNonPolarSpec',
        () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              id: 'rings',
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
            ),
          ],
          polar: groupedPolar,
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.polarConfigOnNonPolarSpec),
      );
    });

    test('the misplaced-polarConfig guard beats the empty-data guard', () {
      // A structural placement error must fire even against empty data, so
      // BravenPlot only ever swallows an otherwise well-formed empty spec.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(id: 'pie', category: fruitName, value: fruitCount),
          ],
          polar: PolarChartConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.polarConfigOnNonPolarSpec),
      );
    });

    test('a pie and a polar mark raise multipleRadialGeoms', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(id: 'p', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(id: 'q', category: fruitName, value: fruitMass),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.multipleRadialGeoms),
      );
    });

    // REGRESSION: `.polarConfig(...)` is a PLOT-level verb available on every
    // chain, so the most likely way to misplace it is on a Cartesian one. The
    // placement guard used to live inside the radial branch, which a Cartesian
    // spec never enters — the config was silently dropped instead of named.
    test('polarConfig on a Cartesian spec raises polarConfigOnNonPolarSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            LineMark<Fruit>(id: 'power', x: sampleX, y: sampleY),
          ],
          polar: PolarChartConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.polarConfigOnNonPolarSpec),
      );
    });

    test('the Cartesian polarConfig diagnostic names the offending mark', () {
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            BarMark<Fruit>(id: 'bars', x: sampleX, y: sampleY),
          ],
          polar: PolarChartConfig(),
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.polarConfigOnNonPolarSpec);
      expect(thrown.message, contains('bars'));
      expect(thrown.message, contains('geomPolar'));
    });

    test('the Cartesian polarConfig guard beats the empty-data guard', () {
      // Data-INDEPENDENT placement errors surface even against empty rows, so
      // BravenPlot only ever swallows an otherwise well-formed empty spec.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            LineMark<Fruit>(id: 'power', x: sampleX, y: sampleY),
          ],
          polar: PolarChartConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.polarConfigOnNonPolarSpec),
      );
    });

    test('a Cartesian spec without polarConfig still lowers', () {
      // The positive control: the hoisted guard must not fire on the ordinary
      // Cartesian path.
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          LineMark<Fruit>(id: 'power', x: sampleX, y: sampleY),
        ],
      )).lower();
      expect(lowered.series, hasLength(1));
      expect(lowered.polarChartConfig, isNull);
    });
  });

  // A polar composition is N series over ONE shared angular axis and ONE shared
  // radial axis. `PolarColumnComposition.validate` is the contract, enforced at
  // widget mount and at artifact hydration; lowering must reach the same verdict
  // FIRST and by name, or an author's chain lowers clean and then blows up in
  // the render pipeline with a raw ArgumentError.
  group('polar composition diagnostics', () {
    test('polar marks with different units raise invalidPolarComposition', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'watts',
              category: fruitName,
              value: fruitCount,
              unit: 'W',
            ),
            PolarMark<Fruit>(
              id: 'beats',
              category: fruitName,
              value: fruitMass,
              unit: 'bpm',
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
      );
    });

    test('the unit diagnostic fires before the empty-data guard', () {
      // `PolarMark.unit` is a mark field, so a unit clash is decidable from the
      // spec's SHAPE. It must not hide behind an empty dataset and only surface
      // once real rows arrive.
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'watts',
              category: fruitName,
              value: fruitCount,
              unit: 'W',
            ),
            PolarMark<Fruit>(
              id: 'beats',
              category: fruitName,
              value: fruitMass,
              unit: 'bpm',
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.invalidPolarComposition);
      expect(thrown.message, contains('beats'));
      expect(thrown.message, contains('bpm'));
    });

    test('polar marks sharing a unit lower cleanly', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'a',
            category: fruitName,
            value: fruitCount,
            unit: 'W',
          ),
          PolarMark<Fruit>(
            id: 'b',
            category: fruitName,
            value: fruitMass,
            unit: 'W',
          ),
        ],
      )).lower();
      expect(lowered.series, hasLength(2));
    });

    test('a grouped composition with one polar mark raises '
        'invalidPolarComposition', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'only', category: fruitName, value: fruitCount),
          ],
          polar: PolarChartConfig(
            composition: PolarColumnCompositionConfig(
              mode: PolarColumnCompositionMode.grouped,
            ),
          ),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
      );
    });

    test('a stacked composition with one polar mark raises '
        'invalidPolarComposition even against empty data', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'only', category: fruitName, value: fruitCount),
          ],
          polar: PolarChartConfig(
            composition: PolarColumnCompositionConfig(
              mode: PolarColumnCompositionMode.stacked,
            ),
          ),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
      );
    });

    test('polar marks whose categories diverge raise invalidPolarComposition',
        () {
      // Two marks over ONE row list may still read DIFFERENT categories, which
      // no polar chart can draw: the two series would need two angular axes.
      expect(
        () => (PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            const PolarMark<Fruit>(
              id: 'a',
              category: fruitName,
              value: fruitCount,
            ),
            PolarMark<Fruit>(
              id: 'b',
              category: (row) => 'x${row.name}',
              value: fruitMass,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
      );
    });

    test('the composition diagnostic names its code and the offending mark',
        () {
      final invalid = GrammarSpecException.invalidPolarComposition(
        'The mark "b" reads in "bpm".',
      );
      expect(invalid.code, GrammarDiagnosticCode.invalidPolarComposition);
      expect(invalid.toString(), contains('invalidPolarComposition'));
      expect(invalid.message, contains('bpm'));
    });
  });

  group('radial duplicate-category diagnostics', () {
    // Two rows share the category 'Apple'. The old behavior collapsed them
    // last-row-wins through the families' fromMap; that silent collapse is now
    // a loud diagnostic.
    const dupCategories = <Fruit>[
      Fruit(name: 'Apple', count: 30),
      Fruit(name: 'Apple', count: 20),
      Fruit(name: 'Pear', count: 10),
    ];

    test('a pie with two rows sharing a category raises '
        'duplicateRadialCategory', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: dupCategories,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateRadialCategory),
      );
    });

    test('a polar with duplicate categories raises duplicateRadialCategory',
        () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: dupCategories,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(category: fruitName, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateRadialCategory),
      );
    });

    test('a donut WITHOUT a ring and duplicate categories raises '
        'duplicateRadialCategory', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: dupCategories,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(category: fruitName, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateRadialCategory),
      );
    });

    test('the diagnostic names the offending duplicate category', () {
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: dupCategories,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
        )).lower();
      } on GrammarSpecException catch (e) {
        thrown = e;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.duplicateRadialCategory);
      expect(thrown.message, contains('Apple'));
    });

    // REGRESSION (the trap): the SAME categories legitimately repeat across
    // DIFFERENT rings. Uniqueness is per-ring, so this is the expected
    // concentric shape and must NOT throw.
    test('the same categories across DIFFERENT rings lower without throwing',
        () {
      const crossRing = <Fruit>[
        Fruit(name: 'Apple', count: 30, basket: 'A'),
        Fruit(name: 'Pear', count: 20, basket: 'A'),
        Fruit(name: 'Apple', count: 10, basket: 'B'),
        Fruit(name: 'Pear', count: 5, basket: 'B'),
      ];
      final lowered = (const PlotSpec<Fruit>(
        data: crossRing,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
          ),
        ],
      )).lower();

      // Two rings, each with the same two categories → N series + config.
      expect(lowered.series, hasLength(2));
      expect(lowered.series.map((s) => s.id), ['fruit-A', 'fruit-B']);
      expect(lowered.concentricDonutConfig, const ConcentricDonutConfig());
      final ringA = lowered.series.first as DonutChartSeries;
      final ringB = lowered.series.last as DonutChartSeries;
      expect(ringA.points.map((p) => p.label), ['Apple', 'Pear']);
      expect(ringB.points.map((p) => p.label), ['Apple', 'Pear']);
    });

    test('a category duplicated WITHIN one ring raises '
        'duplicateRadialCategory', () {
      const dupWithinRing = <Fruit>[
        Fruit(name: 'Apple', count: 30, basket: 'A'),
        Fruit(name: 'Apple', count: 20, basket: 'A'),
        Fruit(name: 'Pear', count: 10, basket: 'B'),
      ];
      expect(
        () => (const PlotSpec<Fruit>(
          data: dupWithinRing,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'fruit',
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.duplicateRadialCategory),
      );
    });
  });
}
