import 'package:flutter/material.dart';

import '../advanced_streaming_example.dart';
import '../basic_streaming_example.dart';
import '../buffer_status_example.dart';
import 'advanced_features_screen.dart';
import 'annotations_comprehensive_screen.dart';
import 'annotations_showcase_screen.dart';
import 'area_chart_screen.dart';
import 'series_annotations_showcase_screen.dart';
import 'axis_theming_screen.dart';
import 'bar_chart_screen.dart';
import 'event_debug_screen.dart';
import 'interaction_examples_screen.dart';
import 'interaction_showcase_screen.dart';
import 'line_chart_screen.dart';
import 'line_style_comparison_screen.dart';
import 'line_styles_streaming_screen.dart';
import 'quickstart_screen.dart';
import 'regression_test_screen.dart';
import 'scatter_chart_screen.dart';
import 'scrollbar_showcase_screen.dart';
import 'simple_zoom_test_screen.dart';
import 'streaming_test_screen.dart';
import 'ultimate_showcase_screen.dart';

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
          _buildTestingSection(context),
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

  Widget _buildTestingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.science,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Testing & Validation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Critical Testing Gates - Dual-Mode Streaming (User Story 1)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please test both scenarios before proceeding to Phase 4:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '✅ Regression Test - Static Chart',
          subtitle: 'CRITICAL: Verify zoom/pan/interaction still work (no breaking changes)',
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegressionTestScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '🚀 Streaming Mode Test',
          subtitle: 'NEW: Test dual-mode streaming, auto-scroll, mode transitions',
          icon: Icons.stream,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StreamingTestScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '📊 Basic Streaming Example',
          subtitle: 'Minimal setup - just add dataStream and StreamingConfig()',
          icon: Icons.play_circle,
          color: Colors.lightBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BasicStreamingExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '⚙️ Advanced Streaming Example',
          subtitle: 'All callbacks, manual control, custom timeout, event log',
          icon: Icons.settings_applications,
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdvancedStreamingExample()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '📈 Buffer Status Example',
          subtitle: '"Return to Live" button with real-time buffer count tracking',
          icon: Icons.queue,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BufferStatusExample()),
          ),
        ),
      ],
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
          title: '🏆 Ultimate Showcase',
          subtitle: 'ALL features: Multiple series, streaming, themes, types, interaction',
          icon: Icons.stars,
          color: Colors.amber,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UltimateShowcaseScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '🎯 Series-Level Annotations',
          subtitle: 'NEW: 3 series with independent annotations (Temperature, Humidity, Pressure)',
          icon: Icons.layers,
          color: Colors.deepOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SeriesAnnotationsShowcaseScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '📊 Annotations Comprehensive',
          subtitle: 'FULL annotation control: Create, edit, delete all 5 types + stress test',
          icon: Icons.edit_note,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnnotationsComprehensiveScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: 'Annotations Showcase',
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
          title: '🚀 Full Interaction Showcase',
          subtitle: 'ALL features: Factory constructors, callbacks, config panel',
          icon: Icons.dashboard,
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InteractionShowcaseScreen()),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '🎯 Simple Zoom Test',
          subtitle: 'Minimal zoom test: Tap chart, then use +/- or SHIFT+scroll',
          icon: Icons.zoom_in,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SimpleZoomTestScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '� Scrollbar Showcase - Pan + Zoom',
          subtitle: 'Phase 5: Dual-purpose scrollbars with edge resize, limits, callbacks',
          icon: Icons.view_carousel,
          color: Colors.deepOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScrollbarShowcaseScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '�🐛 Event Debug Tool',
          subtitle: 'See all events in real-time (keyboard, mouse, gestures)',
          icon: Icons.bug_report,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventDebugScreen()),
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
          title: '🔬 Line Style Comparison Lab',
          subtitle: 'Switch styles for SAME data - static & streaming modes',
          icon: Icons.compare,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LineStyleComparisonScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildChartCard(
          context,
          title: '🎨 Line Styles - Live Streaming',
          subtitle: 'Cubic bezier curves with real-time data (10Hz)',
          icon: Icons.show_chart,
          color: Colors.lightBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LineStylesStreamingScreen()),
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
