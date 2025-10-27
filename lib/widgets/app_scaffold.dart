import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final bool showQuickChips;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showQuickChips = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Temanku',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profil',
          ),
          if (actions != null) ...actions!,
        ],
      ),
      drawer: _DrawerMenu(
        onLogout: () async {
          await context.read<AuthNotifier>().logout();
          // close drawer then go to login
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      ),
      body: (auth.isLoggedIn && showQuickChips)
          ? Column(
              children: [
                const _QuickChips(),
                Expanded(child: body),
              ],
            )
          : body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _DrawerMenu extends StatelessWidget {
  final Future<void> Function() onLogout;
  const _DrawerMenu({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            if (auth.isLoggedIn) ...[
              ListTile(
                title: Text(
                  'Halo, ${auth.user?['name'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Semangat cari uangnya ya!'),
              ),
              const Divider(),
            ],
            _nav(context, Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
            _nav(
              context,
              Icons.account_balance_wallet_outlined,
              'Saldo Akun',
              '/accounts',
            ),
            _nav(context, Icons.add_circle_outline, 'Tambah transaksi', '/add'),
            _nav(context, Icons.history_toggle_off, 'Riwayat', '/transactions'),
            _nav(context, Icons.category_outlined, 'Kategori', '/categories'),
            _nav(context, Icons.receipt_long_outlined, 'Budget', '/budgets'),
            _nav(context, Icons.savings_outlined, 'Tabungan', '/savings'),
            _nav(context, Icons.import_export, 'Import/Export', '/import'),
            _nav(
              context,
              Icons.person_outline,
              'Pengaturan Profil',
              '/profile',
            ),
            const Divider(),
            _nav(context, Icons.palette_outlined, 'UI Showcase', '/showcase'),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 8,
            color: Color(0x14000000),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(context, 'Dashboard', '/dashboard'),
            const SizedBox(width: 10),
            _chip(context, 'Tambah transaksi', '/add', selected: true),
            const SizedBox(width: 10),
            _chip(context, 'Kategori', '/categories'),
            const SizedBox(width: 10),
            _chip(context, 'Budget', '/budgets'),
            const SizedBox(width: 10),
            _chip(context, 'Tabungan', '/savings'),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    String route, {
    bool selected = false,
  }) {
    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(label),
      ),
      selected: selected,
      onSelected: (_) => Navigator.pushNamed(context, route),
    );
  }
}
