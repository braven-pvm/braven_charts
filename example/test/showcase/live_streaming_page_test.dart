import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/live_streaming_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('live stream covers the complete streaming workflow', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LiveStreamingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Live Streaming'), findsOneWidget);
    expect(find.text('Buffer Settings'), findsOneWidget);
    expect(find.text('Viewport Mode'), findsOneWidget);

    final options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Data Generation'),
      300,
      scrollable: options,
    );
    expect(find.text('Data Generation'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Data Flow'),
      300,
      scrollable: options,
    );
    expect(find.text('Data Flow'), findsOneWidget);

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.liveStreamController, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
