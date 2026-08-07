/// Proves that every direct hosted dependency can actually be resolved on the
/// Flutter and Dart floors this package advertises.
///
/// The failure this exists to catch shipped in 0.14.0 through 0.17.0 and was
/// invisible to every other gate. `pubspec.yaml` declared
/// `flutter: ">=3.35.0"` while constraining `flex_color_picker: ^3.8.0`. The
/// only release satisfying `^3.8.0` is `3.8.0`, which itself requires
/// `flutter: ">=3.38.0"`. Because the caret range admitted no lower candidate,
/// pub's solver had nothing to fall back to and version solving failed
/// outright: the package could not be installed on Flutter 3.35, 3.36 or 3.37,
/// a range it publicly advertised.
///
/// Nothing detected it because CI resolves on `channel: stable` and the
/// development toolchain is newer still. The declared floor was never exercised
/// by anything, so it was an unverified claim rather than a tested property.
///
/// For each direct hosted dependency this asks pub.dev for every published
/// version, keeps the ones our constraint admits, and requires that at least
/// one of those is itself compatible with our declared floors. One is enough —
/// pub only needs a single reachable candidate to solve.
///
/// ## Coverage boundary — READ THIS BEFORE TRUSTING IT
///
/// * **Direct hosted dependencies only.** A transitive dependency that raises
///   the effective floor is not detected. Closing that needs a real resolution
///   against the floor SDK, not a metadata query.
/// * **Floors only.** It checks the lower bound of our declared range, not
///   every version within it.
/// * **`any` and git/path/sdk dependencies are skipped**, and reported as
///   skipped rather than silently passed.
/// * It reads published metadata, so it can only be as correct as pub.dev.
///
/// The reasoning that decides reachability lives in
/// `tool/dependency_floor_support.dart` and is asserted, including this exact
/// regression, by `test/contract/dependency_floor_support_test.dart`.
library;

import 'dart:convert';
import 'dart:io';

import 'dependency_floor_support.dart';
import 'public_docs_support.dart';

const _pubspecPath = 'pubspec.yaml';
const _pubApiBase = 'https://pub.dev/api/packages/';

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    stderr.writeln('Usage: dart run tool/check_dependency_floor.dart');
    exitCode = 64;
    return;
  }

  final pubspec = File('${Directory.current.path}/$_pubspecPath');
  if (!pubspec.existsSync()) {
    stderr.writeln('Missing $_pubspecPath.');
    exitCode = 1;
    return;
  }

  final package = readPublicDocsPackageMetadata(pubspec);
  final flutterFloor = lowestAllowedVersion(package.flutterConstraint);
  final dartFloor = lowestAllowedVersion(package.dartConstraint);
  if (flutterFloor == null || dartFloor == null) {
    stderr.writeln(
      'Could not read a lower bound from the declared SDK constraints '
      '(dart "${package.dartConstraint}", flutter '
      '"${package.flutterConstraint}"). A floor that cannot be parsed cannot '
      'be gated.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Declared floors: Flutter ${flutterFloor.text}, Dart ${dartFloor.text}',
  );

  final dependencies = directDependencies(pubspec.readAsStringSync());
  final constrained = {
    for (final entry in dependencies.entries)
      if (entry.value != null && entry.value != 'any') entry.key: entry.value!,
  };
  if (constrained.isEmpty) {
    stderr.writeln(
      'No constrained direct dependencies were parsed from $_pubspecPath. The '
      'gate would pass vacuously, so this is treated as a failure.',
    );
    exitCode = 1;
    return;
  }

  final failures = <String>[];
  final client = HttpClient();
  try {
    for (final entry in constrained.entries) {
      final name = entry.key;
      final constraint = entry.value;

      final List<_PublishedVersion> published;
      try {
        published = await _fetchVersions(client, name);
      } on Object catch (error) {
        failures.add('$name: could not read pub.dev metadata ($error).');
        continue;
      }

      final admitted = published
          .where((version) => constraintAdmits(constraint, version.version))
          .toList();
      if (admitted.isEmpty) {
        failures.add('$name: no published version satisfies "$constraint".');
        continue;
      }

      final reachable = admitted
          .where(
            (version) =>
                reachableFromFloor(version.flutterConstraint, flutterFloor) &&
                reachableFromFloor(version.dartConstraint, dartFloor),
          )
          .toList();

      if (reachable.isEmpty) {
        final newest = admitted.last;
        failures.add(
          '$name: "$constraint" admits ${admitted.length} version(s), none '
          'usable on the declared floor. ${newest.version} requires Flutter '
          '"${newest.flutterConstraint ?? 'unspecified'}" and Dart '
          '"${newest.dartConstraint ?? 'unspecified'}", but this package '
          'advertises Flutter >=${flutterFloor.text} / Dart '
          '>=${dartFloor.text}. Widen the constraint so the solver has a '
          'fallback, or raise the declared floor.',
        );
      } else {
        final shown = reachable.map((v) => v.version).toList();
        stdout.writeln(
          '  OK   $name $constraint -> '
          '${shown.take(3).join(', ')}${shown.length > 3 ? ', ...' : ''}',
        );
      }
    }
  } finally {
    client.close(force: true);
  }

  for (final entry in dependencies.entries) {
    if (entry.value == null || entry.value == 'any') {
      stdout.writeln('  SKIP ${entry.key} (not a hosted version constraint)');
    }
  }

  if (failures.isNotEmpty) {
    stderr
      ..writeln('')
      ..writeln('Dependencies are unresolvable on the declared SDK floor:');
    for (final failure in failures) {
      stderr.writeln('  - $failure');
    }
    stderr
      ..writeln('')
      ..writeln(
        'A consumer on the lowest advertised SDK cannot install this package.',
      );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Every direct hosted dependency resolves on the declared SDK floor.',
  );
}

Future<List<_PublishedVersion>> _fetchVersions(
  HttpClient client,
  String name,
) async {
  final request = await client.getUrl(Uri.parse('$_pubApiBase$name'));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw HttpException('pub.dev returned ${response.statusCode}');
  }
  final decoded = jsonDecode(await response.transform(utf8.decoder).join());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('unexpected pub.dev payload');
  }
  final versions = decoded['versions'];
  if (versions is! List) {
    throw const FormatException('pub.dev payload has no versions list');
  }
  return [
    for (final entry in versions)
      if (entry is Map<String, dynamic>)
        if (entry['version'] case final String version)
          _PublishedVersion(
            version: version,
            flutterConstraint: _environment(entry, 'flutter'),
            dartConstraint: _environment(entry, 'sdk'),
          ),
  ];
}

String? _environment(Map<String, dynamic> versionEntry, String key) {
  if (versionEntry['pubspec'] case final Map<String, dynamic> pubspec) {
    if (pubspec['environment'] case final Map<String, dynamic> environment) {
      final value = environment[key];
      if (value is String) return value;
    }
  }
  return null;
}

class _PublishedVersion {
  const _PublishedVersion({
    required this.version,
    required this.flutterConstraint,
    required this.dartConstraint,
  });

  final String version;
  final String? flutterConstraint;
  final String? dartConstraint;
}
