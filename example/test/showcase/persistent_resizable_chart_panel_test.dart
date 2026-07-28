// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts_example/showcase/platform/showcase_preference_store_contract.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:braven_charts_example/showcase/widgets/persistent_resizable_chart_panel.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const preferenceKey = 'test.chart.height';
  const panelKey = ValueKey('test-chart-panel');
  const handleKey = ValueKey('chart-panel-resize-handle');

  Widget buildSubject(_MemoryPreferenceStore store) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 700,
          child: PersistentResizableChartPanelWorkspace(
            preferenceKey: preferenceKey,
            preferenceStore: store,
            minimumPanelHeight: 300,
            maximumPanelHeight: 800,
            leading: const [SizedBox(height: 100)],
            trailing: const [SizedBox(height: 50)],
            panel: const ColoredBox(key: panelKey, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  testWidgets('dragging resizes and persists the measured panel height', (
    tester,
  ) async {
    final store = _MemoryPreferenceStore();
    await tester.pumpWidget(buildSubject(store));

    expect(tester.getSize(find.byKey(panelKey)).height, 402);

    await tester.drag(find.byKey(handleKey), const Offset(0, 90));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getSize(find.byKey(panelKey)).height, 472);
    expect(store.values[preferenceKey], '472.0');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(buildSubject(store));
    await tester.pump();

    expect(tester.getSize(find.byKey(panelKey)).height, 472);
  });

  testWidgets(
    'keyboard controls enforce bounds and Escape restores auto size',
    (tester) async {
      final store = _MemoryPreferenceStore();
      await tester.pumpWidget(buildSubject(store));

      await tester.tap(find.byKey(handleKey));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Showcase chart panel resize handle',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(tester.getSize(find.byKey(panelKey)).height, 800);
      expect(store.values[preferenceKey], '800.0');

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(tester.getSize(find.byKey(panelKey)).height, 300);
      expect(store.values[preferenceKey], '300.0');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tester.getSize(find.byKey(panelKey)).height, 316);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(tester.getSize(find.byKey(panelKey)).height, 402);
      expect(store.values, isNot(contains(preferenceKey)));
    },
  );

  testWidgets('double-click resets and invalid stored values are ignored', (
    tester,
  ) async {
    final store = _MemoryPreferenceStore()
      ..values[preferenceKey] = 'not-a-height';
    await tester.pumpWidget(buildSubject(store));
    expect(tester.getSize(find.byKey(panelKey)).height, 402);

    await tester.drag(find.byKey(handleKey), const Offset(0, -1000));
    await tester.pump();
    expect(tester.getSize(find.byKey(panelKey)).height, 300);

    await tester.tap(find.byKey(handleKey));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(handleKey));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(panelKey)).height, 402);
    expect(store.values, isNot(contains(preferenceKey)));
  });

  testWidgets('semantics explain drag, keyboard, and reset behavior', (
    tester,
  ) async {
    final store = _MemoryPreferenceStore();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildSubject(store));

    expect(
      tester.getSemantics(find.byKey(handleKey)),
      matchesSemantics(
        label: 'Resize chart panel',
        value: 'Automatic height',
        hint:
            'Drag vertically or use the Up and Down arrow keys. '
            'Press Escape or double-click to restore automatic height.',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('Scatter uses the shared handle to resize its complete card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScatterChartsPage())),
    );
    await tester.pumpAndSettle();

    final handle = find.byKey(handleKey);
    final card = find.byType(ChartCard);
    expect(handle, findsOneWidget);
    expect(card, findsOneWidget);
    final semantics = tester.getSemantics(handle);
    expect(semantics.value, '600 pixels high');
    expect(semantics.increasedValue, '616 pixels high');
    expect(semantics.decreasedValue, '584 pixels high');
    final originalHeight = tester.getSize(card).height;

    await tester.ensureVisible(handle);
    await tester.pumpAndSettle();
    await tester.drag(handle, const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getSize(card).height, lessThan(originalHeight));
    expect(tester.takeException(), isNull);
  });
}

final class _MemoryPreferenceStore implements ShowcasePreferenceStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  void remove(String key) => values.remove(key);

  @override
  void write(String key, String value) => values[key] = value;
}
