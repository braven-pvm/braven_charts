import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/public_docs_support.dart';

void main() {
  group('normalizePublicDocsText', () {
    test('treats LF, CRLF, and CR line endings as equivalent', () {
      const lf = 'first\nsecond\nthird\n';
      const crlf = 'first\r\nsecond\r\nthird\r\n';
      const cr = 'first\rsecond\rthird\r';

      expect(normalizePublicDocsText(crlf), lf);
      expect(normalizePublicDocsText(cr), lf);
    });

    test('preserves meaningful content differences', () {
      const expected = 'first\nsecond\n';
      const stale = 'first\nchanged\n';

      expect(
        normalizePublicDocsText(stale),
        isNot(normalizePublicDocsText(expected)),
      );
    });
  });

  test('reads package version and compatibility metadata from pubspec', () {
    final directory = Directory.systemTemp.createTempSync(
      'braven-public-docs-metadata-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final pubspec =
        File('${directory.path}${Platform.pathSeparator}pubspec.yaml')
          ..writeAsStringSync('''
name: fixture
version: 1.2.3
environment:
  sdk: ">=3.9.0 <4.0.0"
  flutter: ">=3.35.0"
''');

    final metadata = readPublicDocsPackageMetadata(pubspec);

    expect(metadata.version, '1.2.3');
    expect(metadata.dartConstraint, '>=3.9.0 <4.0.0');
    expect(metadata.flutterConstraint, '>=3.35.0');
  });
}
