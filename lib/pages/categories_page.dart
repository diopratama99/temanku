import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/state_widgets.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _typeFilter = 'expense';
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final user = context.read<AuthNotifier>().user!;
    final db = context.read<AppDatabase>().db;

    final results = await db.query(
      'categories',
      where: 'user_id=? AND type=?',
      whereArgs: [user['id'], _typeFilter],
      orderBy: 'name ASC',
    );

    setState(() => _categories = results);
  }

  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    child: const Icon(Icons.add, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    'Tambah Kategori ${_typeFilter == 'expense' ? 'Pengeluaran' : 'Pemasukan'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              TextField(
                controller: emojiCtrl,
                decoration: InputDecoration(
                  labelText: 'Emoji',
                  hintText: '😀',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                  helperText: 'Ketik emoji atau salin dari keyboard',
                ),
                maxLength: 2,
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppTheme.space24),
              FilledButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    showErrorSnackbar(
                      context,
                      'Nama kategori tidak boleh kosong',
                    );
                    return;
                  }

                  final user = context.read<AuthNotifier>().user!;
                  final db = context.read<AppDatabase>().db;

                  await db.insert('categories', {
                    'user_id': user['id'],
                    'name': nameCtrl.text.trim(),
                    'emoji': emojiCtrl.text.trim().isNotEmpty
                        ? emojiCtrl.text.trim()
                        : '📌',
                    'type': _typeFilter,
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      _loadCategories();
      if (!mounted) return;
      showSuccessSnackbar(context, 'Kategori berhasil ditambahkan');
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AppDatabase>().db.delete(
        'categories',
        where: 'id=?',
        whereArgs: [id],
      );
      _loadCategories();
      if (!mounted) return;
      showSuccessSnackbar(context, 'Kategori berhasil dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori'), centerTitle: false),
      body: Column(
        children: [
          // Type Selector Card
          Container(
            margin: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Pengeluaran',
                    value: 'expense',
                    icon: Icons.trending_down,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Pemasukan',
                    value: 'income',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: _categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          'Belum ada kategori ${_typeFilter == 'expense' ? 'pengeluaran' : 'pemasukan'}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Tap tombol + untuk menambah',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _buildCategoryCard(cat);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isActive = _typeFilter == value;

    return InkWell(
      onTap: () {
        setState(() => _typeFilter = value);
        _loadCategories();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final name = cat['name'] as String;
    final emoji = cat['emoji'] as String? ?? '📌';
    final id = cat['id'] as int;

    return Dismissible(
      key: Key('cat-$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _deleteCategory(id, name).then((_) => false),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.space16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            _typeFilter == 'expense' ? 'Pengeluaran' : 'Pemasukan',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteCategory(id, name),
          ),
        ),
      ),
    );
  }
}
