import 'package:flutter/material.dart';

/// Small deterministic writer used by chart source generation.
///
/// This deliberately formats only the Dart constructs emitted by the package;
/// it is not intended to replace a general-purpose Dart formatter.
class DartSourceWriter {
  DartSourceWriter({this.indentWidth = 2})
    : assert(indentWidth > 0, 'indentWidth must be positive');

  final int indentWidth;
  final StringBuffer _buffer = StringBuffer();
  var _indent = 0;

  void write(String value) => _buffer.write(value);

  void writeLine([String value = '']) {
    if (value.isNotEmpty) {
      _buffer.write(' ' * (_indent * indentWidth));
      _buffer.write(value);
    }
    _buffer.writeln();
  }

  void indented(void Function() body) {
    _indent += 1;
    try {
      body();
    } finally {
      _indent -= 1;
    }
  }

  void namedArgument(String name, String expression) {
    writeLine('$name: $expression,');
  }

  void block(String opening, void Function() body, String closing) {
    writeLine(opening);
    indented(body);
    writeLine(closing);
  }

  @override
  String toString() => _buffer.toString();

  static String stringLiteral(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\r', r'\r')
        .replaceAll('\n', r'\n')
        .replaceAll('\t', r'\t')
        .replaceAll('\b', r'\b')
        .replaceAll('\f', r'\f');
    return "'$escaped'";
  }

  static String numberLiteral(num value) {
    if (value is double && !value.isFinite) {
      throw ArgumentError.value(
        value,
        'value',
        'Generated Dart requires a finite number',
      );
    }
    if (value is double && value == 0 && value.isNegative) return '-0.0';
    return value.toString();
  }

  static String colorLiteral(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return 'Color(0x${value.toUpperCase()})';
  }

  static bool isIdentifier(String value) =>
      RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(value) &&
      !dartKeywords.contains(value);

  static const dartKeywords = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };
}
