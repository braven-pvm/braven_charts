import 'dart:math' as math;

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_data_payload.dart';
import '../artifacts/chart_view_state.dart';
import '../table/chart_table_model.dart';
import '../table/chart_table_options.dart';
import 'chart_comparison_model.dart';

/// Builds deterministic, source-preserving comparisons from portable documents.
abstract final class ChartComparisonBuilder {
  static ChartArtifactResult<ChartComparisonModel> compare({
    required Iterable<ChartComparisonInput> inputs,
    required Iterable<ChartSeriesMatch> seriesMatches,
    ChartComparisonOptions options = const ChartComparisonOptions(),
  }) {
    final inputList = inputs.toList(growable: false);
    final matchList = seriesMatches.toList(growable: false);
    final validation = _validateInputs(inputList, matchList, options);
    if (validation != null) return validation;

    final warnings = <ChartArtifactWarning>[];
    final tables = <String, ChartTableModel>{};
    for (var index = 0; index < inputList.length; index++) {
      final input = inputList[index];
      try {
        final table = ChartTableModel.fromDocument(
          input.document,
          viewState: input.viewState,
          options: ChartTableOptions(
            rowLayout: ChartTableRowLayout.long,
            includeMetadata: true,
            formatters: options.formatters,
          ),
        );
        tables[input.inputId] = table;
        warnings.addAll(table.warnings);
      } on UnsupportedError catch (error) {
        return _failure(
          ChartArtifactDiagnosticCodes.comparisonPayloadUnsupported,
          'Comparison input ${input.inputId} must contain resolved inline data: $error',
          path: '\$.inputs[$index].document.series',
        );
      } on Object catch (error) {
        return _failure(
          ChartArtifactDiagnosticCodes.comparisonInvalidInput,
          'Comparison input ${input.inputId} could not be projected: $error',
          path: '\$.inputs[$index].document',
        );
      }
    }

    final rows = <ChartComparisonRow>[];
    for (var matchIndex = 0; matchIndex < matchList.length; matchIndex++) {
      final match = matchList[matchIndex];
      final prepared = _prepareMatch(
        inputList,
        tables,
        match,
        matchIndex,
        warnings,
      );
      if (prepared case ChartArtifactFailure<_PreparedMatch>()) {
        return ChartArtifactFailure(
          error: prepared.error,
          warnings: [...warnings, ...prepared.warnings],
        );
      }
      final value = (prepared as ChartArtifactSuccess<_PreparedMatch>).value;
      ChartArtifactResult<List<ChartComparisonRow>> aligned;
      switch (options.alignmentPolicy) {
        case ChartComparisonAlignmentPolicy.none:
          aligned = ChartArtifactSuccess(
            value: _independentRows(inputList, value, options),
          );
        case ChartComparisonAlignmentPolicy.exactX:
          aligned = _exactXRows(
            inputList,
            value,
            options,
            warnings,
            matchIndex,
          );
        case ChartComparisonAlignmentPolicy.timestampTolerance:
          aligned = _timestampRows(
            inputList,
            value,
            options,
            warnings,
            matchIndex,
          );
      }
      if (aligned case ChartArtifactFailure<List<ChartComparisonRow>>()) {
        return ChartArtifactFailure(
          error: aligned.error,
          warnings: [...warnings, ...aligned.warnings],
        );
      }
      rows.addAll(
        (aligned as ChartArtifactSuccess<List<ChartComparisonRow>>).value,
      );
    }

    return ChartArtifactSuccess(
      value: ChartComparisonModel(
        inputs: inputList,
        seriesMatches: matchList,
        options: options,
        rows: rows,
        warnings: warnings,
      ),
      warnings: warnings,
    );
  }
}

ChartArtifactFailure<ChartComparisonModel>? _validateInputs(
  List<ChartComparisonInput> inputs,
  List<ChartSeriesMatch> matches,
  ChartComparisonOptions options,
) {
  if (inputs.length < 2) {
    return _failure(
      ChartArtifactDiagnosticCodes.comparisonInvalidInput,
      'A chart comparison requires at least two inputs.',
      path: r'$.inputs',
    );
  }
  final inputIds = <String>{};
  for (var index = 0; index < inputs.length; index++) {
    if (inputs[index].inputId.isEmpty || inputs[index].label.isEmpty) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'Comparison input IDs and labels cannot be empty.',
        path: '\$.inputs[$index]',
      );
    }
    if (!inputIds.add(inputs[index].inputId)) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'Comparison input IDs must be unique.',
        path: '\$.inputs[$index].inputId',
      );
    }
  }
  if (matches.isEmpty) {
    return _failure(
      ChartArtifactDiagnosticCodes.comparisonInvalidInput,
      'At least one explicit series mapping is required.',
      path: r'$.seriesMatches',
    );
  }
  final semanticKeys = <String>{};
  final sourceMappings = <String, String>{};
  for (var matchIndex = 0; matchIndex < matches.length; matchIndex++) {
    final match = matches[matchIndex];
    if (match.semanticKey.isEmpty) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'Semantic keys cannot be empty.',
        path: '\$.seriesMatches[$matchIndex].semanticKey',
      );
    }
    if (!semanticKeys.add(match.semanticKey)) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonAmbiguousMapping,
        'Semantic keys must be unique.',
        path: '\$.seriesMatches[$matchIndex].semanticKey',
      );
    }
    if (match.seriesIdByInputId.isEmpty) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'Series mapping ${match.semanticKey} is empty.',
        path: '\$.seriesMatches[$matchIndex].seriesIdByInputId',
      );
    }
    if (match.comparisonUnit != null && match.comparisonUnit!.isEmpty) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'comparisonUnit cannot be empty.',
        path: '\$.seriesMatches[$matchIndex].comparisonUnit',
      );
    }
    for (final entry in match.seriesIdByInputId.entries) {
      if (!inputIds.contains(entry.key)) {
        return _failure(
          ChartArtifactDiagnosticCodes.comparisonInvalidInput,
          'Series mapping references unknown input ${entry.key}.',
          path: '\$.seriesMatches[$matchIndex].seriesIdByInputId.${entry.key}',
        );
      }
      if (entry.value.isEmpty) {
        return _failure(
          ChartArtifactDiagnosticCodes.comparisonInvalidInput,
          'Mapped series IDs cannot be empty.',
          path: '\$.seriesMatches[$matchIndex].seriesIdByInputId.${entry.key}',
        );
      }
      final sourceKey = '${entry.key}\u0000${entry.value}';
      final previous = sourceMappings[sourceKey];
      if (previous != null && previous != match.semanticKey) {
        return _failure(
          ChartArtifactDiagnosticCodes.comparisonAmbiguousMapping,
          'Series ${entry.value} in ${entry.key} maps to both $previous and ${match.semanticKey}.',
          path: '\$.seriesMatches[$matchIndex].seriesIdByInputId.${entry.key}',
        );
      }
      sourceMappings[sourceKey] = match.semanticKey;
    }
    for (final entry in match.unitConversionsByInputId.entries) {
      final conversion = entry.value;
      if (!inputIds.contains(entry.key) ||
          !match.seriesIdByInputId.containsKey(entry.key) ||
          conversion.sourceUnit.isEmpty ||
          conversion.targetUnit.isEmpty ||
          !conversion.scale.isFinite ||
          !conversion.offset.isFinite ||
          (match.comparisonUnit != null &&
              conversion.targetUnit != match.comparisonUnit)) {
        return _failure(
          ChartArtifactDiagnosticCodes.comparisonInvalidInput,
          'Unit conversion for ${entry.key} is invalid for ${match.semanticKey}.',
          path:
              '\$.seriesMatches[$matchIndex].unitConversionsByInputId.${entry.key}',
        );
      }
    }
  }
  final baseline = options.baselineInputId;
  if (baseline != null && !inputIds.contains(baseline)) {
    return _failure(
      ChartArtifactDiagnosticCodes.comparisonInvalidInput,
      'Baseline input $baseline is not present.',
      path: r'$.options.baselineInputId',
    );
  }
  if (options.alignmentPolicy ==
      ChartComparisonAlignmentPolicy.timestampTolerance) {
    final tolerance = options.timestampTolerance;
    if (tolerance == null || tolerance <= Duration.zero) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'Timestamp alignment requires a positive timestampTolerance.',
        path: r'$.options.timestampTolerance',
      );
    }
  }
  for (final entry in options.xUnitConversionsByInputId.entries) {
    if (!inputIds.contains(entry.key) ||
        entry.value.sourceUnit.isEmpty ||
        entry.value.targetUnit.isEmpty ||
        !entry.value.scale.isFinite ||
        !entry.value.offset.isFinite) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonInvalidInput,
        'X conversion for ${entry.key} is invalid.',
        path: '\$.options.xUnitConversionsByInputId.${entry.key}',
      );
    }
  }
  if (options.comparisonXUnit != null && options.comparisonXUnit!.isEmpty) {
    return _failure(
      ChartArtifactDiagnosticCodes.comparisonInvalidInput,
      'comparisonXUnit cannot be empty.',
      path: r'$.options.comparisonXUnit',
    );
  }
  return null;
}

ChartArtifactResult<_PreparedMatch> _prepareMatch(
  List<ChartComparisonInput> inputs,
  Map<String, ChartTableModel> tables,
  ChartSeriesMatch match,
  int matchIndex,
  List<ChartArtifactWarning> warnings,
) {
  final sourceUnitByInput = <String, String?>{};
  final rowsByInput = <String, List<ChartTableLongRow>>{};
  for (final input in inputs) {
    final seriesId = match.seriesIdByInputId[input.inputId];
    if (seriesId == null) {
      rowsByInput[input.inputId] = const [];
      continue;
    }
    final seriesIndex = input.document.series.indexWhere(
      (series) => series.id == seriesId,
    );
    if (seriesIndex < 0) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonSeriesNotFound,
        'Series $seriesId was not found in input ${input.inputId}.',
        path:
            '\$.seriesMatches[$matchIndex].seriesIdByInputId.${input.inputId}',
      );
    }
    final series = input.document.series[seriesIndex];
    if (series.data is! InlineChartDataPayload) {
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonPayloadUnsupported,
        'Series $seriesId in ${input.inputId} must be resolved to inline data before comparison.',
        path: '\$.inputs.${input.inputId}.document.series[$seriesIndex].data',
      );
    }
    final table = tables[input.inputId]!;
    final rows = table.longRows
        .where((row) => row.reference.seriesId == seriesId)
        .toList(growable: false);
    rowsByInput[input.inputId] = rows;
    sourceUnitByInput[input.inputId] = table.series
        .firstWhere((column) => column.seriesId == seriesId)
        .unit;
  }

  final mappedUnits = [
    for (final input in inputs)
      if (match.seriesIdByInputId.containsKey(input.inputId))
        sourceUnitByInput[input.inputId],
  ];
  final comparisonUnit =
      match.comparisonUnit ??
      (mappedUnits.toSet().length == 1 ? mappedUnits.first : null);
  final unitMismatch =
      match.comparisonUnit == null && mappedUnits.toSet().length > 1;
  if (unitMismatch) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.comparisonUnitMismatch,
        message:
            'Series mapping ${match.semanticKey} has incompatible units; deltas are unavailable until a comparisonUnit and conversions are supplied.',
        path: '\$.seriesMatches[$matchIndex]',
      ),
    );
  }

  final pointsByInput = <String, List<_SourcePoint>>{};
  for (final input in inputs) {
    final rows = rowsByInput[input.inputId] ?? const [];
    final sourceUnit = sourceUnitByInput[input.inputId];
    var canCompareUnit = !unitMismatch;
    ChartComparisonUnitConversion? conversion;
    if (comparisonUnit != null && sourceUnit != comparisonUnit) {
      conversion = match.unitConversionsByInputId[input.inputId];
      if (conversion == null ||
          conversion.sourceUnit != sourceUnit ||
          conversion.targetUnit != comparisonUnit ||
          !conversion.scale.isFinite ||
          !conversion.offset.isFinite) {
        canCompareUnit = false;
        if (match.seriesIdByInputId.containsKey(input.inputId)) {
          warnings.add(
            ChartArtifactWarning(
              code: ChartArtifactDiagnosticCodes.comparisonUnitMismatch,
              message:
                  'Input ${input.inputId} uses ${sourceUnit ?? 'no unit'}; an explicit conversion to $comparisonUnit is required for deltas.',
              path:
                  '\$.seriesMatches[$matchIndex].unitConversionsByInputId.${input.inputId}',
            ),
          );
        }
      }
    }
    final points = <_SourcePoint>[];
    var nonFiniteConversion = false;
    for (final row in rows) {
      double? comparisonValue;
      if (row.isValid && canCompareUnit) {
        comparisonValue = conversion?.convert(row.yRaw) ?? row.yRaw;
        if (!comparisonValue.isFinite) {
          comparisonValue = null;
          nonFiniteConversion = true;
        }
      }
      points.add(
        _SourcePoint(
          input: input,
          semanticKey: match.semanticKey,
          row: row,
          sourceUnit: sourceUnit,
          comparisonValue: comparisonValue,
          comparisonUnit: comparisonUnit,
          valueDerived: conversion != null && canCompareUnit,
        ),
      );
    }
    if (nonFiniteConversion) {
      warnings.add(
        ChartArtifactWarning(
          code: ChartArtifactDiagnosticCodes.comparisonUnitMismatch,
          message:
              'Unit conversion for ${input.inputId} produced a non-finite value; affected deltas are unavailable.',
          path:
              '\$.seriesMatches[$matchIndex].unitConversionsByInputId.${input.inputId}',
        ),
      );
    }
    pointsByInput[input.inputId] = points;
  }
  return ChartArtifactSuccess(
    value: _PreparedMatch(match: match, pointsByInput: pointsByInput),
  );
}

ChartArtifactResult<List<ChartComparisonRow>> _exactXRows(
  List<ChartComparisonInput> inputs,
  _PreparedMatch prepared,
  ChartComparisonOptions options,
  List<ChartArtifactWarning> warnings,
  int matchIndex,
) {
  final mappedInputs = inputs
      .where(
        (input) => prepared.match.seriesIdByInputId.containsKey(input.inputId),
      )
      .toList(growable: false);
  final axisTypes = mappedInputs
      .map((input) => input.document.xAxis.axisType)
      .toSet();
  if (axisTypes.length > 1) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.comparisonIncompatibleDomain,
        message:
            'Series mapping ${prepared.match.semanticKey} uses incompatible X domains; rows remain unaligned.',
        path: '\$.seriesMatches[$matchIndex]',
      ),
    );
    return ChartArtifactSuccess(
      value: _independentRows(inputs, prepared, options),
    );
  }

  final xConversions = <String, ChartComparisonUnitConversion?>{};
  final xUnits = {for (final input in mappedInputs) input.document.xAxis.unit};
  if (options.comparisonXUnit == null && xUnits.length > 1) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.comparisonIncompatibleDomain,
        message:
            'Series mapping ${prepared.match.semanticKey} uses incompatible X units; rows remain unaligned.',
        path: '\$.seriesMatches[$matchIndex]',
      ),
    );
    return ChartArtifactSuccess(
      value: _independentRows(inputs, prepared, options),
    );
  }
  for (final input in mappedInputs) {
    final sourceUnit = input.document.xAxis.unit;
    final targetUnit = options.comparisonXUnit;
    if (targetUnit == null || sourceUnit == targetUnit) {
      xConversions[input.inputId] = null;
      continue;
    }
    final conversion = options.xUnitConversionsByInputId[input.inputId];
    if (conversion == null ||
        conversion.sourceUnit != sourceUnit ||
        conversion.targetUnit != targetUnit ||
        !conversion.scale.isFinite ||
        !conversion.offset.isFinite) {
      warnings.add(
        ChartArtifactWarning(
          code: ChartArtifactDiagnosticCodes.comparisonIncompatibleDomain,
          message:
              'Input ${input.inputId} requires an explicit X conversion from ${sourceUnit ?? 'no unit'} to $targetUnit; rows remain unaligned.',
          path: '\$.options.xUnitConversionsByInputId.${input.inputId}',
        ),
      );
      return ChartArtifactSuccess(
        value: _independentRows(inputs, prepared, options),
      );
    }
    xConversions[input.inputId] = conversion;
  }

  final groups = <double, Map<String, List<_SourcePoint>>>{};
  final invalid = <_SourcePoint>[];
  var invalidConvertedX = false;
  for (final input in inputs) {
    for (final point in prepared.pointsByInput[input.inputId] ?? const []) {
      final convertedX =
          xConversions[input.inputId]?.convert(point.row.xRaw) ??
          point.row.xRaw;
      if (!convertedX.isFinite) {
        invalid.add(point);
        if (point.row.xRaw.isFinite) invalidConvertedX = true;
        continue;
      }
      final key = convertedX == 0 ? 0.0 : convertedX;
      groups
          .putIfAbsent(key, () => <String, List<_SourcePoint>>{})
          .putIfAbsent(input.inputId, () => <_SourcePoint>[])
          .add(point);
    }
  }

  if (invalidConvertedX) {
    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.comparisonIncompatibleDomain,
        message:
            'An X conversion for ${prepared.match.semanticKey} produced a non-finite value; affected rows remain unaligned.',
        path: '\$.seriesMatches[$matchIndex]',
      ),
    );
  }

  final output = <ChartComparisonRow>[];
  final sortedKeys = groups.keys.toList()..sort();
  for (final x in sortedKeys) {
    final byInput = groups[x]!;
    final duplicates = byInput.entries.where((entry) => entry.value.length > 1);
    if (duplicates.isNotEmpty &&
        options.duplicatePolicy == ChartComparisonDuplicatePolicy.reject) {
      final duplicate = duplicates.first;
      return _failure(
        ChartArtifactDiagnosticCodes.comparisonDuplicateKey,
        'Input ${duplicate.key} has duplicate X value $x for ${prepared.match.semanticKey}; choose an explicit duplicate policy.',
        path: '\$.seriesMatches[$matchIndex]',
      );
    }

    switch (options.duplicatePolicy) {
      case ChartComparisonDuplicatePolicy.reject:
      case ChartComparisonDuplicatePolicy.byOccurrence:
        final count = byInput.values.fold<int>(
          0,
          (current, values) => math.max(current, values.length),
        );
        for (var occurrence = 0; occurrence < count; occurrence++) {
          output.add(
            _comparisonRow(
              inputs,
              prepared.match.semanticKey,
              options,
              rowId:
                  '${Uri.encodeComponent(prepared.match.semanticKey)}:x:$x:$occurrence',
              occurrence: occurrence,
              alignmentX: x,
              pointsByInput: {
                for (final input in inputs)
                  if ((byInput[input.inputId]?.length ?? 0) > occurrence)
                    input.inputId: byInput[input.inputId]![occurrence],
              },
            ),
          );
        }
      case ChartComparisonDuplicatePolicy.keepFirst:
      case ChartComparisonDuplicatePolicy.keepLast:
        final keepLast =
            options.duplicatePolicy == ChartComparisonDuplicatePolicy.keepLast;
        final selected = <String, _SourcePoint>{};
        final dropped = <_SourcePoint>[];
        for (final entry in byInput.entries) {
          selected[entry.key] = keepLast ? entry.value.last : entry.value.first;
          if (entry.value.length > 1) {
            final extras = keepLast
                ? entry.value.take(entry.value.length - 1)
                : entry.value.skip(1);
            dropped.addAll(extras);
            warnings.add(
              ChartArtifactWarning(
                code: ChartArtifactDiagnosticCodes.comparisonDuplicateKey,
                message:
                    'Input ${entry.key} has ${entry.value.length} values at X $x; ${keepLast ? 'last' : 'first'} was aligned and the rest remain independent.',
                path: '\$.seriesMatches[$matchIndex]',
              ),
            );
          }
        }
        output.add(
          _comparisonRow(
            inputs,
            prepared.match.semanticKey,
            options,
            rowId:
                '${Uri.encodeComponent(prepared.match.semanticKey)}:x:$x:chosen',
            alignmentX: x,
            pointsByInput: selected,
          ),
        );
        for (final point in dropped) {
          output.add(
            _independentRow(inputs, prepared.match.semanticKey, point, options),
          );
        }
    }
  }
  for (final point in invalid) {
    output.add(
      _independentRow(inputs, prepared.match.semanticKey, point, options),
    );
  }
  return ChartArtifactSuccess(value: output);
}

ChartArtifactResult<List<ChartComparisonRow>> _timestampRows(
  List<ChartComparisonInput> inputs,
  _PreparedMatch prepared,
  ChartComparisonOptions options,
  List<ChartArtifactWarning> warnings,
  int matchIndex,
) {
  final tolerance = options.timestampTolerance!;
  final timestampedByInput = <String, List<_SourcePoint>>{};
  final withoutTimestamp = <_SourcePoint>[];
  for (final input in inputs) {
    final all = prepared.pointsByInput[input.inputId] ?? const [];
    final timestamped =
        all.where((point) => point.row.timestamp != null).toList()
          ..sort(_compareTimestampedPoints);
    timestampedByInput[input.inputId] = timestamped;
    final missing = all.where((point) => point.row.timestamp == null).toList();
    withoutTimestamp.addAll(missing);
    if (missing.isNotEmpty) {
      warnings.add(
        ChartArtifactWarning(
          code: ChartArtifactDiagnosticCodes.comparisonMissingTimestamp,
          message:
              '${missing.length} points in ${input.inputId} have no timestamp and remain unaligned.',
          path: '\$.seriesMatches[$matchIndex]',
        ),
      );
    }
  }

  final mappedInputIds = [
    for (final input in inputs)
      if (prepared.match.seriesIdByInputId.containsKey(input.inputId))
        input.inputId,
  ];
  final requestedBaseline = options.baselineInputId;
  final anchorId =
      requestedBaseline != null && mappedInputIds.contains(requestedBaseline)
      ? requestedBaseline
      : mappedInputIds.first;
  final used = <_SourcePoint>{};
  final output = <ChartComparisonRow>[];
  for (final anchor in timestampedByInput[anchorId] ?? const []) {
    used.add(anchor);
    final selected = <String, _SourcePoint>{anchorId: anchor};
    for (final inputId in mappedInputIds) {
      if (inputId == anchorId) continue;
      final candidates =
          (timestampedByInput[inputId] ?? const [])
              .where((candidate) => !used.contains(candidate))
              .map(
                (candidate) => (
                  point: candidate,
                  distance: candidate.row.timestamp!
                      .difference(anchor.row.timestamp!)
                      .abs(),
                ),
              )
              .where((candidate) => candidate.distance <= tolerance)
              .toList()
            ..sort((left, right) {
              final byDistance = left.distance.compareTo(right.distance);
              if (byDistance != 0) return byDistance;
              return _compareTimestampedPoints(left.point, right.point);
            });
      if (candidates.isEmpty) continue;
      final chosen = candidates.first;
      final tied = candidates
          .where((candidate) => candidate.distance == chosen.distance)
          .length;
      if (tied > 1) {
        warnings.add(
          ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.comparisonAmbiguousTimestamp,
            message:
                '$tied points in $inputId are equally close to ${anchor.row.timestamp!.toIso8601String()}; earlier timestamp then point index wins.',
            path: '\$.seriesMatches[$matchIndex]',
          ),
        );
      }
      selected[inputId] = chosen.point;
      used.add(chosen.point);
    }
    output.add(
      _comparisonRow(
        inputs,
        prepared.match.semanticKey,
        options,
        rowId:
            '${Uri.encodeComponent(prepared.match.semanticKey)}:time:${anchor.row.timestamp!.microsecondsSinceEpoch}:${anchor.row.reference.pointIndex}',
        alignmentTimestamp: anchor.row.timestamp,
        pointsByInput: selected,
      ),
    );
  }

  for (final inputId in mappedInputIds) {
    for (final point in timestampedByInput[inputId] ?? const []) {
      if (!used.contains(point)) {
        output.add(
          _independentRow(inputs, prepared.match.semanticKey, point, options),
        );
      }
    }
  }
  for (final point in withoutTimestamp) {
    output.add(
      _independentRow(inputs, prepared.match.semanticKey, point, options),
    );
  }
  output.sort((left, right) {
    final leftTime = left.alignmentTimestamp;
    final rightTime = right.alignmentTimestamp;
    if (leftTime == null && rightTime == null) {
      return left.rowId.compareTo(right.rowId);
    }
    if (leftTime == null) return 1;
    if (rightTime == null) return -1;
    final byTime = leftTime.compareTo(rightTime);
    return byTime != 0 ? byTime : left.rowId.compareTo(right.rowId);
  });
  return ChartArtifactSuccess(value: output);
}

List<ChartComparisonRow> _independentRows(
  List<ChartComparisonInput> inputs,
  _PreparedMatch prepared,
  ChartComparisonOptions options,
) => [
  for (final input in inputs)
    for (final point in prepared.pointsByInput[input.inputId] ?? const [])
      _independentRow(inputs, prepared.match.semanticKey, point, options),
];

ChartComparisonRow _independentRow(
  List<ChartComparisonInput> inputs,
  String semanticKey,
  _SourcePoint point,
  ChartComparisonOptions options,
) => _comparisonRow(
  inputs,
  semanticKey,
  options,
  rowId:
      '${Uri.encodeComponent(semanticKey)}:source:${Uri.encodeComponent(point.input.inputId)}:${Uri.encodeComponent(point.row.reference.seriesId)}:${point.row.reference.pointIndex}',
  alignmentX: point.row.xRaw,
  alignmentTimestamp: point.row.timestamp,
  pointsByInput: {point.input.inputId: point},
  forceUnaligned: true,
);

ChartComparisonRow _comparisonRow(
  List<ChartComparisonInput> inputs,
  String semanticKey,
  ChartComparisonOptions options, {
  required String rowId,
  required Map<String, _SourcePoint> pointsByInput,
  double? alignmentX,
  DateTime? alignmentTimestamp,
  int occurrence = 0,
  bool forceUnaligned = false,
}) {
  final values = <String, ChartComparisonValue>{};
  for (final input in inputs) {
    final point = pointsByInput[input.inputId];
    values[input.inputId] = point == null
        ? ChartComparisonValue(
            inputId: input.inputId,
            inputLabel: input.label,
            semanticKey: semanticKey,
            isMissing: true,
            isValid: false,
            isDerived: false,
            hiddenInSource: false,
          )
        : point.toValue();
  }
  final deltas = _buildDeltas(values, options.baselineInputId);
  return ChartComparisonRow(
    rowId: rowId,
    semanticKey: semanticKey,
    isAligned: !forceUnaligned && pointsByInput.length > 1,
    alignmentX: alignmentX,
    alignmentTimestamp: alignmentTimestamp,
    occurrence: occurrence,
    valuesByInputId: values,
    deltasByInputId: deltas,
  );
}

Map<String, ChartComparisonDelta> _buildDeltas(
  Map<String, ChartComparisonValue> values,
  String? baselineInputId,
) {
  if (baselineInputId == null) return const {};
  final baseline = values[baselineInputId]!;
  final output = <String, ChartComparisonDelta>{};
  for (final entry in values.entries) {
    final inputId = entry.key;
    final current = entry.value;
    if (inputId == baselineInputId) {
      output[inputId] = ChartComparisonDelta(
        inputId: inputId,
        baselineInputId: baselineInputId,
        status: baseline.isMissing
            ? ChartComparisonDeltaStatus.missingValue
            : !baseline.isValid
            ? ChartComparisonDeltaStatus.invalidValue
            : baseline.comparisonValue == null
            ? ChartComparisonDeltaStatus.incompatibleUnit
            : ChartComparisonDeltaStatus.baseline,
      );
      continue;
    }
    if (baseline.isMissing || current.isMissing) {
      output[inputId] = ChartComparisonDelta(
        inputId: inputId,
        baselineInputId: baselineInputId,
        status: ChartComparisonDeltaStatus.missingValue,
      );
      continue;
    }
    if (!baseline.isValid || !current.isValid) {
      output[inputId] = ChartComparisonDelta(
        inputId: inputId,
        baselineInputId: baselineInputId,
        status: ChartComparisonDeltaStatus.invalidValue,
      );
      continue;
    }
    final baselineValue = baseline.comparisonValue;
    final currentValue = current.comparisonValue;
    if (baselineValue == null || currentValue == null) {
      output[inputId] = ChartComparisonDelta(
        inputId: inputId,
        baselineInputId: baselineInputId,
        status: ChartComparisonDeltaStatus.incompatibleUnit,
      );
      continue;
    }
    final absolute = currentValue - baselineValue;
    output[inputId] = ChartComparisonDelta(
      inputId: inputId,
      baselineInputId: baselineInputId,
      absolute: absolute,
      percentage: baselineValue == 0 ? null : absolute / baselineValue * 100,
      status: baselineValue == 0
          ? ChartComparisonDeltaStatus.baselineZero
          : ChartComparisonDeltaStatus.available,
    );
  }
  return output;
}

int _compareTimestampedPoints(_SourcePoint left, _SourcePoint right) {
  final byTime = left.row.timestamp!.compareTo(right.row.timestamp!);
  if (byTime != 0) return byTime;
  return left.row.reference.pointIndex.compareTo(
    right.row.reference.pointIndex,
  );
}

ChartArtifactFailure<T> _failure<T>(
  String code,
  String message, {
  String? path,
}) => ChartArtifactFailure(
  error: ChartArtifactError(code: code, message: message, path: path),
);

final class _PreparedMatch {
  const _PreparedMatch({required this.match, required this.pointsByInput});

  final ChartSeriesMatch match;
  final Map<String, List<_SourcePoint>> pointsByInput;
}

final class _SourcePoint {
  const _SourcePoint({
    required this.input,
    required this.semanticKey,
    required this.row,
    required this.sourceUnit,
    required this.comparisonValue,
    required this.comparisonUnit,
    required this.valueDerived,
  });

  final ChartComparisonInput input;
  final String semanticKey;
  final ChartTableLongRow row;
  final String? sourceUnit;
  final double? comparisonValue;
  final String? comparisonUnit;
  final bool valueDerived;

  ChartComparisonValue toValue() => ChartComparisonValue(
    inputId: input.inputId,
    inputLabel: input.label,
    semanticKey: semanticKey,
    sourceSeriesId: row.reference.seriesId,
    reference: ChartPointRef(
      seriesId: row.reference.seriesId,
      pointIndex: row.reference.pointIndex,
    ),
    rawX: row.xRaw,
    xDisplay: row.xDisplay,
    rawY: row.yRaw,
    yDisplay: row.yDisplay,
    timestamp: row.timestamp,
    sourceUnit: sourceUnit,
    comparisonValue: comparisonValue,
    comparisonUnit: comparisonUnit,
    isMissing: false,
    isValid: row.isValid,
    isDerived: valueDerived,
    hiddenInSource: row.hiddenSeries,
  );
}
