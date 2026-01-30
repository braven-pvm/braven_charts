// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/models.dart';

void main() {
  group('FileStatus', () {
    test('has all required enum values', () {
      expect(FileStatus.values.contains(FileStatus.pending), isTrue);
      expect(FileStatus.values.contains(FileStatus.parsing), isTrue);
      expect(FileStatus.values.contains(FileStatus.ready), isTrue);
      expect(FileStatus.values.contains(FileStatus.error), isTrue);
    });
  });

  group('FileAttachment', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        final content = Uint8List.fromList([1, 2, 3, 4, 5]);
        final attachment = FileAttachment(
          id: 'file-123',
          fileName: 'workout.fit',
          fileType: 'fit',
          fileSizeBytes: 5,
          content: content,
          status: FileStatus.ready,
        );

        expect(attachment.id, equals('file-123'));
        expect(attachment.fileName, equals('workout.fit'));
        expect(attachment.fileType, equals('fit'));
        expect(attachment.fileSizeBytes, equals(5));
        expect(attachment.content, equals(content));
        expect(attachment.status, equals(FileStatus.ready));
        expect(attachment.dataId, isNull);
        expect(attachment.errorMessage, isNull);
      });

      test('creates instance in pending status', () {
        final attachment = FileAttachment(
          id: 'file-456',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.pending,
        );

        expect(attachment.status, equals(FileStatus.pending));
        expect(attachment.dataId, isNull);
      });

      test('creates instance with error status and message', () {
        final attachment = FileAttachment(
          id: 'file-789',
          fileName: 'invalid.csv',
          fileType: 'csv',
          fileSizeBytes: 100,
          content: Uint8List(100),
          status: FileStatus.error,
          errorMessage: 'Unsupported file format',
        );

        expect(attachment.status, equals(FileStatus.error));
        expect(attachment.errorMessage, equals('Unsupported file format'));
      });

      test('creates instance with dataId reference when ready', () {
        final attachment = FileAttachment(
          id: 'file-ready',
          fileName: 'training.csv',
          fileType: 'csv',
          fileSizeBytes: 2048,
          content: Uint8List(2048),
          status: FileStatus.ready,
          dataId: '550e8400-e29b-41d4-a716-446655440000',
        );

        expect(attachment.status, equals(FileStatus.ready));
        expect(
            attachment.dataId, equals('550e8400-e29b-41d4-a716-446655440000'));
      });

      test('throws assertion error when id is empty', () {
        expect(
          () => FileAttachment(
            id: '',
            fileName: 'file.csv',
            fileType: 'csv',
            fileSizeBytes: 100,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when fileName is empty', () {
        expect(
          () => FileAttachment(
            id: 'file-1',
            fileName: '',
            fileType: 'csv',
            fileSizeBytes: 100,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when fileType is empty', () {
        expect(
          () => FileAttachment(
            id: 'file-1',
            fileName: 'data.csv',
            fileType: '',
            fileSizeBytes: 100,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when file size exceeds 50 MB limit', () {
        const maxSize = 52428800; // 50 MB

        expect(
          () => FileAttachment(
            id: 'file-too-large',
            fileName: 'huge.fit',
            fileType: 'fit',
            fileSizeBytes: maxSize + 1,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });

      test('allows file size exactly at 50 MB limit', () {
        const maxSize = 52428800; // 50 MB

        final attachment = FileAttachment(
          id: 'file-max-size',
          fileName: 'large.fit',
          fileType: 'fit',
          fileSizeBytes: maxSize,
          content: Uint8List(100),
          status: FileStatus.ready,
        );

        expect(attachment.fileSizeBytes, equals(maxSize));
      });

      test('throws assertion error when file size is negative', () {
        expect(
          () => FileAttachment(
            id: 'file-1',
            fileName: 'data.csv',
            fileType: 'csv',
            fileSizeBytes: -100,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });

      test('validates allowed file types', () {
        // FIT file is valid
        expect(
          () => FileAttachment(
            id: 'file-fit',
            fileName: 'workout.fit',
            fileType: 'fit',
            fileSizeBytes: 1000,
            content: Uint8List(1000),
            status: FileStatus.ready,
          ),
          returnsNormally,
        );

        // CSV file is valid
        expect(
          () => FileAttachment(
            id: 'file-csv',
            fileName: 'data.csv',
            fileType: 'csv',
            fileSizeBytes: 1000,
            content: Uint8List(1000),
            status: FileStatus.ready,
          ),
          returnsNormally,
        );

        // JSON file is valid
        expect(
          () => FileAttachment(
            id: 'file-json',
            fileName: 'config.json',
            fileType: 'json',
            fileSizeBytes: 1000,
            content: Uint8List(1000),
            status: FileStatus.ready,
          ),
          returnsNormally,
        );

        // TCX file is valid
        expect(
          () => FileAttachment(
            id: 'file-tcx',
            fileName: 'activity.tcx',
            fileType: 'tcx',
            fileSizeBytes: 1000,
            content: Uint8List(1000),
            status: FileStatus.ready,
          ),
          returnsNormally,
        );

        // Invalid file type should fail
        expect(
          () => FileAttachment(
            id: 'file-invalid',
            fileName: 'malicious.exe',
            fileType: 'exe',
            fileSizeBytes: 1000,
            content: Uint8List(1000),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });

      test('sanitizes fileName to prevent path traversal', () {
        // Path traversal attempts should fail
        expect(
          () => FileAttachment(
            id: 'file-1',
            fileName: '../../../etc/passwd',
            fileType: 'csv',
            fileSizeBytes: 100,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );

        expect(
          () => FileAttachment(
            id: 'file-2',
            fileName: '..\\..\\windows\\system32\\config',
            fileType: 'csv',
            fileSizeBytes: 100,
            content: Uint8List(100),
            status: FileStatus.ready,
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final content = Uint8List.fromList([65, 66, 67]); // ABC
        final attachment = FileAttachment(
          id: 'file-123',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 3,
          content: content,
          status: FileStatus.ready,
          dataId: '550e8400-e29b-41d4-a716-446655440000',
        );

        final json = attachment.toJson();

        expect(json['id'], equals('file-123'));
        expect(json['fileName'], equals('data.csv'));
        expect(json['fileType'], equals('csv'));
        expect(json['fileSizeBytes'], equals(3));
        expect(json['status'], equals('ready'));
        expect(json['dataId'], equals('550e8400-e29b-41d4-a716-446655440000'));
      });

      test('toJson handles error status correctly', () {
        final attachment = FileAttachment(
          id: 'file-error',
          fileName: 'bad.csv',
          fileType: 'csv',
          fileSizeBytes: 100,
          content: Uint8List(100),
          status: FileStatus.error,
          errorMessage: 'Parse failed',
        );

        final json = attachment.toJson();

        expect(json['status'], equals('error'));
        expect(json['errorMessage'], equals('Parse failed'));
      });

      test('fromJson creates instance from map', () {
        final json = {
          'id': 'file-456',
          'fileName': 'workout.fit',
          'fileType': 'fit',
          'fileSizeBytes': 5000,
          'content': [1, 2, 3, 4, 5],
          'status': 'parsing',
        };

        final attachment = FileAttachment.fromJson(json);

        expect(attachment.id, equals('file-456'));
        expect(attachment.fileName, equals('workout.fit'));
        expect(attachment.fileType, equals('fit'));
        expect(attachment.fileSizeBytes, equals(5000));
        expect(attachment.status, equals(FileStatus.parsing));
      });

      test('JSON round-trip preserves data', () {
        final content = Uint8List.fromList([10, 20, 30, 40, 50]);
        final original = FileAttachment(
          id: 'file-round-trip',
          fileName: 'test.tcx',
          fileType: 'tcx',
          fileSizeBytes: 5,
          content: content,
          status: FileStatus.ready,
          dataId: '550e8400-e29b-41d4-a716-446655440000',
        );

        final json = original.toJson();
        final restored = FileAttachment.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.fileName, equals(original.fileName));
        expect(restored.fileType, equals(original.fileType));
        expect(restored.fileSizeBytes, equals(original.fileSizeBytes));
        expect(restored.status, equals(original.status));
        expect(restored.dataId, equals(original.dataId));
        expect(restored.content, equals(original.content));
      });
    });

    group('state transitions', () {
      test('transitions from pending to parsing', () {
        final original = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.pending,
        );

        final updated = original.copyWith(status: FileStatus.parsing);

        expect(original.status, equals(FileStatus.pending));
        expect(updated.status, equals(FileStatus.parsing));
      });

      test('transitions from parsing to ready with dataId', () {
        final original = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.parsing,
        );

        final updated = original.copyWith(
          status: FileStatus.ready,
          dataId: '550e8400-e29b-41d4-a716-446655440000',
        );

        expect(updated.status, equals(FileStatus.ready));
        expect(updated.dataId, equals('550e8400-e29b-41d4-a716-446655440000'));
      });

      test('transitions to error with error message', () {
        final original = FileAttachment(
          id: 'file-1',
          fileName: 'bad.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.parsing,
        );

        final updated = original.copyWith(
          status: FileStatus.error,
          errorMessage: 'Invalid CSV format',
        );

        expect(updated.status, equals(FileStatus.error));
        expect(updated.errorMessage, equals('Invalid CSV format'));
      });
    });

    group('copyWith', () {
      test('creates copy with updated status', () {
        final original = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.pending,
        );

        final copy = original.copyWith(status: FileStatus.ready);

        expect(copy.status, equals(FileStatus.ready));
        expect(original.status, equals(FileStatus.pending));
      });

      test('creates copy with added dataId', () {
        final original = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.parsing,
        );

        final copy = original.copyWith(
          dataId: '550e8400-e29b-41d4-a716-446655440000',
        );

        expect(copy.dataId, equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(original.dataId, isNull);
      });

      test('creates copy with added error message', () {
        final original = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.parsing,
        );

        final copy = original.copyWith(
          status: FileStatus.error,
          errorMessage: 'Failed to parse',
        );

        expect(copy.errorMessage, equals('Failed to parse'));
        expect(original.errorMessage, isNull);
      });
    });

    group('equality', () {
      test('equal attachments have same hash code', () {
        final content = Uint8List.fromList([1, 2, 3]);
        final attach1 = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 3,
          content: content,
          status: FileStatus.ready,
        );

        final attach2 = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 3,
          content: content,
          status: FileStatus.ready,
        );

        expect(attach1, equals(attach2));
        expect(attach1.hashCode, equals(attach2.hashCode));
      });

      test('different ids produce different attachments', () {
        final content = Uint8List.fromList([1, 2, 3]);
        final attach1 = FileAttachment(
          id: 'file-1',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 3,
          content: content,
          status: FileStatus.ready,
        );

        final attach2 = FileAttachment(
          id: 'file-2',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 3,
          content: content,
          status: FileStatus.ready,
        );

        expect(attach1, isNot(equals(attach2)));
      });
    });

    group('edge cases', () {
      test('handles empty file content', () {
        final attachment = FileAttachment(
          id: 'file-empty',
          fileName: 'empty.csv',
          fileType: 'csv',
          fileSizeBytes: 0,
          content: Uint8List(0),
          status: FileStatus.ready,
        );

        expect(attachment.content.length, equals(0));
        expect(attachment.fileSizeBytes, equals(0));
      });

      test('handles large file at limit', () {
        const maxSize = 52428800; // 50 MB
        final attachment = FileAttachment(
          id: 'file-large',
          fileName: 'large.fit',
          fileType: 'fit',
          fileSizeBytes: maxSize,
          content: Uint8List(1000), // Don't allocate full 50MB in test
          status: FileStatus.ready,
        );

        expect(attachment.fileSizeBytes, equals(maxSize));
      });

      test('handles file names with special characters', () {
        final attachment = FileAttachment(
          id: 'file-special',
          fileName: 'my-workout_2026.01.25_(zone-2).fit',
          fileType: 'fit',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.ready,
        );

        expect(
            attachment.fileName, equals('my-workout_2026.01.25_(zone-2).fit'));
      });

      test('handles unicode file names', () {
        final attachment = FileAttachment(
          id: 'file-unicode',
          fileName: 'тренировка.csv',
          fileType: 'csv',
          fileSizeBytes: 1000,
          content: Uint8List(1000),
          status: FileStatus.ready,
        );

        expect(attachment.fileName, equals('тренировка.csv'));
      });
    });
  });
}
