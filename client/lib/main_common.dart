import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'firebase_options.dart';

Future<void> bootstrapApp(Widget app) async {
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
  final firebaseOptions = DefaultFirebaseOptions.currentPlatformOrNull;
  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
  }
  runApp(app);
}

Future<(ApiClient, AuthSession)> createAppServices() async {
  final api = ApiClient();
  final session = AuthSession(api);
  await session.restore();
  return (api, session);
}
