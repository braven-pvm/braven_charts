import 'package:flutter/material.dart';

import '../controllers/bar_drilldown_controller.dart';

/// Accessible host chrome for [BarDrilldownController].
class BarDrilldownBreadcrumbs extends StatelessWidget {
  const BarDrilldownBreadcrumbs({
    required this.controller,
    super.key,
    this.compactBreakpoint = 520,
  });

  final BarDrilldownController controller;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final path = controller.path;
        final compact = constraints.maxWidth < compactBreakpoint;
        final visible = compact && path.length > 2
            ? <int>[0, path.length - 1]
            : List<int>.generate(path.length, (index) => index);
        return Semantics(
          container: true,
          label: 'Chart hierarchy breadcrumb',
          child: Row(
            children: [
              if (controller.canGoUp)
                IconButton(
                  key: const ValueKey('bar-drill-back'),
                  tooltip: 'Back to ${path[path.length - 2].label}',
                  onPressed: controller.up,
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (
                        var position = 0;
                        position < visible.length;
                        position++
                      ) ...[
                        if (compact && path.length > 2 && position == 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('… /'),
                          )
                        else if (position > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text('/'),
                          ),
                        _BreadcrumbButton(
                          label: path[visible[position]].label,
                          current: visible[position] == path.length - 1,
                          onPressed: visible[position] == path.length - 1
                              ? null
                              : () => controller.navigateToAncestor(
                                  path[visible[position]].id,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (controller.status == BarDrilldownStatus.loading)
                Semantics(
                  liveRegion: true,
                  label: 'Loading child chart data',
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              if (controller.status == BarDrilldownStatus.empty)
                Semantics(
                  liveRegion: true,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('No data at this level'),
                  ),
                ),
              if (controller.status == BarDrilldownStatus.error) ...[
                Semantics(
                  liveRegion: true,
                  child: const Text('Could not load child data'),
                ),
                TextButton.icon(
                  onPressed: controller.retry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _BreadcrumbButton extends StatelessWidget {
  const _BreadcrumbButton({
    required this.label,
    required this.current,
    required this.onPressed,
  });

  final String label;
  final bool current;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: current ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ),
    ),
  );
}
