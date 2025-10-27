import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/state_widgets.dart';

class BudgetsPageModern extends StatefulWidget {
  const BudgetsPageModern({super.key});

  @override
  State<BudgetsPageModern> createState() => _BudgetsPageModernState();
}

class _BudgetsPageModernState extends State<BudgetsPageModern> {
  late String _month; // YYYY-MM
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _expCats = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateFormat('yyyy-MM').format(now);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppDatabase>();
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final rows = await db.db.rawQuery(
      '''
      SELECT b.id, c.name AS category, c.emoji AS emoji, b.category_id, b.amount,
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
      _loading = false;
    });
  }

  String _money(num v) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(v);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse('$_month-01');
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(date);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Budgeting',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const LoadingStateWidget(message: 'Memuat budgeting...')
          : Column(
              children: [
                // Month Selector Header
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
                        Icons.calendar_month,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Periode Budget',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              monthName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _selectMonth,
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

                // Budget Summary Card
                if (_rows.isNotEmpty) _buildSummaryCard(),

                // Budgets List
                Expanded(
                  child: _rows.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.pie_chart_outline,
                          title: 'Belum Ada Budget',
                          description:
                              'Atur budget pengeluaranmu untuk kontrol keuangan yang lebih baik',
                          actionLabel: 'Tambah Budget',
                          onAction: _showAddDialog,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: AppTheme.space16,
                            right: AppTheme.space16,
                            top: AppTheme.space16,
                            bottom: 80,
                          ),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final r = _rows[i];
                            return _ModernBudgetCard(
                              budget: r,
                              onDelete: () => _deleteBudget(r),
                              onEdit: () => _showEditDialog(r),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _rows.length < 5
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }

  Widget _buildSummaryCard() {
    double totalBudget = 0;
    double totalSpent = 0;

    for (final r in _rows) {
      totalBudget += (r['amount'] as num).toDouble();
      totalSpent += (r['spent'] as num).toDouble();
    }

    final percentage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    final remaining = totalBudget - totalSpent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Budget',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money(totalBudget),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Terpakai',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money(totalSpent),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: percentage > 100 ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 100 ? Colors.red : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% terpakai',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                remaining >= 0
                    ? 'Sisa ${_money(remaining)}'
                    : 'Lebih ${_money(remaining.abs())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: remaining >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth() async {
    final now = DateTime.parse('$_month-01');
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan',
    );
    if (picked != null) {
      setState(() => _month = DateFormat('yyyy-MM').format(picked));
      await _load();
    }
  }

  Future<void> _deleteBudget(Map<String, dynamic> budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tabungan'),
        content: Text('Hapus target tabungan untuk ${budget['category']}?'),
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
        'budgets',
        where: 'id=?',
        whereArgs: [budget['id']],
      );
      if (!mounted) return;
      showSuccessSnackbar(context, 'Tabungan berhasil dihapus');
      await _load();
    }
  }

  Future<void> _showAddDialog() async {
    if (_rows.length >= 5) {
      showErrorSnackbar(context, 'Maksimal 5 budget per bulan');
      return;
    }

    int? selectedCatId;
    final amountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCatId,
                  items: [
                    for (final c in _expCats)
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
                  onChanged: (v) => setDialogState(() => selectedCatId = v),
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Budget',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    helperText: 'Masukkan budget per bulan',
                  ),
                ),
              ],
            ),
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

                if (selectedCatId == null) {
                  showErrorSnackbar(context, 'Pilih kategori terlebih dahulu');
                  return;
                }
                if (amount == null || amount <= 0) {
                  showErrorSnackbar(
                    context,
                    'Jumlah budget harus lebih dari 0',
                  );
                  return;
                }

                try {
                  await context.read<AppDatabase>().db.insert('budgets', {
                    'user_id': userId,
                    'category_id': selectedCatId,
                    'month': _month,
                    'amount': amount,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  showSuccessSnackbar(
                    context,
                    'Target tabungan berhasil ditambahkan',
                  );
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  showErrorSnackbar(
                    context,
                    'Gagal menambah target tabungan: $e',
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> budget) async {
    final amountCtrl = TextEditingController(
      text: (budget['amount'] as num).toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tabungan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              budget['category'] as String,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.space16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Jumlah Target Tabungan',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
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
              final amount = num.tryParse(
                amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
              )?.toDouble();

              if (amount == null || amount <= 0) {
                showErrorSnackbar(
                  context,
                  'Jumlah target tabungan harus lebih dari 0',
                );
                return;
              }

              try {
                await context.read<AppDatabase>().db.update(
                  'budgets',
                  {'amount': amount},
                  where: 'id=?',
                  whereArgs: [budget['id']],
                );
                if (!mounted) return;
                Navigator.pop(context);
                showSuccessSnackbar(
                  context,
                  'Target tabungan berhasil diperbarui',
                );
                await _load();
              } catch (e) {
                if (!mounted) return;
                showErrorSnackbar(
                  context,
                  'Gagal memperbarui target tabungan: $e',
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _ModernBudgetCard extends StatelessWidget {
  final Map<String, dynamic> budget;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ModernBudgetCard({
    required this.budget,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (budget['amount'] as num).toDouble();
    final spent = (budget['spent'] as num).toDouble();
    final percentage = amount > 0 ? (spent / amount * 100) : 0.0;
    final remaining = amount - spent;
    final emoji = budget['emoji'] as String?;

    final isOverBudget = percentage > 100;
    final color = isOverBudget
        ? Colors.red
        : percentage > 80
        ? Colors.orange
        : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: (percentage / 100).clamp(0.0, 1.0),
                            color: color,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji ?? '📊',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppTheme.space16),

              // Budget Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            budget['category'] as String,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: onDelete,
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terpakai',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(spent),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Anggaran',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(amount),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: remaining >= 0
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        remaining >= 0
                            ? 'Sisa ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(remaining)}'
                            : 'Lebih ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(remaining.abs())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: remaining >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Circular Progress Painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
