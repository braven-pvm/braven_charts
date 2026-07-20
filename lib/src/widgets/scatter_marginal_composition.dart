// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

/// Arranges a Scatter chart with independent X and Y marginal charts.
///
/// This widget owns layout only. Each slot remains a normal chart (or any
/// caller-provided widget), retaining its own renderer, controller, document,
/// and interaction contract.
class ScatterMarginalComposition extends StatelessWidget {
  const ScatterMarginalComposition({
    super.key,
    required this.scatter,
    required this.xMarginal,
    required this.yMarginal,
    this.corner,
    this.xMarginalExtent = 112,
    this.yMarginalExtent = 144,
    this.gap = 8,
  }) : assert(xMarginalExtent > 0),
       assert(yMarginalExtent > 0),
       assert(gap >= 0);

  final Widget scatter;
  final Widget xMarginal;
  final Widget yMarginal;

  /// Optional content occupying the top-right intersection of both marginals.
  final Widget? corner;

  final double xMarginalExtent;
  final double yMarginalExtent;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Scatter chart with horizontal and vertical marginal distributions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: xMarginalExtent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: const ValueKey('scatter-x-marginal'),
                    child: xMarginal,
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: yMarginalExtent,
                  child: KeyedSubtree(
                    key: const ValueKey('scatter-marginal-corner'),
                    child: corner ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: const ValueKey('scatter-marginal-main'),
                    child: scatter,
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: yMarginalExtent,
                  child: KeyedSubtree(
                    key: const ValueKey('scatter-y-marginal'),
                    child: yMarginal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
