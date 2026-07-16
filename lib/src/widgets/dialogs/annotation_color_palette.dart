import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

/// Shared color palette used by the native annotation editors.
///
/// A null [value] means that no color override is selected. When [allowClear]
/// is enabled, the first swatch always provides a visible way to return to
/// that state, including after choosing a custom color.
class AnnotationColorPalette extends StatelessWidget {
  const AnnotationColorPalette({
    super.key,
    required this.value,
    required this.onChanged,
    required this.keyPrefix,
    this.allowClear = true,
    this.presetOpacity = 1,
    this.customColorFallback,
  }) : assert(presetOpacity >= 0 && presetOpacity <= 1);

  final Color? value;
  final ValueChanged<Color?> onChanged;
  final String keyPrefix;
  final bool allowClear;
  final double presetOpacity;
  final Color? customColorFallback;

  static const double _paletteHeight = 26;
  static const double _utilityWidth = 28;

  static const List<Color> _canonicalColors = [
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.lightBlue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
  ];

  List<Color> get _presetColors => presetOpacity == 1
      ? _canonicalColors
      : _canonicalColors
            .map((color) => color.withValues(alpha: presetOpacity))
            .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final presetColors = _presetColors;
    final customSelected =
        value != null && !presetColors.any((color) => _sameColor(value, color));

    return SizedBox(
      height: _paletteHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allowClear)
            SizedBox(width: _utilityWidth, child: _clearSwatch(context)),
          for (final color in presetColors)
            Expanded(child: _colorSwatch(context, color)),
          SizedBox(
            width: _utilityWidth,
            child: _customButton(context, selected: customSelected),
          ),
        ],
      ),
    );
  }

  Widget _clearSwatch(BuildContext context) {
    final selected = value == null;
    return Tooltip(
      message: 'No color',
      child: Semantics(
        label: 'Clear color',
        button: true,
        selected: selected,
        child: _swatchTarget(
          key: ValueKey('$keyPrefix-clear'),
          onTap: () => onChanged(null),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.block,
            size: 16,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _colorSwatch(BuildContext context, Color color) {
    final selected = _sameColor(value, color);
    return Tooltip(
      message: selected && allowClear ? 'Click again to clear' : 'Select color',
      child: Semantics(
        label: selected && allowClear ? 'Clear selected color' : 'Select color',
        button: true,
        selected: selected,
        child: _swatchTarget(
          key: ValueKey('$keyPrefix-${color.toARGB32()}'),
          onTap: () => onChanged(selected && allowClear ? null : color),
          color: color,
          child: selected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: _contrastColor(
                    Color.alphaBlend(
                      color,
                      Theme.of(context).colorScheme.surface,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _swatchTarget({
    required Key key,
    required VoidCallback onTap,
    required Color color,
    required Widget? child,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(alignment: Alignment.center, color: color, child: child),
    );
  }

  Widget _customButton(BuildContext context, {required bool selected}) {
    final colors = Theme.of(context).colorScheme;
    final buttonColor = selected
        ? value ?? colors.surfaceContainerHighest
        : colors.surfaceContainerHighest;
    final iconColor = selected
        ? _contrastColor(Color.alphaBlend(buttonColor, colors.surface))
        : colors.onSurfaceVariant;
    return Tooltip(
      message: 'Choose custom color',
      child: InkWell(
        key: ValueKey('$keyPrefix-custom'),
        onTap: () => _chooseCustomColor(context),
        borderRadius: BorderRadius.zero,
        child: Container(
          alignment: Alignment.center,
          color: buttonColor,
          child: Icon(Icons.palette_outlined, size: 16, color: iconColor),
        ),
      ),
    );
  }

  Future<void> _chooseCustomColor(BuildContext context) async {
    var selectedColor = value ?? customColorFallback ?? _presetColors[7];
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: selectedColor,
            onColorChanged: (color) => selectedColor = color,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(selectedColor),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  Color _contrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  bool _sameColor(Color? first, Color second) {
    return first?.toARGB32() == second.toARGB32();
  }
}
