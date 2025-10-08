import 'package:flutter/material.dart';

import 'advanced_features_screen.dart';
import 'annotations_showcase_screen.dart';
import 'area_chart_screen.dart';
import 'axis_theming_screen.dart';
import 'bar_chart_screen.dart';
import 'interaction_examples_screen.dart';
import 'line_chart_screen.dart';
import 'quickstart_screen.dart';
import 'scatter_chart_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braven Charts Example'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 24),
          _buildShowcaseSection(context),
          const SizedBox(height: 24),
          _buildInteractionSection(context),
          const SizedBox(height: 24),
          _buildChartTypeSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Welcome to Braven Charts',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Explore all chart types available in the library. Each chart demonstrates '
              'different features, configurations, and rendering capabilities.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip(context, Icons.speed, 'High Performance'),
                _buildFeatureChip(context, Icons.palette, 'Customizable'),
                _buildFeatureChip(context, Icons.code, 'Pure Flutter'),
                _buildFeatureChip(context, Icons.animation, 'Animated'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildShowcaseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Feature Showcases',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildChartCard(
          context,
          title: 'Annotations',
          subtitle: '5 annotation types: Text, Point, Range, Threshold, Trend',
          icon: Icons.label,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnnotationsShowcaseScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Advanced Features',
          subtitle: 'Real-time streaming, ChartController, dynamic updates',
          icon: Icons.science,
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdvancedFeaturesScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Axis & Theming',
          subtitle: '4 axis presets, custom configs, light/dark themes',
          icon: Icons.tune,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AxisAndThemingScreen()),
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
            'Interaction System',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildChartCard(
          context,
          title: 'Interaction Examples',
          subtitle: '9 examples: crosshair, tooltip, zoom/pan, gestures, keyboard',
          icon: Icons.touch_app,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InteractionExamplesScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Chart Types',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildChartCard(
          context,
          title: 'Quickstart Guide',
          subtitle: 'All 6 quickstart scenarios in one screen',
          icon: Icons.rocket_launch,
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuickstartScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Line Charts',
          subtitle: 'Straight, smooth, and stepped interpolation',
          icon: Icons.show_chart,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LineChartScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Area Charts',
          subtitle: 'Filled areas with gradients and stacking',
          icon: Icons.area_chart,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AreaChartScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Bar Charts',
          subtitle: 'Grouped and stacked bars, vertical & horizontal',
          icon: Icons.bar_chart,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BarChartScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Scatter Plots',
          subtitle: 'Fixed-size, bubble charts, and clustering',
          icon: Icons.scatter_plot,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScatterChartScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(
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
                  size: 32,
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
