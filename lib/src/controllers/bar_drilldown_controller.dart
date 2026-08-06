import 'package:flutter/foundation.dart';

import '../models/bar_drilldown.dart';

enum BarDrilldownStatus { ready, loading, empty, error }

typedef BarDrilldownResolver =
    Future<List<BarDrillNode>> Function(BarDrillNode node);

/// Owns deterministic, renderer-independent navigation through a bar hierarchy.
final class BarDrilldownController extends ChangeNotifier {
  BarDrilldownController({required BarDrilldownConfig config, this.resolver})
    : _config = config,
      _path = <BarDrillNode>[config.root] {
    _validateUniqueIds(config.root);
  }

  BarDrilldownConfig _config;
  List<BarDrillNode> _path;
  int _requestGeneration = 0;
  Object? _error;
  BarDrillNode? _retryNode;
  BarDrilldownStatus _status = BarDrilldownStatus.ready;
  final Map<String, BarDrillNode> _resolvedNodes = <String, BarDrillNode>{};

  final BarDrilldownResolver? resolver;

  BarDrilldownConfig get config => _config;
  List<BarDrillNode> get path => List.unmodifiable(_path);
  BarDrillNode get current => _path.last;
  BarDrilldownStatus get status => _status;
  Object? get error => _error;
  bool get canGoUp => _path.length > 1;

  void replaceConfig(BarDrilldownConfig config) {
    _validateUniqueIds(config.root);
    _requestGeneration++;
    _config = config;
    _path = <BarDrillNode>[config.root];
    _status = BarDrilldownStatus.ready;
    _error = null;
    _retryNode = null;
    _resolvedNodes.clear();
    notifyListeners();
  }

  Future<bool> drillTo(String nodeId) async {
    final authoredChild = current.children.cast<BarDrillNode?>().firstWhere(
      (node) => node?.id == nodeId,
      orElse: () => null,
    );
    if (authoredChild == null) return false;
    final child = _resolvedNodes[authoredChild.id] ?? authoredChild;

    _path = <BarDrillNode>[..._path, child];
    _status = child.series.isEmpty
        ? BarDrilldownStatus.empty
        : BarDrilldownStatus.ready;
    _error = null;
    _retryNode = null;
    notifyListeners();

    if (child.mayHaveLazyChildren && child.children.isEmpty) {
      await _resolveChildren(child);
    }
    return true;
  }

  bool up() {
    if (!canGoUp) return false;
    _requestGeneration++;
    _path = _path.sublist(0, _path.length - 1);
    _status = current.series.isEmpty
        ? BarDrilldownStatus.empty
        : BarDrilldownStatus.ready;
    _error = null;
    _retryNode = null;
    notifyListeners();
    return true;
  }

  bool navigateToAncestor(String nodeId) {
    final index = _path.indexWhere((node) => node.id == nodeId);
    if (index < 0 || index == _path.length - 1) return false;
    _requestGeneration++;
    _path = _path.sublist(0, index + 1);
    _status = current.series.isEmpty
        ? BarDrilldownStatus.empty
        : BarDrilldownStatus.ready;
    _error = null;
    _retryNode = null;
    notifyListeners();
    return true;
  }

  bool root() => navigateToAncestor(_path.first.id);

  Future<void> retry() async {
    final node = _retryNode;
    if (node != null) await _resolveChildren(node);
  }

  Future<void> _resolveChildren(BarDrillNode node) async {
    final callback = resolver;
    if (callback == null) return;
    final generation = ++_requestGeneration;
    _status = BarDrilldownStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final children = await callback(node);
      if (generation != _requestGeneration || current.id != node.id) return;
      final knownIds = _allIds(_config.root);
      for (final child in children) {
        _validateUniqueIds(child, existingIds: knownIds);
      }
      final resolved = node.copyWith(
        children: List.unmodifiable(children),
        mayHaveLazyChildren: false,
      );
      _resolvedNodes[node.id] = resolved;
      _path = <BarDrillNode>[..._path.take(_path.length - 1), resolved];
      _status = resolved.series.isEmpty
          ? BarDrilldownStatus.empty
          : BarDrilldownStatus.ready;
      _retryNode = null;
    } catch (error) {
      if (generation != _requestGeneration || current.id != node.id) return;
      _status = BarDrilldownStatus.error;
      _error = error;
      _retryNode = node;
    }
    notifyListeners();
  }

  static Set<String> _allIds(BarDrillNode root) {
    final ids = <String>{};
    void visit(BarDrillNode node) {
      ids.add(node.id);
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(root);
    return ids;
  }

  static void _validateUniqueIds(
    BarDrillNode root, {
    Set<String>? existingIds,
  }) {
    final ids = existingIds ?? <String>{};
    void visit(BarDrillNode node) {
      if (!ids.add(node.id)) {
        throw ArgumentError.value(node.id, 'node.id', 'must be unique');
      }
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(root);
  }
}
