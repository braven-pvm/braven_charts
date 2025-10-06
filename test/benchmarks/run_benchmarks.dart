/// Script to run all benchmarks in the coordinates module.
///
/// This avoids Flutter SDK issues by running as pure Dart.
library;

import 'coordinates/batch_transformation_benchmark.dart' as batch;

void main() {
  print('\n====== Running Coordinate System Benchmarks ======\n');

  print('Running batch transformation benchmarks...\n');
  batch.main();

  print('\n====== All Benchmarks Complete ======\n');
}
