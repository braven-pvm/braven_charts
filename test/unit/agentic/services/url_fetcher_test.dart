// @orchestra-task: 21
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/services/url_fetcher.dart';

void main() {
  group('UrlFetcherService', () {
    late UrlFetcherService service;

    setUp(() {
      service = UrlFetcherService();
    });

    test('fetchData returns remote file contents on success', () async {
      final result = await service.fetchData('https://example.com/data.csv');

      expect(result, isNotEmpty);
      expect(result, contains(','));
    });

    test('fetchData throws NetworkException on connection failure', () async {
      expect(
        () => service.fetchData('https://example.com/offline.csv'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('fetchData throws ResourceNotFoundException on 404', () async {
      expect(
        () => service.fetchData('https://example.com/missing.csv'),
        throwsA(isA<ResourceNotFoundException>()),
      );
    });

    test('fetchData throws InvalidUrlException on malformed URL', () async {
      expect(
        () => service.fetchData('ht!tp://bad-url'),
        throwsA(isA<InvalidUrlException>()),
      );
    });
  });
}
