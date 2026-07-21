import 'dart:math' as math;

import '../controllers/chart_interaction_group_controller.dart';
import 'cartesian_navigator_models.dart';

/// Logical navigator target operated by pointer or keyboard input.
enum CartesianNavigatorTarget { startHandle, window, endHandle }

/// Pure data-space viewport policy shared by every navigator input path.
///
/// This class performs no rendering, controller writes, or data scans. Pointer
/// and keyboard adapters convert their movement to a data-X delta and reduce it
/// through [reduce].
class CartesianNavigatorReducer {
  /// Creates a reducer for one complete X domain.
  CartesianNavigatorReducer({
    required this.fullDomain,
    this.behavior = const CartesianNavigatorBehavior(),
    this.snapPolicy = const CartesianNavigatorSnapPolicy.none(),
  }) {
    if (!fullDomain.isValid) {
      throw ArgumentError.value(
        fullDomain,
        'fullDomain',
        'must be finite and ordered',
      );
    }
    if (!behavior.minimumSpan.isFinite || behavior.minimumSpan < 0) {
      throw ArgumentError.value(
        behavior.minimumSpan,
        'behavior.minimumSpan',
        'must be finite and non-negative',
      );
    }
    if (behavior.minimumSpan > domainSpan) {
      throw ArgumentError.value(
        behavior.minimumSpan,
        'behavior.minimumSpan',
        'must not exceed the full-domain span',
      );
    }
  }

  /// Complete data-X domain displayed by the navigator overview.
  final ChartXViewport fullDomain;

  /// Enabled movement and minimum-span behavior.
  final CartesianNavigatorBehavior behavior;

  /// Active-edge snapping behavior.
  final CartesianNavigatorSnapPolicy snapPolicy;

  double get domainSpan => fullDomain.max - fullDomain.min;

  double get _minimumSpan => math.max(behavior.minimumSpan, domainSpan * 1e-12);

  /// Resolves initialization using controller, caller, then full-domain order.
  ChartXViewport resolveInitialViewport({
    ChartXViewport? groupViewport,
    ChartXViewport? initialViewport,
  }) {
    final candidate = switch ((groupViewport, initialViewport)) {
      (final ChartXViewport group, _) when group.isValid => group,
      (_, final ChartXViewport initial) when initial.isValid => initial,
      _ => fullDomain,
    };
    return reconcile(candidate);
  }

  /// Fits an external or retained viewport into [fullDomain].
  ///
  /// Existing span is preserved where possible. A viewport narrower than the
  /// configured minimum expands around its center before boundary clamping.
  ChartXViewport reconcile(ChartXViewport viewport) {
    if (!viewport.isValid) {
      throw ArgumentError.value(
        viewport,
        'viewport',
        'must be finite and ordered',
      );
    }
    var span = viewport.max - viewport.min;
    if (span >= domainSpan) return fullDomain;

    var min = viewport.min;
    if (span < _minimumSpan) {
      final center = (viewport.min + viewport.max) / 2;
      span = _minimumSpan;
      min = center - (span / 2);
    }
    min = min.clamp(fullDomain.min, fullDomain.max - span).toDouble();
    return ChartXViewport(min: min, max: min + span);
  }

  /// Applies one pointer- or keyboard-derived data-X [delta].
  ChartXViewport reduce({
    required ChartXViewport viewport,
    required CartesianNavigatorTarget target,
    required double delta,
  }) {
    if (!delta.isFinite) {
      throw ArgumentError.value(delta, 'delta', 'must be finite');
    }
    final current = reconcile(viewport);
    return switch (target) {
      CartesianNavigatorTarget.window => _pan(current, delta),
      CartesianNavigatorTarget.startHandle => _resizeStart(current, delta),
      CartesianNavigatorTarget.endHandle => _resizeEnd(current, delta),
    };
  }

  ChartXViewport _pan(ChartXViewport viewport, double delta) {
    if (!behavior.allowPan || delta == 0) return viewport;
    final span = viewport.max - viewport.min;
    var min = _snap(viewport.min + delta);
    min = min.clamp(fullDomain.min, fullDomain.max - span).toDouble();
    return ChartXViewport(min: min, max: min + span);
  }

  ChartXViewport _resizeStart(ChartXViewport viewport, double delta) {
    if (!behavior.allowResize || delta == 0) return viewport;
    var min = _snap(viewport.min + delta);
    min = min.clamp(fullDomain.min, viewport.max - _minimumSpan).toDouble();
    return ChartXViewport(min: min, max: viewport.max);
  }

  ChartXViewport _resizeEnd(ChartXViewport viewport, double delta) {
    if (!behavior.allowResize || delta == 0) return viewport;
    var max = _snap(viewport.max + delta);
    max = max.clamp(viewport.min + _minimumSpan, fullDomain.max).toDouble();
    return ChartXViewport(min: viewport.min, max: max);
  }

  double _snap(double value) => switch (snapPolicy.mode) {
    CartesianNavigatorSnapMode.none => value,
    CartesianNavigatorSnapMode.interval => _snapToInterval(value),
    CartesianNavigatorSnapMode.orderedValues => _snapToOrderedValue(value),
  };

  double _snapToInterval(double value) {
    final interval = snapPolicy.interval!;
    final step = ((value - fullDomain.min) / interval).round();
    return fullDomain.min + (step * interval);
  }

  double _snapToOrderedValue(double value) {
    final values = snapPolicy.values;
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (values[middle] < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low == 0) return values.first;
    if (low == values.length) return values.last;
    final before = values[low - 1];
    final after = values[low];
    return value - before <= after - value ? before : after;
  }
}
