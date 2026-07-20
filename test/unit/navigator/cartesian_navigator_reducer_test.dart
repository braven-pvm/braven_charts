import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/navigator/cartesian_navigator_reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fullDomain = ChartXViewport(min: 0, max: 100);

  group('CartesianNavigatorSnapPolicy', () {
    test('rejects invalid intervals', () {
      expect(
        () => CartesianNavigatorSnapPolicy.interval(0),
        throwsArgumentError,
      );
      expect(
        () => CartesianNavigatorSnapPolicy.interval(double.nan),
        throwsArgumentError,
      );
    });

    test('copies and validates ordered values', () {
      final source = <double>[1, 3, 8];
      final policy = CartesianNavigatorSnapPolicy.values(source);
      source[1] = 4;

      expect(policy.values, <double>[1, 3, 8]);
      expect(
        () => CartesianNavigatorSnapPolicy.values(const <double>[1, 1]),
        throwsArgumentError,
      );
      expect(
        () =>
            CartesianNavigatorSnapPolicy.values(const <double>[1, double.nan]),
        throwsArgumentError,
      );
    });
  });

  group('CartesianNavigatorReducer initialization', () {
    test('prefers existing group viewport over initial viewport', () {
      final reducer = CartesianNavigatorReducer(fullDomain: fullDomain);

      expect(
        reducer.resolveInitialViewport(
          groupViewport: const ChartXViewport(min: 20, max: 40),
          initialViewport: const ChartXViewport(min: 60, max: 80),
        ),
        const ChartXViewport(min: 20, max: 40),
      );
    });

    test('uses initial viewport before falling back to full domain', () {
      final reducer = CartesianNavigatorReducer(fullDomain: fullDomain);

      expect(
        reducer.resolveInitialViewport(
          initialViewport: const ChartXViewport(min: 60, max: 80),
        ),
        const ChartXViewport(min: 60, max: 80),
      );
      expect(reducer.resolveInitialViewport(), fullDomain);
    });

    test('clamps replacement domains while preserving span', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: const ChartXViewport(min: 0, max: 80),
      );

      expect(
        reducer.reconcile(const ChartXViewport(min: 70, max: 90)),
        const ChartXViewport(min: 60, max: 80),
      );
    });

    test('rejects a minimum span larger than the domain', () {
      expect(
        () => CartesianNavigatorReducer(
          fullDomain: fullDomain,
          behavior: const CartesianNavigatorBehavior(minimumSpan: 101),
        ),
        throwsArgumentError,
      );
    });
  });

  group('CartesianNavigatorReducer movement', () {
    test('body pan preserves span at both boundaries', () {
      final reducer = CartesianNavigatorReducer(fullDomain: fullDomain);
      const viewport = ChartXViewport(min: 20, max: 40);

      expect(
        reducer.reduce(
          viewport: viewport,
          target: CartesianNavigatorTarget.window,
          delta: -50,
        ),
        const ChartXViewport(min: 0, max: 20),
      );
      expect(
        reducer.reduce(
          viewport: viewport,
          target: CartesianNavigatorTarget.window,
          delta: 100,
        ),
        const ChartXViewport(min: 80, max: 100),
      );
    });

    test('reverse movement is stable after hitting a boundary', () {
      final reducer = CartesianNavigatorReducer(fullDomain: fullDomain);
      final atEnd = reducer.reduce(
        viewport: const ChartXViewport(min: 70, max: 90),
        target: CartesianNavigatorTarget.window,
        delta: 40,
      );

      expect(
        reducer.reduce(
          viewport: atEnd,
          target: CartesianNavigatorTarget.window,
          delta: -5,
        ),
        const ChartXViewport(min: 75, max: 95),
      );
    });

    test('edges resize independently and respect minimum span', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: fullDomain,
        behavior: const CartesianNavigatorBehavior(minimumSpan: 10),
      );
      const viewport = ChartXViewport(min: 20, max: 40);

      expect(
        reducer.reduce(
          viewport: viewport,
          target: CartesianNavigatorTarget.startHandle,
          delta: 50,
        ),
        const ChartXViewport(min: 30, max: 40),
      );
      expect(
        reducer.reduce(
          viewport: viewport,
          target: CartesianNavigatorTarget.endHandle,
          delta: -50,
        ),
        const ChartXViewport(min: 20, max: 30),
      );
    });

    test('interval snapping is anchored to the full-domain minimum', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: const ChartXViewport(min: 5, max: 20),
        snapPolicy: CartesianNavigatorSnapPolicy.interval(2),
      );

      expect(
        reducer.reduce(
          viewport: const ChartXViewport(min: 7, max: 11),
          target: CartesianNavigatorTarget.startHandle,
          delta: 1.2,
        ),
        const ChartXViewport(min: 9, max: 11),
      );
    });

    test('ordered-value pan snaps one edge and preserves window span', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: fullDomain,
        snapPolicy: CartesianNavigatorSnapPolicy.values(const <double>[
          0,
          7,
          18,
          42,
          80,
        ]),
      );

      expect(
        reducer.reduce(
          viewport: const ChartXViewport(min: 7, max: 27),
          target: CartesianNavigatorTarget.window,
          delta: 13,
        ),
        const ChartXViewport(min: 18, max: 38),
      );
    });

    test('single-value snap sets still honour minimum span', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: fullDomain,
        behavior: const CartesianNavigatorBehavior(minimumSpan: 10),
        snapPolicy: CartesianNavigatorSnapPolicy.values(const <double>[30]),
      );

      expect(
        reducer.reduce(
          viewport: const ChartXViewport(min: 20, max: 40),
          target: CartesianNavigatorTarget.startHandle,
          delta: 50,
        ),
        const ChartXViewport(min: 30, max: 40),
      );
    });

    test('interval snapping avoids accumulating floating-point drift', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: const ChartXViewport(min: 0, max: 1),
        snapPolicy: CartesianNavigatorSnapPolicy.interval(0.1),
      );
      final result = reducer.reduce(
        viewport: const ChartXViewport(min: 0.2, max: 0.5),
        target: CartesianNavigatorTarget.window,
        delta: 0.099999999999,
      );

      expect(result.min, closeTo(0.3, 1e-12));
      expect(result.max, closeTo(0.6, 1e-12));
    });

    test('disabled movement leaves the viewport unchanged', () {
      final reducer = CartesianNavigatorReducer(
        fullDomain: fullDomain,
        behavior: const CartesianNavigatorBehavior(
          allowPan: false,
          allowResize: false,
        ),
      );
      const viewport = ChartXViewport(min: 20, max: 40);

      expect(
        reducer.reduce(
          viewport: viewport,
          target: CartesianNavigatorTarget.window,
          delta: 20,
        ),
        viewport,
      );
      expect(
        reducer.reduce(
          viewport: viewport,
          target: CartesianNavigatorTarget.endHandle,
          delta: 20,
        ),
        viewport,
      );
    });
  });
}
