// Stub file for web platform (dart:isolate not available)
// This file provides dummy implementations for isolate-related classes

class SendPort {
  void send(Object? message) {}
}

class ReceivePort {
  SendPort get sendPort => SendPort();
  void close() {}
  void listen(void Function(dynamic) onData) {}
}

class Isolate {
  static Future<Isolate> spawn<T>(
      void Function(T) entryPoint, T message) async {
    throw UnsupportedError('Isolates are not supported on web platform');
  }

  void kill({int priority = 0}) {}
  static const int immediate = 0;
}
