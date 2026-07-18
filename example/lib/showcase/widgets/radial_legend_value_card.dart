// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Showcase-owned radial legend content used to demonstrate the public
/// [RadialLegendItemBuilder] contract on both Pie and Donut charts.
class RadialLegendValueCard extends StatelessWidget {
  const RadialLegendValueCard({required this.item, super.key});

  final RadialLegendItemData item;

  @override
  Widget build(BuildContext context) {
    final textColor =
        item.defaultTextStyle.color ?? Theme.of(context).colorScheme.onSurface;
    return AnimatedContainer(
      duration: item.animationDuration,
      width: 156,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: item.selected
            ? item.selectionColor.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.selected ? item.selectionColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.visibleIndex + 1}. ${item.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: item.defaultTextStyle.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.valueLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: item.defaultTextStyle.copyWith(
                          color: textColor.withValues(alpha: 0.78),
                          fontSize:
                              (item.defaultTextStyle.fontSize ?? 11) * 0.92,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        child: Text(
                          item.shareLabel,
                          style: item.defaultTextStyle.copyWith(
                            color: textColor,
                            fontSize:
                                (item.defaultTextStyle.fontSize ?? 11) * 0.88,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Visibility(
            visible: item.selected,
            maintainAnimation: true,
            maintainSize: true,
            maintainState: true,
            child: Icon(
              Icons.check_circle,
              size: 14,
              color: item.selectionColor,
            ),
          ),
        ],
      ),
    );
  }
}
