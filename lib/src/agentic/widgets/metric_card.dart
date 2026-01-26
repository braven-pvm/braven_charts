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

  @override
  Widget build(BuildContext context) =>
      const SizedBox(); // Stub - green phase implements
}
