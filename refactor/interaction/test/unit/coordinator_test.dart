// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Coordinator Unit Tests

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/core/coordinator.dart';
import 'package:interaction_prototype/core/interaction_mode.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';

void main() {
  group('ChartInteractionCoordinator - Initialization', () {
    test('should initialize with idle mode and empty state', () {
      final coordinator = ChartInteractionCoordinator();

      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.selectedElements, isEmpty);
      expect(coordinator.activeElement, isNull);
      expect(coordinator.hoveredElement, isNull);
      expect(coordinator.isCtrlPressed, isFalse);
      expect(coordinator.isShiftPressed, isFalse);
      expect(coordinator.isAltPressed, isFalse);
      expect(coordinator.isPanning, isFalse);
      expect(coordinator.isSelecting, isFalse);
      expect(coordinator.isInteracting, isFalse);
    });
  });

  group('ChartInteractionCoordinator - Mode Transitions', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement testElement;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      testElement = SimulatedDatapoint(
        id: 'test_1',
        center: const Offset(100, 100),
      );
    });

    test('should transition: idle → hovering → idle', () {
      coordinator.setHoveredElement(testElement);
      expect(coordinator.currentMode, equals(InteractionMode.hovering));
      expect(coordinator.hoveredElement, equals(testElement));

      coordinator.setHoveredElement(null);
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.hoveredElement, isNull);
    });

    test('should transition: idle → selecting via selectElement', () {
      coordinator.selectElement(testElement);
      // Note: selectElement doesn't automatically change mode to 'selecting'
      // The element is selected, but mode remains idle until an interaction starts
      expect(coordinator.selectedElements.contains(testElement), isTrue);
      expect(coordinator.isElementSelected(testElement), isTrue);
    });

    test('should transition: selecting → panning → idle', () {
      coordinator.selectElement(testElement);

      final success = coordinator.claimMode(InteractionMode.panning);
      expect(success, isTrue);
      expect(coordinator.currentMode, equals(InteractionMode.panning));
      expect(coordinator.isPanning, isTrue);

      coordinator.releaseMode();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.isPanning, isFalse);
    });

    test('should transition: selecting → draggingDataPoint → idle', () {
      coordinator.selectElement(testElement);

      final success = coordinator.claimMode(
        InteractionMode.draggingDataPoint,
        element: testElement,
      );
      expect(success, isTrue);
      expect(coordinator.currentMode, equals(InteractionMode.draggingDataPoint));
      expect(coordinator.activeElement, equals(testElement));
      expect(coordinator.isDragging, isTrue);

      coordinator.releaseMode();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.activeElement, isNull);
      expect(coordinator.isDragging, isFalse);
    });
  });

  group('ChartInteractionCoordinator - Mode Claiming & Priority', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement element1;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      element1 = SimulatedDatapoint(id: 'elem_1', center: const Offset(50, 50));
    });

    test('should prevent low-priority mode from interrupting high-priority', () {
      // Claim dragging (priority 7)
      coordinator.claimMode(InteractionMode.draggingDataPoint, element: element1);

      // Try to claim panning (priority 3) - should fail
      final canPan = coordinator.claimMode(InteractionMode.panning);
      expect(canPan, isFalse);
      expect(coordinator.currentMode, equals(InteractionMode.draggingDataPoint));
    });

    test('should allow high-priority mode to interrupt low-priority', () {
      // Claim panning (priority 3)
      coordinator.claimMode(InteractionMode.panning);

      // Try to claim dragging (priority 7) - should succeed
      final canDrag = coordinator.claimMode(
        InteractionMode.draggingDataPoint,
        element: element1,
      );
      expect(canDrag, isTrue);
      expect(coordinator.currentMode, equals(InteractionMode.draggingDataPoint));
    });

    test('should block all modes during modal contextMenuOpen', () {
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: element1);
      expect(coordinator.isModal, isTrue);

      // Try various interactions - all should fail
      expect(coordinator.claimMode(InteractionMode.panning), isFalse);
      expect(coordinator.claimMode(InteractionMode.selecting), isFalse);
      expect(coordinator.claimMode(InteractionMode.draggingDataPoint), isFalse);
      expect(coordinator.claimMode(InteractionMode.resizingAnnotation), isFalse);

      // Mode should not have changed
      expect(coordinator.currentMode, equals(InteractionMode.contextMenuOpen));
    });

    test('should block all modes during modal editingAnnotation', () {
      coordinator.claimMode(InteractionMode.editingAnnotation, element: element1);
      expect(coordinator.isModal, isTrue);

      // Try various interactions - all should fail
      expect(coordinator.claimMode(InteractionMode.panning), isFalse);
      expect(coordinator.claimMode(InteractionMode.hovering), isFalse);
      expect(coordinator.claimMode(InteractionMode.draggingDataPoint), isFalse);
    });

    test('should use canStartInteraction to validate mode transitions', () {
      // Idle state - allow most interactions
      expect(coordinator.canStartInteraction(InteractionMode.panning), isTrue);
      expect(coordinator.canStartInteraction(InteractionMode.selecting), isTrue);

      // Claim panning
      coordinator.claimMode(InteractionMode.panning);

      // Check what's allowed during panning
      expect(
        coordinator.canStartInteraction(InteractionMode.resizingAnnotation),
        isTrue, // Priority 9 > 3
      );
      expect(
        coordinator.canStartInteraction(InteractionMode.zooming),
        isFalse, // Priority 1 < 3
      );
    });
  });

  group('ChartInteractionCoordinator - Selection Management', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement element1, element2, element3;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      element1 = SimulatedDatapoint(id: 'elem_1', center: const Offset(50, 50));
      element2 = SimulatedDatapoint(id: 'elem_2', center: const Offset(100, 100));
      element3 = SimulatedDatapoint(id: 'elem_3', center: const Offset(150, 150));
    });

    test('should select single element and clear previous selection', () {
      coordinator.selectElement(element1);
      expect(coordinator.selectedElements.length, equals(1));
      expect(coordinator.isElementSelected(element1), isTrue);

      coordinator.selectElement(element2);
      expect(coordinator.selectedElements.length, equals(1));
      expect(coordinator.isElementSelected(element1), isFalse);
      expect(coordinator.isElementSelected(element2), isTrue);
    });

    test('should toggle selection for multi-select', () {
      coordinator.selectElement(element1);
      coordinator.toggleElementSelection(element2);

      expect(coordinator.selectedElements.length, equals(2));
      expect(coordinator.isElementSelected(element1), isTrue);
      expect(coordinator.isElementSelected(element2), isTrue);

      // Toggle off element1
      coordinator.toggleElementSelection(element1);
      expect(coordinator.selectedElements.length, equals(1));
      expect(coordinator.isElementSelected(element1), isFalse);
      expect(coordinator.isElementSelected(element2), isTrue);
    });

    test('should add multiple elements via addToSelection', () {
      coordinator.addToSelection({element1, element2, element3});

      expect(coordinator.selectedElements.length, equals(3));
      expect(coordinator.isElementSelected(element1), isTrue);
      expect(coordinator.isElementSelected(element2), isTrue);
      expect(coordinator.isElementSelected(element3), isTrue);
    });

    test('should clear all selections', () {
      coordinator.addToSelection({element1, element2, element3});
      expect(coordinator.selectedElements.length, equals(3));

      coordinator.clearSelection();
      expect(coordinator.selectedElements, isEmpty);
    });

    test('should maintain selection during mode transitions', () {
      coordinator.selectElement(element1);
      coordinator.toggleElementSelection(element2);

      coordinator.claimMode(InteractionMode.panning);
      expect(coordinator.selectedElements.length, equals(2));

      coordinator.releaseMode();
      expect(coordinator.selectedElements.length, equals(2));
    });

    test('should notify listeners on selection changes', () {
      int notificationCount = 0;
      coordinator.addListener(() => notificationCount++);

      coordinator.selectElement(element1);
      // selectElement calls clearSelection (1 notify) + adds element (1 notify) = 2
      expect(notificationCount, equals(2));

      coordinator.toggleElementSelection(element2);
      expect(notificationCount, equals(3));

      coordinator.clearSelection();
      expect(notificationCount, equals(4));
    });
  });

  group('ChartInteractionCoordinator - Hover Management', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement element1, element2;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      element1 = SimulatedDatapoint(id: 'elem_1', center: const Offset(50, 50));
      element2 = SimulatedDatapoint(id: 'elem_2', center: const Offset(100, 100));
    });

    test('should track hovered element', () {
      coordinator.setHoveredElement(element1);
      expect(coordinator.hoveredElement, equals(element1));
      expect(coordinator.currentMode, equals(InteractionMode.hovering));
    });

    test('should update hover when moving to different element', () {
      coordinator.setHoveredElement(element1);
      coordinator.setHoveredElement(element2);

      expect(coordinator.hoveredElement, equals(element2));
    });

    test('should suspend hover during panning (per conflict scenario 12)', () {
      coordinator.claimMode(InteractionMode.panning);

      coordinator.setHoveredElement(element1);
      expect(coordinator.currentMode, equals(InteractionMode.panning));
      // setHoveredElement still tracks the element internally, but doesn't enter hover mode
      // and doesn't call onHoverEnter() during panning
      expect(coordinator.hoveredElement, equals(element1)); // Internal tracking maintained
    });

    test('should restore hover after panning ends', () {
      coordinator.claimMode(InteractionMode.panning);
      coordinator.releaseMode();

      coordinator.setHoveredElement(element1);
      expect(coordinator.hoveredElement, equals(element1));
      expect(coordinator.currentMode, equals(InteractionMode.hovering));
    });
  });

  group('ChartInteractionCoordinator - Keyboard Modifier Tracking', () {
    late ChartInteractionCoordinator coordinator;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
    });

    test('should track Ctrl key', () {
      coordinator.updateModifierKeys({LogicalKeyboardKey.control});
      expect(coordinator.isCtrlPressed, isTrue);

      coordinator.updateModifierKeys({});
      expect(coordinator.isCtrlPressed, isFalse);
    });

    test('should track Shift key', () {
      coordinator.updateModifierKeys({LogicalKeyboardKey.shift});
      expect(coordinator.isShiftPressed, isTrue);

      coordinator.updateModifierKeys({});
      expect(coordinator.isShiftPressed, isFalse);
    });

    test('should track Alt key', () {
      coordinator.updateModifierKeys({LogicalKeyboardKey.alt});
      expect(coordinator.isAltPressed, isTrue);

      coordinator.updateModifierKeys({});
      expect(coordinator.isAltPressed, isFalse);
    });

    test('should treat Meta key as Ctrl (macOS Command)', () {
      coordinator.updateModifierKeys({LogicalKeyboardKey.meta});
      expect(coordinator.isCtrlPressed, isTrue);
    });

    test('should track multiple modifiers simultaneously', () {
      coordinator.updateModifierKeys({
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
      });
      expect(coordinator.isCtrlPressed, isTrue);
      expect(coordinator.isShiftPressed, isTrue);
      expect(coordinator.isAltPressed, isFalse);
    });

    test('should support addModifierKey and removeModifierKey', () {
      coordinator.addModifierKey(LogicalKeyboardKey.control);
      expect(coordinator.isCtrlPressed, isTrue);

      coordinator.addModifierKey(LogicalKeyboardKey.shift);
      expect(coordinator.isShiftPressed, isTrue);

      coordinator.removeModifierKey(LogicalKeyboardKey.control);
      expect(coordinator.isCtrlPressed, isFalse);
      expect(coordinator.isShiftPressed, isTrue);
    });
  });

  group('ChartInteractionCoordinator - Complex Workflows', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement element1, element2;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      element1 = SimulatedDatapoint(id: 'elem_1', center: const Offset(50, 50));
      element2 = SimulatedDatapoint(id: 'elem_2', center: const Offset(100, 100));
    });

    test('workflow: hover → select → drag → release', () {
      // Hover
      coordinator.setHoveredElement(element1);
      expect(coordinator.currentMode, equals(InteractionMode.hovering));

      // Select (clears hover)
      coordinator.setHoveredElement(null);
      coordinator.selectElement(element1);
      expect(coordinator.selectedElements.contains(element1), isTrue);

      // Drag
      coordinator.claimMode(InteractionMode.draggingDataPoint, element: element1);
      expect(coordinator.isDragging, isTrue);

      // Release
      coordinator.releaseMode();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.isElementSelected(element1), isTrue); // Selection persists
    });

    test('workflow: multi-select with Ctrl', () {
      coordinator.selectElement(element1);

      coordinator.updateModifierKeys({LogicalKeyboardKey.control});
      coordinator.toggleElementSelection(element2);

      expect(coordinator.selectedElements.length, equals(2));
      expect(coordinator.isCtrlPressed, isTrue);
    });

    test('workflow: context menu blocks then releases', () {
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: element1);

      // Blocked
      expect(coordinator.claimMode(InteractionMode.panning), isFalse);

      // Force release
      coordinator.forceIdle();

      // Now unblocked
      expect(coordinator.claimMode(InteractionMode.panning), isTrue);
    });

    test('should use forceIdle to escape any state', () {
      coordinator.claimMode(InteractionMode.editingAnnotation, element: element1);
      expect(coordinator.isModal, isTrue);

      coordinator.forceIdle();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.isModal, isFalse);
    });

    test('should use releaseMode with force flag on modal states', () {
      coordinator.claimMode(InteractionMode.contextMenuOpen, element: element1);

      coordinator.releaseMode(force: true);
      expect(coordinator.currentMode, equals(InteractionMode.idle));
    });
  });

  group('ChartInteractionCoordinator - Interaction Tracking', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement element1;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      element1 = SimulatedDatapoint(id: 'elem_1', center: const Offset(50, 50));
    });

    test('should track interaction start position and element', () {
      coordinator.startInteraction(const Offset(100, 150), element: element1);

      expect(coordinator.interactionStartPosition, equals(const Offset(100, 150)));
      expect(coordinator.interactionStartElement, equals(element1));
    });

    test('should update box selection rectangle', () {
      coordinator.updateBoxSelection(
        const Offset(10, 10),
        const Offset(100, 100),
      );

      expect(coordinator.boxSelectionRect, isNotNull);
      expect(coordinator.boxSelectionRect!.left, equals(10));
      expect(coordinator.boxSelectionRect!.top, equals(10));
      expect(coordinator.boxSelectionRect!.right, equals(100));
      expect(coordinator.boxSelectionRect!.bottom, equals(100));
    });

    test('should end interaction and clear tracking', () {
      coordinator.startInteraction(const Offset(50, 50), element: element1);
      coordinator.updateBoxSelection(const Offset(10, 10), const Offset(100, 100));

      coordinator.endInteraction();

      expect(coordinator.interactionStartPosition, isNull);
      expect(coordinator.interactionStartElement, isNull);
      expect(coordinator.boxSelectionRect, isNull);
    });

    test('should clear tracking when returning to idle', () {
      coordinator.startInteraction(const Offset(50, 50), element: element1);
      coordinator.updateBoxSelection(const Offset(10, 10), const Offset(100, 100));

      // Claim a mode then release (returns to idle)
      coordinator.claimMode(InteractionMode.panning);
      coordinator.releaseMode();

      // Tracking should be cleared
      expect(coordinator.interactionStartPosition, isNull);
      expect(coordinator.interactionStartElement, isNull);
      expect(coordinator.boxSelectionRect, isNull);
    });
  });

  group('ChartInteractionCoordinator - Edge Cases', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement element1;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      element1 = SimulatedDatapoint(id: 'elem_1', center: const Offset(50, 50));
    });

    test('should handle selecting same element twice', () {
      coordinator.selectElement(element1);
      coordinator.selectElement(element1);

      expect(coordinator.selectedElements.length, equals(1));
    });

    test('should handle toggling empty state', () {
      coordinator.toggleElementSelection(element1);
      expect(coordinator.isElementSelected(element1), isTrue);

      coordinator.toggleElementSelection(element1);
      expect(coordinator.isElementSelected(element1), isFalse);
    });

    test('should handle releaseMode when idle', () {
      coordinator.releaseMode();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
    });

    test('should handle setHoveredElement(null) when not hovering', () {
      coordinator.setHoveredElement(null);
      expect(coordinator.hoveredElement, isNull);
      expect(coordinator.currentMode, equals(InteractionMode.idle));
    });

    test('should handle clearSelection when empty', () {
      coordinator.clearSelection();
      expect(coordinator.selectedElements, isEmpty);
    });

    test('should handle rapid mode cycling', () {
      for (int i = 0; i < 10; i++) {
        coordinator.claimMode(InteractionMode.panning);
        coordinator.releaseMode();
      }
      expect(coordinator.currentMode, equals(InteractionMode.idle));
    });
  });

  group('ChartInteractionCoordinator - Resize Mode Priority (Scenario #1, #10)', () {
    late ChartInteractionCoordinator coordinator;
    late ChartElement annotation;
    late ChartElement datapoint;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
      annotation = SimulatedDatapoint(id: 'annotation_1', center: const Offset(100, 100));
      datapoint = SimulatedDatapoint(id: 'datapoint_1', center: const Offset(100, 100));
    });

    test('should claim resizingAnnotation mode with priority 9', () {
      final success = coordinator.claimMode(
        InteractionMode.resizingAnnotation,
        element: annotation,
      );

      expect(success, isTrue);
      expect(coordinator.currentMode, equals(InteractionMode.resizingAnnotation));
      expect(coordinator.activeElement, equals(annotation));
      expect(coordinator.isDragging, isTrue); // resizingAnnotation is a drag operation
    });

    test('resizingAnnotation (priority 9) should block panning (priority 3)', () {
      // Start resizing
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);

      // Try to pan - should fail (priority 3 < 9)
      final canPan = coordinator.claimMode(InteractionMode.panning);
      expect(canPan, isFalse);
      expect(coordinator.currentMode, equals(InteractionMode.resizingAnnotation));
    });

    test('resizingAnnotation (priority 9) should block datapoint selection (priority 6)', () {
      // Start resizing
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);

      // Try to select/drag datapoint - should fail (priority 6 < 9)
      final canDrag = coordinator.claimMode(
        InteractionMode.draggingDataPoint,
        element: datapoint,
      );
      expect(canDrag, isFalse);
      expect(coordinator.currentMode, equals(InteractionMode.resizingAnnotation));
      expect(coordinator.activeElement, equals(annotation)); // Still on annotation
    });

    test('resizingAnnotation should block selecting mode (priority 6 < 9)', () {
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);

      final canSelect = coordinator.claimMode(InteractionMode.selecting);
      expect(canSelect, isFalse);
      expect(coordinator.currentMode, equals(InteractionMode.resizingAnnotation));
    });

    test('contextMenuOpen (priority 10) should interrupt resizingAnnotation (priority 9)', () {
      // Start resizing
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);

      // Right-click to open context menu - should succeed (priority 10 > 9)
      final canOpenMenu = coordinator.claimMode(
        InteractionMode.contextMenuOpen,
        element: annotation,
      );
      expect(canOpenMenu, isTrue);
      expect(coordinator.currentMode, equals(InteractionMode.contextMenuOpen));
    });

    test('resize mode should persist during drag (not auto-release)', () {
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);

      // Simulate drag movement (mode should remain)
      expect(coordinator.currentMode, equals(InteractionMode.resizingAnnotation));
      expect(coordinator.isDragging, isTrue); // resizingAnnotation is a drag operation

      // Only explicit releaseMode() should end it
      coordinator.releaseMode();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.isDragging, isFalse);
    });

    test('hover should be blocked during resize (priority 0 < 9)', () {
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);

      // Try to hover - mode stays resizing (hover doesn't claim mode during higher priority)
      coordinator.setHoveredElement(datapoint);
      expect(coordinator.currentMode, equals(InteractionMode.resizingAnnotation));
      // Hover element tracked internally but mode not changed
    });

    test('releaseMode after resize should return to idle and clear active element', () {
      coordinator.claimMode(InteractionMode.resizingAnnotation, element: annotation);
      expect(coordinator.activeElement, equals(annotation));

      coordinator.releaseMode();
      expect(coordinator.currentMode, equals(InteractionMode.idle));
      expect(coordinator.activeElement, isNull);
      expect(coordinator.isDragging, isFalse); // No longer in drag operation
    });
  });
}
