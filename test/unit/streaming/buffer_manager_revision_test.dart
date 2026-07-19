import 'package:braven_charts/src/streaming/buffer_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version advances for content mutations but not empty clears', () {
    final buffer = BufferManager<int>(maxSize: 2);

    expect(buffer.version, 0);
    buffer.clear();
    expect(buffer.version, 0);

    buffer.add(1);
    buffer.add(2);
    buffer.add(3);
    expect(buffer.version, 3);
    expect(buffer.toList(), [2, 3]);

    expect(buffer.replaceLatest(4), isTrue);
    expect(buffer.latest, 4);
    expect(buffer.toList(), [2, 4]);
    expect(buffer.version, 4);

    expect(buffer.removeAll(), [2, 4]);
    expect(buffer.version, 5);

    expect(buffer.removeAll(), isEmpty);
    expect(buffer.version, 5);
  });
}
