import 'package:braven_charts/src/agentic/models/axis_config.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';
import 'package:braven_charts/src/agentic/widgets/config_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfigPanel', () {
    late ChartConfiguration testChart;

    setUp(() {
      // Create a test chart configuration with various settings
      testChart = ChartConfiguration(
        id: 'test-chart-1',
        type: ChartType.line,
        title: 'Test Chart',
        theme: 'light',
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [1, 2, 3],
            yAxisId: 'y1',
          ),
        ],
        xAxis: XAxisConfig(label: 'X Axis'),
        yAxes: [
          YAxisConfig(id: 'y1', label: 'Y Axis', position: AxisPosition.left),
        ],
        grid: {'visible': true},
        legend: {'visible': true, 'position': 'bottom'},
      );
    });

    testWidgets('renders with initial configuration values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify ConfigPanel renders without errors
      expect(find.byType(ConfigPanel), findsOneWidget);
    });

    testWidgets('displays theme toggle control', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify theme control is visible
      expect(find.widgetWithText(SwitchListTile, 'Dark Theme'), findsOneWidget);

      // Verify theme switch reflects current state (light theme = off)
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Dark Theme'),
      );
      expect(switchTile.value, isFalse); // light theme = switch off
    });

    testWidgets('theme toggle triggers callback with updated configuration',
        (WidgetTester tester) async {
      ChartConfiguration? updatedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {
                updatedConfig = config;
              },
            ),
          ),
        ),
      );

      // Tap theme toggle
      await tester.tap(find.widgetWithText(SwitchListTile, 'Dark Theme'));
      await tester.pump();

      // Verify callback was triggered with updated theme
      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.theme, equals('dark'));
    });

    testWidgets('displays grid visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify grid visibility control is present
      expect(find.widgetWithText(SwitchListTile, 'Show Grid'), findsOneWidget);

      // Verify grid switch reflects current state (visible = on)
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Show Grid'),
      );
      expect(switchTile.value, isTrue); // grid visible = switch on
    });

    testWidgets('grid toggle triggers callback with updated configuration',
        (WidgetTester tester) async {
      ChartConfiguration? updatedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {
                updatedConfig = config;
              },
            ),
          ),
        ),
      );

      // Tap grid toggle
      await tester.tap(find.widgetWithText(SwitchListTile, 'Show Grid'));
      await tester.pump();

      // Verify callback was triggered with updated grid visibility
      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.grid, isNotNull);
      expect(updatedConfig!.grid['visible'], isFalse);
    });

    testWidgets('displays legend visibility toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify legend visibility control is present
      expect(
          find.widgetWithText(SwitchListTile, 'Show Legend'), findsOneWidget);

      // Verify legend switch reflects current state (visible = on)
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Show Legend'),
      );
      expect(switchTile.value, isTrue); // legend visible = switch on
    });

    testWidgets('legend toggle triggers callback with updated configuration',
        (WidgetTester tester) async {
      ChartConfiguration? updatedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {
                updatedConfig = config;
              },
            ),
          ),
        ),
      );

      // Tap legend toggle
      await tester.tap(find.widgetWithText(SwitchListTile, 'Show Legend'));
      await tester.pump();

      // Verify callback was triggered with updated legend visibility
      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.legend, isNotNull);
      expect(updatedConfig!.legend['visible'], isFalse);
    });

    testWidgets('displays legend position control',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify legend position control is present
      expect(find.text('Legend Position'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Verify dropdown shows current position
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.value, equals('bottom'));
    });

    testWidgets('legend position change triggers callback',
        (WidgetTester tester) async {
      ChartConfiguration? updatedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {
                updatedConfig = config;
              },
            ),
          ),
        ),
      );

      // Tap dropdown to open menu
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select 'top' position
      await tester.tap(find.text('Top').last);
      await tester.pumpAndSettle();

      // Verify callback was triggered with updated legend position
      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.legend, isNotNull);
      expect(updatedConfig!.legend['position'], equals('top'));
    });

    testWidgets('displays scrollbar visibility toggle',
        (WidgetTester tester) async {
      final chartWithScrollbar = ChartConfiguration(
        id: 'test-chart-2',
        type: ChartType.line,
        title: 'Test Chart with Scrollbar',
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [1, 2, 3],
            yAxisId: 'y1',
          ),
        ],
        xAxis: XAxisConfig(label: 'X Axis'),
        yAxes: [
          YAxisConfig(id: 'y1', label: 'Y Axis', position: AxisPosition.left),
        ],
        interactions: {
          'scrollbar': {'enabled': true}
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: chartWithScrollbar,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify scrollbar visibility control is present
      expect(find.widgetWithText(SwitchListTile, 'Show Scrollbar'),
          findsOneWidget);

      // Verify scrollbar switch reflects current state (enabled = on)
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Show Scrollbar'),
      );
      expect(switchTile.value, isTrue); // scrollbar enabled = switch on
    });

    testWidgets('scrollbar toggle triggers callback with updated configuration',
        (WidgetTester tester) async {
      ChartConfiguration? updatedConfig;

      final chartWithScrollbar = ChartConfiguration(
        id: 'test-chart-2',
        type: ChartType.line,
        title: 'Test Chart with Scrollbar',
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [1, 2, 3],
            yAxisId: 'y1',
          ),
        ],
        xAxis: XAxisConfig(label: 'X Axis'),
        yAxes: [
          YAxisConfig(id: 'y1', label: 'Y Axis', position: AxisPosition.left),
        ],
        interactions: {
          'scrollbar': {'enabled': true}
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: chartWithScrollbar,
              onConfigurationChanged: (config) {
                updatedConfig = config;
              },
            ),
          ),
        ),
      );

      // Tap scrollbar toggle
      await tester.tap(find.widgetWithText(SwitchListTile, 'Show Scrollbar'));
      await tester.pump();

      // Verify callback was triggered with updated scrollbar state
      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.interactions, isNotNull);
      expect(updatedConfig!.interactions['scrollbar']['enabled'], isFalse);
    });

    testWidgets('callback triggers complete within 100ms (performance)',
        (WidgetTester tester) async {
      ChartConfiguration? updatedConfig;
      DateTime? callbackTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: testChart,
              onConfigurationChanged: (config) {
                updatedConfig = config;
                callbackTime = DateTime.now();
              },
            ),
          ),
        ),
      );

      final startTime = DateTime.now();

      // Tap theme toggle
      await tester.tap(find.widgetWithText(SwitchListTile, 'Dark Theme'));
      await tester.pump();

      // Verify callback triggered and latency is < 100ms
      expect(updatedConfig, isNotNull);
      expect(callbackTime, isNotNull);
      final latency = callbackTime!.difference(startTime).inMilliseconds;
      expect(latency, lessThan(100));
    });

    testWidgets('handles configuration with missing optional fields',
        (WidgetTester tester) async {
      final minimalChart = ChartConfiguration(
        id: 'minimal-chart',
        type: ChartType.line,
        title: 'Minimal Chart',
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [1, 2, 3],
            yAxisId: 'y1',
          ),
        ],
        xAxis: XAxisConfig(label: 'X Axis'),
        yAxes: [
          YAxisConfig(id: 'y1', label: 'Y Axis', position: AxisPosition.left),
        ],
        // No theme, grid, legend, or interactions specified
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfigPanel(
              configuration: minimalChart,
              onConfigurationChanged: (config) {},
            ),
          ),
        ),
      );

      // Verify ConfigPanel renders with sensible defaults
      expect(find.byType(ConfigPanel), findsOneWidget);

      // Verify all controls are present even with minimal config
      expect(find.widgetWithText(SwitchListTile, 'Dark Theme'), findsOneWidget);
      expect(find.widgetWithText(SwitchListTile, 'Show Grid'), findsOneWidget);
      expect(
          find.widgetWithText(SwitchListTile, 'Show Legend'), findsOneWidget);
    });

    testWidgets('integrates with ValueNotifier pattern',
        (WidgetTester tester) async {
      final configNotifier = ValueNotifier<ChartConfiguration>(testChart);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<ChartConfiguration>(
              valueListenable: configNotifier,
              builder: (context, config, child) {
                return ConfigPanel(
                  configuration: config,
                  onConfigurationChanged: (newConfig) {
                    configNotifier.value = newConfig;
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(configNotifier.value.theme, equals('light'));

      // Toggle theme
      await tester.tap(find.widgetWithText(SwitchListTile, 'Dark Theme'));
      await tester.pump();

      // Verify ValueNotifier was updated
      expect(configNotifier.value.theme, equals('dark'));

      // Verify UI reflects the new state
      await tester.pump(); // Rebuild after notifier change
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Dark Theme'),
      );
      expect(switchTile.value, isTrue); // dark theme = switch on
    });
  });
}
