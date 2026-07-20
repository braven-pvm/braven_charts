import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSelectionConfig', () {
    test('defaults to direct replacement with portable modifiers', () {
      const config = ChartSelectionConfig();

      expect(config.mode, ChartSelectionMode.point);
      expect(config.operation, ChartSelectionOperation.replace);
      expect(config.dragActivation, ChartSelectionDragActivation.primary);
      expect(config.clearOnBackgroundTap, isTrue);
      expect(config.useModifierKeys, isTrue);
      expect(config.ownsPrimaryDrag(), isFalse);
      expect(
        config.resolveOperation(controlOrMeta: true),
        ChartSelectionOperation.toggle,
      );
      expect(config.resolveOperation(shift: true), ChartSelectionOperation.add);
      expect(
        config.resolveOperation(alt: true),
        ChartSelectionOperation.subtract,
      );
    });

    test('modifier precedence is deterministic', () {
      const config = ChartSelectionConfig();

      expect(
        config.resolveOperation(controlOrMeta: true, shift: true),
        ChartSelectionOperation.add,
      );
      expect(
        config.resolveOperation(controlOrMeta: true, shift: true, alt: true),
        ChartSelectionOperation.subtract,
      );
    });

    test('can preserve an explicit operation when modifiers are disabled', () {
      const config = ChartSelectionConfig(
        mode: ChartSelectionMode.lasso,
        operation: ChartSelectionOperation.add,
        clearOnBackgroundTap: false,
        useModifierKeys: false,
      );

      expect(
        config.resolveOperation(controlOrMeta: true, shift: true, alt: true),
        ChartSelectionOperation.add,
      );
      expect(
        config.copyWith(mode: ChartSelectionMode.rectangle).mode,
        ChartSelectionMode.rectangle,
      );
    });

    test(
      'drag ownership is explicit and independent from viewport gestures',
      () {
        const rectangle = ChartSelectionConfig(
          mode: ChartSelectionMode.rectangle,
        );
        const modifiedRectangle = ChartSelectionConfig(
          mode: ChartSelectionMode.rectangle,
          dragActivation: ChartSelectionDragActivation.shiftPrimary,
        );

        expect(rectangle.ownsPrimaryDrag(), isTrue);
        expect(rectangle.ownsPrimaryDrag(shift: true), isTrue);
        expect(modifiedRectangle.ownsPrimaryDrag(), isFalse);
        expect(modifiedRectangle.ownsPrimaryDrag(shift: true), isTrue);
        expect(
          modifiedRectangle.copyWith(
            dragActivation: ChartSelectionDragActivation.primary,
          ),
          rectangle,
        );
      },
    );
  });
}
