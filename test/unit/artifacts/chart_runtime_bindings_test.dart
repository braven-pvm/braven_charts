import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartFormatterRegistry', () {
    test('round-trips descriptors and resolves built-in fixed formatting', () {
      final descriptor = ChartFormatterDescriptor(
        id: 'braven.number.fixed',
        arguments: {
          'decimals': JsonNumberValue(1),
          'prefix': const JsonStringValue('\$'),
          'suffix': const JsonStringValue(' USD'),
        },
      );

      final decoded = ChartFormatterDescriptor.fromDocument(
        descriptor.toDocument(),
      );
      final resolution = const ChartFormatterRegistry().resolve(decoded);

      expect(decoded.id, descriptor.id);
      expect(decoded.arguments['decimals']?.toJson(), 1);
      expect(resolution.formatter(12.34), r'$12.3 USD');
      expect(resolution.warning, isNull);
    });

    test('resolves host formatters with descriptor arguments', () {
      final registry = ChartFormatterRegistry(
        customFormatters: {
          'com.example.suffix': (value, arguments) =>
              '$value${arguments['suffix']?.toJson()}',
        },
      );
      final resolution = registry.resolve(
        ChartFormatterDescriptor(
          id: 'com.example.suffix',
          arguments: const {'suffix': JsonStringValue(' W')},
        ),
      );

      expect(resolution.formatter(250), '250.0 W');
      expect(resolution.warning, isNull);
    });

    test('uses a safe fallback and warning for an unknown formatter', () {
      final resolution = const ChartFormatterRegistry().resolve(
        ChartFormatterDescriptor(
          id: 'com.example.missing',
          fallbackPattern: 'Value: {value}',
        ),
      );

      expect(resolution.formatter(4.5), 'Value: 4.5');
      expect(
        resolution.warning?.code,
        ChartArtifactDiagnosticCodes.unregisteredFormatter,
      );
    });
  });

  test('callback registry resolves only the requested callback type', () {
    void callback(double value) {}
    final registry = ChartCallbackRegistry(
      callbacks: {'com.example.callback': callback},
    );

    expect(
      registry.resolve<void Function(double)>('com.example.callback'),
      same(callback),
    );
    expect(
      registry.resolve<void Function(String)>('com.example.callback'),
      isNull,
    );
  });

  test('tooltip registry resolves a stable builder ID', () {
    Widget builder(BuildContext context, Map<String, dynamic> data) =>
        const Text('Custom');
    final registry = ChartTooltipRegistry(
      builders: {'com.example.tooltip': builder},
    );

    expect(registry.resolve('com.example.tooltip'), same(builder));
  });
}
