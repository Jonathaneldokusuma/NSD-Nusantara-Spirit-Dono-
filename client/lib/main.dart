import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/public_shell.dart';
import 'screens/web_admin_shell.dart';

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
  final firebaseOptions = DefaultFirebaseOptions.currentPlatformOrNull;
  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
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
        builder: (context, _) {
          ErrorWidget.builder = (details) => Material(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'NSD gagal dimuat.\n${details.exceptionAsString()}\n\nCoba hard refresh atau hapus site data jika layar masih kosong.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );

          return MaterialApp(
            title: 'NSD - Nusantara Spiritual Donation',
            debugShowCheckedModeBanner: false,
            theme: nsdTheme(),
            builder: (context, child) => child ?? const SizedBox.shrink(),
            home: kIsWeb
                ? WebAdminShell(api: api, session: session)
                : PublicShell(api: api, session: session),
          );
        },
      );
}
