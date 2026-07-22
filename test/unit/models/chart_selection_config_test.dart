import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSelectionConfig', () {
    test('defaults to direct replacement with portable modifiers', () {
      const config = ChartSelectionConfig();

      expect(config.acquisitionMode, ChartSelectionAcquisitionMode.point);
      expect(config.scope, ChartSelectionScope.mark);
      expect(config.operation, ChartSelectionOperation.replace);
      expect(config.dragActivation, ChartSelectionDragActivation.primaryButton);
      expect(config.clearOnBackgroundTap, isTrue);
      expect(config.useModifierKeys, isTrue);
      expect(config.dataPointHitRadius, 20);
      expect(config.completeSeriesHitRadius, 22);
      expect(config.dataPointHoverScale, 1.5);
      expect(config.dataPointSelectionScale, 2.67);
      expect(config.completeSeriesHoverStrokeScale, 1.75);
      expect(config.completeSeriesSelectionStrokeScale, 1.5);
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
        acquisitionMode: ChartSelectionAcquisitionMode.lasso,
        scope: ChartSelectionScope.wholeSeries,
        operation: ChartSelectionOperation.add,
        clearOnBackgroundTap: false,
        useModifierKeys: false,
      );

      expect(
        config.resolveOperation(controlOrMeta: true, shift: true, alt: true),
        ChartSelectionOperation.add,
      );
      expect(
        config
            .copyWith(acquisitionMode: ChartSelectionAcquisitionMode.rectangle)
            .acquisitionMode,
        ChartSelectionAcquisitionMode.rectangle,
      );
      expect(config.copyWith().scope, ChartSelectionScope.wholeSeries);
      expect(
        config.copyWith(
          scope: ChartSelectionScope.markOrWholeSeries,
          dataPointHitRadius: 14,
          completeSeriesHitRadius: 30,
          dataPointHoverScale: 1.8,
          dataPointSelectionScale: 3.2,
          completeSeriesHoverStrokeScale: 2.1,
          completeSeriesSelectionStrokeScale: 1.9,
        ),
        const ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.lasso,
          scope: ChartSelectionScope.markOrWholeSeries,
          operation: ChartSelectionOperation.add,
          clearOnBackgroundTap: false,
          useModifierKeys: false,
          dataPointHitRadius: 14,
          completeSeriesHitRadius: 30,
          dataPointHoverScale: 1.8,
          dataPointSelectionScale: 3.2,
          completeSeriesHoverStrokeScale: 2.1,
          completeSeriesSelectionStrokeScale: 1.9,
        ),
      );
    });

    test(
      'drag ownership is explicit and independent from viewport gestures',
      () {
        const rectangle = ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
        );
        const modifiedRectangle = ChartSelectionConfig(
          acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
          dragActivation: ChartSelectionDragActivation.shiftPrimaryButton,
        );

        expect(rectangle.ownsPrimaryDrag(), isTrue);
        expect(rectangle.ownsPrimaryDrag(shift: true), isTrue);
        expect(modifiedRectangle.ownsPrimaryDrag(), isFalse);
        expect(modifiedRectangle.ownsPrimaryDrag(shift: true), isTrue);
        expect(
          modifiedRectangle.copyWith(
            dragActivation: ChartSelectionDragActivation.primaryButton,
          ),
          rectangle,
        );
        for (final acquisitionMode in const [
          ChartSelectionAcquisitionMode.xInterval,
          ChartSelectionAcquisitionMode.yInterval,
          ChartSelectionAcquisitionMode.lasso,
        ]) {
          expect(
            ChartSelectionConfig(
              acquisitionMode: acquisitionMode,
            ).ownsPrimaryDrag(),
            isTrue,
          );
        }
      },
    );
  });
}
