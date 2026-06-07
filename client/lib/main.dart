import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/public_shell.dart';

Future<void> main() async {
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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on StateError {
    // Firebase optional during local demo mode.
  }
  final api = ApiClient();
  final session = AuthSession(api);
  await session.restore();
  runApp(NsdApp(api: api, session: session));
}

class NsdApp extends StatelessWidget {
  const NsdApp({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => MaterialApp(
      title: 'NSD - Nusantara Spiritual Donation',
      debugShowCheckedModeBanner: false,
      theme: nsdTheme(),
      builder: (context, child) {
        ErrorWidget.builder = (details) => Material(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'NSD gagal dimuat.\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        return child ?? const SizedBox.shrink();
      },
      home: PublicShell(api: api, session: session),
    ),
  );
}
