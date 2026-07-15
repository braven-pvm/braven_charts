import 'package:flutter/foundation.dart';

/// View-only table state. Sorting never mutates the source chart document.
class ChartTableController extends ChangeNotifier {
  String? _sortColumnId;
  bool _sortAscending = true;

  String? get sortColumnId => _sortColumnId;
  bool get sortAscending => _sortAscending;

  void sortBy(String columnId) {
    if (_sortColumnId == columnId) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumnId = columnId;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void clearSort() {
    if (_sortColumnId == null) return;
    _sortColumnId = null;
    _sortAscending = true;
    notifyListeners();
  }
}
