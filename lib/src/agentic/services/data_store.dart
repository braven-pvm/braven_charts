import 'package:uuid/uuid.dart';

import '../models/chart_configuration.dart';

class DataStore<T> {
  final Map<String, T> _data = <String, T>{};
  final Uuid _uuid = const Uuid();

  String store(T item, {String? id}) {
    final itemId = id ?? _uuid.v4();

    // CRITICAL: If storing a ChartConfiguration, ensure its ID matches the storage key
    // This ensures the object and its storage location have the same ID
    if (item is ChartConfiguration && item.id != itemId) {
      final chartWithId = item.copyWith(id: itemId);
      _data[itemId] = chartWithId as T;
    } else {
      _data[itemId] = item;
    }

    return itemId;
  }

  T? get(String id) => _data[id];

  bool delete(String id) => _data.remove(id) != null;

  Map<String, T> list() => Map<String, T>.from(_data);
}
