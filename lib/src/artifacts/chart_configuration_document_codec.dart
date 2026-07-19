import 'package:flutter/material.dart';

import '../models/grid_config.dart';
import '../models/concentric_donut_config.dart';
import '../models/donut_chart_config.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import '../models/pie_chart_config.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_configuration_documents.dart';
import 'chart_data_payload.dart';
import 'chart_style_document_codec.dart';
import 'donut_center_content_document_codec.dart';
import 'json_value.dart';

typedef ChartLegendConfiguration = ({bool visible, LegendStyle style});

/// Audited adapters for portable chart-level built-in configuration models.
abstract final class ChartConfigurationDocumentCodec {
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
}

Color? _optionalColor(int? value) => value == null ? null : Color(value);

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

ChartArtifactFailure<T> _configurationFailure<T>(Object error, String path) =>
    ChartArtifactFailure(
      error: ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Invalid Concentric Donut configuration: $error',
        path: path,
      ),
    );

class _ConfigurationFormatException implements Exception {
  const _ConfigurationFormatException(this.message, this.path);

  final String message;
  final String path;
}
