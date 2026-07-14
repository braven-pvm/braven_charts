import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';

@immutable
class ChartPreview {
  ChartPreview({
    required this.mimeType,
    required this.widthPixels,
    required this.heightPixels,
    required this.pixelRatio,
    required this.documentHash,
    Uint8List? bytes,
    this.uri,
    this.byteLength,
  }) : _bytes = bytes == null ? null : Uint8List.fromList(bytes) {
    if (bytes != null && uri != null) {
      throw ArgumentError('ChartPreview cannot contain both bytes and uri');
    }
  }

  final String mimeType;
  final int widthPixels;
  final int heightPixels;
  final double pixelRatio;
  final String documentHash;
  final Uint8List? _bytes;
  final Uri? uri;
  final int? byteLength;

  Uint8List? get bytes => _bytes == null ? null : Uint8List.fromList(_bytes);

  Map<String, Object?> toJson() => {
    'mimeType': mimeType,
    'widthPixels': widthPixels,
    'heightPixels': heightPixels,
    'pixelRatio': pixelRatio,
    'documentHash': documentHash,
    if (_bytes != null) 'bytesBase64': base64Encode(_bytes),
    if (uri != null) 'uri': uri.toString(),
    if (byteLength != null) 'byteLength': byteLength,
  };

  factory ChartPreview.fromJson(Map<String, Object?> json) => ChartPreview(
    mimeType: readRequiredString(json, 'mimeType'),
    widthPixels: readRequiredInt(json, 'widthPixels'),
    heightPixels: readRequiredInt(json, 'heightPixels'),
    pixelRatio: readRequiredDouble(json, 'pixelRatio'),
    documentHash: readRequiredString(json, 'documentHash'),
    bytes: json['bytesBase64'] == null
        ? null
        : base64Decode(readRequiredString(json, 'bytesBase64')),
    uri: json['uri'] == null
        ? null
        : Uri.parse(readRequiredString(json, 'uri')),
    byteLength: readOptionalInt(json, 'byteLength'),
  );
}
