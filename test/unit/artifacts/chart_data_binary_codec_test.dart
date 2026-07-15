import 'dart:convert';
import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartDataBinaryCodec', () {
    test('matches the stable binary-v1 compatibility fixture', () {
      final fixture =
          jsonDecode(
                File(
                  'test/fixtures/artifacts/chart_data_binary_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final payload = InlineColumnarPayload.fromPoints([
        _point(0, 100),
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(1),
          y: ChartNumberDocument.fromDouble(101.5),
          label: 'finish',
        ),
      ]);
      final blob = _success(ChartDataBinaryCodec.encode(payload)).value;

      expect(ChartDataBinaryCodec.formatVersion, fixture['formatVersion']);
      expect(blob.contentType, fixture['contentType']);
      expect(ChartDataBinaryCodec.compression, fixture['compression']);
      expect(blob.pointCount, fixture['pointCount']);
      expect(blob.checksum, fixture['checksum']);
      expect(base64Encode(blob.bytes), fixture['bytesBase64']);

      final fixtureBytes = base64Decode(fixture['bytesBase64'] as String);
      final decoded = ChartDataBinaryCodec.decode(
        ReferencedPayload(
          contentType: fixture['contentType'] as String,
          byteLength: fixtureBytes.length,
          checksum: fixture['checksum'] as String,
          pointCount: fixture['pointCount'] as int,
          resolverKey: 'fixture/binary-v1',
        ),
        fixtureBytes,
      );
      expect(
        (decoded as ChartArtifactSuccess<InlineChartDataPayload>).value.points
            .map((point) => point.toJson()),
        payload.points.map((point) => point.toJson()),
      );
    });

    test('round-trips exact values and optional columns deterministically', () {
      final points = [
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(double.nan),
          y: ChartNumberDocument.fromDouble(double.infinity),
          timestamp: DateTime.parse('2026-07-15T08:30:00+02:00'),
          label: 'surge',
          metadata: JsonObjectValue({'lap': JsonNumberValue(3)}),
          segmentStyle: JsonObjectValue({'strokeWidth': JsonNumberValue(2.5)}),
          pointStyle: JsonObjectValue({'size': JsonNumberValue(7)}),
          extensions: const {'quality': JsonStringValue('verified')},
        ),
        _point(2, double.negativeInfinity),
        _point(2, 20),
      ];
      final payload = InlineColumnarPayload.fromPoints(points);

      final first = _success(ChartDataBinaryCodec.encode(payload)).value;
      final second = _success(ChartDataBinaryCodec.encode(payload)).value;
      final decoded = ChartDataBinaryCodec.decode(
        first.reference(resolverKey: 'binary/exact'),
        first.bytes,
      );

      expect(first.contentType, ChartDataBinaryCodec.contentType);
      expect(first.bytes, orderedEquals(second.bytes));
      expect(first.checksum, second.checksum);
      expect(ChartDataBinaryCodec.formatVersion, 1);
      expect(ChartDataBinaryCodec.compression, 'xor-significant-bytes-v1');
      expect(decoded, isA<ChartArtifactSuccess<InlineChartDataPayload>>());
      final roundTrip =
          (decoded as ChartArtifactSuccess<InlineChartDataPayload>).value;
      expect(
        roundTrip.points.map((point) => point.toJson()),
        points.map((point) => point.toJson()),
      );
    });

    test('compresses numeric columns below their canonical JSON payload', () {
      final payload = InlineColumnarPayload.fromPoints([
        for (var index = 0; index < 2000; index++)
          _point(index.toDouble(), 180 + index * 0.125),
      ]);
      final jsonBlob = _success(ChartDataBlobCodec.encode(payload)).value;
      final binaryBlob = _success(ChartDataBinaryCodec.encode(payload)).value;

      expect(binaryBlob.byteLength, lessThan(jsonBlob.byteLength * 0.55));
      expect(binaryBlob.pointCount, 2000);
    });

    test(
      'resolves binary content through artifact hydration and table data',
      () async {
        final payload = InlineColumnarPayload.fromPoints([
          _point(1, 241.44),
          _point(2, 252.75),
          _point(3, 263.5),
        ]);
        final blob = _success(ChartDataBinaryCodec.encode(payload)).value;
        final resolver = _MemoryResolver(blob.bytes);
        final resolved = await ChartDataResolution.resolveArtifact(
          _artifact(blob.reference(resolverKey: 'binary/power')),
          resolver: resolver,
        );

        expect(resolved, isA<ChartArtifactSuccess<ChartArtifact>>());
        final artifact =
            (resolved as ChartArtifactSuccess<ChartArtifact>).value;
        expect(resolver.calls, 1);
        expect(
          artifact.document.series.single.data,
          isA<InlineColumnarPayload>(),
        );
        final table = ChartTableModel.fromDocument(artifact.document);
        expect(table.wideRows, hasLength(3));
        expect(table.wideRows.last.cells['power']?.yRaw, 263.5);

        final hydrated =
            await ChartDocumentHydrator.hydrateArtifactWithDataResolver(
              _artifact(blob.reference(resolverKey: 'binary/power')),
              dataResolver: _MemoryResolver(blob.bytes),
            );
        expect(
          hydrated,
          isA<ChartArtifactSuccess<HydratedChartConfiguration>>(),
        );
        expect(
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>)
              .value
              .series
              .single
              .points
              .last
              .y,
          263.5,
        );
      },
    );

    test('fails closed for corrupt headers, counts, and decode limits', () {
      final payload = InlineColumnarPayload.fromPoints([
        _point(1, 10),
        _point(2, 20),
        _point(3, 30),
      ]);
      final blob = _success(ChartDataBinaryCodec.encode(payload)).value;

      final invalidVersion = [...blob.bytes]..[8] = 2;
      final invalidVersionResult = ChartDataBinaryCodec.decode(
        _referenceFor(invalidVersion, blob.pointCount),
        invalidVersion,
      );
      expect(
        (invalidVersionResult as ChartArtifactFailure<InlineChartDataPayload>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );

      final truncated = blob.bytes.sublist(0, blob.bytes.length - 1);
      final truncatedResult = ChartDataBinaryCodec.decode(
        _referenceFor(truncated, blob.pointCount),
        truncated,
      );
      expect(
        (truncatedResult as ChartArtifactFailure<InlineChartDataPayload>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );

      final invalidDescriptor = [...blob.bytes]..[28] = 0x80;
      final invalidDescriptorResult = ChartDataBinaryCodec.decode(
        _referenceFor(invalidDescriptor, blob.pointCount),
        invalidDescriptor,
      );
      expect(
        (invalidDescriptorResult
                as ChartArtifactFailure<InlineChartDataPayload>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );

      final wrongCount = ChartDataBinaryCodec.decode(
        _referenceFor(blob.bytes, blob.pointCount + 1),
        blob.bytes,
      );
      expect(
        (wrongCount as ChartArtifactFailure<InlineChartDataPayload>).error.code,
        ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch,
      );

      final limited = ChartDataBinaryCodec.decode(
        blob.reference(resolverKey: 'binary/limited'),
        blob.bytes,
        limits: const ChartArtifactValidationLimits(maxPoints: 2),
      );
      expect(
        (limited as ChartArtifactFailure<InlineChartDataPayload>).error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
    });

    test('enforces sidecar string and encoded byte limits', () {
      final payload = InlineColumnarPayload.fromPoints([
        ChartPointDocument(
          x: ChartNumberDocument.fromDouble(1),
          y: ChartNumberDocument.fromDouble(2),
          label: 'label-that-exceeds-the-import-limit',
        ),
      ]);
      final blob = _success(ChartDataBinaryCodec.encode(payload)).value;
      final limitedDecode = ChartDataBinaryCodec.decode(
        blob.reference(resolverKey: 'binary/long-label'),
        blob.bytes,
        limits: const ChartArtifactValidationLimits(maxStringLength: 16),
      );
      expect(
        (limitedDecode as ChartArtifactFailure<InlineChartDataPayload>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );

      final limitedEncode = ChartDataBinaryCodec.encode(
        payload,
        limits: ChartArtifactValidationLimits(
          maxDataPayloadBytes: blob.byteLength - 1,
        ),
      );
      expect(
        (limitedEncode as ChartArtifactFailure<ChartDataBlob>).error.code,
        ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
      );
    });
  });
}

ChartPointDocument _point(double x, double y) => ChartPointDocument(
  x: ChartNumberDocument.fromDouble(x),
  y: ChartNumberDocument.fromDouble(y),
);

ReferencedPayload _referenceFor(List<int> bytes, int pointCount) =>
    ReferencedPayload(
      contentType: ChartDataBinaryCodec.contentType,
      byteLength: bytes.length,
      checksum: 'sha256:${sha256.convert(bytes)}',
      pointCount: pointCount,
      resolverKey: 'binary/test',
    );

ChartArtifact _artifact(ChartDataPayload payload) => ChartArtifact(
  artifactId: 'binary-payload-test',
  renderer: const ChartRendererInfo(package: 'braven_charts', version: 'test'),
  createdAt: DateTime.utc(2026, 7, 15),
  document: ChartDocument(
    documentId: 'binary-document',
    revision: 1,
    series: [_seriesDocument(payload)],
    xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
    axes: const [],
    theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
    interaction: _success(
      ChartInteractionDocumentCodec.encode(const InteractionConfig()),
    ).value,
  ),
);

ChartSeriesDocument _seriesDocument(ChartDataPayload payload) {
  final encoded = _success(
    ChartSeriesDocumentCodec.encode(
      const LineChartSeries(
        id: 'power',
        name: 'Power',
        points: [
          ChartDataPoint(x: 1, y: 241.44),
          ChartDataPoint(x: 2, y: 252.75),
          ChartDataPoint(x: 3, y: 263.5),
        ],
      ),
    ),
  ).value;
  final json = encoded.toJson();
  json['data'] = payload.toJson();
  return ChartSeriesDocument.fromJson(json);
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;

class _MemoryResolver implements ChartDataResolver {
  _MemoryResolver(this.bytes);

  final List<int> bytes;
  int calls = 0;

  @override
  Future<ChartArtifactResult<List<int>>> resolve(
    ReferencedPayload reference,
  ) async {
    calls++;
    return ChartArtifactSuccess(value: bytes);
  }
}
