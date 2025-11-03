// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../annotations/point_annotation.dart';
import '../enums/marker_shape.dart';

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
  const PointAnnotationDialog({
    super.key,
    this.annotation,
    required this.seriesId,
    required this.dataPointIndex,
  });

  final PointAnnotation? annotation;
  final String seriesId;
  final int dataPointIndex;

  @override
  State<PointAnnotationDialog> createState() => _PointAnnotationDialogState();
}

class _PointAnnotationDialogState extends State<PointAnnotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;

  MarkerShape _markerShape = MarkerShape.circle;
  double _markerSize = 12.0;
  Color _markerColor = Colors.red;
  Offset _offset = Offset.zero;

  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;

    // Initialize label controller
    _labelController = TextEditingController(text: annotation?.label ?? '');

    if (annotation != null) {
      _markerShape = annotation.markerShape;
      _markerSize = annotation.markerSize;
      _markerColor = annotation.markerColor;
      _offset = annotation.offset;
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
                    isEditMode ? Icons.edit : Icons.place,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditMode ? 'Edit Point Annotation' : 'Add Point Annotation',
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

              // Data point info (read-only)
              _buildDataPointInfo(),
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

              // Advanced section (offset)
              _buildAdvancedSection(),
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

  Widget _buildDataPointInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'Data Point',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Series: ${widget.seriesId}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Point Index: ${widget.dataPointIndex}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _labelController,
          decoration: InputDecoration(
            hintText: 'Enter label text',
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shapes.map((shape) {
            final isSelected = shape == _markerShape;
            return InkWell(
              onTap: () {
                setState(() {
                  _markerShape = shape;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                    width: 1,
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
                        fontSize: 11,
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

  Widget _buildShapeIcon(MarkerShape shape, bool isSelected) {
    final color = isSelected ? Colors.white : Colors.grey[700];
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
            ),
            const Spacer(),
            Text(
              '${_markerSize.toInt()}px',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marker Color',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetColors.map((color) {
            final isSelected = _markerColor == color;
            return InkWell(
              onTap: () {
                setState(() {
                  _markerColor = color;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: color == Colors.black ? Colors.white : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
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
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Advanced (optional)',
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
        if (_showAdvanced) ...[
          const SizedBox(height: 12),
          Text(
            'Offset from Data Point',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
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

  Widget _buildOffsetField(String label, double value, void Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value.toStringAsFixed(0),
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
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

    print('📍 [PointAnnotationDialog] Creating annotation:');
    print('   - Label: "$label"');
    print('   - Series: ${widget.seriesId}');
    print('   - DataPointIndex: ${widget.dataPointIndex}');
    print('   - MarkerShape: $_markerShape');
    print('   - MarkerSize: $_markerSize');
    print('   - MarkerColor: $_markerColor');

    final annotation = PointAnnotation(
      id: widget.annotation?.id ?? 'point_${DateTime.now().millisecondsSinceEpoch}',
      label: label.isEmpty ? null : label,
      seriesId: widget.seriesId,
      dataPointIndex: widget.dataPointIndex,
      markerShape: _markerShape,
      markerSize: _markerSize,
      markerColor: _markerColor,
      offset: _offset,
    );

    print('✅ [PointAnnotationDialog] Annotation created');
    Navigator.of(context).pop(annotation);
  }
}
