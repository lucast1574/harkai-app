import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_error.dart';

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'HARKAI_API_URL',
    defaultValue: 'https://api.harkai.lat',
  );
  static const sessionKey = 'harkai_go_session_v1';
  final http.Client transport;
  final FlutterSecureStorage storage;
  Map<String, dynamic>? _session;
  Future<bool>? _refreshing;
  int _generation = 0;
  ApiClient({http.Client? transport, FlutterSecureStorage? storage})
    : transport = transport ?? http.Client(),
      storage = storage ?? const FlutterSecureStorage();
  bool get hasSession => _session != null;
  Future<bool> restore() async {
    final value = await storage.read(key: sessionKey);
    if (value == null) return false;
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      if (decoded['access_token'] is! String ||
          decoded['refresh_token'] is! String) {
        throw const FormatException();
      }
      _session = decoded;
      return true;
    } on FormatException {
      await clear();
      return false;
    } on TypeError {
      await clear();
      return false;
    }
  }

  Future<bool> save(Map<String, dynamic> session) async {
    await storage.write(key: sessionKey, value: jsonEncode(session));
    _session = session;
    return true;
  }

  Future<bool> clear() async {
    _generation++;
    _session = null;
    await storage.delete(key: sessionKey);
    return true;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Uint8List? bytes,
    String? contentType,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl/v1/$path'));
    final token = _session?['access_token'];
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (bytes != null) {
      request.headers['Content-Type'] =
          contentType ?? 'application/octet-stream';
      request.bodyBytes = bytes;
    }
    try {
      final timeout = Duration(
        seconds: path == 'media' || path == 'analysis/audio' ? 45 : 20,
      );
      return await transport
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(503, 'timeout');
    } on http.ClientException {
      throw const ApiException(503, 'connection');
    }
  }

  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!;
    _refreshing = _rotate();
    try {
      return await _refreshing!;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _rotate() async {
    final token = _session?['refresh_token'];
    final generation = _generation;
    if (token == null) return false;
    final response = await _send(
      'POST',
      'auth/refresh',
      body: {'refresh_token': token},
    );
    if (generation != _generation) return false;
    if (response.statusCode == 401) {
      await clear();
      return false;
    }
    final result = _decode(response);
    await save(result);
    return true;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 204) return {};
    Map<String, dynamic> result;
    try {
      result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        response.statusCode >= 400 ? response.statusCode : 503,
        'invalid_response',
      );
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        (result['error'] as Map?)?['code'] as String? ?? 'request_failed',
      );
    }
    return result;
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Uint8List? bytes,
    String? contentType,
  }) async {
    var response = await _send(
      method,
      path,
      body: body,
      bytes: bytes,
      contentType: contentType,
    );
    if (response.statusCode == 401 &&
        !path.startsWith('auth/') &&
        await _refresh()) {
      response = await _send(
        method,
        path,
        body: body,
        bytes: bytes,
        contentType: contentType,
      );
    }
    return _decode(response);
  }

  Future<bool> logout() async {
    if (hasSession) {
      try {
        await request('POST', 'auth/logout');
      } on ApiException catch (e) {
        if (e.status != 401) rethrow;
      }
    }
    return clear();
  }

  String photoUrl(String id) => '$baseUrl/v1/media/${Uri.encodeComponent(id)}';
  Map<String, String> get authHeaders => _session == null
      ? {}
      : {'Authorization': 'Bearer ${_session!['access_token']}'};
}
