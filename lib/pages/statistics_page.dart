import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';

/// Modern Statistics Page - Financial Analytics & Insights
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _start;
  late DateTime _end;
  Map<String, dynamic>? _data;
  bool _loading = false;
  String _selectedPeriod = 'month'; // month, quarter, year

  @override
  void initState() {
    super.initState();
    _initPeriod();
    _load();
  }

  void _initPeriod() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'month':
        _start = DateTime(now.year, now.month, 1);
        _end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        _start = DateTime(now.year, startMonth, 1);
        _end = DateTime(now.year, startMonth + 3, 0);
        break;
      case 'year':
        _start = DateTime(now.year, 1, 1);
        _end = DateTime(now.year, 12, 31);
        break;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppDatabase>();
    final auth = context.read<AuthNotifier>();
    final user = auth.user;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final uid = user['id'] as int;
    final data = await db.dashboardData(uid, _iso(_start), _iso(_end));
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _money(num v) => 'Rp ${NumberFormat.decimalPattern('id').format(v)}';

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _initPeriod();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Statistik',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _data == null
                  ? const Center(child: Text('Belum ada data'))
                  : ListView(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      children: [
                        // Period Selector
                        _PeriodSelector(
                          selected: _selectedPeriod,
                          onChanged: _changePeriod,
                        ),

                        const SizedBox(height: AppTheme.space16),

                        // Summary Cards
                        _SummaryCards(
                          income: _data!['income'] as num,
                          expense: _data!['expense'] as num,
                          net: _data!['net'] as num,
                          money: _money,
                        ),

                        const SizedBox(height: AppTheme.space16),

                        // Spending by Category Chart
                        _SpendingByCategoryCard(
                          data: List<Map<String, dynamic>>.from(
                            _data!['spend_by_cat'] as List,
                          ),
                          money: _money,
                        ),

                        const SizedBox(height: AppTheme.space16),

                        // Top Categories
                        _TopCategoriesCard(
                          data: List<Map<String, dynamic>>.from(
                            _data!['spend_by_cat'] as List,
                          ),
                          money: _money,
                        ),

                        const SizedBox(height: AppTheme.space16),

                        // Transaction Count
                        _TransactionCountCard(
                          transactions: List<Map<String, dynamic>>.from(
                            _data!['latest'] as List,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

// Period Selector Widget
class _PeriodSelector extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Row(
          children: [
            Expanded(
              child: _PeriodButton(
                label: 'Bulan',
                value: 'month',
                selected: selected == 'month',
                onTap: () => onChanged('month'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodButton(
                label: 'Kuartal',
                value: 'quarter',
                selected: selected == 'quarter',
                onTap: () => onChanged('quarter'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodButton(
                label: 'Tahun',
                value: 'year',
                selected: selected == 'year',
                onTap: () => onChanged('year'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Summary Cards
class _SummaryCards extends StatelessWidget {
  final num income;
  final num expense;
  final num net;
  final String Function(num) money;

  const _SummaryCards({
    required this.income,
    required this.expense,
    required this.net,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatCard(
          label: 'Total Pemasukan',
          amount: income,
          money: money,
          color: AppTheme.incomeColor,
          icon: Icons.arrow_upward,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Total Pengeluaran',
          amount: expense,
          money: money,
          color: AppTheme.expenseColor,
          icon: Icons.arrow_downward,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Sisa Saldo',
          amount: net,
          money: money,
          color: net >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
          icon: Icons.account_balance_wallet,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final num amount;
  final String Function(num) money;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.money,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(amount),
                    style: TextStyle(
                      fontSize: 20,
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
    );
  }
}

// Spending by Category Chart
class _SpendingByCategoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String Function(num) money;

  const _SpendingByCategoryCard({required this.data, required this.money});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengeluaran per Kategori',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.space16),
            // Pie-like horizontal bars
            for (final item in data.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryBar(
                  category: item['category'] as String? ?? '-',
                  emoji: item['emoji'] as String? ?? '💰',
                  amount: (item['total'] as num?)?.toDouble() ?? 0,
                  total: total,
                  money: money,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final String emoji;
  final double amount;
  final double total;
  final String Function(num) money;

  const _CategoryBar({
    required this.category,
    required this.emoji,
    required this.amount,
    required this.total,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              money(amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Top Categories Card
class _TopCategoriesCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String Function(num) money;

  const _TopCategoriesCard({required this.data, required this.money});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Teratas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.space12),
            for (int i = 0; i < data.take(3).length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      data[i]['emoji'] as String? ?? '💰',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data[i]['category'] as String? ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      money((data[i]['total'] as num?) ?? 0),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.expenseColor,
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
}

// Transaction Count Card
class _TransactionCountCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const _TransactionCountCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final incomeCount = transactions.where((t) => t['type'] == 'income').length;
    final expenseCount = transactions
        .where((t) => t['type'] == 'expense')
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah Transaksi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.space16),
            Row(
              children: [
                Expanded(
                  child: _CountItem(
                    label: 'Pemasukan',
                    count: incomeCount,
                    color: AppTheme.incomeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CountItem(
                    label: 'Pengeluaran',
                    count: expenseCount,
                    color: AppTheme.expenseColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'transaksi',
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
