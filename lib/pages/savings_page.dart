import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Map<String, dynamic>> _goals = [];
  bool _loading = false;
  double _totalIn = 0;
  double _totalAlloc = 0; // termasuk consumed
  double _potAvailable = 0;
  double _availCurrent = 0;
  List<Map<String, dynamic>> _topupsCurrent = [];

  // Form states (alokasi & topup)
  int? _allocGoalId;
  final _allocAmount = TextEditingController();
  final _allocNote = TextEditingController();
  final _topupAmount = TextEditingController();
  final _topupNote = TextEditingController();
  // removed quick-add controllers to avoid duplicate entry points

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _money(num v) => 'Rp ${NumberFormat.decimalPattern('id').format(v)}';

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final db = context.read<AppDatabase>().db;
    final rows = await db.rawQuery(
      '''
      SELECT g.id, g.name, g.target_amount, g.archived_at,
             COALESCE(SUM(a.amount),0) AS allocated
      FROM savings_goals g
      LEFT JOIN savings_allocations a ON a.goal_id=g.id AND a.user_id=g.user_id
      WHERE g.user_id=?
      GROUP BY g.id
      ORDER BY g.archived_at IS NOT NULL, g.created_at DESC
    ''',
      [userId],
    );

    // Summary data mengikuti versi web
    final auto = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS t FROM savings_auto_transfers WHERE user_id=?',
      [userId],
    );
    final manual = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS t FROM savings_manual_topups WHERE user_id=?',
      [userId],
    );
    final alloc = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS t FROM savings_allocations WHERE user_id=?',
      [userId],
    );
    final consumed = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) AS t FROM savings_consumed WHERE user_id=?',
      [userId],
    );
    final totalIn =
        ((auto.first['t'] as num?)?.toDouble() ?? 0) +
        ((manual.first['t'] as num?)?.toDouble() ?? 0);
    final totalAlloc =
        ((alloc.first['t'] as num?)?.toDouble() ?? 0) +
        ((consumed.first['t'] as num?)?.toDouble() ?? 0);

    // Sisa income bulan ini
    final ym = DateFormat('yyyy-MM').format(DateTime.now());
    final monthTotals = await db.rawQuery(
      '''
      SELECT SUM(CASE WHEN type='income' THEN amount ELSE 0 END) AS inc,
             SUM(CASE WHEN type='expense' THEN amount ELSE 0 END) AS exp
      FROM transactions WHERE user_id=? AND substr(date,1,7)=?
    ''',
      [userId, ym],
    );
    final inc = (monthTotals.first['inc'] as num?)?.toDouble() ?? 0;
    final exp = (monthTotals.first['exp'] as num?)?.toDouble() ?? 0;
    final double availCurrent = ((inc - exp) < 0) ? 0.0 : (inc - exp);

    final topups = await db.rawQuery(
      'SELECT id, date, amount, note FROM savings_manual_topups WHERE user_id=? AND month=? ORDER BY date DESC, id DESC',
      [userId, ym],
    );

    setState(() {
      _goals = rows;
      _loading = false;
      _totalIn = totalIn;
      _totalAlloc = totalAlloc;
      _potAvailable = totalIn - totalAlloc;
      _availCurrent = availCurrent;
      _topupsCurrent = topups;
      // default selected goal untuk form alokasi
      final active = rows.where((e) => e['archived_at'] == null).toList();
      _allocGoalId = active.isNotEmpty ? active.first['id'] as int : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Body only - AppBar handled by HomePage
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // Ringkasan (responsive)
              _summarySection(),
              const SizedBox(height: 8),
              // Form alokasi saldo
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alokasikan Saldo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _allocGoalId,
                        style: const TextStyle(color: Colors.black87),
                        dropdownColor: Colors.white,
                        iconEnabledColor: Colors.black87,
                        iconDisabledColor: Colors.black45,
                        items: [
                          for (final g in _goals.where(
                            (e) => e['archived_at'] == null,
                          ))
                            DropdownMenuItem(
                              value: g['id'] as int,
                              child: Text(
                                g['name'] as String,
                                style: const TextStyle(color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _allocGoalId = v),
                        decoration: const InputDecoration(
                          labelText: 'Pilih Goal',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _allocAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _allocNote,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saveAllocation,
                          child: const Text('Simpan Alokasi'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saldo tersedia: ${_money(_potAvailable)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Top-up manual bulan ini
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambah ke Tabungan (bulan ini)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _topupAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _topupNote,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saveTopup,
                          child: const Text('Tambah'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sisa pemasukan bulan ini yang tersedia: ${_money(_availCurrent)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      if (_topupsCurrent.isNotEmpty) ...[
                        const Divider(height: 18),
                        const Text(
                          'Top-up bulan ini',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        for (final t in _topupsCurrent)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.south_west,
                              color: Colors.green,
                            ),
                            title: Text(_money(t['amount'] as num)),
                            subtitle: Text((t['date'] as String?) ?? ''),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Header Goals Aktif + aksi tambah (satu titik masuk)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Goals Aktif',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddGoal,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final g in _goals.where((e) => e['archived_at'] == null))
                _goalTile(g),
              if (_goals.any((e) => e['archived_at'] != null)) ...[
                const SizedBox(height: 8),
                const Text(
                  'Arsip',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final g in _goals.where((e) => e['archived_at'] != null))
                  _goalTile(g, archived: true),
              ],
              const SizedBox(height: 12),
            ],
          );
  }

  Widget _summaryCard(String label, double value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              _money(value),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBigCard(String label, double value) {
    const green = Color(0xFF157347);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: green.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings_outlined, color: green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    _money(value),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: green,
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

  Widget _summarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Pada layar kecil, tampilkan 2 kartu di baris pertama, dan 1 kartu besar di bawahnya
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _summaryCard('Total Masuk', _totalIn)),
                  const SizedBox(width: 8),
                  Expanded(child: _summaryCard('Dialokasikan', _totalAlloc)),
                ],
              ),
              const SizedBox(height: 8),
              _summaryBigCard('Saldo Tersedia', _potAvailable),
            ],
          );
        }
        // Di layar lebar, tiga kartu dalam satu baris
        return Row(
          children: [
            Expanded(child: _summaryCard('Total Masuk', _totalIn)),
            const SizedBox(width: 8),
            Expanded(child: _summaryCard('Dialokasikan', _totalAlloc)),
            const SizedBox(width: 8),
            Expanded(child: _summaryCard('Saldo Tersedia', _potAvailable)),
          ],
        );
      },
    );
  }

  Widget _goalTile(Map<String, dynamic> g, {bool archived = false}) {
    final allocated = (g['allocated'] as num).toDouble();
    final target = (g['target_amount'] as num).toDouble();
    final ratio = target <= 0 ? 0.0 : (allocated / target).clamp(0.0, 1.0);
    final done = target > 0 && allocated >= target - 1e-6;
    const green = Color(0xFF157347);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          value: ratio,
                          strokeWidth: 4,
                          backgroundColor: Colors.black12,
                          valueColor: const AlwaysStoppedAnimation(green),
                        ),
                      ),
                      Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              g['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (archived
                                          ? Colors.black26
                                          : const Color(0xFF157347))
                                      .withOpacity(.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              done
                                  ? 'Tercapai'
                                  : (archived ? 'Arsip' : 'Berjalan'),
                              style: TextStyle(
                                color: archived
                                    ? Colors.black54
                                    : const Color(0xFF157347),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'alokasi') {
                                _allocGoalId = g['id'] as int;
                                await _showAllocateSheet();
                              } else if (v == 'lepas') {
                                await _showReleaseSheet(
                                  g['id'] as int,
                                  allocated,
                                );
                              } else if (v == 'arsip') {
                                await context.read<AppDatabase>().db.update(
                                  'savings_goals',
                                  {
                                    'archived_at': DateTime.now()
                                        .toIso8601String(),
                                  },
                                  where: 'id=?',
                                  whereArgs: [g['id']],
                                );
                                await _load();
                              } else if (v == 'unarsip') {
                                await context.read<AppDatabase>().db.update(
                                  'savings_goals',
                                  {'archived_at': null},
                                  where: 'id=?',
                                  whereArgs: [g['id']],
                                );
                                await _load();
                              } else if (v == 'hapus') {
                                await context.read<AppDatabase>().db.delete(
                                  'savings_goals',
                                  where: 'id=?',
                                  whereArgs: [g['id']],
                                );
                                await context.read<AppDatabase>().db.delete(
                                  'savings_allocations',
                                  where: 'goal_id=?',
                                  whereArgs: [g['id']],
                                );
                                await _load();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'alokasi',
                                child: Text('Tambah Alokasi'),
                              ),
                              if (!archived)
                                const PopupMenuItem(
                                  value: 'lepas',
                                  child: Text('Lepas Dana'),
                                ),
                              if (!archived && done)
                                const PopupMenuItem(
                                  value: 'arsip',
                                  child: Text('Arsipkan'),
                                ),
                              if (archived)
                                const PopupMenuItem(
                                  value: 'unarsip',
                                  child: Text('Kembalikan'),
                                ),
                              const PopupMenuItem(
                                value: 'hapus',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: ratio),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, cns) {
                          final narrow = cns.maxWidth < 440;
                          if (!narrow) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _kvSmall(
                                    'Terkumpul',
                                    _money(allocated),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _kvSmall('Target', _money(target)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _kvSmall(
                                    'Sisa',
                                    _money(
                                      (target - allocated).clamp(
                                        0,
                                        double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _kvSmall(
                                      'Terkumpul',
                                      _money(allocated),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _kvSmall('Target', _money(target)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _kvSmall(
                                'Sisa',
                                _money(
                                  (target - allocated).clamp(
                                    0,
                                    double.infinity,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGoal() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Goal Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama goal'),
            ),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Target (Rp)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              final target = num.tryParse(
                amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
              )?.toDouble();
              if ((nameCtrl.text.trim()).isEmpty || target == null) return;
              await context.read<AppDatabase>().db.insert('savings_goals', {
                'user_id': userId,
                'name': nameCtrl.text.trim(),
                'target_amount': target,
              });
              if (!mounted) return;
              Navigator.pop(context);
              await _load();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAllocateDialog(int goalId) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = DateTime.now();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Alokasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  date = picked;
                }
              },
              child: Text(DateFormat('yyyy-MM-dd').format(date)),
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
              if (amount == null) return;
              await context
                  .read<AppDatabase>()
                  .db
                  .insert('savings_allocations', {
                    'user_id': userId,
                    'goal_id': goalId,
                    'amount': amount,
                    'date': DateFormat('yyyy-MM-dd').format(date),
                    'note': noteCtrl.text,
                  });
              if (!mounted) return;
              Navigator.pop(context);
              await _load();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Quick-add goal removed in favor of single entry via header button (_showAddGoal)

  Future<void> _showAllocateSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tambah Alokasi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _allocAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _allocNote,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saveAllocation,
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReleaseSheet(int goalId, double maxAmount) async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lepaskan Dana',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final amount = num.tryParse(
                    ctrl.text.replaceAll('.', '').replaceAll(',', '.'),
                  )?.toDouble();
                  if (amount == null ||
                      amount <= 0 ||
                      amount > maxAmount + 1e-6)
                    return;
                  final userId =
                      context.read<AuthNotifier>().user!['id'] as int;
                  await context
                      .read<AppDatabase>()
                      .db
                      .insert('savings_allocations', {
                        'user_id': userId,
                        'goal_id': goalId,
                        'amount': -amount,
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'note': 'Release dana',
                      });
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _load();
                },
                child: const Text('Lepas'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAllocation() async {
    final goalId = _allocGoalId;
    if (goalId == null) return;
    final amount = num.tryParse(
      _allocAmount.text.replaceAll('.', '').replaceAll(',', '.'),
    )?.toDouble();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nominal tidak valid')));
      return;
    }
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    await context.read<AppDatabase>().db.insert('savings_allocations', {
      'user_id': userId,
      'goal_id': goalId,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'note': _allocNote.text,
    });
    _allocAmount.clear();
    _allocNote.clear();
    await _load();
  }

  Future<void> _saveTopup() async {
    final amount = num.tryParse(
      _topupAmount.text.replaceAll('.', '').replaceAll(',', '.'),
    )?.toDouble();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nominal tidak valid')));
      return;
    }
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final now = DateTime.now();
    await context.read<AppDatabase>().db.insert('savings_manual_topups', {
      'user_id': userId,
      'month': DateFormat('yyyy-MM').format(now),
      'date': DateFormat('yyyy-MM-dd').format(now),
      'amount': amount,
      'note': _topupNote.text,
    });
    _topupAmount.clear();
    _topupNote.clear();
    await _load();
  }

  Future<void> _showReleaseDialog(int goalId, double maxAmount) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lepaskan Dana'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = num.tryParse(
                ctrl.text.replaceAll('.', '').replaceAll(',', '.'),
              )?.toDouble();
              if (amount == null || amount <= 0 || amount > maxAmount + 1e-6)
                return;
              final userId = context.read<AuthNotifier>().user!['id'] as int;
              await context
                  .read<AppDatabase>()
                  .db
                  .insert('savings_allocations', {
                    'user_id': userId,
                    'goal_id': goalId,
                    'amount': -amount,
                    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'note': 'Release dana',
                  });
              if (!mounted) return;
              Navigator.pop(context);
              await _load();
            },
            child: const Text('Lepas'),
          ),
        ],
      ),
    );
  }

  // Small key-value text used inside goal cards
  Widget _kvSmall(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
