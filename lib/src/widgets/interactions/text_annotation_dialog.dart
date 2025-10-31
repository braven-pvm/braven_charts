// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/widgets/annotations/annotation_style.dart';
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

  // Styling options
  double _fontSize = 14.0;
  Color _textColor = Colors.black;
  Color? _backgroundColor;
  Color? _borderColor;
  bool _showStyling = false;

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;

    // Initialize text controller
    _textController = TextEditingController(text: annotation?.text ?? '');

    if (annotation != null) {
      _anchor = annotation.anchor;
      _backgroundColor = annotation.backgroundColor;
      _borderColor = annotation.borderColor;

      // Extract font size and color from style if available
      final textStyle = annotation.style.textStyle;
      if (textStyle.fontSize != null) {
        _fontSize = textStyle.fontSize!;
      }
      if (textStyle.color != null) {
        _textColor = textStyle.color!;
      }
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
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                fontWeight: FontWeight.w700,
                fontSize: 12,
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
                  borderRadius: BorderRadius.circular(6),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showStyling = !_showStyling;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _showStyling ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Styling (optional)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_showStyling) ...[
          const SizedBox(height: 12),
          // Font size slider
          Row(
            children: [
              Text(
                'Font Size',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '${_fontSize.toInt()}px',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 8,
            max: 32,
            divisions: 24,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // Color pickers (simple version)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildColorOption('Text', _textColor, (color) {
                setState(() {
                  _textColor = color ?? Colors.black;
                });
              }),
              _buildColorOption('Background', _backgroundColor, (color) {
                setState(() {
                  _backgroundColor = color;
                });
              }, allowNull: true),
              _buildColorOption('Border', _borderColor, (color) {
                setState(() {
                  _borderColor = color;
                });
              }, allowNull: true),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildColorOption(
    String label,
    Color? color,
    void Function(Color?) onChanged, {
    bool allowNull = false,
  }) {
    final presetColors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      if (allowNull) null,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          children: presetColors.map((presetColor) {
            final isSelected = color == presetColor;

            return InkWell(
              onTap: () => onChanged(presetColor),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: presetColor ?? Colors.grey.shade100,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: presetColor == null
                    ? Icon(Icons.clear, size: 14, color: Colors.grey[500])
                    : isSelected
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: presetColor == Colors.white || presetColor == Colors.orange ? Colors.grey[800] : Colors.white,
                          )
                        : null,
              ),
            );
          }).toList(),
        ),
      ],
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

    final annotation = TextAnnotation(
      id: widget.annotation?.id ?? 'text_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      position: widget.clickPosition,
      anchor: _anchor,
      backgroundColor: _backgroundColor,
      style: AnnotationStyle(
          textStyle: TextStyle(
        color: _textColor,
        fontSize: _fontSize,
      )),
      borderColor: _borderColor,
    );

    print('✅ [TextAnnotationDialog] Annotation created with position: ${annotation.position}');
    Navigator.of(context).pop(annotation);
  }
}
