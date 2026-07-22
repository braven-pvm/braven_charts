import 'package:flutter/material.dart';

/// A read-only, selectable, syntax-highlighted Dart code surface.
///
/// This is the renderer the workbench Source tab uses, extracted so any other
/// surface that shows Dart — a showcase authoring card, a docs panel — looks
/// exactly the same instead of hand-rolling a second grey box. It paints its
/// own dark window rather than reading the ambient [ColorScheme]: code is read
/// against a fixed, contrast-checked palette, and the Source tab already
/// deliberately keeps that window dark under a light app theme.
///
/// It is a leaf presentation widget: it holds no state and has no `copyWith`,
/// so it is not part of the fluent config surface.
class ChartCodeBlock extends StatelessWidget {
  const ChartCodeBlock({
    super.key,
    required this.code,
    this.wrapLines = false,
    this.semanticLabel,
    this.surfaceKey,
    this.codeKey,
  });

  /// The raw Dart to render. Highlighting is applied for presentation only —
  /// the string is never rewritten, so a selection copies it verbatim.
  final String code;

  /// Whether long lines soft-wrap. `false` (the default) keeps every line
  /// intact and scrolls horizontally, which is what reading generated Dart
  /// wants; callers with a narrow, fixed-width slot turn it on.
  final bool wrapLines;

  /// Screen-reader label for the block as a whole. The line-number gutter is
  /// always excluded from semantics; without a label the block reads as bare
  /// code text, which is right inside a pane that is already labelled and
  /// wrong for a standalone card.
  final String? semanticLabel;

  /// Key on the painted dark window, for tests asserting on the surface
  /// colour rather than on the text.
  final Key? surfaceKey;

  /// Key on the highlighted code [Text], for tests asserting on the rendered
  /// code or its style.
  final Key? codeKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      height: 1.55,
      color: _CodeColors.text,
    );
    final lineCount = '\n'.allMatches(code).length + 1;
    final numberStyle = codeStyle?.copyWith(color: _CodeColors.muted);
    Widget buildCode({required bool flexible}) => SelectionArea(
      child: Row(
        mainAxisSize: flexible ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: _CodeColors.divider),
                ),
              ),
              child: Text(
                [
                  for (var line = 1; line <= lineCount; line++) '$line',
                ].join('\n'),
                textAlign: TextAlign.right,
                style: numberStyle,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (flexible)
            Expanded(
              child: Text.rich(
                _highlightDart(code),
                key: codeKey,
                style: codeStyle,
                softWrap: true,
              ),
            )
          else
            Text.rich(
              _highlightDart(code),
              key: codeKey,
              style: codeStyle,
              softWrap: false,
            ),
        ],
      ),
    );
    final block = Theme(
      data: theme.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _CodeColors.keyword,
          selectionColor: _CodeColors.selection,
          selectionHandleColor: _CodeColors.keyword,
        ),
        scrollbarTheme: const ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(_CodeColors.scrollbar),
          trackColor: WidgetStatePropertyAll(_CodeColors.background),
          trackBorderColor: WidgetStatePropertyAll(
            _CodeColors.divider,
          ),
        ),
      ),
      child: ColoredBox(
        key: surfaceKey,
        color: _CodeColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) => Scrollbar(
            child: SingleChildScrollView(
              child: wrapLines
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: buildCode(flexible: true),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: buildCode(flexible: false),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return block;
    return Semantics(label: label, container: true, child: block);
  }
}

/// Splits [source] into coloured spans for presentation.
///
/// A deliberately small tokenizer, not a parser: comments, single-quoted
/// strings, keywords, numbers and capitalised identifiers. Anything it does
/// not recognise is emitted verbatim, so the concatenated spans always equal
/// [source] character for character.
TextSpan _highlightDart(String source) {
  final pattern = RegExp(
    r"//[^\n]*|'(?:\\.|[^'\\])*'|\b(?:abstract|as|assert|async|await|break|case|class|const|continue|default|do|else|enum|extends|factory|false|final|for|if|implements|import|in|is|late|mixin|new|null|on|required|return|sealed|static|super|switch|this|throw|true|try|typedef|var|void|while|with|yield)\b|\b\d+(?:\.\d+)?\b|\b[A-Z][A-Za-z0-9_]*\b",
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in pattern.allMatches(source)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: source.substring(cursor, match.start)));
    }
    final token = match.group(0)!;
    final color = token.startsWith('//')
        ? _CodeColors.comment
        : token.startsWith("'")
        ? _CodeColors.string
        : RegExp(r'^\d').hasMatch(token)
        ? _CodeColors.number
        : RegExp(r'^[A-Z]').hasMatch(token)
        ? _CodeColors.type
        : _CodeColors.keyword;
    spans.add(
      TextSpan(
        text: token,
        style: TextStyle(
          color: color,
          fontStyle: token.startsWith('//') ? FontStyle.italic : null,
          fontWeight: RegExp(r'^[A-Z]').hasMatch(token)
              ? FontWeight.w600
              : null,
        ),
      ),
    );
    cursor = match.end;
  }
  if (cursor < source.length) {
    spans.add(TextSpan(text: source.substring(cursor)));
  }
  return TextSpan(children: spans);
}

/// The fixed palette [ChartCodeBlock] paints with.
abstract final class _CodeColors {
  static const background = Color(0xFF0F172A);
  static const text = Color(0xFFE5E7EB);
  static const muted = Color(0xFF94A3B8);
  static const comment = Color(0xFF94A3B8);
  static const keyword = Color(0xFF7DD3FC);
  static const type = Color(0xFFC4B5FD);
  static const string = Color(0xFFF0ABFC);
  static const number = Color(0xFFFBBF24);
  static const divider = Color(0xFF64748B);
  static const scrollbar = Color(0xFF64748B);
  static const selection = Color(0xFF1D4ED8);
}
