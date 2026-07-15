# Chart Artifact Migrations

Artifact migrations transform older portable JSON into the current schema
before Dart model construction. They are explicit trusted code, not scripts or
instructions embedded in an artifact.

The current artifact schema begins at version 1. Schema 0 used by the showcase
is a demonstration fixture only; the package does not register a built-in
schema-0 compatibility promise.

## Migration rules

Every `ChartArtifactMigration` must:

1. declare one adjacent step, `vN -> vN+1`;
2. accept and return JSON-safe `Map<String, Object?>` data;
3. write its declared `targetVersion` to `schemaVersion`;
4. be deterministic and free of file, network, clock, or random behavior;
5. preserve unknown namespaced extension values unless the schema explicitly
   changes their contract;
6. avoid depending on controllers, widgets, render objects, or host services.

The registry rejects duplicate source versions, negative versions,
non-adjacent steps, missing paths, thrown migrations, malformed JSON values,
and results that do not write the expected target version.

## Define a migration

This example demonstrates a hypothetical legacy envelope that used `id` for
the artifact identity and `version` for the document revision:

```dart
class LegacyV0ToV1 implements ChartArtifactMigration {
  const LegacyV0ToV1();

  @override
  int get sourceVersion => 0;

  @override
  int get targetVersion => 1;

  @override
  Map<String, Object?> migrate(Map<String, Object?> source) {
    final document = Map<String, Object?>.from(
      source['document']! as Map<String, Object?>,
    );

    final artifactId = source['id'];
    final revision = document['version'];
    document
      ..remove('version')
      ..['revision'] = revision;

    return {
      ...source,
      'schemaVersion': targetVersion,
      'artifactId': artifactId,
      'document': document,
    }..remove('id');
  }
}
```

Migration inputs are deep copied before each step. The final migrated map is
deeply immutable. Do not rely on mutating the caller's original JSON.

## Decode or hydrate with migrations

Pass the trusted chain explicitly at the application boundary:

```dart
const migrations = <ChartArtifactMigration>[
  LegacyV0ToV1(),
];

final decoded = ChartArtifactJsonCodec.decode(
  legacyJson,
  migrations: migrations,
);
```

Or migrate and hydrate in one operation:

```dart
final hydrated = ChartDocumentHydrator.hydrateJson(
  legacyJson,
  migrations: migrations,
  runtimeBindings: bindings,
);
```

For artifacts with referenced data, provide the same migration list to
`hydrateJsonWithDataResolver` together with the host resolver.

On success, `ChartArtifactDecodeResult` reports:

- `sourceSchemaVersion`;
- `migratedSchemaVersion`;
- `migrationsApplied`, such as `v0->v1`;
- the current typed `artifact`.

The codec re-applies structure, resource-count, semantic, capability, and
payload-manifest validation after migration. A migration cannot bypass normal
artifact limits by producing oversized output.

## Registry ownership and security

Artifacts never name a Dart class, package, URL, or executable migration.
Applications choose a fixed trusted list in code. Do not download and execute
migrations based on artifact fields.

Migrations parse untrusted input, so keep them small and total:

- validate old fields before casts;
- throw a `FormatException` for malformed legacy shapes;
- bound any loops and avoid recursive traversal without a depth limit;
- never open a URI or resolve external data during a migration;
- do not silently reinterpret an unknown field;
- test resource-limit validation after the migration.

`artifact_migration_failed` means a registered step threw, emitted non-JSON
data, or wrote the wrong target version. `unsupported_schema_version` means no
complete trusted path exists or the input is newer than the package.

## Testing a schema step

Check in at least one stable legacy JSON fixture for every supported source
version. Tests should prove:

- the fixture migrates to the current typed artifact;
- canonical re-encoding is deterministic;
- the input map remains unchanged;
- the result is deeply immutable;
- missing and duplicate registry steps fail;
- thrown and wrong-target migrations fail;
- resource limits and semantic validation run after migration;
- hydration restores the same runtime behavior as a native current-schema
  artifact.

Keep migration fixtures even after most production data has upgraded. They are
the executable compatibility contract for persisted artifacts.
