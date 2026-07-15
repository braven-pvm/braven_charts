// Copyright 2025 Braven Charts - Axes Page
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'axis_render_range_page.dart';
import 'axis_slot_demo_page.dart';
import 'minor_ticks_page.dart';

/// Comprehensive axis configuration examples.
///
/// Groups tick subdivision, render windows, and constrained axis allocation
/// behind one top-level showcase destination.
class AxesPage extends StatefulWidget {
  const AxesPage({super.key});

  @override
  State<AxesPage> createState() => _AxesPageState();
}

class _AxesPageState extends State<AxesPage> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AxesExamplePicker(
          selected: _selectedSection,
          onSelected: (value) => setState(() => _selectedSection = value),
        ),
        Expanded(
          child: switch (_selectedSection) {
            0 => const MinorTicksPage(),
            1 => const AxisRenderRangePage(),
            _ => const AxisSlotDemoPage(),
          },
        ),
      ],
    );
  }
}

class _AxesExamplePicker extends StatelessWidget {
  const _AxesExamplePicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        key: const ValueKey('axes-example-picker'),
        segments: const [
          ButtonSegment(
            value: 0,
            icon: Icon(Icons.linear_scale),
            label: Text('Ticks & grid'),
          ),
          ButtonSegment(
            value: 1,
            icon: Icon(Icons.crop_free),
            label: Text('Render windows'),
          ),
          ButtonSegment(
            value: 2,
            icon: Icon(Icons.swap_vert),
            label: Text('Axis slots'),
          ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Axes examples',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Configure ticks, visible ranges, and competing axis slots',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            if (constraints.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 12), selector],
              );
            }

            return Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 24),
                selector,
              ],
            );
          },
        ),
      ),
    );
  }
}
