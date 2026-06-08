import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.session,
    super.key,
    this.registerInitially = false,
    this.initialRole = 'donatur',
    this.allowRegistration = true,
    this.demoText = 'Demo: donatur@nsd.id / Demo1234',
  });

  final AuthSession session;
  final bool registerInitially;
  final String initialRole;
  final bool allowRegistration;
  final String demoText;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  late bool _register;
  late String _role;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _register = widget.allowRegistration && widget.registerInitially;
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_register) {
        await widget.session.register(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          role: _role,
        );
      } else {
        await widget.session.login(_email.text, _password.text);
      }
      if (mounted && Navigator.canPop(context)) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NsdColors.mint,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const NsdLogo(),
                              if (Navigator.canPop(context))
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            _register
                                ? 'Buat akun NSD'
                                : 'Selamat datang kembali',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _register
                                ? 'Bergabung sebagai donatur atau ajukan bantuan terverifikasi.'
                                : 'Masuk untuk melanjutkan kebaikan Anda.',
                          ),
                          const SizedBox(height: 26),
                          if (_register) ...[
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'donatur',
                                  icon: Icon(Icons.favorite_outline),
                                  label: Text('Donatur'),
                                ),
                                ButtonSegment(
                                  value: 'pemohon',
                                  icon: Icon(Icons.front_hand_outlined),
                                  label: Text('Pemohon'),
                                ),
                              ],
                              selected: {_role},
                              onSelectionChanged: (value) =>
                                  setState(() => _role = value.first),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nama lengkap',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 3
                                  ? 'Masukkan nama lengkap.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nomor WhatsApp',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 8
                                  ? 'Nomor telepon minimal 8 digit.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) =>
                                !(value?.contains('@') ?? false)
                                ? 'Masukkan email yang valid.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: _hidePassword,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                _register && (value?.length ?? 0) < 8
                                ? 'Password minimal 8 karakter.'
                                : (value?.isEmpty ?? true)
                                ? 'Password wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_register ? 'Daftar sekarang' : 'Masuk'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: widget.allowRegistration
                                ? () => setState(() => _register = !_register)
                                : null,
                            child: Text(
                              widget.allowRegistration
                                  ? _register
                                        ? 'Sudah punya akun? Masuk'
                                        : 'Belum punya akun? Daftar'
                                  : 'Registrasi hanya melalui aplikasi user',
                            ),
                          ),
                          if (!_register) ...[
                            const Divider(height: 32),
                            Text(
                              widget.demoText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
