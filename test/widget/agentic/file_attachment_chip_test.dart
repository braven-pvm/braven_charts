// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:braven_charts/src/agentic/models/file_attachment.dart';
import 'package:braven_charts/src/agentic/widgets/file_attachment_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileAttachmentChip', () {
    testWidgets('displays file name', (tester) async {
      final attachment = FileAttachment(
        id: 'test-id',
        fileName: 'workout.fit',
        fileType: 'fit',
        fileSizeBytes: 1024,
        content: Uint8List(1024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileAttachmentChip(attachment: attachment),
          ),
        ),
      );

      expect(find.text('workout.fit'), findsOneWidget);
    });

    testWidgets('displays formatted file size in KB', (tester) async {
      final attachment = FileAttachment(
        id: 'test-id',
        fileName: 'data.csv',
        fileType: 'csv',
        fileSizeBytes: 2048, // 2 KB
        content: Uint8List(2048),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileAttachmentChip(attachment: attachment),
          ),
        ),
      );

      expect(find.text('2.0 KB'), findsOneWidget);
    });

    testWidgets('displays formatted file size in MB', (tester) async {
      final attachment = FileAttachment(
        id: 'test-id',
        fileName: 'large.fit',
        fileType: 'fit',
        fileSizeBytes: 5242880, // 5 MB
        content: Uint8List(5242880),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileAttachmentChip(attachment: attachment),
          ),
        ),
      );

      expect(find.text('5.00 MB'), findsOneWidget);
    });

    testWidgets('truncates long file name', (tester) async {
      final attachment = FileAttachment(
        id: 'test-id',
        fileName: 'this_is_a_very_long_filename_that_should_be_truncated.fit',
        fileType: 'fit',
        fileSizeBytes: 1024,
        content: Uint8List(1024),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileAttachmentChip(attachment: attachment),
          ),
        ),
      );

      // Should find text widget with truncated name (with ...)
      final textWidgets = find.byType(Text);
      final truncatedText = textWidgets
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .firstWhere((text) => text != null && text.contains('...'),
              orElse: () => null);

      expect(truncatedText, isNotNull);
      expect(truncatedText, contains('.fit')); // Extension should be preserved
    });

    group('status icons', () {
      testWidgets('shows pending icon for pending status', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.pending,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('shows progress indicator for parsing status',
          (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.parsing,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows check icon for ready status', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.ready,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('shows error icon for error status', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.error,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('file type icons', () {
      testWidgets('shows fitness icon for FIT files', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'workout.fit',
          fileType: 'fit',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      });

      testWidgets('shows table icon for CSV files', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'data.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byIcon(Icons.table_chart), findsOneWidget);
      });

      testWidgets('shows route icon for TCX files', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'activity.tcx',
          fileType: 'tcx',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        expect(find.byIcon(Icons.route), findsOneWidget);
      });
    });

    group('remove interaction', () {
      testWidgets('calls onRemove when delete icon is tapped', (tester) async {
        bool removeCalled = false;
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(
                attachment: attachment,
                onRemove: () {
                  removeCalled = true;
                },
              ),
            ),
          ),
        );

        // Find and tap the close icon
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(removeCalled, isTrue);
      });

      testWidgets('does not show delete icon when onRemove is null',
          (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(
                attachment: attachment,
                onRemove: null,
              ),
            ),
          ),
        );

        // Close icon should not be visible when onRemove is null
        expect(find.byIcon(Icons.close), findsNothing);
      });
    });

    group('chip colors', () {
      testWidgets('uses error color for error status', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.error,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        expect(chip.backgroundColor, equals(Colors.red[50]));
      });

      testWidgets('uses success color for ready status', (tester) async {
        final attachment = FileAttachment(
          id: 'test-id',
          fileName: 'test.csv',
          fileType: 'csv',
          fileSizeBytes: 1024,
          content: Uint8List(1024),
          status: FileStatus.ready,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileAttachmentChip(attachment: attachment),
            ),
          ),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        expect(chip.backgroundColor, equals(Colors.green[50]));
      });
    });
  });
}
