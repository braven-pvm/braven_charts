// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Interaction Examples Index Screen
///
/// Navigation hub for all 9 interaction system examples demonstrating:
/// - Crosshair interactions
/// - Tooltip configuration
/// - Zoom and pan
/// - Gesture handling
/// - Keyboard navigation
library;

import 'package:flutter/material.dart';

import 'interaction_examples/basic_crosshair.dart';
import 'interaction_examples/complete_interaction.dart';
import 'interaction_examples/custom_crosshair_style.dart';
import 'interaction_examples/custom_tooltip_builder.dart';
import 'interaction_examples/default_tooltip.dart';
import 'interaction_examples/gesture_callbacks.dart';
import 'interaction_examples/keyboard_navigation.dart';
import 'interaction_examples/multi_series_crosshair.dart';
import 'interaction_examples/zoom_pan_config.dart';

class InteractionExamplesScreen extends StatelessWidget {
  const InteractionExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 24),
          _buildCrosshairSection(context),
          const SizedBox(height: 24),
          _buildTooltipSection(context),
          const SizedBox(height: 24),
          _buildInteractionSection(context),
          const SizedBox(height: 24),
          _buildAdvancedSection(context),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Interaction System',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Explore all interaction features: crosshair, tooltip, zoom/pan, '
              'gestures, and keyboard navigation. Each example demonstrates '
              'different configuration options and use cases.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrosshairSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Crosshair Examples',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildExampleCard(
          context,
          title: 'Example 1: Basic Crosshair',
          subtitle: '5-line crosshair setup with default configuration',
          icon: Icons.add,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BasicCrosshairExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          context,
          title: 'Example 2: Custom Crosshair Style',
          subtitle: 'Custom color, width, dash pattern, snap radius',
          icon: Icons.style,
          color: Colors.lightBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomCrosshairStyleExample()),
          ),
        ),
      ],
    );
  }

  Widget _buildTooltipSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Tooltip Examples',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildExampleCard(
          context,
          title: 'Example 3: Default Tooltip',
          subtitle: 'Tooltip on hover/tap with default formatting',
          icon: Icons.info_outline,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DefaultTooltipExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          context,
          title: 'Example 4: Custom Tooltip Builder',
          subtitle: 'Rich tooltip content with icons and badges',
          icon: Icons.featured_play_list,
          color: Colors.lightGreen,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomTooltipBuilderExample()),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'User Interactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildExampleCard(
          context,
          title: 'Example 5: Zoom/Pan Configuration',
          subtitle: 'Mouse wheel, pinch, drag gestures with zoom levels',
          icon: Icons.zoom_in,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ZoomPanConfigExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          context,
          title: 'Example 6: Gesture Callbacks',
          subtitle: 'Tap, hover, long-press, zoom, pan event handling',
          icon: Icons.touch_app,
          color: Colors.deepOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GestureCallbacksExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          context,
          title: 'Example 7: Keyboard Navigation',
          subtitle: 'Arrow keys, zoom keys (+/-), shortcuts',
          icon: Icons.keyboard,
          color: Colors.amber,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KeyboardNavigationExample()),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Advanced Examples',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildExampleCard(
          context,
          title: 'Example 8: Complete Configuration',
          subtitle: 'All interaction features working together',
          icon: Icons.dashboard,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompleteInteractionExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildExampleCard(
          context,
          title: 'Example 9: Multi-Series Crosshair',
          subtitle: 'Crosshair snapping across multiple series',
          icon: Icons.stacked_line_chart,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MultiSeriesCrosshairExample()),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
