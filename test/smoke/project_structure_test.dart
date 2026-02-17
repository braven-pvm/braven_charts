import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Smoke: project structure', () {
    test('pubspec.yaml should exist and declare package name', () {
      final file = File('pubspec.yaml');
      expect(file.existsSync(), isTrue, reason: 'pubspec.yaml must exist at project root');
      final content = file.readAsStringSync();
      expect(content, contains('name: braven_charts'));
    });

    test('pubspec.yaml should declare required dependencies', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('flutter:'), reason: 'Flutter SDK dependency required');
      expect(content, contains('flutter_test:'), reason: 'flutter_test dev dependency required');
      expect(content, contains('test:'), reason: 'test package dev dependency required');
    });

    test('lib/ directory should exist', () {
      expect(Directory('lib').existsSync(), isTrue, reason: 'lib/ directory must exist');
    });

    test('lib/braven_charts.dart barrel file should exist', () {
      expect(File('lib/braven_charts.dart').existsSync(), isTrue, reason: 'Barrel export file must exist');
    });

    test('analysis_options.yaml should exist', () {
      expect(File('analysis_options.yaml').existsSync(), isTrue, reason: 'Analyzer configuration must exist');
    });

    test('test tier directories should exist', () {
      expect(Directory('test/smoke').existsSync(), isTrue, reason: 'test/smoke/ tier directory required');
      expect(Directory('test/unit').existsSync(), isTrue, reason: 'test/unit/ tier directory required');
      expect(Directory('test/integration').existsSync(), isTrue, reason: 'test/integration/ tier directory required');
    });

    test('.agent-test-config.json should exist', () {
      expect(File('.agent-test-config.json').existsSync(), isTrue, reason: 'Orchestra test tier config required');
    });
  });
}
