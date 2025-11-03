// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/widgets/annotations/annotation_style.dart';
import 'package:braven_charts/src/widgets/interactions/annotation_style_editor.dart';
import 'package:flutter/material.dart';

import '../annotations/text_annotation.dart';
import '../enums/annotation_anchor.dart';

/// Dialog for creating or editing TextAnnotations.
///
/// TextAnnotations use screen coordinates. The position is automatically
/// set from the right-click location and not editable by the user.
///
/// The dialog is theme-aware and uses Material Design 3 components.
class TextAnnotationDialog extends StatefulWidget {
  /// Creates a dialog for adding/editing TextAnnotations.
  ///
  /// [annotation] - If provided, dialog is in edit mode
  /// [clickPosition] - Screen position where user right-clicked (for add mode)
  const TextAnnotationDialog({
    super.key,
    this.annotation,
    required this.clickPosition,
  });

  final TextAnnotation? annotation;
  final Offset clickPosition;

  @override
  State<TextAnnotationDialog> createState() => _TextAnnotationDialogState();
}

class _TextAnnotationDialogState extends State<TextAnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;

  AnnotationAnchor _anchor = AnnotationAnchor.topLeft;

  // Current annotation style (managed by AnnotationStyleEditor)
  late AnnotationStyle _currentStyle;

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;

    // Initialize text controller
    _textController = TextEditingController(text: annotation?.text ?? '');

    if (annotation != null) {
      _anchor = annotation.anchor;
      _currentStyle = annotation.style;
    } else {
      // Default style for new annotations
      _currentStyle = const AnnotationStyle(
        textStyle: TextStyle(
          color: Colors.black,
          fontSize: 14.0,
        ),
        backgroundColor: Colors.white,
        borderColor: Colors.grey,
        borderWidth: 1.0,
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
        width: 380,
        constraints: const BoxConstraints(maxHeight: 600),
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
                      isEditMode ? Icons.edit : Icons.add_comment,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
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
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          runSpacing: 5,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

    print('📝 [TextAnnotationDialog] Creating annotation:');
    print('   - Text: "$text"');
    print('   - Position (from widget.clickPosition): ${widget.clickPosition}');
    print('   - Anchor: $_anchor');
    print('   - Style: textColor=${_currentStyle.textColor}, fontSize=${_currentStyle.fontSize}');
    print('   - Background: ${_currentStyle.backgroundColor}');
    print('   - Border: color=${_currentStyle.borderColor}, width=${_currentStyle.borderWidth}, radius=${_currentStyle.borderRadius}');

    final annotation = TextAnnotation(
      id: widget.annotation?.id ?? 'text_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      position: widget.clickPosition,
      anchor: _anchor,
      style: _currentStyle,
      backgroundColor: _currentStyle.backgroundColor,
      borderColor: _currentStyle.borderColor,
    );

    print('✅ [TextAnnotationDialog] Annotation created with position: ${annotation.position}');
    Navigator.of(context).pop(annotation);
  }
}
