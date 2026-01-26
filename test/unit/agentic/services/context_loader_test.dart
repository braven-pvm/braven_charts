import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/services/context_loader.dart';

void main() {
  group('ContextLoader', () {
    late ContextLoader loader;

    setUp(() {
      loader = ContextLoader();
    });

    test('loads JSON context with colors', () async {
      final directory = await Directory.systemTemp.createTemp('context-json');
      final file = File('${directory.path}/context.json');
      await file.writeAsString('''
{
  "athleteName": "Sam",
  "ftp": 280,
  "lthr": 170,
  "preferredColors": {"power": "#112233"}
}
''');

      final config = await loader.loadContext(file.path);

      expect(config, isNotNull);
      expect(config!.athleteName, equals('Sam'));
      expect(config.ftp, equals(280));
      expect(config.lthr, equals(170));
      expect(config.preferredColors, isNotNull);
      expect(
        config.preferredColors!['power']!.value,
        equals(const Color(0xFF112233).value),
      );
    });

    test('loads YAML context with colors', () async {
      final directory = await Directory.systemTemp.createTemp('context-yaml');
      final file = File('${directory.path}/context.yaml');
      await file.writeAsString('''
athleteName: "Taylor"
ftp: 300
lthr: 175
preferredColors:
  power: "#445566"
''');

      final config = await loader.loadContext(file.path);

      expect(config, isNotNull);
      expect(config!.athleteName, equals('Taylor'));
      expect(config.ftp, equals(300));
      expect(config.lthr, equals(175));
      expect(
        config.preferredColors!['power']!.value,
        equals(const Color(0xFF445566).value),
      );
    });

    test('returns null when file does not exist', () async {
      final config = await loader.loadContext(
        '${Directory.systemTemp.path}/missing-context.json',
      );

      expect(config, isNull);
    });
  });
}
