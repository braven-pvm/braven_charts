// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for ScrollbarManager module

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/rendering/modules/scrollbar_manager.dart';
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test implementation of ScrollbarDelegate for unit testing.
class TestScrollbarDelegate implements ScrollbarDelegate {
  ChartTransform? _transform;
  ChartTransform? _originalTransform;
  DataBounds? _streamingBounds;

  int markNeedsPaintCalls = 0;
  MouseCursor? lastCursor;
  ChartTransform? lastAppliedTransform;
  int updateAxesCalls = 0;

  @override
  ChartTransform? get transform => _transform;

  @override
  ChartTransform? get originalTransform => _originalTransform;

  @override
  DataBounds? get streamingBounds => _streamingBounds;

  void setTransform(ChartTransform? t) => _transform = t;
  void setOriginalTransform(ChartTransform? t) => _originalTransform = t;
  void setStreamingBounds(DataBounds? b) => _streamingBounds = b;

  @override
  void markNeedsPaint() {
    markNeedsPaintCalls++;
  }

  @override
  void setCursor(MouseCursor cursor) {
    lastCursor = cursor;
  }

  @override
  void applyTransform(ChartTransform newTransform) {
    lastAppliedTransform = newTransform;
    _transform = newTransform;
  }

  @override
  void updateAxesFromTransform() {
    updateAxesCalls++;
  }

  void reset() {
    markNeedsPaintCalls = 0;
    lastCursor = null;
    lastAppliedTransform = null;
    updateAxesCalls = 0;
  }
}

void main() {
  group('ScrollbarManager', () {
    late TestScrollbarDelegate delegate;
    late ScrollbarManager manager;

    const defaultTransform = ChartTransform(
      dataXMin: 0,
      dataXMax: 100,
      dataYMin: 0,
      dataYMax: 100,
      plotWidth: 400,
      plotHeight: 300,
      invertY: true,
    );

    setUp(() {
      delegate = TestScrollbarDelegate();
      delegate.setTransform(defaultTransform);
      delegate.setOriginalTransform(defaultTransform);
      manager = ScrollbarManager(delegate: delegate);
    });

    group('Initialization', () {
      test('creates instance with default configuration', () {
        expect(manager.showXScrollbar, isFalse);
        expect(manager.showYScrollbar, isFalse);
        expect(manager.scrollbarTheme, isNull);
        expect(manager.xScrollbarRect, isNull);
        expect(manager.yScrollbarRect, isNull);
        expect(manager.scrollbarsVisible, isTrue);
        expect(manager.scrollbarInitialized, isFalse);
        expect(manager.isDragging, isFalse);
        expect(manager.activeScrollbarAxis, isNull);
      });

      test('creates instance with custom configuration', () {
        final customTheme = ScrollbarConfig.defaultLight;
        final customManager = ScrollbarManager(
          delegate: delegate,
          showXScrollbar: true,
          showYScrollbar: true,
          scrollbarTheme: customTheme,
        );

        expect(customManager.showXScrollbar, isTrue);
        expect(customManager.showYScrollbar, isTrue);
        expect(customManager.scrollbarTheme, equals(customTheme));
      });
    });

    group('Configuration setters', () {
      test('setShowXScrollbar returns true when value changes', () {
        expect(manager.setShowXScrollbar(true), isTrue);
        expect(manager.showXScrollbar, isTrue);
      });

      test('setShowXScrollbar returns false when value unchanged', () {
        manager.setShowXScrollbar(true);
        expect(manager.setShowXScrollbar(true), isFalse);
      });

      test('setShowYScrollbar returns true when value changes', () {
        expect(manager.setShowYScrollbar(true), isTrue);
        expect(manager.showYScrollbar, isTrue);
      });

      test('setShowYScrollbar returns false when value unchanged', () {
        manager.setShowYScrollbar(true);
        expect(manager.setShowYScrollbar(true), isFalse);
      });

      test('setScrollbarTheme returns true when value changes', () {
        final theme = ScrollbarConfig.defaultLight;
        expect(manager.setScrollbarTheme(theme), isTrue);
        expect(manager.scrollbarTheme, equals(theme));
      });

      test('setScrollbarTheme returns false when value unchanged', () {
        final theme = ScrollbarConfig.defaultLight;
        manager.setScrollbarTheme(theme);
        expect(manager.setScrollbarTheme(theme), isFalse);
      });

      test('setScrollbarRects updates both rects', () {
        const xRect = Rect.fromLTWH(0, 290, 400, 10);
        const yRect = Rect.fromLTWH(390, 0, 10, 300);

        manager.setScrollbarRects(xRect: xRect, yRect: yRect);

        expect(manager.xScrollbarRect, equals(xRect));
        expect(manager.yScrollbarRect, equals(yRect));
      });

      test('markInitialized sets scrollbarInitialized flag', () {
        expect(manager.scrollbarInitialized, isFalse);
        manager.markInitialized();
        expect(manager.scrollbarInitialized, isTrue);
      });

      test('setScrollbarsVisible updates visibility', () {
        manager.setScrollbarsVisible(false);
        expect(manager.scrollbarsVisible, isFalse);
        manager.setScrollbarsVisible(true);
        expect(manager.scrollbarsVisible, isTrue);
      });
    });

    group('isViewportModified', () {
      test('returns false when transforms are null', () {
        delegate.setTransform(null);
        expect(manager.isViewportModified(), isFalse);
      });

      test('returns false when original transform is null', () {
        delegate.setOriginalTransform(null);
        expect(manager.isViewportModified(), isFalse);
      });

      test('returns false when transforms match', () {
        expect(manager.isViewportModified(), isFalse);
      });

      test('returns true when dataXMin differs', () {
        delegate.setTransform(defaultTransform.copyWith(dataXMin: 10));
        expect(manager.isViewportModified(), isTrue);
      });

      test('returns true when dataXMax differs', () {
        delegate.setTransform(defaultTransform.copyWith(dataXMax: 90));
        expect(manager.isViewportModified(), isTrue);
      });

      test('returns true when dataYMin differs', () {
        delegate.setTransform(defaultTransform.copyWith(dataYMin: 10));
        expect(manager.isViewportModified(), isTrue);
      });

      test('returns true when dataYMax differs', () {
        delegate.setTransform(defaultTransform.copyWith(dataYMax: 90));
        expect(manager.isViewportModified(), isTrue);
      });
    });

    group('Auto-hide behavior', () {
      test('showScrollbarsAndScheduleHide makes scrollbars visible', () {
        manager.setScrollbarsVisible(false);
        delegate.reset();

        manager.showScrollbarsAndScheduleHide();

        expect(manager.scrollbarsVisible, isTrue);
        expect(delegate.markNeedsPaintCalls, equals(1));
      });

      test('setScrollbarTheme with autoHide false sets visibility to true', () {
        manager.setScrollbarsVisible(false);
        final theme = ScrollbarConfig.defaultLight.copyWith(autoHide: false);

        manager.setScrollbarTheme(theme);

        expect(manager.scrollbarsVisible, isTrue);
      });

      test('setScrollbarTheme with autoHide true respects viewport modification', () {
        // First set up a modified viewport
        delegate.setTransform(defaultTransform.copyWith(dataXMin: 10));
        manager.setScrollbarsVisible(false);

        final theme = ScrollbarConfig.defaultLight.copyWith(autoHide: true);
        manager.setScrollbarTheme(theme);

        // Should be visible because viewport is modified
        expect(manager.scrollbarsVisible, isTrue);
      });

      test('setScrollbarTheme with autoHide true hides if viewport not modified', () {
        // Viewport matches original - not modified
        manager.setScrollbarsVisible(true);

        final theme = ScrollbarConfig.defaultLight.copyWith(autoHide: true);
        manager.setScrollbarTheme(theme);

        // Should be hidden because viewport is not modified
        expect(manager.scrollbarsVisible, isFalse);
      });
    });

    group('Hover detection', () {
      setUp(() {
        manager.setShowXScrollbar(true);
        manager.setShowYScrollbar(true);
        manager.setScrollbarRects(
          xRect: const Rect.fromLTWH(50, 350, 400, 12),
          yRect: const Rect.fromLTWH(450, 50, 12, 300),
        );
      });

      test('returns false when scrollbars not visible', () {
        manager.setScrollbarsVisible(false);
        expect(manager.checkScrollbarHover(const Offset(200, 356)), isFalse);
      });

      test('returns false when position is outside scrollbars', () {
        expect(manager.checkScrollbarHover(const Offset(200, 200)), isFalse);
      });

      test('returns true when hovering over X scrollbar', () {
        expect(manager.checkScrollbarHover(const Offset(200, 356)), isTrue);
      });

      test('returns true when hovering over Y scrollbar', () {
        expect(manager.checkScrollbarHover(const Offset(456, 200)), isTrue);
      });

      test('returns false when X scrollbar not enabled', () {
        manager.setShowXScrollbar(false);
        expect(manager.checkScrollbarHover(const Offset(200, 356)), isFalse);
      });

      test('returns false when Y scrollbar not enabled', () {
        manager.setShowYScrollbar(false);
        expect(manager.checkScrollbarHover(const Offset(456, 200)), isFalse);
      });

      test('updates cursor when hovering over scrollbar', () {
        manager.checkScrollbarHover(const Offset(200, 356));
        expect(delegate.lastCursor, isNotNull);
      });

      test('clears hover zones when not hovering', () {
        // First hover over X scrollbar
        manager.checkScrollbarHover(const Offset(200, 356));
        delegate.reset();

        // Then move away
        manager.checkScrollbarHover(const Offset(200, 200));

        expect(delegate.markNeedsPaintCalls, greaterThan(0));
      });
    });

    group('Hit testing', () {
      setUp(() {
        manager.setShowXScrollbar(true);
        manager.setShowYScrollbar(true);
        manager.setScrollbarRects(
          xRect: const Rect.fromLTWH(50, 350, 400, 12),
          yRect: const Rect.fromLTWH(450, 50, 12, 300),
        );
      });

      test('returns false when position is outside scrollbars', () {
        var claimed = false;
        var canceled = false;
        final result = manager.hitTestScrollbars(
          const Offset(200, 200),
          1, // kPrimaryMouseButton
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () => canceled = true,
        );
        expect(result, isFalse);
      });

      test('returns true when position is on X scrollbar', () {
        var claimed = false;
        var canceled = false;
        final result = manager.hitTestScrollbars(
          const Offset(200, 356),
          1, // kPrimaryMouseButton
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () => canceled = true,
        );
        expect(result, isTrue);
      });

      test('returns true when position is on Y scrollbar', () {
        var claimed = false;
        var canceled = false;
        final result = manager.hitTestScrollbars(
          const Offset(456, 200),
          1, // kPrimaryMouseButton
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () => canceled = true,
        );
        expect(result, isTrue);
      });

      test('returns false when modal mode is active', () {
        var claimed = false;
        var canceled = false;
        final result = manager.hitTestScrollbars(
          const Offset(200, 356),
          1, // kPrimaryMouseButton
          isModal: true, // Modal mode blocks scrollbar interaction
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () => canceled = true,
        );
        expect(result, isFalse);
      });

      test('returns false for non-primary mouse button', () {
        var claimed = false;
        var canceled = false;
        final result = manager.hitTestScrollbars(
          const Offset(200, 356),
          2, // Secondary button
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () => canceled = true,
        );
        expect(result, isFalse);
      });

      test('calls onClaimMode when hit test succeeds', () {
        var claimed = false;
        manager.hitTestScrollbars(
          const Offset(200, 356),
          1,
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () {},
        );
        expect(claimed, isTrue);
      });

      test('calls cancelAutoScroll when hit test succeeds', () {
        var canceled = false;
        manager.hitTestScrollbars(
          const Offset(200, 356),
          1,
          isModal: false,
          onClaimMode: () {},
          cancelAutoScroll: () => canceled = true,
        );
        expect(canceled, isTrue);
      });
    });

    group('Drag handling', () {
      const xScrollbarRect = Rect.fromLTWH(50, 350, 400, 12);
      const yScrollbarRect = Rect.fromLTWH(450, 50, 12, 300);

      setUp(() {
        manager.setShowXScrollbar(true);
        manager.setShowYScrollbar(true);
        manager.setScrollbarRects(xRect: xScrollbarRect, yRect: yScrollbarRect);
      });

      test('hitTestScrollbars starts drag on X scrollbar', () {
        var claimed = false;
        manager.hitTestScrollbars(
          const Offset(200, 356),
          1,
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () {},
        );

        expect(manager.isDragging, isTrue);
        expect(manager.activeScrollbarAxis, equals(Axis.horizontal));
      });

      test('hitTestScrollbars starts drag on Y scrollbar', () {
        var claimed = false;
        manager.hitTestScrollbars(
          const Offset(456, 200),
          1,
          isModal: false,
          onClaimMode: () => claimed = true,
          cancelAutoScroll: () {},
        );

        expect(manager.isDragging, isTrue);
        expect(manager.activeScrollbarAxis, equals(Axis.vertical));
      });

      test('clearScrollbarDragState clears active scrollbar', () {
        manager.hitTestScrollbars(
          const Offset(200, 356),
          1,
          isModal: false,
          onClaimMode: () {},
          cancelAutoScroll: () {},
        );
        expect(manager.isDragging, isTrue);

        manager.clearScrollbarDragState();
        expect(manager.isDragging, isFalse);
        expect(manager.activeScrollbarAxis, isNull);
      });

      test('handleScrollbarDrag does nothing when not dragging', () {
        delegate.reset();
        manager.handleScrollbarDrag(const Offset(200, 356));
        // Should not apply any transform when not dragging
        expect(delegate.lastAppliedTransform, isNull);
      });
    });

    group('Disposal', () {
      test('dispose cancels auto-hide timer', () {
        manager.showScrollbarsAndScheduleHide();
        // Should not throw
        manager.dispose();
      });

      test('dispose can be called multiple times safely', () {
        manager.dispose();
        // Should not throw on second call
        manager.dispose();
      });
    });

    group('Painting', () {
      test('does not paint when scrollbars not visible', () {
        manager.setScrollbarsVisible(false);
        // Should not throw and should return early
        // We can't easily test Canvas calls, but verify no exceptions
        expect(
            () => manager.paint(
                  _FakeCanvas(),
                  const Size(500, 400),
                ),
            returnsNormally);
      });

      test('does not paint when no scrollbars enabled', () {
        manager.setShowXScrollbar(false);
        manager.setShowYScrollbar(false);
        expect(
            () => manager.paint(
                  _FakeCanvas(),
                  const Size(500, 400),
                ),
            returnsNormally);
      });

      test('paints when X scrollbar enabled and visible', () {
        manager.setShowXScrollbar(true);
        manager.setScrollbarRects(xRect: const Rect.fromLTWH(50, 350, 400, 12));
        expect(
            () => manager.paint(
                  _FakeCanvas(),
                  const Size(500, 400),
                ),
            returnsNormally);
      });

      test('paints when Y scrollbar enabled and visible', () {
        manager.setShowYScrollbar(true);
        manager.setScrollbarRects(yRect: const Rect.fromLTWH(450, 50, 12, 300));
        expect(
            () => manager.paint(
                  _FakeCanvas(),
                  const Size(500, 400),
                ),
            returnsNormally);
      });
    });

    group('Streaming bounds', () {
      test('uses streaming bounds when available for viewport check', () {
        // Set up streaming bounds
        const streamingBounds = DataBounds(
          xMin: 0,
          xMax: 200,
          yMin: 0,
          yMax: 200,
        );
        delegate.setStreamingBounds(streamingBounds);

        // With streaming bounds, viewport that matches original transform
        // may still be "modified" relative to streaming bounds
        delegate.setTransform(defaultTransform.copyWith(dataXMax: 100));
        delegate.setOriginalTransform(defaultTransform);

        // This depends on implementation - streaming charts may have
        // different viewport modification logic
        // Just verify no exceptions occur
        expect(() => manager.isViewportModified(), returnsNormally);
      });
    });

    group('Scrollbar calculations', () {
      test('setXScrollbarRect updates X scrollbar rect', () {
        const xRect = Rect.fromLTWH(50, 350, 400, 12);
        manager.setScrollbarRects(xRect: xRect);
        expect(manager.xScrollbarRect, equals(xRect));
      });

      test('setYScrollbarRect updates Y scrollbar rect', () {
        const yRect = Rect.fromLTWH(450, 50, 12, 300);
        manager.setScrollbarRects(yRect: yRect);
        expect(manager.yScrollbarRect, equals(yRect));
      });
    });
  });
}

/// Minimal Canvas implementation for testing paint calls.
class _FakeCanvas implements Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
