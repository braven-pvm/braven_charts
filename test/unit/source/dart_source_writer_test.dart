import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/source/dart_source_writer.dart';

void main() {
  group('DartSourceWriter', () {
    test('writes deterministic nested indentation', () {
      final writer = DartSourceWriter();
      writer.writeLine('final chart = BravenChartPlus(');
      writer.indented(() {
        writer.namedArgument('title', "'Power'");
        writer.block('series: [', () {
          writer.writeLine('LineChartSeries(),');
        }, '],');
      });
      writer.writeLine(');');

      expect(
        writer.toString(),
        "final chart = BravenChartPlus(\n"
        "  title: 'Power',\n"
        '  series: [\n'
        '    LineChartSeries(),\n'
        '  ],\n'
        ');\n',
      );
    });

    test('escapes strings without interpolation or multiline changes', () {
      expect(
        DartSourceWriter.stringLiteral("Power's \\ path\n\$value\tend"),
        r"'Power\'s \\ path\n\$value\tend'",
      );
    });

    test('writes finite numbers and preserves negative zero', () {
      expect(DartSourceWriter.numberLiteral(42), '42');
      expect(DartSourceWriter.numberLiteral(3.25), '3.25');
      expect(DartSourceWriter.numberLiteral(-0.0), '-0.0');
      expect(
        () => DartSourceWriter.numberLiteral(double.nan),
        throwsArgumentError,
      );
      expect(
        () => DartSourceWriter.numberLiteral(double.infinity),
        throwsArgumentError,
      );
    });

    test('writes stable ARGB color literals', () {
      expect(
        DartSourceWriter.colorLiteral(const Color(0x7F12ABEF)),
        'Color(0x7F12ABEF)',
      );
    });

    test('recognizes legal non-keyword identifiers', () {
      expect(DartSourceWriter.isIdentifier('chart'), isTrue);
      expect(DartSourceWriter.isIdentifier(r'$chart_2'), isTrue);
      expect(DartSourceWriter.isIdentifier('class'), isFalse);
      expect(DartSourceWriter.isIdentifier('chart-source'), isFalse);
      expect(DartSourceWriter.isIdentifier('2chart'), isFalse);
    });
  });
}
