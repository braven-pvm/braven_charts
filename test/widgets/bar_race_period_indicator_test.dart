import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the frame label and optional formatted total', (
    tester,
  ) async {
    final controller = BarRaceController(
      config: BarRaceConfig(
        categories: const [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(
            id: '2025',
            label: 'FY 2025',
            values: {'a': 42},
            total: 42,
          ),
        ],
        showTotal: true,
        periodStyle: BarRacePeriodStyle(
          position: BarRacePeriodPosition.topLeft,
          fontSize: 68,
          color: Colors.purple,
          opacity: 0.8,
          inset: 16,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.expand(
          child: BarRacePeriodIndicator(
            controller: controller,
            totalFormatter: (value) => '${value.round()} units',
          ),
        ),
      ),
    );

    expect(find.text('FY 2025'), findsOneWidget);
    expect(find.text('42 units'), findsOneWidget);
    final label = tester.widget<Text>(find.text('FY 2025'));
    expect(label.style?.fontSize, 68);
    expect(label.style?.color, Colors.purple);
    expect(tester.getTopLeft(find.text('FY 2025')), const Offset(16, 16));
  });

  testWidgets('hides the period label when disabled', (tester) async {
    final controller = BarRaceController(
      config: BarRaceConfig(
        categories: const [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(id: 'one', label: 'One', values: {'a': 1}),
        ],
        showPeriod: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: BarRacePeriodIndicator(controller: controller)),
    );

    expect(find.text('One'), findsNothing);
  });

  testWidgets('uses portable period and total format descriptors', (
    tester,
  ) async {
    final controller = BarRaceController(
      config: BarRaceConfig(
        categories: const [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(
            id: 'jan',
            label: 'January checkpoint',
            timestamp: DateTime(1965, 1),
            values: {'a': 1250},
            total: 1250,
          ),
        ],
        showTotal: true,
        periodFormat: const BarRacePeriodFormat(pattern: '{MMM} {yyyy}'),
        totalFormat: const BarRaceValueFormat(
          pattern: '{value} residents',
          decimalPlaces: 1,
          scale: 1000,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: BarRacePeriodIndicator(controller: controller)),
    );

    expect(find.text('Jan 1965'), findsOneWidget);
    expect(find.text('1.3 residents'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Jan 1965, 1.3 residents'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('counts the aggregate through an in-flight frame', (
    tester,
  ) async {
    final controller = BarRaceController(
      config: const BarRaceConfig(
        categories: [
          BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        ],
        frames: [
          BarRaceFrame(
            id: 'jan',
            label: 'January 1965',
            values: {'a': 100},
            total: 100,
          ),
          BarRaceFrame(
            id: 'feb',
            label: 'February 1965',
            values: {'a': 200},
            total: 200,
          ),
        ],
        showTotal: true,
      ),
    )..play();

    await tester.pumpWidget(
      MaterialApp(
        home: BarRacePeriodIndicator(
          controller: controller,
          totalFormatter: (value) => value.toStringAsFixed(0),
        ),
      ),
    );

    controller.next();
    controller.updateAxisTransitionProgress(0.35);
    await tester.pump();

    expect(find.text('February 1965'), findsOneWidget);
    expect(find.text('135'), findsOneWidget);
  });
}
