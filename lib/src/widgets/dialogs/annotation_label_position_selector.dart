import 'package:flutter/material.dart';

import '../../models/chart_annotation.dart';

/// Human-readable name for an annotation label anchor.
String annotationLabelPositionName(AnnotationLabelPosition position) {
  return switch (position) {
    AnnotationLabelPosition.topLeft => 'Top left',
    AnnotationLabelPosition.topCenter => 'Top center',
    AnnotationLabelPosition.topRight => 'Top right',
    AnnotationLabelPosition.centerLeft => 'Center left',
    AnnotationLabelPosition.center => 'Center',
    AnnotationLabelPosition.centerRight => 'Center right',
    AnnotationLabelPosition.bottomLeft => 'Bottom left',
    AnnotationLabelPosition.bottomCenter => 'Bottom center',
    AnnotationLabelPosition.bottomRight => 'Bottom right',
  };
}

/// A spatial 3×3 selector for annotation label placement.
///
/// The center target represents the label itself; the surrounding targets map
/// directly to where the label will sit within its annotation range.
class AnnotationLabelPositionSelector extends StatelessWidget {
  const AnnotationLabelPositionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AnnotationLabelPosition value;
  final ValueChanged<AnnotationLabelPosition> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Label position',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              annotationLabelPositionName(value),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 250.0;
            final centerWidth = (availableWidth - 96)
                .clamp(56.0, 88.0)
                .toDouble();

            return Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                    width: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _positionRow(context, centerWidth, const [
                      AnnotationLabelPosition.topLeft,
                      AnnotationLabelPosition.topCenter,
                      AnnotationLabelPosition.topRight,
                    ]),
                    _positionRow(context, centerWidth, const [
                      AnnotationLabelPosition.centerLeft,
                      AnnotationLabelPosition.center,
                      AnnotationLabelPosition.centerRight,
                    ]),
                    _positionRow(context, centerWidth, const [
                      AnnotationLabelPosition.bottomLeft,
                      AnnotationLabelPosition.bottomCenter,
                      AnnotationLabelPosition.bottomRight,
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _positionRow(
    BuildContext context,
    double centerWidth,
    List<AnnotationLabelPosition> positions,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < positions.length; index++) ...[
          _positionTarget(
            context,
            position: positions[index],
            centerWidth: centerWidth,
          ),
        ],
      ],
    );
  }

  Widget _positionTarget(
    BuildContext context, {
    required AnnotationLabelPosition position,
    required double centerWidth,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = value == position;
    final positionName = annotationLabelPositionName(position);
    final targetWidth = switch (position) {
      AnnotationLabelPosition.topCenter ||
      AnnotationLabelPosition.center ||
      AnnotationLabelPosition.bottomCenter => centerWidth,
      _ => 44.0,
    };
    final isCenter = position == AnnotationLabelPosition.center;
    final visualWidth = isCenter
        ? (targetWidth - 12).clamp(44.0, 76.0).toDouble()
        : 36.0;

    return Tooltip(
      message: positionName,
      child: Semantics(
        label: '$positionName label position',
        button: true,
        selected: isSelected,
        excludeSemantics: true,
        child: SizedBox(
          key: ValueKey('annotation-label-position-${position.name}'),
          width: targetWidth,
          height: 44,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => onChanged(position),
              borderRadius: BorderRadius.circular(6),
              hoverColor: colors.primary.withValues(alpha: 0.035),
              focusColor: colors.primary.withValues(alpha: 0.06),
              child: Center(
                child: AnimatedContainer(
                  key: ValueKey(
                    'annotation-label-position-${position.name}-visual',
                  ),
                  duration: const Duration(milliseconds: 120),
                  width: visualWidth,
                  height: 32,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCenter ? 6 : 4,
                    vertical: isCenter ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.09)
                        : colors.surfaceContainerLow.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.85)
                          : colors.outlineVariant.withValues(alpha: 0.55),
                      width: isSelected ? 1 : 0.75,
                    ),
                  ),
                  child: isCenter
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Label',
                            maxLines: 1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : Align(
                          alignment: _indicatorAlignment(position),
                          child: Container(
                            key: ValueKey(
                              'annotation-label-position-${position.name}-indicator',
                            ),
                            width: 10,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant.withValues(
                                      alpha: 0.68,
                                    ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Alignment _indicatorAlignment(AnnotationLabelPosition position) {
    return switch (position) {
      AnnotationLabelPosition.topLeft => Alignment.topLeft,
      AnnotationLabelPosition.topCenter => Alignment.topCenter,
      AnnotationLabelPosition.topRight => Alignment.topRight,
      AnnotationLabelPosition.centerLeft => Alignment.centerLeft,
      AnnotationLabelPosition.center => Alignment.center,
      AnnotationLabelPosition.centerRight => Alignment.centerRight,
      AnnotationLabelPosition.bottomLeft => Alignment.bottomLeft,
      AnnotationLabelPosition.bottomCenter => Alignment.bottomCenter,
      AnnotationLabelPosition.bottomRight => Alignment.bottomRight,
    };
  }
}
