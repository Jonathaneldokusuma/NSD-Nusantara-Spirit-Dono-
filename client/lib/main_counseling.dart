import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'main_common.dart';
import 'screens/public_shell.dart';
import 'screens/counseling_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  final services = await createAppServices();
  await bootstrapApp(
    NsdAppCounseling(api: services.$1, session: services.$2),
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
    if (!session.isAuthenticated) {
      return PublicShell(api: api, session: session);
    }
    if (session.user?.role == 'konselor') {
      return DashboardScreen(api: api, session: session);
    }
    return CounselingScreen(api: api, session: session);
  }
}
