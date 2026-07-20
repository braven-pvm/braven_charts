import 'package:flutter/widgets.dart';

import '../models/chart_context_action.dart';

/// Package-private propagation of Workbench host actions to its mounted chart.
class ChartWorkbenchContextActionScope extends InheritedWidget {
  const ChartWorkbenchContextActionScope({
    super.key,
    required this.actionsBuilder,
    required this.overlayActionBuilder,
    required this.overlayActionConfig,
    required this.actionListenable,
    required super.child,
  });

  final ChartContextActionsBuilder? actionsBuilder;
  final ChartOverlayActionBuilder? overlayActionBuilder;
  final ChartOverlayActionButtonConfig overlayActionConfig;
  final Listenable? actionListenable;

  static ChartWorkbenchContextActionScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ChartWorkbenchContextActionScope>();

  static ChartWorkbenchContextActionScope? dependOn(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<ChartWorkbenchContextActionScope>();

  @override
  bool updateShouldNotify(ChartWorkbenchContextActionScope oldWidget) =>
      actionsBuilder != oldWidget.actionsBuilder ||
      overlayActionBuilder != oldWidget.overlayActionBuilder ||
      overlayActionConfig != oldWidget.overlayActionConfig ||
      actionListenable != oldWidget.actionListenable;
}
