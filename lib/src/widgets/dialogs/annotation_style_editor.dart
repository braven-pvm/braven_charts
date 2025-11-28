// Copyright (c) 2025 braven_charts. All rights reserved.
// Annotation Style Editor for BravenChartPlus

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../../models/annotation_style.dart';

/// Reusable widget for editing annotation styling properties.
///
/// Provides a comprehensive style editor with:
/// - Text color (preset + custom picker)
/// - Text size (8-32px slider)
/// - Text weight (light to bold)
/// - Background color (preset + custom picker)
/// - Border color (preset + custom picker)
/// - Border width (0-8px slider)
/// - Border radius (0-24px slider)
/// - Padding (0-24px slider)
///
/// Used by TextAnnotationDialog and future annotation dialogs for consistent UX.
///
/// Example usage:
/// ```dart
/// AnnotationStyleEditor(
///   initialStyle: currentStyle,
///   onStyleChanged: (newStyle) {
///     setState(() {
///       currentStyle = newStyle;
///     });
///   },
///   showTextControls: true,
///   showBackgroundControls: true,
///   showBorderControls: true,
/// )
/// ```
class AnnotationStyleEditor extends StatefulWidget {
  /// Creates an annotation style editor.
  ///
  /// [initialStyle] - Starting style values (defaults applied if null)
  /// [onStyleChanged] - Callback invoked when any style property changes
  /// [showTextControls] - Whether to show text color/size/weight (default: true)
  /// [showBackgroundControls] - Whether to show background color (default: true)
  /// [showBorderControls] - Whether to show border properties (default: true)
  /// [showPaddingControls] - Whether to show padding slider (default: false)
  const AnnotationStyleEditor({
    super.key,
    this.initialStyle,
    required this.onStyleChanged,
    this.showTextControls = true,
    this.showBackgroundControls = true,
    this.showBorderControls = true,
    this.showPaddingControls = false,
  });

  final AnnotationStyle? initialStyle;
  final void Function(AnnotationStyle style) onStyleChanged;
  final bool showTextControls;
  final bool showBackgroundControls;
  final bool showBorderControls;
  final bool showPaddingControls;

  @override
  State<AnnotationStyleEditor> createState() => _AnnotationStyleEditorState();
}

class _AnnotationStyleEditorState extends State<AnnotationStyleEditor> {
  // Style properties
  late Color _textColor;
  late double _fontSize;
  late FontWeight _fontWeight;
  late Color _backgroundColor;
  late Color _borderColor;
  late double _borderWidth;
  late double _borderRadius;
  late double _paddingValue;

  // Expanded state for sections
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize from provided style or defaults
    final style = widget.initialStyle ?? const AnnotationStyle();
    _textColor = style.textColor;
    _fontSize = style.fontSize;
    _fontWeight = style.fontWeight;
    _backgroundColor = style.backgroundColor ?? Colors.white;
    _borderColor = style.borderColor ?? Colors.grey;
    _borderWidth = style.borderWidth;
    _borderRadius = (style.borderRadius?.topLeft.x ?? 4.0);
    _paddingValue = (style.padding?.top ?? 8.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Styling',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ),

        if (_isExpanded) ...[
          const SizedBox(height: 12),

          // Text controls
          if (widget.showTextControls) ...[
            _buildTextColorPicker(),
            const SizedBox(height: 16),
            _buildFontSizeSlider(),
            const SizedBox(height: 16),
            _buildFontWeightSelector(),
            const SizedBox(height: 16),
          ],

          // Background controls
          if (widget.showBackgroundControls) ...[
            _buildBackgroundColorPicker(),
            const SizedBox(height: 16),
          ],

          // Border controls
          if (widget.showBorderControls) ...[
            _buildBorderColorPicker(),
            const SizedBox(height: 16),
            _buildBorderWidthSlider(),
            const SizedBox(height: 16),
            _buildBorderRadiusSlider(),
            const SizedBox(height: 16),
          ],

          // Padding controls
          if (widget.showPaddingControls) ...[
            _buildPaddingSlider(),
          ],
        ],
      ],
    );
  }

  Widget _buildTextColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Color',
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildColorSelector(
          currentColor: _textColor,
          onColorChanged: (color) {
            setState(() {
              _textColor = color;
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Background Color',
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildColorSelector(
          currentColor: _backgroundColor,
          onColorChanged: (color) {
            setState(() {
              _backgroundColor = color;
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  Widget _buildBorderColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Border Color',
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildColorSelector(
          currentColor: _borderColor,
          onColorChanged: (color) {
            setState(() {
              _borderColor = color;
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorSelector({
    required Color currentColor,
    required void Function(Color) onColorChanged,
  }) {
    final presetColors = [
      Colors.black,
      Colors.white,
      Colors.grey[600]!,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...presetColors.map((color) {
          final isSelected = currentColor == color;
          return InkWell(
            onTap: () => onColorChanged(color),
            borderRadius: BorderRadius.circular(5),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected ? Colors.black87 : Colors.grey.shade300,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: _getContrastColor(color),
                    )
                  : null,
            ),
          );
        }),
        // Custom color button
        InkWell(
          onTap: () => _showCustomColorPicker(currentColor, onColorChanged),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.palette, size: 16, color: Colors.deepOrange.shade400),
                const SizedBox(width: 5),
                const Text(
                  'Custom',
                  style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Text Size',
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
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
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  Widget _buildFontWeightSelector() {
    final weights = [
      (FontWeight.w300, 'Light'),
      (FontWeight.w400, 'Normal'),
      (FontWeight.w500, 'Medium'),
      (FontWeight.w600, 'Semi-Bold'),
      (FontWeight.w700, 'Bold'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Weight',
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: weights.map((entry) {
            final weight = entry.$1;
            final label = entry.$2;
            final isSelected = _fontWeight == weight;
            return InkWell(
              onTap: () {
                setState(() {
                  _fontWeight = weight;
                  _notifyStyleChanged();
                });
              },
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
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

  Widget _buildBorderWidthSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Border Width',
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_borderWidth.toStringAsFixed(1)}px',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ],
        ),
        Slider(
          value: _borderWidth,
          min: 0.0,
          max: 8.0,
          divisions: 32,
          onChanged: (value) {
            setState(() {
              _borderWidth = value;
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  Widget _buildBorderRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Border Radius',
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_borderRadius.toInt()}px',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ],
        ),
        Slider(
          value: _borderRadius,
          min: 0,
          max: 24,
          divisions: 24,
          onChanged: (value) {
            setState(() {
              _borderRadius = value;
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPaddingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Padding',
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_paddingValue.toInt()}px',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ],
        ),
        Slider(
          value: _paddingValue,
          min: 0,
          max: 24,
          divisions: 24,
          onChanged: (value) {
            setState(() {
              _paddingValue = value;
              _notifyStyleChanged();
            });
          },
        ),
      ],
    );
  }

  void _showCustomColorPicker(Color currentColor, void Function(Color) onColorChanged) {
    Color selectedColor = currentColor;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Color'),
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
                onColorChanged(selectedColor);
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Use white text on dark backgrounds, black on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _notifyStyleChanged() {
    widget.onStyleChanged(
      AnnotationStyle(
        textStyle: TextStyle(
          color: _textColor,
          fontSize: _fontSize,
          fontWeight: _fontWeight,
        ),
        backgroundColor: _backgroundColor,
        borderColor: _borderColor,
        borderWidth: _borderWidth,
        borderRadius: BorderRadius.circular(_borderRadius),
        padding: EdgeInsets.all(_paddingValue),
      ),
    );
  }
}
