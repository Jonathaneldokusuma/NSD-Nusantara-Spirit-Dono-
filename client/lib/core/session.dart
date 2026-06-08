import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
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

  void finishInitialization() {
    if (!initializing) return;
    initializing = false;
    notifyListeners();
  }

  Future<void> restore() async {
    try {
      try {
        if (Firebase.apps.isNotEmpty) {
          final firebaseUser = fb.FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            api.token = await firebaseUser.getIdToken();
            user = User(
              id: firebaseUser.uid,
              name:
                  firebaseUser.displayName ?? firebaseUser.email ?? 'Pengguna',
              email: firebaseUser.email ?? '',
              phone: firebaseUser.phoneNumber ?? '',
              role: 'donatur',
              verified: firebaseUser.emailVerified,
            );
            return;
          }
        }
      } on Exception {
        // Fall back to local/demo session when Firebase is not configured yet.
      }

      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(_tokenKey);
      if (token != null) {
        api.token = token;
        try {
          user = User.fromJson(
            await api.get('/auth/me').timeout(const Duration(seconds: 10))
                as Json,
          );
        } on Exception {
          await preferences.remove(_tokenKey);
          api.token = null;
        }
      }
    } finally {
      finishInitialization();
    }
  }

  Future<void> login(String email, String password) async {
    if (Firebase.apps.isEmpty) {
      final response =
          await api.post('/auth/login', {
                'email': email.trim(),
                'password': password,
              })
              as Json;
      final token = response['token'] as String;
      api.token = token;
      user = User.fromJson(response['user'] as Json);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);
      notifyListeners();
      return;
    }

    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      final firebaseUser = credential.user!;
      api.token = await firebaseUser.getIdToken();
      user = User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? firebaseUser.email ?? 'Pengguna',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: 'donatur',
        verified: firebaseUser.emailVerified,
      );
      notifyListeners();
    } on fb.FirebaseAuthException catch (error) {
      throw ApiException(error.message ?? 'Login Firebase gagal.', 401);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    if (Firebase.apps.isEmpty) {
      final response =
          await api.post('/auth/register', {
                'name': name.trim(),
                'email': email.trim(),
                'phone': phone.trim(),
                'password': password,
                'role': role,
              })
              as Json;
      final token = response['token'] as String;
      api.token = token;
      user = User.fromJson(response['user'] as Json);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);
      notifyListeners();
      return;
    }

    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      final firebaseUser = fb.FirebaseAuth.instance.currentUser!;
      api.token = await firebaseUser.getIdToken();
      user = User(
        id: firebaseUser.uid,
        name: name.trim(),
        email: firebaseUser.email ?? email.trim(),
        phone: phone.trim(),
        role: role,
        verified: firebaseUser.emailVerified,
      );
      notifyListeners();
    } on fb.FirebaseAuthException catch (error) {
      throw ApiException(error.message ?? 'Registrasi Firebase gagal.', 400);
    }
  }

  Future<void> logout() async {
    user = null;
    api.token = null;
    if (Firebase.apps.isNotEmpty) {
      await fb.FirebaseAuth.instance.signOut();
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    notifyListeners();
  }
}
