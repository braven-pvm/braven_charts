// Copyright (c) 2025 braven_charts. All rights reserved.
// PointAnnotation Dialog - Material Design 3

import 'package:flutter/material.dart';

import '../../models/annotation_style.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_theme.dart';
import '../../models/enums.dart';
import 'annotation_color_palette.dart';
import 'annotation_dialog_header.dart';
import 'annotation_style_editor.dart';

/// Dialog for creating or editing PointAnnotations.
///
/// PointAnnotations are attached to specific data points in a series.
/// The series and data point index are automatically determined from
/// the clicked point and cannot be edited by the user.
///
/// The dialog is theme-aware and uses Material Design 3 components.
class PointAnnotationDialog extends StatefulWidget {
  /// Creates a dialog for adding/editing PointAnnotations.
  ///
  /// [annotation] - If provided, dialog is in edit mode
  /// [seriesId] - ID of the series containing the data point
  /// [dataPointIndex] - Index of the data point in the series
  /// [chartTheme] - Optional chart theme for default styling
  const PointAnnotationDialog({
    super.key,
    this.annotation,
    required this.seriesId,
    required this.dataPointIndex,
    this.chartTheme,
  });

  final PointAnnotation? annotation;
  final String seriesId;
  final int dataPointIndex;
  final ChartTheme? chartTheme;

  @override
  State<PointAnnotationDialog> createState() => _PointAnnotationDialogState();
}

class _PointAnnotationDialogState extends State<PointAnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;

  MarkerShape _markerShape = MarkerShape.circle;
  double _markerSize = 12.0;
  Color? _markerColor = Colors.red;
  Offset _offset = Offset.zero;
  AnnotationStyle _currentStyle = const AnnotationStyle();

  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    final pointDefaults = widget.chartTheme?.annotationTheme.pointDefaults;

    // Initialize label controller
    _labelController = TextEditingController(text: annotation?.label ?? '');

    if (annotation != null) {
      // Edit mode - use existing annotation values
      _markerShape = annotation.markerShape;
      _markerSize = annotation.markerSize;
      _markerColor = annotation.markerColor == Colors.transparent
          ? null
          : annotation.markerColor;
      _offset = annotation.offset;
      _currentStyle = annotation.style;
    } else if (pointDefaults != null) {
      // Create mode with theme defaults
      _markerShape = _convertMarkerShape(pointDefaults.markerShape);
      _markerSize = pointDefaults.markerSize;
      _markerColor = pointDefaults.normalColor;
      _currentStyle = AnnotationStyle(
        textStyle: pointDefaults.labelStyle.textStyle,
        backgroundColor: pointDefaults.labelStyle.backgroundColor,
        borderColor: pointDefaults.labelStyle.borderColor,
        borderWidth: pointDefaults.labelStyle.borderWidth,
        borderRadius:
            BorderRadius.circular(pointDefaults.labelStyle.borderRadius),
        padding: pointDefaults.labelStyle.padding,
      );
    } else {
      // Fallback defaults (no theme provided)
      _currentStyle = AnnotationStyle(
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
        borderColor: Colors.grey.shade400,
        borderWidth: 1.0,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      );
    }
  }

  /// Convert theme MarkerShape enum to annotation MarkerShape enum
  /// TODO: Fix duplicate MarkerShape enums - they should use the same enum
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
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnnotationDialogHeader(
                key: const ValueKey('point-dialog-sticky-header'),
                title: isEditMode
                    ? 'Edit Point Annotation'
                    : 'Add Point Annotation',
                icon: isEditMode ? Icons.edit : Icons.place,
                primaryLabel: isEditMode ? 'Update' : 'Add',
                onPrimary: _handleSave,
                onCancel: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataPointInfo(),
                      const SizedBox(height: 20),
                      _buildLabelField(),
                      const SizedBox(height: 20),
                      _buildMarkerShapeSelector(),
                      const SizedBox(height: 20),
                      _buildMarkerSizeSlider(),
                      const SizedBox(height: 20),
                      _buildMarkerColorPicker(),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      _buildAdvancedSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPointInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Attached to Data Point',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Series: ${widget.seriesId}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'Point Index: ${widget.dataPointIndex}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
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
          'Label (optional)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _labelController,
          decoration: InputDecoration(
            hintText: 'Enter label text',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? colorScheme.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : Colors.grey.shade300,
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marker Color (Optional)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        AnnotationColorPalette(
          value: _markerColor,
          keyPrefix: 'point-marker-color',
          customColorFallback: Colors.red,
          onChanged: (color) => setState(() => _markerColor = color),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showAdvanced = !_showAdvanced;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 12),
          Text(
            'Offset from Data Point',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOffsetField('X', _offset.dx, (value) {
                  setState(() {
                    _offset = Offset(value, _offset.dy);
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOffsetField('Y', _offset.dy, (value) {
                  setState(() {
                    _offset = Offset(_offset.dx, value);
                  });
                }),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOffsetField(
      String label, double value, void Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toStringAsFixed(0),
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12),
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: true),
          onChanged: (text) {
            final parsed = double.tryParse(text);
            if (parsed != null) {
              onChanged(parsed);
            }
          },
        ),
      ],
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final label = _labelController.text.trim();

    final annotation = PointAnnotation(
      id: widget.annotation?.id ??
          'point_${DateTime.now().millisecondsSinceEpoch}',
      label: label.isEmpty ? null : label,
      style: _currentStyle,
      seriesId: widget.seriesId,
      dataPointIndex: widget.dataPointIndex,
      markerShape: _markerShape,
      markerSize: _markerSize,
      markerColor: _markerColor ?? Colors.transparent,
      offset: _offset,
      allowDragging: true,
      allowEditing: true,
    );

    Navigator.of(context).pop(annotation);
  }
}
