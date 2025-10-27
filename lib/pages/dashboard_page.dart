import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/state_widgets.dart';

/// Modern minimalist dashboard - redesigned for better UX
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = false;
  late DateTime _start;
  late DateTime _end;

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

  Widget _buildFeatureMenu() {
    final features = [
      _FeatureItem(
        icon: Icons.receipt_long_outlined,
        label: 'Transaksi',
        color: AppTheme.primaryColor,
        onTap: () => Navigator.pushNamed(context, '/transactions'),
      ),
      _FeatureItem(
        icon: Icons.category_outlined,
        label: 'Kategori',
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.pushNamed(context, '/categories'),
      ),
      _FeatureItem(
        icon: Icons.pie_chart_outline,
        label: 'Budgeting',
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.pushNamed(context, '/budgets'),
      ),
      _FeatureItem(
        icon: Icons.savings_outlined,
        label: 'Tabungan',
        color: const Color(0xFF10B981),
        onTap: () => Navigator.pushNamed(context, '/savings'),
      ),
      _FeatureItem(
        icon: Icons.import_export,
        label: 'Import/Export',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.pushNamed(context, '/import'),
      ),
      _FeatureItem(
        icon: Icons.person_outline,
        label: 'Profil',
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.pushNamed(context, '/profile'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              const Text(
                'Menu Cepat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: AppTheme.space12,
            crossAxisSpacing: AppTheme.space12,
            childAspectRatio: 1.0,
            children: features
                .map((item) => _FeatureMenuCard(item: item))
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthNotifier>();

    return _loading
        ? const LoadingStateWidget(message: 'Memuat dashboard...')
        : RefreshIndicator(
            onRefresh: _load,
            child: _data == null
                ? EmptyStateWidget(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Belum Ada Data',
                    description: 'Mulai tambahkan transaksi pertama Anda',
                    actionLabel: 'Tambah Transaksi',
                    onAction: () => Navigator.pushNamed(context, '/add'),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: AppTheme.space24),
                    children: [
                      // Modern Balance Card
                      ModernBalanceCard(
                        balance: _data!['net'] as num,
                        income: _data!['income'] as num,
                        expense: _data!['expense'] as num,
                        onTap: () => Navigator.pushNamed(context, '/accounts'),
                      ),

                      // Feature Menu Grid
                      _buildFeatureMenu(),

                      // Quick Stats (Goals & Budgets)
                      _buildQuickStats(),

                      // Recent Transactions
                      _buildRecentTransactions(),
                    ],
                  ),
          );
  }

  Widget _buildQuickStats() {
    final goals = List<Map<String, dynamic>>.from(
      _data!['active_goals'] as List,
    );
    final budgets = List<Map<String, dynamic>>.from(_data!['budgets'] as List);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              const Text(
                'Ringkasan Keuangan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Goals & Budgets in clean cards
          if (goals.isNotEmpty || budgets.isNotEmpty) ...[
            if (goals.isNotEmpty) _buildGoalsCard(goals),
            const SizedBox(height: AppTheme.space12),
            if (budgets.isNotEmpty) _buildBudgetsCard(budgets),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.track_changes,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    const Text(
                      'Belum Ada Target',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Mulai atur anggaran dan tabungan Anda',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(List<Map<String, dynamic>> goals) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/savings'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.incomeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.savings_outlined,
                          color: AppTheme.incomeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      const Text(
                        'Tabungan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              ...goals.take(2).map((g) {
                final allocated = (g['allocated'] as num? ?? 0).toDouble();
                final target = (g['target_amount'] as num? ?? 0).toDouble();
                final progress = target > 0
                    ? (allocated / target).clamp(0.0, 1.0)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              g['name'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.incomeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppTheme.incomeColor.withOpacity(
                            0.1,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.incomeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_money(allocated)} / ${_money(target)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetsCard(List<Map<String, dynamic>> budgets) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/budgets'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.expenseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          color: AppTheme.expenseColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      const Text(
                        'Budgeting Bulan Ini',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              ...budgets.take(2).map((b) {
                final spent = (b['spent'] as num? ?? 0).toDouble();
                final limit = (b['limit_amount'] as num? ?? 0).toDouble();
                final progress = limit > 0
                    ? (spent / limit).clamp(0.0, 1.0)
                    : 0.0;
                final isOverBudget = progress > 0.9;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b['category'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isOverBudget
                                  ? AppTheme.expenseColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppTheme.expenseColor.withOpacity(
                            0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation(
                            isOverBudget
                                ? AppTheme.expenseColor
                                : AppTheme.neutralColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_money(spent)} / ${_money(limit)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recent = _data!['recent'] as List?;

    if (recent == null || recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terbaru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/transactions'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          ...recent.take(5).map((r) => _buildTransactionItem(r)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final amount = transaction['amount'] as num;
    final category = transaction['category'] as String? ?? 'Lainnya';
    final date = DateFormat(
      'dd MMM',
    ).format(DateFormat('yyyy-MM-dd').parse(transaction['date'] as String));

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/transactions'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'} ${_money(amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isIncome
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Feature Item Data Class
class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// Feature Menu Card Widget
class _FeatureMenuCard extends StatelessWidget {
  final _FeatureItem item;

  const _FeatureMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: item.color.withOpacity(0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
