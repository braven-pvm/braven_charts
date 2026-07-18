import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../table/chart_table_options.dart';

/// Coordinates presentation preferences across a group of chart workbenches.
///
/// Supply this controller explicitly to each `BravenChartWorkbench` or expose
/// it through a [ChartWorkbenchScope]. The controller is caller-owned and must
/// be disposed by the caller.
class ChartWorkbenchGroupController extends ChangeNotifier {
  /// Creates a shared Workbench presentation controller.
  ChartWorkbenchGroupController({
    ChartDisplayMode initialDisplayMode = ChartDisplayMode.chart,
    bool showModeSwitcher = true,
  }) : _displayMode = initialDisplayMode,
       _showModeSwitcher = showModeSwitcher;

  ChartDisplayMode _displayMode;
  bool _showModeSwitcher;
  final Map<Object, Set<ChartDisplayMode>> _members = {};
  bool _membershipNotificationScheduled = false;
  bool _disposed = false;

  /// Display mode requested for every attached Workbench.
  ChartDisplayMode get displayMode => _displayMode;

  /// Whether attached Workbenches may show their package-owned mode selector.
  bool get showModeSwitcher => _showModeSwitcher;

  /// Modes supported by every currently attached Workbench.
  ///
  /// Before a Workbench attaches, every mode is accepted so an application can
  /// establish its initial preference during startup.
  Set<ChartDisplayMode> get availableDisplayModes {
    if (_members.isEmpty) {
      return Set<ChartDisplayMode>.unmodifiable(ChartDisplayMode.values);
    }
    final iterator = _members.values.iterator..moveNext();
    final common = <ChartDisplayMode>{...iterator.current};
    while (iterator.moveNext()) {
      common.retainAll(iterator.current);
    }
    return Set<ChartDisplayMode>.unmodifiable(common);
  }

  /// Requests one shared display mode.
  ///
  /// The request fails without changing the group when any attached Workbench
  /// does not support [mode].
  ChartArtifactResult<ChartDisplayMode> setDisplayMode(ChartDisplayMode mode) {
    if (_members.isNotEmpty && !availableDisplayModes.contains(mode)) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.requestedDisplayModeUnavailable,
          message:
              '${_modeLabel(mode)} mode is not available in every Workbench in this group.',
        ),
      );
    }
    if (_displayMode != mode) {
      _displayMode = mode;
      notifyListeners();
    }
    return ChartArtifactSuccess(value: mode);
  }

  /// Shows or hides the package-owned selector in every attached Workbench.
  ///
  /// A Workbench with `showModeSwitcher: false` remains hidden regardless of
  /// this group preference. Host actions are not affected.
  void setShowModeSwitcher(bool value) {
    if (_showModeSwitcher == value) return;
    _showModeSwitcher = value;
    notifyListeners();
  }

  /// Registers one mounted Workbench. Managed by `BravenChartWorkbench`.
  @internal
  void attachWorkbench(
    Object attachment,
    Set<ChartDisplayMode> availableModes,
  ) {
    _replaceMember(attachment, availableModes);
  }

  /// Updates one mounted Workbench's supported modes.
  @internal
  void updateWorkbench(
    Object attachment,
    Set<ChartDisplayMode> availableModes,
  ) {
    if (!_members.containsKey(attachment)) return;
    _replaceMember(attachment, availableModes);
  }

  /// Removes one mounted Workbench. Managed by `BravenChartWorkbench`.
  @internal
  void detachWorkbench(Object attachment) {
    if (_members.remove(attachment) != null) {
      _scheduleMembershipNotification();
    }
  }

  void _replaceMember(Object attachment, Set<ChartDisplayMode> availableModes) {
    if (availableModes.isEmpty) {
      throw StateError('A grouped Workbench must support at least one mode.');
    }
    final previous = _members[attachment];
    if (previous != null && setEquals(previous, availableModes)) return;
    _members[attachment] = Set<ChartDisplayMode>.unmodifiable(availableModes);
    final common = availableDisplayModes;
    if (common.isEmpty) {
      if (previous == null) {
        _members.remove(attachment);
      } else {
        _members[attachment] = previous;
      }
      throw StateError(
        'Every Workbench in a group must share at least one display mode.',
      );
    }
    if (!common.contains(_displayMode)) {
      _displayMode = common.contains(ChartDisplayMode.chart)
          ? ChartDisplayMode.chart
          : _firstMode(common);
    }
    // Registration occurs from Workbench lifecycle hooks while the subtree may
    // still be building. Keep membership and reconciliation synchronous, then
    // notify inherited consumers after the current frame.
    _scheduleMembershipNotification();
  }

  void _scheduleMembershipNotification() {
    if (_membershipNotificationScheduled || _disposed) return;
    _membershipNotificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _membershipNotificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  static ChartDisplayMode _firstMode(Set<ChartDisplayMode> modes) {
    for (final mode in ChartDisplayMode.values) {
      if (modes.contains(mode)) return mode;
    }
    throw StateError('A Workbench group requires one common display mode.');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Provides a shared Workbench presentation controller to a widget subtree.
///
/// Scopes may be nested. The nearest scope wins unless a Workbench supplies an
/// explicit `groupController`.
class ChartWorkbenchScope
    extends InheritedNotifier<ChartWorkbenchGroupController> {
  /// Creates a Workbench presentation scope.
  const ChartWorkbenchScope({
    super.key,
    required ChartWorkbenchGroupController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns and listens to the nearest shared controller, when present.
  static ChartWorkbenchGroupController? maybeControllerOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<ChartWorkbenchScope>()
      ?.notifier;

  /// Returns and listens to the nearest shared controller.
  static ChartWorkbenchGroupController controllerOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    if (controller == null) {
      throw FlutterError(
        'ChartWorkbenchScope.controllerOf() called without a '
        'ChartWorkbenchScope ancestor.',
      );
    }
    return controller;
  }
}

String _modeLabel(ChartDisplayMode mode) => switch (mode) {
  ChartDisplayMode.chart => 'Chart',
  ChartDisplayMode.data => 'Data',
  ChartDisplayMode.split => 'Split',
  ChartDisplayMode.source => 'Source',
};
