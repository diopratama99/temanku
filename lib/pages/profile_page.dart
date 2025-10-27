import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../state/theme_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/state_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Currency selector removed - app uses IDR only

  @override
  void initState() {
    super.initState();
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

    if (confirm == true) {
      await context.read<AuthNotifier>().logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _resetData() async {
    // Step 1: First confirmation
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Peringatan!'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus SEMUA data?\n\n'
          'Data yang akan dihapus:\n'
          '• Semua transaksi\n'
          '• Semua kategori\n'
          '• Semua budget\n'
          '• Semua tabungan\n\n'
          'Tindakan ini TIDAK DAPAT dibatalkan!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Step 2: Type "HAPUS DATA" confirmation
    final textController = TextEditingController();
    final confirm2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Konfirmasi Penghapusan',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ketik "HAPUS DATA" untuk mengonfirmasi penghapusan:',
              style: TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ketik: HAPUS DATA',
              ),
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.trim() == 'HAPUS DATA') {
                Navigator.pop(context, true);
              } else {
                showErrorSnackbar(context, 'Teks tidak sesuai!');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Semua Data'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    // Perform data deletion
    try {
      final user = context.read<AuthNotifier>().user!;
      final userId = user['id'] as int;
      final db = context.read<AppDatabase>().db;

      await db.transaction((txn) async {
        // Delete all user data
        await txn.delete(
          'transactions',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        await txn.delete(
          'categories',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        await txn.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete(
          'savings_goals',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        await txn.delete(
          'savings_allocations',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        await txn.delete(
          'savings_auto_transfers',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      });

      if (!mounted) return;
      showSuccessSnackbar(context, '✅ Semua data berhasil dihapus!');

      // Refresh to dashboard
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Gagal menghapus data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user!;
    final name = user['name'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Debit Card Style Profile Card
            Stack(
              children: [
                Container(
                  height: 210,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF157347),
                        const Color(0xFF0D4D33),
                        const Color(0xFF1A8B5E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bank Name & Profile Photo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TEMANKU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                fontFamily: 'Courier New',
                              ),
                            ),
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: user['picture'] != null
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(user['picture'] as String),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: user['picture'] == null
                                  ? Center(
                                      child: Text(
                                        (name ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF157347),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        // Chip Card
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber.shade600,
                                  width: 2,
                                ),
                              ),
                              child: CustomPaint(painter: ChipPainter()),
                            ),
                          ],
                        ),
                        // Name Only (Credit Card Style - UPPERCASE)
                        Text(
                          (name ?? 'USER').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            fontFamily: 'Courier New',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Edit Button - Pensil kecil di pojok kanan bawah
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Color(0xFF157347),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Profile Info Section
            _buildSectionCard(
              title: 'Informasi Profil',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Nama Lengkap',
                  value: name ?? 'User',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Username',
                  value: user['username'] as String? ?? '-',
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space16),

            // TODO: Dark Mode Toggle - Temporarily disabled, will re-enable later
            // TODO: Currency Selector - Removed, app uses IDR only
            const SizedBox(height: AppTheme.space16),

            // Reset Data Button
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Reset Data',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Hapus semua data transaksi'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                onTap: _resetData,
              ),
            ),

            const SizedBox(height: AppTheme.space16),

            // Logout Button
            Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade700,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Keluar dari aplikasi'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 32),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'Temanku',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.5.0',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextDisabled.withOpacity(0.2)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppTheme.darkPrimaryColor
                                : AppTheme.primaryColor)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            icon,
            color: isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Chip Painter untuk menggambar chip card
class ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer rounded rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(3),
      ),
      paint,
    );

    // Inner lines (chip pattern)
    final linePaint = Paint()
      ..color = Colors.amber.shade700
      ..strokeWidth = 1;

    // Horizontal lines
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.3),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.5),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.7),
      linePaint,
    );

    // Vertical lines
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.2),
      Offset(size.width * 0.35, size.height * 0.8),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.2),
      Offset(size.width * 0.65, size.height * 0.8),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Edit Profile Page
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user!;
    _name.text = (user['name'] as String?) ?? '';
    _profilePicturePath = (user['picture'] as String?);
  }

  @override
  void dispose() {
    _name.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    final user = context.read<AuthNotifier>().user!;
    await context.read<AppDatabase>().db.update(
      'users',
      {'picture': image.path},
      where: 'id=?',
      whereArgs: [user['id']],
    );

    if (!mounted) return;
    setState(() => _profilePicturePath = image.path);
    await context.read<AuthNotifier>().refreshUser();
    showSuccessSnackbar(context, 'Foto profil berhasil diubah');
  }

  Future<void> _saveIdentity() async {
    if (_name.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Nama tidak boleh kosong');
      return;
    }

    final user = context.read<AuthNotifier>().user!;
    await context.read<AppDatabase>().db.update(
      'users',
      {'name': _name.text.trim()},
      where: 'id=?',
      whereArgs: [user['id']],
    );

    if (!mounted) return;
    await context.read<AuthNotifier>().refreshUser();
    showSuccessSnackbar(context, 'Profil berhasil diperbarui');
  }

  Future<void> _changePassword() async {
    if (_currentPassword.text.isEmpty ||
        _newPassword.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      showErrorSnackbar(context, 'Semua field harus diisi');
      return;
    }

    if (_newPassword.text != _confirmPassword.text) {
      showErrorSnackbar(context, 'Password baru tidak cocok');
      return;
    }

    if (_newPassword.text.length < 6) {
      showErrorSnackbar(context, 'Password minimal 6 karakter');
      return;
    }

    final user = context.read<AuthNotifier>().user!;
    final currentHash = sha256
        .convert(utf8.encode(_currentPassword.text))
        .toString();

    if (user['password_hash'] != currentHash) {
      showErrorSnackbar(context, 'Password lama salah');
      return;
    }

    final newHash = sha256.convert(utf8.encode(_newPassword.text)).toString();
    await context.read<AppDatabase>().db.update(
      'users',
      {'password_hash': newHash},
      where: 'id=?',
      whereArgs: [user['id']],
    );

    if (!mounted) return;
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    showSuccessSnackbar(context, 'Password berhasil diubah');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user!;
    final name = user['name'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            // Profile Picture Section
            GestureDetector(
              onTap: _pickProfilePicture,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: _profilePicturePath != null
                          ? DecorationImage(
                              image: FileImage(File(_profilePicturePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profilePicturePath == null
                        ? Center(
                            child: Text(
                              (name ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Edit Name Section
            _buildSectionCard(
              title: 'Edit Profil',
              icon: Icons.person_outline,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveIdentity,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Perubahan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space16),

            // Change Password Section
            _buildSectionCard(
              title: 'Ubah Password',
              icon: Icons.lock_outline,
              children: [
                TextField(
                  controller: _currentPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Lama',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    helperText: 'Minimal 6 karakter',
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                TextField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.check),
                    label: const Text('Ubah Password'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextDisabled.withOpacity(0.2)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppTheme.darkPrimaryColor
                                : AppTheme.primaryColor)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isDark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            ...children,
          ],
        ),
      ),
    );
  }
}
