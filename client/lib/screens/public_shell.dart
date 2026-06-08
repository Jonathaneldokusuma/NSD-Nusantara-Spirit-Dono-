import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'counseling_screen.dart';
import 'campaigns_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'transparency_screen.dart';

class PublicShell extends StatefulWidget {
  const PublicShell({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  State<PublicShell> createState() => _PublicShellState();
}

class _PublicShellState extends State<PublicShell> {
  int _index = 0;

  bool get _hasUserAccess {
    final role = widget.session.user?.role;
    return ['donatur', 'pemohon'].contains(role);
  }

  void _openDashboard() {
    if (!widget.session.isAuthenticated) {
      _openAuth();
      return;
    }
    if (!_hasUserAccess) {
      showMessage(
        context,
        'Akun ini tidak dapat memakai aplikasi user. Gunakan aplikasi sesuai peran.',
        error: true,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DashboardScreen(api: widget.api, session: widget.session),
      ),
    );
  }

  Future<void> _openAuth({
    bool register = false,
    String role = 'donatur',
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          session: widget.session,
          registerInitially: register,
          initialRole: role,
        ),
      ),
    );
    if (!mounted || !widget.session.isAuthenticated) return;
    if (!_hasUserAccess) {
      await widget.session.logout();
      if (!mounted) return;
      showMessage(
        context,
        'Akun ini tidak dapat memakai aplikasi user. Gunakan aplikasi sesuai peran.',
        error: true,
      );
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 850;
    final pages = [
      HomeScreen(
        api: widget.api,
        session: widget.session,
        showCampaigns: () => setState(() => _index = 1),
        applyForAid: () => _openAuth(register: true, role: 'pemohon'),
      ),
      CampaignsScreen(api: widget.api, session: widget.session),
      CounselingScreen(api: widget.api, session: widget.session),
      TransparencyScreen(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: isDesktop ? 0 : 16,
        title: isDesktop
            ? MaxWidth(
                child: Row(
                  children: [
                    const NsdLogo(),
                    const Spacer(),
                    for (final entry in const [
                      (0, 'Beranda'),
                      (1, 'Campaign'),
                      (2, 'Konseling'),
                      (3, 'Transparansi'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TextButton(
                          onPressed: () => setState(() => _index = entry.$1),
                          style: TextButton.styleFrom(
                            foregroundColor: _index == entry.$1
                                ? NsdColors.green
                                : NsdColors.ink,
                            textStyle: TextStyle(
                              fontWeight: _index == entry.$1
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          child: Text(entry.$2),
                        ),
                      ),
                    const SizedBox(width: 18),
                    if (widget.session.isAuthenticated)
                      FilledButton.icon(
                        onPressed: _openDashboard,
                        icon: const Icon(Icons.dashboard_outlined, size: 18),
                        label: const Text('Dashboard'),
                      )
                    else ...[
                      TextButton(
                        onPressed: _openAuth,
                        child: const Text('Masuk'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _openAuth(register: true),
                        child: const Text('Mulai Berdonasi'),
                      ),
                    ],
                  ],
                ),
              )
            : const NsdLogo(),
        actions: isDesktop
            ? null
            : [
                IconButton(
                  tooltip: widget.session.isAuthenticated
                      ? 'Dashboard'
                      : 'Masuk',
                  onPressed: _openDashboard,
                  icon: Icon(
                    widget.session.isAuthenticated
                        ? Icons.dashboard_outlined
                        : Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 8),
              ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: NsdColors.border),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.volunteer_activism_outlined),
                  selectedIcon: Icon(Icons.volunteer_activism),
                  label: 'Campaign',
                ),
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: 'Konseling',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Transparansi',
                ),
              ],
            ),
    );
  }
}
