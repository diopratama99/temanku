import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/state_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  int _tabIndex = 0;
  bool _busy = false;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() => _busy = true);
    String? err;
    try {
      final auth = context.read<AuthNotifier>();
      err = await auth.login(_loginEmail.text, _loginPassword.text);
    } catch (e) {
      err = 'Gagal login: $e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (err != null) {
      showErrorSnackbar(context, err);
    } else {
      showSuccessSnackbar(context, 'Login berhasil!');
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _doRegister() async {
    setState(() => _busy = true);
    String? err;
    try {
      final auth = context.read<AuthNotifier>();
      err = await auth.register(
        _regName.text,
        _regEmail.text,
        _regPassword.text,
      );
    } catch (e) {
      err = 'Gagal daftar: $e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (err != null) {
      showErrorSnackbar(context, err);
    } else {
      showSuccessSnackbar(context, 'Registrasi berhasil!');
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _doGoogle() async {
    setState(() => _busy = true);
    String? err;
    try {
      final auth = context.read<AuthNotifier>();
      err = await auth.loginGoogle();
    } catch (e) {
      err = 'Gagal login Google: $e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (err != null) {
      showErrorSnackbar(context, err);
    } else {
      showSuccessSnackbar(context, 'Login dengan Google berhasil!');
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppDatabase>();
    final isBusy = _busy;
    if (context.watch<AuthNotifier>().isLoggedIn) {
      // Will be redirected by MaterialApp home builder
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space32,
            AppTheme.space24,
            MediaQuery.of(context).viewInsets.bottom + AppTheme.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Icon
              const SizedBox(height: AppTheme.space32),
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.space16),

              // App Title
              Text(
                'Temanku',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Kelola Keuangan Pribadi',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.space48),

              // Login/Register Tabs
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Masuk'),
                    icon: Icon(Icons.login),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Daftar'),
                    icon: Icon(Icons.person_add),
                  ),
                ],
                selected: {_tabIndex},
                onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
              ),

              const SizedBox(height: AppTheme.space24),

              // Form Content
              _tabIndex == 0 ? _buildLogin() : _buildRegister(),

              const SizedBox(height: AppTheme.space32),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                    ),
                    child: Text(
                      'Atau',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: AppTheme.space24),

              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : _doGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Masuk dengan Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            helperText: 'Masukkan alamat email Anda',
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        PasswordFormField(
          controller: _loginPassword,
          label: 'Password',
          helperText: 'Masukkan password Anda',
        ),
        const SizedBox(height: AppTheme.space24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _doLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            ),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Masuk'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _regName,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            prefixIcon: Icon(Icons.person_outline),
            helperText: 'Masukkan nama lengkap Anda',
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        TextField(
          controller: _regEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            helperText: 'Masukkan alamat email yang valid',
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        PasswordFormField(
          controller: _regPassword,
          label: 'Password',
          helperText: 'Minimal 8 karakter dengan kombinasi huruf dan angka',
          showStrengthIndicator: true,
        ),
        const SizedBox(height: AppTheme.space24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _doRegister,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            ),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Daftar'),
          ),
        ),
      ],
    );
  }
}
