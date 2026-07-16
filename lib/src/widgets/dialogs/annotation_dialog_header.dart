import 'package:flutter/material.dart';

/// Shared sticky header for native annotation editors.
class AnnotationDialogHeader extends StatelessWidget {
  const AnnotationDialogHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
  });

  final String title;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerTint = colorScheme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final headerBackground = Color.alphaBlend(headerTint, colorScheme.surface);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 14, 12),
      decoration: BoxDecoration(
        color: headerBackground,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onPrimary,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.onSurface,
              foregroundColor: colorScheme.surface,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}
