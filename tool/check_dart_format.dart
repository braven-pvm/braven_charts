import 'dart:convert';
import 'dart:io';

const _baselinePath = 'tool/dart_format_baseline.txt';
const _formatScopes = <String>['lib', 'example/lib', 'test', 'example/test'];
const _chunkSize = 100;

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.showHelp) {
    stdout.write(_usage);
    return;
  }

  try {
    final repositoryRoot = await _gitOutput(['rev-parse', '--show-toplevel']);
    final base = options.base ?? await _readBaseline(repositoryRoot);
    final files = options.all
        ? await _allDartFiles(repositoryRoot)
        : await _changedDartFiles(
            repositoryRoot,
            base: base,
            head: options.head,
          );

    if (files.isEmpty) {
      stdout.writeln(
        options.all
            ? 'No Dart files found in the configured format scopes.'
            : 'No changed Dart files require formatting.',
      );
      return;
    }

    stdout.writeln(
      'Checking ${files.length} Dart file(s) with '
      '${Platform.resolvedExecutable}.',
    );
    final failed = await _runFormatter(repositoryRoot, files);
    if (failed) {
      stderr.writeln(
        'Dart formatting failed. Run dart format on the files reported above '
        'and commit the result.',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('Dart format check passed.');
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.write(_usage);
    exitCode = 64;
  } on ProcessException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Future<String> _readBaseline(String repositoryRoot) async {
  final file = File(_join(repositoryRoot, _baselinePath));
  if (!file.existsSync()) {
    throw const FormatException(
      'Missing format baseline at tool/dart_format_baseline.txt.',
    );
  }
  final baseline = file.readAsStringSync().trim();
  if (baseline.isEmpty) {
    throw const FormatException('The Dart format baseline is empty.');
  }
  await _gitOutput([
    'cat-file',
    '-e',
    '$baseline^{commit}',
  ], workingDirectory: repositoryRoot);
  return baseline;
}

Future<List<String>> _changedDartFiles(
  String repositoryRoot, {
  required String base,
  required String head,
}) async {
  await _gitOutput([
    'cat-file',
    '-e',
    '$base^{commit}',
  ], workingDirectory: repositoryRoot);
  await _gitOutput([
    'cat-file',
    '-e',
    '$head^{commit}',
  ], workingDirectory: repositoryRoot);

  final files = <String>{};
  files.addAll(
    await _gitPaths([
      'diff',
      '--name-only',
      '--diff-filter=ACMR',
      '-z',
      base,
      head,
      '--',
      ..._formatScopes,
    ], repositoryRoot),
  );

  if (head == 'HEAD') {
    files.addAll(
      await _gitPaths([
        'diff',
        '--name-only',
        '--diff-filter=ACMR',
        '-z',
        'HEAD',
        '--',
        ..._formatScopes,
      ], repositoryRoot),
    );
    files.addAll(
      await _gitPaths([
        'ls-files',
        '--others',
        '--exclude-standard',
        '-z',
        '--',
        ..._formatScopes,
      ], repositoryRoot),
    );
  }

  return files
      .where((path) => path.endsWith('.dart'))
      .where((path) => File(_join(repositoryRoot, path)).existsSync())
      .toList()
    ..sort();
}

Future<List<String>> _allDartFiles(String repositoryRoot) async {
  final files = await _gitPaths([
    'ls-files',
    '-z',
    '--',
    ..._formatScopes,
  ], repositoryRoot);
  return files.where((path) => path.endsWith('.dart')).toList()..sort();
}

Future<List<String>> _gitPaths(
  List<String> arguments,
  String workingDirectory,
) async {
  final output = await _gitOutput(
    arguments,
    workingDirectory: workingDirectory,
  );
  return output
      .split('\u0000')
      .where((path) => path.isNotEmpty)
      .map((path) => path.replaceAll('\\', '/'))
      .toList();
}

Future<bool> _runFormatter(String repositoryRoot, List<String> files) async {
  var failed = false;
  for (var start = 0; start < files.length; start += _chunkSize) {
    final end = (start + _chunkSize).clamp(0, files.length);
    final result = await Process.run(Platform.resolvedExecutable, [
      'format',
      '--output=none',
      '--set-exit-if-changed',
      ...files.sublist(start, end),
    ], workingDirectory: repositoryRoot);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    failed = failed || result.exitCode != 0;
  }
  return failed;
}

Future<String> _gitOutput(
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      arguments,
      result.stderr.toString().trim(),
      result.exitCode,
    );
  }
  return result.stdout.toString().trim();
}

String _join(String root, String relativePath) {
  final platformPath = relativePath.replaceAll('/', Platform.pathSeparator);
  return '$root${Platform.pathSeparator}$platformPath';
}

final class _Options {
  const _Options({
    required this.base,
    required this.head,
    required this.all,
    required this.showHelp,
  });

  final String? base;
  final String head;
  final bool all;
  final bool showHelp;

  static _Options parse(List<String> arguments) {
    String? base;
    var head = 'HEAD';
    var all = false;
    var showHelp = false;

    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--base':
          if (index + 1 >= arguments.length) {
            throw const FormatException('--base requires a Git revision.');
          }
          base = arguments[++index];
        case '--head':
          if (index + 1 >= arguments.length) {
            throw const FormatException('--head requires a Git revision.');
          }
          head = arguments[++index];
        case '--all':
          all = true;
        case '--help':
        case '-h':
          showHelp = true;
        default:
          throw FormatException('Unknown argument: ${arguments[index]}');
      }
    }

    if (all && base != null) {
      throw const FormatException('--all cannot be combined with --base.');
    }
    if (all && head != 'HEAD') {
      throw const FormatException('--all cannot be combined with --head.');
    }

    return _Options(base: base, head: head, all: all, showHelp: showHelp);
  }
}

const _usage = '''
Usage: dart run tool/check_dart_format.dart [options]

Checks Dart files under lib, example/lib, and test.

By default, only files changed since tool/dart_format_baseline.txt are checked.
Committed, working-tree, and untracked changes are included.

Options:
  --base <revision>  Override the repository baseline.
  --head <revision>  Compare through this revision instead of HEAD.
  --all              Audit every Dart file in the configured scopes.
  -h, --help         Show this help.
''';
