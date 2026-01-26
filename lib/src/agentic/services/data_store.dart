import 'package:uuid/uuid.dart';

class DataStore<T> {
  final Map<String, T> _data = <String, T>{};
  final Uuid _uuid = const Uuid();

  String store(T item, {String? id}) {
    final itemId = id ?? _uuid.v4();
    _data[itemId] = item;
    return itemId;
  }

  T? get(String id) => _data[id];

  bool delete(String id) => _data.remove(id) != null;

  Map<String, T> list() => Map<String, T>.from(_data);
}
