// Copyright (c) 2025 braven_charts. All rights reserved.
// TextAnnotation Dialog for BravenChartPlus

import 'package:flutter/material.dart';

import '../../models/annotation_style.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_theme.dart';
import 'annotation_style_editor.dart';

/// Dialog for creating or editing TextAnnotations in BravenChartPlus.
///
/// TextAnnotations use screen coordinates. The position is automatically
/// set from the right-click location and not editable by the user.
///
/// The dialog is theme-aware and uses Material Design 3 components.
///
/// Example usage:
/// ```dart
/// final result = await showDialog<TextAnnotation>(
///   context: context,
///   builder: (context) => TextAnnotationDialog(
///     clickPosition: Offset(100, 50),
///     chartTheme: myTheme,
///   ),
/// );
/// if (result != null) {
///   annotationController.addAnnotation(result);
/// }
/// ```
class TextAnnotationDialog extends StatefulWidget {
  /// Creates a dialog for adding/editing TextAnnotations.
  ///
  /// [annotation] - If provided, dialog is in edit mode
  /// [clickPosition] - Screen position where user right-clicked (for add mode)
  /// [chartTheme] - Optional chart theme for default styling
  const TextAnnotationDialog({
    super.key,
    this.annotation,
    required this.clickPosition,
    this.chartTheme,
  });

  /// The annotation to edit (null for add mode).
  final TextAnnotation? annotation;

  /// Optional chart theme for default styling.
  final ChartTheme? chartTheme;

  /// The screen position where the user right-clicked.
  final Offset clickPosition;

  @override
  State<TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<TextAnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;

  AnnotationAnchor _anchor = AnnotationAnchor.topLeft;
  bool _allowDragging = true;

  // Current annotation style (managed by AnnotationStyleEditor)
  late AnnotationStyle _currentStyle;

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    final textDefaults = widget.chartTheme?.annotationTheme.textDefaults;

    // Initialize text controller
    _textController = TextEditingController(text: annotation?.text ?? '');

    if (annotation != null) {
      // Edit mode - load existing values
      _anchor = annotation.anchor;
      _allowDragging = annotation.allowDragging;
      _currentStyle = annotation.style;
    } else if (textDefaults != null) {
      // Create mode with theme defaults
      _currentStyle = textDefaults.toAnnotationStyle();
    } else {
      // Fallback defaults (no theme provided)
      _currentStyle = const AnnotationStyle(
        textStyle: TextStyle(
          color: Colors.black,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        borderColor: Colors.grey,
        borderWidth: 1.0,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        padding: EdgeInsets.all(8),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditMode = widget.annotation != null;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Icon(
                      isEditMode ? Icons.edit : Icons.text_fields,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditMode ? 'Edit Text Annotation' : 'Add Text Annotation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Text field
                _buildTextField(),
                const SizedBox(height: 20),

                // Anchor selector
                _buildAnchorSelector(),
                const SizedBox(height: 20),

                // Allow dragging checkbox
                _buildAllowDraggingCheckbox(),
                const SizedBox(height: 20),

                // Styling section
                _buildStylingSection(),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _handleSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(isEditMode ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text *',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Enter annotation text',
            hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w200,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade800, width: 0.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Text is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAnchorSelector() {
    final anchors = [
      AnnotationAnchor.topLeft,
      AnnotationAnchor.topCenter,
      AnnotationAnchor.topRight,
      AnnotationAnchor.centerLeft,
      AnnotationAnchor.center,
      AnnotationAnchor.centerRight,
      AnnotationAnchor.bottomLeft,
      AnnotationAnchor.bottomCenter,
      AnnotationAnchor.bottomRight,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anchor Point',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Determines how the text box aligns to the click position',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: anchors.map((anchor) {
            final isSelected = anchor == _anchor;
            return InkWell(
              onTap: () {
                setState(() {
                  _anchor = anchor;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  _anchorLabel(anchor),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllowDraggingCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _allowDragging,
          onChanged: (value) {
            setState(() {
              _allowDragging = value ?? true;
            });
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allow Dragging',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enable click-and-hold to reposition this annotation',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStylingSection() {
    return AnnotationStyleEditor(
      initialStyle: _currentStyle,
      onStyleChanged: (newStyle) {
        setState(() {
          _currentStyle = newStyle;
        });
      },
      showTextControls: true,
      showBackgroundControls: true,
      showBorderControls: true,
      showPaddingControls: true,
    );
  }

  String _anchorLabel(AnnotationAnchor anchor) {
    switch (anchor) {
      case AnnotationAnchor.topLeft:
        return 'Top Left';
      case AnnotationAnchor.topCenter:
        return 'Top Center';
      case AnnotationAnchor.topRight:
        return 'Top Right';
      case AnnotationAnchor.centerLeft:
        return 'Center Left';
      case AnnotationAnchor.center:
        return 'Center';
      case AnnotationAnchor.centerRight:
        return 'Center Right';
      case AnnotationAnchor.bottomLeft:
        return 'Bottom Left';
      case AnnotationAnchor.bottomCenter:
        return 'Bottom Center';
      case AnnotationAnchor.bottomRight:
        return 'Bottom Right';
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final text = _textController.text.trim();

    final annotation = TextAnnotation(
      id: widget.annotation?.id ?? 'text_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      position: widget.clickPosition,
      anchor: _anchor,
      style: _currentStyle,
      backgroundColor: _currentStyle.backgroundColor,
      borderColor: _currentStyle.borderColor,
      allowDragging: _allowDragging,
      allowEditing: true, // Always allow editing once created
    );

    Navigator.of(context).pop(annotation);
  }
}
