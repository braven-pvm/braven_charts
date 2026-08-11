import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/modules/series_callout_layout.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveSeriesCalloutLaneBoundary', () {
    test('follows the furthest live anchor on the right', () {
      final boundary = resolveSeriesCalloutLaneBoundary(
        placement: SeriesCalloutLanePlacement.anchorFrontier,
        side: SeriesCalloutSide.right,
        anchorXs: const [40, 44, 42],
        plotWidth: 500,
        inset: 8,
        maximumBoxWidth: 100,
      );

      expect(boundary, 52);
    });

    test('clamps a moving right lane inside the plot', () {
      final boundary = resolveSeriesCalloutLaneBoundary(
        placement: SeriesCalloutLanePlacement.anchorFrontier,
        side: SeriesCalloutSide.right,
        anchorXs: const [470],
        plotWidth: 500,
        inset: 8,
        maximumBoxWidth: 100,
      );

      expect(boundary, 392);
    });

    test('preserves the original plot-edge lane by default', () {
      final boundary = resolveSeriesCalloutLaneBoundary(
        placement: SeriesCalloutLanePlacement.plotEdge,
        side: SeriesCalloutSide.left,
        anchorXs: const [240],
        plotWidth: 500,
        inset: 8,
        maximumBoxWidth: 100,
      );

      expect(boundary, 108);
    });
  });

  group('layoutSeriesCallouts', () {
    test('packs dense labels without overlap and inside the lane', () {
      final result = layoutSeriesCallouts(
        candidates: [
          for (var index = 0; index < 6; index++)
            SeriesCalloutLayoutCandidate(
              id: 'series-$index',
              desiredCenterY: 48 + index.toDouble(),
              size: const Size(100, 20),
              priority: 0,
            ),
        ],
        minimumY: 4,
        maximumY: 160,
        gap: 4,
        maximumVisible: 8,
      );

      expect(result, hasLength(6));
      for (var index = 1; index < result.length; index++) {
        expect(
          result[index].top,
          greaterThanOrEqualTo(result[index - 1].top + 24),
        );
      }
      expect(result.first.top, greaterThanOrEqualTo(4));
      expect(result.last.top + 20, lessThanOrEqualTo(160));
    });

    test('keeps highest priority labels under capacity pressure', () {
      final result = layoutSeriesCallouts(
        candidates: const [
          SeriesCalloutLayoutCandidate(
            id: 'low',
            desiredCenterY: 20,
            size: Size(80, 24),
            priority: 0,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'high',
            desiredCenterY: 22,
            size: Size(80, 24),
            priority: 10,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'medium',
            desiredCenterY: 24,
            size: Size(80, 24),
            priority: 5,
          ),
        ],
        minimumY: 0,
        maximumY: 54,
        gap: 4,
        maximumVisible: 10,
      );

      expect(result.map((item) => item.id), containsAll(['high', 'medium']));
      expect(result.map((item) => item.id), isNot(contains('low')));
    });

    test('is deterministic regardless of candidate input order', () {
      const a = SeriesCalloutLayoutCandidate(
        id: 'a',
        desiredCenterY: 50,
        size: Size(80, 18),
        priority: 0,
      );
      const b = SeriesCalloutLayoutCandidate(
        id: 'b',
        desiredCenterY: 50,
        size: Size(80, 18),
        priority: 0,
      );
      final forward = layoutSeriesCallouts(
        candidates: const [a, b],
        minimumY: 0,
        maximumY: 100,
        gap: 4,
        maximumVisible: 4,
      );
      final reverse = layoutSeriesCallouts(
        candidates: const [b, a],
        minimumY: 0,
        maximumY: 100,
        gap: 4,
        maximumVisible: 4,
      );

      expect(
        forward.map((item) => (item.id, item.top)),
        reverse.map((item) => (item.id, item.top)),
      );
    });

    test('compact packing uses the exact minimum gap', () {
      final result = layoutSeriesCallouts(
        candidates: const [
          SeriesCalloutLayoutCandidate(
            id: 'low',
            desiredCenterY: 20,
            size: Size(80, 18),
            priority: 0,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'middle',
            desiredCenterY: 90,
            size: Size(80, 22),
            priority: 0,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'high',
            desiredCenterY: 170,
            size: Size(80, 20),
            priority: 0,
          ),
        ],
        minimumY: 4,
        maximumY: 200,
        gap: 6,
        maximumVisible: 4,
        packing: SeriesCalloutPacking.compact,
      );

      expect(result, hasLength(3));
      expect(result[1].top - (result[0].top + 18), closeTo(6, 0.001));
      expect(result[2].top - (result[1].top + 22), closeTo(6, 0.001));
      expect(result.first.top, greaterThanOrEqualTo(4));
      expect(result.last.top + 20, lessThanOrEqualTo(200));
    });

    test('hide collisions preserves exact endpoint alignment', () {
      final result = layoutSeriesCallouts(
        candidates: const [
          SeriesCalloutLayoutCandidate(
            id: 'leader',
            desiredCenterY: 42,
            size: Size(80, 18),
            priority: 100,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'colliding',
            desiredCenterY: 47,
            size: Size(80, 18),
            priority: 50,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'clear',
            desiredCenterY: 80,
            size: Size(80, 18),
            priority: 25,
          ),
        ],
        minimumY: 0,
        maximumY: 100,
        gap: 4,
        maximumVisible: 10,
        packing: SeriesCalloutPacking.hideCollisions,
      );

      expect(result.map((item) => item.id), ['leader', 'clear']);
      expect(result[0].top, 33);
      expect(result[1].top, 71);
    });

    test('hide collisions clamps edge labels without moving clear labels', () {
      final result = layoutSeriesCallouts(
        candidates: const [
          SeriesCalloutLayoutCandidate(
            id: 'top',
            desiredCenterY: 2,
            size: Size(80, 18),
            priority: 10,
          ),
          SeriesCalloutLayoutCandidate(
            id: 'middle',
            desiredCenterY: 50,
            size: Size(80, 18),
            priority: 5,
          ),
        ],
        minimumY: 4,
        maximumY: 96,
        gap: 4,
        maximumVisible: 10,
        packing: SeriesCalloutPacking.hideCollisions,
      );

      expect(result[0].top, 4);
      expect(result[1].top, 41);
    });
  });

  group('resolveSeriesCalloutPanelRect', () {
    test('hugs the union of visible labels plus padding', () {
      final result = resolveSeriesCalloutPanelRect(
        labelRects: const [
          Rect.fromLTWH(8, 40, 72, 20),
          Rect.fromLTWH(8, 66, 96, 24),
        ],
        plotBounds: const Rect.fromLTWH(0, 0, 300, 200),
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 10),
      );

      expect(result, const Rect.fromLTRB(4, 34, 112, 100));
    });

    test('clips content-sized panel to plot bounds', () {
      final result = resolveSeriesCalloutPanelRect(
        labelRects: const [Rect.fromLTWH(2, 3, 30, 18)],
        plotBounds: const Rect.fromLTWH(0, 0, 100, 100),
        padding: const EdgeInsets.all(8),
      );

      expect(result, const Rect.fromLTRB(0, 0, 40, 29));
    });
  });
}
