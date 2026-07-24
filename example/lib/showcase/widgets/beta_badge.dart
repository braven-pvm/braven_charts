import 'package:flutter/material.dart';

/// The shared "Beta" pill marking work-in-progress surfaces — the
/// Grammar-of-Graphics / fluent authoring API. Used in the Chart Grammar page
/// header and the navigation rail so the Beta status reads consistently
/// everywhere the grammar appears.
class BetaBadge extends StatelessWidget {
  const BetaBadge({super.key, this.compact = false});

  /// A tighter variant for dense spots (the nav rail label).
  final bool compact;

  /// The badge violet — matches the design badge shared for the programme.
  static const Color color = Color(0xFF6C5CE7);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Beta',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : 12.5,
          letterSpacing: 0.3,
          height: 1,
        ),
      ),
    );
  }
}

/// A collapsed-state marker (a small violet dot) for the nav rail when it is
/// showing icons only and a full [BetaBadge] would not fit.
class BetaDot extends StatelessWidget {
  const BetaDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: BetaBadge.color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.surface),
      ),
    );
  }
}
