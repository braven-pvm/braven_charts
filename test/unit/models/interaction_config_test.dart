import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('focus border is opt-in by default', () {
    expect(const InteractionConfig().showFocusBorder, isFalse);
    expect(InteractionConfig.defaultConfig().showFocusBorder, isFalse);
    expect(InteractionConfig.all().showFocusBorder, isFalse);
  });
}
