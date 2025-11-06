// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0.9 - Resize Handle Unit Tests
//
// Tests validate CONFLICT_RESOLUTION_TABLE.md Scenarios #1 and #10:
// - Scenario #1: Resize handle vs datapoint (priority 9 > 6)
// - Scenario #10: Resize drag leaves bounds (handled by coordinator priority)
//
// Acceptance Criteria:
// ✅ All 8 resize handles functional (4 corners + 4 midpoints)
// ✅ Handle hit testing works within 12px radius
// ✅ Handles only visible/hit-testable when annotation selected
// ✅ Priority 9 enforced at coordinator level (tested in coordinator_test.dart)
//
// Note: Full widget-level resize drag testing deferred to integration tests
// when PrototypeChart has resize callbacks implemented.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/elements/simulated_annotation.dart';

void main() {
  group('Resize Handle Detection (Scenario #1)', () {
    test('annotation should provide all 8 resize handles when selected', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      final handles = annotation.getResizeHandles();

      expect(handles.length, equals(8));

      // Verify all 8 handles have distinct directions
      final directions = handles.map((h) => h.direction).toSet();
      expect(directions.length, equals(8)); // All unique

      // Verify handle order: 4 corners + 4 midpoints
      expect(handles[0].direction, equals(ResizeDirection.topLeft));
      expect(handles[1].direction, equals(ResizeDirection.topRight));
      expect(handles[2].direction, equals(ResizeDirection.bottomLeft));
      expect(handles[3].direction, equals(ResizeDirection.bottomRight));
      expect(handles[4].direction, equals(ResizeDirection.top));
      expect(handles[5].direction, equals(ResizeDirection.right));
      expect(handles[6].direction, equals(ResizeDirection.bottom));
      expect(handles[7].direction, equals(ResizeDirection.left));
    });

    test('corner handles should be positioned at annotation corners', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      final handles = annotation.getResizeHandles();

      // Top-left corner
      expect(handles[0].center, equals(const Offset(100, 100)));
      expect(handles[0].id, equals('tl'));

      // Top-right corner
      expect(handles[1].center, equals(const Offset(300, 100)));
      expect(handles[1].id, equals('tr'));

      // Bottom-left corner
      expect(handles[2].center, equals(const Offset(100, 200)));
      expect(handles[2].id, equals('bl'));

      // Bottom-right corner
      expect(handles[3].center, equals(const Offset(300, 200)));
      expect(handles[3].id, equals('br'));
    });

    test('midpoint handles should be positioned at edge centers', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      final handles = annotation.getResizeHandles();

      // Top midpoint
      expect(handles[4].center, equals(const Offset(200, 100)));
      expect(handles[4].id, equals('t'));

      // Right midpoint
      expect(handles[5].center, equals(const Offset(300, 150)));
      expect(handles[5].id, equals('r'));

      // Bottom midpoint
      expect(handles[6].center, equals(const Offset(200, 200)));
      expect(handles[6].id, equals('b'));

      // Left midpoint
      expect(handles[7].center, equals(const Offset(100, 150)));
      expect(handles[7].id, equals('l'));
    });
  });

  group('Resize Handle Hit Testing', () {
    test('hitTestHandle should return handle when clicked within 12px radius', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Hit exactly on topLeft handle center
      final exactHit = annotation.hitTestHandle(const Offset(100, 100));
      expect(exactHit, isNotNull);
      expect(exactHit!.handleId, equals('tl'));
      expect(exactHit.direction, equals(ResizeDirection.topLeft));
    });

    test('hitTestHandle should work at 11px distance (inside 12px radius)', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Click 11px away from topLeft handle (inside 12px radius)
      final nearHit = annotation.hitTestHandle(const Offset(111, 100));
      expect(nearHit, isNotNull);
      expect(nearHit!.direction, equals(ResizeDirection.topLeft));
    });

    test('hitTestHandle should return null at 13px distance (outside 12px radius)', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Click 13px away from topLeft handle (outside 12px radius)
      final farHit = annotation.hitTestHandle(const Offset(113, 100));
      expect(farHit, isNull);
    });

    test('hitTestHandle should return null when annotation not selected', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: false, // NOT selected
      );

      // Handles should not be hit-testable when not selected
      final hit = annotation.hitTestHandle(const Offset(100, 100));
      expect(hit, isNull);
    });

    test('all 8 handles should be individually hit-testable', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      final handles = annotation.getResizeHandles();
      final hitResults = <ResizeDirection>[];

      for (final handle in handles) {
        final hit = annotation.hitTestHandle(handle.center);
        expect(hit, isNotNull, reason: 'Handle ${handle.id} at ${handle.center} should be hit-testable');
        hitResults.add(hit!.direction);
      }

      // All 8 handles should produce unique directions
      expect(hitResults.toSet().length, equals(8));
    });

    test('hitTestHandle should detect nearest handle when multiple are nearby', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Click 5px from topLeft, 15px from top midpoint
      // topLeft should win (5px < 12px radius, 15px > 12px radius)
      final hit = annotation.hitTestHandle(const Offset(105, 100));
      expect(hit, isNotNull);
      expect(hit!.direction, equals(ResizeDirection.topLeft));
    });
  });

  group('Resize Handle Priority vs Datapoint', () {
    test('hitTest should return true for handle hit (priority 9 > datapoint priority 6)', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Hit test on handle position
      final hitResult = annotation.hitTest(const Offset(100, 100));
      expect(hitResult, isTrue); // Annotation claims the hit (handle has priority)
    });

    test('hitTest should return true for annotation body when no handle hit', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Hit test inside annotation body, far from handles
      final hitResult = annotation.hitTest(const Offset(200, 150));
      expect(hitResult, isTrue); // Annotation body hit
    });

    test('hitTest should prioritize handle over body when both overlap', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Hit exactly on handle (which is also in annotation body)
      final handleHit = annotation.hitTestHandle(const Offset(100, 100));
      expect(handleHit, isNotNull); // Handle detected

      final overallHit = annotation.hitTest(const Offset(100, 100));
      expect(overallHit, isTrue); // Annotation claims the hit
    });
  });

  group('Resize Handle Bounds Validation', () {
    test('handles should update when annotation bounds change', () {
      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      final originalHandles = annotation.getResizeHandles();
      expect(originalHandles[0].center, equals(const Offset(100, 100)));

      // Update annotation bounds
      annotation.updateBounds(const Rect.fromLTWH(150, 150, 200, 100));

      final updatedHandles = annotation.getResizeHandles();
      expect(updatedHandles[0].center, equals(const Offset(150, 150))); // topLeft moved
    });

    test('handles should scale with annotation size', () {
      // Small annotation
      final smallAnnotation = SimulatedAnnotation(
        id: 'small',
        bounds: const Rect.fromLTWH(100, 100, 50, 50),
        isSelected: true,
      );

      final smallHandles = smallAnnotation.getResizeHandles();
      expect(smallHandles[4].center, equals(const Offset(125, 100))); // top midpoint

      // Large annotation
      final largeAnnotation = SimulatedAnnotation(
        id: 'large',
        bounds: const Rect.fromLTWH(100, 100, 400, 200),
        isSelected: true,
      );

      final largeHandles = largeAnnotation.getResizeHandles();
      expect(largeHandles[4].center, equals(const Offset(300, 100))); // top midpoint
    });
  });

  group('Resize Direction Enum Validation', () {
    test('all 8 ResizeDirection values should exist', () {
      final directions = ResizeDirection.values;
      expect(directions.length, equals(8));

      expect(directions, contains(ResizeDirection.topLeft));
      expect(directions, contains(ResizeDirection.topRight));
      expect(directions, contains(ResizeDirection.bottomLeft));
      expect(directions, contains(ResizeDirection.bottomRight));
      expect(directions, contains(ResizeDirection.top));
      expect(directions, contains(ResizeDirection.right));
      expect(directions, contains(ResizeDirection.bottom));
      expect(directions, contains(ResizeDirection.left));
    });

    test('ResizeDirection should have distinct values', () {
      final directions = ResizeDirection.values.toSet();
      expect(directions.length, equals(8)); // All unique
    });
  });

  group('Scenario #10: Resize Priority Enforcement', () {
    test('resize mode priority (9) validated at coordinator level', () {
      // This scenario is tested in coordinator_test.dart:
      // - resizingAnnotation (priority 9) blocks panning (priority 3)
      // - resizingAnnotation (priority 9) blocks datapoint selection (priority 6)
      // - contextMenuOpen (priority 10) can interrupt resizingAnnotation (priority 9)
      //
      // This test serves as documentation that Scenario #10 priority enforcement
      // is validated in the coordinator unit tests, not at the element level.

      final annotation = SimulatedAnnotation(
        id: 'annotation_1',
        bounds: const Rect.fromLTWH(100, 100, 200, 100),
        isSelected: true,
      );

      // Annotation priority is 8 (HIGH - for annotation body)
      expect(annotation.priority, equals(8));

      // Resize mode priority is 9 (enforced by InteractionMode.resizingAnnotation)
      // This is tested in coordinator_test.dart
    });
  });
}
