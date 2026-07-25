import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/generated/public_docs_catalog.g.dart';
import 'package:braven_charts_example/showcase/pages/documentation_page.dart';
import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('documentation home exposes the primary developer routes', (
    tester,
  ) async {
    final opened = <String>[];
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DocumentationPage(onOpenPage: opened.add)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('documentation-home')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('docs-build-first-chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('docs-choose-family')), findsOneWidget);
    expect(find.byKey(const ValueKey('docs-browse-api')), findsOneWidget);
    expect(find.text('Explore by what you need to build'), findsOneWidget);
    expect(find.text('Two ways to build the same chart'), findsOneWidget);
    expect(
      find.text('${publicDocsChartFamilies.length} families'),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('docs-feature-chart-families')))
          .height,
      128,
    );

    await tester.tap(find.byKey(const ValueKey('docs-feature-chart-families')));
    await tester.pump();
    expect(opened, ['chart-types']);
    opened.clear();

    await tester.tap(find.byKey(const ValueKey('docs-choose-family')));
    await tester.pump();
    expect(opened, ['chart-types']);
  });

  testWidgets('quick start uses the shared code view and copies either form', (
    tester,
  ) async {
    MethodCall? clipboardCall;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardCall = call;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DocumentationPage(onOpenPage: (_) {})),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('docs-snippet-viewer')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChartCodeBlock), findsOneWidget);
    expect(
      find.byKey(const ValueKey('docs-snippet-code-window')),
      findsOneWidget,
    );
    var code = tester.widget<Text>(
      find.byKey(const ValueKey('docs-snippet-code')),
    );
    expect(code.textSpan?.toPlainText(), contains('class BasicLineChart'));

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('docs-snippet-form-toggle')),
        matching: find.text('Grammar'),
      ),
    );
    await tester.pumpAndSettle();

    code = tester.widget<Text>(find.byKey(const ValueKey('docs-snippet-code')));
    expect(code.textSpan?.toPlainText(), contains('BravenChart.of'));

    await tester.tap(find.byKey(const ValueKey('docs-copy-snippet')));
    await tester.pump();
    expect(clipboardCall?.method, 'Clipboard.setData');
    final clipboardArguments =
        clipboardCall?.arguments as Map<Object?, Object?>;
    expect(clipboardArguments['text'], contains('BravenChart.of'));
  });

  testWidgets('docs route remains documentation on a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ShowcaseHome(requestedPageOverride: 'docs')),
    );
    await tester.pump();

    expect(find.byType(DocumentationPage), findsOneWidget);
    expect(find.byKey(const ValueKey('documentation-home')), findsOneWidget);
  });

  testWidgets('docs route keeps showcase navigation on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ShowcaseHome(requestedPageOverride: 'docs')),
    );
    await tester.pump();

    expect(find.byType(DocumentationPage), findsOneWidget);
    expect(find.byKey(const ValueKey('documentation-home')), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  for (final viewport in <String, Size>{
    'phone': const Size(390, 844),
    'tablet': const Size(768, 1024),
    'desktop': const Size(1440, 1000),
  }.entries) {
    testWidgets('documentation cards fit the ${viewport.key} viewport', (
      tester,
    ) async {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: DocumentationPage(onOpenPage: (_) {})),
      );
      await tester.pump();

      final card = find.byKey(const ValueKey('docs-feature-chart-families'));
      if (card.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          card,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('documentation-home')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tester.pump();
      expect(card, findsOneWidget);
      expect(tester.getSize(card).height, 128);
      expect(tester.getTopLeft(card).dx, greaterThanOrEqualTo(0));
      expect(
        tester.getTopRight(card).dx,
        lessThanOrEqualTo(viewport.value.width),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
