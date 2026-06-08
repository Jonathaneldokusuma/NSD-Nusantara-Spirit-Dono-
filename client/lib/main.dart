import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'main_common.dart';
import 'screens/web_admin_shell.dart';

Future<void> main() async {
  final services = await createAppServices();
  await bootstrapApp(
    NsdAppAdmin(api: services.$1, session: services.$2),
    session: services.$2,
  );
}

class NsdAppAdmin extends StatelessWidget {
  const NsdAppAdmin({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => MaterialApp(
      title: 'NSD Admin',
      debugShowCheckedModeBanner: false,
      theme: nsdTheme(),
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: WebAdminShell(api: api, session: session),
    ),
  );
}
