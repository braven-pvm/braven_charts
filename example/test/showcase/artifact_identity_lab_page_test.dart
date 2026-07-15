import 'package:braven_charts_plus_example/showcase/pages/artifact_identity_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactIdentityLabPage());

  testWidgets('groups document duplicates and invalidates changed content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());

    expect(find.text('2 duplicates grouped'), findsOneWidget);
    expect(find.text('Unique  1'), findsOneWidget);
    expect(find.textContaining('snapshot-a-copy'), findsOneWidget);

    await tester.tap(find.text('Change payload value'));
    await tester.pump();

    expect(find.text('1 duplicate grouped'), findsOneWidget);
    expect(find.text('Unique  2'), findsOneWidget);
    expect(
      find.text('A changed Y value now produces a distinct content hash.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('view scope separates durable view states', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.tap(find.text('Document + view'));
    await tester.pump();

    expect(find.text('1 duplicate grouped'), findsOneWidget);
    expect(find.text('Unique  2'), findsOneWidget);
    expect(
      find.text('Durable view state participates in the identity.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps identity controls usable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());

    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Document + view'), findsOneWidget);
    expect(find.text('Change payload value'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Per-payload identities'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Per-payload identities'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
