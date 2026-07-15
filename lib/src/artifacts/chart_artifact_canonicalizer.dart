import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'chart_data_payload.dart';
import 'chart_document.dart';
import 'chart_view_state.dart';
import 'json_value.dart';

/// Canonical content identities used by previews and host deduplication.
abstract final class ChartArtifactCanonicalizer {
  /// Hashes the complete portable chart document, including its identity and
  /// revision fields.
  static String documentHash(ChartDocument document) {
    return _sha256(canonicalJsonEncode(document.toJson()));
  }

  /// Hashes the document together with the durable view state that should be
  /// restored by a hydrator.
  ///
  /// A missing view state is encoded explicitly so this identity cannot be
  /// confused with a document-only hash.
  static String viewHash(ChartDocument document, ChartViewState? viewState) =>
      _sha256(
        canonicalJsonEncode({
          'document': document.toJson(),
          'viewState': viewState?.toJson(),
        }),
      );

  /// Hashes one data payload without requiring hosts to duplicate external
  /// blob bytes in memory.
  ///
  /// Referenced payloads declare the SHA-256 of their resolved bytes, so that
  /// checksum is their content identity without loading the blob. Hosts still
  /// verify the declared checksum during resolution. Inline payloads are
  /// hashed from their canonical portable representation.
  static String dataPayloadHash(ChartDataPayload payload) =>
      payload is ReferencedPayload
      ? payload.checksum
      : _sha256(canonicalJsonEncode(payload.toJson()));

  static String _sha256(String canonicalJson) {
    final bytes = utf8.encode(canonicalJson);
    return 'sha256:${sha256.convert(bytes)}';
  }
}
