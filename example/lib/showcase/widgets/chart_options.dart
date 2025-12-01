// Copyright 2025 Braven Charts - Chart Options Controller
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Standard chart display options that can be applied to any chart.
///
/// This provides a consistent set of toggleable options across all showcase demos.
class ChartOptions {
  const ChartOptions({
    this.theme,
    this.showGrid = true,
    this.showAxisLines = true,
    this.showDataMarkers = false,
    this.showXScrollbar = false,
    this.showYScrollbar = false,
    this.showLegend = true,
    this.enableZoom = true,
    this.enablePan = true,
    this.lineStyle = LineStyle.smooth,
    this.backgroundColor,
  });

  /// Chart theme preset
  final ChartTheme? theme;

  /// Show grid lines
  final bool showGrid;

  /// Show axis lines
  final bool showAxisLines;

  /// Show markers on data points
  final bool showDataMarkers;

  /// Show horizontal scrollbar
  final bool showXScrollbar;

  /// Show vertical scrollbar
  final bool showYScrollbar;

  /// Show legend
  final bool showLegend;

  /// Enable zoom interactions
  final bool enableZoom;

  /// Enable pan interactions
  final bool enablePan;

  /// Line interpolation style
  final LineStyle lineStyle;

  /// Custom background color (overrides theme)
  final Color? backgroundColor;

  /// Creates a copy with specified properties changed.
  ChartOptions copyWith({
    ChartTheme? theme,
    bool? showGrid,
    bool? showAxisLines,
    bool? showDataMarkers,
    bool? showXScrollbar,
    bool? showYScrollbar,
    bool? showLegend,
    bool? enableZoom,
    bool? enablePan,
    LineStyle? lineStyle,
    Color? backgroundColor,
  }) {
    return ChartOptions(
      theme: theme ?? this.theme,
      showGrid: showGrid ?? this.showGrid,
      showAxisLines: showAxisLines ?? this.showAxisLines,
      showDataMarkers: showDataMarkers ?? this.showDataMarkers,
      showXScrollbar: showXScrollbar ?? this.showXScrollbar,
      showYScrollbar: showYScrollbar ?? this.showYScrollbar,
      showLegend: showLegend ?? this.showLegend,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      lineStyle: lineStyle ?? this.lineStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  /// Gets the effective background color from theme or override.
  Color get effectiveBackgroundColor => backgroundColor ?? theme?.backgroundColor ?? Colors.white;

  /// Creates InteractionConfig with current options applied.
  InteractionConfig get interactionConfig => InteractionConfig(
        enableZoom: enableZoom,
        enablePan: enablePan,
        showXScrollbar: showXScrollbar,
        showYScrollbar: showYScrollbar,
      );
}

/// Controller for managing chart options with change notifications.
class ChartOptionsController extends ChangeNotifier {
  ChartOptionsController([ChartOptions? initial]) : _options = initial ?? const ChartOptions();

  ChartOptions _options;

  /// Current options state.
  ChartOptions get options => _options;

  /// Update options and notify listeners.
  void update(ChartOptions options) {
    if (_options != options) {
      _options = options;
      notifyListeners();
    }
  }

  /// Update a single property.
  void updateWith({
    ChartTheme? theme,
    bool? showGrid,
    bool? showAxisLines,
    bool? showDataMarkers,
    bool? showXScrollbar,
    bool? showYScrollbar,
    bool? showLegend,
    bool? enableZoom,
    bool? enablePan,
    LineStyle? lineStyle,
    Color? backgroundColor,
  }) {
    update(_options.copyWith(
      theme: theme,
      showGrid: showGrid,
      showAxisLines: showAxisLines,
      showDataMarkers: showDataMarkers,
      showXScrollbar: showXScrollbar,
      showYScrollbar: showYScrollbar,
      showLegend: showLegend,
      enableZoom: enableZoom,
      enablePan: enablePan,
      lineStyle: lineStyle,
      backgroundColor: backgroundColor,
    ));
  }

  // Convenience setters
  set theme(ChartTheme? value) => updateWith(theme: value);
  set showGrid(bool value) => updateWith(showGrid: value);
  set showAxisLines(bool value) => updateWith(showAxisLines: value);
  set showDataMarkers(bool value) => updateWith(showDataMarkers: value);
  set showXScrollbar(bool value) => updateWith(showXScrollbar: value);
  set showYScrollbar(bool value) => updateWith(showYScrollbar: value);
  set showLegend(bool value) => updateWith(showLegend: value);
  set enableZoom(bool value) => updateWith(enableZoom: value);
  set enablePan(bool value) => updateWith(enablePan: value);
  set lineStyle(LineStyle value) => updateWith(lineStyle: value);
  set backgroundColor(Color? value) => updateWith(backgroundColor: value);

  // Convenience getters
  ChartTheme? get theme => _options.theme;
  bool get showGrid => _options.showGrid;
  bool get showAxisLines => _options.showAxisLines;
  bool get showDataMarkers => _options.showDataMarkers;
  bool get showXScrollbar => _options.showXScrollbar;
  bool get showYScrollbar => _options.showYScrollbar;
  bool get showLegend => _options.showLegend;
  bool get enableZoom => _options.enableZoom;
  bool get enablePan => _options.enablePan;
  LineStyle get lineStyle => _options.lineStyle;
  Color? get backgroundColor => _options.backgroundColor;
}

/// Available theme presets.
enum ThemePreset {
  light('Light', null), // null = use default light
  dark('Dark', null),
  corporateBlue('Corporate Blue', null),
  vibrant('Vibrant', null),
  minimal('Minimal', null),
  highContrast('High Contrast', null),
  colorblindFriendly('Colorblind Friendly', null);

  const ThemePreset(this.displayName, this._theme);

  final String displayName;
  final ChartTheme? _theme;

  /// Gets the ChartTheme for this preset.
  ChartTheme get theme {
    return switch (this) {
      ThemePreset.light => ChartTheme.light,
      ThemePreset.dark => ChartTheme.dark,
      ThemePreset.corporateBlue => ChartTheme.corporateBlue,
      ThemePreset.vibrant => ChartTheme.vibrant,
      ThemePreset.minimal => ChartTheme.minimal,
      ThemePreset.highContrast => ChartTheme.highContrast,
      ThemePreset.colorblindFriendly => ChartTheme.colorblindFriendly,
    };
  }
}
