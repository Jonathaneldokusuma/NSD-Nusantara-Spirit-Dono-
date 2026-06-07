import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

class AuthSession extends ChangeNotifier {
  AuthSession(this.api);

  static const _tokenKey = 'nsd_token';
  final ApiClient api;
  User? user;
  bool initializing = true;

  bool get isAuthenticated => user != null;

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token != null) {
      api.token = token;
      try {
        user = User.fromJson(await api.get('/auth/me') as Json);
      } on Exception {
        await preferences.remove(_tokenKey);
        api.token = null;
      }
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response =
        await api.post('/auth/login', {
              'email': email.trim(),
              'password': password,
            })
            as Json;
    await _acceptAuth(response);
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response =
        await api.post('/auth/register', {
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
              'role': role,
            })
            as Json;
    await _acceptAuth(response);
  }

  Future<void> _acceptAuth(Json response) async {
    final token = response['token'] as String;
    api.token = token;
    user = User.fromJson(response['user'] as Json);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    notifyListeners();
  }

  Future<void> logout() async {
    user = null;
    api.token = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    notifyListeners();
  }
}
