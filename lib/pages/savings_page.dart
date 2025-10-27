import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/state_widgets.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Map<String, dynamic>> _goals = [];
  bool _loading = false;
  double _totalTarget = 0;
  double _totalSaved = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

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

    double totalTarget = 0;
    double totalSaved = 0;
    for (final row in rows) {
      if (row['archived_at'] == null) {
        totalTarget += (row['target_amount'] as num).toDouble();
        totalSaved += (row['allocated'] as num).toDouble();
      }
    }

    setState(() {
      _goals = rows;
      _totalTarget = totalTarget;
      _totalSaved = totalSaved;
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
    final activeGoals = _goals.where((e) => e['archived_at'] == null).toList();
    final archivedGoals = _goals
        .where((e) => e['archived_at'] != null)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tabungan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const LoadingStateWidget(message: 'Memuat tabungan...')
          : Column(
              children: [
                // Summary Card
                if (activeGoals.isNotEmpty) _buildSummaryCard(),

                // Goals List
                Expanded(
                  child: activeGoals.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.savings_outlined,
                          title: 'Belum Ada Target Tabungan',
                          description:
                              'Buat target tabungan untuk mencapai tujuan finansial Anda',
                          actionLabel: 'Buat Target',
                          onAction: _showAddGoalDialog,
                        )
                      : ListView(
                          padding: const EdgeInsets.only(
                            left: AppTheme.space16,
                            right: AppTheme.space16,
                            bottom: 80,
                          ),
                          children: [
                            // Active Goals
                            for (final goal in activeGoals)
                              _ModernGoalCard(
                                goal: goal,
                                onTap: () => _showGoalDetails(goal),
                                onAddAllocation: () =>
                                    _showAddAllocationDialog(goal),
                                onEdit: () => _showEditGoalDialog(goal),
                                onArchive: () => _archiveGoal(goal),
                                onDelete: () => _deleteGoal(goal),
                              ),

                            // Archived Goals Section
                            if (archivedGoals.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space8,
                                ),
                                child: Text(
                                  'Arsip',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final goal in archivedGoals)
                                _ModernGoalCard(
                                  goal: goal,
                                  isArchived: true,
                                  onTap: () => _showGoalDetails(goal),
                                  onUnarchive: () => _unarchiveGoal(goal),
                                  onDelete: () => _deleteGoal(goal),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('Buat Target'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final percentage = _totalTarget > 0
        ? (_totalSaved / _totalTarget * 100)
        : 0.0;
    final remaining = _totalTarget - _totalSaved;

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(Icons.savings, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Tabungan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(_totalSaved),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% dari target',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Sisa ${_money(remaining)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGoalDialog() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Target Tabungan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Target',
                  hintText: 'Contoh: Liburan ke Bali',
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
                  labelText: 'Target Jumlah',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  helperText: 'Jumlah yang ingin dicapai',
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
              if (nameCtrl.text.trim().isEmpty) {
                showErrorSnackbar(context, 'Nama target harus diisi');
                return;
              }

              final target = num.tryParse(
                amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
              )?.toDouble();

              if (target == null || target <= 0) {
                showErrorSnackbar(context, 'Target jumlah harus lebih dari 0');
                return;
              }

              final userId = context.read<AuthNotifier>().user!['id'] as int;
              await context.read<AppDatabase>().db.insert('savings_goals', {
                'user_id': userId,
                'name': nameCtrl.text.trim(),
                'target_amount': target,
              });

              if (!mounted) return;
              Navigator.pop(context);
              showSuccessSnackbar(context, 'Target berhasil dibuat');
              await _load();
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

  Future<void> _showGoalDetails(Map<String, dynamic> goal) async {
    // Show allocations history
    final goalId = goal['id'] as int;
    final db = context.read<AppDatabase>().db;
    final allocations = await db.query(
      'savings_allocations',
      where: 'goal_id=?',
      whereArgs: [goalId],
      orderBy: 'date DESC',
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['name'] as String,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Riwayat Alokasi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Allocations List
            Expanded(
              child: allocations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allocations.length,
                      itemBuilder: (context, i) {
                        final alloc = allocations[i];
                        final amount = (alloc['amount'] as num).toDouble();
                        final isPositive = amount >= 0;
                        final date = DateTime.parse(alloc['date'] as String);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      (isPositive ? Colors.green : Colors.red)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isPositive ? Icons.add : Icons.remove,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _money(amount.abs()),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                        'id_ID',
                                      ).format(date),
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAllocationDialog(Map<String, dynamic> goal) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah ke ${goal['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
              decoration: InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor.withOpacity(0.6),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
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
                showErrorSnackbar(context, 'Jumlah harus lebih dari 0');
                return;
              }

              final userId = context.read<AuthNotifier>().user!['id'] as int;
              await context
                  .read<AppDatabase>()
                  .db
                  .insert('savings_allocations', {
                    'user_id': userId,
                    'goal_id': goal['id'],
                    'amount': amount,
                    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'note': noteCtrl.text.trim(),
                  });

              if (!mounted) return;
              Navigator.pop(context);
              showSuccessSnackbar(context, 'Alokasi berhasil ditambahkan');
              await _load();
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

  Future<void> _showEditGoalDialog(Map<String, dynamic> goal) async {
    final nameCtrl = TextEditingController(text: goal['name'] as String);
    final amountCtrl = TextEditingController(
      text: (goal['target_amount'] as num).toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Target',
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
                labelText: 'Target Jumlah',
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
              final target = num.tryParse(
                amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
              )?.toDouble();

              if (nameCtrl.text.trim().isEmpty ||
                  target == null ||
                  target <= 0) {
                showErrorSnackbar(context, 'Data tidak valid');
                return;
              }

              await context.read<AppDatabase>().db.update(
                'savings_goals',
                {'name': nameCtrl.text.trim(), 'target_amount': target},
                where: 'id=?',
                whereArgs: [goal['id']],
              );

              if (!mounted) return;
              Navigator.pop(context);
              showSuccessSnackbar(context, 'Target berhasil diperbarui');
              await _load();
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

  Future<void> _archiveGoal(Map<String, dynamic> goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arsipkan Target'),
        content: Text('Arsipkan "${goal['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AppDatabase>().db.update(
        'savings_goals',
        {'archived_at': DateTime.now().toIso8601String()},
        where: 'id=?',
        whereArgs: [goal['id']],
      );
      if (!mounted) return;
      showSuccessSnackbar(context, 'Target berhasil diarsipkan');
      await _load();
    }
  }

  Future<void> _unarchiveGoal(Map<String, dynamic> goal) async {
    await context.read<AppDatabase>().db.update(
      'savings_goals',
      {'archived_at': null},
      where: 'id=?',
      whereArgs: [goal['id']],
    );
    if (!mounted) return;
    showSuccessSnackbar(context, 'Target dikembalikan dari arsip');
    await _load();
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Target'),
        content: Text(
          'Hapus "${goal['name']}"? Semua riwayat alokasi akan ikut terhapus.',
        ),
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
        'savings_goals',
        where: 'id=?',
        whereArgs: [goal['id']],
      );
      await context.read<AppDatabase>().db.delete(
        'savings_allocations',
        where: 'goal_id=?',
        whereArgs: [goal['id']],
      );
      if (!mounted) return;
      showSuccessSnackbar(context, 'Target berhasil dihapus');
      await _load();
    }
  }
}

class _ModernGoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final bool isArchived;
  final VoidCallback onTap;
  final VoidCallback? onAddAllocation;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback onDelete;

  const _ModernGoalCard({
    required this.goal,
    this.isArchived = false,
    required this.onTap,
    this.onAddAllocation,
    this.onEdit,
    this.onArchive,
    this.onUnarchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final target = (goal['target_amount'] as num).toDouble();
    final saved = (goal['allocated'] as num).toDouble();
    final percentage = target > 0 ? (saved / target * 100) : 0.0;
    final remaining = target - saved;
    final isCompleted = percentage >= 100;

    final color = isArchived
        ? Colors.grey
        : isCompleted
        ? Colors.green
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['name'] as String,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isArchived
                                ? 'Arsip'
                                : isCompleted
                                ? '✓ Tercapai'
                                : 'Aktif',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isArchived) ...[
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onAddAllocation,
                      color: AppTheme.primaryColor,
                      tooltip: 'Tambah Alokasi',
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'archive') onArchive?.call();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('Arsipkan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: onUnarchive,
                      tooltip: 'Kembalikan',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: Colors.red,
                      tooltip: 'Hapus',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppTheme.space16),

              // Large Circular Progress
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: CustomPaint(
                            painter: _LargeCircularProgressPainter(
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
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(saved),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.space16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: AppTheme.space12),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(target),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Sisa',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(remaining.clamp(0, double.infinity)),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: remaining > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Large Circular Progress Painter for Goal Cards
class _LargeCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _LargeCircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

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
  bool shouldRepaint(_LargeCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
