import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String name;
  final double value;
  final String unit;

  const MetricCard({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
  });

  String _formatValue() {
    final metricName = name.trim().toUpperCase();
    if (metricName == 'IF') {
      return value.toStringAsFixed(2);
    }
    if (metricName == 'TSS' || metricName == 'NP' || metricName == 'FTP') {
      return value.toStringAsFixed(0);
    }
    if ((value - value.round()).abs() < 1e-9) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(_formatValue(), style: textTheme.headlineSmall),
            if (unit.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(unit, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
