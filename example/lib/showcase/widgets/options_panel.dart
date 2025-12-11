// Copyright 2025 Braven Charts - Options Panel Widgets
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// A panel for displaying configuration options.
///
/// Used in showcase pages to provide interactive controls for chart settings.
class OptionsPanel extends StatelessWidget {
  const OptionsPanel({
    super.key,
    required this.children,
    this.title = 'Options',
    this.width,
  });

  final List<Widget> children;
  final String title;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A collapsible section within an options panel.
class OptionSection extends StatefulWidget {
  const OptionSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? icon;

  @override
  State<OptionSection> createState() => _OptionSectionState();
}

class _OptionSectionState extends State<OptionSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Section content
        AnimatedCrossFade(
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// A boolean toggle option with label.
class BoolOption extends StatelessWidget {
  const BoolOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 11))
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

/// An enum dropdown option.
class EnumOption<T> extends StatelessWidget {
  const EnumOption({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelBuilder,
    this.subtitle,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).hintColor.withOpacity(0.7),
            ),
          ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(),
          ),
          items: values.map((v) {
            return DropdownMenuItem<T>(
              value: v,
              child: Text(
                labelBuilder?.call(v) ?? _defaultLabel(v),
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _defaultLabel(T value) {
    final str = value.toString();
    if (str.contains('.')) {
      // Enum: extract name after dot
      return str.split('.').last;
    }
    return str;
  }
}

/// A slider option with label and value display.
class SliderOption extends StatelessWidget {
  const SliderOption({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.suffix,
    this.decimalPlaces = 1,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String? suffix;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.toStringAsFixed(decimalPlaces);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(
              suffix != null ? '$displayValue $suffix' : displayValue,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// An integer slider option.
class IntSliderOption extends StatelessWidget {
  const IntSliderOption({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return SliderOption(
      label: label,
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      divisions: max - min,
      suffix: suffix,
      decimalPlaces: 0,
      onChanged: (v) => onChanged(v.round()),
    );
  }
}

/// A color picker option.
class ColorOption extends StatelessWidget {
  const ColorOption({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final Color value;
  final List<Color> colors;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: colors.map((color) {
            final isSelected = color.value == value.value;
            return GestureDetector(
              onTap: () => onChanged(color),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// A segmented button group for selecting from a few options.
class SegmentedOption<T> extends StatelessWidget {
  const SegmentedOption({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelBuilder,
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options.map((opt) {
        final label = labelBuilder?.call(opt) ?? opt.toString().split('.').last;
        return ButtonSegment<T>(
          value: opt,
          label: Text(label, style: const TextStyle(fontSize: 11.5)),
        );
      }).toList(),
      selected: {value},
      onSelectionChanged: (Set<T> selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
      showSelectedIcon: false,
    );
  }
}

/// A text input option.
class TextOption extends StatelessWidget {
  const TextOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// A button that triggers an action.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final style = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          )
        : isDestructive
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              )
            : null;

    return SizedBox(
      width: double.infinity,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: style,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            ),
    );
  }
}

/// An info box for displaying helpful tips.
class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.message,
    this.type = InfoBoxType.info,
  });

  final String message;
  final InfoBoxType type;

  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      InfoBoxType.info => (
          Colors.blue.shade50,
          Colors.blue.shade200,
          Colors.blue.shade900
        ),
      InfoBoxType.warning => (
          Colors.orange.shade50,
          Colors.orange.shade200,
          Colors.orange.shade900
        ),
      InfoBoxType.success => (
          Colors.green.shade50,
          Colors.green.shade200,
          Colors.green.shade900
        ),
      InfoBoxType.error => (
          Colors.red.shade50,
          Colors.red.shade200,
          Colors.red.shade900
        ),
    };

    final icon = switch (type) {
      InfoBoxType.info => Icons.info_outline,
      InfoBoxType.warning => Icons.warning_amber_outlined,
      InfoBoxType.success => Icons.check_circle_outline,
      InfoBoxType.error => Icons.error_outline,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.$2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.$3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: colors.$3),
            ),
          ),
        ],
      ),
    );
  }
}

enum InfoBoxType { info, warning, success, error }
