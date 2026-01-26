// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

class UrlFetcherService {
  Future<String> fetchData(String url) {
    throw UnimplementedError('URL fetching will be implemented in green phase');
  }
}

class NetworkException implements Exception {
  NetworkException(this.message);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ResourceNotFoundException implements Exception {
  ResourceNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'ResourceNotFoundException: $message';
}

class InvalidUrlException implements Exception {
  InvalidUrlException(this.message);

  final String message;

  @override
  String toString() => 'InvalidUrlException: $message';
}
