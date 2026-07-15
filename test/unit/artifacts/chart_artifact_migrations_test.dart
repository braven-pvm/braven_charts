import 'dart:convert';
import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('artifact migrations', () {
    test(
      'migrates the checked-in legacy fixture before model construction',
      () {
        final fixture = File(
          'test/fixtures/artifacts/schema_v0_legacy.json',
        ).readAsStringSync();
        final source = jsonDecode(fixture) as Map<String, dynamic>;

        final withoutMigration = ChartArtifactJsonCodec.decode(fixture);
        expect(
          (withoutMigration as ChartArtifactFailure<ChartArtifactDecodeResult>)
              .error
              .code,
          ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
        );

        final migrated = ChartArtifactJsonCodec.decode(
          fixture,
          migrations: [_LegacyV0ToV1Migration()],
        );
        expect(
          migrated,
          isA<ChartArtifactSuccess<ChartArtifactDecodeResult>>(),
        );
        final result =
            (migrated as ChartArtifactSuccess<ChartArtifactDecodeResult>).value;
        expect(result.sourceSchemaVersion, 0);
        expect(result.migratedSchemaVersion, 1);
        expect(result.migrationsApplied, ['v0->v1']);
        expect(result.artifact.artifactId, 'artifact-fixture-legacy');
        expect(result.artifact.document.revision, 3);
        expect(result.artifact.document.pointCount, 2);
        expect(source['schemaVersion'], 0);
        expect(source['id'], 'artifact-fixture-legacy');
        expect(source, isNot(contains('artifactId')));

        final canonical = _success(
          ChartArtifactJsonCodec.encode(result.artifact),
        ).value;
        expect(
          ChartArtifactJsonCodec.decode(canonical),
          isA<ChartArtifactSuccess<ChartArtifactDecodeResult>>(),
        );
      },
    );

    test('revalidates resource limits after migration', () {
      final fixture = File(
        'test/fixtures/artifacts/schema_v0_legacy.json',
      ).readAsStringSync();
      final result = ChartArtifactJsonCodec.decode(
        fixture,
        migrations: [_LegacyV0ToV1Migration()],
        limits: const ChartArtifactValidationLimits(maxPoints: 1),
      );

      expect(
        (result as ChartArtifactFailure<ChartArtifactDecodeResult>).error.code,
        ChartArtifactDiagnosticCodes.validationLimitExceeded,
      );
    });

    test('rejects missing, duplicate, and non-adjacent migration paths', () {
      final source = <String, Object?>{'schemaVersion': 0};
      final missing = ChartArtifactMigrationRegistry(
        const [],
      ).migrate(source, targetSchemaVersion: 1);
      expect(
        (missing as ChartArtifactFailure<ChartArtifactMigrationRun>).error.code,
        ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
      );

      for (final migrations in const <List<ChartArtifactMigration>>[
        [_PassThroughMigration(0, 1), _PassThroughMigration(0, 1)],
        [_PassThroughMigration(0, 2)],
      ]) {
        final result = ChartArtifactMigrationRegistry(
          migrations,
        ).migrate(source, targetSchemaVersion: 1);
        expect(
          (result as ChartArtifactFailure<ChartArtifactMigrationRun>)
              .error
              .code,
          ChartArtifactDiagnosticCodes.invalidMigrationRegistry,
        );
      }
    });

    test('wraps thrown and malformed migration results', () {
      final source = <String, Object?>{'schemaVersion': 0};
      final thrown = ChartArtifactMigrationRegistry([
        _ThrowingMigration(),
      ]).migrate(source, targetSchemaVersion: 1);
      expect(
        (thrown as ChartArtifactFailure<ChartArtifactMigrationRun>).error.code,
        ChartArtifactDiagnosticCodes.artifactMigrationFailed,
      );

      final wrongTarget = ChartArtifactMigrationRegistry([
        _WrongTargetMigration(),
      ]).migrate(source, targetSchemaVersion: 1);
      expect(
        (wrongTarget as ChartArtifactFailure<ChartArtifactMigrationRun>)
            .error
            .code,
        ChartArtifactDiagnosticCodes.artifactMigrationFailed,
      );
    });

    test('publishes a deeply immutable migrated JSON result', () {
      final result =
          ChartArtifactMigrationRegistry(const [
            _PassThroughMigration(0, 1),
          ]).migrate(<String, Object?>{
            'schemaVersion': 0,
            'nested': <String, Object?>{
              'values': <Object?>[1, 2],
            },
          }, targetSchemaVersion: 1);
      final run =
          (result as ChartArtifactSuccess<ChartArtifactMigrationRun>).value;
      final nested = run.artifactJson['nested']! as Map<String, Object?>;
      final values = nested['values']! as List<Object?>;

      expect(
        () => run.artifactJson['schemaVersion'] = 2,
        throwsUnsupportedError,
      );
      expect(() => nested['extra'] = true, throwsUnsupportedError);
      expect(() => values.add(3), throwsUnsupportedError);
    });
  });
}

class _LegacyV0ToV1Migration implements ChartArtifactMigration {
  @override
  int get sourceVersion => 0;

  @override
  int get targetVersion => 1;

  @override
  Map<String, Object?> migrate(Map<String, Object?> source) {
    final document = Map<String, Object?>.from(
      source['document']! as Map<String, Object?>,
    );
    document['revision'] = document.remove('version');
    return {
      ...source,
      'schemaVersion': 1,
      'artifactId': source['id'],
      'document': document,
    }..remove('id');
  }
}

class _PassThroughMigration implements ChartArtifactMigration {
  const _PassThroughMigration(this.sourceVersion, this.targetVersion);

  @override
  final int sourceVersion;
  @override
  final int targetVersion;

  @override
  Map<String, Object?> migrate(Map<String, Object?> source) => {
    ...source,
    'schemaVersion': targetVersion,
  };
}

class _ThrowingMigration implements ChartArtifactMigration {
  @override
  int get sourceVersion => 0;
  @override
  int get targetVersion => 1;

  @override
  Map<String, Object?> migrate(Map<String, Object?> source) =>
      throw StateError('broken legacy field');
}

class _WrongTargetMigration implements ChartArtifactMigration {
  @override
  int get sourceVersion => 0;
  @override
  int get targetVersion => 1;

  @override
  Map<String, Object?> migrate(Map<String, Object?> source) => source;
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
