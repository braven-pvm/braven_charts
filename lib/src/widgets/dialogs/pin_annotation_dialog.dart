// Copyright (c) 2025 braven_charts. All rights reserved.
// PinAnnotation Dialog - Material Design 3

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../../models/annotation_style.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_theme.dart';
import '../../models/enums.dart';
import 'annotation_style_editor.dart';

/// Dialog for creating or editing PinAnnotations.
///
/// PinAnnotations are placed at arbitrary x/y coordinates on the chart
/// and are not attached to any specific series or data point.
///
/// The dialog is theme-aware and uses Material Design 3 components.
class PinAnnotationDialog extends StatefulWidget {
  /// Creates a dialog for adding/editing PinAnnotations.
  ///
  /// [annotation] - If provided, dialog is in edit mode
  /// [initialX] - Initial X coordinate (used when creating new annotation)
  /// [initialY] - Initial Y coordinate (used when creating new annotation)
  /// [chartTheme] - Optional chart theme for default styling
  const PinAnnotationDialog({
    super.key,
    this.annotation,
    this.initialX,
    this.initialY,
    this.chartTheme,
  });

  final PinAnnotation? annotation;
  final double? initialX;
  final double? initialY;
  final ChartTheme? chartTheme;

  @override
  State<PinAnnotationDialog> createState() => _PinAnnotationDialogState();
}

class _PinAnnotationDialogState extends State<PinAnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _xController;
  late final TextEditingController _yController;

  MarkerShape _markerShape = MarkerShape.circle;
  double _markerSize = 12.0;
  Color _markerColor = Colors.red;
  AnnotationStyle _currentStyle = const AnnotationStyle();

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    final pointDefaults = widget.chartTheme?.annotationTheme.pointDefaults;

    // Initialize controllers
    _labelController = TextEditingController(text: annotation?.label ?? '');

    // Initialize x/y from annotation or from click position
    final initialX = annotation?.x ?? widget.initialX ?? 0.0;
    final initialY = annotation?.y ?? widget.initialY ?? 0.0;
    _xController = TextEditingController(text: _formatValue(initialX));
    _yController = TextEditingController(text: _formatValue(initialY));

    if (annotation != null) {
      // Edit mode - use existing annotation values
      _markerShape = annotation.markerShape;
      _markerSize = annotation.markerSize;
      _markerColor = annotation.markerColor;
      _currentStyle = annotation.style;
    } else if (pointDefaults != null) {
      // Create mode with theme defaults (use same defaults as PointAnnotation)
      _markerShape = _convertMarkerShape(pointDefaults.markerShape);
      _markerSize = pointDefaults.markerSize;
      _markerColor = pointDefaults.normalColor;
      _currentStyle = AnnotationStyle(
        textStyle: pointDefaults.labelStyle.textStyle,
        backgroundColor: pointDefaults.labelStyle.backgroundColor,
        borderColor: pointDefaults.labelStyle.borderColor,
        borderWidth: pointDefaults.labelStyle.borderWidth,
        borderRadius: BorderRadius.circular(
          pointDefaults.labelStyle.borderRadius,
        ),
        padding: pointDefaults.labelStyle.padding,
      );
    } else {
      // Fallback defaults
      _currentStyle = AnnotationStyle(
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        borderColor: Colors.grey.shade400,
        borderWidth: 1.0,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      );
    }
  }

  String _formatValue(double value) {
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  MarkerShape _convertMarkerShape(dynamic themeMarkerShape) {
    final shapeName = themeMarkerShape.toString().split('.').last;
    switch (shapeName) {
      case 'circle':
        return MarkerShape.circle;
      case 'square':
        return MarkerShape.square;
      case 'triangle':
        return MarkerShape.triangle;
      case 'diamond':
        return MarkerShape.diamond;
      case 'star':
        return MarkerShape.star;
      case 'cross':
        return MarkerShape.cross;
      case 'plus':
        return MarkerShape.plus;
      case 'none':
      default:
        return MarkerShape.none;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _xController.dispose();
    _yController.dispose();
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
        constraints: const BoxConstraints(maxHeight: 700),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    Icon(
                      isEditMode ? Icons.edit : Icons.push_pin,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditMode ? 'Edit Pin Annotation' : 'Add Pin Annotation',
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
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Coordinate fields
                _buildCoordinateFields(),
                const SizedBox(height: 20),

                // Label field (optional)
                _buildLabelField(),
                const SizedBox(height: 20),

                // Marker shape selector
                _buildMarkerShapeSelector(),
                const SizedBox(height: 20),

                // Marker size slider
                _buildMarkerSizeSlider(),
                const SizedBox(height: 20),

                // Marker color picker
                _buildMarkerColorPicker(),
                const SizedBox(height: 20),

                // Label styling (collapsible)
                AnnotationStyleEditor(
                  initialStyle: _currentStyle,
                  onStyleChanged: (style) {
                    setState(() {
                      _currentStyle = style;
                    });
                  },
                  showTextControls: true,
                  showBackgroundControls: true,
                  showBorderControls: true,
                  showPaddingControls: false,
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
    );
  }

  Widget _buildCoordinateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Position',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _xController,
                decoration: InputDecoration(
                  labelText: 'X',
                  hintText: '0.0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
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
                controller: _yController,
                decoration: InputDecoration(
                  labelText: 'Y',
                  hintText: '0.0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
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

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label (optional)',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _labelController,
          decoration: InputDecoration(
            hintText: 'Enter label text',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildMarkerShapeSelector() {
    final shapes = [
      MarkerShape.circle,
      MarkerShape.square,
      MarkerShape.diamond,
      MarkerShape.triangle,
      MarkerShape.star,
      MarkerShape.cross,
      MarkerShape.plus,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marker Shape',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shapes.map((shape) {
            final isSelected = shape == _markerShape;
            final colorScheme = Theme.of(context).colorScheme;

            return InkWell(
              onTap: () {
                setState(() {
                  _markerShape = shape;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShapeIcon(shape, isSelected),
                    const SizedBox(width: 6),
                    Text(
                      _shapeLabel(shape),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
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

  Widget _buildShapeIcon(MarkerShape shape, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.grey.shade700;
    const size = 14.0;

    switch (shape) {
      case MarkerShape.circle:
        return Icon(Icons.circle, size: size, color: color);
      case MarkerShape.square:
        return Icon(Icons.square, size: size, color: color);
      case MarkerShape.diamond:
        return Icon(Icons.diamond, size: size, color: color);
      case MarkerShape.triangle:
        return Icon(Icons.change_history, size: size, color: color);
      case MarkerShape.cross:
        return Icon(Icons.close, size: size, color: color);
      case MarkerShape.star:
        return Icon(Icons.star, size: size, color: color);
      case MarkerShape.plus:
        return Icon(Icons.add, size: size, color: color);
      case MarkerShape.none:
        return Icon(Icons.not_interested, size: size, color: color);
    }
  }

  String _shapeLabel(MarkerShape shape) {
    switch (shape) {
      case MarkerShape.circle:
        return 'Circle';
      case MarkerShape.square:
        return 'Square';
      case MarkerShape.diamond:
        return 'Diamond';
      case MarkerShape.triangle:
        return 'Triangle';
      case MarkerShape.cross:
        return 'Cross';
      case MarkerShape.star:
        return 'Star';
      case MarkerShape.plus:
        return 'Plus';
      case MarkerShape.none:
        return 'None';
    }
  }

  Widget _buildMarkerSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Marker Size',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_markerSize.toInt()}px',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Slider(
          value: _markerSize,
          min: 6,
          max: 24,
          divisions: 18,
          onChanged: (value) {
            setState(() {
              _markerSize = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMarkerColorPicker() {
    final presetColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.black,
      Colors.white,
      Colors.grey.shade600,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marker Color',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presetColors.map((color) {
              final isSelected = _markerColor == color;
              return InkWell(
                onTap: () {
                  setState(() {
                    _markerColor = color;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: _getContrastColor(color),
                        )
                      : null,
                ),
              );
            }),
            // Custom color picker button
            InkWell(
              onTap: _showCustomColorPicker,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  void _showCustomColorPicker() {
    Color selectedColor = _markerColor;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Marker Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
              width: 40,
              height: 40,
              borderRadius: 4,
              spacing: 5,
              runSpacing: 5,
              wheelDiameter: 200,
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Selected color and its shades',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              showMaterialName: true,
              showColorName: true,
              showColorCode: true,
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true,
              },
              enableShadesSelection: true,
              enableOpacity: true,
              showRecentColors: true,
              maxRecentColors: 5,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _markerColor = selectedColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final label = _labelController.text.trim();
    final x = double.parse(_xController.text);
    final y = double.parse(_yController.text);

    final annotation = PinAnnotation(
      id:
          widget.annotation?.id ??
          'pin_${DateTime.now().millisecondsSinceEpoch}',
      label: label.isEmpty ? null : label,
      style: _currentStyle,
      x: x,
      y: y,
      markerShape: _markerShape,
      markerSize: _markerSize,
      markerColor: _markerColor,
      allowDragging: true,
      allowEditing: true,
    );

    Navigator.of(context).pop(annotation);
  }
}
