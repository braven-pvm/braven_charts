part of 'annotation_color_palette.dart';

// Recent colors belong to this mounted palette, not a process-wide singleton.
class _CustomColorButton extends StatefulWidget {
  const _CustomColorButton({
    super.key,
    required this.keyPrefix,
    required this.initialColor,
    required this.buttonColor,
    required this.iconColor,
    required this.onChanged,
  });

  final String keyPrefix;
  final Color initialColor;
  final Color buttonColor;
  final Color iconColor;
  final ValueChanged<Color?> onChanged;

  @override
  State<_CustomColorButton> createState() => _CustomColorButtonState();
}

class _CustomColorButtonState extends State<_CustomColorButton> {
  final List<Color> _recentColors = [];

  Future<void> _chooseColor() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => _CustomColorDialog(
        initialColor: widget.initialColor,
        recentColors: List.unmodifiable(_recentColors),
        keyPrefix: widget.keyPrefix,
      ),
    );
    if (!mounted || result == null) return;
    _recentColors.removeWhere((color) => color.toARGB32() == result.toARGB32());
    _recentColors.insert(0, result);
    if (_recentColors.length > 5) _recentColors.removeLast();
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Choose custom color',
    child: InkWell(
      key: ValueKey('${widget.keyPrefix}-custom'),
      onTap: _chooseColor,
      borderRadius: BorderRadius.zero,
      child: Container(
        alignment: Alignment.center,
        color: widget.buttonColor,
        child: Icon(Icons.palette_outlined, size: 16, color: widget.iconColor),
      ),
    ),
  );
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({
    required this.initialColor,
    required this.recentColors,
    required this.keyPrefix,
  });

  final Color initialColor;
  final List<Color> recentColors;
  final String keyPrefix;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  static const _primaryColors = <String, MaterialColor>{
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Deep purple': Colors.deepPurple,
    'Indigo': Colors.indigo,
    'Blue': Colors.blue,
    'Light blue': Colors.lightBlue,
    'Cyan': Colors.cyan,
    'Teal': Colors.teal,
    'Green': Colors.green,
    'Light green': Colors.lightGreen,
    'Lime': Colors.lime,
    'Yellow': Colors.yellow,
    'Amber': Colors.amber,
    'Orange': Colors.orange,
    'Deep orange': Colors.deepOrange,
    'Brown': Colors.brown,
    'Grey': Colors.grey,
    'Blue grey': Colors.blueGrey,
  };
  static const _accentColors = <String, MaterialAccentColor>{
    'Red': Colors.redAccent,
    'Pink': Colors.pinkAccent,
    'Purple': Colors.purpleAccent,
    'Deep purple': Colors.deepPurpleAccent,
    'Indigo': Colors.indigoAccent,
    'Blue': Colors.blueAccent,
    'Light blue': Colors.lightBlueAccent,
    'Cyan': Colors.cyanAccent,
    'Teal': Colors.tealAccent,
    'Green': Colors.greenAccent,
    'Light green': Colors.lightGreenAccent,
    'Lime': Colors.limeAccent,
    'Yellow': Colors.yellowAccent,
    'Amber': Colors.amberAccent,
    'Orange': Colors.orangeAccent,
    'Deep orange': Colors.deepOrangeAccent,
  };

  late Color _color;
  late HSVColor _hsv;
  late final TextEditingController _hexController;
  bool _accent = false;
  ColorSwatch<int> _shadeColor = Colors.blue;
  String _shadeName = 'Blue';
  String? _hexError;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
    _hsv = HSVColor.fromColor(_color);
    _hexController = TextEditingController(text: _hexCode(_color));
    _identifyShade(_color);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _hexCode(Color color) =>
      color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  void _identifyShade(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    for (final family in [_primaryColors, _accentColors]) {
      for (final entry in family.entries) {
        final shades = entry.value is MaterialAccentColor
            ? const [100, 200, 400, 700]
            : const [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
        if (shades.any(
          (shade) => (entry.value[shade]!.toARGB32() & 0xFFFFFF) == rgb,
        )) {
          _shadeColor = entry.value;
          _shadeName = entry.key;
          _accent = entry.value is MaterialAccentColor;
          return;
        }
      }
    }
  }

  void _setColor(Color color) {
    setState(() {
      _color = color;
      _hsv = HSVColor.fromColor(color);
      _identifyShade(color);
      _hexError = null;
      _hexController.text = _hexCode(color);
    });
  }

  void _editHex(String text) {
    final code = text.trim().replaceFirst(RegExp(r'^#'), '');
    final valid = RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(code);
    setState(() {
      _hexError = valid ? null : 'Use 6 RGB or 8 ARGB hex digits.';
      if (!valid) return;
      final value = int.parse(code, radix: 16);
      _color = code.length == 8
          ? Color(value)
          : Color(value | (_color.toARGB32() & 0xFF000000));
      _hsv = HSVColor.fromColor(_color);
      _identifyShade(_color);
    });
  }

  void _setHsv(HSVColor hsv) {
    setState(() {
      // Keep the chosen hue/saturation even when brightness reaches zero.
      _hsv = hsv;
      _color = hsv.toColor();
      _hexError = null;
      _hexController.text = _hexCode(_color);
    });
  }

  Color _foregroundColor(Color background) {
    final luminance = background.computeLuminance();
    final blackContrast = (luminance + 0.05) / 0.05;
    final whiteContrast = 1.05 / (luminance + 0.05);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
  }

  Widget _swatch(Color color, String label, VoidCallback onTap) {
    final selected = _color.toARGB32() == color.toARGB32();
    // Choices remain discoverable even when the draft is fully transparent;
    // selecting one still retains the draft's alpha. The preview shows opacity.
    final displayColor = color.withValues(alpha: 1);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: SizedBox.square(
          dimension: 48,
          child: Material(
            color: displayColor,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: selected
                  ? Icon(Icons.check, color: _foregroundColor(displayColor))
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label · ${label == 'Hue' ? '${value.round()}°' : '${(value * 100).round()}%'}',
      ),
      Slider(
        key: ValueKey('${widget.keyPrefix}-${label.toLowerCase()}'),
        value: value,
        max: max,
        label: label,
        semanticFormatterCallback: (value) => label == 'Hue'
            ? '${value.round()} degrees'
            : '${(value * 100).round()} percent',
        onChanged: onChanged,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = _accent ? _accentColors : _primaryColors;
    final shades = _shadeColor is MaterialAccentColor
        ? const [100, 200, 400, 700]
        : const [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
    final previewColor = Color.alphaBlend(
      _color,
      Theme.of(context).colorScheme.surface,
    );
    return AlertDialog(
      title: const Text('Select Color'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SizedBox(
        width: 384,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${_hexCode(_color)}',
                style: TextStyle(color: _foregroundColor(previewColor)),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Primary'),
                  selected: !_accent,
                  onSelected: (_) => setState(() => _accent = false),
                ),
                ChoiceChip(
                  label: const Text('Accent'),
                  selected: _accent,
                  onSelected: (_) => setState(() => _accent = true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in colors.entries)
                  _swatch(
                    entry.value.withValues(alpha: _color.a),
                    '${_accent ? 'Accent' : 'Primary'} ${entry.key}',
                    () {
                      _shadeColor = entry.value;
                      _shadeName = entry.key;
                      _setColor(entry.value.withValues(alpha: _color.a));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$_shadeName shades',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shade in shades)
                  _swatch(
                    _shadeColor[shade]!.withValues(alpha: _color.a),
                    'Shade $shade',
                    () => _setColor(
                      _shadeColor[shade]!.withValues(alpha: _color.a),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              key: ValueKey('${widget.keyPrefix}-hex'),
              controller: _hexController,
              decoration: InputDecoration(
                labelText: 'Hex color',
                helperText: 'RGB preserves opacity; ARGB includes opacity.',
                helperMaxLines: 2,
                errorText: _hexError,
                border: const OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
              onChanged: _editHex,
            ),
            const SizedBox(height: 16),
            _slider(
              'Hue',
              _hsv.hue,
              360,
              (value) => _setHsv(_hsv.withHue(value)),
            ),
            _slider(
              'Saturation',
              _hsv.saturation,
              1,
              (value) => _setHsv(_hsv.withSaturation(value)),
            ),
            _slider(
              'Brightness',
              _hsv.value,
              1,
              (value) => _setHsv(_hsv.withValue(value)),
            ),
            _slider(
              'Opacity',
              _hsv.alpha,
              1,
              (value) => _setHsv(_hsv.withAlpha(value)),
            ),
            if (widget.recentColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent colors',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in widget.recentColors)
                    _swatch(
                      color,
                      'Recent #${_hexCode(color)}',
                      () => _setColor(color),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _hexError == null
              ? () => Navigator.of(context).pop(_color)
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
