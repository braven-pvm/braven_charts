// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/showcase_preference_store.dart';
import '../platform/showcase_preference_store_contract.dart';

const String showcaseChartPanelHeightDesktopKey =
    'braven_charts.showcase.chart_panel_height.desktop.v1';
const String showcaseChartPanelHeightCompactKey =
    'braven_charts.showcase.chart_panel_height.compact.v1';

String showcaseChartPanelHeightKey({required bool compact}) => compact
    ? showcaseChartPanelHeightCompactKey
    : showcaseChartPanelHeightDesktopKey;

/// Owns a chart-family workspace whose primary panel can be resized.
///
/// With no saved preference the [panel] keeps the page's existing flexible,
/// viewport-derived height. The first resize turns that measured height into an
/// explicit size and allows the workspace to scroll when it exceeds the
/// viewport. Double-clicking the handle or pressing Escape restores the
/// responsive default.
class PersistentResizableChartPanelWorkspace extends StatefulWidget {
  const PersistentResizableChartPanelWorkspace({
    super.key,
    required this.panel,
    required this.preferenceKey,
    this.leading = const [],
    this.trailing = const [],
    this.initialPanelHeight,
    this.minimumPanelHeight = 360,
    this.maximumPanelHeight = 1200,
    this.scrollViewKey,
    this.wrapExplicitContentInScrollView = true,
    this.preferenceStore,
  }) : assert(minimumPanelHeight > 0),
       assert(maximumPanelHeight >= minimumPanelHeight),
       assert(
         initialPanelHeight == null || initialPanelHeight > 0,
         'initialPanelHeight must be positive.',
       );

  final Widget panel;
  final String preferenceKey;
  final List<Widget> leading;
  final List<Widget> trailing;

  /// Used by pages that already had a fixed chart-card height.
  ///
  /// Leave null for the usual viewport-derived flexible height.
  final double? initialPanelHeight;
  final double minimumPanelHeight;
  final double maximumPanelHeight;
  final Key? scrollViewKey;

  /// Disable when this workspace already lives inside a page scroll view.
  final bool wrapExplicitContentInScrollView;

  /// Injection point for deterministic tests. The web default uses
  /// `window.localStorage`; non-web platforms safely use a no-op store.
  final ShowcasePreferenceStore? preferenceStore;

  @override
  State<PersistentResizableChartPanelWorkspace> createState() =>
      _PersistentResizableChartPanelWorkspaceState();
}

class _PersistentResizableChartPanelWorkspaceState
    extends State<PersistentResizableChartPanelWorkspace> {
  final GlobalKey _panelKey = GlobalKey();
  final GlobalKey<_ChartPanelResizeHandleState> _resizeHandleKey =
      GlobalKey<_ChartPanelResizeHandleState>();
  late ShowcasePreferenceStore _store;
  double? _preferredHeight;

  @override
  void initState() {
    super.initState();
    _store = widget.preferenceStore ?? createShowcasePreferenceStore();
    _preferredHeight = _readPreference();
  }

  @override
  void didUpdateWidget(PersistentResizableChartPanelWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final storeChanged = oldWidget.preferenceStore != widget.preferenceStore;
    final keyChanged = oldWidget.preferenceKey != widget.preferenceKey;
    if (storeChanged) {
      _store = widget.preferenceStore ?? createShowcasePreferenceStore();
    }
    if (storeChanged || keyChanged) {
      _preferredHeight = _readPreference();
      return;
    }
    final preferredHeight = _preferredHeight;
    if (preferredHeight != null) {
      _preferredHeight = _clamp(preferredHeight);
    }
  }

  double? _readPreference() {
    final value = double.tryParse(_store.read(widget.preferenceKey) ?? '');
    if (value == null || !value.isFinite || value <= 0) return null;
    return _clamp(value);
  }

  double _clamp(double value) =>
      value.clamp(widget.minimumPanelHeight, widget.maximumPanelHeight);

  double _measuredOrInitialHeight() {
    final measuredHeight = _panelKey.currentContext?.size?.height;
    return _clamp(
      measuredHeight ?? widget.initialPanelHeight ?? widget.minimumPanelHeight,
    );
  }

  void _beginResize() {
    if (_preferredHeight != null) return;
    setState(() => _preferredHeight = _measuredOrInitialHeight());
  }

  void _resizeBy(double delta, {required bool persist}) {
    final currentHeight = _preferredHeight ?? _measuredOrInitialHeight();
    final nextHeight = _clamp(currentHeight + delta);
    if (nextHeight == _preferredHeight) return;
    setState(() => _preferredHeight = nextHeight);
    if (persist) _persist();
  }

  void _resizeTo(double height) {
    final nextHeight = _clamp(height);
    if (nextHeight != _preferredHeight) {
      setState(() => _preferredHeight = nextHeight);
    }
    _persist();
  }

  void _persist() {
    final preferredHeight = _preferredHeight;
    if (preferredHeight == null) return;
    _store.write(widget.preferenceKey, preferredHeight.toStringAsFixed(1));
  }

  void _reset() {
    _store.remove(widget.preferenceKey);
    if (_preferredHeight != null) {
      setState(() => _preferredHeight = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final explicitHeight = _preferredHeight ?? widget.initialPanelHeight;
    final handle = _ChartPanelResizeHandle(
      key: _resizeHandleKey,
      height: explicitHeight,
      minimumHeight: widget.minimumPanelHeight,
      maximumHeight: widget.maximumPanelHeight,
      onDragStart: _beginResize,
      onDragUpdate: (delta) => _resizeBy(delta, persist: false),
      onDragEnd: _persist,
      onResizeBy: (delta) => _resizeBy(delta, persist: true),
      onResizeTo: _resizeTo,
      onReset: _reset,
    );

    if (explicitHeight == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.leading,
          Expanded(
            child: KeyedSubtree(key: _panelKey, child: widget.panel),
          ),
          handle,
          ...widget.trailing,
        ],
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.leading,
        SizedBox(
          key: _panelKey,
          height: _clamp(explicitHeight),
          child: widget.panel,
        ),
        handle,
        ...widget.trailing,
      ],
    );
    if (!widget.wrapExplicitContentInScrollView) return content;
    return SingleChildScrollView(
      key: widget.scrollViewKey,
      primary: false,
      child: content,
    );
  }
}

class _ChartPanelResizeHandle extends StatefulWidget {
  const _ChartPanelResizeHandle({
    super.key,
    required this.height,
    required this.minimumHeight,
    required this.maximumHeight,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onResizeBy,
    required this.onResizeTo,
    required this.onReset,
  });

  final double? height;
  final double minimumHeight;
  final double maximumHeight;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;
  final ValueChanged<double> onResizeBy;
  final ValueChanged<double> onResizeTo;
  final VoidCallback onReset;

  @override
  State<_ChartPanelResizeHandle> createState() =>
      _ChartPanelResizeHandleState();
}

class _ChartPanelResizeHandleState extends State<_ChartPanelResizeHandle> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Showcase chart panel resize handle',
  );
  bool _hovered = false;
  bool _dragging = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final largeStep = HardwareKeyboard.instance.isShiftPressed ? 48.0 : 16.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onResizeBy(-largeStep);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onResizeBy(largeStep);
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      widget.onResizeTo(widget.minimumHeight);
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      widget.onResizeTo(widget.maximumHeight);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onReset();
    } else {
      return KeyEventResult.ignored;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final active = _hovered || _dragging || _focusNode.hasFocus;
    final height = widget.height;
    final value = height == null
        ? 'Automatic height'
        : '${height.round()} pixels high';
    final effectiveHeight = height ?? widget.minimumHeight;
    final increasedValue =
        '${(effectiveHeight + 16).clamp(widget.minimumHeight, widget.maximumHeight).round()} pixels high';
    final decreasedValue =
        '${(effectiveHeight - 16).clamp(widget.minimumHeight, widget.maximumHeight).round()} pixels high';

    return Semantics(
      key: const ValueKey('chart-panel-resize-handle'),
      container: true,
      focusable: true,
      focused: _focusNode.hasFocus,
      label: 'Resize chart panel',
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint:
          'Drag vertically or use the Up and Down arrow keys. '
          'Press Escape or double-click to restore automatic height.',
      onIncrease: () => widget.onResizeBy(16),
      onDecrease: () => widget.onResizeBy(-16),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (_) => setState(() {}),
        onKeyEvent: _handleKey,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Tooltip(
            message: 'Drag to resize chart panel. Double-click to reset.',
            excludeFromSemantics: true,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _focusNode.requestFocus(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _focusNode.requestFocus,
                onDoubleTap: widget.onReset,
                onVerticalDragStart: (_) {
                  _focusNode.requestFocus();
                  setState(() => _dragging = true);
                  widget.onDragStart();
                },
                onVerticalDragUpdate: (details) =>
                    widget.onDragUpdate(details.delta.dy),
                onVerticalDragEnd: (_) {
                  setState(() => _dragging = false);
                  widget.onDragEnd();
                },
                onVerticalDragCancel: () {
                  setState(() => _dragging = false);
                  widget.onDragEnd();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 48,
                  color: _dragging
                      ? colorScheme.primaryContainer.withValues(alpha: 0.22)
                      : Colors.transparent,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 52,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: _focusNode.hasFocus
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: active ? 36 : 30,
                          height: active ? 4 : 3,
                          decoration: BoxDecoration(
                            color: active
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.55,
                                  ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
