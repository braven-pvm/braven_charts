// Copyright 2025 Braven Charts - Annotations Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _AnnotationKind {
  threshold,
  range,
  point,
  text,
  pin,
  trend,
  chord,
  legend,
}

enum _RangeDirection { horizontal, vertical, rectangle }

enum _LinePattern { solid, dashed, dotted }

enum _SeriesTarget { automatic, observed, reference }

/// Browse every annotation type, then configure the selected example live.
class AnnotationsPage extends StatefulWidget {
  const AnnotationsPage({super.key});

  @override
  State<AnnotationsPage> createState() => _AnnotationsPageState();
}

class _AnnotationsPageState extends State<AnnotationsPage> {
  static const _palette = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showDataMarkers: true),
  );

  _AnnotationKind _selectedKind = _AnnotationKind.threshold;
  String _label = 'Target';
  bool _showLabel = true;
  int _zIndex = 2;
  _SeriesTarget _seriesTarget = _SeriesTarget.observed;

  Color _accentColor = const Color(0xFF4F46E5);
  double _lineWidth = 2.5;
  double _elevation = 4;
  _LinePattern _linePattern = _LinePattern.dashed;
  double _fontSize = 12;
  bool _boldLabel = true;
  bool _labelBackground = true;
  bool _labelBorder = true;
  double _labelMargin = 8;

  bool _interactiveAnnotations = true;
  bool _allowDragging = true;
  bool _allowEditing = true;

  AnnotationAxis _thresholdAxis = AnnotationAxis.y;
  double _thresholdValue = 65;
  AnnotationLabelPosition _labelPosition = AnnotationLabelPosition.topLeft;

  _RangeDirection _rangeDirection = _RangeDirection.vertical;
  double _rangeStart = 7;
  double _rangeEnd = 14;
  double _rangeOpacity = 0.18;
  bool _snapToValue = false;
  double _snapIncrement = 1;
  double _snapTolerance = 0.05;

  int _pointIndex = 8;
  MarkerShape _markerShape = MarkerShape.star;
  double _markerSize = 12;
  double _markerOffsetX = 0;
  double _markerOffsetY = -4;

  bool _richText = true;
  AnnotationAnchor _textAnchor = AnnotationAnchor.topLeft;
  double _textX = 110;
  double _textY = 54;

  double _pinX = 16;
  double _pinY = 74;

  TrendType _trendType = TrendType.polynomial;
  int _trendWindow = 5;
  int _polynomialDegree = 2;

  int _chordStart = 3;
  int _chordEnd = 19;
  bool _showPerpendicular = true;
  int _perpendicularIndex = 11;
  bool _stylePerpendicularIndependently = true;
  Color _perpendicularColor = const Color(0xFFEF4444);
  double _perpendicularLineWidth = 2;
  double _perpendicularElevation = 3;
  _LinePattern _perpendicularPattern = _LinePattern.dotted;

  LegendPosition _legendPosition = LegendPosition.topRight;
  LegendOrientation _legendOrientation = LegendOrientation.vertical;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.line;
  double _legendOpacity = 0.92;
  double _legendMarkerSize = 16;
  double _legendItemSpacing = 7;
  bool _legendAllowDragging = true;
  bool _hideReferenceSeries = false;
  bool _legendBackground = true;
  bool _legendBorder = true;
  double _legendBorderWidth = 1;
  double _legendRadius = 8;
  double _legendPadding = 8;
  double _legendMarkerLineWidth = 4;
  double _legendLabelSpacing = 7;
  double _legendOffsetX = 0;
  double _legendOffsetY = 0;

  static const _signalValues = <double>[
    32,
    38,
    44,
    51,
    59,
    67,
    74,
    79,
    76,
    69,
    61,
    55,
    51,
    54,
    62,
    72,
    81,
    86,
    80,
    69,
    57,
    49,
    53,
    64,
  ];

  static const _referenceValues = <double>[
    39,
    41,
    43,
    46,
    48,
    51,
    53,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    67,
    68,
    69,
    70,
    71,
  ];

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Annotations',
      subtitle:
          '8 public models, 21 live variants, and the complete context-menu workflow',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      OptionSection(
        title: 'Annotation Type',
        icon: Icons.layers_outlined,
        children: [
          EnumOption<_AnnotationKind>(
            label: 'Type',
            value: _selectedKind,
            values: _AnnotationKind.values,
            labelBuilder: _kindLabel,
            onChanged: _selectKind,
          ),
          TextOption(
            key: ValueKey('annotation-label-${_selectedKind.name}'),
            label: 'Label',
            value: _label,
            hint: 'Annotation label',
            onChanged: (value) => setState(() => _label = value),
          ),
          BoolOption(
            label: 'Show Label',
            value: _showLabel,
            onChanged: (value) => setState(() => _showLabel = value),
          ),
          IntSliderOption(
            label: 'Z-index',
            value: _zIndex,
            min: 0,
            max: 10,
            onChanged: (value) => setState(() => _zIndex = value),
          ),
        ],
      ),
      ..._buildTypeSpecificOptions(),
      if (_selectedKind != _AnnotationKind.legend)
        OptionSection(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            ColorOption(
              label: 'Accent Color',
              value: _accentColor,
              colors: _palette,
              onChanged: (value) => setState(() => _accentColor = value),
            ),
            if (_hasLineAppearance)
              SliderOption(
                label: 'Line Width',
                value: _lineWidth,
                min: 0.5,
                max: 6,
                divisions: 11,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _lineWidth = value),
              ),
            if (_hasLineAppearance)
              EnumOption<_LinePattern>(
                label: 'Line Pattern',
                value: _linePattern,
                values: _LinePattern.values,
                onChanged: (value) => setState(() => _linePattern = value),
              ),
            if (_supportsElevation)
              SliderOption(
                label: 'Glow Elevation',
                value: _elevation,
                min: 0,
                max: 12,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _elevation = value),
              ),
          ],
        ),
      if (_selectedKind != _AnnotationKind.legend)
        OptionSection(
          title: 'Label Style',
          icon: Icons.text_fields,
          children: [
            SliderOption(
              label: 'Font Size',
              value: _fontSize,
              min: 9,
              max: 20,
              divisions: 11,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _fontSize = value),
            ),
            BoolOption(
              label: 'Bold Text',
              value: _boldLabel,
              onChanged: (value) => setState(() => _boldLabel = value),
            ),
            BoolOption(
              label: 'Label Background',
              value: _labelBackground,
              onChanged: (value) => setState(() => _labelBackground = value),
            ),
            BoolOption(
              label: 'Label Border',
              value: _labelBorder,
              onChanged: (value) => setState(() => _labelBorder = value),
            ),
            SliderOption(
              label: 'Label Margin',
              value: _labelMargin,
              min: 0,
              max: 20,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _labelMargin = value),
            ),
          ],
        ),
      OptionSection(
        title: 'Behavior',
        icon: Icons.touch_app_outlined,
        children: [
          BoolOption(
            label: 'Interactive Annotations',
            value: _interactiveAnnotations,
            subtitle: 'Enable selection and annotation gestures',
            onChanged: (value) =>
                setState(() => _interactiveAnnotations = value),
          ),
          if (_selectedKind != _AnnotationKind.legend)
            BoolOption(
              label: 'Allow Dragging',
              value: _allowDragging,
              onChanged: (value) => setState(() => _allowDragging = value),
            ),
          if (_selectedKind != _AnnotationKind.legend)
            BoolOption(
              label: 'Allow Editing',
              value: _allowEditing,
              onChanged: (value) => setState(() => _allowEditing = value),
            ),
        ],
      ),
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Reset Annotation Options',
            icon: Icons.restore,
            onPressed: _resetOptions,
          ),
        ],
      ),
      InfoBox(message: _coverageMessage),
    ];
  }

  List<Widget> _buildTypeSpecificOptions() {
    switch (_selectedKind) {
      case _AnnotationKind.threshold:
        return [
          OptionSection(
            title: 'Threshold Options',
            icon: Icons.horizontal_rule,
            children: [
              EnumOption<AnnotationAxis>(
                label: 'Axis',
                value: _thresholdAxis,
                values: AnnotationAxis.values,
                labelBuilder: (value) => value == AnnotationAxis.y
                    ? 'Y value · horizontal line'
                    : 'X value · vertical line',
                onChanged: (value) => setState(() {
                  _thresholdAxis = value;
                  _thresholdValue = value == AnnotationAxis.y ? 65 : 12;
                }),
              ),
              _seriesTargetOption(allowAutomatic: true),
              SliderOption(
                label: 'Value',
                value: _thresholdValue,
                min: 0,
                max: _thresholdAxis == AnnotationAxis.y ? 100 : 23,
                divisions: _thresholdAxis == AnnotationAxis.y ? 20 : 23,
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _thresholdValue = value),
              ),
              _labelPositionOption(),
            ],
          ),
        ];
      case _AnnotationKind.range:
        return [
          OptionSection(
            title: 'Range Options',
            icon: Icons.crop_free,
            children: [
              EnumOption<_RangeDirection>(
                label: 'Range Shape',
                value: _rangeDirection,
                values: _RangeDirection.values,
                labelBuilder: (value) => switch (value) {
                  _RangeDirection.horizontal => 'Horizontal band · Y range',
                  _RangeDirection.vertical => 'Vertical band · X range',
                  _RangeDirection.rectangle => 'Rectangle · X and Y',
                },
                onChanged: (value) => setState(() {
                  _rangeDirection = value;
                  if (value == _RangeDirection.horizontal) {
                    _rangeStart = 35;
                    _rangeEnd = 65;
                  } else {
                    _rangeStart = 7;
                    _rangeEnd = 14;
                  }
                }),
              ),
              _seriesTargetOption(allowAutomatic: true),
              SliderOption(
                label: 'Start',
                value: _rangeStart,
                min: 0,
                max: _rangeDirection == _RangeDirection.horizontal ? 90 : 20,
                divisions: _rangeDirection == _RangeDirection.horizontal
                    ? 18
                    : 20,
                decimalPlaces: 0,
                onChanged: (value) => setState(() {
                  _rangeStart = value.clamp(0, _rangeEnd - 1);
                }),
              ),
              SliderOption(
                label: 'End',
                value: _rangeEnd,
                min: _rangeDirection == _RangeDirection.horizontal ? 10 : 2,
                max: _rangeDirection == _RangeDirection.horizontal ? 100 : 23,
                divisions: _rangeDirection == _RangeDirection.horizontal
                    ? 18
                    : 21,
                decimalPlaces: 0,
                onChanged: (value) => setState(() {
                  _rangeEnd = value.clamp(_rangeStart + 1, 100);
                }),
              ),
              SliderOption(
                label: 'Fill Opacity',
                value: _rangeOpacity,
                min: 0.05,
                max: 0.5,
                divisions: 9,
                decimalPlaces: 2,
                onChanged: (value) => setState(() => _rangeOpacity = value),
              ),
              _labelPositionOption(),
              BoolOption(
                label: 'Snap to Value',
                value: _snapToValue,
                onChanged: (value) => setState(() => _snapToValue = value),
              ),
              if (_snapToValue) ...[
                SliderOption(
                  label: 'Snap Increment',
                  value: _snapIncrement,
                  min: 0.5,
                  max: 5,
                  divisions: 9,
                  decimalPlaces: 1,
                  onChanged: (value) => setState(() => _snapIncrement = value),
                ),
                SliderOption(
                  label: 'Snap Tolerance',
                  value: _snapTolerance,
                  min: 0,
                  max: 0.2,
                  divisions: 10,
                  decimalPlaces: 2,
                  onChanged: (value) => setState(() => _snapTolerance = value),
                ),
              ],
            ],
          ),
        ];
      case _AnnotationKind.point:
        return [
          OptionSection(
            title: 'Point Options',
            icon: Icons.my_location,
            children: [
              IntSliderOption(
                label: 'Data Point Index',
                value: _pointIndex,
                min: 0,
                max: _signalValues.length - 1,
                onChanged: (value) => setState(() => _pointIndex = value),
              ),
              _seriesTargetOption(),
              _markerShapeOption(),
              _markerSizeOption(),
              SliderOption(
                label: 'Marker Offset X',
                value: _markerOffsetX,
                min: -30,
                max: 30,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _markerOffsetX = value),
              ),
              SliderOption(
                label: 'Marker Offset Y',
                value: _markerOffsetY,
                min: -30,
                max: 30,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _markerOffsetY = value),
              ),
            ],
          ),
        ];
      case _AnnotationKind.text:
        return [
          OptionSection(
            title: 'Text Options',
            icon: Icons.title,
            children: [
              BoolOption(
                label: 'Rich Text Delta',
                value: _richText,
                subtitle: 'Toggle plain text vs formatted Delta content',
                onChanged: (value) => setState(() => _richText = value),
              ),
              EnumOption<AnnotationAnchor>(
                label: 'Anchor',
                value: _textAnchor,
                values: AnnotationAnchor.values,
                onChanged: (value) => setState(() => _textAnchor = value),
              ),
              SliderOption(
                label: 'Screen Position X',
                value: _textX,
                min: 20,
                max: 420,
                divisions: 20,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _textX = value),
              ),
              SliderOption(
                label: 'Screen Position Y',
                value: _textY,
                min: 20,
                max: 220,
                divisions: 20,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _textY = value),
              ),
            ],
          ),
        ];
      case _AnnotationKind.pin:
        return [
          OptionSection(
            title: 'Pin Options',
            icon: Icons.push_pin_outlined,
            children: [
              SliderOption(
                label: 'X Coordinate',
                value: _pinX,
                min: 0,
                max: 23,
                divisions: 23,
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _pinX = value),
              ),
              SliderOption(
                label: 'Y Coordinate',
                value: _pinY,
                min: 0,
                max: 100,
                divisions: 20,
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _pinY = value),
              ),
              _markerShapeOption(),
              _markerSizeOption(),
            ],
          ),
        ];
      case _AnnotationKind.trend:
        return [
          OptionSection(
            title: 'Trend Options',
            icon: Icons.trending_up,
            children: [
              EnumOption<TrendType>(
                label: 'Calculation',
                value: _trendType,
                values: TrendType.values,
                labelBuilder: _trendLabel,
                onChanged: (value) => setState(() => _trendType = value),
              ),
              _seriesTargetOption(),
              if (_trendType == TrendType.movingAverage ||
                  _trendType == TrendType.exponentialMovingAverage)
                IntSliderOption(
                  label: 'Window Size',
                  value: _trendWindow,
                  min: 2,
                  max: 12,
                  onChanged: (value) => setState(() => _trendWindow = value),
                ),
              if (_trendType == TrendType.polynomial)
                IntSliderOption(
                  label: 'Polynomial Degree',
                  value: _polynomialDegree,
                  min: 2,
                  max: 5,
                  onChanged: (value) =>
                      setState(() => _polynomialDegree = value),
                ),
            ],
          ),
        ];
      case _AnnotationKind.chord:
        return [
          OptionSection(
            title: 'Chord Options',
            icon: Icons.timeline,
            children: [
              IntSliderOption(
                label: 'Start Index',
                value: _chordStart,
                min: 0,
                max: _signalValues.length - 2,
                onChanged: (value) => setState(() {
                  _chordStart = value.clamp(0, _chordEnd - 1);
                }),
              ),
              _seriesTargetOption(),
              IntSliderOption(
                label: 'End Index',
                value: _chordEnd,
                min: 1,
                max: _signalValues.length - 1,
                onChanged: (value) => setState(() {
                  _chordEnd = value.clamp(_chordStart + 1, 23);
                }),
              ),
              BoolOption(
                label: 'Perpendicular Drop-line',
                value: _showPerpendicular,
                subtitle: 'Show deflection from a data point to the chord',
                onChanged: (value) =>
                    setState(() => _showPerpendicular = value),
              ),
              if (_showPerpendicular) ...[
                IntSliderOption(
                  label: 'Perpendicular Index',
                  value: _perpendicularIndex,
                  min: _chordStart,
                  max: _chordEnd,
                  onChanged: (value) =>
                      setState(() => _perpendicularIndex = value),
                ),
                BoolOption(
                  label: 'Independent Drop-line Style',
                  value: _stylePerpendicularIndependently,
                  onChanged: (value) =>
                      setState(() => _stylePerpendicularIndependently = value),
                ),
                if (_stylePerpendicularIndependently) ...[
                  ColorOption(
                    label: 'Drop-line Color',
                    value: _perpendicularColor,
                    colors: _palette,
                    onChanged: (value) =>
                        setState(() => _perpendicularColor = value),
                  ),
                  SliderOption(
                    label: 'Drop-line Width',
                    value: _perpendicularLineWidth,
                    min: 0.5,
                    max: 6,
                    divisions: 11,
                    suffix: 'px',
                    decimalPlaces: 1,
                    onChanged: (value) =>
                        setState(() => _perpendicularLineWidth = value),
                  ),
                  EnumOption<_LinePattern>(
                    label: 'Drop-line Pattern',
                    value: _perpendicularPattern,
                    values: _LinePattern.values,
                    onChanged: (value) =>
                        setState(() => _perpendicularPattern = value),
                  ),
                  SliderOption(
                    label: 'Drop-line Glow',
                    value: _perpendicularElevation,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    suffix: 'px',
                    decimalPlaces: 0,
                    onChanged: (value) =>
                        setState(() => _perpendicularElevation = value),
                  ),
                ],
              ],
            ],
          ),
        ];
      case _AnnotationKind.legend:
        return [
          OptionSection(
            title: 'Legend Options',
            icon: Icons.view_list_outlined,
            children: [
              EnumOption<LegendPosition>(
                label: 'Position',
                value: _legendPosition,
                values: LegendPosition.values,
                onChanged: (value) => setState(() => _legendPosition = value),
              ),
              EnumOption<LegendOrientation>(
                label: 'Orientation',
                value: _legendOrientation,
                values: LegendOrientation.values,
                onChanged: (value) =>
                    setState(() => _legendOrientation = value),
              ),
              EnumOption<LegendMarkerShape>(
                label: 'Marker Shape',
                value: _legendMarkerShape,
                values: LegendMarkerShape.values,
                onChanged: (value) =>
                    setState(() => _legendMarkerShape = value),
              ),
              SliderOption(
                label: 'Opacity',
                value: _legendOpacity,
                min: 0.25,
                max: 1,
                divisions: 15,
                decimalPlaces: 2,
                onChanged: (value) => setState(() => _legendOpacity = value),
              ),
              SliderOption(
                label: 'Font Size',
                value: _fontSize,
                min: 9,
                max: 20,
                divisions: 11,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _fontSize = value),
              ),
              BoolOption(
                label: 'Bold Text',
                value: _boldLabel,
                onChanged: (value) => setState(() => _boldLabel = value),
              ),
              BoolOption(
                label: 'Background',
                value: _legendBackground,
                onChanged: (value) => setState(() => _legendBackground = value),
              ),
              BoolOption(
                label: 'Border',
                value: _legendBorder,
                onChanged: (value) => setState(() => _legendBorder = value),
              ),
              if (_legendBorder)
                SliderOption(
                  label: 'Border Width',
                  value: _legendBorderWidth,
                  min: 0.5,
                  max: 4,
                  divisions: 7,
                  suffix: 'px',
                  decimalPlaces: 1,
                  onChanged: (value) =>
                      setState(() => _legendBorderWidth = value),
                ),
              SliderOption(
                label: 'Corner Radius',
                value: _legendRadius,
                min: 0,
                max: 20,
                divisions: 10,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendRadius = value),
              ),
              SliderOption(
                label: 'Container Padding',
                value: _legendPadding,
                min: 0,
                max: 20,
                divisions: 10,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendPadding = value),
              ),
              SliderOption(
                label: 'Marker Size',
                value: _legendMarkerSize,
                min: 8,
                max: 28,
                divisions: 10,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendMarkerSize = value),
              ),
              SliderOption(
                label: 'Marker Line Width',
                value: _legendMarkerLineWidth,
                min: 1,
                max: 8,
                divisions: 7,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _legendMarkerLineWidth = value),
              ),
              SliderOption(
                label: 'Marker Label Spacing',
                value: _legendLabelSpacing,
                min: 0,
                max: 20,
                divisions: 10,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _legendLabelSpacing = value),
              ),
              SliderOption(
                label: 'Item Spacing',
                value: _legendItemSpacing,
                min: 0,
                max: 20,
                divisions: 10,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _legendItemSpacing = value),
              ),
              BoolOption(
                label: 'Allow Legend Dragging',
                value: _legendAllowDragging,
                onChanged: (value) =>
                    setState(() => _legendAllowDragging = value),
              ),
              SliderOption(
                label: 'Offset X',
                value: _legendOffsetX,
                min: -80,
                max: 80,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendOffsetX = value),
              ),
              SliderOption(
                label: 'Offset Y',
                value: _legendOffsetY,
                min: -80,
                max: 80,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendOffsetY = value),
              ),
              BoolOption(
                label: 'Hide Reference Series',
                value: _hideReferenceSeries,
                subtitle: 'Demonstrates hiddenSeriesIds and toggle callbacks',
                onChanged: (value) =>
                    setState(() => _hideReferenceSeries = value),
              ),
            ],
          ),
        ];
    }
  }

  EnumOption<AnnotationLabelPosition> _labelPositionOption() {
    return EnumOption<AnnotationLabelPosition>(
      label: 'Label Position',
      value: _labelPosition,
      values: AnnotationLabelPosition.values,
      onChanged: (value) => setState(() => _labelPosition = value),
    );
  }

  EnumOption<_SeriesTarget> _seriesTargetOption({bool allowAutomatic = false}) {
    final values = allowAutomatic
        ? _SeriesTarget.values
        : const [_SeriesTarget.observed, _SeriesTarget.reference];
    final value = !allowAutomatic && _seriesTarget == _SeriesTarget.automatic
        ? _SeriesTarget.observed
        : _seriesTarget;
    return EnumOption<_SeriesTarget>(
      label: allowAutomatic ? 'Series Scale' : 'Source Series',
      value: value,
      values: values,
      labelBuilder: (target) => switch (target) {
        _SeriesTarget.automatic => 'Automatic',
        _SeriesTarget.observed => 'Observed signal',
        _SeriesTarget.reference => 'Reference',
      },
      onChanged: (target) => setState(() => _seriesTarget = target),
    );
  }

  String? _seriesId({bool allowAutomatic = false}) {
    return switch (_seriesTarget) {
      _SeriesTarget.automatic when allowAutomatic => null,
      _SeriesTarget.reference => 'reference',
      _ => 'signal',
    };
  }

  EnumOption<MarkerShape> _markerShapeOption() {
    return EnumOption<MarkerShape>(
      label: 'Marker Shape',
      value: _markerShape,
      values: MarkerShape.values
          .where((shape) => shape != MarkerShape.none)
          .toList(),
      onChanged: (value) => setState(() => _markerShape = value),
    );
  }

  SliderOption _markerSizeOption() {
    return SliderOption(
      label: 'Marker Size',
      value: _markerSize,
      min: 4,
      max: 24,
      divisions: 10,
      suffix: 'px',
      decimalPlaces: 0,
      onChanged: (value) => setState(() => _markerSize = value),
    );
  }

  Widget _buildWorkspace() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an annotation',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 168, child: _buildAnnotationRibbon()),
            const SizedBox(height: 16),
            _AnnotationGuide(
              kindLabel: _kindLabel(_selectedKind),
              explanation: _kindExplanation(_selectedKind),
              useCase: _kindUseCase(_selectedKind),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildMainChart()),
          ],
        );
      },
    );
  }

  Widget _buildAnnotationRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minimumCardWidth = 168.0;
        final fitWidth = (constraints.maxWidth - spacing * 3) / 4;
        final cardWidth = fitWidth >= minimumCardWidth
            ? fitWidth
            : minimumCardWidth;

        return ListView.separated(
          key: const ValueKey('annotation-type-ribbon'),
          scrollDirection: Axis.horizontal,
          itemCount: _AnnotationKind.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final kind = _AnnotationKind.values[index];
            return SizedBox(
              width: cardWidth,
              child: _AnnotationPreviewCard(
                key: ValueKey('annotation-preview-${kind.name}'),
                kind: kind,
                label: _kindLabel(kind),
                description: _kindDescription(kind),
                selected: _selectedKind == kind,
                onTap: () => _selectKind(kind),
                chart: _buildPreviewChart(kind),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewChart(_AnnotationKind kind) {
    final series = _buildSeries(preview: true);
    return BravenChartPlus(
      series: series,
      annotations: _buildAnnotations(kind, series: series, preview: true),
      showLegend: false,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: const XAxisConfig(
        visible: false,
        min: 0,
        max: 23,
        minHeight: 0,
        maxHeight: 0,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.hidden,
        min: 0,
        max: 100,
        minWidth: 0,
        maxWidth: 0,
      ),
      interactionConfig: InteractionConfig.none(),
      interactiveAnnotations: false,
    );
  }

  Widget _buildMainChart() {
    final series = _buildSeries();
    return ChartCard(
      title: '${_kindLabel(_selectedKind)} annotation playground',
      subtitle: _mainChartSummary,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: BravenChartPlus(
        key: ValueKey('annotation-main-${_selectedKind.name}'),
        series: series,
        annotations: _buildAnnotations(_selectedKind, series: series),
        theme: _optionsController.theme,
        showLegend: false,
        showXScrollbar: _optionsController.showXScrollbar,
        showYScrollbar: _optionsController.showYScrollbar,
        scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
        grid: GridConfig(
          horizontal: _optionsController.showGrid,
          vertical: _optionsController.showGrid,
        ),
        xAxisConfig: XAxisConfig(
          label: 'Sample',
          min: 0,
          max: 23,
          showAxisLine: _optionsController.showAxisLines,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Value',
          min: 0,
          max: 100,
          showAxisLine: _optionsController.showAxisLines,
        ),
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          tooltip: const TooltipConfig(),
          crosshair: const CrosshairConfig(
            enabled: true,
            mode: CrosshairMode.both,
          ),
        ),
        interactiveAnnotations: _interactiveAnnotations,
        onAnnotationTap: (annotation) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Selected ${_kindLabel(_selectedKind)}: '
                  '${annotation.label ?? annotation.id}',
                ),
                duration: const Duration(milliseconds: 900),
              ),
            );
        },
      ),
    );
  }

  List<ChartSeries> _buildSeries({bool preview = false}) {
    final signal = LineChartSeries(
      id: 'signal',
      name: 'Observed signal',
      points: List.generate(
        _signalValues.length,
        (index) => ChartDataPoint(x: index.toDouble(), y: _signalValues[index]),
      ),
      color: const Color(0xFF3B82F6),
      interpolation: LineInterpolation.monotone,
      strokeWidth: preview ? 1.8 : 2.5,
      showDataPointMarkers: !preview && _optionsController.showDataMarkers,
      dataPointMarkerRadius: 3,
    );
    final reference = LineChartSeries(
      id: 'reference',
      name: 'Reference',
      points: List.generate(
        _referenceValues.length,
        (index) =>
            ChartDataPoint(x: index.toDouble(), y: _referenceValues[index]),
      ),
      color: const Color(0xFF94A3B8),
      interpolation: LineInterpolation.bezier,
      strokeWidth: preview ? 1.2 : 1.8,
      showDataPointMarkers: false,
    );
    return [signal, reference];
  }

  List<ChartAnnotation> _buildAnnotations(
    _AnnotationKind kind, {
    required List<ChartSeries> series,
    bool preview = false,
  }) {
    if (preview) return _previewAnnotations(kind, series);

    final label = _showLabel && _label.trim().isNotEmpty ? _label.trim() : null;
    final style = _annotationStyle;
    final dashPattern = _dashPattern;

    return switch (kind) {
      _AnnotationKind.threshold => [
        ThresholdAnnotation(
          id: 'playground-threshold',
          axis: _thresholdAxis,
          value: _thresholdValue,
          seriesId: _seriesId(allowAutomatic: true),
          label: label,
          style: style,
          lineColor: _accentColor,
          lineWidth: _lineWidth,
          dashPattern: dashPattern,
          labelPosition: _labelPosition,
          labelMargin: _labelMargin,
          elevation: _elevation,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: _zIndex,
        ),
        ThresholdAnnotation(
          id: 'threshold-upper-guardrail',
          axis: AnnotationAxis.y,
          value: 86,
          label: 'Upper guardrail',
          style: _companionStyle(const Color(0xFFEF4444)),
          lineColor: const Color(0xFFEF4444),
          lineWidth: 1.5,
          dashPattern: const [3, 3],
          labelPosition: AnnotationLabelPosition.bottomRight,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
        ThresholdAnnotation(
          id: 'threshold-event-marker',
          axis: AnnotationAxis.x,
          value: 18,
          label: 'Event',
          style: _companionStyle(const Color(0xFFF59E0B)),
          lineColor: const Color(0xFFF59E0B),
          lineWidth: 1.5,
          elevation: 2,
          labelPosition: AnnotationLabelPosition.topRight,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
      ],
      _AnnotationKind.range => [
        RangeAnnotation(
          id: 'playground-range',
          startX: _rangeDirection == _RangeDirection.horizontal
              ? null
              : _rangeStart,
          endX: _rangeDirection == _RangeDirection.horizontal
              ? null
              : _rangeEnd,
          startY: _rangeDirection == _RangeDirection.vertical
              ? null
              : _rangeStart,
          endY: _rangeDirection == _RangeDirection.vertical ? null : _rangeEnd,
          seriesId: _seriesId(allowAutomatic: true),
          label: label,
          style: style,
          fillColor: _accentColor.withValues(alpha: _rangeOpacity),
          borderColor: _accentColor,
          labelPosition: _labelPosition,
          labelMargin: _labelMargin,
          snapToValue: _snapToValue,
          snapIncrement: _snapIncrement,
          snapTolerance: _snapTolerance,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: _zIndex,
        ),
        RangeAnnotation(
          id: 'range-target-band',
          startY: 42,
          endY: 58,
          seriesId: 'signal',
          label: 'Target band',
          style: _companionStyle(const Color(0xFF10B981)),
          fillColor: const Color(0x2410B981),
          borderColor: const Color(0xFF10B981),
          labelPosition: AnnotationLabelPosition.bottomRight,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 0,
        ),
        RangeAnnotation(
          id: 'range-focus-window',
          startX: 16,
          endX: 21,
          startY: 65,
          endY: 92,
          seriesId: 'signal',
          label: 'Focus area',
          style: _companionStyle(const Color(0xFF8B5CF6)),
          fillColor: const Color(0x1F8B5CF6),
          borderColor: const Color(0xFF8B5CF6),
          labelPosition: AnnotationLabelPosition.topLeft,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
      ],
      _AnnotationKind.point => [
        PointAnnotation(
          id: 'playground-point',
          seriesId: _seriesId()!,
          dataPointIndex: _pointIndex,
          offset: Offset(_markerOffsetX, _markerOffsetY),
          label: label,
          style: style,
          markerShape: _markerShape,
          markerSize: _markerSize,
          markerColor: _accentColor,
          labelMargin: _labelMargin,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: _zIndex,
        ),
        PointAnnotation(
          id: 'point-rising-sample',
          seriesId: 'signal',
          dataPointIndex: 5,
          label: 'Rising sample',
          style: _companionStyle(const Color(0xFF10B981)),
          markerShape: MarkerShape.diamond,
          markerSize: 10,
          markerColor: const Color(0xFF10B981),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
        PointAnnotation(
          id: 'point-late-peak',
          seriesId: 'signal',
          dataPointIndex: 17,
          label: 'Late peak',
          style: _companionStyle(const Color(0xFFEF4444)),
          markerShape: MarkerShape.triangle,
          markerSize: 11,
          markerColor: const Color(0xFFEF4444),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
      ],
      _AnnotationKind.text => [
        if (_richText)
          TextAnnotation.rich(
            id: 'playground-text',
            label: label,
            richTextDelta: const [
              {
                'insert': 'Important ',
                'attributes': {'b': true},
              },
              {
                'insert': 'insight',
                'attributes': {'i': true, 'u': true},
              },
              {'insert': '\nRich text via Delta\n'},
            ],
            position: Offset(_textX, _textY),
            anchor: _textAnchor,
            style: style,
            backgroundColor: _labelBackground
                ? _accentColor.withValues(alpha: 0.10)
                : null,
            borderColor: _labelBorder ? _accentColor : null,
            allowDragging: _allowDragging,
            allowEditing: _allowEditing,
            zIndex: _zIndex,
          )
        else
          TextAnnotation(
            id: 'playground-text',
            label: label,
            text: label ?? 'Plain text annotation',
            position: Offset(_textX, _textY),
            anchor: _textAnchor,
            style: style,
            backgroundColor: _labelBackground
                ? _accentColor.withValues(alpha: 0.10)
                : null,
            borderColor: _labelBorder ? _accentColor : null,
            allowDragging: _allowDragging,
            allowEditing: _allowEditing,
            zIndex: _zIndex,
          ),
        TextAnnotation(
          id: 'text-plain-note',
          label: 'Plain text',
          text: 'Screen-positioned note',
          position: const Offset(390, 150),
          anchor: AnnotationAnchor.center,
          style: _companionStyle(const Color(0xFF0EA5E9)),
          backgroundColor: const Color(0xEFFFFFFF),
          borderColor: const Color(0xFF0EA5E9),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
      ],
      _AnnotationKind.pin => [
        PinAnnotation(
          id: 'playground-pin',
          x: _pinX,
          y: _pinY,
          label: label,
          style: style,
          markerShape: _markerShape,
          markerSize: _markerSize,
          markerColor: _accentColor,
          labelMargin: _labelMargin,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: _zIndex,
        ),
        PinAnnotation(
          id: 'pin-observation',
          x: 6,
          y: 74,
          label: 'Observation',
          style: _companionStyle(const Color(0xFF10B981)),
          markerShape: MarkerShape.diamond,
          markerSize: 10,
          markerColor: const Color(0xFF10B981),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
        PinAnnotation(
          id: 'pin-low-point',
          x: 21,
          y: 49,
          label: 'Low point',
          style: _companionStyle(const Color(0xFFEF4444)),
          markerShape: MarkerShape.triangle,
          markerSize: 10,
          markerColor: const Color(0xFFEF4444),
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
      ],
      _AnnotationKind.trend => [
        TrendAnnotation(
          id: 'playground-trend',
          seriesId: _seriesId()!,
          trendType: _trendType,
          windowSize:
              _trendType == TrendType.movingAverage ||
                  _trendType == TrendType.exponentialMovingAverage
              ? _trendWindow
              : null,
          degree: _polynomialDegree,
          label: label,
          style: style,
          lineColor: _accentColor,
          lineWidth: _lineWidth,
          dashPattern: dashPattern,
          elevation: _elevation,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: _zIndex,
        ),
        for (final trendType in TrendType.values)
          if (trendType != _trendType) _companionTrend(trendType),
      ],
      _AnnotationKind.chord => [
        ChordAnnotation(
          id: 'playground-chord',
          seriesId: _seriesId()!,
          startIndex: _chordStart,
          endIndex: _chordEnd,
          label: label,
          style: style,
          lineColor: _accentColor,
          lineWidth: _lineWidth,
          dashPattern: dashPattern,
          elevation: _elevation,
          perpendicularIndex: _showPerpendicular ? _perpendicularIndex : null,
          perpendicularLabel: _showPerpendicular ? 'Deflection' : null,
          perpendicularLabelOffset: const Offset(10, -5),
          perpendicularLabelStyle: _showPerpendicular ? style : null,
          perpendicularLineColor: _stylePerpendicularIndependently
              ? _perpendicularColor
              : null,
          perpendicularLineWidth: _stylePerpendicularIndependently
              ? _perpendicularLineWidth
              : null,
          perpendicularDashPattern: _stylePerpendicularIndependently
              ? _dashFor(_perpendicularPattern)
              : null,
          perpendicularElevation: _stylePerpendicularIndependently
              ? _perpendicularElevation
              : null,
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: _zIndex,
        ),
        ChordAnnotation(
          id: 'chord-simple-secant',
          seriesId: 'signal',
          startIndex: 5,
          endIndex: 17,
          label: 'Simple secant',
          style: _companionStyle(const Color(0xFF10B981)),
          lineColor: const Color(0xFF10B981),
          lineWidth: 1.5,
          dashPattern: const [6, 4],
          allowDragging: _allowDragging,
          allowEditing: _allowEditing,
          zIndex: 1,
        ),
      ],
      _AnnotationKind.legend => [
        LegendAnnotation(
          id: 'playground-legend',
          label: label,
          zIndex: _zIndex,
          series: series,
          trendAnnotations: [
            TrendAnnotation(
              id: 'legend-trend',
              seriesId: 'signal',
              trendType: TrendType.linear,
              label: 'Observed trend',
              lineColor: const Color(0xFFF59E0B),
              dashPattern: const [5, 3],
            ),
          ],
          hiddenSeriesIds: _hideReferenceSeries ? {'reference'} : const {},
          onSeriesToggle: (seriesId) {
            if (seriesId == 'reference') {
              setState(() => _hideReferenceSeries = !_hideReferenceSeries);
            }
          },
          legendStyle: LegendStyle(
            position: _legendPosition,
            orientation: _legendOrientation,
            textStyle: TextStyle(
              fontSize: _fontSize,
              fontWeight: _boldLabel ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF1E293B),
            ),
            backgroundColor: _legendBackground
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.transparent,
            borderColor: _legendBorder
                ? const Color(0xFFCBD5E1)
                : Colors.transparent,
            borderWidth: _legendBorder ? _legendBorderWidth : 0,
            borderRadius: BorderRadius.circular(_legendRadius),
            padding: EdgeInsets.all(_legendPadding),
            itemSpacing: _legendItemSpacing,
            markerSize: _legendMarkerSize,
            markerShape: _legendMarkerShape,
            markerLineWidth: _legendMarkerLineWidth,
            markerLabelSpacing: _legendLabelSpacing,
            allowDragging: _legendAllowDragging,
            opacity: _legendOpacity,
            offset: Offset(_legendOffsetX, _legendOffsetY),
          ),
        ),
      ],
    };
  }

  List<ChartAnnotation> _previewAnnotations(
    _AnnotationKind kind,
    List<ChartSeries> series,
  ) {
    const previewStyle = AnnotationStyle(
      textStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
      backgroundColor: Color(0xEFFFFFFF),
      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    );
    return switch (kind) {
      _AnnotationKind.threshold => [
        ThresholdAnnotation(
          id: 'preview-threshold',
          axis: AnnotationAxis.y,
          value: 62,
          label: 'Target',
          style: previewStyle,
          lineColor: const Color(0xFFEF4444),
          lineWidth: 1.5,
          dashPattern: const [4, 3],
        ),
      ],
      _AnnotationKind.range => [
        RangeAnnotation(
          id: 'preview-range',
          startX: 7,
          endX: 14,
          label: 'Window',
          style: previewStyle,
          fillColor: const Color(0x3310B981),
          borderColor: const Color(0xFF10B981),
        ),
      ],
      _AnnotationKind.point => [
        PointAnnotation(
          id: 'preview-point',
          seriesId: 'signal',
          dataPointIndex: 8,
          markerShape: MarkerShape.star,
          markerSize: 8,
          markerColor: const Color(0xFFF59E0B),
        ),
      ],
      _AnnotationKind.text => [
        TextAnnotation(
          id: 'preview-text',
          text: 'Insight',
          position: const Offset(18, 18),
          style: previewStyle,
          backgroundColor: const Color(0xFFF5F3FF),
          borderColor: const Color(0xFF8B5CF6),
        ),
      ],
      _AnnotationKind.pin => [
        PinAnnotation(
          id: 'preview-pin',
          x: 16,
          y: 74,
          label: 'Pinned',
          style: previewStyle,
          markerShape: MarkerShape.diamond,
          markerSize: 8,
          markerColor: const Color(0xFF0EA5E9),
        ),
      ],
      _AnnotationKind.trend => [
        TrendAnnotation(
          id: 'preview-trend',
          seriesId: 'signal',
          trendType: TrendType.polynomial,
          degree: 2,
          lineColor: const Color(0xFF8B5CF6),
          lineWidth: 2,
          dashPattern: const [4, 3],
        ),
      ],
      _AnnotationKind.chord => [
        ChordAnnotation(
          id: 'preview-chord',
          seriesId: 'signal',
          startIndex: 3,
          endIndex: 19,
          lineColor: const Color(0xFF0F766E),
          lineWidth: 1.8,
          perpendicularIndex: 11,
          perpendicularLineColor: const Color(0xFFEF4444),
          perpendicularLineWidth: 1.2,
        ),
      ],
      _AnnotationKind.legend => [
        LegendAnnotation(
          id: 'preview-legend',
          series: series,
          legendStyle: const LegendStyle(
            position: LegendPosition.topRight,
            orientation: LegendOrientation.vertical,
            textStyle: TextStyle(fontSize: 7),
            backgroundColor: Color(0xEFFFFFFF),
            markerSize: 8,
            markerLineWidth: 2,
            markerLabelSpacing: 3,
            itemSpacing: 2,
            padding: EdgeInsets.all(3),
            allowDragging: false,
          ),
        ),
      ],
    };
  }

  AnnotationStyle get _annotationStyle => AnnotationStyle(
    textStyle: TextStyle(
      fontSize: _fontSize,
      fontWeight: _boldLabel ? FontWeight.w700 : FontWeight.normal,
      color: const Color(0xFF1E293B),
    ),
    backgroundColor: _labelBackground
        ? Colors.white.withValues(alpha: 0.92)
        : null,
    borderColor: _labelBorder ? _accentColor.withValues(alpha: 0.7) : null,
    borderWidth: _labelBorder ? 1 : 0,
    borderRadius: BorderRadius.circular(6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
  );

  AnnotationStyle _companionStyle(Color color) => AnnotationStyle(
    textStyle: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    backgroundColor: Colors.white.withValues(alpha: 0.88),
    borderColor: color.withValues(alpha: 0.55),
    borderWidth: 0.75,
    borderRadius: BorderRadius.circular(5),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  );

  TrendAnnotation _companionTrend(TrendType trendType) {
    final color = switch (trendType) {
      TrendType.linear => const Color(0xFFEF4444),
      TrendType.polynomial => const Color(0xFFF59E0B),
      TrendType.movingAverage => const Color(0xFF10B981),
      TrendType.exponentialMovingAverage => const Color(0xFF8B5CF6),
    };
    return TrendAnnotation(
      id: 'trend-${trendType.name}',
      seriesId: _seriesId()!,
      trendType: trendType,
      windowSize:
          trendType == TrendType.movingAverage ||
              trendType == TrendType.exponentialMovingAverage
          ? _trendWindow
          : null,
      degree: _polynomialDegree,
      label: _trendLabel(trendType),
      style: _companionStyle(color),
      lineColor: color,
      lineWidth: 1.6,
      dashPattern: const [5, 3],
      allowDragging: _allowDragging,
      allowEditing: _allowEditing,
      zIndex: 1,
    );
  }

  List<double>? get _dashPattern => _dashFor(_linePattern);

  List<double>? _dashFor(_LinePattern pattern) => switch (pattern) {
    _LinePattern.solid => null,
    _LinePattern.dashed => const [7, 4],
    _LinePattern.dotted => const [2, 3],
  };

  bool get _hasLineAppearance => switch (_selectedKind) {
    _AnnotationKind.threshold ||
    _AnnotationKind.trend ||
    _AnnotationKind.chord => true,
    _ => false,
  };

  bool get _supportsElevation => switch (_selectedKind) {
    _AnnotationKind.threshold ||
    _AnnotationKind.trend ||
    _AnnotationKind.chord => true,
    _ => false,
  };

  String get _mainChartSummary => switch (_selectedKind) {
    _AnnotationKind.threshold =>
      '3 variants · ${_thresholdAxis.name.toUpperCase()} axis · value ${_thresholdValue.toStringAsFixed(0)} · ${_linePattern.name}',
    _AnnotationKind.range =>
      '3 variants · ${_rangeDirection.name} · ${_rangeStart.toStringAsFixed(0)}–${_rangeEnd.toStringAsFixed(0)} · ${(_rangeOpacity * 100).round()}% fill',
    _AnnotationKind.point =>
      '3 variants · series-attached index $_pointIndex · ${_markerShape.name} marker · offset label',
    _AnnotationKind.text =>
      '2 variants · ${_richText ? 'Rich Delta' : 'Plain text'} · ${_textAnchor.name} anchor · screen coordinates',
    _AnnotationKind.pin =>
      '3 variants · data coordinates (${_pinX.toStringAsFixed(0)}, ${_pinY.toStringAsFixed(0)}) · ${_markerShape.name} marker',
    _AnnotationKind.trend =>
      '4 calculations · ${_trendLabel(_trendType)} selected · computed overlays',
    _AnnotationKind.chord =>
      '2 variants · indexes $_chordStart–$_chordEnd${_showPerpendicular ? ' · perpendicular deflection at $_perpendicularIndex' : ''}',
    _AnnotationKind.legend =>
      '${_legendPosition.name} · ${_legendOrientation.name} · draggable canvas annotation',
  };

  String get _coverageMessage => switch (_selectedKind) {
    _AnnotationKind.threshold =>
      'Covers axis, value, series scale, line color/width/dash, label position/margin, glow, style, drag, edit, and z-index.',
    _AnnotationKind.range =>
      'Covers X, Y, and rectangular ranges; series scale; fill/border; label placement; snapping increment/tolerance; drag, edit, and z-index.',
    _AnnotationKind.point =>
      'Covers series ID, point index, marker shape/size/color, marker offset, label margin/style, drag, edit, and z-index.',
    _AnnotationKind.text =>
      'Covers plain and rich Delta text, screen position, all nine anchors, background, border, style, drag, edit, and z-index.',
    _AnnotationKind.pin =>
      'Covers data X/Y coordinates, marker shape/size/color, label margin/style, drag, edit, and z-index.',
    _AnnotationKind.trend =>
      'Covers linear, polynomial, moving average, and exponential moving average calculations plus window/degree and complete line styling.',
    _AnnotationKind.chord =>
      'Covers endpoints, perpendicular projection, label offset/style, independent drop-line color/width/dash/glow, and shared chord styling.',
    _AnnotationKind.legend =>
      'Covers series and trend entries, hidden/toggled series, nine positions, both orientations, marker shapes, typography, container styling, spacing, opacity, and dragging.',
  };

  void _selectKind(_AnnotationKind kind) {
    if (_selectedKind == kind) return;
    setState(() {
      _selectedKind = kind;
      _label = switch (kind) {
        _AnnotationKind.threshold => 'Target',
        _AnnotationKind.range => 'Analysis window',
        _AnnotationKind.point => 'Peak sample',
        _AnnotationKind.text => 'Important insight',
        _AnnotationKind.pin => 'Pinned value',
        _AnnotationKind.trend => 'Signal trend',
        _AnnotationKind.chord => 'Rate of change',
        _AnnotationKind.legend => 'Chart legend',
      };
    });
  }

  void _resetOptions() {
    setState(() {
      _showLabel = true;
      _zIndex = 2;
      _seriesTarget = _SeriesTarget.observed;
      _accentColor = const Color(0xFF4F46E5);
      _lineWidth = 2.5;
      _elevation = 4;
      _linePattern = _LinePattern.dashed;
      _fontSize = 12;
      _boldLabel = true;
      _labelBackground = true;
      _labelBorder = true;
      _labelMargin = 8;
      _interactiveAnnotations = true;
      _allowDragging = true;
      _allowEditing = true;
      _thresholdAxis = AnnotationAxis.y;
      _thresholdValue = 65;
      _labelPosition = AnnotationLabelPosition.topLeft;
      _rangeDirection = _RangeDirection.vertical;
      _rangeStart = 7;
      _rangeEnd = 14;
      _rangeOpacity = 0.18;
      _snapToValue = false;
      _snapIncrement = 1;
      _snapTolerance = 0.05;
      _pointIndex = 8;
      _markerShape = MarkerShape.star;
      _markerSize = 12;
      _markerOffsetX = 0;
      _markerOffsetY = -4;
      _richText = true;
      _textAnchor = AnnotationAnchor.topLeft;
      _textX = 110;
      _textY = 54;
      _pinX = 16;
      _pinY = 74;
      _trendType = TrendType.polynomial;
      _trendWindow = 5;
      _polynomialDegree = 2;
      _chordStart = 3;
      _chordEnd = 19;
      _showPerpendicular = true;
      _perpendicularIndex = 11;
      _stylePerpendicularIndependently = true;
      _perpendicularColor = const Color(0xFFEF4444);
      _perpendicularLineWidth = 2;
      _perpendicularElevation = 3;
      _perpendicularPattern = _LinePattern.dotted;
      _legendPosition = LegendPosition.topRight;
      _legendOrientation = LegendOrientation.vertical;
      _legendMarkerShape = LegendMarkerShape.line;
      _legendOpacity = 0.92;
      _legendMarkerSize = 16;
      _legendItemSpacing = 7;
      _legendAllowDragging = true;
      _hideReferenceSeries = false;
      _legendBackground = true;
      _legendBorder = true;
      _legendBorderWidth = 1;
      _legendRadius = 8;
      _legendPadding = 8;
      _legendMarkerLineWidth = 4;
      _legendLabelSpacing = 7;
      _legendOffsetX = 0;
      _legendOffsetY = 0;
    });
  }

  String _kindLabel(_AnnotationKind kind) => switch (kind) {
    _AnnotationKind.threshold => 'Threshold',
    _AnnotationKind.range => 'Range',
    _AnnotationKind.point => 'Point',
    _AnnotationKind.text => 'Text',
    _AnnotationKind.pin => 'Pin',
    _AnnotationKind.trend => 'Trend',
    _AnnotationKind.chord => 'Chord',
    _AnnotationKind.legend => 'Legend',
  };

  String _kindDescription(_AnnotationKind kind) => switch (kind) {
    _AnnotationKind.threshold => 'Fixed X or Y reference',
    _AnnotationKind.range => 'Highlight X, Y, or both',
    _AnnotationKind.point => 'Attach to a series index',
    _AnnotationKind.text => 'Plain or rich text overlay',
    _AnnotationKind.pin => 'Mark a data coordinate',
    _AnnotationKind.trend => 'Four computed trend types',
    _AnnotationKind.chord => 'Connect and project points',
    _AnnotationKind.legend => 'Draggable canvas legend',
  };

  String _kindExplanation(_AnnotationKind kind) => switch (kind) {
    _AnnotationKind.threshold =>
      'Reference lines pinned to an X or Y value. This stage shows a target, a guardrail, and a vertical event marker.',
    _AnnotationKind.range =>
      'Filled regions that can span X, Y, or both axes. Compare a time window, a target band, and a rectangular focus area.',
    _AnnotationKind.point =>
      'Markers attached to exact indexes in a series, so they continue to follow the data through zooming and normalization.',
    _AnnotationKind.text =>
      'Plain or rich Delta text positioned in screen coordinates with 9 available anchor points.',
    _AnnotationKind.pin =>
      'Free markers placed at data coordinates. Unlike point annotations, pins do not require an existing series sample.',
    _AnnotationKind.trend =>
      'Computed overlays for linear regression, polynomial regression, moving average, and exponential moving average.',
    _AnnotationKind.chord =>
      'Secant lines between series indexes, with an optional perpendicular projection for deflection analysis.',
    _AnnotationKind.legend =>
      'A canvas annotation with series toggles, trend entries, 9 anchor positions, custom styling, and drag support.',
  };

  String _kindUseCase(_AnnotationKind kind) => switch (kind) {
    _AnnotationKind.threshold =>
      'Use for limits, targets, events, and baselines.',
    _AnnotationKind.range =>
      'Use for phases, safe zones, and selected regions.',
    _AnnotationKind.point => 'Use for peaks, outliers, and named measurements.',
    _AnnotationKind.text =>
      'Use for analysis notes and contextual explanations.',
    _AnnotationKind.pin =>
      'Use for arbitrary coordinates and user-created markers.',
    _AnnotationKind.trend =>
      'Use to reveal direction, smoothing, and model fit.',
    _AnnotationKind.chord =>
      'Use for rates of change and threshold deflection.',
    _AnnotationKind.legend =>
      'Use when the legend belongs inside the chart canvas.',
  };

  String _trendLabel(TrendType trendType) => switch (trendType) {
    TrendType.linear => 'Linear regression',
    TrendType.polynomial => 'Polynomial regression',
    TrendType.movingAverage => 'Moving average',
    TrendType.exponentialMovingAverage => 'Exponential moving average',
  };
}

class _AnnotationGuide extends StatelessWidget {
  const _AnnotationGuide({
    required this.kindLabel,
    required this.explanation,
    required this.useCase,
  });

  final String kindLabel;
  final String explanation;
  final String useCase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final explanationBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 20, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$kindLabel annotations',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                explanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                useCase,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final contextMenuBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Try it',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
              children: const [
                TextSpan(
                  text: 'Right-click the plot',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' to add an annotation. '),
                TextSpan(
                  text: 'Right-click an annotation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' to edit or delete it. Point, trend, and chord actions appear on compatible data.',
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      key: const ValueKey('annotation-context-menu-guide'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                explanationBlock,
                const SizedBox(height: 12),
                contextMenuBlock,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: explanationBlock),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: contextMenuBlock),
            ],
          );
        },
      ),
    );
  }
}

class _AnnotationPreviewCard extends StatelessWidget {
  const _AnnotationPreviewCard({
    super.key,
    required this.kind,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _AnnotationKind kind;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Select $label annotation',
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-annotation-${kind.name}'),
                        size: 17,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: IgnorePointer(child: chart)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
