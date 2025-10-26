import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Manual test to verify Timer throttling logic works in test environment
void main() {
  test('Timer throttle basic behavior', () async {
    final updateTimes = <int>[];
    final stopwatch = Stopwatch()..start();

    Timer? throttleTimer;
    int? pendingUpdate;

    void sendUpdate(int value) {
      pendingUpdate = value;

      if (throttleTimer == null) {
        // Fire immediately
        updateTimes.add(stopwatch.elapsedMilliseconds);
        print('T=${stopwatch.elapsedMilliseconds}ms: Fired immediate: $value');
        pendingUpdate = null;

        throttleTimer = Timer(const Duration(milliseconds: 16), () {
          if (pendingUpdate != null) {
            updateTimes.add(stopwatch.elapsedMilliseconds);
            print('T=${stopwatch.elapsedMilliseconds}ms: Fired pending: $pendingUpdate');
            pendingUpdate = null;
          }
          throttleTimer = null;
          print('T=${stopwatch.elapsedMilliseconds}ms: Timer cleared');
        });
      } else {
        print('T=${stopwatch.elapsedMilliseconds}ms: Throttled: $value');
      }
    }

    // Send updates rapidly
    for (int i = 0; i < 10; i++) {
      sendUpdate(i);
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // Wait for final timer
    await Future.delayed(const Duration(milliseconds: 20));

    print('Total updates fired: ${updateTimes.length}');
    print('Update times: $updateTimes');

    // Should have ~2-3 updates over ~50ms with 16ms throttle
    expect(updateTimes.length, greaterThan(1));
    expect(updateTimes.length, lessThan(6));
  });
}
