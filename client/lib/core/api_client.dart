import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? token}) : _token = token;

  static String get baseUrl {
    const configured = String.fromEnvironment('API_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'https://nsdserver-production.up.railway.app/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }

  static String get socketUrl {
    if (kIsWeb && baseUrl.startsWith('/')) return Uri.base.origin;
    return baseUrl.replaceFirst(RegExp(r'/api$'), '');
  }

  String? _token;

  set token(String? value) => _token = value;

  Future<void> syncFirebaseToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    _token = await currentUser.getIdToken();
  }

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, [Json? body]) =>
      _request('POST', path, body);
  Future<dynamic> patch(String path, Json body) =>
      _request('PATCH', path, body);

  Future<dynamic> _request(String method, String path, [Json? body]) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    final uri = Uri.parse('$baseUrl$path');

    late http.Response response;
    try {
      response = switch (method) {
        'POST' => await http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'PATCH' => await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body),
        ),
        _ => await http.get(uri, headers: headers),
      };
    } on Exception {
      throw const ApiException(
        'Tidak dapat terhubung ke server NSD. Pastikan API sedang berjalan.',
        0,
      );
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Json
          ? decoded['message'] as String? ?? 'Permintaan gagal diproses.'
          : 'Permintaan gagal diproses.';
      throw ApiException(message, response.statusCode);
    }
    return decoded;
  }
}
