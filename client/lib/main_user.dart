import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'main_common.dart';
import 'screens/public_shell.dart';

Future<void> main() async {
  final services = await createAppServices();
  await bootstrapApp(
    NsdAppUser(api: services.$1, session: services.$2),
    session: services.$2,
  );
}

class NsdAppUser extends StatelessWidget {
  const NsdAppUser({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => MaterialApp(
      title: 'NSD User',
      debugShowCheckedModeBanner: false,
      theme: nsdTheme(),
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: _UserGate(api: api, session: session),
    ),
  );
}

class _UserGate extends StatelessWidget {
  const _UserGate({required this.api, required this.session});

  final ApiClient api;
  final AuthSession session;

  bool get _hasUserAccess =>
      !session.isAuthenticated ||
      ['donatur', 'pemohon'].contains(session.user?.role);

  @override
  Widget build(BuildContext context) {
    if (session.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasUserAccess) {
      return PublicShell(api: api, session: session);
    }
    return _UserAccessDenied(session: session);
  }
}

class _UserAccessDenied extends StatelessWidget {
  const _UserAccessDenied({required this.session});

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
                  'Akses Aplikasi User Ditolak',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplikasi ini hanya untuk donatur dan pemohon. Gunakan panel internal atau aplikasi konselor sesuai peran akun.',
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
