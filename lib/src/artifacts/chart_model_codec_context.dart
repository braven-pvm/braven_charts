import 'dart:collection';

import 'chart_data_storage.dart';

/// Shared recursion guard for mutually nested series and annotation codecs.
final class ChartModelCodecContext {
  ChartModelCodecContext({
    this.maxDepth = 64,
    this.dataStorage = ChartDataStorage.inlinePoints,
  });

  final int maxDepth;
  final ChartDataStorage dataStorage;
  final Set<Object> _active = HashSet.identity();
  int _depth = 0;

  void enter(Object value) {
    if (_depth >= maxDepth) {
      throw ChartModelGraphException(
        'Model nesting exceeds the maximum depth of $maxDepth.',
      );
    }
    if (!_active.add(value)) {
      throw const ChartModelGraphException(
        'Cyclic series/annotation model graph cannot be serialized.',
      );
    }
    _depth++;
  }

  void exit(Object value) {
    _active.remove(value);
    _depth--;
  }
}

class ChartModelGraphException implements Exception {
  const ChartModelGraphException(this.message);

  final String message;
}
