import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/chart_code_block.dart';
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
          child: ChartCodeBlock(
            code: source.source,
            wrapLines: _wrapLines,
            surfaceKey: const ValueKey('chart-source-dark-window'),
            codeKey: const ValueKey('chart-source-code'),
          ),
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
