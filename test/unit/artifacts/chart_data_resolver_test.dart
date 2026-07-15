import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('referenced chart data', () {
    test('encodes a deterministic immutable blob and wire manifest', () {
      final blob = _blob();
      final reference = blob.reference(
        uri: Uri.parse('content://sha256/power-data'),
      );
      final roundTrip = ChartDataPayload.fromJson(reference.toJson());

      expect(blob.contentType, ChartDataBlobCodec.contentType);
      expect(blob.checksum, startsWith('sha256:'));
      expect(blob.checksum, hasLength(71));
      expect(() => blob.bytes.add(0), throwsUnsupportedError);
      expect(roundTrip, isA<ReferencedPayload>());
      expect(roundTrip.pointCount, 3);
      expect((roundTrip as ReferencedPayload).uri?.scheme, 'content');
      expect(roundTrip.resolverKey, isNull);
      expect(
        () => blob.reference(
          resolverKey: 'ambiguous',
          uri: Uri.parse('content://sha256/power-data'),
        ),
        throwsArgumentError,
      );
      expect(
        () => blob.reference(
          resolverKey: '   ',
          uri: Uri.parse('content://sha256/power-data'),
        ),
        throwsArgumentError,
      );
    });

    test(
      'resolves once, hydrates, and projects through the native table',
      () async {
        final blob = _blob();
        final reference = blob.reference(resolverKey: 'activity/power');
        final artifact = _artifact(
          [reference, reference],
          ids: ['power', 'copy'],
        );
        final resolver = _MemoryResolver(blob.bytes);

        final resolved = await ChartDataResolution.resolveArtifact(
          artifact,
          resolver: resolver,
        );

        expect(resolved, isA<ChartArtifactSuccess<ChartArtifact>>());
        final resolvedArtifact =
            (resolved as ChartArtifactSuccess<ChartArtifact>).value;
        expect(resolver.calls, 1);
        expect(
          resolvedArtifact.document.series.map((series) => series.data),
          everyElement(isA<InlineColumnarPayload>()),
        );
        final table = ChartTableModel.fromDocument(resolvedArtifact.document);
        expect(table.wideRows, hasLength(3));
        expect(table.wideRows.last.cells['power']?.yRaw, 30);

        final encoded = _success(ChartArtifactJsonCodec.encode(artifact)).value;
        final hydrationResolver = _MemoryResolver(blob.bytes);
        final hydrated =
            await ChartDocumentHydrator.hydrateJsonWithDataResolver(
              encoded,
              dataResolver: hydrationResolver,
            );
        if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
          fail(
            '${hydrated.error.code}: ${hydrated.error.message} '
            'at ${hydrated.error.path}',
          );
        }
        expect(
          hydrated,
          isA<ChartArtifactSuccess<HydratedChartConfiguration>>(),
        );
        final configuration =
            (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>)
                .value;
        expect(configuration.series, hasLength(2));
        expect(configuration.series.first.points.last.y, 30);
        expect(hydrationResolver.calls, 1);
      },
    );

    test('rejects byte, checksum, and point-count mismatches', () async {
      final blob = _blob();
      final wrongLength = ReferencedPayload(
        contentType: blob.contentType,
        byteLength: blob.byteLength + 1,
        checksum: blob.checksum,
        pointCount: blob.pointCount,
        resolverKey: 'length',
      );
      final wrongChecksum = ReferencedPayload(
        contentType: blob.contentType,
        byteLength: blob.byteLength,
        checksum: '${blob.checksum.substring(0, 70)}0',
        pointCount: blob.pointCount,
        resolverKey: 'checksum',
      );
      final wrongCount = ReferencedPayload(
        contentType: blob.contentType,
        byteLength: blob.byteLength,
        checksum: blob.checksum,
        pointCount: blob.pointCount + 1,
        resolverKey: 'count',
      );

      for (final reference in [wrongLength, wrongChecksum, wrongCount]) {
        final result = await ChartDataResolution.resolveArtifact(
          _artifact([reference]),
          resolver: _MemoryResolver(blob.bytes),
        );
        expect(result, isA<ChartArtifactFailure<ChartArtifact>>());
        expect(
          (result as ChartArtifactFailure<ChartArtifact>).error.code,
          ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch,
        );
      }
    });

    test('returns structured failures for malformed bytes and blob limits', () {
      final invalidBytes = ReferencedPayload(
        contentType: ChartDataBlobCodec.contentType,
        byteLength: 1,
        checksum:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        pointCount: 0,
        resolverKey: 'invalid-bytes',
      );
      final invalidResult = ChartDataBlobCodec.decode(invalidBytes, const [-1]);
      expect(
        (invalidResult as ChartArtifactFailure<InlineChartDataPayload>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
      final oversizedEncode = ChartDataBlobCodec.encode(
        InlinePointPayload([_point(1, 2)]),
        limits: const ChartArtifactValidationLimits(maxDataPayloadBytes: 1),
      );
      expect(
        (oversizedEncode as ChartArtifactFailure<ChartDataBlob>).error.code,
        ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
      );

      final longLabelBlob = _success(
        ChartDataBlobCodec.encode(
          InlinePointPayload([
            ChartPointDocument(
              x: ChartNumberDocument.fromDouble(1),
              y: ChartNumberDocument.fromDouble(2),
              label: 'label-that-exceeds-the-resolved-limit',
            ),
          ]),
        ),
      ).value;
      final limitedResult = ChartDataBlobCodec.decode(
        longLabelBlob.reference(resolverKey: 'limited-label'),
        longLabelBlob.bytes,
        limits: const ChartArtifactValidationLimits(maxStringLength: 16),
      );
      expect(
        (limitedResult as ChartArtifactFailure<InlineChartDataPayload>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
    });

    test('applies manifest limits before invoking the host resolver', () async {
      final blob = _blob();
      final resolver = _MemoryResolver(blob.bytes);
      final result = await ChartDataResolution.resolveArtifact(
        _artifact([blob.reference(resolverKey: 'too-large')]),
        resolver: resolver,
        limits: ChartArtifactValidationLimits(
          maxDataPayloadBytes: blob.byteLength - 1,
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartArtifact>>());
      expect(
        (result as ChartArtifactFailure<ChartArtifact>).error.code,
        ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
      );
      expect(resolver.calls, 0);

      final unsupportedResolver = _MemoryResolver(blob.bytes);
      final unsupported = await ChartDataResolution.resolveArtifact(
        _artifact([
          ReferencedPayload(
            contentType: 'application/octet-stream',
            byteLength: blob.byteLength,
            checksum: blob.checksum,
            pointCount: blob.pointCount,
            resolverKey: 'unsupported-content',
          ),
        ]),
        resolver: unsupportedResolver,
      );
      expect(
        (unsupported as ChartArtifactFailure<ChartArtifact>).error.code,
        ChartArtifactDiagnosticCodes.unsupportedDataPayloadContentType,
      );
      expect(unsupportedResolver.calls, 0);
    });

    test(
      'resolves nested legend data and preflights aggregate bytes',
      () async {
        final blob = _blob();
        final reference = blob.reference(resolverKey: 'shared-nested-data');
        final artifact = _artifact(
          [reference],
          annotations: [_legendWithPayload(reference)],
        );
        final limitedResolver = _MemoryResolver(blob.bytes);
        final limited = await ChartDataResolution.resolveArtifact(
          artifact,
          resolver: limitedResolver,
          limits: ChartArtifactValidationLimits(
            maxTotalDataPayloadBytes: blob.byteLength * 2 - 1,
          ),
        );
        expect(
          (limited as ChartArtifactFailure<ChartArtifact>).error.code,
          ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
        );
        expect(limitedResolver.calls, 0);

        final resolver = _MemoryResolver(blob.bytes);
        final resolved =
            await ChartDataResolution.resolveArtifact(
                  artifact,
                  resolver: resolver,
                )
                as ChartArtifactSuccess<ChartArtifact>;
        final decodedLegend =
            ChartAnnotationDocumentCodec.decode(
                  resolved.value.document.annotations.single,
                )
                as ChartArtifactSuccess<ChartAnnotation>;
        final legend = decodedLegend.value as LegendAnnotation;

        expect(resolver.calls, 1);
        expect(legend.series.single.points, hasLength(3));
        expect(legend.series.single.points.last.y, 30);
      },
    );

    test('rejects invalid locators and hashes during envelope decode', () {
      final blob = _blob();
      final artifact = _artifact([
        blob.reference(resolverKey: 'valid-reference'),
      ]);
      final root =
          jsonDecode(_success(ChartArtifactJsonCodec.encode(artifact)).value)
              as Map<String, dynamic>;
      final document = root['document'] as Map<String, dynamic>;
      final series = document['series'] as List<dynamic>;
      final data =
          (series.single as Map<String, dynamic>)['data']
              as Map<String, dynamic>;

      data['checksum'] = 'sha256:not-a-digest';
      final invalidHash = ChartArtifactJsonCodec.decode(jsonEncode(root));
      expect(
        (invalidHash as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );

      data['checksum'] = blob.checksum;
      data.remove('resolverKey');
      data['uri'] = 'relative/path';
      final invalidUri = ChartArtifactJsonCodec.decode(jsonEncode(root));
      expect(
        (invalidUri as ChartArtifactFailure<ChartArtifactDecodeResult>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
    });

    test('propagates host failures and wraps thrown resolver errors', () async {
      final blob = _blob();
      final artifact = _artifact([
        blob.reference(resolverKey: 'protected-data'),
      ]);
      final denied = await ChartDataResolution.resolveArtifact(
        artifact,
        resolver: _DeniedResolver(),
      );
      expect(
        (denied as ChartArtifactFailure<ChartArtifact>).error.code,
        'host_data_access_denied',
      );

      final thrown = await ChartDataResolution.resolveArtifact(
        artifact,
        resolver: _ThrowingResolver(),
      );
      expect(
        (thrown as ChartArtifactFailure<ChartArtifact>).error.code,
        ChartArtifactDiagnosticCodes.dataPayloadResolutionFailed,
      );
    });
  });
}

ChartDataBlob _blob() => _success(
  ChartDataBlobCodec.encode(
    InlineColumnarPayload.fromPoints([
      _point(1, 10),
      _point(2, 20),
      _point(3, 30),
    ]),
  ),
).value;

ChartPointDocument _point(double x, double y) => ChartPointDocument(
  x: ChartNumberDocument.fromDouble(x),
  y: ChartNumberDocument.fromDouble(y),
);

ChartArtifact _artifact(
  List<ChartDataPayload> payloads, {
  List<String>? ids,
  List<ChartAnnotationDocument> annotations = const [],
}) => ChartArtifact(
  artifactId: 'referenced-data-test',
  renderer: const ChartRendererInfo(package: 'braven_charts', version: 'test'),
  createdAt: DateTime.utc(2026, 7, 15),
  document: ChartDocument(
    documentId: 'referenced-document',
    revision: 1,
    series: [
      for (var index = 0; index < payloads.length; index++)
        _seriesDocument(ids?[index] ?? 'power-$index', payloads[index]),
    ],
    xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
    axes: const [],
    annotations: annotations,
    theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
    interaction: _success(
      ChartInteractionDocumentCodec.encode(const InteractionConfig()),
    ).value,
  ),
);

ChartAnnotationDocument _legendWithPayload(ChartDataPayload payload) {
  final encoded = _success(
    ChartAnnotationDocumentCodec.encode(
      LegendAnnotation(
        series: const [
          LineChartSeries(
            id: 'nested-power',
            points: [
              ChartDataPoint(x: 1, y: 10),
              ChartDataPoint(x: 2, y: 20),
              ChartDataPoint(x: 3, y: 30),
            ],
          ),
        ],
      ),
    ),
  ).value;
  final json = encoded.toJson();
  final annotationPayload = json['payload']! as Map<String, Object?>;
  final series = annotationPayload['series']! as List<Object?>;
  final nestedSeries = series.single! as Map<String, Object?>;
  nestedSeries['data'] = payload.toJson();
  return ChartAnnotationDocument.fromJson(json);
}

ChartSeriesDocument _seriesDocument(String id, ChartDataPayload payload) {
  final encoded = _success(
    ChartSeriesDocumentCodec.encode(
      LineChartSeries(
        id: id,
        name: id,
        points: const [
          ChartDataPoint(x: 1, y: 10),
          ChartDataPoint(x: 2, y: 20),
          ChartDataPoint(x: 3, y: 30),
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

class _DeniedResolver implements ChartDataResolver {
  @override
  Future<ChartArtifactResult<List<int>>> resolve(
    ReferencedPayload reference,
  ) async => ChartArtifactFailure(
    error: const ChartArtifactError(
      code: 'host_data_access_denied',
      message: 'The host did not authorize this resolver key.',
    ),
  );
}

class _ThrowingResolver implements ChartDataResolver {
  @override
  Future<ChartArtifactResult<List<int>>> resolve(ReferencedPayload reference) =>
      throw StateError('resolver offline');
}
