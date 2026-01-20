import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';

// Generate mocks for testing
// Run: flutter packages pub run build_runner build

@GenerateMocks([
  // System services
  SystemChrome,

  // Painting and rendering
  Canvas,
  Paint,
  Path,

  // Custom interfaces for chart components
  ChartRenderer,
  DataProvider,
  AnimationController,
])
class MockDefinitions {
  // This class is used only for mock generation annotations
}

// Mock interfaces for chart components
abstract class ChartRenderer {
  void render(Canvas canvas, Size size);
  void update(dynamic data);
}

abstract class DataProvider {
  List<dynamic> getData();
  void setData(List<dynamic> data);
  Stream<List<dynamic>> get dataStream;
}

abstract class AnimationController {
  void start();
  void stop();
  void reset();
  double get value;
}
