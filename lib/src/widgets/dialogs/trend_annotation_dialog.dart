// Copyright (c) 2025 braven_charts. All rights reserved.
// TrendAnnotation Dialog - Material Design 3

import 'package:flutter/material.dart';

import '../../models/chart_annotation.dart';
import 'annotation_color_palette.dart';
import 'annotation_dialog_header.dart';

/// Dialog for creating or editing a TrendAnnotation.
///
/// Provides UI for configuring:
/// - Series selection (if multiple available)
/// - Trend type (linear, polynomial, moving average, etc.)
/// - Type-specific parameters (window size, polynomial degree)
/// - Line style (color, width, dash pattern)
/// - Optional label
class TrendAnnotationDialog extends StatefulWidget {
  const TrendAnnotationDialog({
    super.key,
    this.annotation,
    required this.availableSeries,
    this.preselectedSeriesId,
  });

  /// Existing annotation to edit, or null to create new.
  final TrendAnnotation? annotation;

  /// List of available series IDs to choose from.
  final List<String> availableSeries;

  /// Pre-selected series ID (when adding trend from series context menu).
  final String? preselectedSeriesId;

  @override
  State<TrendAnnotationDialog> createState() => _TrendAnnotationDialogState();
}

class _TrendAnnotationDialogState extends State<TrendAnnotationDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _windowSizeController;
  late final TextEditingController _degreeController;

  late String _selectedSeriesId;
  late TrendType _trendType;
  late Color _lineColor;
  late double _lineWidth;
  late List<double>? _dashPattern;
  late double _elevation;
  late double _loessSpan;
  late int _loessRobustnessIterations;
  late int _loessSampleCount;
  late bool _showEquation;
  late bool _showRSquared;
  late bool _showSampleCount;
  late bool _showPearsonCorrelation;
  late bool _showSpearmanCorrelation;
  late bool _showConfidenceBand;
  late bool _showPredictionBand;
  late double _confidenceLevel;

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
    _selectedSeriesId =
        annotation?.seriesId ??
        widget.preselectedSeriesId ??
        (widget.availableSeries.isNotEmpty ? widget.availableSeries.first : '');
    _trendType = annotation?.trendType ?? TrendType.linear;
    _labelController = TextEditingController(text: annotation?.label ?? '');
    _windowSizeController = TextEditingController(
      text: annotation?.windowSize?.toString() ?? '5',
    );
    _degreeController = TextEditingController(
      text: annotation?.degree.toString() ?? '2',
    );
    _lineColor = annotation?.lineColor ?? Colors.blue;
    _lineWidth = annotation?.lineWidth ?? 2.0;
    _dashPattern = annotation?.dashPattern;
    _elevation = annotation?.elevation ?? 0.0;
    _loessSpan = annotation?.loessSpan ?? 0.5;
    _loessRobustnessIterations = annotation?.loessRobustnessIterations ?? 2;
    _loessSampleCount = annotation?.loessSampleCount ?? 100;
    _showEquation = annotation?.showEquation ?? false;
    _showRSquared = annotation?.showRSquared ?? false;
    _showSampleCount = annotation?.showSampleCount ?? false;
    _showPearsonCorrelation = annotation?.showPearsonCorrelation ?? false;
    _showSpearmanCorrelation = annotation?.showSpearmanCorrelation ?? false;
    _showConfidenceBand = annotation?.showConfidenceBand ?? false;
    _showPredictionBand = annotation?.showPredictionBand ?? false;
    _confidenceLevel = annotation?.confidenceLevel ?? 0.95;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _windowSizeController.dispose();
    _degreeController.dispose();
    super.dispose();
  }

  String _getDashPatternName() {
    if (_dashPattern == null) return 'Solid';
    for (final entry in _dashPatterns.entries) {
      if (_listEquals(entry.value, _dashPattern)) return entry.key;
    }
    // If custom pattern not in map, default to Solid to avoid dropdown error
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a series')));
      return;
    }

    // Validate type-specific parameters
    int? windowSize;
    if (_trendType == TrendType.movingAverage ||
        _trendType == TrendType.exponentialMovingAverage) {
      windowSize = int.tryParse(_windowSizeController.text);
      if (windowSize == null || windowSize <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid window size (positive integer)',
            ),
          ),
        );
        return;
      }
    }

    int degree = 2;
    if (_trendType == TrendType.polynomial) {
      final parsedDegree = int.tryParse(_degreeController.text);
      if (parsedDegree == null || parsedDegree <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid polynomial degree (positive integer)',
            ),
          ),
        );
        return;
      }
      degree = parsedDegree;
    }

    final annotation = TrendAnnotation(
      id: widget.annotation?.id,
      seriesId: _selectedSeriesId,
      trendType: _trendType,
      windowSize: windowSize,
      degree: degree,
      loessSpan: _loessSpan,
      loessRobustnessIterations: _loessRobustnessIterations,
      loessSampleCount: _loessSampleCount,
      showEquation: _showEquation,
      showRSquared: _showRSquared,
      showSampleCount: _showSampleCount,
      showPearsonCorrelation: _showPearsonCorrelation,
      showSpearmanCorrelation: _showSpearmanCorrelation,
      showConfidenceBand: _showConfidenceBand,
      showPredictionBand: _showPredictionBand,
      confidenceLevel: _confidenceLevel,
      confidenceBandColor: widget.annotation?.confidenceBandColor,
      predictionBandColor: widget.annotation?.predictionBandColor,
      confidenceBandOpacity: widget.annotation?.confidenceBandOpacity ?? 0.20,
      predictionBandOpacity: widget.annotation?.predictionBandOpacity ?? 0.10,
      label: _labelController.text.isEmpty ? null : _labelController.text,
      lineColor: _lineColor,
      lineWidth: _lineWidth,
      dashPattern: _dashPattern,
      elevation: _elevation,
      allowDragging: true, // Enable dragging by default
    );

    Navigator.of(context).pop(annotation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.annotation != null;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnnotationDialogHeader(
              key: const ValueKey('trend-dialog-sticky-header'),
              title: isEditing ? 'Edit Trend' : 'Add Trend',
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
                      Text('Target Series', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSeriesId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.show_chart),
                        ),
                        items: widget.availableSeries.map((seriesId) {
                          return DropdownMenuItem(
                            value: seriesId,
                            child: Text(seriesId),
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
                      // Show read-only series info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.show_chart,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Series: $_selectedSeriesId',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Trend Type Selection
                    Text('Trend Type', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...TrendType.values.map((type) {
                      return RadioListTile<TrendType>(
                        title: Text(_trendTypeName(type)),
                        subtitle: Text(_trendTypeDescription(type)),
                        value: type,
                        groupValue: _trendType,
                        onChanged: (value) {
                          if (value != null) setState(() => _trendType = value);
                        },
                      );
                    }),

                    const SizedBox(height: 16),

                    // Type-specific parameters
                    if (_trendType == TrendType.movingAverage ||
                        _trendType == TrendType.exponentialMovingAverage) ...[
                      TextField(
                        controller: _windowSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Window Size *',
                          hintText: 'Number of data points',
                          helperText: 'Number of data points to average',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.view_week),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_trendType == TrendType.polynomial) ...[
                      TextField(
                        controller: _degreeController,
                        decoration: const InputDecoration(
                          labelText: 'Polynomial Degree *',
                          hintText: 'e.g., 2 for quadratic',
                          helperText: '2 = quadratic, 3 = cubic, etc.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.functions),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_trendType == TrendType.loess) ...[
                      Text(
                        'LOESS smoothing',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use a wider neighborhood for a smoother curve. Robust passes reduce outlier influence.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TrendParameterSlider(
                        key: const ValueKey('trend-loess-span'),
                        label: 'Neighborhood',
                        valueLabel: '${(_loessSpan * 100).round()}%',
                        value: _loessSpan,
                        min: 0.1,
                        max: 1,
                        divisions: 18,
                        onChanged: (value) =>
                            setState(() => _loessSpan = value),
                      ),
                      _TrendParameterSlider(
                        key: const ValueKey('trend-loess-robustness'),
                        label: 'Robust passes',
                        valueLabel: '$_loessRobustnessIterations',
                        value: _loessRobustnessIterations.toDouble(),
                        min: 0,
                        max: 4,
                        divisions: 4,
                        onChanged: (value) => setState(
                          () => _loessRobustnessIterations = value.round(),
                        ),
                      ),
                      _TrendParameterSlider(
                        key: const ValueKey('trend-loess-samples'),
                        label: 'Curve detail',
                        valueLabel: '$_loessSampleCount points',
                        value: _loessSampleCount.toDouble(),
                        min: 20,
                        max: 200,
                        divisions: 9,
                        onChanged: (value) =>
                            setState(() => _loessSampleCount = value.round()),
                      ),
                      const SizedBox(height: 8),
                    ],

                    Text('Trend details', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the diagnostics shown beside the fitted line.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_trendType == TrendType.linear ||
                            _trendType == TrendType.polynomial)
                          FilterChip(
                            key: const ValueKey('trend-show-equation'),
                            label: const Text('Equation'),
                            selected: _showEquation,
                            onSelected: (value) =>
                                setState(() => _showEquation = value),
                          ),
                        FilterChip(
                          key: const ValueKey('trend-show-r-squared'),
                          label: const Text('R²'),
                          selected: _showRSquared,
                          onSelected: (value) =>
                              setState(() => _showRSquared = value),
                        ),
                        FilterChip(
                          key: const ValueKey('trend-show-sample-count'),
                          label: const Text('Sample n'),
                          selected: _showSampleCount,
                          onSelected: (value) =>
                              setState(() => _showSampleCount = value),
                        ),
                        FilterChip(
                          key: const ValueKey('trend-show-pearson'),
                          label: const Text('Pearson r'),
                          selected: _showPearsonCorrelation,
                          onSelected: (value) =>
                              setState(() => _showPearsonCorrelation = value),
                        ),
                        FilterChip(
                          key: const ValueKey('trend-show-spearman'),
                          label: const Text('Spearman ρ'),
                          selected: _showSpearmanCorrelation,
                          onSelected: (value) =>
                              setState(() => _showSpearmanCorrelation = value),
                        ),
                      ],
                    ),
                    if (_trendType == TrendType.linear) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Linear uncertainty',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'OLS bands assume independent observations, constant residual variance, normal residuals, and fixed X values.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            key: const ValueKey('trend-confidence-band'),
                            label: const Text('Mean confidence'),
                            selected: _showConfidenceBand,
                            onSelected: (value) =>
                                setState(() => _showConfidenceBand = value),
                          ),
                          FilterChip(
                            key: const ValueKey('trend-prediction-band'),
                            label: const Text('Future prediction'),
                            selected: _showPredictionBand,
                            onSelected: (value) =>
                                setState(() => _showPredictionBand = value),
                          ),
                        ],
                      ),
                      if (_showConfidenceBand || _showPredictionBand) ...[
                        const SizedBox(height: 8),
                        SegmentedButton<double>(
                          key: const ValueKey('trend-confidence-level'),
                          segments: const [
                            ButtonSegment(value: 0.90, label: Text('90%')),
                            ButtonSegment(value: 0.95, label: Text('95%')),
                            ButtonSegment(value: 0.99, label: Text('99%')),
                          ],
                          selected: {_confidenceLevel},
                          onSelectionChanged: (values) =>
                              setState(() => _confidenceLevel = values.first),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),

                    // Label (Optional)
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        hintText: 'e.g., "Linear Trend"',
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

                    const Row(
                      children: [
                        Icon(Icons.palette, size: 20),
                        SizedBox(width: 12),
                        Text('Color'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnnotationColorPalette(
                      value: _lineColor,
                      keyPrefix: 'trend-line-color',
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
                            textAlign: TextAlign.right,
                          ),
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
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (name) {
                            if (name != null) {
                              setState(
                                () => _dashPattern = _dashPatterns[name],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _trendTypeName(TrendType type) {
    switch (type) {
      case TrendType.linear:
        return 'Linear Regression';
      case TrendType.polynomial:
        return 'Polynomial Regression';
      case TrendType.movingAverage:
        return 'Moving Average';
      case TrendType.exponentialMovingAverage:
        return 'Exponential Moving Average';
      case TrendType.loess:
        return 'LOESS';
    }
  }

  String _trendTypeDescription(TrendType type) {
    switch (type) {
      case TrendType.linear:
        return 'Straight line fit (y = mx + b)';
      case TrendType.polynomial:
        return 'Curved fit (customizable degree)';
      case TrendType.movingAverage:
        return 'Simple moving average';
      case TrendType.exponentialMovingAverage:
        return 'Weighted moving average';
      case TrendType.loess:
        return 'Robust locally weighted curve';
    }
  }
}

class _TrendParameterSlider extends StatelessWidget {
  const _TrendParameterSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 108, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(valueLabel, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
