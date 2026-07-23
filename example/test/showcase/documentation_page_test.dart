import 'package:braven_charts_example/showcase/pages/documentation_page.dart';
import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:flutter/material.dart';
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

    await tester.tap(find.byKey(const ValueKey('docs-choose-family')));
    await tester.pump();
    expect(opened, ['chart-types']);
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
}
