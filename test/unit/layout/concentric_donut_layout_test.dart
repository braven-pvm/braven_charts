import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/layout/concentric_donut_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DonutChartSeries ring(
    String id, {
    double sweep = 360,
    bool clockwise = true,
  }) => DonutChartSeries.fromMap(
    id: id,
    values: const {'A': 2, 'B': 1},
    donutStyle: DonutChartStyle(sweepAngleDegrees: sweep, clockwise: clockwise),
  );

  group('ConcentricDonutLayoutCalculator', () {
    test('allocates equal rings from outside to inside by default', () {
      final layout = ConcentricDonutLayoutCalculator.calculate(
        series: [ring('current'), ring('previous')],
        config: const ConcentricDonutConfig(
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 1,
          ringGap: 4,
        ),
        availableRadius: 100,
      );

      expect(layout.innerRadius, 20);
      expect(layout.outerRadius, 100);
      expect(layout.rings, hasLength(2));
      expect(layout.rings[0].seriesId, 'current');
      expect(layout.rings[0].innerRadius, 62);
      expect(layout.rings[0].outerRadius, 100);
      expect(layout.rings[1].seriesId, 'previous');
      expect(layout.rings[1].innerRadius, 20);
      expect(layout.rings[1].outerRadius, 58);
    });

    test('allocates list order from inside to outside when requested', () {
      final layout = ConcentricDonutLayoutCalculator.calculate(
        series: [ring('baseline'), ring('actual')],
        config: const ConcentricDonutConfig(
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 1,
          ringGap: 4,
          order: ConcentricRingOrder.innerToOuter,
        ),
        availableRadius: 100,
      );

      expect(layout.rings[0].seriesId, 'baseline');
      expect(layout.rings[0].innerRadius, 20);
      expect(layout.rings[0].outerRadius, 58);
      expect(layout.rings[1].seriesId, 'actual');
      expect(layout.rings[1].innerRadius, 62);
      expect(layout.rings[1].outerRadius, 100);
    });

    test('uses weights for radial thickness without changing ring order', () {
      final layout = ConcentricDonutLayoutCalculator.calculate(
        series: [ring('primary'), ring('context')],
        config: const ConcentricDonutConfig(
          innerRadiusFactor: 0.1,
          outerRadiusFactor: 0.9,
          ringGap: 5,
          ringWeights: {'primary': 3, 'context': 1},
        ),
        availableRadius: 200,
      );

      expect(layout.innerRadius, 20);
      expect(layout.outerRadius, 180);
      expect(layout.rings[0].thickness, closeTo(116.25, 1e-9));
      expect(layout.rings[1].thickness, closeTo(38.75, 1e-9));
      expect(layout.rings[0].weight, 3);
      expect(layout.rings[1].weight, 1);
    });

    test(
      'fits the requested gap only when a responsive pane is constrained',
      () {
        final rings = [ring('a'), ring('b'), ring('c')];
        const config = ConcentricDonutConfig(
          innerRadiusFactor: 0.4,
          outerRadiusFactor: 0.5,
          ringGap: 6,
        );

        final compact = ConcentricDonutLayoutCalculator.calculate(
          series: rings,
          config: config,
          availableRadius: 100,
          fitRingGap: true,
        );

        expect(compact.effectiveRingGap, closeTo(2.5, 1e-9));
        expect(compact.rings.every((ring) => ring.thickness >= 1), isTrue);
        expect(compact.rings.every((ring) => ring.thickness.isFinite), isTrue);

        final roomy = ConcentricDonutLayoutCalculator.calculate(
          series: rings,
          config: config,
          availableRadius: 300,
          fitRingGap: true,
        );
        expect(roomy.effectiveRingGap, config.ringGap);
      },
    );

    test('rejects a weight whose key is not a real series ID', () {
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('current'), ring('previous')],
          config: const ConcentricDonutConfig(ringWeights: {'missing': 2}),
          availableRadius: 100,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('missing'),
          ),
        ),
      );
    });

    test('rejects duplicate series IDs', () {
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('duplicate'), ring('duplicate')],
          config: const ConcentricDonutConfig(),
          availableRadius: 100,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('unique'),
          ),
        ),
      );
    });

    test('rejects invalid pane factors and weights', () {
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('a'), ring('b')],
          config: const ConcentricDonutConfig(
            innerRadiusFactor: 0.8,
            outerRadiusFactor: 0.5,
          ),
          availableRadius: 100,
        ),
        throwsArgumentError,
      );
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('a'), ring('b')],
          config: const ConcentricDonutConfig(ringWeights: {'a': 0}),
          availableRadius: 100,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a pane too small to leave positive ring thickness', () {
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('a'), ring('b'), ring('c')],
          config: const ConcentricDonutConfig(
            innerRadiusFactor: 0.4,
            outerRadiusFactor: 0.5,
            ringGap: 6,
          ),
          availableRadius: 100,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('positive thickness'),
          ),
        ),
      );
    });

    test('rejects incompatible ring sweep or direction', () {
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('a'), ring('b', sweep: 270)],
          config: const ConcentricDonutConfig(),
          availableRadius: 100,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('sweep'),
          ),
        ),
      );
      expect(
        () => ConcentricDonutLayoutCalculator.calculate(
          series: [ring('a'), ring('b', clockwise: false)],
          config: const ConcentricDonutConfig(),
          availableRadius: 100,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('direction'),
          ),
        ),
      );
    });
  });
}
