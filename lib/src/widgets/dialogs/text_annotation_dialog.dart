// Copyright (c) 2025 braven_charts. All rights reserved.
// TextAnnotation Dialog for BravenChartPlus

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import '../../models/annotation_style.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_theme.dart';
import 'annotation_style_editor.dart';

/// Text editing mode for TextAnnotationDialog.
enum TextEditMode {
  /// Simple plain text mode using TextFormField.
  simple,

  /// Rich text mode using Fleather editor with formatting toolbar.
  rich,
}

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

  /// Fleather controller for rich text editing.
  late FleatherController _fleatherController;

  /// Current text editing mode.
  late TextEditMode _editMode;

  AnnotationAnchor _anchor = AnnotationAnchor.topLeft;
  bool _allowDragging = true;

  // Current annotation style (managed by AnnotationStyleEditor)
  late AnnotationStyle _currentStyle;

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    final textDefaults = widget.chartTheme?.annotationTheme.textDefaults;

    // Determine initial mode based on existing annotation
    if (annotation != null && annotation.isRichText) {
      _editMode = TextEditMode.rich;
    } else {
      _editMode = TextEditMode.simple;
    }

    // Initialize text controller for simple mode
    _textController = TextEditingController(text: annotation?.plainText ?? '');

    // Initialize Fleather controller for rich text mode
    if (annotation != null && annotation.isRichText) {
      _fleatherController = FleatherController(
        document: annotation.toParchmentDocument(),
      );
    } else if (annotation != null) {
      // Convert plain text to Parchment document
      _fleatherController = FleatherController(
        document: ParchmentDocument.fromDelta(
          Delta()..insert('${annotation.text ?? ''}\n'),
        ),
      );
    } else {
      // New empty document
      _fleatherController = FleatherController(document: ParchmentDocument());
    }

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
    _fleatherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditMode = widget.annotation != null;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      isEditMode
                          ? 'Edit Text Annotation'
                          : 'Add Text Annotation',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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
        // Label with mode toggle
        Row(
          children: [
            Text(
              'Text *',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            // Mode toggle
            _buildModeToggle(),
          ],
        ),
        const SizedBox(height: 8),
        // Show either simple or rich text editor based on mode
        if (_editMode == TextEditMode.simple)
          _buildSimpleTextEditor()
        else
          _buildRichTextEditor(),
      ],
    );
  }

  /// Builds the Simple/Rich mode toggle buttons.
  Widget _buildModeToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeButton(
          label: 'Simple',
          icon: Icons.text_fields,
          mode: TextEditMode.simple,
        ),
        const SizedBox(width: 4),
        _buildModeButton(
          label: 'Rich',
          icon: Icons.format_bold,
          mode: TextEditMode.rich,
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required TextEditMode mode,
  }) {
    final isSelected = _editMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _switchMode(mode),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Switches between Simple and Rich text modes.
  void _switchMode(TextEditMode newMode) {
    if (_editMode == newMode) return;

    setState(() {
      if (newMode == TextEditMode.rich) {
        // Switching from Simple to Rich: copy text to Fleather
        final currentText = _textController.text;
        _fleatherController = FleatherController(
          document: ParchmentDocument.fromDelta(
            Delta()..insert('$currentText\n'),
          ),
        );
      } else {
        // Switching from Rich to Simple: extract plain text
        final plainText = _fleatherController.document.toPlainText().trim();
        _textController.text = plainText;
      }
      _editMode = newMode;
    });
  }

  /// Builds the simple plain text editor.
  Widget _buildSimpleTextEditor() {
    return TextFormField(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
      maxLines: 3,
      validator: (value) {
        if (_editMode == TextEditMode.simple &&
            (value == null || value.trim().isEmpty)) {
          return 'Text is required';
        }
        return null;
      },
    );
  }

  /// Builds the rich text editor with Fleather toolbar.
  Widget _buildRichTextEditor() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Fleather Toolbar - Customized for annotations
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: FleatherToolbar.basic(
              controller: _fleatherController,
              // Hide buttons not useful for chart annotations
              hideDirection: true, // RTL not needed
              hideAlignment: true, // Text alignment not needed
              hideIndentation: true, // Indentation not needed
              hideListNumbers: true, // Lists not needed for annotations
              hideListBullets: true,
              hideListChecks: true,
              hideCodeBlock: true, // Code blocks not useful
              hideQuote: true, // Block quotes not needed
              hideLink: true, // Links not useful in annotations
              hideHorizontalRule: true, // HR not needed
              // Keep useful formatting:
              // - Bold, Italic, Underline, Strikethrough
              // - Foreground/Background colors
              // - Inline code (for monospace)
              // - Headings (for font size variation)
              // - Undo/Redo
            ),
          ),
          // Fleather Editor
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FleatherEditor(
              controller: _fleatherController,
              padding: EdgeInsets.zero,
              focusNode: FocusNode(),
              autofocus: false,
            ),
          ),
        ],
      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
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

    // Validate rich text content if in rich mode
    if (_editMode == TextEditMode.rich) {
      final plainText = _fleatherController.document.toPlainText().trim();
      if (plainText.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Text is required')));
        return;
      }
    }

    final id =
        widget.annotation?.id ??
        'text_${DateTime.now().millisecondsSinceEpoch}';

    TextAnnotation annotation;

    if (_editMode == TextEditMode.simple) {
      // Simple text annotation
      annotation = TextAnnotation(
        id: id,
        text: _textController.text.trim(),
        position: widget.clickPosition,
        anchor: _anchor,
        style: _currentStyle,
        backgroundColor: _currentStyle.backgroundColor,
        borderColor: _currentStyle.borderColor,
        allowDragging: _allowDragging,
        allowEditing: true,
      );
    } else {
      // Rich text annotation
      annotation = TextAnnotation.fromParchmentDocument(
        id: id,
        document: _fleatherController.document,
        position: widget.clickPosition,
        anchor: _anchor,
        style: _currentStyle,
        backgroundColor: _currentStyle.backgroundColor,
        borderColor: _currentStyle.borderColor,
        allowDragging: _allowDragging,
        allowEditing: true,
      );
    }

    Navigator.of(context).pop(annotation);
  }
}
