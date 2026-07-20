part of 'chart_data_resolver.dart';

/// Deterministic schema-v1 binary codec for host-resolved columnar data.
///
/// X and Y values retain their exact IEEE-754 representation. Each value is
/// XORed with the previous value in its column and only the significant byte
/// window is retained. Optional point columns remain a canonical JSON sidecar
/// so their portable schema stays aligned with [InlineColumnarPayload].
abstract final class ChartDataBinaryCodec {
  static const contentType = 'application/vnd.braven-charts.columnar-binary-v1';
  static const formatVersion = 1;
  static const compression = 'xor-significant-bytes-v1';

  static const _headerLength = 28;
  static const _magic = <int>[0x42, 0x52, 0x56, 0x4e, 0x44, 0x41, 0x54, 0x31];
  static const _sidecarKeys = <String>{
    'timestamps',
    'labels',
    'magnitudes',
    'colorValues',
    'opacityValues',
    'categoryValues',
    'metadata',
    'segmentStyles',
    'pointStyles',
    'pointExtensions',
  };

  static ChartArtifactResult<ChartDataBlob> encode(
    InlineChartDataPayload payload, {
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
  }) {
    final columnar = payload is InlineColumnarPayload
        ? payload
        : InlineColumnarPayload.fromPoints(payload.points);
    if (columnar.pointCount > limits.maxPoints) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message:
              'Data payload has ${columnar.pointCount} points; maximum is '
              '${limits.maxPoints}.',
          path: r'$.data.pointCount',
        ),
      );
    }

    final xBytes = _encodeNumbers(columnar.xValues);
    final yBytes = _encodeNumbers(columnar.yValues);
    final sidecar = columnar.toJson()
      ..remove('storage')
      ..remove('x')
      ..remove('y');
    final sidecarBytes = utf8.encode(canonicalJsonEncode(sidecar));
    final byteLength =
        _headerLength + xBytes.length + yBytes.length + sidecarBytes.length;
    if (byteLength > limits.maxDataPayloadBytes) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
          message:
              'Binary data payload is $byteLength bytes; maximum is '
              '${limits.maxDataPayloadBytes}.',
          path: r'$.data',
        ),
      );
    }

    final bytes = Uint8List(byteLength);
    bytes.setRange(0, _magic.length, _magic);
    final header = ByteData.sublistView(bytes, 8, _headerLength);
    header.setUint8(0, formatVersion);
    header.setUint8(1, 0);
    header.setUint16(2, _headerLength, Endian.big);
    header.setUint32(4, columnar.pointCount, Endian.big);
    header.setUint32(8, xBytes.length, Endian.big);
    header.setUint32(12, yBytes.length, Endian.big);
    header.setUint32(16, sidecarBytes.length, Endian.big);
    var offset = _headerLength;
    bytes.setRange(offset, offset + xBytes.length, xBytes);
    offset += xBytes.length;
    bytes.setRange(offset, offset + yBytes.length, yBytes);
    offset += yBytes.length;
    bytes.setRange(offset, offset + sidecarBytes.length, sidecarBytes);

    return ChartArtifactSuccess(
      value: ChartDataBlob(
        bytes: bytes,
        contentType: contentType,
        checksum: ChartDataBlobCodec._checksum(bytes),
        pointCount: columnar.pointCount,
      ),
    );
  }

  static ChartArtifactResult<InlineChartDataPayload> decode(
    ReferencedPayload reference,
    List<int> bytes, {
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
    String path = r'$.data',
  }) {
    final manifestFailure = ChartDataBlobCodec._validateManifest(
      reference,
      limits,
      path,
      supportedContentTypes: const {contentType},
    );
    if (manifestFailure != null) {
      return ChartArtifactFailure(error: manifestFailure);
    }
    final bytesFailure = ChartDataBlobCodec._validateResolvedBytes(
      reference,
      bytes,
      path,
    );
    if (bytesFailure != null) {
      return ChartArtifactFailure(error: bytesFailure);
    }

    try {
      if (bytes.length < _headerLength) {
        throw const FormatException('Binary payload header is truncated.');
      }
      for (var index = 0; index < _magic.length; index++) {
        if (bytes[index] != _magic[index]) {
          throw const FormatException('Binary payload magic is invalid.');
        }
      }
      final buffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final header = ByteData.sublistView(buffer, 8, _headerLength);
      if (header.getUint8(0) != formatVersion) {
        throw FormatException(
          'Unsupported binary payload version ${header.getUint8(0)}.',
        );
      }
      if (header.getUint8(1) != 0 ||
          header.getUint16(2, Endian.big) != _headerLength) {
        throw const FormatException('Binary payload header is invalid.');
      }
      final pointCount = header.getUint32(4, Endian.big);
      if (pointCount != reference.pointCount) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch,
            message:
                'Binary payload has $pointCount points; manifest declares '
                '${reference.pointCount}.',
            path: '$path.pointCount',
          ),
        );
      }
      if (pointCount > limits.maxPoints) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
            message:
                'Binary payload has $pointCount points; maximum is '
                '${limits.maxPoints}.',
            path: '$path.pointCount',
          ),
        );
      }

      final xLength = header.getUint32(8, Endian.big);
      final yLength = header.getUint32(12, Endian.big);
      final sidecarLength = header.getUint32(16, Endian.big);
      final expectedLength = _headerLength + xLength + yLength + sidecarLength;
      if (expectedLength != bytes.length) {
        throw const FormatException(
          'Binary payload section lengths do not match its byte length.',
        );
      }

      const xStart = _headerLength;
      final yStart = xStart + xLength;
      final sidecarStart = yStart + yLength;
      final sidecarText = utf8.decode(
        Uint8List.sublistView(
          buffer,
          sidecarStart,
          sidecarStart + sidecarLength,
        ),
        allowMalformed: false,
      );
      final decodedSidecar = jsonDecode(sidecarText);
      ChartDataBlobCodec._validateStructure(decodedSidecar, limits, path);
      final sidecar = readStringMap(decodedSidecar, 'binary data sidecar');
      final unsupportedKeys = sidecar.keys.toSet().difference(_sidecarKeys);
      if (unsupportedKeys.isNotEmpty) {
        throw FormatException(
          'Unsupported binary sidecar field: ${unsupportedKeys.first}.',
        );
      }

      final xValues = _decodeNumbers(
        Uint8List.sublistView(buffer, xStart, yStart),
        pointCount,
        '$path.x',
      );
      final yValues = _decodeNumbers(
        Uint8List.sublistView(buffer, yStart, sidecarStart),
        pointCount,
        '$path.y',
      );
      return ChartArtifactSuccess(
        value: InlineColumnarPayload.fromDecodedColumns(
          xValues: xValues,
          yValues: yValues,
          optionalColumns: sidecar,
        ),
      );
    } on _ResolvedPayloadLimitException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message: error.message,
          path: error.path,
        ),
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
          path: path,
        ),
      );
    } on ArgumentError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message?.toString() ?? 'Invalid binary data payload.',
          path: path,
        ),
      );
    }
  }

  static Uint8List _encodeNumbers(List<ChartNumberDocument> values) {
    final output = BytesBuilder(copy: false);
    final bits = ByteData(8);
    var previousHigh = 0;
    var previousLow = 0;
    for (final value in values) {
      bits.setFloat64(0, value.asDouble, Endian.big);
      final high = bits.getUint32(0, Endian.big);
      final low = bits.getUint32(4, Endian.big);
      final xorHigh = high ^ previousHigh;
      final xorLow = low ^ previousLow;
      final encoded = ByteData(8)
        ..setUint32(0, xorHigh, Endian.big)
        ..setUint32(4, xorLow, Endian.big);
      var firstByte = 0;
      while (firstByte < 8 && encoded.getUint8(firstByte) == 0) {
        firstByte++;
      }
      if (firstByte == 8) {
        output.addByte(0);
      } else {
        var lastByte = 7;
        while (lastByte > firstByte && encoded.getUint8(lastByte) == 0) {
          lastByte--;
        }
        final encodedLength = lastByte - firstByte + 1;
        output.addByte((firstByte << 4) | encodedLength);
        output.add(encoded.buffer.asUint8List(firstByte, encodedLength));
      }
      previousHigh = high;
      previousLow = low;
    }
    return output.takeBytes();
  }

  static List<ChartNumberDocument> _decodeNumbers(
    Uint8List bytes,
    int pointCount,
    String path,
  ) {
    var offset = 0;
    var previousHigh = 0;
    var previousLow = 0;
    final bits = ByteData(8);
    final values = List<ChartNumberDocument>.generate(pointCount, (index) {
      if (offset >= bytes.length) {
        throw FormatException(
          'Compressed number stream is truncated at $path.',
        );
      }
      final descriptor = bytes[offset++];
      final firstByte = descriptor >> 4;
      final encodedLength = descriptor & 0x0f;
      if ((encodedLength == 0 && descriptor != 0) ||
          encodedLength > 8 ||
          firstByte + encodedLength > 8 ||
          offset + encodedLength > bytes.length) {
        throw FormatException('Compressed number stream is invalid at $path.');
      }
      final xorBits = ByteData(8);
      for (
        var byteIndex = firstByte;
        byteIndex < firstByte + encodedLength;
        byteIndex++
      ) {
        xorBits.setUint8(byteIndex, bytes[offset++]);
      }
      final high = previousHigh ^ xorBits.getUint32(0, Endian.big);
      final low = previousLow ^ xorBits.getUint32(4, Endian.big);
      bits
        ..setUint32(0, high, Endian.big)
        ..setUint32(4, low, Endian.big);
      final value = ChartNumberDocument.fromDouble(
        bits.getFloat64(0, Endian.big),
      );
      previousHigh = high;
      previousLow = low;
      return value;
    }, growable: false);
    if (offset != bytes.length) {
      throw FormatException(
        'Compressed number stream has trailing bytes at $path.',
      );
    }
    return values;
  }
}
