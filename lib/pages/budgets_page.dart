import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late String _month; // YYYY-MM
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _expCats = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateFormat('yyyy-MM').format(now);
    _load();
  }

  Future<void> _load() async {
    final db = context.read<AppDatabase>();
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final rows = await db.db.rawQuery(
      '''
      SELECT b.id, c.name AS category, b.category_id, b.amount,
             COALESCE( (SELECT SUM(amount) FROM transactions
                        WHERE user_id=b.user_id AND type='expense' AND category_id=b.category_id
                          AND substr(date,1,7)=b.month), 0) AS spent
      FROM budgets b
      JOIN categories c ON c.id=b.category_id
      WHERE b.user_id=? AND b.month=?
      ORDER BY c.name
    ''',
      [userId, _month],
    );

    final cats = await db.db.query(
      'categories',
      where: 'user_id=? AND type=?',
      whereArgs: [userId, 'expense'],
      orderBy: 'name',
    );
    setState(() {
      _rows = rows;
      _expCats = cats;
    });
  }

  String _money(num v) => 'Rp ${NumberFormat.decimalPattern('id').format(v)}';

  @override
  Widget build(BuildContext context) {
    // Body only - AppBar handled by HomePage
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.parse('$_month-01');
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      helpText: 'Pilih tanggal dalam bulan',
                    );
                    if (picked != null) {
                      setState(
                        () => _month = DateFormat('yyyy-MM').format(picked),
                      );
                      await _load();
                    }
                  },
                  child: Text('Bulan: $_month'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _rows.length,
            itemBuilder: (context, i) {
              final r = _rows[i];
              final amount = (r['amount'] as num).toDouble();
              final spent = (r['spent'] as num).toDouble();
              final ratio = amount <= 0
                  ? 0.0
                  : (spent / amount).clamp(0.0, 1.0);
              return ListTile(
                title: Text(r['category'] as String),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: ratio),
                    const SizedBox(height: 4),
                    Text('${_money(spent)} / ${_money(amount)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await context.read<AppDatabase>().db.delete(
                      'budgets',
                      where: 'id=?',
                      whereArgs: [r['id']],
                    );
                    await _load();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog() async {
    int? selectedCatId;
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCatId,
                items: [
                  for (final c in _expCats)
                    DropdownMenuItem(
                      value: c['id'] as int,
                      child: Text(c['name'] as String),
                    ),
                ],
                onChanged: (v) => selectedCatId = v,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final userId = context.read<AuthNotifier>().user!['id'] as int;
                final amount = num.tryParse(
                  amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
                )?.toDouble();
                if (selectedCatId == null || amount == null) return;
                await context.read<AppDatabase>().db.insert('budgets', {
                  'user_id': userId,
                  'category_id': selectedCatId,
                  'month': _month,
                  'amount': amount,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
                if (!mounted) return;
                Navigator.pop(context);
                await _load();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
