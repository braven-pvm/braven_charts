import 'package:flutter/material.dart';

import '../models/chart_theme.dart';
import '../models/pie_chart_config.dart';
import '../theming/components/animation_theme.dart';
import '../theming/components/annotation_theme.dart';
import '../theming/components/axis_style.dart';
import '../theming/components/grid_style.dart';
import '../theming/components/interaction_theme.dart';
import '../theming/components/scrollbar_config.dart';
import '../theming/components/series_theme.dart' as series_theme;
import '../theming/components/typography_theme.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_document.dart';
import 'chart_style_document_codec.dart';
import 'json_value.dart';

enum ChartThemeCaptureMode { referenceOnly, resolvedOnly, referenceAndResolved }

enum ChartThemeHydrationMode { asCaptured, adaptToHost, hostOverride }

/// Complete resolved codec for every appearance-affecting [ChartTheme] field.
abstract final class ChartThemeDocumentCodec {
  static ChartArtifactResult<ChartThemeDocument> encode(
    ChartTheme theme, {
    ChartThemeCaptureMode captureMode =
        ChartThemeCaptureMode.referenceAndResolved,
    String? reference,
  }) {
    try {
      final resolved = captureMode == ChartThemeCaptureMode.referenceOnly
          ? const <String, Object?>{}
          : _encodeTheme(theme);
      return ChartArtifactSuccess(
        value: ChartThemeDocument(
          captureMode: captureMode.name,
          reference: reference,
          resolved: _object(resolved),
        ),
      );
    } on _UnsupportedThemeValue catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: error.message,
          path: error.path,
        ),
      );
    } on UnsupportedError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: error.message?.toString() ?? 'Unsupported theme style.',
          path: r'$.theme.resolved',
        ),
      );
    } on Object catch (error) {
      return _invalidFailure(error);
    }
  }

  static ChartArtifactResult<ChartTheme> decode(ChartThemeDocument document) {
    try {
      _enum(document.captureMode, ChartThemeCaptureMode.values);
      if (document.resolved.values.isEmpty) {
        return ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Reference-only themes require a host theme registry before hydration.',
            path: r'$.theme.reference',
          ),
        );
      }
      return ChartArtifactSuccess(value: _decodeTheme(_map(document.resolved)));
    } on Object catch (error) {
      return _invalidFailure(error);
    }
  }
}

Map<String, Object?> _encodeTheme(ChartTheme theme) => {
  'backgroundColor': theme.backgroundColor.toARGB32(),
  'gridStyle': _encodeGridStyle(theme.gridStyle),
  'axisStyle': _encodeAxisStyle(theme.axisStyle),
  'seriesTheme': _encodeSeriesTheme(theme.seriesTheme),
  'interactionTheme': _encodeInteractionTheme(theme.interactionTheme),
  'typographyTheme': _encodeTypographyTheme(theme.typographyTheme),
  'animationTheme': _encodeAnimationTheme(theme.animationTheme),
  'annotationTheme': _encodeAnnotationTheme(theme.annotationTheme),
  'scrollbarConfig': _encodeScrollbar(theme.scrollbarConfig),
  'legendStyle': ChartStyleDocumentCodec.encodeLegendStyle(
    theme.legendStyle,
  ).toJson(),
  'pieChartTheme': _encodePieChartTheme(theme.pieChartTheme),
  'focusBorderColor': theme.focusBorderColor.toARGB32(),
  'focusBorderWidth': _n(theme.focusBorderWidth),
  'focusBorderRadius': _n(theme.focusBorderRadius),
};

ChartTheme _decodeTheme(Map<String, Object?> map) => ChartTheme(
  backgroundColor: _color(map, 'backgroundColor'),
  gridStyle: _decodeGridStyle(_requiredMap(map, 'gridStyle')),
  axisStyle: _decodeAxisStyle(_requiredMap(map, 'axisStyle')),
  seriesTheme: _decodeSeriesTheme(_requiredMap(map, 'seriesTheme')),
  interactionTheme: _decodeInteractionTheme(
    _requiredMap(map, 'interactionTheme'),
  ),
  typographyTheme: _decodeTypographyTheme(_requiredMap(map, 'typographyTheme')),
  animationTheme: _decodeAnimationTheme(_requiredMap(map, 'animationTheme')),
  annotationTheme: _decodeAnnotationTheme(_requiredMap(map, 'annotationTheme')),
  scrollbarConfig: _decodeScrollbar(_requiredMap(map, 'scrollbarConfig')),
  legendStyle: ChartStyleDocumentCodec.decodeLegendStyle(
    _object(_requiredMap(map, 'legendStyle')),
  ),
  pieChartTheme: map['pieChartTheme'] == null
      ? const PieChartTheme()
      : _decodePieChartTheme(_requiredMap(map, 'pieChartTheme')),
  focusBorderColor: _color(map, 'focusBorderColor'),
  focusBorderWidth: _double(map, 'focusBorderWidth'),
  focusBorderRadius: _double(map, 'focusBorderRadius'),
);

Map<String, Object?> _encodePieChartTheme(PieChartTheme theme) => {
  'opacity': _n(theme.opacity),
  'cornerRadius': _n(theme.cornerRadius),
  'cornerTreatment': theme.cornerTreatment.name,
  'shadow': _encodePieElevation(theme.shadow),
  'selectedElevation': _encodePieElevation(theme.selectedElevation),
  'borderColorMode': theme.borderColorMode.name,
  'borderHueShiftDegrees': _n(theme.borderHueShiftDegrees),
  'borderSaturationShift': _n(theme.borderSaturationShift),
  'borderLightnessShift': _n(theme.borderLightnessShift),
  if (theme.gradient != null) 'gradient': _encodePieGradient(theme.gradient!),
  if (theme.calloutStyle != null)
    'calloutStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      theme.calloutStyle!,
    ).toJson(),
  if (theme.centerLabelStyle != null)
    'centerLabelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      theme.centerLabelStyle!,
    ).toJson(),
  if (theme.centerValueStyle != null)
    'centerValueStyle': ChartStyleDocumentCodec.encodeLabelStyle(
      theme.centerValueStyle!,
    ).toJson(),
  'animationMode': theme.animationMode.name,
};

PieChartTheme _decodePieChartTheme(Map<String, Object?> map) => PieChartTheme(
  opacity: _double(map, 'opacity'),
  cornerRadius: _double(map, 'cornerRadius'),
  cornerTreatment: map['cornerTreatment'] == null
      ? PieCornerTreatment.roundAll
      : _enum(_string(map, 'cornerTreatment'), PieCornerTreatment.values),
  shadow: _decodePieElevation(_requiredMap(map, 'shadow')),
  selectedElevation: _decodePieElevation(
    _requiredMap(map, 'selectedElevation'),
  ),
  borderColorMode: map['borderColorMode'] == null
      ? PieBorderColorMode.chartTheme
      : _enum(_string(map, 'borderColorMode'), PieBorderColorMode.values),
  borderHueShiftDegrees: _optionalDouble(map['borderHueShiftDegrees']) ?? 0,
  borderSaturationShift: _optionalDouble(map['borderSaturationShift']) ?? 0,
  borderLightnessShift: _optionalDouble(map['borderLightnessShift']) ?? -0.12,
  gradient: map['gradient'] == null
      ? null
      : _decodePieGradient(_requiredMap(map, 'gradient')),
  calloutStyle: map['calloutStyle'] == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _object(_requiredMap(map, 'calloutStyle')),
        ),
  centerLabelStyle: map['centerLabelStyle'] == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _object(_requiredMap(map, 'centerLabelStyle')),
        ),
  centerValueStyle: map['centerValueStyle'] == null
      ? null
      : ChartStyleDocumentCodec.decodeLabelStyle(
          _object(_requiredMap(map, 'centerValueStyle')),
        ),
  animationMode: _enum(_string(map, 'animationMode'), PieAnimationMode.values),
);

Map<String, Object?> _encodePieGradient(PieGradientStyle style) => {
  'enabled': style.enabled,
  'type': style.type.name,
  if (style.startColor != null) 'startColor': style.startColor!.toARGB32(),
  if (style.endColor != null) 'endColor': style.endColor!.toARGB32(),
  'startLightnessShift': _n(style.startLightnessShift),
  'endLightnessShift': _n(style.endLightnessShift),
  'angleDegrees': _n(style.angleDegrees),
};

PieGradientStyle _decodePieGradient(Map<String, Object?> map) =>
    PieGradientStyle(
      enabled: _bool(map, 'enabled'),
      type: _enum(_string(map, 'type'), PieGradientType.values),
      startColor: _optionalColor(map['startColor']),
      endColor: _optionalColor(map['endColor']),
      startLightnessShift: _double(map, 'startLightnessShift'),
      endLightnessShift: _double(map, 'endLightnessShift'),
      angleDegrees: _double(map, 'angleDegrees'),
    );

Map<String, Object?> _encodePieElevation(PieElevationStyle style) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  'blurRadius': _n(style.blurRadius),
  'spreadRadius': _n(style.spreadRadius),
  'offset': {'dx': _n(style.offset.dx), 'dy': _n(style.offset.dy)},
  'opacity': _n(style.opacity),
};

PieElevationStyle _decodePieElevation(Map<String, Object?> map) =>
    PieElevationStyle(
      color: _optionalColor(map['color']),
      blurRadius: _double(map, 'blurRadius'),
      spreadRadius: _double(map, 'spreadRadius'),
      offset: Offset(
        _double(_requiredMap(map, 'offset'), 'dx'),
        _double(_requiredMap(map, 'offset'), 'dy'),
      ),
      opacity: _double(map, 'opacity'),
    );

Map<String, Object?> _encodeGridStyle(GridStyle style) => {
  'majorColor': style.majorColor.toARGB32(),
  'majorWidth': _n(style.majorWidth),
  'majorDashPattern': style.majorDashPattern.map(_n).toList(),
  if (style.minorColor != null) 'minorColor': style.minorColor!.toARGB32(),
  if (style.minorWidth != null) 'minorWidth': _n(style.minorWidth!),
  'minorDashPattern': style.minorDashPattern.map(_n).toList(),
  'showMinor': style.showMinor,
};

GridStyle _decodeGridStyle(Map<String, Object?> map) => GridStyle(
  majorColor: _color(map, 'majorColor'),
  majorWidth: _double(map, 'majorWidth'),
  majorDashPattern: _doubleList(map, 'majorDashPattern'),
  minorColor: _optionalColor(map['minorColor']),
  minorWidth: _optionalDouble(map['minorWidth']),
  minorDashPattern: _doubleList(map, 'minorDashPattern'),
  showMinor: _bool(map, 'showMinor'),
);

Map<String, Object?> _encodeAxisStyle(AxisStyle style) => {
  'lineColor': style.lineColor.toARGB32(),
  'lineWidth': _n(style.lineWidth),
  'labelStyle': ChartStyleDocumentCodec.encodeTextStyle(
    style.labelStyle,
  ).toJson(),
  'titleStyle': ChartStyleDocumentCodec.encodeTextStyle(
    style.titleStyle,
  ).toJson(),
  'showTicks': style.showTicks,
  'tickLength': _n(style.tickLength),
  'tickColor': style.tickColor.toARGB32(),
  'tickWidth': _n(style.tickWidth),
};

AxisStyle _decodeAxisStyle(Map<String, Object?> map) => AxisStyle(
  lineColor: _color(map, 'lineColor'),
  lineWidth: _double(map, 'lineWidth'),
  labelStyle: ChartStyleDocumentCodec.decodeTextStyle(
    _object(_requiredMap(map, 'labelStyle')),
  ),
  titleStyle: ChartStyleDocumentCodec.decodeTextStyle(
    _object(_requiredMap(map, 'titleStyle')),
  ),
  showTicks: _bool(map, 'showTicks'),
  tickLength: _double(map, 'tickLength'),
  tickColor: _color(map, 'tickColor'),
  tickWidth: _double(map, 'tickWidth'),
);

Map<String, Object?> _encodeSeriesTheme(series_theme.SeriesTheme theme) => {
  'colors': theme.colors.map((color) => color.toARGB32()).toList(),
  'lineWidths': theme.lineWidths.map(_n).toList(),
  'markerSizes': theme.markerSizes.map(_n).toList(),
  'markerShapes': theme.markerShapes.map((shape) => shape.name).toList(),
};

series_theme.SeriesTheme _decodeSeriesTheme(Map<String, Object?> map) =>
    series_theme.SeriesTheme(
      colors: _list(map, 'colors').map(_requiredColorValue).toList(),
      lineWidths: _doubleList(map, 'lineWidths'),
      markerSizes: _doubleList(map, 'markerSizes'),
      markerShapes: _list(map, 'markerShapes')
          .map(
            (value) => _enum(
              _requiredStringValue(value),
              series_theme.SeriesMarkerShape.values,
            ),
          )
          .toList(),
    );

Map<String, Object?> _encodeInteractionTheme(InteractionTheme theme) => {
  'crosshairColor': theme.crosshairColor.toARGB32(),
  'crosshairWidth': _n(theme.crosshairWidth),
  'crosshairDashPattern': theme.crosshairDashPattern.map(_n).toList(),
  'crosshairLabelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
    theme.crosshairLabelStyle,
  ).toJson(),
  'tooltipStyle': ChartStyleDocumentCodec.encodeLabelStyle(
    theme.tooltipStyle,
  ).toJson(),
  'selectionColor': theme.selectionColor.toARGB32(),
};

InteractionTheme _decodeInteractionTheme(Map<String, Object?> map) =>
    InteractionTheme(
      crosshairColor: _color(map, 'crosshairColor'),
      crosshairWidth: _double(map, 'crosshairWidth'),
      crosshairDashPattern: _doubleList(map, 'crosshairDashPattern'),
      crosshairLabelStyle: ChartStyleDocumentCodec.decodeLabelStyle(
        _object(_requiredMap(map, 'crosshairLabelStyle')),
      ),
      tooltipStyle: ChartStyleDocumentCodec.decodeLabelStyle(
        _object(_requiredMap(map, 'tooltipStyle')),
      ),
      selectionColor: _color(map, 'selectionColor'),
    );

Map<String, Object?> _encodeTypographyTheme(TypographyTheme theme) => {
  'fontFamily': theme.fontFamily,
  'baseFontSize': _n(theme.baseFontSize),
  'scaleFactorMobile': _n(theme.scaleFactorMobile),
  'scaleFactorTablet': _n(theme.scaleFactorTablet),
  'scaleFactorDesktop': _n(theme.scaleFactorDesktop),
  'titleMultiplier': _n(theme.titleMultiplier),
  'labelMultiplier': _n(theme.labelMultiplier),
};

TypographyTheme _decodeTypographyTheme(Map<String, Object?> map) =>
    TypographyTheme(
      fontFamily: _string(map, 'fontFamily'),
      baseFontSize: _double(map, 'baseFontSize'),
      scaleFactorMobile: _double(map, 'scaleFactorMobile'),
      scaleFactorTablet: _double(map, 'scaleFactorTablet'),
      scaleFactorDesktop: _double(map, 'scaleFactorDesktop'),
      titleMultiplier: _double(map, 'titleMultiplier'),
      labelMultiplier: _double(map, 'labelMultiplier'),
    );

Map<String, Object?> _encodeAnimationTheme(AnimationTheme theme) => {
  'dataUpdateDurationMicros': theme.dataUpdateDuration.inMicroseconds,
  'dataUpdateCurve': _curveName(
    theme.dataUpdateCurve,
    r'$.theme.resolved.animationTheme.dataUpdateCurve',
  ),
  'themeChangeDurationMicros': theme.themeChangeDuration.inMicroseconds,
  'themeChangeCurve': _curveName(
    theme.themeChangeCurve,
    r'$.theme.resolved.animationTheme.themeChangeCurve',
  ),
  'interactionDurationMicros': theme.interactionDuration.inMicroseconds,
  'interactionCurve': _curveName(
    theme.interactionCurve,
    r'$.theme.resolved.animationTheme.interactionCurve',
  ),
};

AnimationTheme _decodeAnimationTheme(Map<String, Object?> map) =>
    AnimationTheme(
      dataUpdateDuration: Duration(
        microseconds: _int(map, 'dataUpdateDurationMicros'),
      ),
      dataUpdateCurve: _curve(_string(map, 'dataUpdateCurve')),
      themeChangeDuration: Duration(
        microseconds: _int(map, 'themeChangeDurationMicros'),
      ),
      themeChangeCurve: _curve(_string(map, 'themeChangeCurve')),
      interactionDuration: Duration(
        microseconds: _int(map, 'interactionDurationMicros'),
      ),
      interactionCurve: _curve(_string(map, 'interactionCurve')),
    );

Map<String, Object?> _encodeAnnotationTheme(AnnotationTheme theme) => {
  'pointDefaults': _encodePointDefaults(theme.pointDefaults),
  'rangeDefaults': _encodeRangeDefaults(theme.rangeDefaults),
  'textDefaults': _encodeTextDefaults(theme.textDefaults),
  'thresholdDefaults': _encodeThresholdDefaults(theme.thresholdDefaults),
  'trendDefaults': _encodeTrendDefaults(theme.trendDefaults),
};

AnnotationTheme _decodeAnnotationTheme(Map<String, Object?> map) =>
    AnnotationTheme(
      pointDefaults: _decodePointDefaults(_requiredMap(map, 'pointDefaults')),
      rangeDefaults: _decodeRangeDefaults(_requiredMap(map, 'rangeDefaults')),
      textDefaults: _decodeTextDefaults(_requiredMap(map, 'textDefaults')),
      thresholdDefaults: _decodeThresholdDefaults(
        _requiredMap(map, 'thresholdDefaults'),
      ),
      trendDefaults: _decodeTrendDefaults(_requiredMap(map, 'trendDefaults')),
    );

Map<String, Object?> _encodePointDefaults(PointAnnotationDefaults value) => {
  'markerShape': value.markerShape.name,
  'markerSize': _n(value.markerSize),
  'normalColor': value.normalColor.toARGB32(),
  'selectedColor': value.selectedColor.toARGB32(),
  'hoveredColor': value.hoveredColor.toARGB32(),
  'draggingColor': value.draggingColor.toARGB32(),
  'ghostOpacity': _n(value.ghostOpacity),
  'previewOpacity': _n(value.previewOpacity),
  'previewScale': _n(value.previewScale),
  'labelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
    value.labelStyle,
  ).toJson(),
};

PointAnnotationDefaults _decodePointDefaults(Map<String, Object?> map) =>
    PointAnnotationDefaults(
      markerShape: _enum(
        _string(map, 'markerShape'),
        series_theme.SeriesMarkerShape.values,
      ),
      markerSize: _double(map, 'markerSize'),
      normalColor: _color(map, 'normalColor'),
      selectedColor: _color(map, 'selectedColor'),
      hoveredColor: _color(map, 'hoveredColor'),
      draggingColor: _color(map, 'draggingColor'),
      ghostOpacity: _double(map, 'ghostOpacity'),
      previewOpacity: _double(map, 'previewOpacity'),
      previewScale: _double(map, 'previewScale'),
      labelStyle: ChartStyleDocumentCodec.decodeLabelStyle(
        _object(_requiredMap(map, 'labelStyle')),
      ),
    );

Map<String, Object?> _encodeRangeDefaults(RangeAnnotationDefaults value) => {
  'normalFillColor': value.normalFillColor.toARGB32(),
  'selectedFillColor': value.selectedFillColor.toARGB32(),
  'hoveredFillColor': value.hoveredFillColor.toARGB32(),
  'draggingFillColor': value.draggingFillColor.toARGB32(),
  'normalBorderColor': value.normalBorderColor.toARGB32(),
  'selectedBorderColor': value.selectedBorderColor.toARGB32(),
  'hoveredBorderColor': value.hoveredBorderColor.toARGB32(),
  'draggingBorderColor': value.draggingBorderColor.toARGB32(),
  'borderWidth': _n(value.borderWidth),
  'labelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
    value.labelStyle,
  ).toJson(),
};

RangeAnnotationDefaults _decodeRangeDefaults(Map<String, Object?> map) =>
    RangeAnnotationDefaults(
      normalFillColor: _color(map, 'normalFillColor'),
      selectedFillColor: _color(map, 'selectedFillColor'),
      hoveredFillColor: _color(map, 'hoveredFillColor'),
      draggingFillColor: _color(map, 'draggingFillColor'),
      normalBorderColor: _color(map, 'normalBorderColor'),
      selectedBorderColor: _color(map, 'selectedBorderColor'),
      hoveredBorderColor: _color(map, 'hoveredBorderColor'),
      draggingBorderColor: _color(map, 'draggingBorderColor'),
      borderWidth: _double(map, 'borderWidth'),
      labelStyle: ChartStyleDocumentCodec.decodeLabelStyle(
        _object(_requiredMap(map, 'labelStyle')),
      ),
    );

Map<String, Object?> _encodeTextDefaults(TextAnnotationDefaults value) => {
  'textStyle': ChartStyleDocumentCodec.encodeTextStyle(
    value.textStyle,
  ).toJson(),
  'backgroundColor': value.backgroundColor.toARGB32(),
  'borderColor': value.borderColor.toARGB32(),
  'borderWidth': _n(value.borderWidth),
  'borderRadius': _n(value.borderRadius),
  'padding': _encodeInsets(value.padding),
};

TextAnnotationDefaults _decodeTextDefaults(Map<String, Object?> map) =>
    TextAnnotationDefaults(
      textStyle: ChartStyleDocumentCodec.decodeTextStyle(
        _object(_requiredMap(map, 'textStyle')),
      ),
      backgroundColor: _color(map, 'backgroundColor'),
      borderColor: _color(map, 'borderColor'),
      borderWidth: _double(map, 'borderWidth'),
      borderRadius: _double(map, 'borderRadius'),
      padding: _decodeInsets(_requiredMap(map, 'padding')),
    );

Map<String, Object?> _encodeThresholdDefaults(
  ThresholdAnnotationDefaults value,
) => {
  'lineColor': value.lineColor.toARGB32(),
  'lineWidth': _n(value.lineWidth),
  'dashPattern': value.dashPattern.map(_n).toList(),
  'labelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
    value.labelStyle,
  ).toJson(),
};

ThresholdAnnotationDefaults _decodeThresholdDefaults(
  Map<String, Object?> map,
) => ThresholdAnnotationDefaults(
  lineColor: _color(map, 'lineColor'),
  lineWidth: _double(map, 'lineWidth'),
  dashPattern: _doubleList(map, 'dashPattern'),
  labelStyle: ChartStyleDocumentCodec.decodeLabelStyle(
    _object(_requiredMap(map, 'labelStyle')),
  ),
);

Map<String, Object?> _encodeTrendDefaults(TrendAnnotationDefaults value) => {
  'lineColor': value.lineColor.toARGB32(),
  'lineWidth': _n(value.lineWidth),
  'dashPattern': value.dashPattern.map(_n).toList(),
  'confidenceBandColor': value.confidenceBandColor.toARGB32(),
  'confidenceBandOpacity': _n(value.confidenceBandOpacity),
  'labelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
    value.labelStyle,
  ).toJson(),
};

TrendAnnotationDefaults _decodeTrendDefaults(Map<String, Object?> map) =>
    TrendAnnotationDefaults(
      lineColor: _color(map, 'lineColor'),
      lineWidth: _double(map, 'lineWidth'),
      dashPattern: _doubleList(map, 'dashPattern'),
      confidenceBandColor: _color(map, 'confidenceBandColor'),
      confidenceBandOpacity: _double(map, 'confidenceBandOpacity'),
      labelStyle: ChartStyleDocumentCodec.decodeLabelStyle(
        _object(_requiredMap(map, 'labelStyle')),
      ),
    );

Map<String, Object?> _encodeScrollbar(ScrollbarConfig value) => {
  'thickness': _n(value.thickness),
  'minHandleSize': _n(value.minHandleSize),
  'trackColor': value.trackColor.toARGB32(),
  'handleColor': value.handleColor.toARGB32(),
  'handleHoverColor': value.handleHoverColor.toARGB32(),
  'edgeZoneColor': value.edgeZoneColor.toARGB32(),
  'edgeHoverColor': value.edgeHoverColor.toARGB32(),
  'handleActiveColor': value.handleActiveColor.toARGB32(),
  'handleDisabledColor': value.handleDisabledColor.toARGB32(),
  'trackHoverColor': value.trackHoverColor.toARGB32(),
  'borderRadius': _n(value.borderRadius),
  'showGripIndicator': value.showGripIndicator,
  'gripIndicatorColor': value.gripIndicatorColor.toARGB32(),
  'padding': _n(value.padding),
  'edgeGripWidth': _n(value.edgeGripWidth),
  'enableResizeHandles': value.enableResizeHandles,
  'minZoomRatio': _n(value.minZoomRatio),
  'maxZoomRatio': _n(value.maxZoomRatio),
  'autoHide': value.autoHide,
  'autoHideDelayMicros': value.autoHideDelay.inMicroseconds,
  'fadeDurationMicros': value.fadeDuration.inMicroseconds,
  'forcedColorsMode': value.forcedColorsMode,
  'prefersReducedMotion': value.prefersReducedMotion,
};

ScrollbarConfig _decodeScrollbar(Map<String, Object?> map) => ScrollbarConfig(
  thickness: _double(map, 'thickness'),
  minHandleSize: _double(map, 'minHandleSize'),
  trackColor: _color(map, 'trackColor'),
  handleColor: _color(map, 'handleColor'),
  handleHoverColor: _color(map, 'handleHoverColor'),
  edgeZoneColor: _color(map, 'edgeZoneColor'),
  edgeHoverColor: _color(map, 'edgeHoverColor'),
  handleActiveColor: _color(map, 'handleActiveColor'),
  handleDisabledColor: _color(map, 'handleDisabledColor'),
  trackHoverColor: _color(map, 'trackHoverColor'),
  borderRadius: _double(map, 'borderRadius'),
  showGripIndicator: _bool(map, 'showGripIndicator'),
  gripIndicatorColor: _color(map, 'gripIndicatorColor'),
  padding: _double(map, 'padding'),
  edgeGripWidth: _double(map, 'edgeGripWidth'),
  enableResizeHandles: _bool(map, 'enableResizeHandles'),
  minZoomRatio: _double(map, 'minZoomRatio'),
  maxZoomRatio: _double(map, 'maxZoomRatio'),
  autoHide: _bool(map, 'autoHide'),
  autoHideDelay: Duration(microseconds: _int(map, 'autoHideDelayMicros')),
  fadeDuration: Duration(microseconds: _int(map, 'fadeDurationMicros')),
  forcedColorsMode: _bool(map, 'forcedColorsMode'),
  prefersReducedMotion: _bool(map, 'prefersReducedMotion'),
);

String _curveName(Curve curve, String path) {
  for (final entry in _curves.entries) {
    if (curve == entry.value) return entry.key;
  }
  throw _UnsupportedThemeValue(
    'Custom animation curves require an extension codec.',
    path,
  );
}

Curve _curve(String name) =>
    _curves[name] ?? (throw FormatException('Unknown curve "$name".'));

final Map<String, Curve> _curves = {
  'linear': Curves.linear,
  'easeIn': Curves.easeIn,
  'easeOut': Curves.easeOut,
  'easeInOut': Curves.easeInOut,
  'easeInCubic': Curves.easeInCubic,
  'easeOutCubic': Curves.easeOutCubic,
  'easeInOutCubic': Curves.easeInOutCubic,
  'fastOutSlowIn': Curves.fastOutSlowIn,
  'bounceIn': Curves.bounceIn,
  'bounceOut': Curves.bounceOut,
  'bounceInOut': Curves.bounceInOut,
  'elasticIn': Curves.elasticIn,
  'elasticOut': Curves.elasticOut,
  'elasticInOut': Curves.elasticInOut,
  'easeOutBack': Curves.easeOutBack,
};

Map<String, Object?> _encodeInsets(EdgeInsets value) => {
  'left': _n(value.left),
  'top': _n(value.top),
  'right': _n(value.right),
  'bottom': _n(value.bottom),
};

EdgeInsets _decodeInsets(Map<String, Object?> map) => EdgeInsets.fromLTRB(
  _double(map, 'left'),
  _double(map, 'top'),
  _double(map, 'right'),
  _double(map, 'bottom'),
);

Object _n(double value) => ChartNumberDocument.fromDouble(value).toJson();

JsonObjectValue _object(Map<String, Object?> value) =>
    JsonValue.fromJson(value) as JsonObjectValue;

Map<String, Object?> _map(JsonObjectValue value) =>
    Map<String, Object?>.from(value.toJson() as Map);

Map<String, Object?> _requiredMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('Expected object at $key.');
}

List<Object?> _list(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is List) return List<Object?>.from(value);
  throw FormatException('Expected list at $key.');
}

List<double> _doubleList(Map<String, Object?> map, String key) =>
    _list(map, key).map((value) => _requiredDoubleValue(value)).toList();

String _string(Map<String, Object?> map, String key) =>
    _requiredStringValue(map[key]);

String _requiredStringValue(Object? value) {
  if (value is String) return value;
  throw const FormatException('Expected string value.');
}

bool _bool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is bool) return value;
  throw FormatException('Expected boolean at $key.');
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  throw FormatException('Expected integer at $key.');
}

double _double(Map<String, Object?> map, String key) =>
    _requiredDoubleValue(map[key]);

double _requiredDoubleValue(Object? value) =>
    ChartNumberDocument.fromJson(value).asDouble;

double? _optionalDouble(Object? value) =>
    value == null ? null : _requiredDoubleValue(value);

Color _color(Map<String, Object?> map, String key) =>
    _requiredColorValue(map[key]);

Color _requiredColorValue(Object? value) {
  if (value is int) return Color(value);
  throw const FormatException('Expected ARGB color integer.');
}

Color? _optionalColor(Object? value) =>
    value == null ? null : _requiredColorValue(value);

T _enum<T extends Enum>(String name, List<T> values) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown enum value "$name".');
}

ChartArtifactFailure<T> _invalidFailure<T>(Object error) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid resolved chart theme: $error',
        path: r'$.theme.resolved',
      ),
    );

class _UnsupportedThemeValue implements Exception {
  const _UnsupportedThemeValue(this.message, this.path);

  final String message;
  final String path;
}
