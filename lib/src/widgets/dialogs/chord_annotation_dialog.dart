// Copyright (c) 2025 braven_charts. All rights reserved.
// ChordAnnotation Dialog - Material Design 3

import 'package:flutter/material.dart';

import '../../models/annotation_style.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_series.dart';
import 'annotation_color_palette.dart';
import 'annotation_dialog_header.dart';

/// Dialog for creating or editing a ChordAnnotation.
///
/// Provides UI for configuring:
/// - Series selection (if multiple available)
/// - Start and end data point indices
/// - Line style (color, width, dash pattern, glow)
/// - Optional label
/// - Perpendicular line to a third data point (index, label, styling)
class ChordAnnotationDialog extends StatefulWidget {
  const ChordAnnotationDialog({
    super.key,
    this.annotation,
    required this.availableSeries,
  });

  /// Existing annotation to edit, or null to create new.
  final ChordAnnotation? annotation;

  /// Available series to choose from (need full objects for point counts).
  final List<ChartSeries> availableSeries;

  @override
  State<ChordAnnotationDialog> createState() => _ChordAnnotationDialogState();
}

class _ChordAnnotationDialogState extends State<ChordAnnotationDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _startIndexController;
  late final TextEditingController _endIndexController;

  late String _selectedSeriesId;
  late Color _lineColor;
  late double _lineWidth;
  late List<double>? _dashPattern;
  late double _elevation;

  // Chord label styling
  late Color _labelTextColor;
  late Color? _labelBgColor;
  late double _labelFontSize;
  late FontWeight _labelFontWeight;

  // Perpendicular state
  late final TextEditingController _perpIndexController;
  late final TextEditingController _perpLabelController;
  late bool _perpEnabled;
  late bool _perpSeparateStyling;
  late Color _perpLineColor;
  late double _perpLineWidth;
  late List<double>? _perpDashPattern;
  late double _perpElevation;
  late Color _perpLabelTextColor;
  late Color? _perpLabelBgColor;
  late double _perpLabelFontSize;
  late FontWeight _perpLabelFontWeight;

  static const Map<String, List<double>?> _standardDashPatterns = {
    'Solid': null,
    'Dashed': [8, 4],
    'Short Dash': [6, 4],
    'Dotted': [2, 4],
    'Dash-Dot': [8, 4, 2, 4],
    'Fine Dash': [4, 3],
  };

  @override
  void initState() {
    super.initState();

    final annotation = widget.annotation;
    _selectedSeriesId = annotation?.seriesId ??
        (widget.availableSeries.isNotEmpty
            ? widget.availableSeries.first.id
            : '');
    _labelController =
        TextEditingController(text: annotation?.label ?? '');
    _startIndexController =
        TextEditingController(text: annotation?.startIndex.toString() ?? '0');
    _endIndexController =
        TextEditingController(text: annotation?.endIndex.toString() ?? '1');
    _lineColor = annotation?.lineColor ?? Colors.blue;
    _lineWidth = annotation?.lineWidth ?? 2.0;
    _dashPattern = annotation?.dashPattern;
    _elevation = annotation?.elevation ?? 0.0;
    _labelTextColor = annotation?.style.textColor ?? Colors.black;
    _labelBgColor = annotation?.style.backgroundColor;
    _labelFontSize = annotation?.style.fontSize ?? 12.0;
    _labelFontWeight = annotation?.style.fontWeight ?? FontWeight.normal;

    // Perpendicular
    _perpEnabled = annotation?.perpendicularIndex != null;
    _perpIndexController = TextEditingController(
        text: annotation?.perpendicularIndex?.toString() ?? '');
    _perpLabelController =
        TextEditingController(text: annotation?.perpendicularLabel ?? '');
    _perpSeparateStyling = annotation?.perpendicularLineColor != null ||
        annotation?.perpendicularLineWidth != null ||
        annotation?.perpendicularDashPattern != null ||
        annotation?.perpendicularElevation != null;
    _perpLineColor = annotation?.perpendicularLineColor ??
        annotation?.lineColor ??
        Colors.blue;
    _perpLineWidth =
        annotation?.perpendicularLineWidth ?? annotation?.lineWidth ?? 2.0;
    _perpDashPattern =
        annotation?.perpendicularDashPattern ?? annotation?.dashPattern;
    _perpElevation =
        annotation?.perpendicularElevation ?? annotation?.elevation ?? 0.0;
    _perpLabelTextColor =
        annotation?.effectivePerpendicularLabelStyle.textColor ?? Colors.black;
    _perpLabelBgColor =
        annotation?.effectivePerpendicularLabelStyle.backgroundColor;
    _perpLabelFontSize =
        annotation?.effectivePerpendicularLabelStyle.fontSize ?? 12.0;
    _perpLabelFontWeight =
        annotation?.effectivePerpendicularLabelStyle.fontWeight ??
            FontWeight.normal;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _startIndexController.dispose();
    _endIndexController.dispose();
    _perpIndexController.dispose();
    _perpLabelController.dispose();
    super.dispose();
  }

  /// Returns the number of data points in the currently selected series.
  int get _selectedSeriesPointCount {
    final series = widget.availableSeries
        .where((s) => s.id == _selectedSeriesId)
        .firstOrNull;
    return series?.points.length ?? 0;
  }

  String _getDashPatternName([List<double>? pattern]) {
    final p = pattern ?? _dashPattern;
    if (p == null) return 'Solid';
    for (final entry in _standardDashPatterns.entries) {
      if (_listEquals(entry.value, p)) return entry.key;
    }
    return 'Solid';
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
    if (_selectedSeriesId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a series')));
      return;
    }

    final startIndex = int.tryParse(_startIndexController.text);
    final endIndex = int.tryParse(_endIndexController.text);
    final maxIndex = _selectedSeriesPointCount - 1;

    if (startIndex == null || startIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Start index must be a non-negative integer')));
      return;
    }
    if (endIndex == null || endIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('End index must be a non-negative integer')));
      return;
    }
    if (startIndex == endIndex) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Start and end indices must be different')));
      return;
    }
    if (maxIndex >= 0 && (startIndex > maxIndex || endIndex > maxIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Indices must be between 0 and $maxIndex')));
      return;
    }

    // Perpendicular validation
    int? perpIndex;
    if (_perpEnabled && _perpIndexController.text.isNotEmpty) {
      perpIndex = int.tryParse(_perpIndexController.text);
      if (perpIndex == null || perpIndex < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Perpendicular index must be a non-negative integer')));
        return;
      }
      if (maxIndex >= 0 && perpIndex > maxIndex) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Perpendicular index must be between 0 and $maxIndex')));
        return;
      }
    }

    final annotation = ChordAnnotation(
      id: widget.annotation?.id,
      seriesId: _selectedSeriesId,
      startIndex: startIndex,
      endIndex: endIndex,
      label: _labelController.text.isEmpty ? null : _labelController.text,
      style: AnnotationStyle(
        textStyle: TextStyle(
          color: _labelTextColor,
          fontSize: _labelFontSize,
          fontWeight: _labelFontWeight,
        ),
        backgroundColor: _labelBgColor,
      ),
      lineColor: _lineColor,
      lineWidth: _lineWidth,
      dashPattern: _dashPattern,
      elevation: _elevation,
      perpendicularIndex: perpIndex,
      perpendicularLabel: _perpLabelController.text.isEmpty
          ? null
          : _perpLabelController.text,
      perpendicularLabelStyle: AnnotationStyle(
        textStyle: TextStyle(
          color: _perpLabelTextColor,
          fontSize: _perpLabelFontSize,
          fontWeight: _perpLabelFontWeight,
        ),
        backgroundColor: _perpLabelBgColor,
      ),
      perpendicularLineColor:
          _perpSeparateStyling ? _perpLineColor : null,
      perpendicularLineWidth:
          _perpSeparateStyling ? _perpLineWidth : null,
      perpendicularDashPattern:
          _perpSeparateStyling ? _perpDashPattern : null,
      perpendicularElevation:
          _perpSeparateStyling ? _perpElevation : null,
    );

    Navigator.of(context).pop(annotation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.annotation != null;
    final pointCount = _selectedSeriesPointCount;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnnotationDialogHeader(
              key: const ValueKey('chord-dialog-sticky-header'),
              title: isEditing ? 'Edit Chord' : 'Add Chord',
              icon: Icons.show_chart,
              primaryLabel: isEditing ? 'Update' : 'Add',
              onPrimary: _handleCreate,
              onCancel: () => Navigator.of(context).pop(),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Series Selection
                    if (widget.availableSeries.length > 1) ...[
                      Text('Target Series',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSeriesId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.show_chart),
                        ),
                        items: widget.availableSeries.map((series) {
                          return DropdownMenuItem(
                            value: series.id,
                            child: Text(
                                series.name ?? series.id),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSeriesId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ] else if (widget.availableSeries.length == 1) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.show_chart,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Text(
                              'Series: ${widget.availableSeries.first.name ?? _selectedSeriesId}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Data Point Indices
                    Text('Data Points', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    if (pointCount > 0)
                      Text(
                        'Valid range: 0 – ${pointCount - 1} ($pointCount points)',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startIndexController,
                            decoration: const InputDecoration(
                              labelText: 'Start Index *',
                              hintText: '0',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.first_page),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _endIndexController,
                            decoration: const InputDecoration(
                              labelText: 'End Index *',
                              hintText: '1',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.last_page),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Label (Optional)
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        hintText: 'e.g., "Secant Line"',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      maxLength: 50,
                    ),

                    const SizedBox(height: 8),

                    _buildColorPalette(
                      label: 'Label color',
                      icon: Icons.format_color_text,
                      value: _labelTextColor,
                      keyPrefix: 'chord-label-text-color',
                      allowClear: false,
                      customColorFallback: Colors.black,
                      onChanged: (color) {
                        if (color != null) {
                          setState(() => _labelTextColor = color);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildColorPalette(
                      label: 'Label background',
                      icon: Icons.format_color_fill,
                      value: _labelBgColor,
                      keyPrefix: 'chord-label-background-color',
                      customColorFallback: Colors.white,
                      onChanged: (color) =>
                          setState(() => _labelBgColor = color),
                    ),

                    const SizedBox(height: 12),

                    // Label font size
                    Row(
                      children: [
                        const Icon(Icons.format_size, size: 20),
                        const SizedBox(width: 12),
                        const Text('Font Size'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _labelFontSize,
                            min: 8,
                            max: 24,
                            divisions: 16,
                            label: '${_labelFontSize.round()}',
                            onChanged: (v) =>
                                setState(() => _labelFontSize = v),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('${_labelFontSize.round()}',
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Label font weight
                    Row(
                      children: [
                        const Icon(Icons.format_bold, size: 20),
                        const SizedBox(width: 12),
                        const Text('Weight'),
                        const Spacer(),
                        SegmentedButton<FontWeight>(
                          segments: const [
                            ButtonSegment(
                                value: FontWeight.normal,
                                label: Text('Normal')),
                            ButtonSegment(
                                value: FontWeight.bold,
                                label: Text('Bold')),
                          ],
                          selected: {_labelFontWeight},
                          onSelectionChanged: (v) =>
                              setState(() => _labelFontWeight = v.first),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Line Style Section
                    Text('Line Style', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),

                    _buildColorPalette(
                      label: 'Color',
                      icon: Icons.palette,
                      value: _lineColor,
                      keyPrefix: 'chord-line-color',
                      allowClear: false,
                      customColorFallback: Colors.blue,
                      onChanged: (color) {
                        if (color != null) {
                          setState(() => _lineColor = color);
                        }
                      },
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
                            onChanged: (value) =>
                                setState(() => _lineWidth = value),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                              '${_lineWidth.toStringAsFixed(1)}px',
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Elevation/Glow
                    Row(
                      children: [
                        const Icon(Icons.blur_on, size: 20),
                        const SizedBox(width: 12),
                        const Text('Glow'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _elevation,
                            min: 0.0,
                            max: 12.0,
                            divisions: 24,
                            label: _elevation == 0
                                ? 'Off'
                                : _elevation.toStringAsFixed(1),
                            onChanged: (value) =>
                                setState(() => _elevation = value),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                              _elevation == 0
                                  ? 'Off'
                                  : _elevation.toStringAsFixed(1),
                              textAlign: TextAlign.right),
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
                          items: _standardDashPatterns.keys.map((name) {
                            return DropdownMenuItem(
                                value: name, child: Text(name));
                          }).toList(),
                          onChanged: (name) {
                            if (name != null) {
                              setState(
                                  () => _dashPattern = _standardDashPatterns[name]);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Perpendicular Line Section
                    Row(
                      children: [
                        Text('Perpendicular Line',
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Switch(
                          value: _perpEnabled,
                          onChanged: (v) =>
                              setState(() => _perpEnabled = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drop-line from chord to a data point',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),

                    if (_perpEnabled) ...[
                      const SizedBox(height: 16),

                      // Perpendicular Index
                      TextField(
                        controller: _perpIndexController,
                        decoration: InputDecoration(
                          labelText: 'Data Point Index *',
                          hintText: 'e.g., 8',
                          helperText: pointCount > 0
                              ? 'Valid range: 0 – ${pointCount - 1}'
                              : null,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.my_location),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 16),

                      // Perpendicular Label
                      TextField(
                        controller: _perpLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Label (optional)',
                          hintText: 'e.g., "chord"',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        maxLength: 50,
                      ),

                      const SizedBox(height: 8),

                      _buildColorPalette(
                        label: 'Label color',
                        icon: Icons.format_color_text,
                        value: _perpLabelTextColor,
                        keyPrefix: 'chord-perpendicular-label-text-color',
                        allowClear: false,
                        customColorFallback: Colors.black,
                        onChanged: (color) {
                          if (color != null) {
                            setState(() => _perpLabelTextColor = color);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildColorPalette(
                        label: 'Label background',
                        icon: Icons.format_color_fill,
                        value: _perpLabelBgColor,
                        keyPrefix:
                            'chord-perpendicular-label-background-color',
                        customColorFallback: Colors.white,
                        onChanged: (color) =>
                            setState(() => _perpLabelBgColor = color),
                      ),

                      const SizedBox(height: 12),

                      // Perp label font size
                      Row(
                        children: [
                          const Icon(Icons.format_size, size: 20),
                          const SizedBox(width: 12),
                          const Text('Font Size'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _perpLabelFontSize,
                              min: 8,
                              max: 24,
                              divisions: 16,
                              label: '${_perpLabelFontSize.round()}',
                              onChanged: (v) =>
                                  setState(() => _perpLabelFontSize = v),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('${_perpLabelFontSize.round()}',
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Perp label font weight
                      Row(
                        children: [
                          const Icon(Icons.format_bold, size: 20),
                          const SizedBox(width: 12),
                          const Text('Weight'),
                          const Spacer(),
                          SegmentedButton<FontWeight>(
                            segments: const [
                              ButtonSegment(
                                  value: FontWeight.normal,
                                  label: Text('Normal')),
                              ButtonSegment(
                                  value: FontWeight.bold,
                                  label: Text('Bold')),
                            ],
                            selected: {_perpLabelFontWeight},
                            onSelectionChanged: (v) => setState(
                                () => _perpLabelFontWeight = v.first),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Separate line styling toggle
                      SwitchListTile(
                        title: const Text('Separate styling'),
                        subtitle: const Text(
                            'Override chord line style'),
                        value: _perpSeparateStyling,
                        onChanged: (v) =>
                            setState(() => _perpSeparateStyling = v),
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_perpSeparateStyling) ...[
                        const SizedBox(height: 8),

                        _buildColorPalette(
                          label: 'Color',
                          icon: Icons.palette,
                          value: _perpLineColor,
                          keyPrefix: 'chord-perpendicular-line-color',
                          allowClear: false,
                          customColorFallback: Colors.blue,
                          onChanged: (color) {
                            if (color != null) {
                              setState(() => _perpLineColor = color);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Perp Width
                        Row(
                          children: [
                            const Icon(Icons.line_weight, size: 20),
                            const SizedBox(width: 12),
                            const Text('Width'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Slider(
                                value: _perpLineWidth,
                                min: 0.5,
                                max: 10.0,
                                divisions: 19,
                                label:
                                    '${_perpLineWidth.toStringAsFixed(1)}px',
                                onChanged: (v) =>
                                    setState(() => _perpLineWidth = v),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                  '${_perpLineWidth.toStringAsFixed(1)}px',
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Perp Glow
                        Row(
                          children: [
                            const Icon(Icons.blur_on, size: 20),
                            const SizedBox(width: 12),
                            const Text('Glow'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Slider(
                                value: _perpElevation,
                                min: 0.0,
                                max: 12.0,
                                divisions: 24,
                                label: _perpElevation == 0
                                    ? 'Off'
                                    : _perpElevation.toStringAsFixed(1),
                                onChanged: (v) =>
                                    setState(() => _perpElevation = v),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                  _perpElevation == 0
                                      ? 'Off'
                                      : _perpElevation.toStringAsFixed(1),
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Perp Dash Pattern
                        Row(
                          children: [
                            const Icon(Icons.more_horiz, size: 20),
                            const SizedBox(width: 12),
                            const Text('Pattern'),
                            const Spacer(),
                            DropdownButton<String>(
                              value:
                                  _getDashPatternName(_perpDashPattern),
                              items: _standardDashPatterns.keys.map((name) {
                                return DropdownMenuItem(
                                    value: name, child: Text(name));
                              }).toList(),
                              onChanged: (name) {
                                if (name != null) {
                                  setState(() => _perpDashPattern =
                                      _standardDashPatterns[name]);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildColorPalette({
    required String label,
    required IconData icon,
    required Color? value,
    required String keyPrefix,
    required ValueChanged<Color?> onChanged,
    bool allowClear = true,
    Color? customColorFallback,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        const SizedBox(height: 8),
        AnnotationColorPalette(
          value: value,
          keyPrefix: keyPrefix,
          allowClear: allowClear,
          customColorFallback: customColorFallback,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
