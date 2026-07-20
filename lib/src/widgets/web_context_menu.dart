import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-aware native context menu for chart interactions.
class WebContextMenu extends StatefulWidget {
  const WebContextMenu({
    super.key,
    required this.items,
    this.activationAnimation,
  });

  final List<WebContextMenuItem> items;
  final Animation<double>? activationAnimation;

  /// Shows a context menu and returns a dismissible session.
  static WebContextMenuSession show({
    required BuildContext context,
    required Offset position,
    required List<WebContextMenuItem> items,
  }) {
    final navigator = Navigator.of(context);
    final route = _WebContextMenuRoute(position: position, items: items);
    return WebContextMenuSession._(
      route: route,
      selection: navigator.push<String>(route),
    );
  }

  @override
  State<WebContextMenu> createState() => _WebContextMenuState();
}

/// Active menu route that can be dismissed when its owning chart disposes.
class WebContextMenuSession {
  WebContextMenuSession._({required this.route, required this.selection});

  final Route<String> route;
  final Future<String?> selection;

  void dismiss() {
    final navigator = route.navigator;
    if (navigator == null || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop<String>();
    } else {
      navigator.removeRoute(route);
    }
  }
}

class _WebContextMenuState extends State<WebContextMenu> {
  late List<FocusNode> _focusNodes;

  List<WebContextMenuAction> get _actions =>
      widget.items.whereType<WebContextMenuAction>().toList(growable: false);

  @override
  void initState() {
    super.initState();
    _createFocusNodes();
    widget.activationAnimation?.addStatusListener(_handleAnimationStatus);
    if (widget.activationAnimation == null ||
        widget.activationAnimation!.status == AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstEnabled());
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _focusFirstEnabled();
  }

  @override
  void didUpdateWidget(WebContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items == widget.items) return;
    for (final node in _focusNodes) {
      node.dispose();
    }
    _createFocusNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstEnabled());
  }

  void _createFocusNodes() {
    _focusNodes = [
      for (final action in _actions)
        FocusNode(
          debugLabel: 'Chart context action ${action.value}',
          canRequestFocus: action.enabled,
        ),
    ];
  }

  @override
  void dispose() {
    widget.activationAnimation?.removeStatusListener(_handleAnimationStatus);
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _focusFirstEnabled() {
    if (!mounted) return;
    final index = _actions.indexWhere((action) => action.enabled);
    if (index >= 0) _focusNodes[index].requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) =>
      _handleMenuKeyEvent(event);

  KeyEventResult _handleMenuKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop<String>();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _focusBoundary(first: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _focusBoundary(first: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveFocus(int delta) {
    if (_focusNodes.isEmpty) return;
    var current = _focusNodes.indexWhere((node) => node.hasFocus);
    for (var step = 0; step < _focusNodes.length; step++) {
      current = (current + delta) % _focusNodes.length;
      if (current < 0) current += _focusNodes.length;
      if (_actions[current].enabled) {
        _focusNodes[current].requestFocus();
        return;
      }
    }
  }

  void _focusBoundary({required bool first}) {
    final indices = first
        ? Iterable<int>.generate(_actions.length)
        : Iterable<int>.generate(
            _actions.length,
            (index) => _actions.length - index - 1,
          );
    for (final index in indices) {
      if (_actions[index].enabled) {
        _focusNodes[index].requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    var actionIndex = 0;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 208, maxWidth: 320),
            child: Material(
              color: colors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in widget.items)
                      if (item is WebContextMenuDivider)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.outlineVariant,
                        )
                      else if (item is WebContextMenuAction)
                        _WebContextMenuItemWidget(
                          item: item,
                          focusNode: _focusNodes[actionIndex++],
                          onMenuKeyEvent: _handleMenuKeyEvent,
                          onSelected: () =>
                              Navigator.of(context).pop(item.value),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

sealed class WebContextMenuItem {
  const WebContextMenuItem();
}

class WebContextMenuDivider extends WebContextMenuItem {
  const WebContextMenuDivider();
}

class WebContextMenuAction extends WebContextMenuItem {
  const WebContextMenuAction({
    required this.value,
    required this.label,
    this.icon,
    this.shortcut,
    this.enabled = true,
    this.destructive = false,
    this.semanticLabel,
  });

  final String value;
  final IconData? icon;
  final String label;
  final String? shortcut;
  final bool enabled;
  final bool destructive;
  final String? semanticLabel;
}

class _WebContextMenuItemWidget extends StatefulWidget {
  const _WebContextMenuItemWidget({
    required this.item,
    required this.focusNode,
    required this.onMenuKeyEvent,
    required this.onSelected,
  });

  final WebContextMenuAction item;
  final FocusNode focusNode;
  final KeyEventResult Function(KeyEvent event) onMenuKeyEvent;
  final VoidCallback onSelected;

  @override
  State<_WebContextMenuItemWidget> createState() =>
      _WebContextMenuItemWidgetState();
}

class _WebContextMenuItemWidgetState extends State<_WebContextMenuItemWidget> {
  bool _hovered = false;
  bool _focused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final menuResult = widget.onMenuKeyEvent(event);
    if (menuResult == KeyEventResult.handled) return menuResult;
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.item.enabled;
    final foreground = widget.item.destructive
        ? colors.error
        : colors.onSurface;
    final effectiveForeground = enabled
        ? foreground
        : colors.onSurface.withValues(alpha: 0.38);
    final highlighted = enabled && (_hovered || _focused);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.item.semanticLabel ?? widget.item.label,
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: InkWell(
            onTap: enabled ? widget.onSelected : null,
            canRequestFocus: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: highlighted
                    ? colors.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                border: _focused
                    ? Border.all(color: colors.primary, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: widget.item.icon == null
                        ? null
                        : Icon(
                            widget.item.icon,
                            size: 20,
                            color: effectiveForeground,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: effectiveForeground,
                      ),
                    ),
                  ),
                  if (widget.item.shortcut != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      widget.item.shortcut!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebContextMenuRoute extends PopupRoute<String> {
  _WebContextMenuRoute({required this.position, required this.items});

  final Offset position;
  final List<WebContextMenuItem> items;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss chart context menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 75);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SafeArea(
      child: CustomSingleChildLayout(
        delegate: _ContextMenuLayoutDelegate(position),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: WebContextMenu(items: items, activationAnimation: animation),
        ),
      ),
    );
  }
}

class _ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _ContextMenuLayoutDelegate(this.preferredPosition);

  static const double _viewportPadding = 8;
  final Offset preferredPosition;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: (constraints.maxWidth - (_viewportPadding * 2)).clamp(0, 320),
        maxHeight: (constraints.maxHeight - (_viewportPadding * 2)).clamp(
          0,
          double.infinity,
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    preferredPosition.dx.clamp(
      _viewportPadding,
      (size.width - childSize.width - _viewportPadding).clamp(
        _viewportPadding,
        double.infinity,
      ),
    ),
    preferredPosition.dy.clamp(
      _viewportPadding,
      (size.height - childSize.height - _viewportPadding).clamp(
        _viewportPadding,
        double.infinity,
      ),
    ),
  );

  @override
  bool shouldRelayout(_ContextMenuLayoutDelegate oldDelegate) =>
      preferredPosition != oldDelegate.preferredPosition;
}
