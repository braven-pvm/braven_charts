import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'chart_document.dart';
import 'json_value.dart';

/// Canonical content identities used by previews and host deduplication.
abstract final class ChartArtifactCanonicalizer {
  static String documentHash(ChartDocument document) {
    final bytes = utf8.encode(canonicalJsonEncode(document.toJson()));
    return 'sha256:${sha256.convert(bytes)}';
  }
}
