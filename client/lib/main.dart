import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/public_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: PublicShell(api: api, session: session),
    ),
  );
}
