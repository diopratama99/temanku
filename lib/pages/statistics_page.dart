import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/descriptive_statistics.dart';
import '../widgets/category_donut_chart.dart';

/// Modern Statistics Page - Financial Analytics & Insights
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late DateTime _start;
  late DateTime _end;
  Map<String, dynamic>? _data;
  bool _loading = false;
  String _selectedPeriod = 'month'; // month, quarter, year

  late TabController _tabController;
  DescriptiveStatistics? _expenseStats;
  DescriptiveStatistics? _incomeStats;
  Map<String, double> _expenseCategoryData = {};
  Map<String, double> _incomeCategoryData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPeriod();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    // Load transaction amounts for descriptive statistics
    final transactions = await _loadTransactionAmounts(db, uid);

    // Load category data for donut chart
    final categoryData = await _loadCategoryData(db, uid);

    // Load transaction counts
    final transactionCounts = await _loadTransactionCounts(db, uid);
    data['transaction_counts'] = transactionCounts;

    setState(() {
      _data = data;
      _expenseStats = DescriptiveStatistics(transactions['expense'] ?? []);
      _incomeStats = DescriptiveStatistics(transactions['income'] ?? []);
      _expenseCategoryData = categoryData['expense'] ?? {};
      _incomeCategoryData = categoryData['income'] ?? {};
      _loading = false;
    });
  }

  Future<Map<String, int>> _loadTransactionCounts(
    AppDatabase db,
    int userId,
  ) async {
    final result = await db.db.rawQuery(
      '''
      SELECT type, COUNT(*) as count
      FROM transactions
      WHERE user_id = ? AND date BETWEEN ? AND ?
      GROUP BY type
      ''',
      [userId, _iso(_start), _iso(_end)],
    );

    int incomeCount = 0;
    int expenseCount = 0;

    for (final row in result) {
      final type = row['type'] as String?;
      final count = (row['count'] as int?) ?? 0;

      if (type == 'income') {
        incomeCount = count;
      } else if (type == 'expense') {
        expenseCount = count;
      }
    }

    return {'income': incomeCount, 'expense': expenseCount};
  }

  Future<Map<String, List<double>>> _loadTransactionAmounts(
    AppDatabase db,
    int userId,
  ) async {
    final result = await db.db.rawQuery(
      '''
      SELECT type, amount
      FROM transactions
      WHERE user_id = ? AND date BETWEEN ? AND ?
      ORDER BY amount
      ''',
      [userId, _iso(_start), _iso(_end)],
    );

    final expenseAmounts = <double>[];
    final incomeAmounts = <double>[];

    for (final row in result) {
      final type = row['type'] as String?;
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;

      if (type == 'expense') {
        expenseAmounts.add(amount);
      } else if (type == 'income') {
        incomeAmounts.add(amount);
      }
    }

    return {'expense': expenseAmounts, 'income': incomeAmounts};
  }

  Future<Map<String, Map<String, double>>> _loadCategoryData(
    AppDatabase db,
    int userId,
  ) async {
    final result = await db.db.rawQuery(
      '''
      SELECT t.type, c.name as category, c.emoji, SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND t.date BETWEEN ? AND ?
      GROUP BY t.type, c.name, c.emoji
      ORDER BY total DESC
      ''',
      [userId, _iso(_start), _iso(_end)],
    );

    final expenseData = <String, double>{};
    final incomeData = <String, double>{};

    for (final row in result) {
      final type = row['type'] as String?;
      final category = (row['category'] as String?) ?? 'Lainnya';
      final emoji = (row['emoji'] as String?) ?? '📝';
      final total = (row['total'] as num?)?.toDouble() ?? 0;

      // Combine emoji + category name
      final displayName = '$emoji $category';

      if (type == 'expense') {
        expenseData[displayName] = total;
      } else if (type == 'income') {
        incomeData[displayName] = total;
      }
    }

    return {'expense': expenseData, 'income': incomeData};
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Detail'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Summary Statistics (existing)
                _buildSummaryTab(),

                // Tab 2: Descriptive Statistics (new)
                _buildDescriptiveTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return RefreshIndicator(
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
                  incomeCount:
                      (_data!['transaction_counts']
                          as Map<String, int>)['income'] ??
                      0,
                  expenseCount:
                      (_data!['transaction_counts']
                          as Map<String, int>)['expense'] ??
                      0,
                ),
              ],
            ),
    );
  }

  Widget _buildDescriptiveTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: _expenseStats == null && _incomeStats == null
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

                // Info Card
                _buildInfoCard(),

                const SizedBox(height: AppTheme.space16),

                // Expense Statistics
                if (_expenseStats != null &&
                    _expenseStats!.data.isNotEmpty) ...[
                  _buildStatisticsCard(
                    title: '📉 Statistika Pengeluaran',
                    stats: _expenseStats!,
                    color: AppTheme.expenseColor,
                    categoryData: _expenseCategoryData,
                  ),
                  const SizedBox(height: AppTheme.space16),
                ],

                // Income Statistics
                if (_incomeStats != null && _incomeStats!.data.isNotEmpty) ...[
                  _buildStatisticsCard(
                    title: '📈 Statistika Pemasukan',
                    stats: _incomeStats!,
                    color: AppTheme.incomeColor,
                    categoryData: _incomeCategoryData,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lihat detail keuanganmu: rata-rata pengeluaran, pola keuangan, dan transaksi yang tidak biasa',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard({
    required String title,
    required DescriptiveStatistics stats,
    required Color color,
    required Map<String, double> categoryData,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total ${stats.data.length} transaksi',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            // Donut Chart - Distribusi per Kategori
            if (categoryData.isNotEmpty) ...[
              _buildSection(
                icon: Icons.pie_chart,
                title: 'Distribusi per Kategori',
                color: Colors.purple,
                children: [
                  CategoryDonutChart(
                    categoryData: categoryData,
                    title: title,
                    primaryColor: color,
                  ),
                ],
              ),
              const Divider(height: 32),
            ],

            // Rata-rata & Info Penting
            _buildSection(
              icon: Icons.account_balance_wallet,
              title: 'Info Penting',
              color: Colors.blue,
              children: [
                _buildHighlightRow(
                  'Rata-rata per Transaksi',
                  _money(stats.mean),
                  color,
                ),
                const SizedBox(height: 8),
                _buildHighlightRow(
                  'Paling Sering',
                  _money(stats.median),
                  color.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                _buildHighlightRow(
                  'Terkecil - Terbesar',
                  '${_money(stats.min)} - ${_money(stats.max)}',
                  AppTheme.textSecondary,
                ),
              ],
            ),

            const Divider(height: 32),

            // Pola Keuangan dengan insight otomatis
            _buildSection(
              icon: Icons.insights,
              title: 'Pola Keuanganmu',
              color: Colors.orange,
              children: [_buildSpendingPattern(stats)],
            ),

            const Divider(height: 32),

            // Deteksi Transaksi Tidak Biasa
            _buildSection(
              icon: Icons.warning_amber_outlined,
              title: 'Transaksi Tidak Biasa',
              color: Colors.red,
              children: [_buildAnomalyDetection(stats)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightRow(String label, String value, Color color) {
    return Container(
      width: double.infinity, // Full width
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSpendingPattern(DescriptiveStatistics stats) {
    String pattern = '';
    String icon = '';
    Color patternColor = AppTheme.textSecondary;
    String explanation = '';

    // Analisis berdasarkan skewness
    if (stats.skewness.abs() < 0.5) {
      pattern = 'Stabil';
      icon = '✅';
      patternColor = Colors.green;
      explanation = 'Pengeluaranmu merata, tidak ada yang ekstrem';
    } else if (stats.skewness < -0.5) {
      pattern = 'Boros';
      icon = '⚠️';
      patternColor = Colors.orange;
      explanation = 'Sering keluar uang banyak, coba lebih hemat';
    } else {
      pattern = 'Normal';
      icon = '�';
      patternColor = Colors.blue;
      explanation = 'Biasanya kecil-kecil, kadang ada yang besar';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: patternColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: patternColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: patternColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyDetection(DescriptiveStatistics stats) {
    final normalCount = stats.zScores.where((z) => z.abs() < 2).length;
    final abnormalCount = stats.data.length - normalCount;
    final abnormalPercentage = stats.data.length > 0
        ? (abnormalCount / stats.data.length * 100)
        : 0.0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (abnormalPercentage < 5) {
      statusColor = Colors.green;
      statusText = 'Aman';
      statusIcon = Icons.check_circle;
    } else if (abnormalPercentage < 15) {
      statusColor = Colors.blue;
      statusText = 'Cukup Baik';
      statusIcon = Icons.info;
    } else if (abnormalPercentage < 25) {
      statusColor = Colors.orange;
      statusText = 'Perlu Hati-hati';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.red;
      statusText = 'Waspada';
      statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$abnormalCount dari ${stats.data.length} transaksi tidak wajar',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (stats.outliers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Transaksi Aneh: ${stats.outliers.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: stats.outliers.take(5).map((outlier) {
                return Chip(
                  label: Text(
                    _money(outlier),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            if (stats.outliers.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... dan ${stats.outliers.length - 5} lainnya',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ],
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
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
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
  final int incomeCount;
  final int expenseCount;

  const _TransactionCountCard({
    required this.incomeCount,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
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
