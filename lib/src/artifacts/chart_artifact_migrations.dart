import 'package:flutter/foundation.dart';

import 'chart_artifact_diagnostics.dart';

/// Result of applying a deterministic adjacent-version migration chain.
@immutable
class ChartArtifactMigrationRun {
  ChartArtifactMigrationRun({
    required Map<String, Object?> artifactJson,
    required this.sourceSchemaVersion,
    required this.migratedSchemaVersion,
    required Iterable<String> migrationsApplied,
  }) : artifactJson = _freezeJsonValue(artifactJson) as Map<String, Object?>,
       migrationsApplied = List.unmodifiable(migrationsApplied);

  final Map<String, Object?> artifactJson;
  final int sourceSchemaVersion;
  final int migratedSchemaVersion;
  final List<String> migrationsApplied;
}

/// Validates and executes registered `vN -> vN+1` artifact migrations.
///
/// Artifact JSON never selects executable code. The package or host supplies
/// this trusted registry explicitly, and every step must advance exactly one
/// schema version.
@immutable
class ChartArtifactMigrationRegistry {
  ChartArtifactMigrationRegistry(Iterable<ChartArtifactMigration> migrations)
    : migrations = List.unmodifiable(migrations);

  final List<ChartArtifactMigration> migrations;

  ChartArtifactResult<ChartArtifactMigrationRun> migrate(
    Map<String, Object?> source, {
    required int targetSchemaVersion,
  }) {
    final sourceVersion = source['schemaVersion'];
    if (sourceVersion is! int || sourceVersion < 0) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'schemaVersion must be a non-negative integer.',
          path: r'$.schemaVersion',
        ),
      );
    }
    if (sourceVersion > targetSchemaVersion) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
          message:
              'Schema $sourceVersion is newer than supported schema '
              '$targetSchemaVersion.',
          path: r'$.schemaVersion',
        ),
      );
    }

    final bySourceVersion = <int, ChartArtifactMigration>{};
    for (final migration in migrations) {
      if (migration.sourceVersion < 0 ||
          migration.targetVersion != migration.sourceVersion + 1 ||
          bySourceVersion.containsKey(migration.sourceVersion)) {
        return ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.invalidMigrationRegistry,
            message:
                'Migration registry must contain one adjacent migration per '
                'source schema version.',
          ),
        );
      }
      bySourceVersion[migration.sourceVersion] = migration;
    }

    final Map<String, Object?> initialCopy;
    try {
      initialCopy = _copyJsonObject(source);
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
          path: r'$',
        ),
      );
    }
    var current = initialCopy;
    var currentVersion = sourceVersion;
    final applied = <String>[];
    while (currentVersion < targetSchemaVersion) {
      final migration = bySourceVersion[currentVersion];
      if (migration == null) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
            message:
                'No migration is registered from schema $currentVersion to '
                '${currentVersion + 1}.',
            path: r'$.schemaVersion',
          ),
        );
      }
      final Map<String, Object?> migrated;
      try {
        migrated = migration.migrate(_copyJsonObject(current));
      } catch (error) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.artifactMigrationFailed,
            message:
                'Migration v${migration.sourceVersion} to '
                'v${migration.targetVersion} failed: $error',
            path: r'$.schemaVersion',
          ),
        );
      }
      if (migrated['schemaVersion'] != migration.targetVersion) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.artifactMigrationFailed,
            message:
                'Migration v${migration.sourceVersion} to '
                'v${migration.targetVersion} did not write its target '
                'schemaVersion.',
            path: r'$.schemaVersion',
          ),
        );
      }
      try {
        current = _copyJsonObject(migrated);
      } on FormatException catch (error) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.artifactMigrationFailed,
            message: error.message,
            path: r'$',
          ),
        );
      }
      applied.add('v${migration.sourceVersion}->v${migration.targetVersion}');
      currentVersion = migration.targetVersion;
    }

    return ChartArtifactSuccess(
      value: ChartArtifactMigrationRun(
        artifactJson: current,
        sourceSchemaVersion: sourceVersion,
        migratedSchemaVersion: currentVersion,
        migrationsApplied: applied,
      ),
    );
  }
}

Map<String, Object?> _copyJsonObject(Map<String, Object?> source) => {
  for (final entry in source.entries) entry.key: _copyJsonValue(entry.value),
};

Object? _copyJsonValue(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is List) return [for (final item in value) _copyJsonValue(item)];
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('Migrated JSON contains a non-string key.');
      }
      result[entry.key as String] = _copyJsonValue(entry.value);
    }
    return result;
  }
  throw FormatException(
    'Migrated JSON contains unsupported value ${value.runtimeType}.',
  );
}

Object? _freezeJsonValue(Object? value) {
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJsonValue));
  }
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _freezeJsonValue(entry.value),
    });
  }
  return value;
}
