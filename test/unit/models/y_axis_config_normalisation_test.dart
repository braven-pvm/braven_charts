import 'package:braven_charts/braven_charts.dart';
import 'package:test/test.dart';

void main() {
  group('YAxisConfig position normalisation', () {
    test('leftOuter normalises to left', () {
      // ignore: deprecated_member_use
      final config = YAxisConfig(position: YAxisPosition.leftOuter);
      expect(config.position, equals(YAxisPosition.left));
    });

    test('rightOuter normalises to right', () {
      // ignore: deprecated_member_use
      final config = YAxisConfig(position: YAxisPosition.rightOuter);
      expect(config.position, equals(YAxisPosition.right));
    });

    test('left is unchanged', () {
      final config = YAxisConfig(position: YAxisPosition.left);
      expect(config.position, equals(YAxisPosition.left));
    });

    test('right is unchanged', () {
      final config = YAxisConfig(position: YAxisPosition.right);
      expect(config.position, equals(YAxisPosition.right));
    });

    test('hidden sets visible to false', () {
      final config = YAxisConfig(position: YAxisPosition.hidden, visible: true);
      expect(config.position, equals(YAxisPosition.hidden));
      expect(config.visible, isFalse);
    });

    test('leftOuter does not suppress visible', () {
      // ignore: deprecated_member_use
      final config = YAxisConfig(position: YAxisPosition.leftOuter, visible: true);
      expect(config.visible, isTrue);
      expect(config.position, equals(YAxisPosition.left));
    });
  });
}
