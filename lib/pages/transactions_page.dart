import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/state_widgets.dart';
import '../widgets/transaction_list_item.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late DateTime _start;
  late DateTime _end;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppDatabase>();
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final rows = await db.db.rawQuery(
      '''
      SELECT t.*, COALESCE(c.name,'-') AS category, c.emoji AS category_emoji
      FROM transactions t
      LEFT JOIN categories c ON c.id=t.category_id
      WHERE t.user_id=? AND t.date BETWEEN ? AND ?
      ORDER BY t.date DESC, t.id DESC
    ''',
      [userId, _iso(_start), _iso(_end)],
    );
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    // Body only - AppBar handled by HomePage
    return _loading
        ? const LoadingStateWidget(message: 'Memuat transaksi...')
        : Column(
            children: [
              // Date Filter
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _start,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _start = picked);
                            await _load();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_iso(_start)),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _end,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _end = picked);
                            await _load();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_iso(_end)),
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: _rows.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum Ada Transaksi',
                        description:
                            'Mulai tambahkan transaksi untuk periode ini',
                        actionLabel: 'Tambah Transaksi',
                        onAction: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditTransactionPage(),
                            ),
                          );
                          await _load();
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.space24,
                        ),
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          return TransactionListTile(
                            transaction: r,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditTransactionPage(existing: r),
                                ),
                              );
                              await _load();
                            },
                            onDelete: () async {
                              await context.read<AppDatabase>().db.delete(
                                'transactions',
                                where: 'id=?',
                                whereArgs: [r['id']],
                              );
                              showSuccessSnackbar(
                                context,
                                'Transaksi berhasil dihapus',
                              );
                              await _load();
                            },
                          );
                        },
                      ),
              ),
            ],
          );
  }
}

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const EditTransactionPage({this.existing});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late DateTime _date;
  late String _type;
  int? _categoryId;
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _notes = TextEditingController();
  String _account = 'Transfer';
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _date = ex != null
        ? DateFormat('yyyy-MM-dd').parse(ex['date'] as String)
        : DateTime.now();
    _type = ex != null ? (ex['type'] as String) : 'expense';
    _account = ex != null
        ? ((ex['account'] as String?) ?? 'Transfer')
        : 'Transfer';
    _amount.text = ex != null ? ((ex['amount'] as num).toString()) : '';
    _payee.text = ex != null ? ((ex['source_or_payee'] as String?) ?? '') : '';
    _notes.text = ex != null ? ((ex['notes'] as String?) ?? '') : '';
    _categoryId = ex != null ? (ex['category_id'] as int?) : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCats();
      _loadFavorites();
    });
  }

  Future<void> _loadCats() async {
    try {
      final userId = context.read<AuthNotifier>().user!['id'] as int;
      final rows = await context.read<AppDatabase>().db.query(
        'categories',
        where: 'user_id=? AND type=?',
        whereArgs: [userId, _type],
        orderBy: 'name',
      );
      if (!mounted) return;
      setState(() {
        _cats = rows;
        if (_cats.isEmpty) {
          _categoryId = null;
        } else {
          final has = _cats.any((e) => e['id'] == _categoryId);
          if (!has) _categoryId = _cats.first['id'] as int;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cats = [];
      });
    }
  }

  Future<void> _save() async {
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final amount = num.tryParse(
      _amount.text.replaceAll('.', '').replaceAll(',', '.'),
    )?.toDouble();
    if (amount == null || _categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi data')));
      return;
    }
    if (widget.existing == null) {
      await context.read<AppDatabase>().db.insert('transactions', {
        'user_id': userId,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'type': _type,
        'category_id': _categoryId,
        'amount': amount,
        'source_or_payee': _payee.text,
        'account': _account,
        'notes': _notes.text,
      });
    } else {
      await context.read<AppDatabase>().db.update(
        'transactions',
        {
          'date': DateFormat('yyyy-MM-dd').format(_date),
          'type': _type,
          'category_id': _categoryId,
          'amount': amount,
          'source_or_payee': _payee.text,
          'account': _account,
          'notes': _notes.text,
        },
        where: 'id=?',
        whereArgs: [widget.existing!['id']],
      );
    }
    if (!mounted) return;
    // Arahkan ke halaman Riwayat setelah simpan
    Navigator.pushReplacementNamed(context, '/transactions');
  }

  Future<void> _loadFavorites() async {
    try {
      final userId = context.read<AuthNotifier>().user!['id'] as int;
      final favs = await context.read<AppDatabase>().db.query(
        'favorites',
        where: 'user_id=? AND type=?',
        whereArgs: [userId, _type],
        orderBy: 'name',
      );
      if (!mounted) return;
      setState(() {
        _favorites = favs;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favorites = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space16,
            AppTheme.space16,
            MediaQuery.of(context).viewInsets.bottom + AppTheme.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_favorites.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final f in _favorites)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    avatar: const Icon(
                                      Icons.star_border,
                                      size: 18,
                                    ),
                                    label: Text(f['name'] as String),
                                    onPressed: () {
                                      setState(() {
                                        _type = f['type'] as String;
                                        _categoryId = f['category_id'] as int;
                                        _amount.text =
                                            ((f['amount'] as num?) ?? 0)
                                                .toString();
                                        _account =
                                            (f['account'] as String?) ??
                                            'Transfer';
                                        _payee.text =
                                            (f['source_or_payee'] as String?) ??
                                            '';
                                        _notes.text =
                                            (f['notes'] as String?) ?? '';
                                      });
                                      _loadCats();
                                    },
                                  ),
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.add),
                                label: const Text('Simpan Favorit'),
                                onPressed: () async {
                                  final nameCtrl = TextEditingController();
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Simpan sebagai Favorit',
                                      ),
                                      content: TextField(
                                        controller: nameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Batal'),
                                        ),
                                        FilledButton(
                                          onPressed: () async {
                                            final userId =
                                                context
                                                        .read<AuthNotifier>()
                                                        .user!['id']
                                                    as int;
                                            await context
                                                .read<AppDatabase>()
                                                .db
                                                .insert(
                                                  'favorites',
                                                  {
                                                    'user_id': userId,
                                                    'name': nameCtrl.text
                                                        .trim(),
                                                    'type': _type,
                                                    'category_id': _categoryId,
                                                    'amount': num.tryParse(
                                                      _amount.text
                                                          .replaceAll('.', '')
                                                          .replaceAll(',', '.'),
                                                    )?.toDouble(),
                                                    'account': _account,
                                                    'source_or_payee':
                                                        _payee.text,
                                                    'notes': _notes.text,
                                                  },
                                                  conflictAlgorithm:
                                                      ConflictAlgorithm.replace,
                                                );
                                            if (!mounted) return;
                                            Navigator.pop(context);
                                            await _loadFavorites();
                                          },
                                          child: const Text('Simpan'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Jenis (vertikal agar stabil di semua device)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jenis',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              textStyle: MaterialStateProperty.all(
                                const TextStyle(fontSize: 13),
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: 'expense',
                                label: Text('Keluar'),
                                icon: Icon(Icons.south_east),
                              ),
                              ButtonSegment(
                                value: 'income',
                                label: Text('Masuk'),
                                icon: Icon(Icons.north_east),
                              ),
                            ],
                            selected: {_type},
                            onSelectionChanged: (sel) {
                              setState(() => _type = sel.first);
                              _loadCats();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tanggal
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          hintText: DateFormat('yyyy-MM-dd').format(_date),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _categoryId,
                        items: [
                          for (final c in _cats)
                            DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text(c['name'] as String),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        style: const TextStyle(color: Colors.black87),
                        dropdownColor: Colors.white,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              textStyle: MaterialStateProperty.all(
                                const TextStyle(fontSize: 12),
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: 'Transfer',
                                label: Text('Rek'),
                                icon: Icon(Icons.account_balance),
                              ),
                              ButtonSegment(
                                value: 'Tunai',
                                label: Text('Tunai'),
                                icon: Icon(Icons.payments_outlined),
                              ),
                              ButtonSegment(
                                value: 'E-Wallet',
                                label: Text('E-Wlt'),
                                icon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                            ],
                            selected: {_account},
                            onSelectionChanged: (s) =>
                                setState(() => _account = s.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _payee,
                        decoration: const InputDecoration(
                          labelText: 'Sumber/Penerima',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notes,
                        decoration: const InputDecoration(labelText: 'Catatan'),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _save,
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
