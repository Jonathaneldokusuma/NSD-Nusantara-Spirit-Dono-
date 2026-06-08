import 'package:flutter/material.dart';

import '../core/api_client.dart';
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
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loggingOutUnauthorized = false;
  String? _error;

  bool get _hasAdminAccess {
    final role = widget.session.user?.role;
    return ['operator', 'admin', 'super_admin'].contains(role);
  }

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
      if (!_hasAdminAccess) {
        await widget.session.logout();
        if (mounted) {
          setState(() {
            _error =
                'Panel internal hanya untuk operator, admin, dan super admin.';
          });
        }
        return;
      }
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logoutUnauthorized() {
    if (_loggingOutUnauthorized) return;
    _loggingOutUnauthorized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.session.logout();
      if (!mounted) return;
      setState(() {
        _loggingOutUnauthorized = false;
        _error = 'Panel internal hanya untuk operator, admin, dan super admin.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.initializing) {
      return const Scaffold(body: LoadingView());
    }
    if (widget.session.isAuthenticated && !_hasAdminAccess) {
      _logoutUnauthorized();
      return const Scaffold(body: LoadingView());
    }
    if (_hasAdminAccess) {
      return DashboardScreen(api: widget.api, session: widget.session);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: const NsdLogo(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: NsdColors.border),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Panel Internal NSD',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Masuk dengan akun operator, admin, atau super admin.',
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) => !(value?.contains('@') ?? false)
                          ? 'Email tidak valid.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      onFieldSubmitted: (_) => _login(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
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
                      const SizedBox(height: 10),
                    ],
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 12),
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
      ),
    );
  }
}
