// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/agentic/tools/data_store.dart';
import 'package:braven_charts/src/agentic/widgets/data_preview.dart';
import 'package:flutter/material.dart' hide DataColumn;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataPreview', () {
    late DataStore store;

    setUp(() {
      store = DataStore();
    });

    testWidgets('displays file name and row count', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'workout.fit',
        fileType: 'fit',
        columns: [],
        rowCount: 100,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.text('workout.fit'), findsOneWidget);
      expect(find.text('100 rows'), findsOneWidget);
    });

    testWidgets('displays column list', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'data.csv',
        fileType: 'csv',
        columns: [
          DataColumn(
            name: 'power',
            type: 'number',
            nullable: false,
            data: const [150, 200, 250],
            stats: ColumnStats(
              nullCount: 0,
              min: 100,
              max: 300,
              mean: 200,
            ),
            sampleValues: const [150, 200, 250],
          ),
          DataColumn(
            name: 'heart_rate',
            type: 'number',
            nullable: false,
            data: const [130, 150, 170],
            stats: ColumnStats(
              nullCount: 0,
              min: 120,
              max: 180,
              mean: 150,
            ),
            sampleValues: const [130, 150, 170],
          ),
        ],
        rowCount: 50,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.text('power'), findsOneWidget);
      expect(find.text('heart_rate'), findsOneWidget);
    });

    testWidgets('displays column types', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'data.csv',
        fileType: 'csv',
        columns: [
          DataColumn(
            name: 'temperature',
            type: 'number',
            nullable: false,
            data: const [],
            stats: ColumnStats(nullCount: 0),
            sampleValues: const [],
          ),
          DataColumn(
            name: 'notes',
            type: 'string',
            nullable: false,
            data: const [],
            stats: ColumnStats(nullCount: 0),
            sampleValues: const [],
          ),
          DataColumn(
            name: 'timestamp',
            type: 'datetime',
            nullable: false,
            data: const [],
            stats: ColumnStats(nullCount: 0),
            sampleValues: const [],
          ),
        ],
        rowCount: 10,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.text('number'), findsOneWidget);
      expect(find.text('string'), findsOneWidget);
      expect(find.text('datetime'), findsOneWidget);
    });

    testWidgets('displays nullable flag for nullable columns', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'data.csv',
        fileType: 'csv',
        columns: [
          DataColumn(
            name: 'cadence',
            type: 'number',
            nullable: true,
            data: const [],
            stats: ColumnStats(nullCount: 5),
            sampleValues: const [],
          ),
        ],
        rowCount: 50,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.text('nullable'), findsOneWidget);
    });

    testWidgets('displays statistics for numeric columns', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'data.csv',
        fileType: 'csv',
        columns: [
          DataColumn(
            name: 'power',
            type: 'number',
            nullable: false,
            data: const [],
            stats: ColumnStats(
              nullCount: 0,
              min: 150,
              max: 350,
              mean: 250.5,
            ),
            sampleValues: const [],
          ),
        ],
        rowCount: 100,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.textContaining('Min: 150'), findsOneWidget);
      expect(find.textContaining('Max: 350'), findsOneWidget);
      expect(find.textContaining('Mean: 250.50'), findsOneWidget);
    });

    testWidgets('displays null count when present', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'data.csv',
        fileType: 'csv',
        columns: [
          DataColumn(
            name: 'cadence',
            type: 'number',
            nullable: true,
            data: const [],
            stats: ColumnStats(
              nullCount: 15,
              min: 60,
              max: 100,
              mean: 80,
            ),
            sampleValues: const [],
          ),
        ],
        rowCount: 100,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.textContaining('Nulls: 15'), findsOneWidget);
    });

    testWidgets('displays sample values when available', (tester) async {
      const dataId = 'test-data-id';
      final frame = DataFrame(
        fileName: 'data.csv',
        fileType: 'csv',
        columns: [
          DataColumn(
            name: 'power',
            type: 'number',
            nullable: false,
            data: const [150, 200, 250],
            stats: ColumnStats(
              nullCount: 0,
              min: 100,
              max: 300,
            ),
            sampleValues: const [150, 200, 250],
          ),
        ],
        rowCount: 100,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.textContaining('Samples: 150, 200, 250'), findsOneWidget);
    });

    testWidgets('shows error message when data not found', (tester) async {
      const dataId = 'non-existent-id';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      expect(find.text('Data not found'), findsOneWidget);
    });

    group('type icons', () {
      testWidgets('displays correct icon for number type', (tester) async {
        const dataId = 'test-data-id';
        final frame = DataFrame(
          fileName: 'data.csv',
          fileType: 'csv',
          columns: [
            DataColumn(
              name: 'value',
              type: 'number',
              nullable: false,
              data: const [],
              stats: ColumnStats(nullCount: 0),
              sampleValues: const [],
            ),
          ],
          rowCount: 10,
        );
        store.store(dataId, frame);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DataPreview(dataId: dataId),
            ),
          ),
        );

        expect(find.byIcon(Icons.tag), findsOneWidget);
      });

      testWidgets('displays correct icon for string type', (tester) async {
        const dataId = 'test-data-id';
        final frame = DataFrame(
          fileName: 'data.csv',
          fileType: 'csv',
          columns: [
            DataColumn(
              name: 'name',
              type: 'string',
              nullable: false,
              data: const [],
              stats: ColumnStats(nullCount: 0),
              sampleValues: const [],
            ),
          ],
          rowCount: 10,
        );
        store.store(dataId, frame);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DataPreview(dataId: dataId),
            ),
          ),
        );

        expect(find.byIcon(Icons.text_fields), findsOneWidget);
      });

      testWidgets('displays correct icon for datetime type', (tester) async {
        const dataId = 'test-data-id';
        final frame = DataFrame(
          fileName: 'data.csv',
          fileType: 'csv',
          columns: [
            DataColumn(
              name: 'timestamp',
              type: 'datetime',
              nullable: false,
              data: const [],
              stats: ColumnStats(nullCount: 0),
              sampleValues: const [],
            ),
          ],
          rowCount: 10,
        );
        store.store(dataId, frame);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DataPreview(dataId: dataId),
            ),
          ),
        );

        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });
    });

    testWidgets('handles scrolling for many columns', (tester) async {
      const dataId = 'test-data-id';
      final columns = List.generate(
        20,
        (i) => DataColumn(
          name: 'column_$i',
          type: 'number',
          nullable: false,
          data: const [],
          stats: ColumnStats(nullCount: 0, min: i, max: i + 100),
          sampleValues: const [],
        ),
      );
      final frame = DataFrame(
        fileName: 'large_data.csv',
        fileType: 'csv',
        columns: columns,
        rowCount: 1000,
      );
      store.store(dataId, frame);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataPreview(dataId: dataId),
          ),
        ),
      );

      // Should find ListView for scrollable columns
      expect(find.byType(ListView), findsOneWidget);

      // First column should be visible
      expect(find.text('column_0'), findsOneWidget);

      // Last column might not be visible initially (scroll needed)
      // This tests that the widget handles many columns properly
    });
  });
}
