import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../braven_chart_plus.dart';
import '../controllers/chart_interaction_group_controller.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';
import '../models/grid_config.dart';
import '../models/interaction_config.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import '../rendering/chart_render_box.dart';
import 'cartesian_navigator_models.dart';
import 'cartesian_navigator_reducer.dart';

/// A full-domain overview that controls synchronized Cartesian chart viewports.
///
/// The caller-owned [interactionGroupController] is the only viewport
/// authority. The navigator observes it and writes changes through
/// [ChartInteractionGroupController.setViewport]. Its internal overview chart
/// deliberately opts out of both viewport and cursor synchronization, so the
/// overview always shows [fullDomain] and never participates in tracking.
///
/// [overviewSeries] must be one [LineChartSeries] or [AreaChartSeries]. It is a
/// visual summary only; Line, Area, Bar, Scatter, and Candlestick charts can all
/// be controlled when attached to the same interaction group.
class CartesianNavigator extends StatefulWidget {
  const CartesianNavigator({
    super.key,
    required this.interactionGroupController,
    required this.overviewSeries,
    required this.fullDomain,
    this.initialViewport,
    this.behavior = const CartesianNavigatorBehavior(),
    this.snapPolicy = const CartesianNavigatorSnapPolicy.none(),
    this.style = const CartesianNavigatorStyle(),
    this.theme,
    this.height = 96,
    this.enabled = true,
    this.semanticLabel = 'Chart range navigator',
    this.onViewportPreview,
    this.onViewportChanged,
  });

  /// Sole controller used to observe and publish the selected X viewport.
  final ChartInteractionGroupController interactionGroupController;

  /// Full-domain Line or Area series rendered as the overview visual.
  final ChartSeries overviewSeries;

  /// Complete data-X domain retained by the overview chart.
  final ChartXViewport fullDomain;

  /// Initial viewport used only when the group has no valid viewport yet.
  final ChartXViewport? initialViewport;

  /// Enabled gestures, live-preview behavior, and minimum selected span.
  final CartesianNavigatorBehavior behavior;

  /// Active-edge snapping policy.
  final CartesianNavigatorSnapPolicy snapPolicy;

  /// Selection, mask, handle, and interaction-state styling.
  final CartesianNavigatorStyle style;

  /// Optional chart theme for the overview and inherited navigator colors.
  final ChartTheme? theme;

  /// Total navigator height.
  final double height;

  /// Whether pointer, keyboard, and semantic actions can change the viewport.
  final bool enabled;

  /// Accessible name for the complete navigator control.
  final String semanticLabel;

  /// Called for every local pointer or keyboard viewport preview.
  final ValueChanged<ChartXViewport>? onViewportPreview;

  /// Called when a local pointer or keyboard viewport change commits.
  final ValueChanged<ChartXViewport>? onViewportChanged;

  @override
  State<CartesianNavigator> createState() => _CartesianNavigatorState();
}

class _CartesianNavigatorState extends State<CartesianNavigator> {
  static const EdgeInsets _plotInsets = ChartRenderBox.axislessPlotInsets;

  late CartesianNavigatorReducer _reducer;
  late ChartXViewport _viewport;
  final FocusNode _startFocusNode = FocusNode(
    debugLabel: 'Cartesian navigator start edge',
  );
  final FocusNode _windowFocusNode = FocusNode(
    debugLabel: 'Cartesian navigator selected window',
  );
  final FocusNode _endFocusNode = FocusNode(
    debugLabel: 'Cartesian navigator end edge',
  );
  CartesianNavigatorTarget? _hoveredTarget;
  CartesianNavigatorTarget? _pressedTarget;
  CartesianNavigatorTarget? _focusedTarget;
  CartesianNavigatorTarget? _activeTarget;
  ChartXViewport? _gestureStartViewport;
  ChartXViewport? _pendingExternalViewport;
  ChartXViewport? _postFrameExternalViewport;
  double? _dragOriginGlobalX;
  bool _publishingViewport = false;

  bool get _isInteracting => _activeTarget != null;

  @override
  void initState() {
    super.initState();
    _validateWidget(widget);
    _reducer = _buildReducer(widget);
    _viewport = _reducer.resolveInitialViewport(
      groupViewport: widget.interactionGroupController.viewport,
      initialViewport: widget.initialViewport,
    );
    widget.interactionGroupController.viewportListenable.addListener(
      _handleExternalViewport,
    );
    // Publishing while this widget is mounting can notify an ancestor
    // ListenableBuilder during its own build. Defer the initial authority write
    // until the frame is complete; subsequent local interactions still publish
    // synchronously.
    _schedulePublishViewport();
  }

  @override
  void didUpdateWidget(CartesianNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateWidget(widget);
    final controllerChanged =
        oldWidget.interactionGroupController !=
        widget.interactionGroupController;
    final domainChanged = oldWidget.fullDomain != widget.fullDomain;
    if (controllerChanged) {
      oldWidget.interactionGroupController.viewportListenable.removeListener(
        _handleExternalViewport,
      );
    }

    if (controllerChanged || (oldWidget.enabled && !widget.enabled)) {
      _activeTarget = null;
      _pressedTarget = null;
      _gestureStartViewport = null;
      _pendingExternalViewport = null;
      _dragOriginGlobalX = null;
    }
    if (controllerChanged || domainChanged) {
      _postFrameExternalViewport = null;
    }

    _reducer = _buildReducer(widget);
    _viewport = controllerChanged || domainChanged
        ? _reducer.resolveInitialViewport(
            groupViewport: widget.interactionGroupController.viewport,
            initialViewport: widget.initialViewport,
          )
        : _reducer.reconcile(_viewport);
    _gestureStartViewport = _gestureStartViewport == null
        ? null
        : _reducer.reconcile(_gestureStartViewport!);
    _pendingExternalViewport = _pendingExternalViewport == null
        ? null
        : _reducer.reconcile(_pendingExternalViewport!);

    if (controllerChanged) {
      widget.interactionGroupController.viewportListenable.addListener(
        _handleExternalViewport,
      );
    }
    _schedulePublishViewport();
  }

  @override
  void dispose() {
    widget.interactionGroupController.viewportListenable.removeListener(
      _handleExternalViewport,
    );
    _startFocusNode.dispose();
    _windowFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  CartesianNavigatorReducer _buildReducer(CartesianNavigator source) =>
      CartesianNavigatorReducer(
        fullDomain: source.fullDomain,
        behavior: source.behavior,
        snapPolicy: source.snapPolicy,
      );

  void _validateWidget(CartesianNavigator source) {
    if (source.overviewSeries is! LineChartSeries &&
        source.overviewSeries is! AreaChartSeries) {
      throw ArgumentError.value(
        source.overviewSeries,
        'overviewSeries',
        'must be a LineChartSeries or AreaChartSeries',
      );
    }
    if (!source.fullDomain.isValid) {
      throw ArgumentError.value(
        source.fullDomain,
        'fullDomain',
        'must be finite and ordered',
      );
    }
    if (source.initialViewport != null && !source.initialViewport!.isValid) {
      throw ArgumentError.value(
        source.initialViewport,
        'initialViewport',
        'must be finite and ordered',
      );
    }
    final metrics = <String, double>{
      'height': source.height,
      'style.borderWidth': source.style.borderWidth,
      'style.handleVisualWidth': source.style.handleVisualWidth,
      'style.handleVisualHeight': source.style.handleVisualHeight,
      'style.handleHitWidth': source.style.handleHitWidth,
      'style.borderRadius': source.style.borderRadius,
    };
    for (final entry in metrics.entries) {
      if (!entry.value.isFinite || entry.value <= 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'must be finite and greater than zero',
        );
      }
    }
  }

  void _handleExternalViewport() {
    if (_publishingViewport) return;
    final external = widget.interactionGroupController.viewport;
    if (external == null) return;
    final outsideCurrentDomain =
        external.max <= widget.fullDomain.min ||
        external.min >= widget.fullDomain.max;
    if (outsideCurrentDomain) {
      _postFrameExternalViewport = external;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _postFrameExternalViewport == null) return;
        final deferred = _postFrameExternalViewport!;
        _postFrameExternalViewport = null;
        _applyExternalViewport(deferred);
      });
      return;
    }
    _applyExternalViewport(external);
  }

  void _applyExternalViewport(ChartXViewport external) {
    final reconciled = _reducer.reconcile(external);
    if (_isInteracting) {
      _pendingExternalViewport = reconciled;
      return;
    }
    if (reconciled == _viewport || !mounted) return;
    setState(() => _viewport = reconciled);
    if (reconciled != external && !widget.behavior.allowExternalDomainGrowth) {
      _publishViewport(reconciled);
    }
  }

  void _publishViewport(ChartXViewport viewport) {
    if (widget.interactionGroupController.viewport == viewport) return;
    _publishingViewport = true;
    try {
      widget.interactionGroupController.setViewport(viewport);
    } finally {
      _publishingViewport = false;
    }
  }

  void _schedulePublishViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final external = widget.interactionGroupController.viewport;
      if (widget.behavior.allowExternalDomainGrowth &&
          external != null &&
          _reducer.reconcile(external) != external) {
        return;
      }
      _publishViewport(_viewport);
    });
  }

  void _startGesture(CartesianNavigatorTarget target, double globalX) {
    if (!widget.enabled) return;
    setState(() {
      _activeTarget = target;
      _pressedTarget = target;
      _gestureStartViewport = _viewport;
      _pendingExternalViewport = null;
      _dragOriginGlobalX ??= globalX;
    });
  }

  void _updateGesture(
    CartesianNavigatorTarget target,
    double globalX,
    double width,
  ) {
    if (!widget.enabled || _activeTarget != target || width <= 0) return;
    final origin = _dragOriginGlobalX;
    final start = _gestureStartViewport;
    if (origin == null || start == null) return;
    final dataDelta = (globalX - origin) / width * _reducer.domainSpan;
    final next = _reducer.reduce(
      viewport: start,
      target: target,
      delta: dataDelta,
    );
    if (next == _viewport) return;
    setState(() => _viewport = next);
    widget.onViewportPreview?.call(next);
    if (widget.behavior.livePreview) _publishViewport(next);
  }

  void _commitGesture() {
    if (!_isInteracting) return;
    final committed = _viewport;
    final pending = _pendingExternalViewport;
    if (!widget.behavior.livePreview && pending == null) {
      _publishViewport(committed);
    }
    widget.onViewportChanged?.call(committed);
    setState(() {
      _activeTarget = null;
      _pressedTarget = null;
      _gestureStartViewport = null;
      _pendingExternalViewport = null;
      _dragOriginGlobalX = null;
      if (pending != null) _viewport = pending;
    });
    if (pending != null) _publishViewport(pending);
  }

  void _cancelGesture() {
    if (!_isInteracting) return;
    final restored = _pendingExternalViewport ?? _gestureStartViewport!;
    setState(() {
      _viewport = restored;
      _activeTarget = null;
      _pressedTarget = null;
      _gestureStartViewport = null;
      _pendingExternalViewport = null;
      _dragOriginGlobalX = null;
    });
    _publishViewport(restored);
  }

  void _applyKeyboardDelta(CartesianNavigatorTarget target, int direction) {
    if (!widget.enabled) return;
    final delta = _keyboardDelta(target, direction);
    final next = _reducer.reduce(
      viewport: _viewport,
      target: target,
      delta: delta,
    );
    if (next == _viewport) return;
    setState(() => _viewport = next);
    widget.onViewportPreview?.call(next);
    _publishViewport(next);
    widget.onViewportChanged?.call(next);
  }

  double _keyboardDelta(CartesianNavigatorTarget target, int direction) {
    if (widget.snapPolicy.mode == CartesianNavigatorSnapMode.interval) {
      return widget.snapPolicy.interval! * direction;
    }
    if (widget.snapPolicy.mode == CartesianNavigatorSnapMode.orderedValues) {
      final current = switch (target) {
        CartesianNavigatorTarget.startHandle ||
        CartesianNavigatorTarget.window => _viewport.min,
        CartesianNavigatorTarget.endHandle => _viewport.max,
      };
      final values = widget.snapPolicy.values;
      if (direction < 0) {
        for (var index = values.length - 1; index >= 0; index -= 1) {
          if (values[index] < current) return values[index] - current;
        }
      } else {
        for (final value in values) {
          if (value > current) return value - current;
        }
      }
      return direction * _reducer.domainSpan;
    }
    return direction * _reducer.domainSpan / 100;
  }

  KeyEventResult _handleKey(
    CartesianNavigatorTarget target,
    FocusNode _,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _applyKeyboardDelta(target, -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _applyKeyboardDelta(target, 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme =
        widget.theme ??
        (Theme.of(context).brightness == Brightness.dark
            ? ChartTheme.dark
            : ChartTheme.light);
    final style = _ResolvedCartesianNavigatorStyle.resolve(
      context,
      chartTheme,
      widget.style,
    );
    return Semantics(
      key: const ValueKey('cartesian-navigator'),
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: ExcludeSemantics(
                child: _CartesianNavigatorOverviewChart(
                  overviewSeries: widget.overviewSeries,
                  chartTheme: chartTheme,
                  fullDomain: widget.fullDomain,
                  interactionGroupController: widget.interactionGroupController,
                ),
              ),
            ),
            Padding(
              padding: _plotInsets,
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _buildOverlay(constraints.biggest, style),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(Size size, _ResolvedCartesianNavigatorStyle style) {
    if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) {
      return const SizedBox.shrink();
    }
    final startX = _xForValue(_viewport.min, size.width);
    final endX = _xForValue(_viewport.max, size.width);
    final hitWidth = math.min(style.handleHitWidth, size.width);
    final startHitLeft = (startX - hitWidth / 2)
        .clamp(0.0, math.max(0, size.width - hitWidth))
        .toDouble();
    final endHitLeft = (endX - hitWidth / 2)
        .clamp(0.0, math.max(0, size.width - hitWidth))
        .toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            key: const ValueKey('cartesian-navigator-selection'),
            painter: _CartesianNavigatorPainter(
              viewport: _viewport,
              fullDomain: widget.fullDomain,
              style: style,
              hoveredTarget: _hoveredTarget,
              pressedTarget: _pressedTarget,
              focusedTarget: _focusedTarget,
              enabled: widget.enabled,
            ),
          ),
        ),
        Positioned(
          left: startX,
          width: math.max(0, endX - startX),
          top: 0,
          bottom: 0,
          child: _buildTarget(
            key: const ValueKey('cartesian-navigator-window'),
            target: CartesianNavigatorTarget.window,
            focusNode: _windowFocusNode,
            semanticOrdinal: 1,
            width: size.width,
          ),
        ),
        Positioned(
          left: startHitLeft,
          width: hitWidth,
          top: 0,
          bottom: 0,
          child: _buildTarget(
            key: const ValueKey('cartesian-navigator-start-handle'),
            target: CartesianNavigatorTarget.startHandle,
            focusNode: _startFocusNode,
            semanticOrdinal: 0,
            width: size.width,
          ),
        ),
        Positioned(
          left: endHitLeft,
          width: hitWidth,
          top: 0,
          bottom: 0,
          child: _buildTarget(
            key: const ValueKey('cartesian-navigator-end-handle'),
            target: CartesianNavigatorTarget.endHandle,
            focusNode: _endFocusNode,
            semanticOrdinal: 2,
            width: size.width,
          ),
        ),
      ],
    );
  }

  Widget _buildTarget({
    required Key key,
    required CartesianNavigatorTarget target,
    required FocusNode focusNode,
    required double semanticOrdinal,
    required double width,
  }) {
    final label = switch (target) {
      CartesianNavigatorTarget.startHandle => 'Range start',
      CartesianNavigatorTarget.window => 'Selected range',
      CartesianNavigatorTarget.endHandle => 'Range end',
    };
    final value = switch (target) {
      CartesianNavigatorTarget.startHandle => _formatValue(_viewport.min),
      CartesianNavigatorTarget.window =>
        '${_formatValue(_viewport.min)} to ${_formatValue(_viewport.max)}',
      CartesianNavigatorTarget.endHandle => _formatValue(_viewport.max),
    };
    final cursor = target == CartesianNavigatorTarget.window
        ? (_activeTarget == target || _pressedTarget == target
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab)
        : SystemMouseCursors.resizeLeftRight;
    return MouseRegion(
      cursor: widget.enabled ? cursor : SystemMouseCursors.basic,
      onEnter: widget.enabled
          ? (_) => setState(() => _hoveredTarget = target)
          : null,
      onExit: widget.enabled
          ? (_) => setState(() {
              if (_hoveredTarget == target) _hoveredTarget = null;
            })
          : null,
      child: Focus(
        focusNode: focusNode,
        canRequestFocus: widget.enabled,
        onFocusChange: (focused) => setState(() {
          if (focused) {
            _focusedTarget = target;
          } else if (_focusedTarget == target) {
            _focusedTarget = null;
          }
        }),
        onKeyEvent: (node, event) => _handleKey(target, node, event),
        child: Semantics(
          sortKey: OrdinalSortKey(semanticOrdinal),
          container: true,
          focusable: widget.enabled,
          enabled: widget.enabled,
          label: label,
          value: value,
          increasedValue: widget.enabled
              ? _semanticValueAfter(target, 1)
              : null,
          decreasedValue: widget.enabled
              ? _semanticValueAfter(target, -1)
              : null,
          hint: target == CartesianNavigatorTarget.window
              ? 'Drag or use left and right arrow keys to pan'
              : 'Drag or use left and right arrow keys to resize',
          onIncrease: widget.enabled
              ? () => _applyKeyboardDelta(target, 1)
              : null,
          onDecrease: widget.enabled
              ? () => _applyKeyboardDelta(target, -1)
              : null,
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.translucent,
            onTapDown: widget.enabled
                ? (_) {
                    focusNode.requestFocus();
                    setState(() => _pressedTarget = target);
                  }
                : null,
            onTapUp: widget.enabled
                ? (_) => setState(() => _pressedTarget = null)
                : null,
            onTapCancel: widget.enabled
                ? () => setState(() {
                    if (!_isInteracting) _pressedTarget = null;
                  })
                : null,
            onHorizontalDragStart: widget.enabled
                ? (details) {
                    focusNode.requestFocus();
                    _startGesture(target, details.globalPosition.dx);
                  }
                : null,
            onHorizontalDragDown: widget.enabled
                ? (details) {
                    _dragOriginGlobalX = details.globalPosition.dx;
                    setState(() => _pressedTarget = target);
                  }
                : null,
            onHorizontalDragUpdate: widget.enabled
                ? (details) =>
                      _updateGesture(target, details.globalPosition.dx, width)
                : null,
            onHorizontalDragEnd: widget.enabled
                ? (_) => _commitGesture()
                : null,
            onHorizontalDragCancel: widget.enabled ? _cancelGesture : null,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  double _xForValue(double value, double width) =>
      (value - widget.fullDomain.min) / _reducer.domainSpan * width;

  String _semanticValueAfter(CartesianNavigatorTarget target, int direction) {
    final next = _reducer.reduce(
      viewport: _viewport,
      target: target,
      delta: _keyboardDelta(target, direction),
    );
    return switch (target) {
      CartesianNavigatorTarget.startHandle => _formatValue(next.min),
      CartesianNavigatorTarget.window =>
        '${_formatValue(next.min)} to ${_formatValue(next.max)}',
      CartesianNavigatorTarget.endHandle => _formatValue(next.max),
    };
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

/// Keeps the navigator's implementation-only plot distinct from host charts.
///
/// In addition to clarifying diagnostics and widget inspection, this prevents
/// generic host discovery of `BravenChartPlus` instances from treating the
/// full-domain visual summary as another application chart.
class _CartesianNavigatorOverviewChart extends BravenChartPlus {
  _CartesianNavigatorOverviewChart({
    required ChartSeries overviewSeries,
    required ChartTheme chartTheme,
    required ChartXViewport fullDomain,
    required ChartInteractionGroupController interactionGroupController,
  }) : super(
         key: const ValueKey('cartesian-navigator-overview'),
         series: <ChartSeries>[overviewSeries],
         theme: chartTheme,
         showLegend: false,
         interactiveAnnotations: false,
         grid: const GridConfig(horizontal: false, vertical: false),
         xAxisConfig: XAxisConfig(
           min: fullDomain.min,
           max: fullDomain.max,
           visible: false,
           showAxisLine: false,
           showTicks: false,
           showTickLabels: false,
           showCrosshairLabel: false,
         ),
         yAxis: YAxisConfig(
           position: YAxisPosition.hidden,
           visible: false,
           showAxisLine: false,
           showTicks: false,
           showTickLabels: false,
           showCrosshairLabel: false,
         ),
         interactionGroupController: interactionGroupController,
         interactionGroupOptions: const ChartInteractionGroupOptions(
           synchronizeCursor: false,
           synchronizeViewport: false,
         ),
         interactionConfig: const InteractionConfig(
           enableZoom: false,
           enablePan: false,
           crosshair: CrosshairConfig(enabled: false),
           tooltip: TooltipConfig(enabled: false),
         ),
       );
}

class _ResolvedCartesianNavigatorStyle {
  const _ResolvedCartesianNavigatorStyle({
    required this.selectionFillColor,
    required this.selectionBorderColor,
    required this.outsideMaskColor,
    required this.handleColor,
    required this.handleBorderColor,
    required this.hoverOverlayColor,
    required this.pressedOverlayColor,
    required this.focusColor,
    required this.disabledOverlayColor,
    required this.borderWidth,
    required this.handleVisualWidth,
    required this.handleVisualHeight,
    required this.handleHitWidth,
    required this.borderRadius,
  });

  factory _ResolvedCartesianNavigatorStyle.resolve(
    BuildContext context,
    ChartTheme chartTheme,
    CartesianNavigatorStyle style,
  ) {
    final colors = Theme.of(context).colorScheme;
    final accent = chartTheme.focusBorderColor;
    final darkBackground =
        ThemeData.estimateBrightnessForColor(chartTheme.backgroundColor) ==
        Brightness.dark;
    return _ResolvedCartesianNavigatorStyle(
      selectionFillColor:
          style.selectionFillColor ?? accent.withValues(alpha: .14),
      selectionBorderColor: style.selectionBorderColor ?? accent,
      outsideMaskColor:
          style.outsideMaskColor ??
          (darkBackground
              ? Colors.black.withValues(alpha: .32)
              : colors.shadow.withValues(alpha: .12)),
      handleColor: style.handleColor ?? accent,
      handleBorderColor: style.handleBorderColor ?? chartTheme.backgroundColor,
      hoverOverlayColor:
          style.hoverOverlayColor ?? accent.withValues(alpha: .08),
      pressedOverlayColor:
          style.pressedOverlayColor ?? accent.withValues(alpha: .16),
      focusColor: style.focusColor ?? colors.primary,
      disabledOverlayColor:
          style.disabledOverlayColor ??
          colors.surface.withValues(alpha: darkBackground ? .32 : .48),
      borderWidth: style.borderWidth,
      handleVisualWidth: style.handleVisualWidth,
      handleVisualHeight: style.handleVisualHeight,
      handleHitWidth: style.handleHitWidth,
      borderRadius: style.borderRadius,
    );
  }

  final Color selectionFillColor;
  final Color selectionBorderColor;
  final Color outsideMaskColor;
  final Color handleColor;
  final Color handleBorderColor;
  final Color hoverOverlayColor;
  final Color pressedOverlayColor;
  final Color focusColor;
  final Color disabledOverlayColor;
  final double borderWidth;
  final double handleVisualWidth;
  final double handleVisualHeight;
  final double handleHitWidth;
  final double borderRadius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ResolvedCartesianNavigatorStyle &&
          other.selectionFillColor == selectionFillColor &&
          other.selectionBorderColor == selectionBorderColor &&
          other.outsideMaskColor == outsideMaskColor &&
          other.handleColor == handleColor &&
          other.handleBorderColor == handleBorderColor &&
          other.hoverOverlayColor == hoverOverlayColor &&
          other.pressedOverlayColor == pressedOverlayColor &&
          other.focusColor == focusColor &&
          other.disabledOverlayColor == disabledOverlayColor &&
          other.borderWidth == borderWidth &&
          other.handleVisualWidth == handleVisualWidth &&
          other.handleVisualHeight == handleVisualHeight &&
          other.handleHitWidth == handleHitWidth &&
          other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    selectionFillColor,
    selectionBorderColor,
    outsideMaskColor,
    handleColor,
    handleBorderColor,
    hoverOverlayColor,
    pressedOverlayColor,
    focusColor,
    disabledOverlayColor,
    borderWidth,
    handleVisualWidth,
    handleVisualHeight,
    handleHitWidth,
    borderRadius,
  ]);
}

class _CartesianNavigatorPainter extends CustomPainter {
  const _CartesianNavigatorPainter({
    required this.viewport,
    required this.fullDomain,
    required this.style,
    required this.hoveredTarget,
    required this.pressedTarget,
    required this.focusedTarget,
    required this.enabled,
  });

  final ChartXViewport viewport;
  final ChartXViewport fullDomain;
  final _ResolvedCartesianNavigatorStyle style;
  final CartesianNavigatorTarget? hoveredTarget;
  final CartesianNavigatorTarget? pressedTarget;
  final CartesianNavigatorTarget? focusedTarget;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final domainSpan = fullDomain.max - fullDomain.min;
    final left = (viewport.min - fullDomain.min) / domainSpan * size.width;
    final right = (viewport.max - fullDomain.min) / domainSpan * size.width;
    final selection = Rect.fromLTRB(left, 0, right, size.height);
    final selectionRRect = RRect.fromRectAndRadius(
      selection.deflate(style.borderWidth / 2),
      Radius.circular(style.borderRadius),
    );

    final maskPaint = Paint()..color = style.outsideMaskColor;
    if (left > 0) {
      canvas.drawRect(Rect.fromLTRB(0, 0, left, size.height), maskPaint);
    }
    if (right < size.width) {
      canvas.drawRect(
        Rect.fromLTRB(right, 0, size.width, size.height),
        maskPaint,
      );
    }

    canvas.drawRRect(selectionRRect, Paint()..color = style.selectionFillColor);
    final interactionColor = pressedTarget != null
        ? style.pressedOverlayColor
        : hoveredTarget != null
        ? style.hoverOverlayColor
        : null;
    if (interactionColor != null) {
      canvas.drawRRect(selectionRRect, Paint()..color = interactionColor);
    }
    canvas.drawRRect(
      selectionRRect,
      Paint()
        ..color = style.selectionBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.borderWidth,
    );

    _paintHandle(canvas, size, left, CartesianNavigatorTarget.startHandle);
    _paintHandle(canvas, size, right, CartesianNavigatorTarget.endHandle);

    if (focusedTarget != null) {
      final focusRect = switch (focusedTarget!) {
        CartesianNavigatorTarget.window => selection.deflate(2),
        CartesianNavigatorTarget.startHandle => Rect.fromCenter(
          center: Offset(left, size.height / 2),
          width: style.handleVisualWidth + 8,
          height: style.handleVisualHeight + 8,
        ),
        CartesianNavigatorTarget.endHandle => Rect.fromCenter(
          center: Offset(right, size.height / 2),
          width: style.handleVisualWidth + 8,
          height: style.handleVisualHeight + 8,
        ),
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          focusRect,
          Radius.circular(style.borderRadius + 2),
        ),
        Paint()
          ..color = style.focusColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (!enabled) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = style.disabledOverlayColor,
      );
    }
  }

  void _paintHandle(
    Canvas canvas,
    Size size,
    double x,
    CartesianNavigatorTarget target,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(x, size.height / 2),
      width: style.handleVisualWidth,
      height: math.min(style.handleVisualHeight, size.height),
    );
    final color = pressedTarget == target
        ? Color.alphaBlend(style.pressedOverlayColor, style.handleColor)
        : hoveredTarget == target
        ? Color.alphaBlend(style.hoverOverlayColor, style.handleColor)
        : style.handleColor;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.handleVisualWidth / 2),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = style.handleBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CartesianNavigatorPainter oldDelegate) =>
      oldDelegate.viewport != viewport ||
      oldDelegate.fullDomain != fullDomain ||
      oldDelegate.style != style ||
      oldDelegate.hoveredTarget != hoveredTarget ||
      oldDelegate.pressedTarget != pressedTarget ||
      oldDelegate.focusedTarget != focusedTarget ||
      oldDelegate.enabled != enabled;
}
