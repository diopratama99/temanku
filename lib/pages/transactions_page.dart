import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/state_widgets.dart';
import 'add_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  final bool hideAddButton;

  const TransactionsPage({super.key, this.hideAddButton = false});

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const LoadingStateWidget(message: 'Memuat transaksi...')
          : Column(
              children: [
                // Modern Date Filter Card
                Container(
                  margin: const EdgeInsets.all(AppTheme.space16),
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Periode',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM', 'id_ID').format(_start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_end)}',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showDateRangePicker(),
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: const Text('Ubah'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                            vertical: AppTheme.space8,
                          ),
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
                          onAction: () => _navigateToAdd(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final r = _rows[i];
                            return _ModernTransactionCard(
                              transaction: r,
                              onTap: () => _navigateToEdit(r),
                              onDelete: () => _deleteTransaction(r),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: widget.hideAddButton
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToAdd,
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
              backgroundColor: AppTheme.primaryColor,
            ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
      await _load();
    }
  }

  Future<void> _navigateToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddTransactionPage(showHistoryButton: false),
      ),
    );
    await _load();
  }

  Future<void> _navigateToEdit(Map<String, dynamic> transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTransactionPageModern(existing: transaction),
      ),
    );
    await _load();
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
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
        'transactions',
        where: 'id=?',
        whereArgs: [transaction['id']],
      );
      if (!mounted) return;
      showSuccessSnackbar(context, 'Transaksi berhasil dihapus');
      await _load();
    }
  }
}

class _ModernTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ModernTransactionCard({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'] as String;
    final amount = transaction['amount'] as num;
    final category = transaction['category'] as String;
    final emoji = transaction['category_emoji'] as String?;
    final payee = transaction['source_or_payee'] as String?;
    final date = DateFormat('yyyy-MM-dd').parse(transaction['date'] as String);
    final account = transaction['account'] as String?;

    final isIncome = type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Dismissible(
      key: Key('transaction_${transaction['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false; // We handle deletion manually
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      emoji ?? (isIncome ? '💰' : '🛒'),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.space16),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy', 'id_ID').format(date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          if (account != null) ...[
                            const SizedBox(width: AppTheme.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                account,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (payee != null && payee.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          payee,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Edit Transaction Page
class EditTransactionPageModern extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const EditTransactionPageModern({super.key, this.existing});

  @override
  State<EditTransactionPageModern> createState() =>
      _EditTransactionPageModernState();
}

class _EditTransactionPageModernState extends State<EditTransactionPageModern> {
  late DateTime _date;
  late String _type;
  int? _categoryId;
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _notes = TextEditingController();
  String _account = 'Transfer';
  List<Map<String, dynamic>> _cats = [];

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
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _payee.dispose();
    _notes.dispose();
    super.dispose();
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

    if (amount == null || amount <= 0) {
      showErrorSnackbar(context, 'Jumlah harus lebih dari 0');
      return;
    }

    if (_categoryId == null) {
      showErrorSnackbar(context, 'Pilih kategori terlebih dahulu');
      return;
    }

    try {
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
      showSuccessSnackbar(
        context,
        widget.existing == null
            ? 'Transaksi berhasil ditambahkan'
            : 'Transaksi berhasil diperbarui',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Gagal menyimpan transaksi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Tambah Transaksi' : 'Edit Transaksi',
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Simpan',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
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
              // Type Selector
              _buildSection(
                'Jenis Transaksi',
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Pengeluaran'),
                      icon: Icon(Icons.south_east),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Pemasukan'),
                      icon: Icon(Icons.north_east),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (sel) {
                    setState(() => _type = sel.first);
                    _loadCats();
                  },
                  style: ButtonStyle(visualDensity: VisualDensity.comfortable),
                ),
              ),

              const SizedBox(height: 20),

              // Amount Field (Big & Bold)
              _buildSection(
                'Jumlah',
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Category
              _buildSection(
                'Kategori',
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  items: [
                    for (final c in _cats)
                      DropdownMenuItem(
                        value: c['id'] as int,
                        child: Row(
                          children: [
                            Text(
                              (c['emoji'] as String?) ?? '📁',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Text(c['name'] as String),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Date
              _buildSection(
                'Tanggal',
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                            'id_ID',
                          ).format(_date),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Account Type
              _buildSection(
                'Metode Pembayaran',
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Transfer',
                      label: Text('Bank'),
                      icon: Icon(Icons.account_balance, size: 18),
                    ),
                    ButtonSegment(
                      value: 'Tunai',
                      label: Text('Tunai'),
                      icon: Icon(Icons.payments_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: 'E-Wallet',
                      label: Text('E-Wallet'),
                      icon: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                      ),
                    ),
                  ],
                  selected: {_account},
                  onSelectionChanged: (s) => setState(() => _account = s.first),
                ),
              ),

              const SizedBox(height: 20),

              // Payee
              _buildSection(
                'Dari/Untuk',
                TextField(
                  controller: _payee,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Toko Swalayan, Kantor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Notes
              _buildSection(
                'Catatan (Opsional)',
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.space32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.existing == null
                        ? 'Tambah Transaksi'
                        : 'Simpan Perubahan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        child,
      ],
    );
  }
}
