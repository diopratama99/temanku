import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _picture = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user!;
    _name.text = (user['name'] as String?) ?? '';
    _picture.text = (user['picture'] as String?) ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _picture.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _saveIdentity() async {
    final user = context.read<AuthNotifier>().user!;
    await context.read<AppDatabase>().db.update(
      'users',
      {
        'name': _name.text.trim(),
        'picture': _picture.text.trim().isEmpty ? null : _picture.text.trim(),
      },
      where: 'id=?',
      whereArgs: [user['id']],
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthNotifier>().logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user!;
    final isGoogleUser =
        (user['google_sub'] as String?) != null &&
        (user['google_sub'] as String).isNotEmpty;

    // Body only - AppBar handled by HomePage
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: (_picture.text.trim().isNotEmpty)
                  ? NetworkImage(_picture.text.trim())
                  : null,
              child: (_picture.text.trim().isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _picture,
          decoration: const InputDecoration(labelText: 'URL Foto (opsional)'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saveIdentity,
            child: const Text('Simpan Profil'),
          ),
        ),
        const Divider(height: 32),
        if (isGoogleUser)
          const Text(
            'Akun Google tidak dapat mengganti password di sini.',
            style: TextStyle(color: Colors.grey),
          )
        else ...[
          TextField(
            controller: _currentPassword,
            decoration: const InputDecoration(labelText: 'Password Saat Ini'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassword,
            decoration: const InputDecoration(labelText: 'Password Baru'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            decoration: const InputDecoration(
              labelText: 'Konfirmasi Password Baru',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                if (_newPassword.text != _confirmPassword.text ||
                    _newPassword.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password baru tidak valid')),
                  );
                  return;
                }
                final user = context.read<AuthNotifier>().user!;
                // Very basic change: we cannot verify current hash here without original method; do simple check through login api.
                // Reuse AuthService.login to verify current password before update.
                final authNotifier = context.read<AuthNotifier>();
                final err = await authNotifier.login(
                  user['email'] as String,
                  _currentPassword.text,
                );
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password saat ini salah')),
                  );
                  return;
                }
                // logged in now; update hash
                final newHash = sha256
                    .convert(utf8.encode(_newPassword.text))
                    .toString();
                await context.read<AppDatabase>().db.update(
                  'users',
                  {'password_hash': newHash},
                  where: 'id=?',
                  whereArgs: [user['id']],
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password diperbarui')),
                );
              },
              child: const Text('Ganti Password'),
            ),
          ),
        ],
        const Divider(height: 32),
        // Logout button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
