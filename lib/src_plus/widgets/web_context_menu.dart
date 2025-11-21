// Copyright (c) 2025 braven_charts. All rights reserved.
// Web-native context menu widget for chart interactions

import 'package:flutter/material.dart';

/// Web-native context menu that matches browser/desktop app styling.
///
/// Features:
/// - Flat design with subtle border (no elevation)
/// - Compact spacing for web-first design
/// - Left-aligned icons with consistent spacing
/// - Hover states with subtle background
/// - Support for dividers and disabled items
/// - Optional keyboard shortcuts display
class WebContextMenu extends StatelessWidget {
  const WebContextMenu({
    super.key,
    required this.items,
    this.onDismiss,
  });
  final List<WebContextMenuItem> items;
  final VoidCallback? onDismiss;

  /// Show the context menu at the specified global position.
  /// Returns the selected action value, or null if dismissed.
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required List<WebContextMenuItem> items,
  }) {
    return Navigator.of(context).push(
      _WebContextMenuRoute(
        position: position,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 300,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items.map((item) {
            if (item is WebContextMenuDivider) {
              return const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE0E0E0),
              );
            } else if (item is WebContextMenuAction) {
              return _WebContextMenuItemWidget(
                item: item,
                onTap: () {
                  Navigator.of(context).pop(item.value);
                },
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
    );
  }
}

/// Base class for context menu items
sealed class WebContextMenuItem {
  const WebContextMenuItem();
}

/// Divider line between menu sections
class WebContextMenuDivider extends WebContextMenuItem {
  const WebContextMenuDivider();
}

/// Actionable menu item with icon, label, and optional keyboard shortcut
class WebContextMenuAction extends WebContextMenuItem {
  const WebContextMenuAction({
    required this.value,
    required this.label,
    this.icon,
    this.shortcut,
    this.enabled = true,
    this.iconColor,
    this.textColor,
  });
  final String value;
  final IconData? icon;
  final String label;
  final String? shortcut;
  final bool enabled;
  final Color? iconColor;
  final Color? textColor;
}

/// Individual menu item widget with hover state
class _WebContextMenuItemWidget extends StatefulWidget {
  const _WebContextMenuItemWidget({
    required this.item,
    required this.onTap,
  });
  final WebContextMenuAction item;
  final VoidCallback onTap;

  @override
  State<_WebContextMenuItemWidget> createState() => _WebContextMenuItemWidgetState();
}

class _WebContextMenuItemWidgetState extends State<_WebContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.item.enabled;
    final baseTextColor = widget.item.textColor ?? const Color(0xFF333333);
    final textColor = isEnabled ? baseTextColor : const Color(0xFFAAAAAA);
    final iconColor = widget.item.iconColor ?? const Color(0xFF666666);
    final finalIconColor = isEnabled ? iconColor : const Color(0xFFCCCCCC);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEnabled ? widget.onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered && isEnabled ? const Color(0xFFF5F5F5) : Colors.transparent,
          ),
          child: Row(
            children: [
              // Icon (18px with 8px right margin)
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 18,
                  color: finalIconColor,
                ),
                const SizedBox(width: 8),
              ] else ...[
                // Spacer for alignment when no icon
                const SizedBox(width: 26),
              ],

              // Label
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              // Keyboard shortcut (if provided)
              if (widget.item.shortcut != null) ...[
                const SizedBox(width: 16),
                Text(
                  widget.item.shortcut!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Route for displaying the context menu as an overlay
class _WebContextMenuRoute extends PopupRoute<String> {
  _WebContextMenuRoute({
    required this.position,
    required this.items,
  });
  final Offset position;
  final List<WebContextMenuItem> items;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 75);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: Material(
                color: Colors.transparent,
                child: WebContextMenu(
                  items: items,
                  onDismiss: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
