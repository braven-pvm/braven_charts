// Copyright (c) 2025 braven_charts. All rights reserved.
// Tests for SeriesCacheManager module

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:braven_charts/src/rendering/modules/series_cache_manager.dart';

void main() {
  group('SeriesCacheManager', () {
    late SeriesCacheManager cacheManager;

    setUp(() {
      cacheManager = SeriesCacheManager();
    });

    tearDown(() {
      cacheManager.dispose();
    });

    // =========================================================================
    // Initial State Tests
    // =========================================================================

    group('Initial State', () {
      test('starts with isDirty true', () {
        expect(cacheManager.isDirty, isTrue);
      });

      test('starts with cachedPicture null', () {
        expect(cacheManager.cachedPicture, isNull);
      });
    });

    // =========================================================================
    // Invalidation Tests
    // =========================================================================

    group('Invalidation', () {
      test('invalidate sets isDirty to true', () {
        // Generate a picture first to clear dirty flag
        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: const ChartTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 800,
            plotHeight: 600,
          ),
          painter: (canvas, size) {},
        );

        expect(cacheManager.isDirty, isFalse);

        cacheManager.invalidate();

        expect(cacheManager.isDirty, isTrue);
      });
    });

    // =========================================================================
    // Generate Picture Tests
    // =========================================================================

    group('Generate Picture', () {
      test('generates a non-null Picture', () {
        final picture = cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: const ChartTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 800,
            plotHeight: 600,
          ),
          painter: (canvas, size) {},
        );

        expect(picture, isNotNull);
        expect(cacheManager.cachedPicture, equals(picture));
      });

      test('clears isDirty after generation', () {
        expect(cacheManager.isDirty, isTrue);

        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: const ChartTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 800,
            plotHeight: 600,
          ),
          painter: (canvas, size) {},
        );

        expect(cacheManager.isDirty, isFalse);
      });

      test('calls painter callback with canvas and size', () {
        var painterCalled = false;
        Size? receivedSize;

        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: const ChartTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 800,
            plotHeight: 600,
          ),
          painter: (canvas, size) {
            painterCalled = true;
            receivedSize = size;
          },
        );

        expect(painterCalled, isTrue);
        expect(receivedSize, equals(const Size(800, 600)));
      });
    });

    // =========================================================================
    // Cache Validity Tests
    // =========================================================================

    group('Cache Validity', () {
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 800,
        plotHeight: 600,
      );

      test('isValid returns false when no picture exists', () {
        expect(
          cacheManager.isValid(
            elements: [],
            currentTransform: transform,
          ),
          isFalse,
        );
      });

      test('isValid returns false when isDirty', () {
        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: transform,
          painter: (canvas, size) {},
        );

        cacheManager.invalidate();

        expect(
          cacheManager.isValid(
            elements: [],
            currentTransform: transform,
          ),
          isFalse,
        );
      });

      test('isValid returns true when cache is fresh', () {
        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: transform,
          painter: (canvas, size) {},
        );

        expect(
          cacheManager.isValid(
            elements: [],
            currentTransform: transform,
          ),
          isTrue,
        );
      });

      test('isValid returns false when transform changes', () {
        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: transform,
          painter: (canvas, size) {},
        );

        const newTransform = ChartTransform(
          dataXMin: 10, // Changed!
          dataXMax: 100,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 800,
          plotHeight: 600,
        );

        expect(
          cacheManager.isValid(
            elements: [],
            currentTransform: newTransform,
          ),
          isFalse,
        );
      });
    });

    // =========================================================================
    // Disposal Tests
    // =========================================================================

    group('Disposal', () {
      test('dispose clears cachedPicture', () {
        cacheManager.generatePicture(
          elements: [],
          plotAreaSize: const Size(800, 600),
          currentTransform: const ChartTransform(
            dataXMin: 0,
            dataXMax: 100,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 800,
            plotHeight: 600,
          ),
          painter: (canvas, size) {},
        );

        expect(cacheManager.cachedPicture, isNotNull);

        cacheManager.dispose();

        expect(cacheManager.cachedPicture, isNull);
      });

      test('dispose can be called multiple times safely', () {
        cacheManager.dispose();
        cacheManager.dispose();
        // No exception thrown
      });
    });
  });
}
