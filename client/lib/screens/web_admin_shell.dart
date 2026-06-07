import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

class WebAdminShell extends StatefulWidget {
  const WebAdminShell({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _WebAdminShellState extends State<WebAdminShell> {
  final _email = TextEditingController(text: 'admin@nsd.id');
  final _password = TextEditingController(text: 'Demo1234');
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.session.login(_email.text, _password.text);
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDashboard() {
    if (!widget.session.isAuthenticated) {
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
          if (authenticated)
            TextButton(
              onPressed: () async {
                await widget.session.logout();
                if (mounted) setState(() {});
              },
              child: const Text('Keluar'),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: authenticated ? _openDashboard : _login,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: Text(authenticated ? 'Buka Panel' : 'Masuk Admin'),
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
                'Web ini khusus untuk admin, operator, super admin, dan konselor. Donatur dan pemohon memakai app mobile terpisah di HP.',
                style: TextStyle(fontSize: 18, height: 1.6),
              ),
              const SizedBox(height: 28),
              if (!authenticated)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: const [
                          _AdminCard(
                            icon: Icons.campaign_outlined,
                            title: 'Kelola Campaign',
                            message:
                                'Moderasi, verifikasi, dan update status campaign.',
                          ),
                          _AdminCard(
                            icon: Icons.forum_outlined,
                            title: 'Konseling',
                            message:
                                'Pantau sesi pendampingan dan pesan konselor.',
                          ),
                          _AdminCard(
                            icon: Icons.fact_check_outlined,
                            title: 'Pengajuan Bantuan',
                            message:
                                'Tinjau, setujui, dan tindak lanjuti aplikasi bantuan.',
                          ),
                          _AdminCard(
                            icon: Icons.security_outlined,
                            title: 'Audit & Transparansi',
                            message:
                                'Lihat log aktivitas dan laporan penyaluran dana.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 380,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Masuk Admin',
                                  style:
                                      Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Gunakan akun admin/operator/konselor.',
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _email,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  validator: (value) =>
                                      !(value?.contains('@') ?? false)
                                      ? 'Email tidak valid.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  validator: (value) =>
                                      (value?.isEmpty ?? true)
                                      ? 'Password wajib diisi.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: NsdColors.coral,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                FilledButton(
                                  onPressed: _loading ? null : _login,
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text('Masuk ke Panel'),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Demo admin: admin@nsd.id / Demo1234',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
