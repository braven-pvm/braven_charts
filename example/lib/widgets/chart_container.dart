import 'package:flutter/material.dart';

/// Reusable chart container widget
class ChartContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final double height;
  final VoidCallback? onRefresh;

  const ChartContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.height = 300,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh data',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo chart widget (temporary placeholder for actual chart rendering)
class DemoChartWidget extends StatelessWidget {
  final String chartType;
  final Color color;
  final String description;

  const DemoChartWidget({
    super.key,
    required this.chartType,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              chartType,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
