import 'package:flutter/material.dart';

import '../models/grid_config.dart';
import '../models/legend_style.dart';
import '../models/normalization_mode.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_configuration_documents.dart';
import 'chart_data_payload.dart';
import 'chart_style_document_codec.dart';

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
