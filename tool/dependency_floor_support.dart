/// Pure version and constraint logic behind `tool/check_dependency_floor.dart`.
///
/// This lives apart from the command so the reasoning that decides whether a
/// dependency is reachable can be tested without touching the network. A bug
/// here would make the gate vacuous — it would report every dependency as
/// reachable and quietly stop catching the defect it exists for — so the
/// regression case from BC-0060 is asserted directly in
/// `test/contract/dependency_floor_support_test.dart`.
library;

/// A parsed `major.minor.patch`, ignoring build metadata.
class DependencyFloorVersion implements Comparable<DependencyFloorVersion> {
  const DependencyFloorVersion(
    this.major,
    this.minor,
    this.patch, {
    this.isPrerelease = false,
  });

  final int major;
  final int minor;
  final int patch;
  final bool isPrerelease;

  String get text => '$major.$minor.$patch';

  @override
  int compareTo(DependencyFloorVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => text;
}

/// Parses `1.2.3`, `1.2.3-beta.1` or `1.2.3+4`. Returns null when [value] is
/// not a plain three-part version.
DependencyFloorVersion? parseDependencyFloorVersion(String value) {
  final match = RegExp(
    r'^([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([^+]+))?(?:\+.*)?$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  return DependencyFloorVersion(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    isPrerelease: match.group(4) != null,
  );
}

/// The lowest version a constraint allows, or null when there is no readable
/// lower bound. `null` in, `null` out, so an unspecified dependency
/// environment is treated as imposing no floor.
DependencyFloorVersion? lowestAllowedVersion(String? constraint) {
  if (constraint == null) return null;
  final trimmed = constraint.trim();
  if (trimmed.isEmpty || trimmed == 'any') return null;
  if (trimmed.startsWith('^')) {
    return parseDependencyFloorVersion(trimmed.substring(1));
  }
  final match = RegExp(
    r'>=\s*([0-9]+\.[0-9]+\.[0-9]+(?:-[^\s,<]+)?)',
  ).firstMatch(trimmed);
  if (match != null) return parseDependencyFloorVersion(match.group(1)!);
  return parseDependencyFloorVersion(trimmed);
}

/// Whether [constraint] admits [version].
///
/// Prereleases are excluded: pub will not select one to satisfy an ordinary
/// constraint, so counting them as reachable would let the gate pass on a
/// candidate a real consumer never receives.
bool constraintAdmits(String constraint, String version) {
  final parsed = parseDependencyFloorVersion(version);
  if (parsed == null || parsed.isPrerelease) return false;

  final trimmed = constraint.trim();
  if (trimmed.isEmpty || trimmed == 'any') return true;

  if (trimmed.startsWith('^')) {
    final base = parseDependencyFloorVersion(trimmed.substring(1));
    if (base == null) return true;
    if (parsed.compareTo(base) < 0) return false;
    final upper = base.major > 0
        ? DependencyFloorVersion(base.major + 1, 0, 0)
        : DependencyFloorVersion(0, base.minor + 1, 0);
    return parsed.compareTo(upper) < 0;
  }

  final bounds = RegExp(
    r'(>=|<=|>|<)\s*([0-9]+\.[0-9]+\.[0-9]+)',
  ).allMatches(trimmed);
  if (bounds.isEmpty) return true;

  var admits = true;
  for (final bound in bounds) {
    final limit = parseDependencyFloorVersion(bound.group(2)!);
    if (limit == null) continue;
    final comparison = parsed.compareTo(limit);
    admits &= switch (bound.group(1)!) {
      '>=' => comparison >= 0,
      '>' => comparison > 0,
      '<=' => comparison <= 0,
      '<' => comparison < 0,
      _ => true,
    };
  }
  return admits;
}

/// Whether a dependency version requiring [versionConstraint] can be used by a
/// consumer sitting exactly on [floor].
///
/// An unspecified constraint imposes no requirement and is therefore reachable.
bool reachableFromFloor(
  String? versionConstraint,
  DependencyFloorVersion floor,
) {
  final required = lowestAllowedVersion(versionConstraint);
  if (required == null) return true;
  return required.compareTo(floor) <= 0;
}

/// Direct dependencies declared under `dependencies:`, mapped to their version
/// constraint. Nested blocks (git, path, sdk) map to null so the command can
/// report them as skipped rather than silently passing them.
Map<String, String?> directDependencies(String pubspecSource) {
  final source = pubspecSource.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final dependencies = <String, String?>{};

  var inDependencies = false;
  for (final line in source.split('\n')) {
    if (line.startsWith('dependencies:')) {
      inDependencies = true;
      continue;
    }
    if (!inDependencies) continue;
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('#')) {
      break;
    }

    final match = RegExp(r'^  ([a-zA-Z0-9_]+):[ \t]*(.*)$').firstMatch(line);
    if (match == null) continue;
    final name = match.group(1)!;
    final value = match.group(2)!.trim();
    dependencies[name] = value.isEmpty
        ? null
        : value.replaceAll('"', '').replaceAll("'", '');
  }
  return dependencies;
}
