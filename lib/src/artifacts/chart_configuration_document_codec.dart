import 'package:flutter/material.dart';

import '../models/grid_config.dart';
import '../models/concentric_donut_config.dart';
import '../models/donut_chart_config.dart';
import '../models/gauge_chart_config.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import '../models/pie_chart_config.dart';
import '../models/polar_chart_config.dart';
import '../models/radial_bar_chart_config.dart';
import '../models/radar_chart_config.dart';
import '../models/series_callout_config.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_configuration_documents.dart';
import 'chart_data_payload.dart';
import 'chart_style_document_codec.dart';
import 'donut_center_content_document_codec.dart';
import 'json_value.dart';

typedef ChartLegendConfiguration = ({bool visible, LegendStyle style});

/// Audited adapters for portable chart-level built-in configuration models.
abstract final class ChartConfigurationDocumentCodec {
  /// Encodes the chart-level collision-aware series callout policy.
  static ChartArtifactResult<JsonObjectValue> encodeSeriesCallouts(
    SeriesCalloutConfig config,
  ) {
    const path = r'$.configuration.seriesCallouts';
    try {
      return ChartArtifactSuccess(
        value: JsonObjectValue({
          'seriesCallouts': JsonValue.fromJson({
            'enabled': config.enabled,
            'showByDefault': config.showByDefault,
            'side': config.side.name,
            'lanePlacement': config.lanePlacement.name,
            'anchor': config.anchor.name,
            if (config.anchorX != null) 'anchorX': config.anchorX,
            'connector': config.connector.name,
            'packing': config.packing.name,
            'laneWidth': config.laneWidth,
            'inset': config.inset,
            'minimumGap': config.minimumGap,
            'maximumVisible': config.maximumVisible,
            'collisionFadeDurationMicros':
                config.collisionFadeDuration.inMicroseconds,
            if (config.connectorColor != null)
              'connectorColor': config.connectorColor!.toARGB32(),
            'connectorWidth': config.connectorWidth,
            'connectorOpacity': config.connectorOpacity,
            'connectorGlow': config.connectorGlow,
            'anchorRadius': config.anchorRadius,
            'labelPadding': {
              'left': config.labelPadding.left,
              'top': config.labelPadding.top,
              'right': config.labelPadding.right,
              'bottom': config.labelPadding.bottom,
            },
            'labelStyle': ChartStyleDocumentCodec.encodeTextStyle(
              config.labelStyle,
            ).toJson(),
            if (config.backgroundColor != null)
              'backgroundColor': config.backgroundColor!.toARGB32(),
            'backgroundOpacity': config.backgroundOpacity,
            if (config.borderColor != null)
              'borderColor': config.borderColor!.toARGB32(),
            'borderWidth': config.borderWidth,
            'borderRadius': config.borderRadius,
            if (config.panelBackgroundColor != null)
              'panelBackgroundColor': config.panelBackgroundColor!.toARGB32(),
            'panelOpacity': config.panelOpacity,
            if (config.panelBorderColor != null)
              'panelBorderColor': config.panelBorderColor!.toARGB32(),
            'panelBorderWidth': config.panelBorderWidth,
            'panelBorderRadius': config.panelBorderRadius,
            'panelPadding': {
              'left': config.panelPadding.left,
              'top': config.panelPadding.top,
              'right': config.panelPadding.right,
              'bottom': config.panelPadding.bottom,
            },
            'series': {
              for (final entry in config.series.entries)
                entry.key: _encodeSeriesCalloutSpec(entry.value),
            },
          }, path: path),
        }),
      );
    } on Object catch (error) {
      return _seriesCalloutConfigurationFailure(error, path);
    }
  }

  static Map<String, Object?> _encodeSeriesCalloutSpec(
    SeriesCalloutSpec spec,
  ) => {
    if (spec.show != null) 'show': spec.show,
    if (spec.label != null) 'label': spec.label,
    if (spec.anchor != null) 'anchor': spec.anchor!.name,
    if (spec.anchorX != null) 'anchorX': spec.anchorX,
    'priority': spec.priority,
    if (spec.color != null) 'color': spec.color!.toARGB32(),
    if (spec.textStyle != null)
      'textStyle': ChartStyleDocumentCodec.encodeTextStyle(
        spec.textStyle!,
      ).toJson(),
    if (spec.backgroundColor != null)
      'backgroundColor': spec.backgroundColor!.toARGB32(),
    if (spec.borderColor != null) 'borderColor': spec.borderColor!.toARGB32(),
    if (spec.connectorWidth != null) 'connectorWidth': spec.connectorWidth,
    if (spec.connectorOpacity != null)
      'connectorOpacity': spec.connectorOpacity,
    if (spec.connectorGlow != null) 'connectorGlow': spec.connectorGlow,
    if (spec.backgroundOpacity != null)
      'backgroundOpacity': spec.backgroundOpacity,
    if (spec.borderWidth != null) 'borderWidth': spec.borderWidth,
    if (spec.borderRadius != null) 'borderRadius': spec.borderRadius,
  };

  /// Decodes the optional chart-level series callout policy.
  static ChartArtifactResult<SeriesCalloutConfig> decodeSeriesCallouts(
    JsonObjectValue configuration,
  ) {
    const path = r'$.configuration.seriesCallouts';
    final raw = configuration.values['seriesCallouts'];
    if (raw == null) {
      return ChartArtifactSuccess(value: const SeriesCalloutConfig());
    }
    if (raw is! JsonObjectValue) {
      return _seriesCalloutConfigurationFailure(
        'Series callout configuration must be an object.',
        path,
      );
    }
    try {
      final map = raw.toJson() as Map<String, Object?>;
      final padding = _requiredMap(map, 'labelPadding', path);
      final panelPadding = map['panelPadding'] == null
          ? null
          : _requiredMap(map, 'panelPadding', path);
      final seriesMap = _requiredMap(map, 'series', path);
      final series = <String, SeriesCalloutSpec>{};
      for (final entry in seriesMap.entries) {
        if (entry.value is! Map) {
          throw _ConfigurationFormatException(
            'Series override must be an object.',
            '$path.series.${entry.key}',
          );
        }
        final spec = (entry.value as Map).cast<String, Object?>();
        series[entry.key] = SeriesCalloutSpec(
          show: spec['show'] as bool?,
          label: spec['label'] as String?,
          anchor: _optionalEnum(
            spec,
            'anchor',
            SeriesCalloutAnchor.values,
            '$path.series.${entry.key}',
          ),
          anchorX: _optionalDouble(
            spec,
            'anchorX',
            '$path.series.${entry.key}',
          ),
          priority: _requiredInt(spec, 'priority', '$path.series.${entry.key}'),
          color: _optionalConfigurationColor(spec['color']),
          textStyle: spec['textStyle'] == null
              ? null
              : ChartStyleDocumentCodec.decodeTextStyle(
                  JsonValue.fromJson(spec['textStyle']) as JsonObjectValue,
                ),
          backgroundColor: _optionalConfigurationColor(spec['backgroundColor']),
          borderColor: _optionalConfigurationColor(spec['borderColor']),
          connectorWidth: _optionalDouble(
            spec,
            'connectorWidth',
            '$path.series.${entry.key}',
          ),
          connectorOpacity: _optionalDouble(
            spec,
            'connectorOpacity',
            '$path.series.${entry.key}',
          ),
          connectorGlow: _optionalDouble(
            spec,
            'connectorGlow',
            '$path.series.${entry.key}',
          ),
          backgroundOpacity: _optionalDouble(
            spec,
            'backgroundOpacity',
            '$path.series.${entry.key}',
          ),
          borderWidth: _optionalDouble(
            spec,
            'borderWidth',
            '$path.series.${entry.key}',
          ),
          borderRadius: _optionalDouble(
            spec,
            'borderRadius',
            '$path.series.${entry.key}',
          ),
        );
      }
      return ChartArtifactSuccess(
        value: SeriesCalloutConfig(
          enabled: _requiredBool(map, 'enabled', path),
          showByDefault: _requiredBool(map, 'showByDefault', path),
          side: _requiredEnum(map, 'side', SeriesCalloutSide.values, path),
          lanePlacement:
              _optionalEnum(
                map,
                'lanePlacement',
                SeriesCalloutLanePlacement.values,
                path,
              ) ??
              SeriesCalloutLanePlacement.plotEdge,
          anchor: _requiredEnum(
            map,
            'anchor',
            SeriesCalloutAnchor.values,
            path,
          ),
          anchorX: _optionalDouble(map, 'anchorX', path),
          connector: _requiredEnum(
            map,
            'connector',
            SeriesCalloutConnector.values,
            path,
          ),
          packing:
              _optionalEnum(
                map,
                'packing',
                SeriesCalloutPacking.values,
                path,
              ) ??
              SeriesCalloutPacking.followAnchors,
          laneWidth: _requiredDouble(map, 'laneWidth', path),
          inset: _requiredDouble(map, 'inset', path),
          minimumGap: _requiredDouble(map, 'minimumGap', path),
          maximumVisible: _requiredInt(map, 'maximumVisible', path),
          collisionFadeDuration: Duration(
            microseconds:
                _optionalInt(map, 'collisionFadeDurationMicros', path) ??
                const Duration(milliseconds: 180).inMicroseconds,
          ),
          connectorColor: _optionalConfigurationColor(map['connectorColor']),
          connectorWidth: _requiredDouble(map, 'connectorWidth', path),
          connectorOpacity: _requiredDouble(map, 'connectorOpacity', path),
          connectorGlow: _optionalDouble(map, 'connectorGlow', path) ?? 0,
          anchorRadius: _requiredDouble(map, 'anchorRadius', path),
          labelPadding: EdgeInsets.fromLTRB(
            _requiredDouble(padding, 'left', '$path.labelPadding'),
            _requiredDouble(padding, 'top', '$path.labelPadding'),
            _requiredDouble(padding, 'right', '$path.labelPadding'),
            _requiredDouble(padding, 'bottom', '$path.labelPadding'),
          ),
          labelStyle: ChartStyleDocumentCodec.decodeTextStyle(
            JsonValue.fromJson(map['labelStyle']) as JsonObjectValue,
          ),
          backgroundColor: _optionalConfigurationColor(map['backgroundColor']),
          backgroundOpacity: _requiredDouble(map, 'backgroundOpacity', path),
          borderColor: _optionalConfigurationColor(map['borderColor']),
          borderWidth: _requiredDouble(map, 'borderWidth', path),
          borderRadius: _requiredDouble(map, 'borderRadius', path),
          panelBackgroundColor: _optionalConfigurationColor(
            map['panelBackgroundColor'],
          ),
          panelOpacity: _requiredDouble(map, 'panelOpacity', path),
          panelBorderColor: _optionalConfigurationColor(
            map['panelBorderColor'],
          ),
          panelBorderWidth: _requiredDouble(map, 'panelBorderWidth', path),
          panelBorderRadius: _requiredDouble(map, 'panelBorderRadius', path),
          panelPadding: panelPadding == null
              ? const EdgeInsets.all(6)
              : EdgeInsets.fromLTRB(
                  _requiredDouble(panelPadding, 'left', '$path.panelPadding'),
                  _requiredDouble(panelPadding, 'top', '$path.panelPadding'),
                  _requiredDouble(panelPadding, 'right', '$path.panelPadding'),
                  _requiredDouble(panelPadding, 'bottom', '$path.panelPadding'),
                ),
          series: series,
        ),
      );
    } on Object catch (error) {
      return _seriesCalloutConfigurationFailure(error, path);
    }
  }

  static ChartGridDocument encodeGrid(GridConfig config) => ChartGridDocument(
    horizontal: config.horizontal,
    vertical: config.vertical,
    horizontalColor: config.horizontalColor?.toARGB32(),
    verticalColor: config.verticalColor?.toARGB32(),
    horizontalStrokeWidth: ChartNumberDocument.fromDouble(
      config.horizontalStrokeWidth,
    ),
    verticalStrokeWidth: ChartNumberDocument.fromDouble(
      config.verticalStrokeWidth,
    ),
  );

  static ChartArtifactResult<GridConfig> decodeGrid(
    ChartGridDocument document,
  ) {
    try {
      return ChartArtifactSuccess(
        value: GridConfig(
          horizontal: document.horizontal,
          vertical: document.vertical,
          horizontalColor: _optionalColor(document.horizontalColor),
          verticalColor: _optionalColor(document.verticalColor),
          horizontalStrokeWidth: document.horizontalStrokeWidth.asDouble,
          verticalStrokeWidth: document.verticalStrokeWidth.asDouble,
        ),
      );
    } on Object catch (error) {
      return _invalidFailure(error, r'$.grid');
    }
  }

  static ChartArtifactResult<ChartLegendDocument> encodeLegend({
    required bool visible,
    required LegendStyle style,
  }) {
    try {
      return ChartArtifactSuccess(
        value: ChartLegendDocument(
          visible: visible,
          style: ChartStyleDocumentCodec.encodeLegendStyle(style),
        ),
      );
    } on UnsupportedError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedModelType,
          message: error.message?.toString() ?? 'Unsupported legend style.',
          path: r'$.legend.style.textStyle',
        ),
      );
    } on Object catch (error) {
      return _invalidFailure(error, r'$.legend');
    }
  }

  static ChartArtifactResult<ChartLegendConfiguration> decodeLegend(
    ChartLegendDocument document,
  ) {
    try {
      return ChartArtifactSuccess(
        value: (
          visible: document.visible,
          style: document.style.values.isEmpty
              ? const LegendStyle()
              : ChartStyleDocumentCodec.decodeLegendStyle(document.style),
        ),
      );
    } on Object catch (error) {
      return _invalidFailure(error, r'$.legend');
    }
  }

  static ChartNormalizationDocument encodeNormalization(
    NormalizationMode mode, {
    double autoRangeRatioThreshold = 10,
  }) => ChartNormalizationDocument(
    mode: mode.name,
    autoRangeRatioThreshold: ChartNumberDocument.fromDouble(
      autoRangeRatioThreshold,
    ),
  );

  static ChartArtifactResult<NormalizationMode> decodeNormalization(
    ChartNormalizationDocument document,
  ) {
    try {
      if (!document.autoRangeRatioThreshold.asDouble.isFinite ||
          document.autoRangeRatioThreshold.asDouble <= 0) {
        throw const FormatException(
          'Normalization ratio threshold must be positive and finite.',
        );
      }
      for (final mode in NormalizationMode.values) {
        if (mode.name == document.mode) {
          return ChartArtifactSuccess(value: mode);
        }
      }
      throw FormatException('Unknown normalization mode "${document.mode}".');
    } on Object catch (error) {
      return _invalidFailure(error, r'$.normalization');
    }
  }

  /// Encodes the plot-level Concentric Donut composition.
  static ChartArtifactResult<JsonObjectValue> encodeConcentricDonut(
    ConcentricDonutConfig config, {
    JsonObjectValue? centerFormatterDescriptor,
  }) {
    const path = r'$.configuration.concentricDonut';
    try {
      _validateConcentricConfig(config, path);
      if (config.centerContent.valueFormatter != null &&
          centerFormatterDescriptor == null) {
        return ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.runtimeBindingRequired,
            message:
                'Concentric Donut center formatters must be represented by a runtime binding descriptor.',
            path:
                r'$.configuration.concentricDonut.centerContent.valueFormatter',
          ),
        );
      }
      return ChartArtifactSuccess(
        value: JsonObjectValue({
          'concentricDonut': JsonValue.fromJson({
            'innerRadiusFactor': config.innerRadiusFactor,
            'outerRadiusFactor': config.outerRadiusFactor,
            'ringGap': config.ringGap,
            'order': config.order.name,
            'ringWeights': config.ringWeights,
            'legendMode': config.legendMode.name,
            'centerContent': DonutCenterContentDocumentCodec.encode(
              config.centerContent,
              valueFormatter: centerFormatterDescriptor,
            ),
          }, path: path),
        }),
      );
    } on _ConfigurationFormatException catch (error) {
      return _configurationFailure(error.message, error.path);
    } on Object catch (error) {
      return _configurationFailure(error, path);
    }
  }

  /// Decodes an optional plot-level Concentric Donut composition.
  static ChartArtifactResult<ConcentricDonutConfig?> decodeConcentricDonut(
    JsonObjectValue configuration, {
    RadialValueFormatter? centerFormatter,
  }) {
    const path = r'$.configuration.concentricDonut';
    final raw = configuration.values['concentricDonut'];
    if (raw == null) {
      return ChartArtifactSuccess<ConcentricDonutConfig?>(value: null);
    }
    if (raw is! JsonObjectValue) {
      return _configurationFailure(
        'Concentric Donut configuration must be an object.',
        path,
      );
    }
    try {
      final map = raw.toJson() as Map<String, Object?>;
      final weights = _stringDoubleMap(map['ringWeights'], '$path.ringWeights');
      final config = ConcentricDonutConfig(
        innerRadiusFactor: _requiredDouble(map, 'innerRadiusFactor', path),
        outerRadiusFactor: _requiredDouble(map, 'outerRadiusFactor', path),
        ringGap: _requiredDouble(map, 'ringGap', path),
        order: _requiredEnum(map, 'order', ConcentricRingOrder.values, path),
        ringWeights: weights,
        legendMode: _requiredEnum(
          map,
          'legendMode',
          ConcentricDonutLegendMode.values,
          path,
        ),
        centerContent: DonutCenterContentDocumentCodec.decode(
          _requiredMap(map, 'centerContent', path),
          valueFormatter: centerFormatter,
          path: '$path.centerContent',
        ),
      );
      _validateConcentricConfig(config, path);
      return ChartArtifactSuccess(value: config);
    } on _ConfigurationFormatException catch (error) {
      return _configurationFailure(error.message, error.path);
    } on Object catch (error) {
      return _configurationFailure(error, path);
    }
  }

  /// Encodes the pane and both axes shared by axis-based polar series.
  static ChartArtifactResult<JsonObjectValue> encodePolarChart(
    PolarChartConfig config,
  ) {
    const path = r'$.configuration.polarChart';
    try {
      config.validate();
      return ChartArtifactSuccess(
        value: JsonObjectValue({
          'polarChart': JsonValue.fromJson({
            'pane': {
              'startAngleDegrees': config.pane.startAngleDegrees,
              'sweepAngleDegrees': config.pane.sweepAngleDegrees,
              'clockwise': config.pane.clockwise,
              'innerRadiusFactor': config.pane.innerRadiusFactor,
              'outerRadiusFactor': config.pane.outerRadiusFactor,
              'clipMarks': config.pane.clipMarks,
            },
            'angularAxis': {
              'innerPadding': config.angularAxis.innerPadding,
              'outerPadding': config.angularAxis.outerPadding,
              'showLabels': config.angularAxis.showLabels,
              'showGridLines': config.angularAxis.showGridLines,
              'maximumVisibleLabels': config.angularAxis.maximumVisibleLabels,
              'maximumVisibleGridLines':
                  config.angularAxis.maximumVisibleGridLines,
              'labelOffset': config.angularAxis.labelOffset,
              'labelStyle': _encodePolarLabelStyle(
                config.angularAxis.labelStyle,
              ),
            },
            'radialAxis': {
              if (config.radialAxis.minimum != null)
                'minimum': config.radialAxis.minimum,
              if (config.radialAxis.maximum != null)
                'maximum': config.radialAxis.maximum,
              if (config.radialAxis.scaleMode != null)
                'scaleMode': config.radialAxis.scaleMode!.name,
              'tickCount': config.radialAxis.tickCount,
              'showLabels': config.radialAxis.showLabels,
              'showGridLines': config.radialAxis.showGridLines,
              'labelPosition': config.radialAxis.labelPosition.name,
              'labelAngleOffsetDegrees':
                  config.radialAxis.labelAngleOffsetDegrees,
              'labelOffset': config.radialAxis.labelOffset,
              'labelStyle': _encodePolarLabelStyle(
                config.radialAxis.labelStyle,
              ),
            },
            'composition': {
              'mode': config.composition.mode.name,
              'groupInnerPadding': config.composition.groupInnerPadding,
            },
            'thresholds': [
              for (final threshold in config.thresholds)
                {
                  'value': threshold.value,
                  if (threshold.label != null) 'label': threshold.label,
                  if (threshold.color != null)
                    'color': threshold.color!.toARGB32(),
                  'width': threshold.width,
                  'dashPattern': threshold.dashPattern,
                },
            ],
          }, path: path),
        }),
      );
    } on Object catch (error) {
      return _polarConfigurationFailure(error, path);
    }
  }

  /// Decodes an optional axis-based polar plot configuration.
  static ChartArtifactResult<PolarChartConfig?> decodePolarChart(
    JsonObjectValue configuration,
  ) {
    const path = r'$.configuration.polarChart';
    final raw = configuration.values['polarChart'];
    if (raw == null) {
      return ChartArtifactSuccess<PolarChartConfig?>(value: null);
    }
    if (raw is! JsonObjectValue) {
      return _polarConfigurationFailure(
        'Polar chart configuration must be an object.',
        path,
      );
    }
    try {
      final map = raw.toJson() as Map<String, Object?>;
      final pane = _requiredMap(map, 'pane', path);
      final angular = _requiredMap(map, 'angularAxis', path);
      final radial = _requiredMap(map, 'radialAxis', path);
      final composition = switch (map['composition']) {
        null => null,
        final Map value => value.cast<String, Object?>(),
        _ => throw const _ConfigurationFormatException(
          'Optional object field "composition" is invalid.',
          '$path.composition',
        ),
      };
      final config = PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: _requiredDouble(
            pane,
            'startAngleDegrees',
            '$path.pane',
          ),
          sweepAngleDegrees: _requiredDouble(
            pane,
            'sweepAngleDegrees',
            '$path.pane',
          ),
          clockwise: _requiredBool(pane, 'clockwise', '$path.pane'),
          innerRadiusFactor: _requiredDouble(
            pane,
            'innerRadiusFactor',
            '$path.pane',
          ),
          outerRadiusFactor: _requiredDouble(
            pane,
            'outerRadiusFactor',
            '$path.pane',
          ),
          clipMarks: _requiredBool(pane, 'clipMarks', '$path.pane'),
        ),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: _requiredDouble(
            angular,
            'innerPadding',
            '$path.angularAxis',
          ),
          outerPadding: _requiredDouble(
            angular,
            'outerPadding',
            '$path.angularAxis',
          ),
          showLabels: _requiredBool(angular, 'showLabels', '$path.angularAxis'),
          showGridLines: _requiredBool(
            angular,
            'showGridLines',
            '$path.angularAxis',
          ),
          maximumVisibleLabels:
              _optionalInt(
                angular,
                'maximumVisibleLabels',
                '$path.angularAxis',
              ) ??
              24,
          maximumVisibleGridLines:
              _optionalInt(
                angular,
                'maximumVisibleGridLines',
                '$path.angularAxis',
              ) ??
              72,
          labelOffset:
              _optionalDouble(angular, 'labelOffset', '$path.angularAxis') ?? 0,
          labelStyle: _decodePolarLabelStyle(
            angular['labelStyle'],
            '$path.angularAxis.labelStyle',
          ),
        ),
        radialAxis: PolarNumericAxisConfig(
          minimum: _optionalDouble(radial, 'minimum', '$path.radialAxis'),
          maximum: _optionalDouble(radial, 'maximum', '$path.radialAxis'),
          scaleMode: _optionalEnum(
            radial,
            'scaleMode',
            PolarRadialScaleMode.values,
            '$path.radialAxis',
          ),
          tickCount: _requiredInt(radial, 'tickCount', '$path.radialAxis'),
          showLabels: _requiredBool(radial, 'showLabels', '$path.radialAxis'),
          showGridLines: _requiredBool(
            radial,
            'showGridLines',
            '$path.radialAxis',
          ),
          labelPosition:
              _optionalEnum(
                radial,
                'labelPosition',
                PolarRadialLabelPosition.values,
                '$path.radialAxis',
              ) ??
              PolarRadialLabelPosition.start,
          labelAngleOffsetDegrees:
              _optionalDouble(
                radial,
                'labelAngleOffsetDegrees',
                '$path.radialAxis',
              ) ??
              0,
          labelOffset:
              _optionalDouble(radial, 'labelOffset', '$path.radialAxis') ?? 4,
          labelStyle: _decodePolarLabelStyle(
            radial['labelStyle'],
            '$path.radialAxis.labelStyle',
            defaults: const PolarLabelStyle(fontSize: 10),
          ),
        ),
        composition: composition == null
            ? const PolarColumnCompositionConfig()
            : PolarColumnCompositionConfig(
                mode: _requiredEnum(
                  composition,
                  'mode',
                  PolarColumnCompositionMode.values,
                  '$path.composition',
                ),
                groupInnerPadding: _requiredDouble(
                  composition,
                  'groupInnerPadding',
                  '$path.composition',
                ),
              ),
        thresholds: _decodePolarThresholds(map['thresholds'], path),
      );
      config.validate();
      return ChartArtifactSuccess(value: config);
    } on _ConfigurationFormatException catch (error) {
      return _polarConfigurationFailure(error.message, error.path);
    } on Object catch (error) {
      return _polarConfigurationFailure(error, path);
    }
  }

  /// Encodes the pane and category/numeric axes used by Radar charts.
  static ChartArtifactResult<JsonObjectValue> encodeRadarChart(
    RadarChartConfig config,
  ) {
    const path = r'$.configuration.radarChart';
    try {
      config.validate();
      return ChartArtifactSuccess(
        value: JsonObjectValue({
          'radarChart': JsonValue.fromJson({
            'pane': {
              'startAngleDegrees': config.pane.startAngleDegrees,
              'sweepAngleDegrees': config.pane.sweepAngleDegrees,
              'clockwise': config.pane.clockwise,
              'innerRadiusFactor': config.pane.innerRadiusFactor,
              'outerRadiusFactor': config.pane.outerRadiusFactor,
              'clipMarks': config.pane.clipMarks,
            },
            'categoryAxis': {
              'showLabels': config.categoryAxis.showLabels,
              'showSpokes': config.categoryAxis.showSpokes,
              'maximumVisibleLabels': config.categoryAxis.maximumVisibleLabels,
              'labelOffset': config.categoryAxis.labelOffset,
              'labelStyle': _encodePolarLabelStyle(
                config.categoryAxis.labelStyle,
              ),
            },
            'radialAxis': {
              'minimum': config.radialAxis.minimum,
              if (config.radialAxis.maximum != null)
                'maximum': config.radialAxis.maximum,
              'tickCount': config.radialAxis.tickCount,
              'showLabels': config.radialAxis.showLabels,
              'showGridLines': config.radialAxis.showGridLines,
              'gridShape': config.radialAxis.gridShape.name,
              'labelPosition': config.radialAxis.labelPosition.name,
              'labelAngleOffsetDegrees':
                  config.radialAxis.labelAngleOffsetDegrees,
              'labelOffset': config.radialAxis.labelOffset,
              'labelStyle': _encodePolarLabelStyle(
                config.radialAxis.labelStyle,
              ),
            },
          }, path: path),
        }),
      );
    } on Object catch (error) {
      return _polarConfigurationFailure(error, path);
    }
  }

  /// Decodes an optional Radar plot configuration.
  static ChartArtifactResult<RadarChartConfig?> decodeRadarChart(
    JsonObjectValue configuration,
  ) {
    const path = r'$.configuration.radarChart';
    final raw = configuration.values['radarChart'];
    if (raw == null) {
      return ChartArtifactSuccess<RadarChartConfig?>(value: null);
    }
    if (raw is! JsonObjectValue) {
      return _polarConfigurationFailure(
        'Radar chart configuration must be an object.',
        path,
      );
    }
    try {
      final map = raw.toJson() as Map<String, Object?>;
      final pane = _requiredMap(map, 'pane', path);
      final category = _requiredMap(map, 'categoryAxis', path);
      final radial = _requiredMap(map, 'radialAxis', path);
      final config = RadarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: _requiredDouble(
            pane,
            'startAngleDegrees',
            '$path.pane',
          ),
          sweepAngleDegrees: _requiredDouble(
            pane,
            'sweepAngleDegrees',
            '$path.pane',
          ),
          clockwise: _requiredBool(pane, 'clockwise', '$path.pane'),
          innerRadiusFactor: _requiredDouble(
            pane,
            'innerRadiusFactor',
            '$path.pane',
          ),
          outerRadiusFactor: _requiredDouble(
            pane,
            'outerRadiusFactor',
            '$path.pane',
          ),
          clipMarks: _requiredBool(pane, 'clipMarks', '$path.pane'),
        ),
        categoryAxis: RadarCategoryAxisConfig(
          showLabels: _requiredBool(
            category,
            'showLabels',
            '$path.categoryAxis',
          ),
          showSpokes: _requiredBool(
            category,
            'showSpokes',
            '$path.categoryAxis',
          ),
          maximumVisibleLabels: _requiredInt(
            category,
            'maximumVisibleLabels',
            '$path.categoryAxis',
          ),
          labelOffset: _requiredDouble(
            category,
            'labelOffset',
            '$path.categoryAxis',
          ),
          labelStyle: _decodePolarLabelStyle(
            category['labelStyle'],
            '$path.categoryAxis.labelStyle',
          ),
        ),
        radialAxis: RadarNumericAxisConfig(
          minimum: _requiredDouble(radial, 'minimum', '$path.radialAxis'),
          maximum: _optionalDouble(radial, 'maximum', '$path.radialAxis'),
          tickCount: _requiredInt(radial, 'tickCount', '$path.radialAxis'),
          showLabels: _requiredBool(radial, 'showLabels', '$path.radialAxis'),
          showGridLines: _requiredBool(
            radial,
            'showGridLines',
            '$path.radialAxis',
          ),
          gridShape: _requiredEnum(
            radial,
            'gridShape',
            RadarGridShape.values,
            '$path.radialAxis',
          ),
          labelPosition: _requiredEnum(
            radial,
            'labelPosition',
            PolarRadialLabelPosition.values,
            '$path.radialAxis',
          ),
          labelAngleOffsetDegrees: _requiredDouble(
            radial,
            'labelAngleOffsetDegrees',
            '$path.radialAxis',
          ),
          labelOffset: _requiredDouble(
            radial,
            'labelOffset',
            '$path.radialAxis',
          ),
          labelStyle: _decodePolarLabelStyle(
            radial['labelStyle'],
            '$path.radialAxis.labelStyle',
            defaults: const PolarLabelStyle(fontSize: 10),
          ),
        ),
      );
      config.validate();
      return ChartArtifactSuccess(value: config);
    } on _ConfigurationFormatException catch (error) {
      return _configurationFailure(error.message, error.path);
    } on Object catch (error) {
      return _polarConfigurationFailure(error, path);
    }
  }

  /// Encodes the pane, track layout, scale guides, and thresholds shared by a
  /// Radial Bar plot. The numeric domain remains series-owned.
  static ChartArtifactResult<JsonObjectValue> encodeRadialBarChart(
    RadialBarChartConfig config,
  ) {
    const path = r'$.configuration.radialBarChart';
    try {
      config.validate();
      return ChartArtifactSuccess(
        value: JsonObjectValue({
          'radialBarChart': JsonValue.fromJson({
            'pane': {
              'startAngleDegrees': config.pane.startAngleDegrees,
              'sweepAngleDegrees': config.pane.sweepAngleDegrees,
              'clockwise': config.pane.clockwise,
              'innerRadiusFactor': config.pane.innerRadiusFactor,
              'outerRadiusFactor': config.pane.outerRadiusFactor,
              'clipMarks': config.pane.clipMarks,
            },
            'trackGap': config.trackGap,
            'trackOrder': config.trackOrder.name,
            'showCategoryLabels': config.showCategoryLabels,
            'categoryLabels': {
              'position': config.categoryLabels.position.name,
              'orientation': config.categoryLabels.orientation.name,
              'offset': config.categoryLabels.offset,
              'textStyle': _encodePolarLabelStyle(
                config.categoryLabels.textStyle,
              ),
              'showPanel': config.categoryLabels.showPanel,
              if (config.categoryLabels.panelStyle != null)
                'panelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
                  config.categoryLabels.panelStyle!,
                ).toJson(),
              'connectorLength': config.categoryLabels.connectorLength,
              'connectorWidth': config.categoryLabels.connectorWidth,
              if (config.categoryLabels.connectorColor != null)
                'connectorColor': config.categoryLabels.connectorColor!
                    .toARGB32(),
            },
            'showScaleLabels': config.showScaleLabels,
            'showGridLines': config.showGridLines,
            'tickCount': config.tickCount,
            'thresholds': [
              for (final threshold in config.thresholds)
                {
                  'value': threshold.value,
                  if (threshold.label != null) 'label': threshold.label,
                  if (threshold.color != null)
                    'color': threshold.color!.toARGB32(),
                  'width': threshold.width,
                  'dashPattern': threshold.dashPattern,
                },
            ],
          }, path: path),
        }),
      );
    } on Object catch (error) {
      return _radialBarConfigurationFailure(error, path);
    }
  }

  /// Decodes an optional Radial Bar plot configuration.
  static ChartArtifactResult<RadialBarChartConfig?> decodeRadialBarChart(
    JsonObjectValue configuration,
  ) {
    const path = r'$.configuration.radialBarChart';
    final raw = configuration.values['radialBarChart'];
    if (raw == null) {
      return ChartArtifactSuccess<RadialBarChartConfig?>(value: null);
    }
    if (raw is! JsonObjectValue) {
      return _radialBarConfigurationFailure(
        'Radial Bar chart configuration must be an object.',
        path,
      );
    }
    try {
      final map = raw.toJson() as Map<String, Object?>;
      final pane = _requiredMap(map, 'pane', path);
      final categoryLabels = map['categoryLabels'] == null
          ? null
          : _requiredMap(map, 'categoryLabels', path);
      final config = RadialBarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: _requiredDouble(
            pane,
            'startAngleDegrees',
            '$path.pane',
          ),
          sweepAngleDegrees: _requiredDouble(
            pane,
            'sweepAngleDegrees',
            '$path.pane',
          ),
          clockwise: _requiredBool(pane, 'clockwise', '$path.pane'),
          innerRadiusFactor: _requiredDouble(
            pane,
            'innerRadiusFactor',
            '$path.pane',
          ),
          outerRadiusFactor: _requiredDouble(
            pane,
            'outerRadiusFactor',
            '$path.pane',
          ),
          clipMarks: _requiredBool(pane, 'clipMarks', '$path.pane'),
        ),
        trackGap: _requiredDouble(map, 'trackGap', path),
        trackOrder: _requiredEnum(
          map,
          'trackOrder',
          RadialBarTrackOrder.values,
          path,
        ),
        showCategoryLabels: _requiredBool(map, 'showCategoryLabels', path),
        categoryLabels: categoryLabels == null
            ? const RadialBarCategoryLabelConfig(
                position: RadialBarCategoryLabelPosition.legacyOnTrack,
              )
            : RadialBarCategoryLabelConfig(
                position: _requiredEnum(
                  categoryLabels,
                  'position',
                  RadialBarCategoryLabelPosition.values,
                  '$path.categoryLabels',
                ),
                orientation:
                    _optionalEnum(
                      categoryLabels,
                      'orientation',
                      RadialBarCategoryLabelOrientation.values,
                      '$path.categoryLabels',
                    ) ??
                    RadialBarCategoryLabelOrientation.followStartAngle,
                offset: _requiredDouble(
                  categoryLabels,
                  'offset',
                  '$path.categoryLabels',
                ),
                textStyle: _decodePolarLabelStyle(
                  _requiredMap(
                    categoryLabels,
                    'textStyle',
                    '$path.categoryLabels',
                  ),
                  '$path.categoryLabels.textStyle',
                ),
                showPanel: _requiredBool(
                  categoryLabels,
                  'showPanel',
                  '$path.categoryLabels',
                ),
                panelStyle: categoryLabels['panelStyle'] == null
                    ? null
                    : ChartStyleDocumentCodec.decodeLabelStyle(
                        JsonValue.fromJson(
                              _requiredMap(
                                categoryLabels,
                                'panelStyle',
                                '$path.categoryLabels',
                              ),
                            )
                            as JsonObjectValue,
                      ),
                connectorLength: _requiredDouble(
                  categoryLabels,
                  'connectorLength',
                  '$path.categoryLabels',
                ),
                connectorWidth: _requiredDouble(
                  categoryLabels,
                  'connectorWidth',
                  '$path.categoryLabels',
                ),
                connectorColor: categoryLabels['connectorColor'] == null
                    ? null
                    : Color(
                        _requiredInt(
                          categoryLabels,
                          'connectorColor',
                          '$path.categoryLabels',
                        ),
                      ),
              ),
        showScaleLabels: _requiredBool(map, 'showScaleLabels', path),
        showGridLines: _requiredBool(map, 'showGridLines', path),
        tickCount: _requiredInt(map, 'tickCount', path),
        thresholds: _decodeRadialBarThresholds(map['thresholds'], path),
      );
      config.validate();
      return ChartArtifactSuccess(value: config);
    } on _ConfigurationFormatException catch (error) {
      return _radialBarConfigurationFailure(error.message, error.path);
    } on Object catch (error) {
      return _radialBarConfigurationFailure(error, path);
    }
  }

  /// Encodes one Gauge pane and its portable center-label fallback.
  static ChartArtifactResult<JsonObjectValue> encodeGaugeChart(
    GaugeChartConfig config,
  ) {
    const path = r'$.configuration.gaugeChart';
    try {
      config.validate();
      return ChartArtifactSuccess(
        value: JsonObjectValue({
          'gaugeChart': JsonValue.fromJson({
            'pane': {
              'startAngleDegrees': config.pane.startAngleDegrees,
              'sweepAngleDegrees': config.pane.sweepAngleDegrees,
              'clockwise': config.pane.clockwise,
              'innerRadiusFactor': config.pane.innerRadiusFactor,
              'outerRadiusFactor': config.pane.outerRadiusFactor,
              'clipMarks': config.pane.clipMarks,
            },
            'tickCount': config.tickCount,
            'minorTicksPerInterval': config.minorTicksPerInterval,
            'showAxis': config.showAxis,
            'showTicks': config.showTicks,
            'showTickLabels': config.showTickLabels,
            'showZones': config.showZones,
            'colorIndicatorByActiveZone': config.colorIndicatorByActiveZone,
            'scale': {
              if (config.scale.tickColor != null)
                'tickColor': config.scale.tickColor!.toARGB32(),
              if (config.scale.tickWidth != null)
                'tickWidth': config.scale.tickWidth,
              if (config.scale.tickLength != null)
                'tickLength': config.scale.tickLength,
              'tickPosition': config.scale.tickPosition.name,
              'tickGap': config.scale.tickGap,
              if (config.scale.minorTickColor != null)
                'minorTickColor': config.scale.minorTickColor!.toARGB32(),
              'minorTickWidth': config.scale.minorTickWidth,
              'minorTickLength': config.scale.minorTickLength,
              'labelStyle': _encodePolarLabelStyle(config.scale.labelStyle),
              'labelPosition': config.scale.labelPosition.name,
              'labelOffset': config.scale.labelOffset,
              'labelMaxWidth': config.scale.labelMaxWidth,
            },
            'zones': {
              'gap': config.zones.gap,
              'cornerRadius': config.zones.cornerRadius,
              if (config.zones.opacity != null) 'opacity': config.zones.opacity,
              if (config.zones.borderColor != null)
                'borderColor': config.zones.borderColor!.toARGB32(),
              'borderWidth': config.zones.borderWidth,
            },
            'references': {
              'showLabels': config.references.showLabels,
              'innerLineOffset': config.references.innerLineOffset,
              'outerLineOffset': config.references.outerLineOffset,
              'labelStyle': _encodePolarLabelStyle(
                config.references.labelStyle,
              ),
              'labelOffset': config.references.labelOffset,
              'labelMaxWidth': config.references.labelMaxWidth,
              'showLabelPanel': config.references.showLabelPanel,
              if (config.references.panelColor != null)
                'panelColor': config.references.panelColor!.toARGB32(),
              if (config.references.panelBorderColor != null)
                'panelBorderColor': config.references.panelBorderColor!
                    .toARGB32(),
              'panelBorderWidth': config.references.panelBorderWidth,
              'panelBorderRadius': config.references.panelBorderRadius,
              'panelPadding': config.references.panelPadding,
            },
            'center': {
              'showMetric': config.center.showMetric,
              'showValue': config.center.showValue,
              'showTarget': config.center.showTarget,
              'showStatus': config.center.showStatus,
              'metricStyle': _encodePolarLabelStyle(config.center.metricStyle),
              'valueStyle': _encodePolarLabelStyle(config.center.valueStyle),
              'targetStyle': _encodePolarLabelStyle(config.center.targetStyle),
              'statusStyle': _encodePolarLabelStyle(config.center.statusStyle),
              'horizontalOffset': config.center.horizontalOffset,
              'verticalOffset': config.center.verticalOffset,
              'lineSpacing': config.center.lineSpacing,
            },
          }, path: path),
        }),
      );
    } on Object catch (error) {
      return _gaugeConfigurationFailure(error, path);
    }
  }

  /// Decodes an optional Gauge plot configuration.
  static ChartArtifactResult<GaugeChartConfig?> decodeGaugeChart(
    JsonObjectValue configuration,
  ) {
    const path = r'$.configuration.gaugeChart';
    final raw = configuration.values['gaugeChart'];
    if (raw == null) {
      return ChartArtifactSuccess<GaugeChartConfig?>(value: null);
    }
    if (raw is! JsonObjectValue) {
      return _gaugeConfigurationFailure(
        'Gauge chart configuration must be an object.',
        path,
      );
    }
    try {
      final map = raw.toJson() as Map<String, Object?>;
      final pane = _requiredMap(map, 'pane', path);
      final center = _requiredMap(map, 'center', path);
      final config = GaugeChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: _requiredDouble(
            pane,
            'startAngleDegrees',
            '$path.pane',
          ),
          sweepAngleDegrees: _requiredDouble(
            pane,
            'sweepAngleDegrees',
            '$path.pane',
          ),
          clockwise: _requiredBool(pane, 'clockwise', '$path.pane'),
          innerRadiusFactor: _requiredDouble(
            pane,
            'innerRadiusFactor',
            '$path.pane',
          ),
          outerRadiusFactor: _requiredDouble(
            pane,
            'outerRadiusFactor',
            '$path.pane',
          ),
          clipMarks: _requiredBool(pane, 'clipMarks', '$path.pane'),
        ),
        tickCount: _requiredInt(map, 'tickCount', path),
        minorTicksPerInterval:
            _optionalInt(map, 'minorTicksPerInterval', path) ?? 0,
        showAxis: _requiredBool(map, 'showAxis', path),
        showTicks: _requiredBool(map, 'showTicks', path),
        showTickLabels: _requiredBool(map, 'showTickLabels', path),
        showZones: _requiredBool(map, 'showZones', path),
        colorIndicatorByActiveZone: _requiredBool(
          map,
          'colorIndicatorByActiveZone',
          path,
        ),
        scale: _decodeGaugeScaleStyle(map['scale'], '$path.scale'),
        zones: _decodeGaugeZoneStyle(map['zones'], '$path.zones'),
        references: _decodeGaugeReferenceStyle(
          map['references'],
          '$path.references',
        ),
        center: GaugeCenterConfig(
          showMetric: _requiredBool(center, 'showMetric', '$path.center'),
          showValue: _requiredBool(center, 'showValue', '$path.center'),
          showTarget: _requiredBool(center, 'showTarget', '$path.center'),
          showStatus: _requiredBool(center, 'showStatus', '$path.center'),
          metricStyle: _decodePolarLabelStyle(
            center['metricStyle'],
            '$path.center.metricStyle',
          ),
          valueStyle: _decodePolarLabelStyle(
            center['valueStyle'],
            '$path.center.valueStyle',
          ),
          targetStyle: _decodePolarLabelStyle(
            center['targetStyle'],
            '$path.center.targetStyle',
          ),
          statusStyle: _decodePolarLabelStyle(
            center['statusStyle'],
            '$path.center.statusStyle',
          ),
          horizontalOffset:
              _optionalDouble(center, 'horizontalOffset', '$path.center') ?? 0,
          verticalOffset:
              _optionalDouble(center, 'verticalOffset', '$path.center') ?? 0,
          lineSpacing:
              _optionalDouble(center, 'lineSpacing', '$path.center') ?? 3,
        ),
      );
      config.validate();
      return ChartArtifactSuccess(value: config);
    } on _ConfigurationFormatException catch (error) {
      return _gaugeConfigurationFailure(error.message, error.path);
    } on Object catch (error) {
      return _gaugeConfigurationFailure(error, path);
    }
  }
}

GaugeScaleStyle _decodeGaugeScaleStyle(Object? value, String path) {
  if (value == null) return const GaugeScaleStyle();
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Gauge scale style must be an object.',
      path,
    );
  }
  final map = value.cast<String, Object?>();
  final tickColor = map['tickColor'];
  final minorTickColor = map['minorTickColor'];
  if (tickColor != null && tickColor is! int) {
    throw _ConfigurationFormatException(
      'Optional tick color must be an ARGB integer.',
      '$path.tickColor',
    );
  }
  if (minorTickColor != null && minorTickColor is! int) {
    throw _ConfigurationFormatException(
      'Optional minor tick color must be an ARGB integer.',
      '$path.minorTickColor',
    );
  }
  return GaugeScaleStyle(
    tickColor: tickColor == null ? null : Color(tickColor as int),
    tickWidth: _optionalDouble(map, 'tickWidth', path),
    tickLength: _optionalDouble(map, 'tickLength', path),
    tickPosition: _decodeGaugeTickPosition(
      map['tickPosition'],
      '$path.tickPosition',
    ),
    tickGap: _optionalDouble(map, 'tickGap', path) ?? 0,
    minorTickColor: minorTickColor == null
        ? null
        : Color(minorTickColor as int),
    minorTickWidth: _optionalDouble(map, 'minorTickWidth', path) ?? 1,
    minorTickLength: _optionalDouble(map, 'minorTickLength', path) ?? 5,
    labelStyle: map['labelStyle'] == null
        ? const PolarLabelStyle(fontSize: 9)
        : _decodePolarLabelStyle(map['labelStyle'], '$path.labelStyle'),
    labelPosition: _decodeGaugeScaleLabelPosition(
      map['labelPosition'],
      '$path.labelPosition',
    ),
    labelOffset: _optionalDouble(map, 'labelOffset', path) ?? 10,
    labelMaxWidth: _optionalDouble(map, 'labelMaxWidth', path) ?? 72,
  );
}

GaugeTickPosition _decodeGaugeTickPosition(Object? value, String path) {
  if (value == null) return GaugeTickPosition.centered;
  if (value is! String) {
    throw _ConfigurationFormatException(
      'Gauge tick position must be a string.',
      path,
    );
  }
  try {
    return GaugeTickPosition.values.byName(value);
  } on ArgumentError {
    throw _ConfigurationFormatException(
      'Unknown Gauge tick position "$value".',
      path,
    );
  }
}

GaugeScaleLabelPosition _decodeGaugeScaleLabelPosition(
  Object? value,
  String path,
) {
  if (value == null) return GaugeScaleLabelPosition.outside;
  if (value is! String) {
    throw _ConfigurationFormatException(
      'Gauge scale-label position must be a string.',
      path,
    );
  }
  try {
    return GaugeScaleLabelPosition.values.byName(value);
  } on ArgumentError {
    throw _ConfigurationFormatException(
      'Unknown Gauge scale-label position "$value".',
      path,
    );
  }
}

GaugeZoneStyle _decodeGaugeZoneStyle(Object? value, String path) {
  if (value == null) return const GaugeZoneStyle();
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Gauge zone style must be an object.',
      path,
    );
  }
  final map = value.cast<String, Object?>();
  final borderColor = map['borderColor'];
  if (borderColor != null && borderColor is! int) {
    throw _ConfigurationFormatException(
      'Optional zone border color must be an ARGB integer.',
      '$path.borderColor',
    );
  }
  return GaugeZoneStyle(
    gap: _optionalDouble(map, 'gap', path) ?? 0,
    cornerRadius: _optionalDouble(map, 'cornerRadius', path) ?? 0,
    opacity: _optionalDouble(map, 'opacity', path),
    borderColor: borderColor == null ? null : Color(borderColor as int),
    borderWidth: _optionalDouble(map, 'borderWidth', path) ?? 0,
  );
}

GaugeReferenceStyle _decodeGaugeReferenceStyle(Object? value, String path) {
  if (value == null) return const GaugeReferenceStyle();
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Gauge reference style must be an object.',
      path,
    );
  }
  final map = value.cast<String, Object?>();
  final showLabels = map['showLabels'];
  final showLabelPanel = map['showLabelPanel'];
  final panelColor = map['panelColor'];
  final panelBorderColor = map['panelBorderColor'];
  if (showLabels != null && showLabels is! bool) {
    throw _ConfigurationFormatException(
      'Optional showLabels field must be a boolean.',
      '$path.showLabels',
    );
  }
  if (showLabelPanel != null && showLabelPanel is! bool) {
    throw _ConfigurationFormatException(
      'Optional showLabelPanel field must be a boolean.',
      '$path.showLabelPanel',
    );
  }
  if (panelColor != null && panelColor is! int) {
    throw _ConfigurationFormatException(
      'Optional panel color must be an ARGB integer.',
      '$path.panelColor',
    );
  }
  if (panelBorderColor != null && panelBorderColor is! int) {
    throw _ConfigurationFormatException(
      'Optional panel border color must be an ARGB integer.',
      '$path.panelBorderColor',
    );
  }
  return GaugeReferenceStyle(
    showLabels: showLabels as bool? ?? true,
    innerLineOffset: _optionalDouble(map, 'innerLineOffset', path) ?? 4,
    outerLineOffset: _optionalDouble(map, 'outerLineOffset', path) ?? 6,
    labelStyle: map['labelStyle'] == null
        ? const PolarLabelStyle(fontSize: 10, fontWeight: FontWeight.w700)
        : _decodePolarLabelStyle(map['labelStyle'], '$path.labelStyle'),
    labelOffset: _optionalDouble(map, 'labelOffset', path) ?? 8,
    labelMaxWidth: _optionalDouble(map, 'labelMaxWidth', path) ?? 100,
    showLabelPanel: showLabelPanel as bool? ?? false,
    panelColor: panelColor == null ? null : Color(panelColor as int),
    panelBorderColor: panelBorderColor == null
        ? null
        : Color(panelBorderColor as int),
    panelBorderWidth: _optionalDouble(map, 'panelBorderWidth', path) ?? 1,
    panelBorderRadius: _optionalDouble(map, 'panelBorderRadius', path) ?? 4,
    panelPadding: _optionalDouble(map, 'panelPadding', path) ?? 4,
  );
}

List<PolarThreshold> _decodePolarThresholds(Object? value, String path) {
  if (value == null) return const <PolarThreshold>[];
  if (value is! List) {
    throw _ConfigurationFormatException(
      'Optional thresholds field must be a list.',
      '$path.thresholds',
    );
  }
  return <PolarThreshold>[
    for (final (index, rawThreshold) in value.indexed)
      _decodePolarThreshold(rawThreshold, '$path.thresholds[$index]'),
  ];
}

PolarThreshold _decodePolarThreshold(Object? value, String path) {
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Polar threshold must be an object.',
      path,
    );
  }
  final map = value.cast<String, Object?>();
  final label = map['label'];
  if (label != null && label is! String) {
    throw _ConfigurationFormatException(
      'Optional threshold label must be text.',
      '$path.label',
    );
  }
  final color = map['color'];
  if (color != null && color is! int) {
    throw _ConfigurationFormatException(
      'Optional threshold color must be an ARGB integer.',
      '$path.color',
    );
  }
  final rawPattern = map['dashPattern'];
  if (rawPattern is! List || rawPattern.any((interval) => interval is! num)) {
    throw _ConfigurationFormatException(
      'Threshold dashPattern must be a numeric list.',
      '$path.dashPattern',
    );
  }
  return PolarThreshold(
    value: _requiredDouble(map, 'value', path),
    label: label as String?,
    color: _optionalColor(color as int?),
    width: _requiredDouble(map, 'width', path),
    dashPattern: <double>[
      for (final interval in rawPattern) (interval as num).toDouble(),
    ],
  );
}

List<RadialBarThreshold> _decodeRadialBarThresholds(
  Object? value,
  String path,
) {
  if (value == null) return const <RadialBarThreshold>[];
  if (value is! List) {
    throw _ConfigurationFormatException(
      'Optional thresholds field must be a list.',
      '$path.thresholds',
    );
  }
  return <RadialBarThreshold>[
    for (final (index, rawThreshold) in value.indexed)
      _decodeRadialBarThreshold(rawThreshold, '$path.thresholds[$index]'),
  ];
}

RadialBarThreshold _decodeRadialBarThreshold(Object? value, String path) {
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Radial Bar threshold must be an object.',
      path,
    );
  }
  final map = value.cast<String, Object?>();
  final label = map['label'];
  if (label != null && label is! String) {
    throw _ConfigurationFormatException(
      'Optional threshold label must be text.',
      '$path.label',
    );
  }
  final color = map['color'];
  if (color != null && color is! int) {
    throw _ConfigurationFormatException(
      'Optional threshold color must be an ARGB integer.',
      '$path.color',
    );
  }
  final rawPattern = map['dashPattern'];
  if (rawPattern is! List || rawPattern.any((interval) => interval is! num)) {
    throw _ConfigurationFormatException(
      'Threshold dashPattern must be a numeric list.',
      '$path.dashPattern',
    );
  }
  return RadialBarThreshold(
    value: _requiredDouble(map, 'value', path),
    label: label as String?,
    color: _optionalColor(color as int?),
    width: _requiredDouble(map, 'width', path),
    dashPattern: <double>[
      for (final interval in rawPattern) (interval as num).toDouble(),
    ],
  );
}

Color? _optionalColor(int? value) => value == null ? null : Color(value);

Map<String, Object?> _encodePolarLabelStyle(PolarLabelStyle style) => {
  if (style.color != null) 'color': style.color!.toARGB32(),
  if (style.fontSize != null) 'fontSize': style.fontSize,
  if (style.fontWeight != null)
    'fontWeightIndex': FontWeight.values.indexOf(style.fontWeight!),
};

PolarLabelStyle _decodePolarLabelStyle(
  Object? value,
  String path, {
  PolarLabelStyle defaults = const PolarLabelStyle(),
}) {
  if (value == null) return defaults;
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Polar label style must be an object.',
      path,
    );
  }
  final map = value.cast<String, Object?>();
  final rawColor = map['color'];
  if (rawColor != null && rawColor is! int) {
    throw _ConfigurationFormatException(
      'Optional label color must be an ARGB integer.',
      '$path.color',
    );
  }
  final rawWeight = map['fontWeightIndex'];
  FontWeight? weight = defaults.fontWeight;
  if (rawWeight != null) {
    if (rawWeight is! int ||
        rawWeight < 0 ||
        rawWeight >= FontWeight.values.length) {
      throw _ConfigurationFormatException(
        'Optional font weight index is invalid.',
        '$path.fontWeightIndex',
      );
    }
    weight = FontWeight.values[rawWeight];
  }
  return PolarLabelStyle(
    color: rawColor == null ? defaults.color : Color(rawColor as int),
    fontSize: _optionalDouble(map, 'fontSize', path) ?? defaults.fontSize,
    fontWeight: weight,
  );
}

ChartArtifactFailure<T> _invalidFailure<T>(Object error, String path) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid built-in chart configuration: $error',
        path: path,
      ),
    );

void _validateConcentricConfig(ConcentricDonutConfig config, String path) {
  if (!config.innerRadiusFactor.isFinite ||
      config.innerRadiusFactor < 0 ||
      config.innerRadiusFactor >= 1) {
    throw _ConfigurationFormatException(
      'Inner radius factor must be finite and in [0, 1).',
      '$path.innerRadiusFactor',
    );
  }
  if (!config.outerRadiusFactor.isFinite ||
      config.outerRadiusFactor <= 0 ||
      config.outerRadiusFactor > 1) {
    throw _ConfigurationFormatException(
      'Outer radius factor must be finite and in (0, 1].',
      '$path.outerRadiusFactor',
    );
  }
  if (config.innerRadiusFactor >= config.outerRadiusFactor) {
    throw _ConfigurationFormatException(
      'Inner radius factor must be smaller than outer radius factor.',
      '$path.innerRadiusFactor',
    );
  }
  if (!config.ringGap.isFinite || config.ringGap < 0) {
    throw _ConfigurationFormatException(
      'Ring gap must be finite and non-negative.',
      '$path.ringGap',
    );
  }
  for (final entry in config.ringWeights.entries) {
    if (!entry.value.isFinite || entry.value <= 0) {
      throw _ConfigurationFormatException(
        'Ring weights must be finite and greater than zero.',
        '$path.ringWeights[${entry.key}]',
      );
    }
  }
  final label = config.centerContent.label?.trim();
  if (config.centerContent.label != null && (label == null || label.isEmpty)) {
    throw _ConfigurationFormatException(
      'Center label cannot be blank.',
      '$path.centerContent.label',
    );
  }
  final customValue = config.centerContent.customValue?.trim();
  if (config.centerContent.valueMode == DonutCenterValueMode.custom &&
      (customValue == null || customValue.isEmpty)) {
    throw _ConfigurationFormatException(
      'Custom center content requires a visible custom value.',
      '$path.centerContent.customValue',
    );
  }
}

double _requiredDouble(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! num) {
    throw _ConfigurationFormatException(
      'Required numeric field "$key" is missing or invalid.',
      '$path.$key',
    );
  }
  final result = value.toDouble();
  if (!result.isFinite) {
    throw _ConfigurationFormatException(
      'Numeric field "$key" must be finite.',
      '$path.$key',
    );
  }
  return result;
}

double? _optionalDouble(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value == null) return null;
  if (value is! num || !value.toDouble().isFinite) {
    throw _ConfigurationFormatException(
      'Optional numeric field "$key" is invalid.',
      '$path.$key',
    );
  }
  return value.toDouble();
}

int _requiredInt(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! int) {
    throw _ConfigurationFormatException(
      'Required integer field "$key" is missing or invalid.',
      '$path.$key',
    );
  }
  return value;
}

int? _optionalInt(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value == null) return null;
  if (value is! int) {
    throw _ConfigurationFormatException(
      'Optional integer field "$key" is invalid.',
      '$path.$key',
    );
  }
  return value;
}

bool _requiredBool(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! bool) {
    throw _ConfigurationFormatException(
      'Required boolean field "$key" is missing or invalid.',
      '$path.$key',
    );
  }
  return value;
}

Map<String, Object?> _requiredMap(
  Map<String, Object?> map,
  String key,
  String path,
) {
  final value = map[key];
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Required object field "$key" is missing or invalid.',
      '$path.$key',
    );
  }
  return value.cast<String, Object?>();
}

Map<String, double> _stringDoubleMap(Object? value, String path) {
  if (value is! Map) {
    throw _ConfigurationFormatException(
      'Ring weights must be an object.',
      path,
    );
  }
  final result = <String, double>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! num) {
      throw _ConfigurationFormatException(
        'Ring weights must map series IDs to numbers.',
        path,
      );
    }
    result[entry.key as String] = (entry.value as num).toDouble();
  }
  return result;
}

T _requiredEnum<T extends Enum>(
  Map<String, Object?> map,
  String key,
  List<T> values,
  String path,
) {
  final name = map[key];
  if (name is String) {
    for (final value in values) {
      if (value.name == name) return value;
    }
  }
  throw _ConfigurationFormatException(
    'Unknown or missing $key "$name".',
    '$path.$key',
  );
}

T? _optionalEnum<T extends Enum>(
  Map<String, Object?> map,
  String key,
  List<T> values,
  String path,
) {
  final name = map[key];
  if (name == null) return null;
  if (name is String) {
    for (final value in values) {
      if (value.name == name) return value;
    }
  }
  throw _ConfigurationFormatException('Unknown $key "$name".', '$path.$key');
}

ChartArtifactFailure<T> _configurationFailure<T>(Object error, String path) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid Concentric Donut configuration: $error',
        path: path,
      ),
    );

ChartArtifactFailure<T> _polarConfigurationFailure<T>(
  Object error,
  String path,
) => ChartArtifactFailure(
  error: ChartArtifactError(
    code: ChartArtifactDiagnosticCodes.invalidArtifact,
    message: 'Invalid Polar chart configuration: $error',
    path: path,
  ),
);

ChartArtifactFailure<T> _radialBarConfigurationFailure<T>(
  Object error,
  String path,
) => ChartArtifactFailure(
  error: ChartArtifactError(
    code: ChartArtifactDiagnosticCodes.invalidArtifact,
    message: 'Invalid Radial Bar chart configuration: $error',
    path: path,
  ),
);

ChartArtifactFailure<T> _gaugeConfigurationFailure<T>(
  Object error,
  String path,
) => ChartArtifactFailure(
  error: ChartArtifactError(
    code: ChartArtifactDiagnosticCodes.invalidArtifact,
    message: 'Invalid Gauge chart configuration: $error',
    path: path,
  ),
);

Color? _optionalConfigurationColor(Object? value) {
  if (value == null) return null;
  if (value is! int) {
    throw const FormatException('Color must be an ARGB integer.');
  }
  return Color(value);
}

ChartArtifactFailure<T> _seriesCalloutConfigurationFailure<T>(
  Object error,
  String path,
) => ChartArtifactFailure(
  error: ChartArtifactError(
    code: ChartArtifactDiagnosticCodes.invalidArtifact,
    message: 'Invalid series callout configuration: $error',
    path: path,
  ),
);

class _ConfigurationFormatException implements Exception {
  const _ConfigurationFormatException(this.message, this.path);

  final String message;
  final String path;
}
