import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';

class AccountTransfersPage extends StatefulWidget {
  const AccountTransfersPage({super.key});

  @override
  State<AccountTransfersPage> createState() => _AccountTransfersPageState();
}

class _AccountTransfersPageState extends State<AccountTransfersPage> {
  late String _month; // YYYY-MM
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _balances = [];
  bool _loading = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _month = DateFormat('yyyy-MM').format(DateTime.now());
    _load();
  }

  String _money(num v) => 'Rp ${NumberFormat.decimalPattern('id').format(v)}';

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final rows = await context.read<AppDatabase>().db.rawQuery(
      '''
      SELECT id, date, from_account, to_account, amount, note
      FROM account_transfers
      WHERE user_id=? AND substr(date,1,7)=?
      ORDER BY id DESC
      LIMIT 100
    ''',
      [userId, _month],
    );
    final balances = await context.read<AppDatabase>().accountBalancesByMonth(
      userId,
      _month,
    );
    setState(() {
      _rows = rows;
      _balances = balances;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saldo Akun')),
      body: Column(
        children: [
          // Hapus selector Bulan: <YYYY-MM> sesuai permintaan (tetap pakai bulan aktif di belakang layar)
          if (_balances.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 12,
              ),
              child: Card(
                child: Column(
                  children: [
                    for (int i = 0; i < _balances.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              _iconFor(_balances[i]['acc'] as String),
                              color: const Color(0xFF157347),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _balances[i]['label'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _money(
                                      (_balances[i]['saldo'] as num).toDouble(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          ((_balances[i]['saldo'] as num) >= 0)
                                          ? const Color(0xFF157347)
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != _balances.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          // Card aksi: Tambah Mutasi Akun (pindah dari AppBar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showAddDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(.15),
                              const Color(0xFFE8F5E9),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.swap_horiz,
                            color: Color(0xFF157347),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Mutasi Akun',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pindah saldo antar akun',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF157347)),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Color(0xFF157347),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Header card Riwayat Mutasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  'Riwayat Mutasi (${_monthLabel()})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _rows.isEmpty
                      ? 'Belum ada data'
                      : '${_rows.length} transaksi',
                ),
                trailing: Icon(
                  _showHistory ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () => setState(() => _showHistory = !_showHistory),
              ),
            ),
          ),
          // Riwayat mutasi ditampilkan di ListView (Expanded) agar bisa scroll
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    itemCount: _showHistory ? _rows.length : 0,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      return Dismissible(
                        key: ValueKey(r['id']),
                        background: Container(color: Colors.red),
                        onDismissed: (_) async {
                          await context.read<AppDatabase>().db.delete(
                            'account_transfers',
                            where: 'id=?',
                            whereArgs: [r['id']],
                          );
                          _rows.removeAt(i);
                          setState(() {});
                        },
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            leading: Icon(
                              _iconFor(r['from_account'] as String),
                              color: const Color(0xFF157347),
                            ),
                            title: Text(
                              '${r['from_account']} -> ${r['to_account']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${r['date']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _money(r['amount'] as num),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    DateTime date = DateTime.now();
    String from = 'Transfer';
    String to = 'Tunai';
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final feeCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      useSafeArea: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        final baseTheme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Tambah Mutasi Akun',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: from,
                        items: const [
                          DropdownMenuItem(
                            value: 'Transfer',
                            child: Text('Rekening'),
                          ),
                          DropdownMenuItem(
                            value: 'Tunai',
                            child: Text('Tunai'),
                          ),
                          DropdownMenuItem(
                            value: 'E-Wallet',
                            child: Text('E-Wallet'),
                          ),
                        ],
                        onChanged: (v) => from = v ?? 'Transfer',
                        decoration: const InputDecoration(labelText: 'Dari'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: to,
                        items: const [
                          DropdownMenuItem(
                            value: 'Transfer',
                            child: Text('Rekening'),
                          ),
                          DropdownMenuItem(
                            value: 'Tunai',
                            child: Text('Tunai'),
                          ),
                          DropdownMenuItem(
                            value: 'E-Wallet',
                            child: Text('E-Wallet'),
                          ),
                        ],
                        onChanged: (v) => to = v ?? 'Tunai',
                        decoration: const InputDecoration(labelText: 'Ke'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Biaya admin (opsional)',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) date = picked;
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat('yyyy-MM-dd').format(date)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final userId =
                              context.read<AuthNotifier>().user!['id'] as int;
                          final amount = _parseAmount(amountCtrl.text);
                          final fee = _parseAmount(feeCtrl.text) ?? 0.0;
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jumlah tidak valid'),
                              ),
                            );
                            return;
                          }
                          if (from == to) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pilih akun yang berbeda'),
                              ),
                            );
                            return;
                          }
                          await context
                              .read<AppDatabase>()
                              .insertAccountTransferWithFee(
                                userId: userId,
                                dateIso: DateFormat('yyyy-MM-dd').format(date),
                                fromAccount: from,
                                toAccount: to,
                                amount: amount,
                                note: noteCtrl.text,
                                adminFee: fee,
                              );
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mutasi disimpan')),
                          );
                          await _load();
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthLabel() {
    try {
      final dt = DateTime.parse('$_month-01');
      final m = DateFormat('MMMM', 'id').format(dt);
      final y = DateFormat('y').format(dt);
      return '$m - $y';
    } catch (_) {
      return _month;
    }
  }

  double? _parseAmount(String raw) {
    final s = raw
        .replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(s);
  }

  IconData _iconFor(String acc) {
    switch (acc) {
      case 'Transfer':
        return Icons.account_balance;
      case 'Tunai':
        return Icons.payments_outlined;
      case 'E-Wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class _AccountRow extends StatelessWidget {
  final Map<String, dynamic> balance;
  final String Function(num) money;
  final IconData Function(String) iconFor;
  const _AccountRow({
    required this.balance,
    required this.money,
    required this.iconFor,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = (balance['saldo'] as num).toDouble();
    final color = saldo >= 0 ? const Color(0xFF157347) : Colors.red;
    return Row(
      children: [
        Icon(iconFor(balance['acc'] as String), color: const Color(0xFF157347)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                balance['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                money(saldo),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> row;
  final String Function(num) money;
  final IconData Function(String) iconFor;
  final Future<void> Function() onDelete;
  const _HistoryItem({
    required this.row,
    required this.money,
    required this.iconFor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Tanggal', row['date'] as String? ?? '-'),
        const Divider(height: 12),
        _kv('Dari', row['from_account'] as String? ?? '-'),
        const Divider(height: 12),
        _kv('Ke', row['to_account'] as String? ?? '-'),
        const Divider(height: 12),
        _kv('Jumlah', money(row['amount'] as num)),
        const Divider(height: 12),
        _kv(
          'Catatan',
          (row['note'] as String?)?.trim().isEmpty == true
              ? '-'
              : (row['note'] as String? ?? '-'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: onDelete,
            child: const Text('Hapus'),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            k,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(v)),
      ],
    );
  }
}
