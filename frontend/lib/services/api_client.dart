import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Shared HTTP client that mirrors backend route style (`/api/...`)
/// and attaches the JWT from [AuthSession] when present.
class ApiClient {
  ApiClient({http.Client? httpClient, AuthSession? session})
      : _http = httpClient ?? http.Client(),
        _session = session ?? AuthSession.instance;

  final http.Client _http;
  final AuthSession _session;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      query: query,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      body: body,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(fields);
    request.files.addAll(files);
    request.headers['Accept'] = 'application/json';

    if (auth) {
      final token = await _session.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final streamed = await _http.send(request);
      final response = await http.Response.fromStream(streamed);
      return _decodeResponse(response);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException(
        0,
        'Unable to reach the server. Check that the API is running.',
      );
    }
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    required bool auth,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await _session.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers);
        case 'POST':
          response = await _http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'PATCH':
          response = await _http.patch(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          response = await _http.delete(uri, headers: headers);
        default:
          throw ApiException(500, 'Unsupported HTTP method: $method');
      }
    } catch (error) {
      if (error is ApiException) rethrow;
      throw const ApiException(
        0,
        'Unable to reach the server. Check that the API is running.',
      );
    }

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> decoded = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        } else {
          decoded = <String, dynamic>{'data': parsed};
        }
      } catch (_) {
        decoded = <String, dynamic>{'message': response.body};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        decoded['message']?.toString() ??
            'Request failed (${response.statusCode})',
      );
    }

    return decoded;
  }
}
