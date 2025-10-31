// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../annotations/text_annotation.dart';
import 'text_annotation_dialog.dart';

/// Context menu for annotation management via right-click.
///
/// Displays contextual menu options based on what was clicked:
/// - Empty chart area: "Add Text Annotation"
/// - Existing annotation: "Edit Annotation", "Delete Annotation"
class AnnotationContextMenu {
  /// Shows a context menu at the specified position.
  ///
  /// [context] - BuildContext for showing the menu
  /// [position] - Global position where user right-clicked
  /// [localPosition] - Local position within the chart widget
  /// [existingAnnotation] - If user clicked on existing annotation, pass it here
  /// [availableSeriesIds] - List of series IDs for data-position mode
  /// [onSave] - Callback when annotation is saved (add or update)
  /// [onDelete] - Callback when annotation is deleted
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required Offset localPosition,
    TextAnnotation? existingAnnotation,
    required List<String> availableSeriesIds,
    required void Function(TextAnnotation) onSave,
    void Function(String annotationId)? onDelete,
  }) async {
    print('📋 [AnnotationContextMenu] show() called:');
    print('   - position (global): $position');
    print('   - localPosition: $localPosition');

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect menuPosition = RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 8,
      color: Colors.white,
      menuPadding: const EdgeInsets.all(0),
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black,
      constraints: const BoxConstraints(
        minWidth: 140,
        maxWidth: 160,
      ),
      items: existingAnnotation != null ? _buildEditMenuItems(context) : _buildAddMenuItems(context),
    );

    if (!context.mounted) return;

    switch (result) {
      case 'add':
        await _showAddDialog(
          context: context,
          localPosition: localPosition,
          availableSeriesIds: availableSeriesIds,
          onSave: onSave,
        );
        break;
      case 'edit':
        if (existingAnnotation != null) {
          await _showEditDialog(
            context: context,
            annotation: existingAnnotation,
            availableSeriesIds: availableSeriesIds,
            onSave: onSave,
          );
        }
        break;
      case 'delete':
        if (existingAnnotation != null && onDelete != null) {
          onDelete(existingAnnotation.id);
        }
        break;
    }
  }

  static List<PopupMenuEntry<String>> _buildAddMenuItems(BuildContext context) {
    return [
      PopupMenuItem<String>(
        value: 'add',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_comment_outlined,
              size: 16,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 10),
            Text(
              'Add Annotation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static List<PopupMenuEntry<String>> _buildEditMenuItems(BuildContext context) {
    return [
      PopupMenuItem<String>(
        value: 'edit',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 10),
            Text(
              'Edit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      PopupMenuDivider(
        height: 0.5,
        color: Colors.grey.shade300,
      ),
      PopupMenuItem<String>(
        value: 'delete',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.red[400],
            ),
            const SizedBox(width: 10),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[400],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static Future<void> _showAddDialog({
    required BuildContext context,
    required Offset localPosition,
    required List<String> availableSeriesIds,
    required void Function(TextAnnotation) onSave,
  }) async {
    print('💬 [AnnotationContextMenu] _showAddDialog called with localPosition: $localPosition');

    final annotation = await showDialog<TextAnnotation>(
      context: context,
      builder: (ctx) => TextAnnotationDialog(
        clickPosition: localPosition,
      ),
    );

    if (annotation != null) {
      print('✅ [AnnotationContextMenu] Annotation returned from dialog: ${annotation.position}');
      onSave(annotation);
    }
  }

  static Future<void> _showEditDialog({
    required BuildContext context,
    required TextAnnotation annotation,
    required List<String> availableSeriesIds,
    required void Function(TextAnnotation) onSave,
  }) async {
    final updatedAnnotation = await showDialog<TextAnnotation>(
      context: context,
      builder: (ctx) => TextAnnotationDialog(
        annotation: annotation,
        clickPosition: annotation.position,
      ),
    );

    if (updatedAnnotation != null) {
      onSave(updatedAnnotation);
    }
  }
}
