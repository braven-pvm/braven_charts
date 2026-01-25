import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/widgets/error_message.dart';

void main() {
  testWidgets('renders message and retry button', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorMessage(
            message: 'Something went wrong',
            onRetry: () => retryCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byKey(const Key('error_retry_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('error_retry_button')));
    await tester.pump();

    expect(retryCount, equals(1));
  });

  testWidgets('hides retry button when callback is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ErrorMessage(
            message: 'Try again later',
          ),
        ),
      ),
    );

    expect(find.text('Try again later'), findsOneWidget);
    expect(find.byKey(const Key('error_retry_button')), findsNothing);
  });
}
