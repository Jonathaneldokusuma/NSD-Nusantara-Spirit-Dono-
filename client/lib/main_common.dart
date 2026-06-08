import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'firebase_options.dart';

Future<void> bootstrapApp(Widget app, {AuthSession? session}) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      // ignore: avoid_print
      print(details.exceptionAsString());
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(error);
      // ignore: avoid_print
      print(stack);
    }
    return true;
  };
  runApp(app);
  unawaited(_initializeServices(session));
}

Future<void> _initializeServices(AuthSession? session) async {
  try {
    final firebaseOptions = DefaultFirebaseOptions.currentPlatformOrNull;
    if (firebaseOptions != null && Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: firebaseOptions,
      ).timeout(const Duration(seconds: 8));
    }
  } on Exception catch (error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase initialization skipped: $error');
    }
  }

  if (session == null) return;
  try {
    await session.restore().timeout(const Duration(seconds: 12));
  } on Exception catch (error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Session restore skipped: $error');
    }
    session.finishInitialization();
  }
}

Future<(ApiClient, AuthSession)> createAppServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final session = AuthSession(api);
  return (api, session);
}
