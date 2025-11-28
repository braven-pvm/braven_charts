// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/utils/buffer_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for T026: Buffer Management (User Story 2).
///
/// Tests FIFO Queue operations for buffering stream data during interactive mode (FR-006, FR-013, FR-014).
///
/// **Test Scenarios**:
/// 1. Buffer initialization with configurable max size
/// 2. Adding items (addLast)
/// 3. Removing items (removeFirst)
/// 4. FIFO behavior (oldest data discarded first when full)
/// 5. Clearing buffer
/// 6. Length and capacity tracking
/// 7. isFull property
void main() {
  group('T026: BufferManager Tests', () {
    test('BufferManager initializes with correct max size', () {
      final buffer = BufferManager<int>(maxSize: 100);
      expect(buffer.length, 0);
      expect(buffer.maxSize, 100);
      expect(buffer.isEmpty, true);
      expect(buffer.isFull, false);
    });

    test('BufferManager adds items correctly', () {
      final buffer = BufferManager<int>(maxSize: 3);

      buffer.add(1);
      expect(buffer.length, 1);
      expect(buffer.isEmpty, false);

      buffer.add(2);
      expect(buffer.length, 2);

      buffer.add(3);
      expect(buffer.length, 3);
      expect(buffer.isFull, true);
    });

    test('BufferManager discards oldest item when full (FIFO - FR-014)', () {
      final buffer = BufferManager<int>(maxSize: 3);

      // Fill buffer: [1, 2, 3]
      buffer.add(1);
      buffer.add(2);
      buffer.add(3);
      expect(buffer.length, 3);
      expect(buffer.isFull, true);

      // Add 4th item - should discard 1 and contain [2, 3, 4]
      buffer.add(4);
      expect(buffer.length, 3); // Still at max
      expect(buffer.isFull, true);

      // Remove all and verify order
      final items = buffer.removeAll();
      expect(items, [2, 3, 4]); // 1 was discarded (oldest)
    });

    test('BufferManager removeAll returns all items in FIFO order', () {
      final buffer = BufferManager<int>(maxSize: 10);

      buffer.add(10);
      buffer.add(20);
      buffer.add(30);
      buffer.add(40);

      final items = buffer.removeAll();
      expect(items, [10, 20, 30, 40]); // Same order as added
      expect(buffer.length, 0);
      expect(buffer.isEmpty, true);
    });

    test('BufferManager clear empties the buffer', () {
      final buffer = BufferManager<int>(maxSize: 10);

      buffer.add(1);
      buffer.add(2);
      buffer.add(3);
      expect(buffer.length, 3);

      buffer.clear();
      expect(buffer.length, 0);
      expect(buffer.isEmpty, true);
      expect(buffer.isFull, false);
    });

    test('BufferManager handles edge case of maxSize=1', () {
      final buffer = BufferManager<int>(maxSize: 1);
      expect(buffer.maxSize, 1);
      expect(buffer.isFull, false);

      buffer.add(1);
      expect(buffer.length, 1);
      expect(buffer.isFull, true);

      // Adding 2nd item should discard first
      buffer.add(2);
      expect(buffer.length, 1);

      final items = buffer.removeAll();
      expect(items, [2]); // First item (1) was discarded
    });

    test('BufferManager handles single-item capacity', () {
      final buffer = BufferManager<int>(maxSize: 1);

      buffer.add(100);
      expect(buffer.length, 1);
      expect(buffer.isFull, true);

      buffer.add(200); // Should replace 100
      expect(buffer.length, 1);
      expect(buffer.isFull, true);

      final items = buffer.removeAll();
      expect(items, [200]); // Only the latest item
    });

    test('BufferManager works with complex objects', () {
      final buffer = BufferManager<Map<String, dynamic>>(maxSize: 2);

      buffer.add({'x': 1.0, 'y': 10.0});
      buffer.add({'x': 2.0, 'y': 20.0});
      expect(buffer.length, 2);
      expect(buffer.isFull, true);

      buffer.add({'x': 3.0, 'y': 30.0}); // Should discard first item
      expect(buffer.length, 2);

      final items = buffer.removeAll();
      expect(items.length, 2);
      expect(items[0]['x'], 2.0); // First item was discarded
      expect(items[1]['x'], 3.0);
    });

    test('BufferManager removeAll on empty buffer returns empty list', () {
      final buffer = BufferManager<int>(maxSize: 10);
      expect(buffer.isEmpty, true);

      final items = buffer.removeAll();
      expect(items, isEmpty);
      expect(buffer.isEmpty, true);
    });

    test('BufferManager stress test - repeated add/removeAll cycles', () {
      final buffer = BufferManager<int>(maxSize: 5);

      // Cycle 1: Add 5, remove all
      for (int i = 0; i < 5; i++) {
        buffer.add(i);
      }
      expect(buffer.length, 5);
      expect(buffer.isFull, true);

      var items = buffer.removeAll();
      expect(items, [0, 1, 2, 3, 4]);
      expect(buffer.isEmpty, true);

      // Cycle 2: Add 3, remove all
      buffer.add(10);
      buffer.add(20);
      buffer.add(30);
      expect(buffer.length, 3);
      expect(buffer.isFull, false);

      items = buffer.removeAll();
      expect(items, [10, 20, 30]);
      expect(buffer.isEmpty, true);

      // Cycle 3: Add 7 (exceeds capacity), remove all
      for (int i = 100; i < 107; i++) {
        buffer.add(i);
      }
      expect(buffer.length, 5); // Capped at max size
      expect(buffer.isFull, true);

      items = buffer.removeAll();
      expect(items, [102, 103, 104, 105, 106]); // First 2 (100, 101) discarded
      expect(buffer.isEmpty, true);
    });

    test('BufferManager stress test - large capacity (SC-005: 10K points)', () {
      final buffer = BufferManager<int>(maxSize: 10000);

      // Add 15,000 items (exceeds capacity)
      for (int i = 0; i < 15000; i++) {
        buffer.add(i);
      }

      expect(buffer.length, 10000); // Capped at max size
      expect(buffer.isFull, true);

      final items = buffer.removeAll();
      expect(items.length, 10000);
      expect(items.first, 5000); // First 5000 (0-4999) discarded
      expect(items.last, 14999); // Last item is 14999
    });
  });
}
