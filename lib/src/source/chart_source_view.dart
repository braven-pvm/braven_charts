import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_source_models.dart';

/// Read-only, selectable Dart source presentation for a generated chart.
class ChartSourceView extends StatefulWidget {
  const ChartSourceView({
    super.key,
    required this.generated,
    this.isStale = false,
    this.isRefreshing = false,
    this.onRefresh,
  });

  final ChartGeneratedSource generated;
  final bool isStale;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  @override
  State<ChartSourceView> createState() => _ChartSourceViewState();
}

class _ChartSourceViewState extends State<ChartSourceView> {
  var _wrapLines = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final source = widget.generated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Dart · Effective configuration · '
                '${source.seriesCount} series · '
                '${source.pointCount} ${source.pointCount == 1 ? 'point' : 'points'}',
                style: theme.textTheme.labelLarge,
              ),
              if (source.warnings.isNotEmpty)
                _SourceStatus(
                  icon: Icons.info_outline,
                  label:
                      '${source.warnings.length} ${source.warnings.length == 1 ? 'warning' : 'warnings'}',
                  color: colors.tertiary,
                ),
              if (widget.isStale)
                _SourceStatus(
                  icon: Icons.update_outlined,
                  label: 'Chart changed',
                  color: colors.tertiary,
                ),
              IconButton(
                tooltip: _wrapLines ? 'Disable line wrapping' : 'Wrap lines',
                onPressed: () => setState(() => _wrapLines = !_wrapLines),
                icon: Icon(
                  _wrapLines ? Icons.wrap_text : Icons.horizontal_rule,
                ),
              ),
              if (widget.isStale && widget.onRefresh != null)
                TextButton.icon(
                  onPressed: widget.isRefreshing ? null : widget.onRefresh,
                  icon: widget.isRefreshing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    widget.isRefreshing ? 'Refreshing…' : 'Refresh source',
                  ),
                ),
              FilledButton.tonalIcon(
                onPressed: () => _copySource(context),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy code'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _SourceCode(source: source.source, wrapLines: _wrapLines),
        ),
      ],
    );
  }

  Future<void> _copySource(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.generated.source));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Chart source copied')));
  }
}

class _SourceCode extends StatelessWidget {
  const _SourceCode({required this.source, required this.wrapLines});

  final String source;
  final bool wrapLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      height: 1.55,
      color: _SourceCodeColors.text,
    );
    final lineCount = '\n'.allMatches(source).length + 1;
    final numberStyle = codeStyle?.copyWith(color: _SourceCodeColors.muted);
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
                  right: BorderSide(color: _SourceCodeColors.divider),
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
                _highlightDart(source),
                key: const ValueKey('chart-source-code'),
                style: codeStyle,
                softWrap: true,
              ),
            )
          else
            Text.rich(
              _highlightDart(source),
              key: const ValueKey('chart-source-code'),
              style: codeStyle,
              softWrap: false,
            ),
        ],
      ),
    );
    return Theme(
      data: theme.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _SourceCodeColors.keyword,
          selectionColor: _SourceCodeColors.selection,
          selectionHandleColor: _SourceCodeColors.keyword,
        ),
        scrollbarTheme: const ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(_SourceCodeColors.scrollbar),
          trackColor: WidgetStatePropertyAll(_SourceCodeColors.background),
          trackBorderColor: WidgetStatePropertyAll(_SourceCodeColors.divider),
        ),
      ),
      child: ColoredBox(
        key: const ValueKey('chart-source-dark-window'),
        color: _SourceCodeColors.background,
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
  }
}

class _SourceStatus extends StatelessWidget {
  const _SourceStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

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
        ? _SourceCodeColors.comment
        : token.startsWith("'")
        ? _SourceCodeColors.string
        : RegExp(r'^\d').hasMatch(token)
        ? _SourceCodeColors.number
        : RegExp(r'^[A-Z]').hasMatch(token)
        ? _SourceCodeColors.type
        : _SourceCodeColors.keyword;
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

abstract final class _SourceCodeColors {
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
