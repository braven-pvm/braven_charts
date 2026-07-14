import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_document.dart';
import 'chart_preview.dart';
import 'chart_view_state.dart';
import 'json_value.dart';

@immutable
class ChartRendererInfo {
  const ChartRendererInfo({required this.package, required this.version});

  final String package;
  final String version;

  Map<String, Object?> toJson() => {'package': package, 'version': version};

  factory ChartRendererInfo.fromJson(Map<String, Object?> json) =>
      ChartRendererInfo(
        package: readRequiredString(json, 'package'),
        version: readRequiredString(json, 'version'),
      );
}

@immutable
class ChartArtifactProvenance {
  ChartArtifactProvenance({JsonObjectValue? values})
    : values = values ?? JsonObjectValue(const {});

  final JsonObjectValue values;

  Map<String, Object?> toJson() => values.toJson() as Map<String, Object?>;

  factory ChartArtifactProvenance.fromJson(Map<String, Object?> json) =>
      ChartArtifactProvenance(
        values: JsonValue.fromJson(json) as JsonObjectValue,
      );
}

@immutable
class ChartArtifactIntegrity {
  const ChartArtifactIntegrity({required this.algorithm, required this.digest});

  final String algorithm;
  final String digest;

  Map<String, Object?> toJson() => {'algorithm': algorithm, 'digest': digest};

  factory ChartArtifactIntegrity.fromJson(Map<String, Object?> json) =>
      ChartArtifactIntegrity(
        algorithm: readRequiredString(json, 'algorithm'),
        digest: readRequiredString(json, 'digest'),
      );
}

@immutable
class ChartArtifact {
  ChartArtifact({
    required this.artifactId,
    this.schemaVersion = currentSchemaVersion,
    required this.renderer,
    required DateTime createdAt,
    required this.document,
    this.viewState,
    this.preview,
    ChartArtifactProvenance? provenance,
    this.integrity,
    Map<String, JsonValue> extensions = const {},
  }) : createdAt = createdAt.toUtc(),
       provenance = provenance ?? ChartArtifactProvenance(),
       extensions = Map.unmodifiable(extensions);

  static const artifactType = 'braven.chartArtifact';
  static const currentSchemaVersion = 1;

  final String artifactId;
  final int schemaVersion;
  final ChartRendererInfo renderer;
  final DateTime createdAt;
  final ChartDocument document;
  final ChartViewState? viewState;
  final ChartPreview? preview;
  final ChartArtifactProvenance provenance;
  final ChartArtifactIntegrity? integrity;
  final Map<String, JsonValue> extensions;

  Map<String, Object?> toJson() => {
    'artifactType': artifactType,
    'schemaVersion': schemaVersion,
    'renderer': renderer.toJson(),
    'artifactId': artifactId,
    'createdAt': createdAt.toIso8601String(),
    'document': document.toJson(),
    if (viewState != null) 'viewState': viewState!.toJson(),
    if (preview != null) 'preview': preview!.toJson(),
    if (provenance.values.values.isNotEmpty) 'provenance': provenance.toJson(),
    if (integrity != null) 'integrity': integrity!.toJson(),
    if (extensions.isNotEmpty) 'extensions': jsonValueMap(extensions),
  };

  factory ChartArtifact.fromJson(Map<String, Object?> json) {
    final artifactTypeValue = readRequiredString(json, 'artifactType');
    if (artifactTypeValue != artifactType) {
      throw FormatException('Unsupported artifactType: $artifactTypeValue');
    }
    return ChartArtifact(
      artifactId: readRequiredString(json, 'artifactId'),
      schemaVersion: readRequiredInt(json, 'schemaVersion'),
      renderer: ChartRendererInfo.fromJson(readRequiredMap(json, 'renderer')),
      createdAt: readRequiredDateTime(json, 'createdAt'),
      document: ChartDocument.fromJson(readRequiredMap(json, 'document')),
      viewState: json['viewState'] == null
          ? null
          : ChartViewState.fromJson(readRequiredMap(json, 'viewState')),
      preview: json['preview'] == null
          ? null
          : ChartPreview.fromJson(readRequiredMap(json, 'preview')),
      provenance: json['provenance'] == null
          ? null
          : ChartArtifactProvenance.fromJson(
              readRequiredMap(json, 'provenance'),
            ),
      integrity: json['integrity'] == null
          ? null
          : ChartArtifactIntegrity.fromJson(readRequiredMap(json, 'integrity')),
      extensions: readOptionalJsonValueMap(json, 'extensions'),
    );
  }
}
