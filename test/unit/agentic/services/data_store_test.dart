import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/src/agentic/services/data_store.dart';

void main() {
  group('DataStore', () {
    test('store returns UUID v4 and value is retrievable', () {
      final store = DataStore<String>();
      final id = store.store('alpha');

      expect(id, isA<String>());
      expect(_isValidUuidV4(id), isTrue);
      expect(store.get(id), equals('alpha'));
    });

    test('delete removes entry and returns true', () {
      final store = DataStore<int>();
      final id = store.store(42);

      final deleted = store.delete(id);

      expect(deleted, isTrue);
      expect(store.get(id), isNull);
    });

    test('list returns all stored items', () {
      final store = DataStore<String>();
      final firstId = store.store('a');
      final secondId = store.store('b');

      final all = store.list();

      expect(all.keys, containsAll(<String>[firstId, secondId]));
      expect(all.values, containsAll(<String>['a', 'b']));
    });

    test('get returns null for unknown id', () {
      final store = DataStore<String>();
      const missingId = '00000000-0000-4000-8000-000000000000';

      expect(store.get(missingId), isNull);
    });
  });
}

bool _isValidUuidV4(String id) {
  final uuidV4Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidV4Pattern.hasMatch(id);
}
