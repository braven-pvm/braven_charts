import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartComparisonBuilder', () {
    test('uses explicit series mapping and exact-X missing cells', () {
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power-a', [_point(1, 100), _point(2, 0)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('totally-different-id', [
            _point(1, 110),
            _point(3, 50),
          ], unit: 'W'),
        ]),
        match: ChartSeriesMatch(
          semanticKey: 'power',
          seriesIdByInputId: const {
            'baseline': 'power-a',
            'candidate': 'totally-different-id',
          },
        ),
      );

      final model = _success(result).value;
      expect(model.rows.map((row) => row.alignmentX), [1, 2, 3]);
      final aligned = model.rows.first;
      expect(aligned.isAligned, isTrue);
      expect(aligned.valuesByInputId['baseline']?.rawY, 100);
      expect(aligned.valuesByInputId['candidate']?.rawY, 110);
      expect(aligned.deltasByInputId['candidate']?.absolute, 10);
      expect(aligned.deltasByInputId['candidate']?.percentage, 10);
      expect(model.rows[1].valuesByInputId['candidate']?.isMissing, isTrue);
      expect(model.rows[2].valuesByInputId['baseline']?.isMissing, isTrue);
    });

    test('does not calculate deltas across units without a conversion', () {
      final match = ChartSeriesMatch(
        semanticKey: 'power',
        seriesIdByInputId: const {'baseline': 'power', 'candidate': 'power'},
      );
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1, 0.11)], unit: 'kW'),
        ]),
        match: match,
      );

      final success = _success(result);
      final row = success.value.rows.single;
      expect(row.valuesByInputId['baseline']?.rawY, 100);
      expect(row.valuesByInputId['candidate']?.rawY, 0.11);
      expect(row.valuesByInputId['candidate']?.comparisonValue, isNull);
      expect(
        row.deltasByInputId['candidate']?.status,
        ChartComparisonDeltaStatus.incompatibleUnit,
      );
      expect(
        success.warnings.map((warning) => warning.code),
        contains(ChartArtifactDiagnosticCodes.comparisonUnitMismatch),
      );
    });

    test('adds an explicit converted value without replacing the source', () {
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1, 0.11)], unit: 'kW'),
        ]),
        match: ChartSeriesMatch(
          semanticKey: 'power',
          comparisonUnit: 'W',
          seriesIdByInputId: const {'baseline': 'power', 'candidate': 'power'},
          unitConversionsByInputId: const {
            'candidate': ChartComparisonUnitConversion(
              sourceUnit: 'kW',
              targetUnit: 'W',
              scale: 1000,
            ),
          },
        ),
      );

      final value = _success(
        result,
      ).value.rows.single.valuesByInputId['candidate']!;
      final delta = _success(
        result,
      ).value.rows.single.deltasByInputId['candidate']!;
      expect(value.rawY, 0.11);
      expect(value.sourceUnit, 'kW');
      expect(value.comparisonValue, closeTo(110, 0.000001));
      expect(value.comparisonUnit, 'W');
      expect(value.isDerived, isTrue);
      expect(delta.absolute, closeTo(10, 0.000001));
    });

    test('percentage delta against zero is undefined, not infinity', () {
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 0)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1, 10)], unit: 'W'),
        ]),
        match: _sameSeriesMatch(),
      );

      final delta = _success(
        result,
      ).value.rows.single.deltasByInputId['candidate']!;
      expect(delta.absolute, 10);
      expect(delta.percentage, isNull);
      expect(delta.status, ChartComparisonDeltaStatus.baselineZero);
    });

    test('duplicate exact X fails closed until a policy is explicit', () {
      final baseline = _document('baseline-doc', [
        _series('power', [_point(1, 100), _point(1, 101)], unit: 'W'),
      ]);
      final candidate = _document('candidate-doc', [
        _series('power', [_point(1, 110)], unit: 'W'),
      ]);

      final rejected = _compare(
        baseline: baseline,
        candidate: candidate,
        match: _sameSeriesMatch(),
      );
      expect(rejected, isA<ChartArtifactFailure<ChartComparisonModel>>());
      expect(
        (rejected as ChartArtifactFailure<ChartComparisonModel>).error.code,
        ChartArtifactDiagnosticCodes.comparisonDuplicateKey,
      );

      final paired = _compare(
        baseline: baseline,
        candidate: candidate,
        match: _sameSeriesMatch(),
        options: const ChartComparisonOptions(
          baselineInputId: 'baseline',
          duplicatePolicy: ChartComparisonDuplicatePolicy.byOccurrence,
        ),
      );
      final rows = _success(paired).value.rows;
      expect(rows, hasLength(2));
      expect(rows.first.isAligned, isTrue);
      expect(rows.last.valuesByInputId['baseline']?.rawY, 101);
      expect(rows.last.valuesByInputId['candidate']?.isMissing, isTrue);
    });

    test('timestamp tolerance is one-to-one and ties are deterministic', () {
      final anchor = DateTime.utc(2026, 7, 15, 10);
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100, timestamp: anchor)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('power', [
            _point(
              1,
              90,
              timestamp: anchor.subtract(const Duration(milliseconds: 500)),
            ),
            _point(
              2,
              110,
              timestamp: anchor.add(const Duration(milliseconds: 500)),
            ),
          ], unit: 'W'),
        ]),
        match: _sameSeriesMatch(),
        options: const ChartComparisonOptions(
          alignmentPolicy: ChartComparisonAlignmentPolicy.timestampTolerance,
          timestampTolerance: Duration(seconds: 1),
          baselineInputId: 'baseline',
        ),
      );

      final success = _success(result);
      expect(success.value.rows, hasLength(2));
      expect(success.value.rows.first.isAligned, isTrue);
      expect(success.value.rows.first.valuesByInputId['candidate']?.rawY, 90);
      expect(success.value.rows.last.isAligned, isFalse);
      expect(
        success.warnings.map((warning) => warning.code),
        contains(ChartArtifactDiagnosticCodes.comparisonAmbiguousTimestamp),
      );
    });

    test('no-alignment mode preserves every source point independently', () {
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100), _point(2, 101)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1, 110)], unit: 'W'),
        ]),
        match: _sameSeriesMatch(),
        options: const ChartComparisonOptions(
          alignmentPolicy: ChartComparisonAlignmentPolicy.none,
          baselineInputId: 'baseline',
        ),
      );

      final rows = _success(result).value.rows;
      expect(rows, hasLength(3));
      expect(rows.every((row) => !row.isAligned), isTrue);
      expect(
        rows
            .expand((row) => row.valuesByInputId.values)
            .where((value) => !value.isMissing),
        hasLength(3),
      );
    });

    test('incompatible X domains warn and preserve independent rows', () {
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100)], unit: 'W'),
        ], xAxisType: 'value'),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1, 110)], unit: 'W'),
        ], xAxisType: 'datetime'),
        match: _sameSeriesMatch(),
      );

      final success = _success(result);
      expect(success.value.rows, hasLength(2));
      expect(success.value.rows.every((row) => !row.isAligned), isTrue);
      expect(
        success.warnings.map((warning) => warning.code),
        contains(ChartArtifactDiagnosticCodes.comparisonIncompatibleDomain),
      );
    });

    test('exact-X alignment requires and retains explicit X conversion', () {
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100)], unit: 'W'),
        ], xUnit: 's'),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1000, 110)], unit: 'W'),
        ], xUnit: 'ms'),
        match: _sameSeriesMatch(),
        options: const ChartComparisonOptions(
          baselineInputId: 'baseline',
          comparisonXUnit: 's',
          xUnitConversionsByInputId: {
            'candidate': ChartComparisonUnitConversion(
              sourceUnit: 'ms',
              targetUnit: 's',
              scale: 0.001,
            ),
          },
        ),
      );

      final row = _success(result).value.rows.single;
      expect(row.isAligned, isTrue);
      expect(row.alignmentX, 1);
      expect(row.valuesByInputId['baseline']?.rawX, 1);
      expect(row.valuesByInputId['candidate']?.rawX, 1000);
      final export = ChartComparisonExporter.export(_success(result).value);
      expect(
        export.columns
            .firstWhere((column) => column.id == 'alignmentX')
            .isDerived,
        isTrue,
      );
    });

    test('requires referenced payloads to be host-resolved first', () {
      final referenced = _document('candidate-doc', [
        ChartSeriesDocument(
          type: 'line',
          id: 'power',
          unit: 'W',
          data: ReferencedPayload(
            contentType: ChartDataBlobCodec.contentType,
            byteLength: 24,
            checksum: 'sha256:${List.filled(64, '0').join()}',
            pointCount: 1,
            resolverKey: 'candidate-power',
          ),
          requiredCapabilities: const {'series.line'},
        ),
      ]);
      final result = _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100)], unit: 'W'),
        ]),
        candidate: referenced,
        match: _sameSeriesMatch(),
      );

      expect(result, isA<ChartArtifactFailure<ChartComparisonModel>>());
      expect(
        (result as ChartArtifactFailure<ChartComparisonModel>).error.code,
        ChartArtifactDiagnosticCodes.comparisonPayloadUnsupported,
      );
    });

    test('rejects missing and ambiguous explicit mappings', () {
      final baseline = _document('baseline-doc', [
        _series('power', [_point(1, 100)], unit: 'W'),
      ]);
      final candidate = _document('candidate-doc', [
        _series('power', [_point(1, 110)], unit: 'W'),
      ]);
      final missing = _compare(
        baseline: baseline,
        candidate: candidate,
        match: ChartSeriesMatch(
          semanticKey: 'power',
          seriesIdByInputId: const {
            'baseline': 'missing',
            'candidate': 'power',
          },
        ),
      );
      expect(
        (missing as ChartArtifactFailure<ChartComparisonModel>).error.code,
        ChartArtifactDiagnosticCodes.comparisonSeriesNotFound,
      );

      final ambiguous = ChartComparisonBuilder.compare(
        inputs: [
          ChartComparisonInput(
            inputId: 'baseline',
            label: 'Baseline',
            document: baseline,
          ),
          ChartComparisonInput(
            inputId: 'candidate',
            label: 'Candidate',
            document: candidate,
          ),
        ],
        seriesMatches: [
          _sameSeriesMatch(),
          ChartSeriesMatch(
            semanticKey: 'other-power',
            seriesIdByInputId: const {'baseline': 'power'},
          ),
        ],
      );
      expect(
        (ambiguous as ChartArtifactFailure<ChartComparisonModel>).error.code,
        ChartArtifactDiagnosticCodes.comparisonAmbiguousMapping,
      );
    });
  });

  test('comparison export labels every derived column', () {
    final model = _success(
      _compare(
        baseline: _document('baseline-doc', [
          _series('power', [_point(1, 100)], unit: 'W'),
        ]),
        candidate: _document('candidate-doc', [
          _series('power', [_point(1, 110)], unit: 'W'),
        ]),
        match: _sameSeriesMatch(),
      ),
    ).value;

    final export = ChartComparisonExporter.export(model);
    final derived = export.columns.where((column) => column.isDerived);
    expect(derived, isNotEmpty);
    expect(
      derived.every((column) => column.label.contains('[derived]')),
      isTrue,
    );
    expect(export.csv, contains('Candidate · Absolute delta [derived]'));
    expect(export.csv, contains(',100.00,'));
    expect(export.csv, contains(',110.00,'));
  });
}

ChartArtifactResult<ChartComparisonModel> _compare({
  required ChartDocument baseline,
  required ChartDocument candidate,
  required ChartSeriesMatch match,
  ChartComparisonOptions options = const ChartComparisonOptions(
    baselineInputId: 'baseline',
  ),
}) => ChartComparisonBuilder.compare(
  inputs: [
    ChartComparisonInput(
      inputId: 'baseline',
      label: 'Baseline',
      document: baseline,
    ),
    ChartComparisonInput(
      inputId: 'candidate',
      label: 'Candidate',
      document: candidate,
    ),
  ],
  seriesMatches: [match],
  options: options,
);

ChartSeriesMatch _sameSeriesMatch() => ChartSeriesMatch(
  semanticKey: 'power',
  seriesIdByInputId: const {'baseline': 'power', 'candidate': 'power'},
);

ChartSeriesDocument _series(
  String id,
  List<ChartPointDocument> points, {
  String? unit,
}) => ChartSeriesDocument(
  type: 'line',
  id: id,
  name: id,
  unit: unit,
  data: InlinePointPayload(points),
  requiredCapabilities: const {'series.line'},
);

ChartPointDocument _point(double x, double y, {DateTime? timestamp}) =>
    ChartPointDocument(
      x: ChartNumberDocument.fromDouble(x),
      y: ChartNumberDocument.fromDouble(y),
      timestamp: timestamp,
    );

ChartDocument _document(
  String id,
  List<ChartSeriesDocument> series, {
  String xAxisType = 'value',
  String? xUnit,
}) => ChartDocument(
  documentId: id,
  revision: 1,
  series: series,
  xAxis: ChartAxisDocument(
    id: 'x',
    position: 'bottom',
    axisType: xAxisType,
    unit: xUnit,
  ),
  axes: [ChartAxisDocument(id: 'y', position: 'left')],
  theme: _artifactSuccess(
    ChartThemeDocumentCodec.encode(ChartTheme.light),
  ).value,
  interaction: _artifactSuccess(
    ChartInteractionDocumentCodec.encode(const InteractionConfig()),
  ).value,
);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}

ChartArtifactSuccess<T> _artifactSuccess<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
