// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../annotations/annotation_style.dart';

/// Reusable widget for editing annotation styling properties.
///
/// Provides a comprehensive style editor with:
/// - Text color (preset + custom picker)
/// - Text size (8-32px slider)
/// - Background color (preset + custom picker)
/// - Border color (preset + custom picker)
/// - Border width (0-8px slider)
/// - Border radius (0-24px slider)
///
/// Used by TextAnnotationDialog and future annotation dialogs for consistent UX.
class AnnotationStyleEditor extends StatefulWidget {
  /// Creates an annotation style editor.
  ///
  /// [initialStyle] - Starting style values (defaults applied if null)
  /// [onStyleChanged] - Callback invoked when any style property changes
  /// [showTextControls] - Whether to show text color/size (default: true)
  /// [showBackgroundControls] - Whether to show background color (default: true)
  /// [showBorderControls] - Whether to show border properties (default: true)
  const AnnotationStyleEditor({
    super.key,
    this.initialStyle,
    required this.onStyleChanged,
    this.showTextControls = true,
    this.showBackgroundControls = true,
    this.showBorderControls = true,
  });

  final AnnotationStyle? initialStyle;
  final void Function(AnnotationStyle style) onStyleChanged;
  final bool showTextControls;
  final bool showBackgroundControls;
  final bool showBorderControls;

  @override
  State<AnnotationStyleEditor> createState() => _AnnotationStyleEditorState();
}

class _AnnotationStyleEditorState extends State<AnnotationStyleEditor> {
  // Style properties
  late Color _textColor;
  late double _fontSize;
  late Color _backgroundColor;
  late Color _borderColor;
  late double _borderWidth;
  late double _borderRadius;

  // Expanded state for sections
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize from provided style or defaults
    final style = widget.initialStyle ?? const AnnotationStyle();
    _textColor = style.textColor;
    _fontSize = style.fontSize;
    _backgroundColor = style.backgroundColor ?? Colors.white;
    _borderColor = style.borderColor ?? Colors.grey;
    _borderWidth = style.borderWidth;
    _borderRadius = (style.borderRadius?.topLeft.x ?? 4.0);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset colors
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetColors.map((color) {
            final isSelected = currentColor == color;
            return InkWell(
              onTap: () => onColorChanged(color),
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
                        color: _getContrastColor(color),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        // Custom color picker button
        InkWell(
          onTap: () => _showCustomColorPicker(currentColor, onColorChanged),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.palette, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Custom Color',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
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
              '${_borderWidth.toInt()}px',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ],
        ),
        Slider(
          value: _borderWidth,
          min: 0,
          max: 8,
          divisions: 16,
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

  void _showCustomColorPicker(Color currentColor, void Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => _CustomColorPickerDialog(
        initialColor: currentColor,
        onColorSelected: onColorChanged,
      ),
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
        ),
        backgroundColor: _backgroundColor,
        borderColor: _borderColor,
        borderWidth: _borderWidth,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
    );
  }
}

/// Custom color picker dialog with RGB sliders and hex input.
class _CustomColorPickerDialog extends StatefulWidget {
  const _CustomColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  final Color initialColor;
  final void Function(Color) onColorSelected;

  @override
  State<_CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late double _red;
  late double _green;
  late double _blue;
  late double _alpha;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final a = (widget.initialColor.a * 255).round();
    final r = (widget.initialColor.r * 255).round();
    final g = (widget.initialColor.g * 255).round();
    final b = (widget.initialColor.b * 255).round();
    _red = r.toDouble();
    _green = g.toDouble();
    _blue = b.toDouble();
    _alpha = a.toDouble();
    _hexController = TextEditingController(text: _colorToHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => Color.fromARGB(_alpha.toInt(), _red.toInt(), _green.toInt(), _blue.toInt());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.palette, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Custom Color',
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

            // Color preview
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 20),

            // Hex input
            TextField(
              controller: _hexController,
              decoration: InputDecoration(
                labelText: 'Hex Code',
                prefixText: '#',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              onChanged: _onHexChanged,
            ),
            const SizedBox(height: 20),

            // RGB Sliders
            _buildColorSlider('Red', _red, Colors.red, (value) {
              setState(() {
                _red = value;
                _updateHexFromRgb();
              });
            }),
            const SizedBox(height: 12),
            _buildColorSlider('Green', _green, Colors.green, (value) {
              setState(() {
                _green = value;
                _updateHexFromRgb();
              });
            }),
            const SizedBox(height: 12),
            _buildColorSlider('Blue', _blue, Colors.blue, (value) {
              setState(() {
                _blue = value;
                _updateHexFromRgb();
              });
            }),
            const SizedBox(height: 12),
            _buildColorSlider('Opacity', _alpha, Colors.grey, (value) {
              setState(() {
                _alpha = value;
                _updateHexFromRgb();
              });
            }),
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
                  onPressed: () {
                    widget.onColorSelected(_currentColor);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSlider(String label, double value, Color trackColor, void Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              value.toInt().toString(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[800]),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: trackColor,
            thumbColor: trackColor,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _colorToHex(Color color) {
    final a = (color.a * 255).round() & 0xff;
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return '${a.toRadixString(16).padLeft(2, '0')}'
            '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _onHexChanged(String hex) {
    // Remove # if present
    hex = hex.replaceAll('#', '');

    // Parse hex to color
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity if not specified
    }

    if (hex.length == 8) {
      try {
        final color = Color(int.parse(hex, radix: 16));
        final a = (color.a * 255).round();
        final r = (color.r * 255).round();
        final g = (color.g * 255).round();
        final b = (color.b * 255).round();
        setState(() {
          _alpha = a.toDouble();
          _red = r.toDouble();
          _green = g.toDouble();
          _blue = b.toDouble();
        });
      } catch (e) {
        // Invalid hex, ignore
      }
    }
  }

  void _updateHexFromRgb() {
    _hexController.text = _colorToHex(_currentColor);
  }
}
