import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _type = 'expense';
  List<Map<String, dynamic>> _rows = [];
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final rows = await context.read<AppDatabase>().db.query(
      'categories',
      where: 'user_id=? AND type=?',
      whereArgs: [userId, _type],
      orderBy: 'name',
    );
    setState(() => _rows = rows);
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim();
    if (name.isEmpty) return;
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    await context.read<AppDatabase>().db.insert('categories', {
      'user_id': userId,
      'type': _type,
      'name': name,
      'emoji': emoji.isEmpty ? null : emoji,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    _nameCtrl.clear();
    _emojiCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
              ButtonSegment(value: 'income', label: Text('Pemasukan')),
            ],
            selected: {_type},
            onSelectionChanged: (s) async {
              setState(() => _type = s.first);
              await _load();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _emojiCtrl,
                    decoration: const InputDecoration(hintText: '😀'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nama kategori',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Text('Tambah')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final r = _rows[i];
                return Dismissible(
                  key: ValueKey(r['id']),
                  background: Container(color: Colors.red),
                  onDismissed: (_) async {
                    await context.read<AppDatabase>().db.delete(
                      'categories',
                      where: 'id=?',
                      whereArgs: [r['id']],
                    );
                    _rows.removeAt(i);
                    setState(() {});
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        ((r['emoji'] as String?) ?? '•').characters.first,
                      ),
                    ),
                    title: Text(r['name'] as String),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
