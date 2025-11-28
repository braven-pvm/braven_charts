/// Integration tests for theme switching with RenderContext.
library;

import 'dart:ui';

import 'package:braven_charts/legacy/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/legacy/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart';
import 'package:braven_charts/legacy/src/rendering/render_context.dart';
import 'package:braven_charts/legacy/src/rendering/text_layout_cache.dart';
import 'package:braven_charts/legacy/src/theming/chart_theme.dart';
import 'package:braven_charts/legacy/src/theming/extensions/render_context_theme_extension.dart';
import 'package:braven_charts/legacy/src/theming/utilities/style_cache.dart';
import 'package:flutter/material.dart' show TextPainter, Color;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Switching Integration', () {
    late RenderContext context;
    late Canvas canvas;

    setUp(() {
      // Create a minimal RenderContext for testing
      final recorder = PictureRecorder();
      canvas = Canvas(recorder);

      context = RenderContext(
        canvas: canvas,
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(0, 0, 800, 600),
        culler: const ViewportCuller(),
        paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
        pathPool:
            ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
        textPainterPool: ObjectPool<TextPainter>(
          factory: () => TextPainter(textDirection: TextDirection.ltr),
          reset: (tp) {},
        ),
        textCache: LinkedHashMapTextLayoutCache(),
        performanceMonitor: StopwatchPerformanceMonitor(),
      );
    });

    group('Theme Application', () {
      test('applyTheme sets current theme', () {
        context.applyTheme(ChartTheme.defaultLight);

        expect(context.currentTheme, equals(ChartTheme.defaultLight));
      });

      test('applyTheme clears style cache', () {
        // Add something to cache first
        final cache = context.styleCache;
        cache.put(
          const StyleCacheKey(themeHash: 123, elementType: 'test'),
          'value',
        );
        expect(cache.size, equals(1));

        // Apply theme should clear cache
        context.applyTheme(ChartTheme.defaultLight);

        expect(cache.size, equals(0));
        expect(cache.isEmpty, isTrue);
      });

      test('multiple applyTheme calls each clear cache', () {
        final cache = context.styleCache;

        context.applyTheme(ChartTheme.defaultLight);
        cache.put(
          const StyleCacheKey(themeHash: 1, elementType: 'test'),
          'value1',
        );

        context.applyTheme(ChartTheme.defaultDark);
        expect(cache.size, equals(0)); // Cache cleared

        cache.put(
          const StyleCacheKey(themeHash: 2, elementType: 'test'),
          'value2',
        );

        context.applyTheme(ChartTheme.vibrant);
        expect(cache.size, equals(0)); // Cache cleared again
      });
    });

    group('Theme Switching with Diffing', () {
      test('updateTheme with no previous theme clears cache', () {
        final cache = context.styleCache;
        cache.put(
          const StyleCacheKey(themeHash: 999, elementType: 'old'),
          'old-value',
        );

        final changes = context.updateTheme(ChartTheme.defaultLight);

        // Should clear cache since no previous theme
        expect(cache.size, equals(0));
        expect(context.currentTheme, equals(ChartTheme.defaultLight));
        expect(changes.anyChanged, isTrue);
      });

      test('updateTheme to identical theme does not clear cache', () {
        final cache = context.styleCache;

        context.applyTheme(ChartTheme.defaultLight);
        cache.put(
          const StyleCacheKey(themeHash: 123, elementType: 'test'),
          'value',
        );

        final changes = context.updateTheme(ChartTheme.defaultLight);

        // Cache should NOT be cleared (no changes)
        expect(cache.size, equals(1));
        expect(changes.anyChanged, isFalse);
      });

      test('updateTheme to different theme clears cache', () {
        final cache = context.styleCache;

        context.applyTheme(ChartTheme.defaultLight);
        cache.put(
          const StyleCacheKey(themeHash: 123, elementType: 'test'),
          'value',
        );

        final changes = context.updateTheme(ChartTheme.defaultDark);

        // Cache should be cleared (themes different)
        expect(cache.size, equals(0));
        expect(changes.anyChanged, isTrue);
        expect(context.currentTheme, equals(ChartTheme.defaultDark));
      });

      test('updateTheme returns correct change information', () {
        context.applyTheme(ChartTheme.defaultLight);

        final newTheme = ChartTheme.defaultLight.copyWith(
          backgroundColor: const Color(0xFF000000),
        );

        final changes = context.updateTheme(newTheme);

        expect(changes.backgroundChanged, isTrue);
        expect(changes.gridStyleChanged, isFalse);
        expect(changes.axisStyleChanged, isFalse);
        expect(changes.anyChanged, isTrue);
      });
    });

    group('Cache Invalidation on Theme Change', () {
      test('cache invalidated when background changes', () {
        final cache = context.styleCache;

        context.applyTheme(ChartTheme.defaultLight);
        cache.put(
          const StyleCacheKey(themeHash: 1, elementType: 'bg'),
          'cached-bg',
        );

        final newTheme = ChartTheme.defaultLight.copyWith(
          backgroundColor: const Color(0xFF000000),
        );
        context.updateTheme(newTheme);

        // Cache should be cleared
        expect(cache.size, equals(0));
      });

      test('cache invalidated when grid style changes', () {
        final cache = context.styleCache;

        context.applyTheme(ChartTheme.defaultLight);
        cache.put(
          const StyleCacheKey(themeHash: 1, elementType: 'grid'),
          'cached-grid',
        );

        final newTheme = ChartTheme.defaultLight.copyWith(
          gridStyle: ChartTheme.defaultDark.gridStyle,
        );
        context.updateTheme(newTheme);

        // Cache should be cleared
        expect(cache.size, equals(0));
      });

      test('cache invalidated when series theme changes', () {
        final cache = context.styleCache;

        context.applyTheme(ChartTheme.defaultLight);
        cache.put(
          const StyleCacheKey(themeHash: 1, elementType: 'series'),
          'cached-series',
        );

        final newTheme = ChartTheme.defaultLight.copyWith(
          seriesTheme: ChartTheme.vibrant.seriesTheme,
        );
        context.updateTheme(newTheme);

        // Cache should be cleared
        expect(cache.size, equals(0));
      });
    });

    group('Theme Switching Preserves Context State', () {
      test('canvas remains accessible after theme switch', () {
        context.applyTheme(ChartTheme.defaultLight);
        expect(context.canvas, equals(canvas));

        context.updateTheme(ChartTheme.defaultDark);
        expect(context.canvas, equals(canvas));
      });

      test('viewport remains unchanged after theme switch', () {
        context.applyTheme(ChartTheme.defaultLight);
        final viewport = context.viewport;

        context.updateTheme(ChartTheme.defaultDark);

        expect(context.viewport, equals(viewport));
      });

      test('size remains unchanged after theme switch', () {
        context.applyTheme(ChartTheme.defaultLight);
        final size = context.size;

        context.updateTheme(ChartTheme.defaultDark);

        expect(context.size, equals(size));
      });

      test('object pools remain accessible after theme switch', () {
        context.applyTheme(ChartTheme.defaultLight);

        final paintPool = context.paintPool;
        final pathPool = context.pathPool;
        final textPainterPool = context.textPainterPool;

        context.updateTheme(ChartTheme.defaultDark);

        expect(context.paintPool, equals(paintPool));
        expect(context.pathPool, equals(pathPool));
        expect(context.textPainterPool, equals(textPainterPool));
      });
    });

    group('Partial Re-render Detection', () {
      test('can detect which components need re-render', () {
        context.applyTheme(ChartTheme.defaultLight);

        final newTheme = ChartTheme.defaultLight.copyWith(
          backgroundColor: const Color(0xFF000000),
          gridStyle: ChartTheme.defaultDark.gridStyle,
        );

        final changes = context.updateTheme(newTheme);

        // Can determine what needs re-rendering
        expect(changes.backgroundChanged, isTrue); // Re-render background
        expect(changes.gridStyleChanged, isTrue); // Re-render grid
        expect(changes.axisStyleChanged, isFalse); // Skip axis re-render
        expect(changes.seriesThemeChanged, isFalse); // Skip series re-render
      });

      test('no re-render needed when theme identical', () {
        context.applyTheme(ChartTheme.defaultLight);

        final changes = context.updateTheme(ChartTheme.defaultLight);

        // Nothing needs re-rendering
        expect(changes.anyChanged, isFalse);
      });
    });

    group('Real-World Scenarios', () {
      test('light to dark theme switch', () {
        context.applyTheme(ChartTheme.defaultLight);

        final changes = context.updateTheme(ChartTheme.defaultDark);

        expect(changes.anyChanged, isTrue);
        expect(context.currentTheme, equals(ChartTheme.defaultDark));
      });

      test('switching between custom themes', () {
        final customTheme1 = ChartTheme.defaultLight.copyWith(
          backgroundColor: const Color(0xFFF5F5F5),
        );

        final customTheme2 = ChartTheme.defaultLight.copyWith(
          backgroundColor: const Color(0xFFE0E0E0),
        );

        context.applyTheme(customTheme1);
        final changes = context.updateTheme(customTheme2);

        expect(changes.backgroundChanged, isTrue);
        expect(changes.anyChanged, isTrue);
      });

      test('rapid theme switches', () {
        final themes = [
          ChartTheme.defaultLight,
          ChartTheme.defaultDark,
          ChartTheme.vibrant,
          ChartTheme.corporateBlue,
          ChartTheme.minimal,
        ];

        for (final theme in themes) {
          context.updateTheme(theme);
          expect(context.currentTheme, equals(theme));
        }
      });
    });
  });
}
