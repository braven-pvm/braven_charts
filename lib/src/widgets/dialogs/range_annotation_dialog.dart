// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/widgets/dialogs/annotation_style_editor.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/annotation_style.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_series.dart';
import '../../models/chart_theme.dart';
import '../../models/normalization_mode.dart';

/// Dialog for creating or editing RangeAnnotations.
///
/// Allows users to define rectangular range highlights on charts.
class RangeAnnotationDialog extends StatefulWidget {
  const RangeAnnotationDialog({
    super.key,
    this.annotation,
    this.initialStartX,
    this.initialEndX,
    this.initialStartY,
    this.initialEndY,
    this.chartTheme,
    this.availableSeries,
    this.normalizationMode,
  });

  /// The annotation to edit, or null to create a new one.
  final RangeAnnotation? annotation;

  /// Optional chart theme for default styling.
  final ChartTheme? chartTheme;

  /// Initial X-axis start value (from interactive drag).
  final double? initialStartX;

  /// Initial X-axis end value (from interactive drag).
  final double? initialEndX;

  /// Initial Y-axis start value (from interactive drag).
  final double? initialStartY;

  /// Initial Y-axis end value (from interactive drag).
  final double? initialEndY;

  /// Available series for series selection (perSeries mode).
  ///
  /// When [normalizationMode] is [NormalizationMode.perSeries] and the user
  /// specifies Y-axis range values, a dropdown allows selecting which series
  /// the range should be associated with for correct Y-value normalization.
  final List<ChartSeries>? availableSeries;

  /// Current normalization mode.
  ///
  /// When [NormalizationMode.perSeries], shows series selector for ranges
  /// with Y-axis values.
  final NormalizationMode? normalizationMode;

  @override
  State<RangeAnnotationDialog> createState() => _RangeAnnotationDialogState();
}

/// Range annotation mode - determines which axis bounds are specified.
enum RangeMode {
  /// Horizontal band - spans full X-axis, user specifies Y range only.
  horizontal,

  /// Vertical band - spans full Y-axis, user specifies X range only.
  vertical,

  /// Custom rectangle - user specifies both X and Y ranges.
  custom,
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
  AnnotationStyle? _labelStyle;
  bool _snapToDataPoints = true;

  /// Selected series ID for perSeries normalization mode.
  String? _selectedSeriesId;

  /// Current range mode (horizontal, vertical, or custom).
  RangeMode _rangeMode = RangeMode.custom;

  /// Whether to show the series selector dropdown.
  /// Only shown when normalization mode is perSeries and there are available series.
  bool get _showSeriesSelector =>
      widget.normalizationMode == NormalizationMode.perSeries && widget.availableSeries != null && widget.availableSeries!.isNotEmpty;

  /// Gets the Y data range (min, max) for a given series.
  /// Returns null if series not found or has no points.
  /// Returns PADDED bounds (5% padding) to match the renderer's computeSeriesBounds.
  (double min, double max)? _getSeriesYBounds(String? seriesId) {
    if (seriesId == null || widget.availableSeries == null) return null;
    final series = widget.availableSeries!.where((s) => s.id == seriesId).firstOrNull;
    if (series == null || series.points.isEmpty) return null;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final point in series.points) {
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }
    if (minY == double.infinity || maxY == double.negativeInfinity) return null;

    // Apply 5% padding to match renderer (MultiAxisManager.computeSeriesBounds)
    final span = maxY - minY;
    final padding = span > 0 ? span * 0.05 : 0.5;
    return (minY - padding, maxY + padding);
  }

  /// Denormalizes a Y value from normalized range to actual data range.
  /// The input normalizedY comes from plotToData which returns values
  /// in the 0-1 range (within the padded bounds).
  double? _denormalizeY(double? normalizedY, String? seriesId) {
    if (normalizedY == null || !_showSeriesSelector) return normalizedY;
    final bounds = _getSeriesYBounds(seriesId);
    if (bounds == null) return normalizedY;
    final (minY, maxY) = bounds;
    final span = maxY - minY;
    if (span <= 0) return normalizedY;
    return minY + normalizedY * span;
  }

  /// Normalizes a Y value from actual data range to 0-1 range.
  /// Used internally for re-translating values when series changes.
  double? _normalizeY(double? actualY, String? seriesId) {
    if (actualY == null || !_showSeriesSelector) return actualY;
    final bounds = _getSeriesYBounds(seriesId);
    if (bounds == null) return actualY;
    final (minY, maxY) = bounds;
    final span = maxY - minY;
    if (span <= 0) return actualY;
    return (actualY - minY) / span;
  }

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    final rangeDefaults = widget.chartTheme?.annotationTheme.rangeDefaults;

    // Initialize series selection FIRST (needed for Y value denormalization)
    if (annotation != null && annotation.seriesId != null) {
      // Sanitize seriesId - LLMs sometimes include trailing punctuation
      var sanitizedId = annotation.seriesId!.trim();
      while (sanitizedId.isNotEmpty && (sanitizedId.endsWith(',') || sanitizedId.endsWith('.') || sanitizedId.endsWith(';'))) {
        sanitizedId = sanitizedId.substring(0, sanitizedId.length - 1).trim();
      }

      // Validate that the seriesId exists in availableSeries
      final validIds = widget.availableSeries?.map((s) => s.id).toSet() ?? <String>{};
      if (validIds.contains(sanitizedId)) {
        _selectedSeriesId = sanitizedId;
      } else if (widget.availableSeries != null && widget.availableSeries!.isNotEmpty) {
        // Fallback to first series if seriesId is invalid
        _selectedSeriesId = widget.availableSeries!.first.id;
      }
    } else if (widget.availableSeries != null && widget.availableSeries!.isNotEmpty) {
      // Default to first series
      _selectedSeriesId = widget.availableSeries!.first.id;
    }

    // Prefer annotation values, fallback to initial values from drag
    final startX = annotation?.startX ?? widget.initialStartX;
    final endX = annotation?.endX ?? widget.initialEndX;
    final startY = annotation?.startY ?? widget.initialStartY;
    final endY = annotation?.endY ?? widget.initialEndY;

    // Note: In perSeries mode, Y values are now pre-denormalized by the
    // event handler before being passed to this dialog. No additional
    // denormalization needed here.

    _labelController = TextEditingController(text: annotation?.label ?? '');
    _startXController = TextEditingController(text: startX != null ? startX.toStringAsFixed(2) : '');
    _endXController = TextEditingController(text: endX != null ? endX.toStringAsFixed(2) : '');
    _startYController = TextEditingController(text: startY != null ? startY.toStringAsFixed(2) : '');
    _endYController = TextEditingController(text: endY != null ? endY.toStringAsFixed(2) : '');

    // Detect initial range mode based on which values are provided
    final hasX = startX != null || endX != null;
    final hasY = startY != null || endY != null;
    if (hasX && !hasY) {
      _rangeMode = RangeMode.vertical;
    } else if (hasY && !hasX) {
      _rangeMode = RangeMode.horizontal;
    } else {
      _rangeMode = RangeMode.custom;
    }

    if (annotation != null) {
      // Edit mode - use existing annotation values
      _fillColor = annotation.fillColor ?? Colors.blue.withOpacity(0.2);
      _borderColor = annotation.borderColor;
      _labelPosition = annotation.labelPosition;
      _labelStyle = annotation.style;
      _snapToDataPoints = annotation.snapToValue;
    } else if (rangeDefaults != null) {
      // Create mode with theme defaults
      _fillColor = rangeDefaults.normalFillColor;
      _borderColor = rangeDefaults.normalBorderColor;
      _labelStyle = rangeDefaults.toAnnotationStyle();
    }
    // else: fallback to field initialization defaults
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                        isEditMode ? 'Edit Range Annotation' : 'Add Range Annotation',
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

                  // Info message
                  _buildInfoMessage(),
                  const SizedBox(height: 20),

                  // Range Mode Selector
                  _buildRangeModeSelector(),
                  const SizedBox(height: 20),

                  // Label field (optional)
                  _buildLabelField(),
                  const SizedBox(height: 20),

                  // Range inputs (X-axis) - shown for Vertical and Custom modes
                  if (_rangeMode == RangeMode.vertical || _rangeMode == RangeMode.custom) ...[
                    _buildRangeInputs(
                      title: 'X-Axis Range',
                      startController: _startXController,
                      endController: _endXController,
                      hint: _rangeMode == RangeMode.custom ? 'Leave blank for full range' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Range inputs (Y-axis) - shown for Horizontal and Custom modes
                  if (_rangeMode == RangeMode.horizontal || _rangeMode == RangeMode.custom) ...[
                    _buildRangeInputs(
                      title: 'Y-Axis Range',
                      startController: _startYController,
                      endController: _endYController,
                      hint: _rangeMode == RangeMode.custom ? 'Leave blank for full range' : null,
                    ),
                  ],

                  // Series Selection (only in perSeries normalization mode and when Y is shown)
                  if (_showSeriesSelector && _rangeMode != RangeMode.vertical) ...[
                    const SizedBox(height: 20),
                    _buildSeriesSelector(),
                  ],
                  const SizedBox(height: 20),

                  // Snap to data points checkbox
                  _buildSnapToDataPointsCheckbox(),
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
      ),
    );
  }

  Widget _buildInfoMessage() {
    // Update message based on mode
    final message = switch (_rangeMode) {
      RangeMode.horizontal => 'Horizontal band spanning the full X-axis',
      RangeMode.vertical => 'Vertical band spanning the full Y-axis',
      RangeMode.custom => 'Custom rectangle with specified X and Y ranges',
    };

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
              message,
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

  /// Builds the range mode selector (Horizontal, Vertical, Custom).
  Widget _buildRangeModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Range Type',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<RangeMode>(
          segments: const [
            ButtonSegment(
              value: RangeMode.horizontal,
              label: Text('Horizontal'),
              icon: Icon(Icons.horizontal_rule),
            ),
            ButtonSegment(
              value: RangeMode.vertical,
              label: Text('Vertical'),
              icon: Icon(Icons.vertical_align_center),
            ),
            ButtonSegment(
              value: RangeMode.custom,
              label: Text('Custom'),
              icon: Icon(Icons.crop_free),
            ),
          ],
          selected: {_rangeMode},
          onSelectionChanged: (Set<RangeMode> selection) {
            final newMode = selection.first;
            if (newMode == _rangeMode) return;

            setState(() {
              // Clear the fields that won't be used in the new mode
              if (newMode == RangeMode.horizontal) {
                // Horizontal = Y only, clear X
                _startXController.clear();
                _endXController.clear();
              } else if (newMode == RangeMode.vertical) {
                // Vertical = X only, clear Y
                _startYController.clear();
                _endYController.clear();
              }
              // Custom mode keeps whatever values are there

              _rangeMode = newMode;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label (Optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  Widget _buildSnapToDataPointsCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _snapToDataPoints,
            onChanged: (value) {
              setState(() {
                _snapToDataPoints = value ?? true;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Snap to Data Points',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Automatically snap range edges to nearby data points when dragging',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the series selector dropdown for perSeries normalization mode.
  Widget _buildSeriesSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Series',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the series whose data range will be used to position this range annotation.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedSeriesId,
          decoration: const InputDecoration(
            labelText: 'Series',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.show_chart),
            isDense: true,
          ),
          items: widget.availableSeries!.map((series) {
            return DropdownMenuItem(
              value: series.id,
              child: Text(series.name ?? series.id),
            );
          }).toList(),
          onChanged: (newSeriesId) {
            if (newSeriesId == null || newSeriesId == _selectedSeriesId) return;

            // Re-translate Y values from old series scale to new series scale
            // Current displayed values are in old series' data units
            // Normalize them to 0-1, then denormalize to new series' data units
            final oldSeriesId = _selectedSeriesId;

            // Get current displayed Y values (actual data values in old series scale)
            final currentStartY = _startYController.text.trim().isEmpty ? null : double.tryParse(_startYController.text.trim());
            final currentEndY = _endYController.text.trim().isEmpty ? null : double.tryParse(_endYController.text.trim());

            // Normalize from old series → Denormalize to new series
            final normalizedStartY = _normalizeY(currentStartY, oldSeriesId);
            final normalizedEndY = _normalizeY(currentEndY, oldSeriesId);
            final newStartY = _denormalizeY(normalizedStartY, newSeriesId);
            final newEndY = _denormalizeY(normalizedEndY, newSeriesId);

            setState(() {
              _selectedSeriesId = newSeriesId;
              if (newStartY != null) {
                _startYController.text = newStartY.toStringAsFixed(2);
              }
              if (newEndY != null) {
                _endYController.text = newEndY.toStringAsFixed(2);
              }
            });
          },
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.palette, size: 16, color: Colors.deepOrange.shade400),
                    const Text(
                      'Custom',
                      style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
                              color: color == Colors.black ? Colors.white : Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    spacing: 5,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette, size: 16, color: Colors.deepOrange.shade400),
                      const Text(
                        'Custom',
                        style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
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

  Future<void> _showCustomColorPicker(Color currentColor, void Function(Color) onColorChanged) async {
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

    // Parse X values (only used for Vertical and Custom modes)
    double? startX;
    double? endX;
    if (_rangeMode == RangeMode.vertical || _rangeMode == RangeMode.custom) {
      startX = _startXController.text.trim().isEmpty ? null : double.tryParse(_startXController.text.trim());
      endX = _endXController.text.trim().isEmpty ? null : double.tryParse(_endXController.text.trim());
    }

    // Parse Y values (only used for Horizontal and Custom modes)
    double? startY;
    double? endY;
    if (_rangeMode == RangeMode.horizontal || _rangeMode == RangeMode.custom) {
      startY = _startYController.text.trim().isEmpty ? null : double.tryParse(_startYController.text.trim());
      endY = _endYController.text.trim().isEmpty ? null : double.tryParse(_endYController.text.trim());
    }

    // Validation based on mode
    if (_rangeMode == RangeMode.horizontal && startY == null && endY == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify Y-axis range for horizontal band'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rangeMode == RangeMode.vertical && startX == null && endX == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify X-axis range for vertical band'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rangeMode == RangeMode.custom && startX == null && endX == null && startY == null && endY == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify at least one axis range'),
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

    // Store actual data values - the renderer handles normalization
    final annotation = RangeAnnotation(
      id: widget.annotation?.id,
      label: label.isEmpty ? null : label,
      style: _labelStyle ?? const AnnotationStyle(),
      startX: startX,
      endX: endX,
      startY: startY,
      endY: endY,
      // Only include seriesId in perSeries mode when Y values are used
      seriesId: (_showSeriesSelector && _rangeMode != RangeMode.vertical) ? _selectedSeriesId : null,
      fillColor: _fillColor,
      borderColor: _borderColor,
      labelPosition: _labelPosition,
      snapToValue: _snapToDataPoints,
    );

    Navigator.of(context).pop(annotation);
  }
}
