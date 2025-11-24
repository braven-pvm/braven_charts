// Copyright (c) 2025 braven_charts. All rights reserved.
// ThresholdAnnotation Dialog - Material Design 3

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../../models/chart_annotation.dart';

/// Dialog for creating or editing a ThresholdAnnotation.
///
/// Provides UI for configuring:
/// - Axis selection (X or Y)
/// - Threshold value
/// - Line style (color, width, dash pattern)
/// - Optional label with positioning
/// - Label styling (via AnnotationStyleEditor)
class ThresholdAnnotationDialog extends StatefulWidget {
  const ThresholdAnnotationDialog({
    super.key,
    this.annotation,
    this.initialXValue,
    this.initialYValue,
  });

  /// Existing annotation to edit, or null to create new.
  final ThresholdAnnotation? annotation;

  /// Initial X-axis value from click position.
  final double? initialXValue;

  /// Initial Y-axis value from click position.
  final double? initialYValue;
  @override
  State<ThresholdAnnotationDialog> createState() => _ThresholdAnnotationDialogState();
}

class _ThresholdAnnotationDialogState extends State<ThresholdAnnotationDialog> {
  late final TextEditingController _valueController;
  late final TextEditingController _labelController;

  late AnnotationAxis _selectedAxis;
  late Color _lineColor;
  late double _lineWidth;
  late List<double>? _dashPattern;
  late AnnotationLabelPosition _labelPosition;
  late double _labelMargin;

  // Predefined dash patterns
  final Map<String, List<double>?> _dashPatterns = {
    'Solid': null,
    'Dashed': [8, 4],
    'Dotted': [2, 4],
    'Dash-Dot': [8, 4, 2, 4],
  };

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    _selectedAxis = annotation?.axis ?? AnnotationAxis.y; // Default to Y-axis

    // Set initial value based on selected axis
    String initialValue = '';
    if (annotation != null) {
      initialValue = annotation.value.toString();
    } else {
      // For new annotations, use Y-axis value by default
      if (widget.initialYValue != null) {
        initialValue = widget.initialYValue!.toStringAsFixed(2);
      }
    }

    _valueController = TextEditingController(text: initialValue);
    _labelController = TextEditingController(text: annotation?.label ?? '');
    _lineColor = annotation?.lineColor ?? Colors.red;
    _lineWidth = annotation?.lineWidth ?? 1.0;
    _dashPattern = annotation?.dashPattern;
    _labelPosition = annotation?.labelPosition ?? AnnotationLabelPosition.topLeft;
    _labelMargin = annotation?.labelMargin ?? 8.0;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  String _getDashPatternName() {
    if (_dashPattern == null) return 'Solid';
    for (final entry in _dashPatterns.entries) {
      if (_listEquals(entry.value, _dashPattern)) return entry.key;
    }
    return 'Custom';
  }

  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleCreate() {
    final value = double.tryParse(_valueController.text);
    if (value == null || !value.isFinite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid threshold value')),
      );
      return;
    }

    final annotation = ThresholdAnnotation(
      id: widget.annotation?.id,
      axis: _selectedAxis,
      value: value,
      label: _labelController.text.isEmpty ? null : _labelController.text,
      lineColor: _lineColor,
      lineWidth: _lineWidth,
      dashPattern: _dashPattern,
      labelPosition: _labelPosition,
      labelMargin: _labelMargin,
      allowDragging: true, // Enable dragging by default
    );

    Navigator.of(context).pop(annotation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.annotation != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Threshold' : 'Add Threshold',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Horizontal or vertical reference line',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Axis Selection
                    Text('Axis', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<AnnotationAxis>(
                      segments: const [
                        ButtonSegment(
                          value: AnnotationAxis.x,
                          label: Text('X-Axis'),
                          icon: Icon(Icons.horizontal_rule),
                        ),
                        ButtonSegment(
                          value: AnnotationAxis.y,
                          label: Text('Y-Axis'),
                          icon: Icon(Icons.remove),
                        ),
                      ],
                      selected: {_selectedAxis},
                      onSelectionChanged: (Set<AnnotationAxis> selection) {
                        setState(() {
                          _selectedAxis = selection.first;
                          // Update value field when switching axes (only for new annotations)
                          if (widget.annotation == null) {
                            if (_selectedAxis == AnnotationAxis.x && widget.initialXValue != null) {
                              _valueController.text = widget.initialXValue!.toStringAsFixed(2);
                            } else if (_selectedAxis == AnnotationAxis.y && widget.initialYValue != null) {
                              _valueController.text = widget.initialYValue!.toStringAsFixed(2);
                            }
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Value Input
                    TextField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Threshold Value *',
                        hintText: 'Enter numeric value',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),

                    const SizedBox(height: 24),

                    // Label (Optional)
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        hintText: 'e.g., "Target" or "Maximum"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      maxLength: 50,
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Line Style Section
                    Text('Line Style', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),

                    // Line Color
                    Row(
                      children: [
                        const Icon(Icons.palette, size: 20),
                        const SizedBox(width: 12),
                        const Text('Color'),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showColorPicker(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _lineColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Line Width
                    Row(
                      children: [
                        const Icon(Icons.line_weight, size: 20),
                        const SizedBox(width: 12),
                        const Text('Width'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _lineWidth,
                            min: 0.5,
                            max: 10.0,
                            divisions: 19,
                            label: '${_lineWidth.toStringAsFixed(1)}px',
                            onChanged: (value) => setState(() => _lineWidth = value),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${_lineWidth.toStringAsFixed(1)}px',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dash Pattern
                    Row(
                      children: [
                        const Icon(Icons.more_horiz, size: 20),
                        const SizedBox(width: 12),
                        const Text('Pattern'),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _getDashPatternName(),
                          items: _dashPatterns.keys.map((name) {
                            return DropdownMenuItem(value: name, child: Text(name));
                          }).toList(),
                          onChanged: (name) {
                            if (name != null) {
                              setState(() => _dashPattern = _dashPatterns[name]);
                            }
                          },
                        ),
                      ],
                    ),

                    if (_labelController.text.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Label Position
                      Text('Label Position', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AnnotationLabelPosition.values.map((position) {
                          return ChoiceChip(
                            label: Text(_labelPositionName(position)),
                            selected: _labelPosition == position,
                            onSelected: (selected) {
                              if (selected) setState(() => _labelPosition = position);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Label Margin
                      Row(
                        children: [
                          const Icon(Icons.space_bar, size: 20),
                          const SizedBox(width: 12),
                          const Text('Margin'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _labelMargin,
                              min: 0,
                              max: 32,
                              divisions: 16,
                              label: '${_labelMargin.toInt()}px',
                              onChanged: (value) => setState(() => _labelMargin = value),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${_labelMargin.toInt()}px',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _handleCreate,
                    icon: Icon(isEditing ? Icons.check : Icons.add),
                    label: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelPositionName(AnnotationLabelPosition position) {
    switch (position) {
      case AnnotationLabelPosition.topLeft:
        return 'Top Left';
      case AnnotationLabelPosition.topRight:
        return 'Top Right';
      case AnnotationLabelPosition.bottomLeft:
        return 'Bottom Left';
      case AnnotationLabelPosition.bottomRight:
        return 'Bottom Right';
      case AnnotationLabelPosition.center:
        return 'Center';
    }
  }

  Future<void> _showColorPicker() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Line Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: _lineColor,
            onColorChanged: (color) => setState(() => _lineColor = color),
            width: 40,
            height: 40,
            borderRadius: 8,
            spacing: 8,
            runSpacing: 8,
            wheelDiameter: 200,
            enableShadesSelection: false,
            pickersEnabled: const {
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: false,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
