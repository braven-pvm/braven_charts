// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/widgets/interactions/annotation_style_editor.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../annotations/annotation_style.dart';
import '../annotations/range_annotation.dart';

/// Dialog for creating or editing RangeAnnotations.
///
/// Allows users to define rectangular range highlights on charts.
class RangeAnnotationDialog extends StatefulWidget {
  const RangeAnnotationDialog({super.key, this.annotation});

  /// The annotation to edit, or null to create a new one.
  final RangeAnnotation? annotation;

  @override
  State<RangeAnnotationDialog> createState() => _RangeAnnotationDialogState();
}

class _RangeAnnotationDialogState extends State<RangeAnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _startXController;
  late final TextEditingController _endXController;
  late final TextEditingController _startYController;
  late final TextEditingController _endYController;

  Color _fillColor = Colors.blue.withOpacity(0.2);
  Color? _borderColor;
  AnnotationLabelPosition _labelPosition = AnnotationLabelPosition.topLeft;
  AnnotationStyle _labelStyle = const AnnotationStyle();

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;

    _labelController = TextEditingController(text: annotation?.label ?? '');
    _startXController = TextEditingController(
      text: annotation?.startX?.toString() ?? '',
    );
    _endXController = TextEditingController(
      text: annotation?.endX?.toString() ?? '',
    );
    _startYController = TextEditingController(
      text: annotation?.startY?.toString() ?? '',
    );
    _endYController = TextEditingController(
      text: annotation?.endY?.toString() ?? '',
    );

    if (annotation != null) {
      _fillColor = annotation.fillColor ?? Colors.blue.withOpacity(0.2);
      _borderColor = annotation.borderColor;
      _labelPosition = annotation.labelPosition;
      _labelStyle = annotation.style;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _startXController.dispose();
    _endXController.dispose();
    _startYController.dispose();
    _endYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditMode = widget.annotation != null;

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      Icon(
                        isEditMode ? Icons.edit : Icons.select_all,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditMode
                            ? 'Edit Range Annotation'
                            : 'Add Range Annotation',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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

                  // Info message
                  _buildInfoMessage(),
                  const SizedBox(height: 20),

                  // Label field (optional)
                  _buildLabelField(),
                  const SizedBox(height: 20),

                  // Range inputs (X-axis)
                  _buildRangeInputs(
                    title: 'X-Axis Range',
                    startController: _startXController,
                    endController: _endXController,
                    hint: 'Leave blank for full range',
                  ),
                  const SizedBox(height: 20),

                  // Range inputs (Y-axis)
                  _buildRangeInputs(
                    title: 'Y-Axis Range',
                    startController: _startYController,
                    endController: _endYController,
                    hint: 'Leave blank for full range',
                  ),
                  const SizedBox(height: 20),

                  // Fill color picker
                  _buildFillColorPicker(),
                  const SizedBox(height: 20),

                  // Border color picker
                  _buildBorderColorPicker(),
                  const SizedBox(height: 20),

                  // Label position selector
                  _buildLabelPositionSelector(),
                  const SizedBox(height: 20),

                  // Label styling
                  AnnotationStyleEditor(
                    initialStyle: _labelStyle,
                    onStyleChanged: (style) {
                      setState(() {
                        _labelStyle = style;
                      });
                    },
                  ),
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
      ),
    );
  }

  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Define at least one axis range (X or Y)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label (Optional)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _labelController,
          decoration: const InputDecoration(
            hintText: 'e.g., Weekend, Q1 2024',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildRangeInputs({
    required String title,
    required TextEditingController startController,
    required TextEditingController endController,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillColorPicker() {
    final presetColors = [
      Colors.blue.withOpacity(0.2),
      Colors.green.withOpacity(0.2),
      Colors.red.withOpacity(0.2),
      Colors.orange.withOpacity(0.2),
      Colors.purple.withOpacity(0.2),
      Colors.yellow.withOpacity(0.2),
      Colors.grey.withOpacity(0.2),
      Colors.teal.withOpacity(0.2),
      Colors.pink.withOpacity(0.2),
      Colors.indigo.withOpacity(0.2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill Color',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            ...presetColors.map((color) {
              final isSelected = _fillColor == color;
              return InkWell(
                onTap: () {
                  setState(() {
                    _fillColor = color;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.grey.shade300,
                      width: isSelected ? 0.5 : 0.2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }),
            // Custom color picker button
            InkWell(
              onTap: () => _showCustomColorPicker(_fillColor, (color) {
                setState(() {
                  _fillColor = color;
                });
              }),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette,
                      size: 16,
                      color: Colors.deepOrange.shade400,
                    ),
                    const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _fillColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBorderColorPicker() {
    final presetColors = [
      Colors.transparent,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.black,
      Colors.grey,
      Colors.teal,
      Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Border Color (Optional)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            ...presetColors.map((color) {
              final isSelected = _borderColor == color;
              final isTransparent = color == Colors.transparent;
              return InkWell(
                onTap: () {
                  setState(() {
                    _borderColor = color == Colors.transparent ? null : color;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTransparent ? Colors.white : color,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.grey.shade300,
                      width: isSelected ? 0.5 : 0.2,
                    ),
                  ),
                  child: isTransparent
                      ? Icon(
                          Icons.block,
                          size: 16,
                          color: isSelected ? Colors.red : Colors.grey,
                        )
                      : isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: color == Colors.black
                              ? Colors.white
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }),
            // Custom color picker button
            if (_borderColor != null && _borderColor != Colors.transparent)
              InkWell(
                onTap: () => _showCustomColorPicker(_borderColor!, (color) {
                  setState(() {
                    _borderColor = color;
                  });
                }),
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    spacing: 5,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.palette,
                        size: 16,
                        color: Colors.deepOrange.shade400,
                      ),
                      const Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _borderColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelPositionSelector() {
    final positions = [
      (AnnotationLabelPosition.topLeft, 'Top Left', Icons.north_west),
      (AnnotationLabelPosition.topRight, 'Top Right', Icons.north_east),
      (AnnotationLabelPosition.center, 'Center', Icons.center_focus_strong),
      (AnnotationLabelPosition.bottomLeft, 'Bottom Left', Icons.south_west),
      (AnnotationLabelPosition.bottomRight, 'Bottom Right', Icons.south_east),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label Position',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: positions.map((pos) {
            final position = pos.$1;
            final label = pos.$2;
            final icon = pos.$3;
            final isSelected = position == _labelPosition;

            return InkWell(
              onTap: () {
                setState(() {
                  _labelPosition = position;
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
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showCustomColorPicker(
    Color currentColor,
    void Function(Color) onColorChanged,
  ) async {
    Color selectedColor = currentColor;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: selectedColor,
            onColorChanged: (color) => selectedColor = color,
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.wheel: true,
            },
            enableShadesSelection: true,
            showColorName: true,
            showColorCode: true,
            colorCodeHasColor: true,
            enableOpacity: true,
            opacityTrackHeight: 30,
            opacityThumbRadius: 16,
            recentColorsSubheading: const Text('Recent colors'),
            maxRecentColors: 5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result == true) {
      onColorChanged(selectedColor);
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final label = _labelController.text.trim();
    final startX = _startXController.text.trim().isEmpty
        ? null
        : double.tryParse(_startXController.text.trim());
    final endX = _endXController.text.trim().isEmpty
        ? null
        : double.tryParse(_endXController.text.trim());
    final startY = _startYController.text.trim().isEmpty
        ? null
        : double.tryParse(_startYController.text.trim());
    final endY = _endYController.text.trim().isEmpty
        ? null
        : double.tryParse(_endYController.text.trim());

    // Validation: At least one axis range must be specified
    if (startX == null && endX == null && startY == null && endY == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify at least one axis range (X or Y)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: start < end for each axis
    if (startX != null && endX != null && startX >= endX) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('X-axis: Start must be less than End'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (startY != null && endY != null && startY >= endY) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Y-axis: Start must be less than End'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final annotation = RangeAnnotation(
      id:
          widget.annotation?.id ??
          'range_${DateTime.now().millisecondsSinceEpoch}',
      label: label.isEmpty ? null : label,
      style: _labelStyle,
      startX: startX,
      endX: endX,
      startY: startY,
      endY: endY,
      fillColor: _fillColor,
      borderColor: _borderColor,
      labelPosition: _labelPosition,
      // allowDragging and allowEditing default to true for RangeAnnotation
    );

    Navigator.of(context).pop(annotation);
  }
}
