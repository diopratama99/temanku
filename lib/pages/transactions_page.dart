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
        builder: (_) => const AddTransactionPage(showHistoryButton: false),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                payee,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space8,
                                  vertical: AppTheme.space4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppTheme.space4),
                                    Text(
                                      'Hapus',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Jika tidak ada payee, tampilkan hapus di bawah
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space8,
                                vertical: AppTheme.space4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppTheme.space4),
                                  Text(
                                    'Hapus',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF157347),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.existing == null ? 'Transaksi Baru' : 'Edit Transaksi',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Type Selector - Compact
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _type = 'expense';
                          _categoryId = null;
                        });
                        _loadCats();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'expense'
                              ? const Color(0xFFEF4444)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _type == 'expense'
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_down_rounded,
                              color: _type == 'expense'
                                  ? Colors.white
                                  : Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                color: _type == 'expense'
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _type = 'income';
                          _categoryId = null;
                        });
                        _loadCats();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'income'
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _type == 'income'
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: _type == 'income'
                                  ? Colors.white
                                  : Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                color: _type == 'income'
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Input - Compact
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _type == 'expense'
                                ? const Color(0xFFEF4444).withOpacity(0.05)
                                : const Color(0xFF10B981).withOpacity(0.05),
                            _type == 'expense'
                                ? const Color(0xFFFCA5A5).withOpacity(0.05)
                                : const Color(0xFF6EE7B7).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _type == 'expense'
                              ? const Color(0xFFEF4444).withOpacity(0.2)
                              : const Color(0xFF10B981).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumlah ${_type == 'expense' ? 'Pengeluaran' : 'Pemasukan'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _type == 'expense'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Rp ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: _type == 'expense'
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _amount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: _type == 'expense'
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                    height: 1.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category Selection - Compact
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value:
                                          _cats.any(
                                            (e) => e['id'] == _categoryId,
                                          )
                                          ? _categoryId
                                          : null,
                                      isExpanded: true,
                                      hint: const Text(
                                        'Pilih kategori',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      items: [
                                        for (final c in _cats)
                                          DropdownMenuItem(
                                            value: c['id'] as int,
                                            child: Row(
                                              children: [
                                                Text(
                                                  c['emoji'] as String? ?? '📁',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  c['name'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _categoryId = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date & Payment Method Row
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Selection
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _date = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.blue.shade700,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd/MM/yy').format(_date),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Payment Method
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _account == 'Transfer'
                                          ? Icons.account_balance_rounded
                                          : _account == 'Tunai'
                                          ? Icons.payments_rounded
                                          : Icons.phone_android_rounded,
                                      color: Colors.purple.shade700,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _account,
                                        isExpanded: true,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Transfer',
                                            child: Text('Bank'),
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
                                        onChanged: (v) =>
                                            setState(() => _account = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Keterangan
                    TextField(
                      controller: _payee,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Keterangan',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        hintText: 'Contoh: Gaji bulan ini, Belanja bulanan',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.description_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF157347),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),

                    const SizedBox(height: 12),

                    // Catatan
                    TextField(
                      controller: _notes,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        hintText: 'Tambahkan catatan...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.note_alt_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF157347),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Fixed Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.transparent),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _type == 'expense'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          widget.existing == null
                              ? (_type == 'expense'
                                    ? 'Simpan Pengeluaran'
                                    : 'Simpan Pemasukan')
                              : 'Simpan Perubahan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
