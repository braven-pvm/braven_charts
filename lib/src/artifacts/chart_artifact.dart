import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_document.dart';
import 'chart_preview.dart';
import 'chart_view_state.dart';
import 'json_value.dart';

/// Identifies the renderer that produced an artifact.
///
/// This metadata is recorded for observability and compatibility decisions;
/// it never dynamically loads the named package or version.
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

/// JSON-safe host metadata carried alongside a portable artifact.
///
/// Provenance is descriptive only. Hosts that need authenticity must add a
/// separate signing and verification policy.
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

/// Optional content-integrity metadata supplied by the host.
///
/// The codec preserves this value but does not interpret an algorithm name as
/// a cryptographic verification instruction.
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

/// Portable envelope for one effective chart document.
///
/// The envelope contains renderer-independent configuration and data, durable
/// view state, and optionally a preview. Use [ChartArtifactJsonCodec] for
/// validated transport rather than relying on [toJson] alone.
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

  /// Stable discriminator written at the root of every artifact JSON object.
  static const artifactType = 'braven.chartArtifact';

  /// Schema version written by this package.
  static const currentSchemaVersion = 1;

  /// Host-selected identity for storage, sharing, or cache keys.
  final String artifactId;

  /// Schema version of this envelope.
  final int schemaVersion;

  /// Renderer metadata recorded at capture time.
  final ChartRendererInfo renderer;

  /// UTC capture time.
  final DateTime createdAt;

  /// Effective chart configuration and data.
  final ChartDocument document;

  /// Optional durable visibility, selection, viewport, and axis-slot state.
  final ChartViewState? viewState;

  /// Optional raster preview bound to [document] by canonical hash.
  final ChartPreview? preview;

  /// Optional JSON-safe host provenance metadata.
  final ChartArtifactProvenance provenance;

  /// Optional host-supplied integrity metadata.
  final ChartArtifactIntegrity? integrity;

  /// Namespaced JSON-safe extension values preserved across transport.
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
