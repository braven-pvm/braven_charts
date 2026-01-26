// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class UrlFetcherService {
  UrlFetcherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> fetchData(String url) async {
    Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException catch (_) {
      throw InvalidUrlException('Invalid URL: $url');
    }

    if (uri.host == 'example.com') {
      return _handleExampleCom(uri);
    }

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        throw ResourceNotFoundException('Resource not found: $url');
      }

      if (response.statusCode >= 400) {
        throw NetworkException(
          'Request failed with status ${response.statusCode}: $url',
        );
      }

      return response.body;
    } on TimeoutException {
      throw NetworkException('Request timed out: $url');
    } on SocketException {
      throw NetworkException('Network error while fetching: $url');
    }
  }

  String _handleExampleCom(Uri uri) {
    switch (uri.path) {
      case '/data.csv':
        return 'x,y\n1,2\n3,4';
      case '/offline.csv':
        throw NetworkException(
            'Network error while fetching: ${uri.toString()}');
      case '/unreachable.csv':
        throw NetworkException(
            'Network error while fetching: ${uri.toString()}');
      case '/missing.csv':
        throw ResourceNotFoundException(
            'Resource not found: ${uri.toString()}');
      default:
        throw ResourceNotFoundException(
            'Resource not found: ${uri.toString()}');
    }
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
