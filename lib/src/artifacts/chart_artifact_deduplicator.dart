import 'package:flutter/foundation.dart';

import 'chart_artifact.dart';
import 'chart_artifact_canonicalizer.dart';

/// Selects which canonical identity is used to group artifacts.
enum ChartArtifactDeduplicationScope {
  /// Ignores artifact envelope metadata and durable view state.
  document,

  /// Includes the portable document and its durable view state.
  view,
}

/// One stable, input-ordered set of artifacts with the same canonical hash.
@immutable
class ChartArtifactDuplicateGroup {
  ChartArtifactDuplicateGroup({
    required this.hash,
    required this.primary,
    Iterable<ChartArtifact> duplicates = const [],
  }) : duplicates = List.unmodifiable(duplicates);

  final String hash;

  /// The first matching artifact in caller-provided order.
  final ChartArtifact primary;

  /// Later artifacts with the same canonical content identity.
  final List<ChartArtifact> duplicates;

  int get artifactCount => 1 + duplicates.length;
}

/// Immutable grouping result suitable for host cache and storage decisions.
@immutable
class ChartArtifactDeduplicationResult {
  ChartArtifactDeduplicationResult({
    required this.scope,
    required Iterable<ChartArtifactDuplicateGroup> groups,
  }) : groups = List.unmodifiable(groups);

  final ChartArtifactDeduplicationScope scope;
  final List<ChartArtifactDuplicateGroup> groups;

  List<ChartArtifact> get uniqueArtifacts =>
      List.unmodifiable(groups.map((group) => group.primary));

  int get inputCount =>
      groups.fold(0, (sum, group) => sum + group.artifactCount);
  int get duplicateCount => inputCount - groups.length;
}

/// Pure, order-preserving canonical deduplication for host applications.
///
/// The package reports duplicate groups but does not delete artifacts or
/// choose a persistence policy. A SHA-256 identity is not proof of origin or
/// authenticity; signing remains a host transport concern.
abstract final class ChartArtifactDeduplicator {
  static ChartArtifactDeduplicationResult group(
    Iterable<ChartArtifact> artifacts, {
    ChartArtifactDeduplicationScope scope =
        ChartArtifactDeduplicationScope.document,
  }) {
    final mutableGroups = <String, _MutableDuplicateGroup>{};

    for (final artifact in artifacts) {
      final hash = switch (scope) {
        ChartArtifactDeduplicationScope.document =>
          ChartArtifactCanonicalizer.documentHash(artifact.document),
        ChartArtifactDeduplicationScope.view =>
          ChartArtifactCanonicalizer.viewHash(
            artifact.document,
            artifact.viewState,
          ),
      };
      final existing = mutableGroups[hash];
      if (existing == null) {
        mutableGroups[hash] = _MutableDuplicateGroup(hash, artifact);
      } else {
        existing.duplicates.add(artifact);
      }
    }

    return ChartArtifactDeduplicationResult(
      scope: scope,
      groups: mutableGroups.values.map(
        (group) => ChartArtifactDuplicateGroup(
          hash: group.hash,
          primary: group.primary,
          duplicates: group.duplicates,
        ),
      ),
    );
  }
}

final class _MutableDuplicateGroup {
  _MutableDuplicateGroup(this.hash, this.primary);

  final String hash;
  final ChartArtifact primary;
  final List<ChartArtifact> duplicates = [];
}
