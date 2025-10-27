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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _tabController.dispose();
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
      // Navigate to root and clear all routes
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppDatabase>();
    if (context.watch<AuthNotifier>().isLoggedIn) {
      // Will be redirected by MaterialApp home builder
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Icon
              const SizedBox(height: AppTheme.space24),
              Image.asset(
                'assets/images/temanku_icon.png',
                width: 140,
                height: 140,
              ),
              const SizedBox(height: AppTheme.space8),

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
                'Teman kecil yang bantu jagain keuanganmu',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.space48),

              // Login/Register Tabs - Modern Segmented Control
              Container(
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Stack(
                  children: [
                    // Animated background
                    AnimatedAlign(
                      alignment: _tabController.index == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2 - 32,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tabs
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_tabController.index != 0) {
                                _tabController.animateTo(0);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _tabController.index == 0
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                                child: const Text('Masuk'),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_tabController.index != 1) {
                                _tabController.animateTo(1);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _tabController.index == 1
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                                child: const Text('Daftar'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space16),

              // Form Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildLogin(), _buildRegister()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _loginEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          PasswordFormField(controller: _loginPassword, label: 'Password'),
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
          const SizedBox(height: AppTheme.space24),
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
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
              onPressed: _busy ? null : _doGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Masuk dengan Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _regName,
            decoration: const InputDecoration(
              hintText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          TextField(
            controller: _regEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          PasswordFormField(
            controller: _regPassword,
            label: 'Password',
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
      ),
    );
  }
}
