// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:braven_charts/src/agentic/services/file_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileValidator', () {
    late FileValidator validator;

    setUp(() {
      validator = FileValidator();
    });

    group('size limit enforcement (FR-018)', () {
      test('accepts file at exactly 50MB limit', () {
        const size = 52428800; // 50 MB exactly
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'test.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.warningMessage, isNotNull);
        expect(result.warningMessage, contains('Large file may take longer'));
      });

      test('rejects file exceeding 50MB limit', () {
        const size = 52428801; // 50 MB + 1 byte
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'test.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('exceeds maximum'));
        expect(result.errorMessage, contains('50 MB'));
      });

      test('accepts small file', () {
        const size = 1024; // 1 KB
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'test.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('provides file size in error message', () {
        const size = 104857600; // 100 MB
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'test.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('100.00 MB'));
      });
    });

    group('format validation (FR-019)', () {
      test('accepts FIT file', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'workout.fit',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });

      test('accepts CSV file', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'data.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });

      test('accepts TCX file', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'activity.tcx',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });

      test('rejects unsupported format', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'document.pdf',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('Unsupported file format'));
        expect(result.errorMessage, contains('.pdf'));
      });

      test('rejects file without extension', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'noextension',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('missing file extension'));
      });

      test('is case-insensitive for extensions', () {
        const size = 1024;
        final content = Uint8List(size);

        final resultUpper = validator.validate(
          fileName: 'workout.FIT',
          fileSizeBytes: size,
          content: content,
        );
        final resultMixed = validator.validate(
          fileName: 'data.CsV',
          fileSizeBytes: size,
          content: content,
        );

        expect(resultUpper.success, isTrue);
        expect(resultMixed.success, isTrue);
      });

      test('lists allowed formats in error message', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'file.txt',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('.fit'));
        expect(result.errorMessage, contains('.csv'));
        expect(result.errorMessage, contains('.tcx'));
      });
    });

    group('path traversal prevention', () {
      test('rejects filename with ../ sequence', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: '../../../etc/passwd.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('path traversal'));
      });

      test('rejects filename with ..\\ sequence (Windows)', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: '..\\..\\..\\windows\\system32\\config.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('path traversal'));
      });

      test('accepts filename with dots but not traversal', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'my.file.with.dots.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });

      test('accepts simple filename without path', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'workout.fit',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });
    });

    group('content size validation', () {
      test('rejects when content size does not match declared size', () {
        const declaredSize = 1024;
        final content = Uint8List(512); // Different from declared

        final result = validator.validate(
          fileName: 'test.csv',
          fileSizeBytes: declaredSize,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('size mismatch'));
        expect(result.errorMessage, contains('1024'));
        expect(result.errorMessage, contains('512'));
      });

      test('accepts when content size matches declared size', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'test.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });
    });

    group('edge cases', () {
      test('accepts empty file (zero bytes)', () {
        const size = 0;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'empty.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });

      test('handles complex filename with valid extension', () {
        const size = 1024;
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'my workout - 2026-01-25 (morning session).fit',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
      });
    });

    group('executable content detection (FR-019)', () {
      test('rejects Windows PE executable (MZ header)', () {
        final content = Uint8List.fromList([
          0x4D, 0x5A, // MZ signature
          ...List.filled(1022, 0),
        ]);

        final result = validator.validate(
          fileName: 'malicious.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('executable content'));
      });

      test('rejects ELF executable (Linux)', () {
        final content = Uint8List.fromList([
          0x7F, 0x45, 0x4C, 0x46, // ELF signature
          ...List.filled(1020, 0),
        ]);

        final result = validator.validate(
          fileName: 'malicious.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('executable content'));
      });

      test('rejects Mach-O executable (macOS)', () {
        final content = Uint8List.fromList([
          0xFE, 0xED, 0xFA, 0xCE, // 32-bit Mach-O
          ...List.filled(1020, 0),
        ]);

        final result = validator.validate(
          fileName: 'malicious.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('executable content'));
      });

      test('rejects script with shebang', () {
        final content = Uint8List.fromList([
          0x23, 0x21, // #!
          ...List.filled(1022, 0x20),
        ]);

        final result = validator.validate(
          fileName: 'malicious.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('executable content'));
      });

      test('rejects Windows batch file', () {
        final content = Uint8List.fromList(
          '@echo off\r\ndel /f /q *.*'.codeUnits,
        );

        final result = validator.validate(
          fileName: 'malicious.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, contains('executable content'));
      });

      test('accepts valid CSV content', () {
        final content = Uint8List.fromList('timestamp,power,hr\n1,2,3'.codeUnits);

        final result = validator.validate(
          fileName: 'data.csv',
          fileSizeBytes: content.length,
          content: content,
        );

        expect(result.success, isTrue);
      });
    });

    group('large file warning (40-50MB)', () {
      test('provides warning for file at 40MB threshold', () {
        const size = 41943040; // 40 MB
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'large.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
        expect(result.warningMessage, isNotNull);
        expect(result.warningMessage, contains('Large file may take longer to process'));
      });

      test('provides warning for file at 45MB', () {
        const size = 47185920; // 45 MB
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'large.fit',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
        expect(result.warningMessage, isNotNull);
        expect(result.warningMessage, contains('Large file may take longer to process'));
      });

      test('no warning for file under 40MB', () {
        const size = 41943039; // Just under 40 MB
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'medium.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
        expect(result.warningMessage, isNull);
      });

      test('no warning for small file', () {
        const size = 1024; // 1 KB
        final content = Uint8List(size);

        final result = validator.validate(
          fileName: 'small.csv',
          fileSizeBytes: size,
          content: content,
        );

        expect(result.success, isTrue);
        expect(result.warningMessage, isNull);
      });
    });
  });
}
