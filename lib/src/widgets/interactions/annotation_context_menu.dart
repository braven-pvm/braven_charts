// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../annotations/point_annotation.dart';
import '../annotations/text_annotation.dart';
import 'point_annotation_dialog.dart';
import 'text_annotation_dialog.dart';

/// Type of annotation context menu to show
enum AnnotationContextType {
  /// Menu for adding/editing text annotations (chart-level)
  textAnnotation,

  /// Menu for adding/editing point annotations (series-level)
  pointAnnotation,
}

/// Context menu for annotation management via right-click.
///
/// Displays contextual menu options based on what was clicked:
/// - Empty chart area: "Add Text Annotation"
/// - Data point: "Add Point Annotation"
/// - Existing annotation: "Edit Annotation", "Delete Annotation"
class AnnotationContextMenu {
  /// Shows a context menu at the specified position.
  ///
  /// [context] - BuildContext for showing the menu
  /// [position] - Global position where user right-clicked
  /// [localPosition] - Local position within the chart widget
  /// [contextType] - Type of annotation context (text vs point)
  /// [existingTextAnnotation] - If user clicked on existing text annotation
  /// [existingPointAnnotation] - If user clicked on existing point annotation
  /// [seriesId] - Series ID for point annotations
  /// [dataPointIndex] - Data point index for point annotations
  /// [availableSeriesIds] - List of series IDs for data-position mode
  /// [onSaveTextAnnotation] - Callback when text annotation is saved
  /// [onSavePointAnnotation] - Callback when point annotation is saved
  /// [onDeleteTextAnnotation] - Callback when text annotation is deleted
  /// [onDeletePointAnnotation] - Callback when point annotation is deleted
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required Offset localPosition,
    required AnnotationContextType contextType,
    TextAnnotation? existingTextAnnotation,
    PointAnnotation? existingPointAnnotation,
    String? seriesId,
    int? dataPointIndex,
    required List<String> availableSeriesIds,
    required void Function(TextAnnotation) onSaveTextAnnotation,
    void Function(PointAnnotation)? onSavePointAnnotation,
    void Function(String annotationId)? onDeleteTextAnnotation,
    void Function(String seriesId, String annotationId)? onDeletePointAnnotation,
  }) async {
    print('📋 [AnnotationContextMenu] show() called:');
    print('   - position (global): $position');
    print('   - localPosition: $localPosition');
    print('   - contextType: $contextType');

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect menuPosition = RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    // Determine if we're editing or adding
    final isEditMode = existingTextAnnotation != null || existingPointAnnotation != null;

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
        maxWidth: 180,
      ),
      items: isEditMode ? _buildEditMenuItems(context, contextType) : _buildAddMenuItems(context, contextType),
    );

    if (!context.mounted) return;

    switch (result) {
      case 'add_text':
        await _showAddTextDialog(
          context: context,
          localPosition: localPosition,
          availableSeriesIds: availableSeriesIds,
          onSave: onSaveTextAnnotation,
        );
        break;
      case 'add_point':
        if (seriesId != null && dataPointIndex != null && onSavePointAnnotation != null) {
          await _showAddPointDialog(
            context: context,
            seriesId: seriesId,
            dataPointIndex: dataPointIndex,
            onSave: onSavePointAnnotation,
          );
        }
        break;
      case 'edit':
        if (existingTextAnnotation != null) {
          await _showEditTextDialog(
            context: context,
            annotation: existingTextAnnotation,
            availableSeriesIds: availableSeriesIds,
            onSave: onSaveTextAnnotation,
          );
        } else if (existingPointAnnotation != null && onSavePointAnnotation != null) {
          await _showEditPointDialog(
            context: context,
            annotation: existingPointAnnotation,
            onSave: onSavePointAnnotation,
          );
        }
        break;
      case 'delete':
        if (existingTextAnnotation != null && onDeleteTextAnnotation != null) {
          onDeleteTextAnnotation(existingTextAnnotation.id);
        } else if (existingPointAnnotation != null && onDeletePointAnnotation != null) {
          onDeletePointAnnotation(existingPointAnnotation.seriesId, existingPointAnnotation.id);
        }
        break;
    }
  }

  static List<PopupMenuEntry<String>> _buildAddMenuItems(BuildContext context, AnnotationContextType contextType) {
    final isPointContext = contextType == AnnotationContextType.pointAnnotation;

    return [
      PopupMenuItem<String>(
        value: isPointContext ? 'add_point' : 'add_text',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPointContext ? Icons.place : Icons.add_comment_outlined,
              size: 16,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 10),
            Text(
              isPointContext ? 'Add Point Annotation' : 'Add Text Annotation',
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

  static List<PopupMenuEntry<String>> _buildEditMenuItems(BuildContext context, AnnotationContextType contextType) {
    final isPointContext = contextType == AnnotationContextType.pointAnnotation;

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
              isPointContext ? 'Edit Point Annotation' : 'Edit Annotation',
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

  static Future<void> _showAddTextDialog({
    required BuildContext context,
    required Offset localPosition,
    required List<String> availableSeriesIds,
    required void Function(TextAnnotation) onSave,
  }) async {
    print('💬 [AnnotationContextMenu] _showAddTextDialog called with localPosition: $localPosition');

    final annotation = await showDialog<TextAnnotation>(
      context: context,
      builder: (ctx) => TextAnnotationDialog(
        clickPosition: localPosition,
      ),
    );

    if (annotation != null) {
      print('✅ [AnnotationContextMenu] Text annotation returned from dialog: ${annotation.position}');
      onSave(annotation);
    }
  }

  static Future<void> _showAddPointDialog({
    required BuildContext context,
    required String seriesId,
    required int dataPointIndex,
    required void Function(PointAnnotation) onSave,
  }) async {
    print('📍 [AnnotationContextMenu] _showAddPointDialog called:');
    print('   - seriesId: $seriesId');
    print('   - dataPointIndex: $dataPointIndex');

    final annotation = await showDialog<PointAnnotation>(
      context: context,
      builder: (ctx) => PointAnnotationDialog(
        seriesId: seriesId,
        dataPointIndex: dataPointIndex,
      ),
    );

    if (annotation != null) {
      print('✅ [AnnotationContextMenu] Point annotation returned from dialog');
      onSave(annotation);
    }
  }

  static Future<void> _showEditTextDialog({
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

  static Future<void> _showEditPointDialog({
    required BuildContext context,
    required PointAnnotation annotation,
    required void Function(PointAnnotation) onSave,
  }) async {
    final updatedAnnotation = await showDialog<PointAnnotation>(
      context: context,
      builder: (ctx) => PointAnnotationDialog(
        annotation: annotation,
        seriesId: annotation.seriesId,
        dataPointIndex: annotation.dataPointIndex,
      ),
    );

    if (updatedAnnotation != null) {
      onSave(updatedAnnotation);
    }
  }
}
