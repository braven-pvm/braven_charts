// Copyright 2025 Braven Charts - Options Panel Widgets
// SPDX-License-Identifier: MIT

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

/// Search and help metadata understood by the showcase property inspector.
@immutable
class ShowcasePropertyMetadata {
  const ShowcasePropertyMetadata({
    required this.label,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final String? description;
  final List<String> aliases;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      label,
      ?description,
      ...aliases,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

/// Implemented by controls which participate in inspector search.
abstract interface class ShowcaseInspectorEntry {
  ShowcasePropertyMetadata get inspectorMetadata;
}

/// Adds search metadata to a custom inspector widget.
class SearchableOption extends StatelessWidget
    implements ShowcaseInspectorEntry {
  const SearchableOption({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final String? description;
  final List<String> aliases;
  final Widget child;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description,
    aliases: aliases,
  );

  @override
  Widget build(BuildContext context) => child;
}

/// A panel for displaying configuration options.
///
/// Used in showcase pages to provide interactive controls for chart settings.
class OptionsPanel extends StatefulWidget {
  const OptionsPanel({
    super.key,
    required this.children,
    this.title = 'Options',
    this.width,
    this.headerEditor,
    this.headerEditorLabel = 'Additional options',
    this.headerEditorKey = 'options-panel-header-editor',
  });

  final List<Widget> children;
  final String title;
  final double? width;
  final Widget? headerEditor;
  final String headerEditorLabel;
  final String headerEditorKey;

  @override
  State<OptionsPanel> createState() => _OptionsPanelState();
}

class _OptionsPanelState extends State<OptionsPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _searchVisible = false;
  bool _helpVisible = false;
  int _sectionExpansionRevision = 0;
  bool _expandSections = true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _query = '';
      _searchVisible = false;
    });
  }

  void _setAllSectionsExpanded(bool expanded) {
    setState(() {
      _expandSections = expanded;
      _sectionExpansionRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleChildren = _query.isEmpty
        ? widget.children
        : widget.children
              .where((child) => _widgetMatchesQuery(child, _query))
              .toList(growable: false);
    final matchCount = _query.isEmpty
        ? 0
        : visibleChildren.fold<int>(
            0,
            (total, child) => total + _widgetMatchCount(child, _query),
          );

    return SizedBox(
      width: widget.width,
      child: Material(
        color: theme.cardColor,
        shape: Border(left: BorderSide(color: theme.dividerColor, width: 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<bool>(
                      key: const ValueKey('options-panel-section-actions'),
                      tooltip: 'Expand or collapse all sections',
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      initialValue: _expandSections,
                      constraints: const BoxConstraints(minWidth: 176),
                      onSelected: _setAllSectionsExpanded,
                      itemBuilder: (context) => const [
                        PopupMenuItem<bool>(
                          key: ValueKey('options-panel-expand-all'),
                          value: true,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.unfold_more, size: 18),
                            title: Text('Expand all sections'),
                          ),
                        ),
                        PopupMenuItem<bool>(
                          key: ValueKey('options-panel-collapse-all'),
                          value: false,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.unfold_less, size: 18),
                            title: Text('Collapse all sections'),
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.unfold_more, size: 16),
                    ),
                  ),
                  if (widget.headerEditor != null) ...[
                    IconButton(
                      key: ValueKey(widget.headerEditorKey),
                      tooltip: widget.headerEditorLabel,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 20,
                        height: 20,
                      ),
                      padding: const EdgeInsets.all(2),
                      onPressed: _showHeaderEditor,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton(
                    key: const ValueKey('options-panel-help-toggle'),
                    tooltip: _helpVisible
                        ? 'Hide property help'
                        : 'Show property help',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 20,
                      height: 20,
                    ),
                    padding: const EdgeInsets.all(2),
                    onPressed: () =>
                        setState(() => _helpVisible = !_helpVisible),
                    icon: Icon(
                      _helpVisible ? Icons.help : Icons.help_outline,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    key: const ValueKey('options-panel-search-toggle'),
                    tooltip: _searchVisible
                        ? 'Close property search'
                        : 'Search properties',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 20,
                      height: 20,
                    ),
                    padding: const EdgeInsets.all(2),
                    onPressed: _searchVisible ? _closeSearch : _openSearch,
                    icon: Icon(
                      _searchVisible ? Icons.close : Icons.search,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (_searchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  key: const ValueKey('options-panel-search'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    labelText: 'Search properties',
                    hintText: 'Try “tooltip”, “axis”, or “colour”',
                    prefixIcon: const Icon(Icons.search, size: 19),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('options-panel-search-clear'),
                            tooltip: 'Clear property search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  matchCount == 1
                      ? '1 matching property'
                      : '$matchCount matching properties',
                  key: const ValueKey('options-panel-match-count'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            // Content
            Expanded(
              child: _InspectorSectionExpansionScope(
                revision: _sectionExpansionRevision,
                expanded: _expandSections,
                child: _InspectorHelpScope(
                  visible: _helpVisible,
                  child: _InspectorSearchScope(
                    query: _query,
                    child: visibleChildren.isEmpty
                        ? const _NoPropertyMatches()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            children: visibleChildren,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHeaderEditor() async {
    final editor = widget.headerEditor;
    if (editor == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 19),
            const SizedBox(width: 8),
            Text(widget.headerEditorLabel),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: _InspectorHelpScope(
              visible: false,
              child: _InspectorSearchScope(query: '', child: editor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InspectorSearchScope extends InheritedWidget {
  const _InspectorSearchScope({required this.query, required super.child});

  final String query;

  static String queryOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_InspectorSearchScope>()
          ?.query ??
      '';

  @override
  bool updateShouldNotify(_InspectorSearchScope oldWidget) =>
      query != oldWidget.query;
}

class _InspectorSectionExpansionScope extends InheritedWidget {
  const _InspectorSectionExpansionScope({
    required this.revision,
    required this.expanded,
    required super.child,
  });

  final int revision;
  final bool expanded;

  static _InspectorSectionExpansionScope? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<_InspectorSectionExpansionScope>();

  @override
  bool updateShouldNotify(_InspectorSectionExpansionScope oldWidget) =>
      revision != oldWidget.revision || expanded != oldWidget.expanded;
}

class _NoPropertyMatches extends StatelessWidget {
  const _NoPropertyMatches();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No matching properties',
              key: const ValueKey('options-panel-empty-search'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Try a property name, API term, or description.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _widgetMatchesQuery(Widget widget, String query) {
  if (query.isEmpty) return true;
  if (widget is OptionSection) {
    return widget.inspectorMetadata.matches(query) ||
        widget.children.any((child) => _widgetMatchesQuery(child, query));
  }
  if (widget is ShowcaseInspectorEntry) {
    return (widget as ShowcaseInspectorEntry).inspectorMetadata.matches(query);
  }
  return false;
}

int _widgetMatchCount(Widget widget, String query) {
  if (widget is OptionSection) {
    if (widget.inspectorMetadata.matches(query)) {
      final childCount = widget.children
          .whereType<ShowcaseInspectorEntry>()
          .length;
      return childCount == 0 ? 1 : childCount;
    }
    return widget.children.fold<int>(
      0,
      (total, child) => total + _widgetMatchCount(child, query),
    );
  }
  if (widget is ShowcaseInspectorEntry &&
      (widget as ShowcaseInspectorEntry).inspectorMetadata.matches(query)) {
    return 1;
  }
  return 0;
}

class _OptionHelpButton extends StatelessWidget {
  const _OptionHelpButton({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey('option-help-${_keyToken(label)}'),
      tooltip: 'About $label',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 22, height: 22),
      padding: const EdgeInsets.all(2),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(label),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.help_outline, size: 16),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.label, this.description, this.style});

  final String label;
  final String? description;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (description == null || !_InspectorHelpScope.visibleOf(context)) {
      return Text(label, style: style);
    }
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        _OptionHelpButton(label: label, description: description!),
      ],
    );
  }
}

String _keyToken(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

class _OptionHelpCatalog {
  const _OptionHelpCatalog._();

  static const Map<String, String> _descriptions = <String, String>{
    'theme':
        'Changes the complete chart theme preset, including default colours, typography, grids, and interaction styling.',
    'theme preset':
        'Changes the complete chart theme preset while preserving explicit property overrides.',
    'show grid lines':
        'Shows or hides the chart grid used to compare values across the plotting area.',
    'show axis lines':
        'Shows or hides the primary axis strokes around the plotting area.',
    'show data markers':
        'Shows or hides the marker drawn at each rendered data point.',
    'show x scrollbar':
        'Shows a horizontal scrollbar that reflects and controls the visible X viewport.',
    'show y scrollbar':
        'Shows a vertical scrollbar that reflects and controls the visible Y viewport.',
    'show legend':
        'Shows or hides the legend that identifies the rendered series and encodings.',
    'enable zoom':
        'Allows pointer, wheel, keyboard, or touch gestures to change the visible chart range.',
    'enable pan':
        'Allows dragging or touch gestures to move the current chart viewport.',
    'line style': 'Selects the stroke pattern used to draw the line.',
    'seed':
        'A deterministic input. Reusing the same seed reproduces the same generated data and properties.',
    'playback interval':
        'Sets how long the randomizer keeps each generated chart visible before advancing.',
    'opacity':
        'Controls element transparency from fully transparent to fully opaque.',
    'corner radius':
        'Controls how strongly eligible element corners are rounded.',
    'border width': 'Controls the thickness of the element outline.',
    'line width': 'Controls the rendered stroke thickness.',
    'marker radius':
        'Controls marker size as a radius measured in logical pixels.',
    'marker shape': 'Selects the silhouette used for each data marker.',
    'value labels':
        'Shows or hides formatted values next to their chart elements.',
    'label position':
        'Selects where labels are placed relative to their chart elements.',
    'edge offset':
        'Adds space between a label and the edge of its chart element.',
    'category fill':
        'Controls how much of each category band is occupied by its marks.',
    'bar gap': 'Sets the gap between adjacent bars within a category.',
    'series count':
        'Sets how many independent data series are generated and displayed.',
    'point count': 'Sets how many data points are generated for each series.',
    'show tooltip':
        'Shows contextual values when a point or element is tracked.',
    'tooltip trigger': 'Selects which interaction opens a tooltip.',
    'tooltip position':
        'Controls where the tooltip is placed relative to the tracked element.',
    'selection effect':
        'Selects the visual treatment applied to selected chart elements.',
    'animation duration': 'Sets how long chart transitions take to complete.',
    'animation curve':
        'Selects the easing curve used during chart transitions.',
    'chart appearance':
        'Controls the chart theme, canvas, palette, and other global visual settings.',
    'labels':
        'Controls label visibility, formatting, placement, density, and collision behaviour.',
    'grid & axes':
        'Controls axis strokes, labels, ticks, grid visibility, and grid styling.',
    'legends': 'Controls legend visibility, placement, content, and styling.',
    'tooltips':
        'Controls tooltip visibility, triggers, placement, formatting, and styling.',
    'selection':
        'Controls how chart elements respond visually and semantically when selected.',
    'property randomizer':
        'Generates a reproducible combination of data and supported chart properties for inspection and stress testing.',
  };

  static String? descriptionFor(String label) =>
      _descriptions[label.trim().toLowerCase()];

  static String forSection(String label) =>
      descriptionFor(label) ??
      'Contains the editable properties for ${label.trim().toLowerCase()}.';

  static String forToggle(String label) =>
      descriptionFor(label) ??
      'Turns ${label.trim().toLowerCase()} on or off for the current chart.';

  static String forChoice(String label) =>
      descriptionFor(label) ??
      'Selects the ${label.trim().toLowerCase()} used by the current chart.';

  static String forNumber(String label, num min, num max) =>
      descriptionFor(label) ??
      'Adjusts ${label.trim().toLowerCase()} between $min and $max.';

  static String forColor(String label) =>
      descriptionFor(label) ??
      'Sets ${label.trim().toLowerCase()} with the shared preset, clear, and custom-colour controls.';

  static String forText(String label) =>
      descriptionFor(label) ??
      'Sets the text used for ${label.trim().toLowerCase()}.';

  static String forAction(String label) =>
      descriptionFor(label) ?? 'Runs the ${label.trim().toLowerCase()} action.';
}

class _InspectorHelpScope extends InheritedWidget {
  const _InspectorHelpScope({required this.visible, required super.child});

  final bool visible;

  static bool visibleOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_InspectorHelpScope>()
          ?.visible ??
      false;

  @override
  bool updateShouldNotify(_InspectorHelpScope oldWidget) =>
      visible != oldWidget.visible;
}

/// A collapsible section within an options panel.
class OptionSection extends StatefulWidget implements ShowcaseInspectorEntry {
  const OptionSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.icon,
    this.description,
    this.aliases = const <String>[],
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? icon;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: title,
    description: description ?? _OptionHelpCatalog.forSection(title),
    aliases: aliases,
  );

  @override
  State<OptionSection> createState() => _OptionSectionState();
}

class _OptionSectionState extends State<OptionSection> {
  late bool _isExpanded;
  int _lastExpansionRevision = -1;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final expansion = _InspectorSectionExpansionScope.maybeOf(context);
    if (expansion != null &&
        expansion.revision > 0 &&
        expansion.revision != _lastExpansionRevision) {
      _lastExpansionRevision = expansion.revision;
      _isExpanded = expansion.expanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _InspectorSearchScope.queryOf(context);
    final sectionMatches = widget.inspectorMetadata.matches(query);
    final visibleChildren = query.isEmpty || sectionMatches
        ? widget.children
        : widget.children
              .where((child) => _widgetMatchesQuery(child, query))
              .toList(growable: false);
    final effectiveExpanded = query.isNotEmpty || _isExpanded;
    final description = widget.inspectorMetadata.description;

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
                  Icon(widget.icon, size: 16, color: theme.colorScheme.primary),
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
                if (description != null &&
                    _InspectorHelpScope.visibleOf(context))
                  _OptionHelpButton(
                    label: widget.title,
                    description: description,
                  ),
                AnimatedRotation(
                  turns: effectiveExpanded ? 0.5 : 0,
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
            children: visibleChildren,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: effectiveExpanded
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
class BoolOption extends StatelessWidget implements ShowcaseInspectorEntry {
  const BoolOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forToggle(label),
    aliases: <String>[?subtitle, ...aliases],
  );

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: _OptionLabel(
        label: label,
        description: inspectorMetadata.description,
        style: const TextStyle(fontSize: 14),
      ),
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
class EnumOption<T> extends StatelessWidget implements ShowcaseInspectorEntry {
  const EnumOption({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelBuilder,
    this.subtitle,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;
  final String? subtitle;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forChoice(label),
    aliases: <String>[
      ?subtitle,
      ...values.map(
        (value) => labelBuilder?.call(value) ?? _defaultLabel(value),
      ),
      ...aliases,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionLabel(
          label: label,
          description: inspectorMetadata.description,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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
class SliderOption extends StatelessWidget implements ShowcaseInspectorEntry {
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
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String? suffix;
  final int decimalPlaces;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forNumber(label, min, max),
    aliases: aliases,
  );

  @override
  Widget build(BuildContext context) {
    final displayValue = value.toStringAsFixed(decimalPlaces);
    final hasRange = max > min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _OptionLabel(
                label: label,
                description: inspectorMetadata.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              suffix != null ? '$displayValue $suffix' : displayValue,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
            divisions: hasRange ? divisions : null,
            onChanged: hasRange ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

/// An integer slider option.
class IntSliderOption extends StatelessWidget
    implements ShowcaseInspectorEntry {
  const IntSliderOption({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? suffix;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forNumber(label, min, max),
    aliases: aliases,
  );

  @override
  Widget build(BuildContext context) {
    return SliderOption(
      label: label,
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      divisions: max - min,
      suffix: suffix,
      description: description,
      aliases: aliases,
      decimalPlaces: 0,
      onChanged: (v) => onChanged(v.round()),
    );
  }
}

/// A color picker option.
class ColorOption extends StatelessWidget implements ShowcaseInspectorEntry {
  const ColorOption({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.keyPrefix,
    this.clearValue,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final Color value;

  /// Retained for source compatibility and as the fallback used by the
  /// custom-colour dialog. Preset swatches come from [ChartColorPalette] so
  /// every showcase surface exposes the same canonical palette.
  final List<Color> colors;
  final ValueChanged<Color> onChanged;
  final String? keyPrefix;

  /// Value restored by the clear swatch. Required colour properties cannot be
  /// null, so clearing means returning to their authored/default colour.
  final Color? clearValue;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forColor(label),
    aliases: <String>['color', 'colour', ...aliases],
  );

  @override
  Widget build(BuildContext context) {
    final effectiveKeyPrefix =
        keyPrefix ?? 'showcase-color-${_keyToken(label)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionLabel(
          label: label,
          description: inspectorMetadata.description,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 6),
        ChartColorPalette(
          value: value,
          keyPrefix: effectiveKeyPrefix,
          customColorFallback: value,
          onChanged: (color) {
            onChanged(color ?? clearValue ?? colors.first);
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// A showcase color control backed by the same palette as annotation editors.
///
/// Null means "inherit from the active preset or theme". The palette provides
/// an explicit clear swatch, clears a selected swatch when it is tapped again,
/// and exposes the shared custom color dialog.
class PaletteColorOption extends StatelessWidget
    implements ShowcaseInspectorEntry {
  const PaletteColorOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.keyPrefix,
    this.subtitle,
    this.enabled = true,
    this.onEnabledChanged,
    this.customColorFallback,
    this.presetOpacity = 1,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final String? subtitle;
  final Color? value;
  final ValueChanged<Color?> onChanged;
  final String keyPrefix;
  final bool enabled;
  final ValueChanged<bool>? onEnabledChanged;
  final Color? customColorFallback;
  final double presetOpacity;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forColor(label),
    aliases: <String>['color', 'colour', 'palette', ...aliases],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _OptionLabel(
      label: this.label,
      description: inspectorMetadata.description,
      style: TextStyle(fontSize: 12, color: theme.hintColor),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onEnabledChanged == null)
            label
          else
            Row(
              children: [
                Expanded(child: label),
                Switch(
                  key: ValueKey('$keyPrefix-toggle'),
                  value: enabled,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: theme.hintColor.withValues(alpha: 0.7),
              ),
            ),
          if (enabled) ...[
            const SizedBox(height: 6),
            ChartColorPalette(
              value: value,
              onChanged: onChanged,
              keyPrefix: keyPrefix,
              customColorFallback: customColorFallback,
              presetOpacity: presetOpacity,
            ),
            const SizedBox(height: 4),
            Text(
              value == null ? 'Using preset color' : 'Color override active',
              key: ValueKey('$keyPrefix-status'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A segmented button group for selecting from a few options.
class SegmentedOption<T> extends StatelessWidget
    implements ShowcaseInspectorEntry {
  const SegmentedOption({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelBuilder,
    this.label,
    this.description,
    this.aliases = const <String>[],
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;
  final String? label;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label ?? options.map(_labelFor).join(' / '),
    description:
        description ??
        (label == null ? null : _OptionHelpCatalog.forChoice(label!)),
    aliases: <String>[...options.map(_labelFor), ...aliases],
  );

  @override
  Widget build(BuildContext context) {
    final control = SegmentedButton<T>(
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
    if (label == null) return control;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionLabel(
          label: label!,
          description: inspectorMetadata.description,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        control,
        const SizedBox(height: 12),
      ],
    );
  }

  String _labelFor(T value) =>
      labelBuilder?.call(value) ?? value.toString().split('.').last;
}

/// A text input option.
class TextOption extends StatelessWidget implements ShowcaseInspectorEntry {
  const TextOption({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forText(label),
    aliases: <String>[?hint, ...aliases],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionLabel(
          label: label,
          description: inspectorMetadata.description,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
class ActionButton extends StatelessWidget implements ShowcaseInspectorEntry {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isDestructive = false,
    this.description,
    this.aliases = const <String>[],
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isDestructive;
  final String? description;
  final List<String> aliases;

  @override
  ShowcasePropertyMetadata get inspectorMetadata => ShowcasePropertyMetadata(
    label: label,
    description: description ?? _OptionHelpCatalog.forAction(label),
    aliases: aliases,
  );

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
        Colors.blue.shade900,
      ),
      InfoBoxType.warning => (
        Colors.orange.shade50,
        Colors.orange.shade200,
        Colors.orange.shade900,
      ),
      InfoBoxType.success => (
        Colors.green.shade50,
        Colors.green.shade200,
        Colors.green.shade900,
      ),
      InfoBoxType.error => (
        Colors.red.shade50,
        Colors.red.shade200,
        Colors.red.shade900,
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
