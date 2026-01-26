import 'package:flutter/material.dart';

/// Card container for chart widgets with an action bar.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.child, this.onRefresh, this.onShare});

  final Widget child;
  final VoidCallback? onRefresh;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2), // Debug border
        ),
        constraints: const BoxConstraints(minHeight: 200), // Ensure minimum height
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
