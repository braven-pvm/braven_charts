// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/summary/value_summary_reducer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a one-value snapshot tagged by [seriesId] so tests can assert which
/// source a reduction resolved.
CartesianTrackingSnapshot _snapshot(
  String seriesId, {
  CartesianTrackingOrigin origin = CartesianTrackingOrigin.pointer,
}) => CartesianTrackingSnapshot(
  dataX: 1,
  plotX: 10,
  values: [
    CartesianTrackedSeriesValue(
      seriesId: seriesId,
      seriesName: seriesId,
      seriesColor: const Color(0xFF2196F3),
      x: 1,
      y: 2,
      dataPointIndex: 0,
      isInterpolated: false,
      formattedX: '1',
      formattedY: '2',
    ),
  ],
  origin: origin,
  primaryPoint: ChartPointRef(seriesId: seriesId, pointIndex: 0),
);

/// Recording providers so tests can assert exactly which sources were
/// consulted and prove lazy evaluation of the fallback chain.
class _Providers {
  _Providers({
    Map<ChartPointRef, CartesianTrackingSnapshot>? byRef,
    this.latest,
    this.first,
  }) : byRef = byRef ?? const {};

  final Map<ChartPointRef, CartesianTrackingSnapshot> byRef;
  final CartesianTrackingSnapshot? latest;
  final CartesianTrackingSnapshot? first;

  final List<ChartPointRef> resolveCalls = [];
  int latestCalls = 0;
  int firstCalls = 0;

  CartesianTrackingSnapshot? resolvePoint(ChartPointRef ref) {
    resolveCalls.add(ref);
    return byRef[ref];
  }

  CartesianTrackingSnapshot? latestVisible() {
    latestCalls++;
    return latest;
  }

  CartesianTrackingSnapshot? firstVisible() {
    firstCalls++;
    return first;
  }
}

ValueSummaryReduction _reduce(
  CartesianValueSummaryValuePolicy policy, {
  CartesianTrackingSnapshot? tracking,
  ChartPointRef? pinned,
  ChartPointRef? selection,
  required _Providers providers,
}) => ValueSummaryReducer.reduce(
  policy: policy,
  tracking: tracking,
  pinned: pinned,
  selection: selection,
  resolvePoint: providers.resolvePoint,
  latestVisible: providers.latestVisible,
  firstVisible: providers.firstVisible,
);

void main() {
  const pinRef = ChartPointRef(seriesId: 'pinned-series', pointIndex: 3);
  const selectionRef = ChartPointRef(
    seriesId: 'selected-series',
    pointIndex: 5,
  );

  group('ValueSummaryReducer explicitOnly', () {
    test('no pin hides the summary without consulting any fallback', () {
      final providers = _Providers(latest: _snapshot('latest'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.explicitOnly,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(reduction.clearedInvalidPin, isFalse);
      expect(providers.resolveCalls, isEmpty);
      expect(providers.latestCalls, 0);
      expect(providers.firstCalls, 0);
    });

    test('valid pin resolves the pinned snapshot', () {
      final pinSnapshot = _snapshot(
        'pinned-series',
        origin: CartesianTrackingOrigin.pinned,
      );
      final providers = _Providers(
        byRef: {pinRef: pinSnapshot},
        latest: _snapshot('latest'),
      );
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.explicitOnly,
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(pinSnapshot));
      expect(reduction.clearedInvalidPin, isFalse);
      expect(providers.latestCalls, 0);
    });

    test('invalid pin hides the summary and reports the cleared pin', () {
      final providers = _Providers(latest: _snapshot('latest'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.explicitOnly,
        tracking: _snapshot('tracking'),
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(reduction.clearedInvalidPin, isTrue);
      expect(providers.resolveCalls, [pinRef]);
      expect(providers.latestCalls, 0);
    });

    test('active tracking is ignored', () {
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.explicitOnly,
        tracking: _snapshot('tracking'),
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(reduction.clearedInvalidPin, isFalse);
    });

    test('selection is ignored', () {
      final providers = _Providers(
        byRef: {selectionRef: _snapshot('selected-series')},
      );
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.explicitOnly,
        selection: selectionRef,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(providers.resolveCalls, isEmpty);
    });
  });

  group('ValueSummaryReducer pinnedThenTrackingThenLatest', () {
    test('valid pin wins over active tracking', () {
      final pinSnapshot = _snapshot(
        'pinned-series',
        origin: CartesianTrackingOrigin.pinned,
      );
      final providers = _Providers(byRef: {pinRef: pinSnapshot});
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        tracking: _snapshot('tracking'),
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(pinSnapshot));
      expect(reduction.clearedInvalidPin, isFalse);
    });

    test('invalid pin falls through to tracking and reports the clear', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(latest: _snapshot('latest'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        tracking: trackingSnapshot,
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(reduction.clearedInvalidPin, isTrue);
      expect(providers.latestCalls, 0);
    });

    test('invalid pin without tracking falls through to latest', () {
      final latestSnapshot = _snapshot(
        'latest',
        origin: CartesianTrackingOrigin.fallback,
      );
      final providers = _Providers(latest: latestSnapshot);
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(latestSnapshot));
      expect(reduction.clearedInvalidPin, isTrue);
    });

    test('no pin with active tracking resolves tracking', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(latest: _snapshot('latest'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        tracking: trackingSnapshot,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(providers.latestCalls, 0);
    });

    test(
      'no pin and no tracking falls back to latest without a pin report',
      () {
        final latestSnapshot = _snapshot(
          'latest',
          origin: CartesianTrackingOrigin.fallback,
        );
        final providers = _Providers(latest: latestSnapshot);
        final reduction = _reduce(
          CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
          providers: providers,
        );
        expect(reduction.snapshot, same(latestSnapshot));
        expect(reduction.clearedInvalidPin, isFalse);
      },
    );

    test('selection is not part of this policy chain', () {
      final latestSnapshot = _snapshot('latest');
      final providers = _Providers(
        byRef: {selectionRef: _snapshot('selected-series')},
        latest: latestSnapshot,
      );
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        selection: selectionRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(latestSnapshot));
      expect(providers.resolveCalls, isEmpty);
    });

    test('hides the summary when every source is empty', () {
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(reduction.clearedInvalidPin, isFalse);
      expect(providers.latestCalls, 1);
    });
  });

  group('ValueSummaryReducer selectionThenTrackingThenLatest', () {
    test('valid selection wins over active tracking', () {
      final selectionSnapshot = _snapshot('selected-series');
      final providers = _Providers(byRef: {selectionRef: selectionSnapshot});
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        tracking: _snapshot('tracking'),
        selection: selectionRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(selectionSnapshot));
      expect(reduction.clearedInvalidPin, isFalse);
    });

    test('unresolvable selection falls through without a pin report', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        tracking: trackingSnapshot,
        selection: selectionRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(reduction.clearedInvalidPin, isFalse);
      expect(providers.resolveCalls, [selectionRef]);
    });

    test('pin is not part of this policy chain', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(byRef: {pinRef: _snapshot('pinned-series')});
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        tracking: trackingSnapshot,
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(providers.resolveCalls, isEmpty);
      expect(reduction.clearedInvalidPin, isFalse);
    });

    test('no selection with active tracking resolves tracking', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(latest: _snapshot('latest'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        tracking: trackingSnapshot,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(providers.latestCalls, 0);
    });

    test('no selection and no tracking falls back to latest', () {
      final latestSnapshot = _snapshot('latest');
      final providers = _Providers(latest: latestSnapshot);
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        providers: providers,
      );
      expect(reduction.snapshot, same(latestSnapshot));
    });

    test('hides the summary when every source is empty', () {
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
    });
  });

  group('ValueSummaryReducer trackingThenLatest', () {
    test('active tracking wins and the fallback is never consulted', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(latest: _snapshot('latest'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenLatest,
        tracking: trackingSnapshot,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(providers.latestCalls, 0);
      expect(providers.firstCalls, 0);
    });

    test('no tracking falls back to the latest visible datum', () {
      final latestSnapshot = _snapshot(
        'latest',
        origin: CartesianTrackingOrigin.fallback,
      );
      final providers = _Providers(latest: latestSnapshot);
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenLatest,
        providers: providers,
      );
      expect(reduction.snapshot, same(latestSnapshot));
      expect(providers.firstCalls, 0);
    });

    test('pin and selection are both ignored', () {
      final latestSnapshot = _snapshot('latest');
      final providers = _Providers(
        byRef: {
          pinRef: _snapshot('pinned-series'),
          selectionRef: _snapshot('selected-series'),
        },
        latest: latestSnapshot,
      );
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenLatest,
        pinned: pinRef,
        selection: selectionRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(latestSnapshot));
      expect(providers.resolveCalls, isEmpty);
      expect(reduction.clearedInvalidPin, isFalse);
    });

    test('hides the summary when the fallback has nothing visible', () {
      // All series hidden (or no data): the latest-visible provider yields
      // null and the summary hides rather than retaining stale values.
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenLatest,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(providers.latestCalls, 1);
    });
  });

  group('ValueSummaryReducer trackingThenFirst', () {
    test('active tracking wins', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(first: _snapshot('first'));
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenFirst,
        tracking: trackingSnapshot,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(providers.firstCalls, 0);
    });

    test('no tracking falls back to first visible, never latest', () {
      final firstSnapshot = _snapshot(
        'first',
        origin: CartesianTrackingOrigin.fallback,
      );
      final providers = _Providers(
        latest: _snapshot('latest'),
        first: firstSnapshot,
      );
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenFirst,
        providers: providers,
      );
      expect(reduction.snapshot, same(firstSnapshot));
      expect(providers.latestCalls, 0);
      expect(providers.firstCalls, 1);
    });

    test('pin is ignored', () {
      final firstSnapshot = _snapshot('first');
      final providers = _Providers(
        byRef: {pinRef: _snapshot('pinned-series')},
        first: firstSnapshot,
      );
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenFirst,
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(firstSnapshot));
      expect(providers.resolveCalls, isEmpty);
    });

    test('hides the summary when the fallback has nothing visible', () {
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenFirst,
        providers: providers,
      );
      expect(reduction.snapshot, isNull);
      expect(providers.firstCalls, 1);
    });
  });

  group('ValueSummaryReduction shape', () {
    test('reduction is deterministic for identical inputs', () {
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers(latest: _snapshot('latest'));
      final one = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenLatest,
        tracking: trackingSnapshot,
        providers: providers,
      );
      final two = _reduce(
        CartesianValueSummaryValuePolicy.trackingThenLatest,
        tracking: trackingSnapshot,
        providers: providers,
      );
      expect(one.snapshot, same(two.snapshot));
      expect(one.clearedInvalidPin, two.clearedInvalidPin);
    });

    test('clearedInvalidPin is reported alongside the resolved snapshot', () {
      // Task 8 consumes this record: the snapshot feeds the adapter while
      // clearedInvalidPin instructs the pipeline to clear the stale pin.
      final trackingSnapshot = _snapshot('tracking');
      final providers = _Providers();
      final reduction = _reduce(
        CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        tracking: trackingSnapshot,
        pinned: pinRef,
        providers: providers,
      );
      expect(reduction.snapshot, same(trackingSnapshot));
      expect(reduction.clearedInvalidPin, isTrue);
    });
  });
}
