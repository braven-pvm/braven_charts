import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory repository;
  late String checkerPath;

  setUp(() {
    repository = Directory.systemTemp.createTempSync(
      'braven_charts_format_gate_',
    );
    checkerPath = File(
      '${Directory.current.path}${Platform.pathSeparator}'
      'tool${Platform.pathSeparator}check_dart_format.dart',
    ).absolute.path;

    _git(repository, ['init']);
    _git(repository, ['config', 'user.email', 'format-gate@example.invalid']);
    _git(repository, ['config', 'user.name', 'Format Gate Test']);

    _write(
      repository,
      'lib/legacy.dart',
      "void legacy( ){print('grandfathered');}\n",
    );
    _write(repository, 'lib/current.dart', 'void current() {}\n');
    _git(repository, ['add', '.']);
    _git(repository, ['commit', '-m', 'baseline']);
  });

  tearDown(() {
    repository.deleteSync(recursive: true);
  });

  test('grandfathers unchanged files from the baseline', () {
    final baseline = _git(repository, ['rev-parse', 'HEAD']).stdout.toString();

    final result = _runChecker(repository, checkerPath, baseline.trim());

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('No changed Dart files'));
  });

  test(
    'fails for a changed misformatted file and passes from a clean checkout',
    () {
      final baseline = _git(repository, [
        'rev-parse',
        'HEAD',
      ]).stdout.toString();
      _write(
        repository,
        'lib/current.dart',
        "void current( ){print('changed');}\n",
      );
      _git(repository, ['add', '.']);
      _git(repository, ['commit', '-m', 'change current']);

      final failed = _runChecker(repository, checkerPath, baseline.trim());

      expect(failed.exitCode, 1);
      expect(failed.stdout, contains('Changed lib/current.dart'));

      final format = Process.runSync(_dartExecutable(), [
        'format',
        'lib/current.dart',
      ], workingDirectory: repository.path);
      expect(format.exitCode, 0, reason: format.stderr.toString());
      _git(repository, ['add', '.']);
      _git(repository, ['commit', '-m', 'format current']);
      expect(
        _git(repository, ['status', '--porcelain']).stdout.toString(),
        isEmpty,
      );

      final passed = _runChecker(repository, checkerPath, baseline.trim());

      expect(passed.exitCode, 0, reason: '${passed.stdout}\n${passed.stderr}');
      expect(passed.stdout, contains('Dart format check passed'));
    },
  );

  test('includes untracked Dart files in a local check', () {
    final baseline = _git(repository, ['rev-parse', 'HEAD']).stdout.toString();
    _write(repository, 'test/new_test.dart', 'void main( ) {}\n');

    final result = _runChecker(repository, checkerPath, baseline.trim());

    expect(result.exitCode, 1);
    expect(result.stdout, contains('Changed test/new_test.dart'));
  });
}

ProcessResult _runChecker(
  Directory directory,
  String checkerPath,
  String baseline,
) {
  return Process.runSync(_dartExecutable(), [
    checkerPath,
    '--base',
    baseline,
  ], workingDirectory: directory.path);
}

String _dartExecutable() {
  final resolved = File(Platform.resolvedExecutable);
  if (resolved.path.toLowerCase().contains('dart')) {
    return resolved.path;
  }

  var directory = resolved.parent;
  while (directory.parent.path != directory.path) {
    final executable = Platform.isWindows ? 'dart.exe' : 'dart';
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}'
      'dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}'
      '$executable',
    );
    if (candidate.existsSync()) {
      return candidate.path;
    }
    directory = directory.parent;
  }

  throw StateError(
    'Unable to locate the Dart executable from ${resolved.path}.',
  );
}

ProcessResult _git(Directory directory, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: directory.path,
  );
  if (result.exitCode != 0) {
    fail(
      'git ${arguments.join(' ')} failed:\n'
      '${result.stdout}\n${result.stderr}',
    );
  }
  return result;
}

void _write(Directory repository, String path, String content) {
  final file = File(
    '${repository.path}${Platform.pathSeparator}'
    '${path.replaceAll('/', Platform.pathSeparator)}',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}
