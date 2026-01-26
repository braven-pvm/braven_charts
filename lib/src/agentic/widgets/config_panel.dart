import 'package:flutter/material.dart';
import '../models/chart_configuration.dart';

/// Minimal stub for TDD Red phase.
/// This allows tests to compile and fail properly.
/// Full implementation will be done in Green phase.
class ConfigPanel extends StatelessWidget {
  final ChartConfiguration configuration;
  final ValueChanged<ChartConfiguration> onConfigurationChanged;

  const ConfigPanel({
    super.key,
    required this.configuration,
    required this.onConfigurationChanged,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}
