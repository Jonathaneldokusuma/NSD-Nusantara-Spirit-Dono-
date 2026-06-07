import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';

class WebAdminShell extends StatefulWidget {
  const WebAdminShell({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _WebAdminShellState extends State<WebAdminShell> {
  Future<void> _openAuth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          session: widget.session,
          registerInitially: false,
          initialRole: 'admin',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openDashboard() {
    if (!widget.session.isAuthenticated) {
      _openAuth();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DashboardScreen(api: widget.api, session: widget.session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = widget.session.isAuthenticated;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: const NsdLogo(),
        actions: [
          TextButton(
            onPressed: _openAuth,
            child: Text(authenticated ? 'Ganti akun' : 'Masuk Admin'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _openDashboard,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Buka Panel'),
          ),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: NsdColors.border),
        ),
      ),
      body: MaxWidth(
        width: 1300,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Panel NSD',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Panel web khusus untuk operator, admin, super admin, dan konselor. Aplikasi mobile tetap dipakai untuk donatur dan pemohon di HP.',
                style: TextStyle(fontSize: 18, height: 1.6),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [
                  _AdminCard(
                    icon: Icons.campaign_outlined,
                    title: 'Kelola Campaign',
                    message: 'Moderasi, verifikasi, dan update status campaign.',
                  ),
                  _AdminCard(
                    icon: Icons.forum_outlined,
                    title: 'Konseling',
                    message: 'Pantau sesi pendampingan dan pesan konselor.',
                  ),
                  _AdminCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Pengajuan Bantuan',
                    message: 'Tinjau, setujui, dan tindak lanjuti aplikasi bantuan.',
                  ),
                  _AdminCard(
                    icon: Icons.security_outlined,
                    title: 'Audit & Transparansi',
                    message: 'Lihat log aktivitas dan laporan penyaluran dana.',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (!authenticated)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Masuk untuk membuka dashboard admin dan konseling.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        FilledButton(
                          onPressed: _openAuth,
                          child: const Text('Masuk'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: NsdColors.mint,
                          child: Text(
                            widget.session.user!.name.isEmpty
                                ? '?'
                                : widget.session.user!.name[0],
                            style: const TextStyle(
                              color: NsdColors.green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.user!.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(roleLabel(widget.session.user!.role)),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _openDashboard,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Masuk Panel'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: NsdColors.mint,
              child: Icon(icon, color: NsdColors.green),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    ),
  );
}
