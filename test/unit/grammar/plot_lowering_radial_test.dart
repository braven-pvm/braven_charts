// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Radial lowering: channel→series mapping, config parity and diagnostics.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/layout/polar_column_composition.dart';
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

// Pie/donut per-slice colour. Top-level so the marks stay const.
Color? fruitSliceColor(Fruit row) =>
    row.basket == 'A' ? const Color(0xFF112233) : null;
Color? fruitSolidSliceColor(Fruit row) => const Color(0xFF445566);
Color? fruitNoSliceColor(Fruit row) => null;

const fruits = <Fruit>[
  Fruit(name: 'Apple', count: 30, mass: 5, basket: 'A'),
  Fruit(name: 'Pear', count: 20, mass: 3, basket: 'A'),
  Fruit(name: 'Plum', count: 10, mass: 2, basket: 'B'),
];

// A CROSS-RING fixture: the same two categories appear in BOTH baskets, and
// `Apple` takes a DIFFERENT colour in each. `fruits` cannot express that —
// every fruit there belongs to exactly one basket, and `fromMap` reads
// `sliceColors[category]` only for the categories present in `values`, so a
// colour map resolved across the WHOLE data set would produce byte-identical
// rings and leave the per-bucket resolution unproven.
const crossRingFruits = <Fruit>[
  Fruit(name: 'Apple', count: 30, mass: 5, basket: 'A'),
  Fruit(name: 'Pear', count: 20, mass: 3, basket: 'A'),
  Fruit(name: 'Apple', count: 12, mass: 4, basket: 'B'),
  Fruit(name: 'Pear', count: 8, mass: 1, basket: 'B'),
];

/// Basket A colours `Apple` only; basket B colours BOTH, and gives `Apple` a
/// different colour. Resolved over the whole list the map collapses to
/// `{Apple: 0xFFDC2626, Pear: 0xFF0D9488}` (last non-null wins), which is wrong
/// for basket A on both keys.
Color? crossRingSliceColor(Fruit row) => switch ((row.basket, row.name)) {
  ('A', 'Apple') => const Color(0xFF2563EB),
  ('B', 'Apple') => const Color(0xFFDC2626),
  ('B', 'Pear') => const Color(0xFF0D9488),
  _ => null,
};

// Per-ring data-label fixtures. Top-level so the marks stay const. The BASE is
// itself non-default, so a resolution that fell back to the family default
// (rather than to `dataLabels`) fails on the unlisted ring too.
const insideLabels = PieDataLabelConfig(position: PieDataLabelPosition.inside);
const hiddenLabels = PieDataLabelConfig(isVisible: false);

/// A ConcentricDonutConfig whose every field differs from the default, so a
/// passthrough that quietly drops one cannot masquerade as success.
const customConcentric = ConcentricDonutConfig(
  innerRadiusFactor: 0.4,
  outerRadiusFactor: 0.9,
  ringGap: 12,
  order: ConcentricRingOrder.innerToOuter,
  ringWeights: <String, double>{'fruit-A': 2},
  legendMode: ConcentricDonutLegendMode.flat,
  centerContent: DonutCenterContent(label: 'Fleet'),
);

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  group('lowering plumbing', () {
    test(
      'a Cartesian spec is not radial and lowers with null radial configs',
      () {
        const spec = PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[LineMark<Fruit>(x: sampleX, y: sampleY)],
        );
        expect(spec.isRadial, isFalse);
        final lowered = spec.lower();
        expect(lowered.concentricDonutConfig, isNull);
        expect(lowered.polarChartConfig, isNull);
      },
    );

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

      final conflict = GrammarSpecException.conflictingConcentricCenter(
        'rings',
      );
      expect(conflict.code, GrammarDiagnosticCode.conflictingConcentricCenter);
      expect(conflict.toString(), contains('conflictingConcentricCenter'));
      expect(conflict.message, contains('rings'));
      expect(conflict.message, contains('center'));
      expect(conflict.message, contains('concentric'));

      final ringless = GrammarSpecException.concentricConfigOnRinglessDonut(
        'plain',
      );
      expect(
        ringless.code,
        GrammarDiagnosticCode.concentricConfigOnRinglessDonut,
      );
      expect(ringless.toString(), contains('concentricConfigOnRinglessDonut'));
      expect(ringless.message, contains('plain'));
      expect(ringless.message, contains('ring:'));
      expect(ringless.message, contains('center:'));

      final composition = GrammarSpecException.invalidConcentricComposition(
        'Ring gap must be finite and non-negative.',
        ringIds: <String>['fruit-A', 'fruit-B'],
      );
      expect(
        composition.code,
        GrammarDiagnosticCode.invalidConcentricComposition,
      );
      expect(composition.toString(), contains('invalidConcentricComposition'));
      expect(composition.message, contains('Ring gap'));
      expect(composition.message, contains('fruit-A'));
      expect(composition.message, contains(r"'<markId>-<ringKey>'"));

      final dup = GrammarSpecException.duplicateRadialCategory('Apple');
      expect(dup.code, GrammarDiagnosticCode.duplicateRadialCategory);
      expect(dup.toString(), contains('duplicateRadialCategory'));
      expect(dup.message, contains('Apple'));
    });

    // The `multipleRadialGeoms` message carries the ONLY statement of the
    // relaxed rule an author sees at the moment they hit the diagnostic: "at
    // most one radial geom" is now false for polar columns, and the message
    // must say which geom is the exception rather than sending the author off
    // to split a composition the grammar in fact accepts. Both halves are
    // pinned together so the sentence cannot survive as a lie: the message
    // must name `geomPolar` as the exception, AND the very composition it
    // points at must lower.
    test('multipleRadialGeoms names geomPolar as the one exception', () {
      final many = GrammarSpecException.multipleRadialGeoms(['a', 'b']);

      expect(many.code, GrammarDiagnosticCode.multipleRadialGeoms);
      expect(many.message, contains('at most one radial geom'));
      expect(many.message, contains('exception'));
      expect(many.message, contains('geomPolar'));
      // The exception is stated as a SHARING permission, not as a second
      // "split them" instruction.
      expect(many.message, contains('share a plot'));

      // The escape hatch the sentence promises is real: several geomPolar
      // marks lower instead of raising the diagnostic whose message names
      // them.
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
          PolarMark<Fruit>(id: 'b', category: fruitName, value: fruitMass),
        ],
      )).lower();
      expect(lowered.series, hasLength(2));

      // ...and it is genuinely an EXCEPTION, not a general relaxation: two
      // radial geoms that are not both polar still raise the diagnostic.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PieMark<Fruit>(id: 'b', category: fruitName, value: fruitMass),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.multipleRadialGeoms),
      );
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

    test('a sliceColor accessor lowers to per-point PointStyle colors, '
        'skipping nulls', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            sliceColor: fruitSliceColor,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PieChartSeries;
      expect(series.points.map((p) => p.pointStyle?.color), [
        const Color(0xFF112233),
        const Color(0xFF112233),
        null,
      ]);
      // A skipped category carries no PointStyle at all, so it stays on the
      // series colour exactly as an unset accessor leaves it.
      expect(series.points.last.pointStyle, isNull);
    });

    test(
      'an all-null sliceColor accessor lowers identically to an unset one',
      () {
        final allNull = (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(
              id: 'fruit',
              category: fruitName,
              value: fruitCount,
              sliceColor: fruitNoSliceColor,
            ),
          ],
        )).lower();
        final unset = (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(id: 'fruit', category: fruitName, value: fruitCount),
          ],
        )).lower();

        expect(allNull.series.single, unset.series.single);
      },
    );
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

    test(
      'empty radial data raises emptyData (so BravenPlot can swallow it)',
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
      },
    );

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
    test(
      'a single donut lowers to one DonutChartSeries, no concentric config',
      () {
        final lowered = (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              id: 'fruit',
            ),
          ],
        )).lower();

        expect(lowered.series, hasLength(1));
        final series = lowered.series.single as DonutChartSeries;
        expect(series.id, 'fruit');
        expect(series.points.map((p) => p.label), ['Apple', 'Pear', 'Plum']);
        expect(series.points.map((p) => p.y), [30, 20, 10]);
        expect(lowered.concentricDonutConfig, isNull);
        expect(lowered.polarChartConfig, isNull);
      },
    );

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

    test('sliceColor and radius compose on one donut point', () {
      // `fromMap` builds the GENERAL `PointStyle(color:, size:)`, so the two
      // channels must land on the same point rather than one overwriting the
      // other.
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            id: 'fruit',
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
            sliceColor: fruitSolidSliceColor,
          ),
        ],
      )).lower();

      final series = lowered.series.single as DonutChartSeries;
      expect(series.points.map((p) => p.pointStyle?.color), [
        const Color(0xFF445566),
        const Color(0xFF445566),
        const Color(0xFF445566),
      ]);
      expect(series.points.map((p) => p.pointStyle?.size), [5, 3, 2]);
      expect(
        series,
        DonutChartSeries.fromMap(
          id: 'fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
          sliceColors: const {
            'Apple': Color(0xFF445566),
            'Pear': Color(0xFF445566),
            'Plum': Color(0xFF445566),
          },
          radiusValues: const {'Apple': 5, 'Pear': 3, 'Plum': 2},
        ),
      );
    });
  });

  group('concentric donut (ring channel)', () {
    test(
      'rings partition rows in first-seen order with a ConcentricDonutConfig',
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
      },
    );

    test('a ring the accessor does not colour keeps the series colour', () {
      // Ring A takes the override and ring B's sole row is skipped back onto
      // the series colour. NOTE what this does NOT prove: every category here
      // lives in exactly one bucket, so it cannot distinguish a per-bucket
      // resolution from a whole-data-set one. That is the next test's job.
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            sliceColor: fruitSliceColor,
          ),
        ],
      )).lower();

      final ringA = lowered.series.first as DonutChartSeries;
      final ringB = lowered.series.last as DonutChartSeries;
      expect(ringA.points.map((p) => p.pointStyle?.color), [
        const Color(0xFF112233),
        const Color(0xFF112233),
      ]);
      expect(ringB.points.single.pointStyle, isNull);
      expect(
        ringA,
        DonutChartSeries.fromMap(
          id: 'fruit-A',
          name: 'A',
          values: const {'Apple': 30, 'Pear': 20},
          sliceColors: const {
            'Apple': Color(0xFF112233),
            'Pear': Color(0xFF112233),
          },
          centerContent: DonutCenterContent.hidden,
        ),
      );
    });

    test('sliceColor is resolved per ring bucket: the SAME category takes a '
        'DIFFERENT colour in each ring', () {
      // The discriminating shape. `Apple` and `Pear` are in BOTH baskets;
      // `Apple` is blue in A and red in B, and `Pear` is uncoloured in A but
      // teal in B. Resolving the accessor over the whole data set instead of
      // over `buckets[key]` collapses to one map per category (last non-null
      // wins), so ring A would come back red/teal. Both assertions below fail
      // under that mutation, which is what makes them worth having.
      final lowered = (const PlotSpec<Fruit>(
        data: crossRingFruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            sliceColor: crossRingSliceColor,
          ),
        ],
      )).lower();

      expect(lowered.series.map((s) => s.id), ['fruit-A', 'fruit-B']);
      final ringA = lowered.series.first as DonutChartSeries;
      final ringB = lowered.series.last as DonutChartSeries;
      expect(ringA.points.map((p) => p.label), ['Apple', 'Pear']);
      expect(ringA.points.map((p) => p.pointStyle?.color), [
        const Color(0xFF2563EB),
        isNull,
      ]);
      expect(ringB.points.map((p) => p.label), ['Apple', 'Pear']);
      expect(ringB.points.map((p) => p.pointStyle?.color), [
        const Color(0xFFDC2626),
        const Color(0xFF0D9488),
      ]);
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

    test('a single-ring collapse still honours its per-ring label override', () {
      // One distinct ring key only, so the composition collapses to a single
      // donut. That branch does not build its series the way the multi-ring
      // branch does, so it is a separate regression risk and gets its own test.
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
            dataLabelsByRing: <String, PieDataLabelConfig>{'A': hiddenLabels},
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as DonutChartSeries;
      expect(series.dataLabels.isVisible, isFalse);
      expect(series.dataLabels, hiddenLabels);
    });

    test('per-ring label overrides reach each ring; unlisted rings take the '
        'mark base', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            dataLabels: insideLabels,
            dataLabelsByRing: <String, PieDataLabelConfig>{'A': hiddenLabels},
          ),
        ],
      )).lower();

      // Ring A is overridden; ring B is unlisted and must take `dataLabels` —
      // NOT the family default, which `insideLabels` is deliberately not.
      final rings = lowered.series.cast<DonutChartSeries>();
      expect(rings.map((r) => r.name), ['A', 'B']);
      expect(rings.first.dataLabels.isVisible, isFalse);
      expect(rings.first.dataLabels, hiddenLabels);
      expect(rings.last.dataLabels.position, PieDataLabelPosition.inside);
      expect(rings.last.dataLabels, insideLabels);
    });

    test(
      'a genuine multi-value ring keeps center on the config (no regression)',
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
      },
    );

    test('a concentric config lowers carrying every one of its fields', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            concentric: customConcentric,
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(2));
      expect(lowered.concentricDonutConfig, customConcentric);
      // The config's own centerContent is the authoritative shared center.
      expect(
        lowered.concentricDonutConfig!.centerContent,
        const DonutCenterContent(label: 'Fleet'),
      );
      for (final ring in lowered.series.cast<DonutChartSeries>()) {
        expect(ring.centerContent, DonutCenterContent.hidden);
      }
    });

    test('a single-value ring keeps the concentric config and its center', () {
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
            concentric: customConcentric,
          ),
        ],
      )).lower();

      // The collapsed ring must carry the config's center on itself — the
      // render path only reads ConcentricDonutConfig.centerContent when more
      // than one donut series is present — and the config still round-trips.
      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as DonutChartSeries;
      expect(series.centerContent, const DonutCenterContent(label: 'Fleet'));
      expect(lowered.concentricDonutConfig, customConcentric);
    });

    test('a ring-less donut refuses concentric by name', () {
      // A ring-less donut composes no rings, so every field of the config
      // except `centerContent` is inert AND the capture path drops the config
      // entirely (`braven_chart_plus` only stamps it for >1 donut series). A
      // silent carry would hand the workbench a chain it cannot reproduce, so
      // the misplacement is named — exactly like polarConfigOnNonPolarSpec.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              id: 'fruit',
              concentric: customConcentric,
            ),
          ],
        )).lower(),
        throwsGrammarCode(
          GrammarDiagnosticCode.concentricConfigOnRinglessDonut,
        ),
      );
    });

    test(
      'a ring-less concentric config is refused before the empty-data guard',
      () {
        expect(
          () => (const PlotSpec<Fruit>(
            data: <Fruit>[],
            marks: <Mark<Fruit>>[
              DonutMark<Fruit>(
                category: fruitName,
                value: fruitCount,
                id: 'fruit',
                concentric: customConcentric,
              ),
            ],
          )).lower(),
          throwsGrammarCode(
            GrammarDiagnosticCode.concentricConfigOnRinglessDonut,
          ),
        );
      },
    );

    test('a ring-less donut refuses dataLabelsByRing by name', () {
      // The exact mistake the unknownRingKey guard exists to catch, in its most
      // inert form: with no `ring` channel there are no rings AT ALL, so the
      // whole map applies to nothing. The ringed guard cannot see this shape —
      // it lives inside the ring loop — so without a check here a real override
      // (and any typo inside it) vanishes silently. Mirrors
      // concentricConfigOnRinglessDonut, the sibling refusal for the sibling
      // field.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              id: 'fruit',
              dataLabelsByRing: <String, PieDataLabelConfig>{'A': hiddenLabels},
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.perRingOverrideOnRinglessDonut),
      );
    });

    test(
      'the ring-less dataLabelsByRing refusal names the map and the fix',
      () {
        Object? thrown;
        try {
          (const PlotSpec<Fruit>(
            data: fruits,
            marks: <Mark<Fruit>>[
              DonutMark<Fruit>(
                category: fruitName,
                value: fruitCount,
                id: 'fruit',
                dataLabelsByRing: <String, PieDataLabelConfig>{
                  'A': hiddenLabels,
                  'B': insideLabels,
                },
              ),
            ],
          )).lower();
        } catch (error) {
          thrown = error;
        }
        expect(thrown, isA<GrammarSpecException>());
        final failure = thrown! as GrammarSpecException;
        expect(failure.message, contains('fruit'));
        expect(failure.message, contains('dataLabelsByRing'));
        // Both dead keys are named, and so is the one-word fix.
        expect(failure.message, contains('"A"'));
        expect(failure.message, contains('"B"'));
        expect(failure.message, contains('ring:'));
        expect(failure.message, contains('dataLabels:'));
      },
    );

    test(
      'a ring-less dataLabelsByRing is refused before the empty-data guard',
      () {
        // Decidable from the mark's shape alone, so it belongs above the
        // emptyData guard with the other shape checks — a chain must not lower
        // clean over an empty data set and only report once rows arrive.
        expect(
          () => (const PlotSpec<Fruit>(
            data: <Fruit>[],
            marks: <Mark<Fruit>>[
              DonutMark<Fruit>(
                category: fruitName,
                value: fruitCount,
                id: 'fruit',
                dataLabelsByRing: <String, PieDataLabelConfig>{
                  'A': hiddenLabels,
                },
              ),
            ],
          )).lower(),
          throwsGrammarCode(
            GrammarDiagnosticCode.perRingOverrideOnRinglessDonut,
          ),
        );
      },
    );

    test('a ring-less donut with an EMPTY dataLabelsByRing lowers clean', () {
      // An empty map carries no override, so it is a no-op here for exactly the
      // reason it is a no-op on the ringed path. Refusing it would fork the two
      // paths apart on a map that means nothing either way.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              id: 'fruit',
              dataLabelsByRing: <String, PieDataLabelConfig>{},
            ),
          ],
        )).lower(),
        returnsNormally,
      );
    });

    test('a ring-less donut with no concentric keeps its center hidden', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(category: fruitName, value: fruitCount, id: 'fruit'),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(
        (lowered.series.single as DonutChartSeries).centerContent,
        DonutCenterContent.hidden,
      );
      expect(lowered.concentricDonutConfig, isNull);
    });

    test(
      'an invalid concentric config is refused above the empty-data guard',
      () {
        // Inverted radii are decidable from the CONFIG alone, so they must not
        // hide behind an empty (or single-ring) dataset and resurface as a raw
        // ArgumentError from ConcentricDonutLayoutCalculator at widget mount.
        expect(
          () => (const PlotSpec<Fruit>(
            data: <Fruit>[],
            marks: <Mark<Fruit>>[
              DonutMark<Fruit>(
                category: fruitName,
                value: fruitCount,
                ring: fruitBasket,
                id: 'fruit',
                concentric: ConcentricDonutConfig(
                  innerRadiusFactor: 0.9,
                  outerRadiusFactor: 0.5,
                ),
              ),
            ],
          )).lower(),
          throwsGrammarCode(GrammarDiagnosticCode.invalidConcentricComposition),
        );
      },
    );

    test(
      'an invalid concentric config cannot hide behind single-ring data',
      () {
        const oneBasket = <Fruit>[
          Fruit(name: 'Apple', count: 30, basket: 'A'),
          Fruit(name: 'Pear', count: 20, basket: 'A'),
        ];
        expect(
          () => (const PlotSpec<Fruit>(
            data: oneBasket,
            marks: <Mark<Fruit>>[
              DonutMark<Fruit>(
                category: fruitName,
                value: fruitCount,
                ring: fruitBasket,
                id: 'fruit',
                concentric: ConcentricDonutConfig(ringGap: -4),
              ),
            ],
          )).lower(),
          throwsGrammarCode(GrammarDiagnosticCode.invalidConcentricComposition),
        );
      },
    );

    test('a ring weight keyed by the ring value rather than the series id is '
        'refused by name', () {
      // The rings are ided `<markId>-<ringKey>`, so the natural-looking key
      // 'A' names no series. The render pipeline throws a raw ArgumentError
      // for exactly this; lowering must name it first.
      Object? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'fruit',
              concentric: ConcentricDonutConfig(
                ringWeights: <String, double>{'A': 2},
              ),
            ),
          ],
        )).lower();
      } catch (error) {
        thrown = error;
      }
      expect(thrown, isA<GrammarSpecException>());
      final failure = thrown! as GrammarSpecException;
      expect(failure.code, GrammarDiagnosticCode.invalidConcentricComposition);
      expect(failure.message, contains('"A"'));
      expect(failure.message, contains('fruit-A'));
    });

    test('a dataLabelsByRing key naming no ring is refused by name', () {
      // The mirror of the ringWeights mistake, in the other direction: the
      // override map is keyed by the BARE ring value, so the series id
      // 'fruit-A' names nothing. Left unchecked the entry is simply inert — it
      // applies to no ring and reports nothing — so the typo would survive into
      // the rendered chart.
      Object? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'fruit',
              dataLabelsByRing: <String, PieDataLabelConfig>{
                'fruit-A': hiddenLabels,
              },
            ),
          ],
        )).lower();
      } catch (error) {
        thrown = error;
      }
      expect(thrown, isA<GrammarSpecException>());
      final failure = thrown! as GrammarSpecException;
      expect(failure.code, GrammarDiagnosticCode.unknownRingKey);
      expect(failure.message, contains('"fruit-A"'));
      expect(failure.message, contains('dataLabelsByRing'));
      // The real ring keys are named, so the fix is readable off the message.
      expect(failure.message, contains('"A"'));
      expect(failure.message, contains('"B"'));
    });

    test('every dataLabelsByRing key naming a real ring lowers clean', () {
      // The FULL map: every ring the `fruits` fixture produces is named, so the
      // guard has the largest legitimate surface to over-fire on. Pinning it on
      // a populated map is the point — an empty map is vacuously unknown-free
      // and would pass even a guard rewritten to reject valid keys.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'fruit',
              dataLabelsByRing: <String, PieDataLabelConfig>{
                'A': hiddenLabels,
                'B': insideLabels,
              },
            ),
          ],
        )).lower(),
        returnsNormally,
      );

      // And an empty override map stays a no-op rather than a refusal.
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'fruit',
              dataLabelsByRing: <String, PieDataLabelConfig>{},
            ),
          ],
        )).lower(),
        returnsNormally,
      );
    });

    test('concentric plus center raises conflictingConcentricCenter', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'rings',
              center: DonutCenterContent(label: 'Total'),
              concentric: customConcentric,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.conflictingConcentricCenter),
      );
    });

    test('concentric plus center is refused before the empty-data guard', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'rings',
              center: DonutCenterContent(label: 'Total'),
              concentric: customConcentric,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.conflictingConcentricCenter),
      );
    });

    test('an unset concentric keeps the center shorthand behavior', () {
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

    test(
      'a lowered polar equals the hand-built PolarColumnChartSeries.fromMap',
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
      },
    );
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
          PolarMark<Fruit>(id: 'fruit', category: fruitName, value: fruitCount),
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

    test('a half-specified LOWER bound fires before the empty-data guard', () {
      // Which of the two interval accessors is null is decidable from the
      // spec's SHAPE — no row is read to know it. BravenPlot swallows exactly
      // emptyData, so a spec that reports emptyData reads as WELL FORMED; a
      // half-specified interval must therefore never hide behind a momentarily
      // empty dataset and only surface once real rows arrive.
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'fruit',
              category: fruitName,
              value: fruitCount,
              intervalLow: fruitLow,
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.incompletePolarInterval);
      expect(thrown.message, contains('fruit'));
    });

    test('a half-specified UPPER bound fires before the empty-data guard', () {
      // The mirror of the pair: the guard is the `!=` between the two
      // accessors' nullity, so BOTH halves must outrank the empty-data guard.
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'fruit',
              category: fruitName,
              value: fruitCount,
              intervalHigh: fruitHigh,
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.incompletePolarInterval);
      expect(thrown.message, contains('fruit'));
    });

    test('the interval diagnostic names the SECOND mark of a polar pair', () {
      // The shape check runs over EVERY polar mark, not just the first, and it
      // must keep naming the offender.
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(
              id: 'b',
              category: fruitName,
              value: fruitMass,
              intervalHigh: fruitHigh,
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.incompletePolarInterval);
      expect(thrown.message, contains('b'));
    });

    test('a complete interval still lowers against empty data to emptyData', () {
      // The positive control for the hoisted guard: a WELL-FORMED interval must
      // still reach the empty-data guard, or BravenPlot loses its empty state.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'fruit',
              category: fruitName,
              value: fruitCount,
              intervalLow: fruitLow,
              intervalHigh: fruitHigh,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
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

    test(
      'two polar marks lower to two PolarColumnChartSeries with the config',
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
        expect(
          lowered.series.every((s) => s is PolarColumnChartSeries),
          isTrue,
        );
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
      },
    );

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

    test(
      'polarConfig on a concentric donut raises polarConfigOnNonPolarSpec',
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
      },
    );

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
    test(
      'polarConfig on a Cartesian spec raises polarConfigOnNonPolarSpec',
      () {
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
      },
    );

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
            PolarMark<Fruit>(
              id: 'only',
              category: fruitName,
              value: fruitCount,
            ),
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
            PolarMark<Fruit>(
              id: 'only',
              category: fruitName,
              value: fruitCount,
            ),
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

    test(
      'polar marks whose categories diverge raise invalidPolarComposition',
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
      },
    );

    test('polar marks with different presets raise invalidPolarComposition', () {
      // `PolarMark.preset` is what the builder's `rose:` flag sets, so
      // `.geomPolar(rose: true).geomPolar()` became expressible the moment the
      // advanced per-series fields landed. A rose series divides the circle
      // into equal angles and encodes value as AREA; a standard series encodes
      // it as radius. One pane cannot draw both, so the composition contract
      // refuses the pair — and lowering must reach that verdict by name rather
      // than let a chain lower clean and throw a raw ArgumentError at mount.
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(
              id: 'b',
              category: fruitName,
              value: fruitMass,
              preset: PolarColumnPreset.rose,
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.invalidPolarComposition);
      expect(thrown.message, contains('preset'));
      expect(thrown.message, contains('b'));
    });

    test('the preset diagnostic fires before the empty-data guard', () {
      // `PolarMark.preset` is a mark FIELD, so the clash is decidable from the
      // spec's SHAPE. It must outrank the empty-data guard for the same reason
      // the unit clash does: BravenPlot swallows emptyData, so a spec that
      // reports emptyData reads as well formed.
      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(
              id: 'b',
              category: fruitName,
              value: fruitMass,
              preset: PolarColumnPreset.rose,
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.code, GrammarDiagnosticCode.invalidPolarComposition);
      expect(thrown.message, contains('preset'));
      expect(thrown.message, contains('b'));
    });

    test('the preset diagnostic reads identically with and without rows', () {
      // One authoring error, one wording. Hoisting the check above the
      // empty-data guard must not fork the message into a "shape" variant and
      // a "materialized" variant that drift apart.
      String messageFor(List<Fruit> data) {
        try {
          (PlotSpec<Fruit>(
            data: data,
            marks: const <Mark<Fruit>>[
              PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
              PolarMark<Fruit>(
                id: 'b',
                category: fruitName,
                value: fruitMass,
                preset: PolarColumnPreset.rose,
              ),
            ],
          )).lower();
        } on GrammarSpecException catch (error) {
          return error.message;
        }
        return 'did not throw';
      }

      expect(messageFor(<Fruit>[]), messageFor(fruits));
      expect(messageFor(<Fruit>[]), isNot('did not throw'));
    });

    test('the hoisted preset message matches the composition authority', () {
      // The shape check RESTATES a rule owned by `PolarColumnComposition`
      // (which cannot run without lowered series, and so cannot run above the
      // empty-data guard). This pins the restatement to the authority so the
      // two cannot drift into two different sentences for one mistake.
      final rose = PolarColumnChartSeries.rose(
        id: 'b',
        values: const {'Apple': 30},
      );
      final standard = PolarColumnChartSeries.fromMap(
        id: 'a',
        values: const {'Apple': 30},
      );
      String? authorityDetail;
      try {
        PolarColumnComposition.validate(<PolarColumnChartSeries>[
          standard,
          rose,
        ]);
      } on ArgumentError catch (error) {
        authorityDetail = error.invalidValue == null
            ? '${error.message}.'
            : '${error.message} ("${error.invalidValue}").';
      }
      expect(authorityDetail, isNotNull);

      GrammarSpecException? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(id: 'a', category: fruitName, value: fruitCount),
            PolarMark<Fruit>(
              id: 'b',
              category: fruitName,
              value: fruitMass,
              preset: PolarColumnPreset.rose,
            ),
          ],
        )).lower();
      } on GrammarSpecException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(
        thrown!.message,
        GrammarSpecException.invalidPolarComposition(authorityDetail!).message,
      );
    });

    test('polar marks sharing a preset still reach the empty-data guard', () {
      // The positive control for the hoisted preset check: agreement must not
      // be mistaken for a clash, or BravenPlot loses its empty state.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'a',
              category: fruitName,
              value: fruitCount,
              preset: PolarColumnPreset.rose,
            ),
            PolarMark<Fruit>(
              id: 'b',
              category: fruitName,
              value: fruitMass,
              preset: PolarColumnPreset.rose,
            ),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });

    test('polar marks sharing the rose preset lower cleanly', () {
      // The other half of the pair: the diagnostic must fire on DIVERGENCE, not
      // on the mere presence of a non-default preset.
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            id: 'a',
            category: fruitName,
            value: fruitCount,
            preset: PolarColumnPreset.rose,
          ),
          PolarMark<Fruit>(
            id: 'b',
            category: fruitName,
            value: fruitMass,
            preset: PolarColumnPreset.rose,
          ),
        ],
      )).lower();
      expect(lowered.series, hasLength(2));
      expect(
        lowered.series.cast<PolarColumnChartSeries>().every(
          (series) => series.preset == PolarColumnPreset.rose,
        ),
        isTrue,
      );
    });

    // `.polarConfig(...)` is a plot-level verb, and every rule
    // `PolarChartConfig.validate()` enforces — pane geometry, radial-axis
    // bounds, the grouped sub-band padding, each threshold's finiteness and
    // dash-pair parity, and the stacked zero-baseline — is decidable from the
    // CONFIG alone, with no rows in sight. The widget runs that same validator
    // at mount, so without a hoist a chain lowers CLEAN over an empty dataset
    // and then throws a raw ArgumentError once real rows arrive: exactly the
    // failure the concentric half was hoisted to prevent.
    test(
      'an invalid polar pane radius is refused above the empty-data guard',
      () {
        expect(
          () => (const PlotSpec<Fruit>(
            data: <Fruit>[],
            marks: <Mark<Fruit>>[
              PolarMark<Fruit>(
                id: 'only',
                category: fruitName,
                value: fruitCount,
              ),
            ],
            polar: PolarChartConfig(
              pane: PolarPaneConfig(innerRadiusFactor: 2),
            ),
          )).lower(),
          throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
        );
      },
    );

    test('a threshold with an odd dash pattern is refused above the empty-data '
        'guard', () {
      // A dash pattern is painted-gap PAIRS, so an odd length cannot be drawn
      // whatever the data says.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'only',
              category: fruitName,
              value: fruitCount,
            ),
          ],
          polar: PolarChartConfig(
            thresholds: <PolarThreshold>[
              PolarThreshold(value: 20, dashPattern: <double>[6, 4, 2]),
            ],
          ),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
      );
    });

    test('an out-of-range groupInnerPadding is refused above the empty-data '
        'guard', () {
      // The mode stays layered, so the "grouped needs two series" check cannot
      // be what fires: this pins the CONFIG's own contract.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'only',
              category: fruitName,
              value: fruitCount,
            ),
          ],
          polar: PolarChartConfig(
            composition: PolarColumnCompositionConfig(groupInnerPadding: 1.5),
          ),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.invalidPolarComposition),
      );
    });

    test('the hoisted config diagnostic is a named grammar failure, not a raw '
        "ArgumentError, and reads in the authority's own words — including "
        'the field that failed', () {
      // The grammar delegates to `PolarChartConfig.validate()` — the same
      // validator BravenChartPlus runs at mount — and only RENAMES its failure,
      // so the two cannot describe one mistake in two different sentences.
      //
      // The renaming must not LOSE anything either. The raw ArgumentError this
      // replaces carries a `name` — the offending field — and a
      // PolarChartConfig range-checks eight of them, so "Value must be in
      // [0, 1)" on its own is strictly less actionable than the error the
      // diagnostic hides.
      const invalidConfig = PolarChartConfig(
        pane: PolarPaneConfig(innerRadiusFactor: 2),
      );
      String? authorityName;
      String? authorityDetail;
      try {
        invalidConfig.validate();
      } on ArgumentError catch (error) {
        authorityName = error.name;
        authorityDetail = error.invalidValue == null
            ? '${error.name}: ${error.message}.'
            : '${error.name}: ${error.message} ("${error.invalidValue}").';
      }
      expect(authorityDetail, isNotNull);
      expect(
        authorityName,
        'pane.innerRadiusFactor',
        reason:
            'the authority stopped naming the failing field, so the detail '
            'below can no longer carry it either',
      );

      Object? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'only',
              category: fruitName,
              value: fruitCount,
            ),
          ],
          polar: invalidConfig,
        )).lower();
      } catch (error) {
        thrown = error;
      }
      expect(thrown, isA<GrammarSpecException>());
      expect(thrown, isNot(isA<ArgumentError>()));
      final failure = thrown! as GrammarSpecException;
      expect(failure.code, GrammarDiagnosticCode.invalidPolarComposition);
      expect(
        failure.message,
        GrammarSpecException.invalidPolarComposition(authorityDetail!).message,
      );
      // Asserted separately from the parity comparison above, which would pass
      // just as happily if both sides dropped the field name together.
      expect(
        failure.message,
        contains('pane.innerRadiusFactor'),
        reason:
            'the diagnostic must say WHICH field the config got wrong; the raw '
            'ArgumentError it replaces does',
      );
    });

    test('the hoisted concentric diagnostic names its failing field too', () {
      // The concentric guard is the twin of the polar one and renames the same
      // shape of authority failure, so it carries the same obligation: a ring
      // gap and two radii are all range-checked, and the diagnostic that
      // replaces the raw error must not be the one that stops saying which.
      Object? thrown;
      try {
        (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              category: fruitName,
              value: fruitCount,
              ring: fruitBasket,
              id: 'rings',
              concentric: ConcentricDonutConfig(innerRadiusFactor: 2),
            ),
          ],
        )).lower();
      } catch (error) {
        thrown = error;
      }
      expect(thrown, isA<GrammarSpecException>());
      final failure = thrown! as GrammarSpecException;
      expect(failure.code, GrammarDiagnosticCode.invalidConcentricComposition);
      expect(
        failure.message,
        contains('innerRadiusFactor'),
        reason:
            'the diagnostic must say WHICH field the concentric config got '
            'wrong; the raw ArgumentError it replaces does',
      );
    });

    test('a valid polar config still lowers and is carried through', () {
      // The positive control for the hoisted config check: a well-formed
      // config must not be mistaken for a malformed one.
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(id: 'only', category: fruitName, value: fruitCount),
        ],
        polar: PolarChartConfig(
          pane: PolarPaneConfig(innerRadiusFactor: 0.2),
          composition: PolarColumnCompositionConfig(groupInnerPadding: 0.25),
          thresholds: <PolarThreshold>[
            PolarThreshold(value: 20, dashPattern: <double>[6, 4]),
          ],
        ),
      )).lower();
      expect(lowered.series, hasLength(1));
      expect(lowered.polarChartConfig, isNotNull);
      expect(lowered.polarChartConfig!.pane.innerRadiusFactor, 0.2);
      expect(lowered.polarChartConfig!.composition.groupInnerPadding, 0.25);
      expect(lowered.polarChartConfig!.thresholds, hasLength(1));
    });

    test('a valid polar config still reaches the empty-data guard', () {
      // The other half of the positive control: the hoist must not swallow
      // BravenPlot's empty state for a config that is perfectly well formed.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'only',
              category: fruitName,
              value: fruitCount,
            ),
          ],
          polar: PolarChartConfig(
            pane: PolarPaneConfig(innerRadiusFactor: 0.2),
            thresholds: <PolarThreshold>[PolarThreshold(value: 20)],
          ),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });

    test(
      'the composition diagnostic names its code and the offending mark',
      () {
        final invalid = GrammarSpecException.invalidPolarComposition(
          'The mark "b" reads in "bpm".',
        );
        expect(invalid.code, GrammarDiagnosticCode.invalidPolarComposition);
        expect(invalid.toString(), contains('invalidPolarComposition'));
        expect(invalid.message, contains('bpm'));
      },
    );
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

    test(
      'a polar with duplicate categories raises duplicateRadialCategory',
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
      },
    );

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
    test(
      'the same categories across DIFFERENT rings lower without throwing',
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
      },
    );

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
