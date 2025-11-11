import 'dart:io';

void main() {
  final file = File('lib/src_plus/rendering/chart_render_box.dart');
  final lines = file.readAsLinesSync();
  final output = <String>[];

  bool inDebugPrint = false;
  int parenDepth = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Start of debugPrint statement
    if (trimmed.startsWith('debugPrint(')) {
      inDebugPrint = true;
      parenDepth = _countParens(line);

      // Single-line debugPrint - skip it
      if (line.contains(');')) {
        inDebugPrint = false;
        continue;
      }
      continue;
    }

    // Inside multi-line debugPrint
    if (inDebugPrint) {
      parenDepth += _countParens(line);

      // End of debugPrint
      if (parenDepth <= 0 || line.contains(');')) {
        inDebugPrint = false;
        continue;
      }
      continue;
    }

    // Keep all other lines
    output.add(line);
  }

  file.writeAsStringSync('${output.join('\n')}\n');
  print('Removed ${lines.length - output.length} debugPrint lines');
  print('Original: ${lines.length} lines, New: ${output.length} lines');
}

int _countParens(String line) {
  int count = 0;
  for (var i = 0; i < line.length; i++) {
    if (line[i] == '(') count++;
    if (line[i] == ')') count--;
  }
  return count;
}
