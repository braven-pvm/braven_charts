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

  /// Every name this package exports that `package:flutter/material.dart` also
  /// exports under a DIFFERENT declaration.
  ///
  /// Generated source imports both libraries unprefixed, so a name in this set
  /// is `ambiguous_import` wherever it appears: the file parses, reads
  /// perfectly, and does not compile. `TooltipTriggerMode` is the package's own
  /// enum in `interaction_config.dart` and, since Flutter grew
  /// `raw_tooltip.dart`, a Flutter enum too — which is why the package's own
  /// sources already write `import 'package:flutter/material.dart' hide
  /// TooltipTriggerMode;` (see `chart_interaction_document_codec.dart`).
  ///
  /// The list is derived rather than guessed, and
  /// `test/unit/source/generated_import_ambiguity_test.dart` re-derives it: it
  /// exports both libraries from a probe file, hides exactly these names, and
  /// fails if the analyzer still finds an ambiguity or if a name here has
  /// stopped being ambiguous. So a future export that collides shows up as a
  /// red test rather than as source a user cannot paste.
  static const materialAmbiguousNames = <String>['TooltipTriggerMode'];

  /// The `package:flutter/material.dart` import line for generated source whose
  /// body is [body].
  ///
  /// The hide combinator is added only for the ambiguous names [body] actually
  /// uses, so a chart that never mentions one emits the plain import and stays
  /// byte-identical. Matched on the emitted TEXT rather than recorded by the
  /// seam that wrote it: a scan cannot miss a name a new emission path starts
  /// writing, whereas a bookkeeping call a new path forgets to make would
  /// silently reintroduce uncompilable source. The failure direction that costs
  /// nothing is the other one — a name matched inside a string literal or a
  /// diagnostic comment adds a hide the file did not need, and the file still
  /// compiles.
  static String materialImport(String body) {
    final hidden = materialAmbiguousNames
        .where((name) => RegExp('\\b$name\\b').hasMatch(body))
        .toList();
    if (hidden.isEmpty) return "import 'package:flutter/material.dart';";
    return "import 'package:flutter/material.dart' hide ${hidden.join(', ')};";
  }

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
