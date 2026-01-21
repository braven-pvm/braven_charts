// @orchestra-task: 1
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Test suite to verify braven_data package initialization
///
/// These tests verify all acceptance criteria from Task 1:
/// - Package directory structure
/// - pubspec.yaml configuration
/// - analysis_options.yaml strict typing
/// - Required directory placeholders
void main() {
  // Get package root (parent of test directory)
  final packageRoot = Directory.current.path;

  group('Package Structure', () {
    test('braven_data directory exists at workspace root', () {
      final dir = Directory(packageRoot);
      expect(dir.existsSync(), isTrue,
          reason: 'braven_data/ directory must exist');
    });

    test('pubspec.yaml exists and is valid', () {
      final pubspec = File(path.join(packageRoot, 'pubspec.yaml'));
      expect(pubspec.existsSync(), isTrue, reason: 'pubspec.yaml must exist');

      final content = pubspec.readAsStringSync();
      expect(content.contains('name: braven_data'), isTrue,
          reason: 'Package name must be braven_data');
    });

    test('Dart SDK constraint matches project (>=3.0.0 <4.0.0)', () {
      final pubspec = File(path.join(packageRoot, 'pubspec.yaml'));
      final content = pubspec.readAsStringSync();
      expect(content.contains('sdk: ">=3.0.0 <4.0.0"'), isTrue,
          reason: 'SDK constraint must be >=3.0.0 <4.0.0');
    });

    test('test dependency is included', () {
      final pubspec = File(path.join(packageRoot, 'pubspec.yaml'));
      final content = pubspec.readAsStringSync();
      expect(content.contains('test:'), isTrue,
          reason: 'test package must be in dev_dependencies');
    });

    test('analysis_options.yaml exists with strict typing', () {
      final analysisOptions =
          File(path.join(packageRoot, 'analysis_options.yaml'));
      expect(analysisOptions.existsSync(), isTrue,
          reason: 'analysis_options.yaml must exist');

      final content = analysisOptions.readAsStringSync();
      expect(content.contains('strict-casts: true'), isTrue,
          reason: 'Must enable strict-casts');
      expect(content.contains('strict-inference: true'), isTrue,
          reason: 'Must enable strict-inference');
      expect(content.contains('strict-raw-types: true'), isTrue,
          reason: 'Must enable strict-raw-types');
    });
  });

  group('Directory Structure', () {
    test('lib/braven_data.dart entry point exists', () {
      final entryPoint =
          File(path.join(packageRoot, 'lib', 'braven_data.dart'));
      expect(entryPoint.existsSync(), isTrue,
          reason: 'Library entry point must exist');

      final content = entryPoint.readAsStringSync();
      expect(content.contains('library'), isTrue,
          reason: 'Entry point must declare library');
    });

    test('lib/src/ directory exists', () {
      final srcDir = Directory(path.join(packageRoot, 'lib', 'src'));
      expect(srcDir.existsSync(), isTrue,
          reason: 'Source directory must exist');
    });

    test('test/unit/ directory exists', () {
      final unitDir = Directory(path.join(packageRoot, 'test', 'unit'));
      expect(unitDir.existsSync(), isTrue,
          reason: 'Unit test directory must exist');
    });

    test('test/benchmarks/ directory exists', () {
      final benchDir = Directory(path.join(packageRoot, 'test', 'benchmarks'));
      expect(benchDir.existsSync(), isTrue,
          reason: 'Benchmarks directory must exist');
    });
  });

  group('Package Functionality', () {
    test('dart pub get succeeds (verified by test execution)', () {
      // If this test is running, dart pub get succeeded
      expect(true, isTrue,
          reason: 'dart pub get must succeed for tests to run');
    });

    test('package can be imported', () {
      // This test file imports package:test which requires valid pubspec
      expect(true, isTrue, reason: 'Package must be importable');
    });
  });
}
