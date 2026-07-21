import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../models/cartesian_value_summary_config.dart';
import '../models/cartesian_value_summary_style.dart';
import '../models/chart_overlay_placement.dart';
import '../models/chart_style_value.dart';
import '../models/interaction_config.dart';
import '../models/interaction_callbacks.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_data_payload.dart';
import 'chart_document.dart';
import 'chart_runtime_bindings.dart';
import 'chart_style_document_codec.dart';
import 'json_value.dart';

/// Complete portable codec for [InteractionConfig].
///
/// Executable callbacks are represented only by explicit host binding
/// descriptors. Decoding a document that requires bindings is deferred to the
/// hydration layer, where a runtime registry can safely resolve them.
abstract final class ChartInteractionDocumentCodec {
  static const tooltipBuilderBinding = 'tooltip.customBuilder';
  static const dataPointTapBinding = 'onDataPointTap';
  static const dataPointHoverBinding = 'onDataPointHover';
  static const dataPointLongPressBinding = 'onDataPointLongPress';
  static const selectionChangedBinding = 'onSelectionChanged';
  static const zoomChangedBinding = 'onZoomChanged';
  static const panChangedBinding = 'onPanChanged';
  static const viewportChangedBinding = 'onViewportChanged';
  static const crosshairChangedBinding = 'onCrosshairChanged';
  static const tooltipChangedBinding = 'onTooltipChanged';
  static const keyboardActionBinding = 'onKeyboardAction';
  static const valueSummaryPlacementChangedBinding =
      'valueSummary.onPlacementChanged';

  static ChartArtifactResult<ChartInteractionDocument> encode(
    InteractionConfig config, {
    Map<String, JsonObjectValue> runtimeBindingDescriptors = const {},
  }) {
    final warnings = <ChartArtifactWarning>[];
    try {
      final callbacks = <String, Object?>{};
      final requiredBindings = <String>{};
      void capture(String field, bool present) {
        if (!present) return;
        final descriptor = runtimeBindingDescriptors[field];
        if (descriptor == null) {
          throw _BindingException(
            'Interaction callback $field requires a runtime binding descriptor.',
            r'$.interaction.configuration.callbacks.' + field,
          );
        }
        final descriptorMap = _map(descriptor);
        final id = _string(descriptorMap, 'id');
        callbacks[field] = descriptor.toJson();
        requiredBindings.add(id);
      }

      capture(tooltipBuilderBinding, config.tooltip.customBuilder != null);
      capture(dataPointTapBinding, config.onDataPointTap != null);
      capture(dataPointHoverBinding, config.onDataPointHover != null);
      capture(dataPointLongPressBinding, config.onDataPointLongPress != null);
      capture(selectionChangedBinding, config.onSelectionChanged != null);
      capture(zoomChangedBinding, config.onZoomChanged != null);
      capture(panChangedBinding, config.onPanChanged != null);
      capture(viewportChangedBinding, config.onViewportChanged != null);
      capture(crosshairChangedBinding, config.onCrosshairChanged != null);
      capture(tooltipChangedBinding, config.onTooltipChanged != null);
      capture(keyboardActionBinding, config.onKeyboardAction != null);
      capture(
        valueSummaryPlacementChangedBinding,
        config.valueSummary.onPlacementChanged != null,
      );

      return ChartArtifactSuccess(
        value: ChartInteractionDocument(
          configuration: _object({
            'enabled': config.enabled,
            'crosshair': _encodeCrosshair(config.crosshair),
            'tooltip': _encodeTooltip(config.tooltip),
            'gesture': _encodeGesture(config.gesture),
            'keyboard': _encodeKeyboard(config.keyboard),
            'enableZoom': config.enableZoom,
            'enablePan': config.enablePan,
            'enableSelection': config.enableSelection,
            if (config.selection != const ChartSelectionConfig())
              'selection': _encodeSelection(config.selection),
            if (config.valueSummary != const CartesianValueSummaryConfig())
              'valueSummary': _encodeValueSummary(
                config.valueSummary,
                requiredBindings,
                warnings,
              ),
            'showFocusBorder': config.showFocusBorder,
            'enableFocusOnHover': config.enableFocusOnHover,
            'showXScrollbar': config.showXScrollbar,
            'showYScrollbar': config.showYScrollbar,
            'keyboardZoomPercent': config.keyboardZoomPercent,
            if (callbacks.isNotEmpty) 'callbacks': callbacks,
          }),
          requiredBindings: requiredBindings,
        ),
        warnings: warnings,
      );
    } on _BindingException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          message: error.message,
          path: error.path,
        ),
        warnings: warnings,
      );
    } on UnsupportedError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message:
              error.message?.toString() ?? 'Unsupported interaction style.',
          path: r'$.interaction.configuration',
        ),
        warnings: warnings,
      );
    } on Object catch (error) {
      return _invalidFailure(error);
    }
  }

  static ChartArtifactResult<InteractionConfig> decode(
    ChartInteractionDocument document, {
    ChartRuntimeBindings bindings = const ChartRuntimeBindings(),
  }) {
    final warnings = <ChartArtifactWarning>[];
    try {
      final map = _map(document.configuration);
      final callbackDescriptors = map['callbacks'] == null
          ? const <String, Object?>{}
          : _requiredMap(map, 'callbacks');
      final describedBindingIds = <String>{};
      String? descriptorId(String field) {
        final raw = callbackDescriptors[field];
        if (raw == null) return null;
        if (raw is! Map) {
          throw FormatException(
            'Callback descriptor $field must be an object.',
          );
        }
        final descriptor = Map<String, Object?>.from(raw);
        final id = _string(descriptor, 'id');
        if (!document.requiredBindings.contains(id)) {
          throw FormatException(
            'Callback descriptor $field must declare $id in requiredBindings.',
          );
        }
        describedBindingIds.add(id);
        return id;
      }

      T? resolveCallback<T extends Function>(String field) {
        final id = descriptorId(field);
        if (id == null) return null;
        final callback = bindings.callbacks.resolve<T>(id);
        if (callback == null) {
          warnings.add(
            ChartArtifactWarning(
              code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
              message:
                  'Optional interaction binding "$id" is unavailable; $field is disabled.',
              path: r'$.interaction.configuration.callbacks.' + field,
            ),
          );
        }
        return callback;
      }

      final tooltipBuilderId = descriptorId(tooltipBuilderBinding);
      final tooltipBuilder = tooltipBuilderId == null
          ? null
          : bindings.tooltips.resolve(tooltipBuilderId);
      if (tooltipBuilderId != null && tooltipBuilder == null) {
        warnings.add(
          ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Optional tooltip binding "$tooltipBuilderId" is unavailable; the standard tooltip is active.',
            path:
                r'$.interaction.configuration.callbacks.tooltip.customBuilder',
          ),
        );
      }
      final onDataPointTap = resolveCallback<DataPointCallback>(
        dataPointTapBinding,
      );
      final onDataPointHover = resolveCallback<DataPointHoverCallback>(
        dataPointHoverBinding,
      );
      final onDataPointLongPress = resolveCallback<DataPointLongPressCallback>(
        dataPointLongPressBinding,
      );
      final onSelectionChanged = resolveCallback<SelectionCallback>(
        selectionChangedBinding,
      );
      final onZoomChanged = resolveCallback<ZoomCallback>(zoomChangedBinding);
      final onPanChanged = resolveCallback<PanCallback>(panChangedBinding);
      final onViewportChanged = resolveCallback<ViewportCallback>(
        viewportChangedBinding,
      );
      final onCrosshairChanged = resolveCallback<CrosshairChangeCallback>(
        crosshairChangedBinding,
      );
      final onTooltipChanged = resolveCallback<TooltipChangeCallback>(
        tooltipChangedBinding,
      );
      final onKeyboardAction = resolveCallback<KeyboardActionCallback>(
        keyboardActionBinding,
      );
      final onPlacementChanged =
          resolveCallback<ValueChanged<ChartOverlayPlacement>>(
            valueSummaryPlacementChangedBinding,
          );
      var valueSummary = map['valueSummary'] == null
          ? const CartesianValueSummaryConfig()
          : _decodeValueSummary(
              _requiredMap(map, 'valueSummary'),
              document: document,
              bindings: bindings,
              warnings: warnings,
              describedBindingIds: describedBindingIds,
            );
      if (onPlacementChanged != null) {
        valueSummary = valueSummary.copyWith(
          onPlacementChanged: onPlacementChanged,
        );
      }
      for (final id in document.requiredBindings.difference(
        describedBindingIds,
      )) {
        warnings.add(
          ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Runtime binding "$id" has no recognized interaction descriptor and was ignored.',
            path: r'$.interaction.requiredBindings',
          ),
        );
      }

      return ChartArtifactSuccess(
        value: InteractionConfig(
          enabled: _bool(map, 'enabled'),
          crosshair: _decodeCrosshair(_requiredMap(map, 'crosshair')),
          tooltip: _decodeTooltip(
            _requiredMap(map, 'tooltip'),
            customBuilder: tooltipBuilder,
          ),
          gesture: _decodeGesture(_requiredMap(map, 'gesture')),
          keyboard: _decodeKeyboard(_requiredMap(map, 'keyboard')),
          enableZoom: _bool(map, 'enableZoom'),
          enablePan: _bool(map, 'enablePan'),
          enableSelection: _bool(map, 'enableSelection'),
          selection: map['selection'] == null
              ? const ChartSelectionConfig()
              : _decodeSelection(_requiredMap(map, 'selection')),
          valueSummary: valueSummary,
          showFocusBorder: _bool(map, 'showFocusBorder'),
          enableFocusOnHover: _bool(map, 'enableFocusOnHover'),
          showXScrollbar: _bool(map, 'showXScrollbar'),
          showYScrollbar: _bool(map, 'showYScrollbar'),
          keyboardZoomPercent: _int(map, 'keyboardZoomPercent'),
          onDataPointTap: onDataPointTap,
          onDataPointHover: onDataPointHover,
          onDataPointLongPress: onDataPointLongPress,
          onSelectionChanged: onSelectionChanged,
          onZoomChanged: onZoomChanged,
          onPanChanged: onPanChanged,
          onViewportChanged: onViewportChanged,
          onCrosshairChanged: onCrosshairChanged,
          onTooltipChanged: onTooltipChanged,
          onKeyboardAction: onKeyboardAction,
        ),
        warnings: warnings,
      );
    } on Object catch (error) {
      return _invalidFailure(error);
    }
  }
}

Map<String, Object?> _encodeCrosshair(CrosshairConfig value) => {
  'enabled': value.enabled,
  'mode': value.mode.name,
  'snapToDataPoint': value.snapToDataPoint,
  'snapRadius': _n(value.snapRadius),
  'showCoordinateLabels': value.showCoordinateLabels,
  if (value.coordinateLabelStyle != null)
    'coordinateLabelStyle': ChartStyleDocumentCodec.encodeTextStyle(
      value.coordinateLabelStyle!,
    ).toJson(),
  'style': _encodeCrosshairStyle(value.style),
  'displayMode': value.displayMode.name,
  'trackingModeThreshold': value.trackingModeThreshold,
  'interpolateValues': value.interpolateValues,
  'showTrackingTooltip': value.showTrackingTooltip,
  'showIntersectionMarkers': value.showIntersectionMarkers,
  'intersectionMarkerRadius': _n(value.intersectionMarkerRadius),
};

CrosshairConfig _decodeCrosshair(Map<String, Object?> map) => CrosshairConfig(
  enabled: _bool(map, 'enabled'),
  mode: _enum(map, 'mode', CrosshairMode.values),
  snapToDataPoint: _bool(map, 'snapToDataPoint'),
  snapRadius: _double(map, 'snapRadius'),
  showCoordinateLabels: _bool(map, 'showCoordinateLabels'),
  coordinateLabelStyle: map['coordinateLabelStyle'] == null
      ? null
      : ChartStyleDocumentCodec.decodeTextStyle(
          _object(_requiredMap(map, 'coordinateLabelStyle')),
        ),
  style: _decodeCrosshairStyle(_requiredMap(map, 'style')),
  displayMode: _enum(map, 'displayMode', CrosshairDisplayMode.values),
  trackingModeThreshold: _int(map, 'trackingModeThreshold'),
  interpolateValues: _bool(map, 'interpolateValues'),
  showTrackingTooltip: _bool(map, 'showTrackingTooltip'),
  showIntersectionMarkers: _bool(map, 'showIntersectionMarkers'),
  intersectionMarkerRadius: _double(map, 'intersectionMarkerRadius'),
);

Map<String, Object?> _encodeCrosshairStyle(CrosshairStyle value) => {
  'lineColor': value.lineColor.toARGB32(),
  'lineWidth': _n(value.lineWidth),
  if (value.dashPattern != null)
    'dashPattern': value.dashPattern!.map(_n).toList(),
  'strokeCap': value.strokeCap.name,
  'labelBackgroundColor': value.labelBackgroundColor.toARGB32(),
  'labelTextColor': value.labelTextColor.toARGB32(),
  'labelPadding': _n(value.labelPadding),
};

CrosshairStyle _decodeCrosshairStyle(Map<String, Object?> map) =>
    CrosshairStyle(
      lineColor: _color(map, 'lineColor'),
      lineWidth: _double(map, 'lineWidth'),
      dashPattern: map['dashPattern'] == null
          ? null
          : _doubleList(map, 'dashPattern'),
      strokeCap: _enum(map, 'strokeCap', StrokeCap.values),
      labelBackgroundColor: _color(map, 'labelBackgroundColor'),
      labelTextColor: _color(map, 'labelTextColor'),
      labelPadding: _double(map, 'labelPadding'),
    );

Map<String, Object?> _encodeTooltip(TooltipConfig value) => {
  'enabled': value.enabled,
  'triggerMode': value.triggerMode.name,
  'preferredPosition': value.preferredPosition.name,
  'showDelayMicros': value.showDelay.inMicroseconds,
  'hideDelayMicros': value.hideDelay.inMicroseconds,
  'followCursor': value.followCursor,
  'offsetFromPoint': _n(value.offsetFromPoint),
  'style': _encodeTooltipStyle(value.style),
};

TooltipConfig _decodeTooltip(
  Map<String, Object?> map, {
  TooltipBuilder? customBuilder,
}) => TooltipConfig(
  enabled: _bool(map, 'enabled'),
  triggerMode: _enum(map, 'triggerMode', TooltipTriggerMode.values),
  preferredPosition: _enum(map, 'preferredPosition', TooltipPosition.values),
  showDelay: Duration(microseconds: _int(map, 'showDelayMicros')),
  hideDelay: Duration(microseconds: _int(map, 'hideDelayMicros')),
  followCursor: _bool(map, 'followCursor'),
  offsetFromPoint: _double(map, 'offsetFromPoint'),
  style: _decodeTooltipStyle(_requiredMap(map, 'style')),
  customBuilder: customBuilder,
);

Map<String, Object?> _encodeTooltipStyle(TooltipStyle value) => {
  'backgroundColor': value.backgroundColor.toARGB32(),
  'borderColor': value.borderColor.toARGB32(),
  'borderWidth': _n(value.borderWidth),
  'borderRadius': _n(value.borderRadius),
  'shadowColor': value.shadowColor.toARGB32(),
  'shadowBlurRadius': _n(value.shadowBlurRadius),
  'padding': _n(value.padding),
  'textColor': value.textColor.toARGB32(),
  'fontSize': _n(value.fontSize),
};

TooltipStyle _decodeTooltipStyle(Map<String, Object?> map) => TooltipStyle(
  backgroundColor: _color(map, 'backgroundColor'),
  borderColor: _color(map, 'borderColor'),
  borderWidth: _double(map, 'borderWidth'),
  borderRadius: _double(map, 'borderRadius'),
  shadowColor: _color(map, 'shadowColor'),
  shadowBlurRadius: _double(map, 'shadowBlurRadius'),
  padding: _double(map, 'padding'),
  textColor: _color(map, 'textColor'),
  fontSize: _double(map, 'fontSize'),
);

Map<String, Object?> _encodeGesture(GestureConfig value) => {
  'tapTimeoutMicros': value.tapTimeout.inMicroseconds,
  'longPressTimeoutMicros': value.longPressTimeout.inMicroseconds,
  'panThreshold': _n(value.panThreshold),
  'pinchThreshold': _n(value.pinchThreshold),
};

GestureConfig _decodeGesture(Map<String, Object?> map) => GestureConfig(
  tapTimeout: Duration(microseconds: _int(map, 'tapTimeoutMicros')),
  longPressTimeout: Duration(microseconds: _int(map, 'longPressTimeoutMicros')),
  panThreshold: _double(map, 'panThreshold'),
  pinchThreshold: _double(map, 'pinchThreshold'),
);

Map<String, Object?> _encodeSelection(ChartSelectionConfig value) => {
  'mode': value.mode.name,
  'operation': value.operation.name,
  'dragActivation': value.dragActivation.name,
  'clearOnBackgroundTap': value.clearOnBackgroundTap,
  'useModifierKeys': value.useModifierKeys,
};

ChartSelectionConfig _decodeSelection(Map<String, Object?> map) =>
    ChartSelectionConfig(
      mode: _enum(map, 'mode', ChartSelectionMode.values),
      operation: _enum(map, 'operation', ChartSelectionOperation.values),
      dragActivation: map['dragActivation'] == null
          ? ChartSelectionDragActivation.primary
          : _enum(map, 'dragActivation', ChartSelectionDragActivation.values),
      clearOnBackgroundTap: _bool(map, 'clearOnBackgroundTap'),
      useModifierKeys: _bool(map, 'useModifierKeys'),
    );

Map<String, Object?> _encodeKeyboard(KeyboardConfig value) => {
  'enabled': value.enabled,
  'panStep': _n(value.panStep),
  'zoomStep': _n(value.zoomStep),
  'enableArrowKeys': value.enableArrowKeys,
  'enablePlusMinusKeys': value.enablePlusMinusKeys,
  'enableHomeEndKeys': value.enableHomeEndKeys,
};

KeyboardConfig _decodeKeyboard(Map<String, Object?> map) => KeyboardConfig(
  enabled: _bool(map, 'enabled'),
  panStep: _double(map, 'panStep'),
  zoomStep: _double(map, 'zoomStep'),
  enableArrowKeys: _bool(map, 'enableArrowKeys'),
  enablePlusMinusKeys: _bool(map, 'enablePlusMinusKeys'),
  enableHomeEndKeys: _bool(map, 'enableHomeEndKeys'),
);

Map<String, Object?> _encodeValueSummary(
  CartesianValueSummaryConfig value,
  Set<String> requiredBindings,
  List<ChartArtifactWarning> warnings,
) => {
  'enabled': value.enabled,
  'valuePolicy': value.valuePolicy.name,
  if (value.valueMode != CartesianValueSummaryValueMode.interpolated)
    'valueMode': value.valueMode.name,
  'presentation': _encodeValueSummaryPresentation(value.presentation),
  'content': _encodeValueSummaryContent(
    value.content,
    requiredBindings,
    warnings,
  ),
  'showSeriesAccent': value.showSeriesAccent,
  'announceChanges': value.announceChanges,
  if (value.style != const CartesianValueSummaryStyle())
    'style': _encodeValueSummaryStyle(value.style),
};

CartesianValueSummaryConfig _decodeValueSummary(
  Map<String, Object?> map, {
  required ChartInteractionDocument document,
  required ChartRuntimeBindings bindings,
  required List<ChartArtifactWarning> warnings,
  required Set<String> describedBindingIds,
}) => CartesianValueSummaryConfig(
  enabled: _bool(map, 'enabled'),
  valuePolicy: _enum(
    map,
    'valuePolicy',
    CartesianValueSummaryValuePolicy.values,
  ),
  // Absent means the default: only non-default modes are encoded.
  valueMode: map['valueMode'] == null
      ? CartesianValueSummaryValueMode.interpolated
      : _enum(map, 'valueMode', CartesianValueSummaryValueMode.values),
  presentation: _decodeValueSummaryPresentation(
    _requiredMap(map, 'presentation'),
  ),
  content: _decodeValueSummaryContent(
    _requiredMap(map, 'content'),
    document: document,
    bindings: bindings,
    warnings: warnings,
    describedBindingIds: describedBindingIds,
  ),
  showSeriesAccent: _bool(map, 'showSeriesAccent'),
  announceChanges: _bool(map, 'announceChanges'),
  style: map['style'] == null
      ? const CartesianValueSummaryStyle()
      : _decodeValueSummaryStyle(_requiredMap(map, 'style')),
);

Map<String, Object?> _encodeValueSummaryPresentation(
  CartesianValueSummaryPresentation value,
) => switch (value) {
  CartesianValueSummaryOverlay(:final placement) => {
    'kind': 'overlay',
    'placement': _encodeOverlayPlacement(placement),
  },
  CartesianValueSummaryAnnotation(
    :final placement,
    :final draggable,
    :final clampToPlot,
  ) =>
    {
      'kind': 'annotation',
      'placement': _encodeOverlayPlacement(placement),
      'draggable': draggable,
      'clampToPlot': clampToPlot,
    },
};

CartesianValueSummaryPresentation _decodeValueSummaryPresentation(
  Map<String, Object?> map,
) {
  final kind = _string(map, 'kind');
  return switch (kind) {
    'overlay' => CartesianValueSummaryOverlay(
      placement: _decodeOverlayPlacement(_requiredMap(map, 'placement')),
    ),
    'annotation' => CartesianValueSummaryAnnotation(
      placement: _decodeOverlayPlacement(_requiredMap(map, 'placement')),
      draggable: _bool(map, 'draggable'),
      clampToPlot: _bool(map, 'clampToPlot'),
    ),
    _ => throw FormatException(
      'Unknown value summary presentation kind "$kind".',
    ),
  };
}

Map<String, Object?> _encodeOverlayPlacement(ChartOverlayPlacement value) => {
  'anchor': {'x': _n(value.anchor.x), 'y': _n(value.anchor.y)},
  'offset': {'dx': _n(value.offset.dx), 'dy': _n(value.offset.dy)},
};

ChartOverlayPlacement _decodeOverlayPlacement(Map<String, Object?> map) {
  final anchor = _requiredMap(map, 'anchor');
  final offset = _requiredMap(map, 'offset');
  return ChartOverlayPlacement(
    anchor: Alignment(_double(anchor, 'x'), _double(anchor, 'y')),
    offset: Offset(_double(offset, 'dx'), _double(offset, 'dy')),
  );
}

Map<String, Object?> _encodeValueSummaryContent(
  CartesianValueSummaryContent value,
  Set<String> requiredBindings,
  List<ChartArtifactWarning> warnings,
) {
  switch (value) {
    case CartesianValueSummaryAutomaticContent(
      :final includeTrends,
      :final includeHiddenSeries,
    ):
      return {
        'kind': 'automatic',
        'includeTrends': includeTrends,
        'includeHiddenSeries': includeHiddenSeries,
      };
    case CartesianValueSummaryBuilderContent(:final descriptorId):
      if (descriptorId == null) {
        warnings.add(
          const ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Value summary builder content has no descriptorId; the '
                'runtime builder is an omitted dependency and automatic '
                'content was encoded instead.',
            path: r'$.interaction.configuration.valueSummary.content',
          ),
        );
        return const {
          'kind': 'automatic',
          'includeTrends': false,
          'includeHiddenSeries': false,
        };
      }
      requiredBindings.add(descriptorId);
      return {'kind': 'builder', 'descriptorId': descriptorId};
  }
}

CartesianValueSummaryContent _decodeValueSummaryContent(
  Map<String, Object?> map, {
  required ChartInteractionDocument document,
  required ChartRuntimeBindings bindings,
  required List<ChartArtifactWarning> warnings,
  required Set<String> describedBindingIds,
}) {
  final kind = _string(map, 'kind');
  switch (kind) {
    case 'automatic':
      return CartesianValueSummaryAutomaticContent(
        includeTrends: _bool(map, 'includeTrends'),
        includeHiddenSeries: _bool(map, 'includeHiddenSeries'),
      );
    case 'builder':
      final id = _string(map, 'descriptorId');
      if (!document.requiredBindings.contains(id)) {
        throw FormatException(
          'Value summary content descriptor must declare $id in '
          'requiredBindings.',
        );
      }
      describedBindingIds.add(id);
      final builder = bindings.callbacks
          .resolve<CartesianValueSummaryRowBuilder>(id);
      if (builder == null) {
        warnings.add(
          ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Optional value summary content binding "$id" is unavailable; '
                'automatic content is active.',
            path: r'$.interaction.configuration.valueSummary.content',
          ),
        );
        return const CartesianValueSummaryContent.automatic();
      }
      return CartesianValueSummaryContent.builder(builder, descriptorId: id);
    default:
      throw FormatException('Unknown value summary content kind "$kind".');
  }
}

Map<String, Object?> _encodeValueSummaryStyle(
  CartesianValueSummaryStyle value,
) => {
  ..._styleEntry('backgroundColor', value.backgroundColor, _colorJson),
  ..._styleEntry('backgroundOpacity', value.backgroundOpacity, _n),
  ..._styleEntry('borderColor', value.borderColor, _colorJson),
  ..._styleEntry('borderWidth', value.borderWidth, _n),
  ..._styleEntry('borderRadius', value.borderRadius, _borderRadiusJson),
  ..._styleEntry('padding', value.padding, _insetsJson),
  ..._styleEntry('textStyle', value.textStyle, _textStyleJson),
  ..._styleEntry('labelStyle', value.labelStyle, _textStyleJson),
  ..._styleEntry('accentColor', value.accentColor, _colorJson),
  ..._styleEntry('shadow', value.shadow, _boxShadowJson),
  ..._styleEntry('minWidth', value.minWidth, _n),
  ..._styleEntry('maxWidth', value.maxWidth, _n),
  ..._styleEntry('rowGap', value.rowGap, _n),
  ..._styleEntry('labelValueGap', value.labelValueGap, _n),
};

CartesianValueSummaryStyle _decodeValueSummaryStyle(
  Map<String, Object?> map,
) => CartesianValueSummaryStyle(
  backgroundColor: _styleValue(map, 'backgroundColor', _colorPayload),
  backgroundOpacity: _styleValue(map, 'backgroundOpacity', _doublePayload),
  borderColor: _styleValue(map, 'borderColor', _colorPayload),
  borderWidth: _styleValue(map, 'borderWidth', _doublePayload),
  borderRadius: _styleValue(map, 'borderRadius', _borderRadiusPayload),
  padding: _styleValue(map, 'padding', _insetsPayload),
  textStyle: _styleValue(map, 'textStyle', _textStylePayload),
  labelStyle: _styleValue(map, 'labelStyle', _textStylePayload),
  accentColor: _styleValue(map, 'accentColor', _colorPayload),
  shadow: _styleValue(map, 'shadow', _boxShadowPayload),
  minWidth: _styleValue(map, 'minWidth', _doublePayload),
  maxWidth: _styleValue(map, 'maxWidth', _doublePayload),
  rowGap: _styleValue(map, 'rowGap', _doublePayload),
  labelValueGap: _styleValue(map, 'labelValueGap', _doublePayload),
);

/// Tri-state artifact form: an absent key is [ChartStyleValue.inherit], the
/// explicit `"none"` token is [ChartStyleValue.none], anything else is the
/// typed payload of [ChartStyleValue.value].
Map<String, Object?> _styleEntry<T>(
  String key,
  ChartStyleValue<T> value,
  Object Function(T payload) encodePayload,
) => switch (value) {
  ChartStyleInherit<T>() => const {},
  ChartStyleNone<T>() => {key: 'none'},
  ChartStyleExplicit<T>(:final value) => {key: encodePayload(value)},
};

ChartStyleValue<T> _styleValue<T>(
  Map<String, Object?> map,
  String key,
  T Function(Object? raw) decodePayload,
) {
  final raw = map[key];
  if (raw == null) return ChartStyleValue<T>.inherit();
  if (raw == 'none') return ChartStyleValue<T>.none();
  return ChartStyleValue<T>.value(decodePayload(raw));
}

Object _colorJson(Color value) => value.toARGB32();

Color _colorPayload(Object? value) {
  if (value is int) return Color(value);
  throw const FormatException('Expected ARGB color integer style value.');
}

double _doublePayload(Object? value) =>
    ChartNumberDocument.fromJson(value).asDouble;

Object _textStyleJson(TextStyle value) =>
    ChartStyleDocumentCodec.encodeTextStyle(value).toJson();

TextStyle _textStylePayload(Object? value) =>
    ChartStyleDocumentCodec.decodeTextStyle(_object(_asMap(value)));

Object _insetsJson(EdgeInsets value) => {
  'left': _n(value.left),
  'top': _n(value.top),
  'right': _n(value.right),
  'bottom': _n(value.bottom),
};

EdgeInsets _insetsPayload(Object? value) {
  final map = _asMap(value);
  return EdgeInsets.fromLTRB(
    _double(map, 'left'),
    _double(map, 'top'),
    _double(map, 'right'),
    _double(map, 'bottom'),
  );
}

Object _borderRadiusJson(BorderRadius value) => {
  'topLeft': _radiusJson(value.topLeft),
  'topRight': _radiusJson(value.topRight),
  'bottomLeft': _radiusJson(value.bottomLeft),
  'bottomRight': _radiusJson(value.bottomRight),
};

BorderRadius _borderRadiusPayload(Object? value) {
  final map = _asMap(value);
  return BorderRadius.only(
    topLeft: _radiusPayload(_requiredMap(map, 'topLeft')),
    topRight: _radiusPayload(_requiredMap(map, 'topRight')),
    bottomLeft: _radiusPayload(_requiredMap(map, 'bottomLeft')),
    bottomRight: _radiusPayload(_requiredMap(map, 'bottomRight')),
  );
}

Map<String, Object?> _radiusJson(Radius value) => {
  'x': _n(value.x),
  'y': _n(value.y),
};

Radius _radiusPayload(Map<String, Object?> map) =>
    Radius.elliptical(_double(map, 'x'), _double(map, 'y'));

Object _boxShadowJson(BoxShadow value) => {
  'color': value.color.toARGB32(),
  'offset': {'dx': _n(value.offset.dx), 'dy': _n(value.offset.dy)},
  'blurRadius': _n(value.blurRadius),
  'spreadRadius': _n(value.spreadRadius),
  'blurStyle': value.blurStyle.name,
};

BoxShadow _boxShadowPayload(Object? value) {
  final map = _asMap(value);
  final offset = _requiredMap(map, 'offset');
  return BoxShadow(
    color: _color(map, 'color'),
    offset: Offset(_double(offset, 'dx'), _double(offset, 'dy')),
    blurRadius: _double(map, 'blurRadius'),
    spreadRadius: _double(map, 'spreadRadius'),
    blurStyle: _enum(map, 'blurStyle', BlurStyle.values),
  );
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw const FormatException('Expected object style value.');
}

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

List<double> _doubleList(Map<String, Object?> map, String key) => _list(
  map,
  key,
).map((value) => ChartNumberDocument.fromJson(value).asDouble).toList();

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected non-empty string at $key.');
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
    ChartNumberDocument.fromJson(map[key]).asDouble;

Color _color(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return Color(value);
  throw FormatException('Expected ARGB color integer at $key.');
}

T _enum<T extends Enum>(Map<String, Object?> map, String key, List<T> values) {
  final name = _string(map, key);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Unknown enum value "$name" at $key.');
}

ChartArtifactFailure<T> _invalidFailure<T>(Object error) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid interaction configuration: $error',
        path: r'$.interaction.configuration',
      ),
    );

class _BindingException implements Exception {
  const _BindingException(this.message, this.path);

  final String message;
  final String path;
}
