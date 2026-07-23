import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XAxisConfig placement and tick-label rotation', () {
    test('preserves the existing bottom and horizontal defaults', () {
      const config = XAxisConfig();

      expect(config.position, XAxisPosition.bottom);
      expect(config.tickLabelRotationDegrees, isNull);
      expect(config.effectiveTickLabelRotationDegrees, 0);
    });

    test('applies rotation to numeric axes', () {
      const config = XAxisConfig(
        position: XAxisPosition.top,
        tickLabelRotationDegrees: -45,
      );

      expect(config.position, XAxisPosition.top);
      expect(config.effectiveTickLabelRotationDegrees, -45);
    });

    test('supports mirrored top and bottom axes', () {
      const config = XAxisConfig(position: XAxisPosition.both);

      expect(config.position, XAxisPosition.both);
      expect(config.copyWith(), config);
    });

    test('retains the categorical rotation compatibility fallback', () {
      const config = XAxisConfig(
        categoryAxis: CategoryAxisConfig(
          categories: ['Alpha', 'Beta'],
          labelRotationDegrees: 30,
        ),
      );

      expect(config.tickLabelRotationDegrees, isNull);
      expect(config.effectiveTickLabelRotationDegrees, 30);
    });

    test('general rotation overrides the categorical fallback', () {
      const config = XAxisConfig(
        tickLabelRotationDegrees: -60,
        categoryAxis: CategoryAxisConfig(
          categories: ['Alpha', 'Beta'],
          labelRotationDegrees: 30,
        ),
      );

      expect(config.effectiveTickLabelRotationDegrees, -60);
      expect(
        config
            .copyWith(clearTickLabelRotationDegrees: true)
            .effectiveTickLabelRotationDegrees,
        30,
      );
    });

    test('rejects rotation outside the supported range', () {
      expect(
        () => XAxisConfig(tickLabelRotationDegrees: 91),
        throwsAssertionError,
      );
      expect(
        () => XAxisConfig(tickLabelRotationDegrees: -91),
        throwsAssertionError,
      );
    });
  });
}
