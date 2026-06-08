import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'main_common.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  final services = await createAppServices();
  await bootstrapApp(
    NsdAppCounseling(api: services.$1, session: services.$2),
    session: services.$2,
  );
}

class NsdAppCounseling extends StatelessWidget {
  const NsdAppCounseling({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => MaterialApp(
      title: 'NSD Counseling',
      debugShowCheckedModeBanner: false,
      theme: nsdTheme(),
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: _CounselingGate(api: api, session: session),
    ),
  );
}

class _CounselingGate extends StatelessWidget {
  const _CounselingGate({required this.api, required this.session});

  final ApiClient api;
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    if (session.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.isAuthenticated) {
      return AuthScreen(
        session: session,
        initialRole: 'konselor',
        allowRegistration: false,
        demoText: 'Demo konselor: konselor@nsd.id / Demo1234',
      );
    }
    if (session.user?.role == 'konselor') {
      return DashboardScreen(api: api, session: session);
    }
    return _CounselingAccessDenied(session: session);
  }
}

class _CounselingAccessDenied extends StatelessWidget {
  const _CounselingAccessDenied({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SizedBox(
        width: 420,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Akses Konselor Ditolak',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplikasi ini hanya untuk akun konselor. Gunakan aplikasi user untuk donatur atau pemohon.',
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => session.logout(),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
