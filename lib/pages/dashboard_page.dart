import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/state_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _start;
  late DateTime _end;
  Map<String, dynamic>? _data;
  bool _loading = false;
  List<Map<String, dynamic>> _balancesMonth = const [];

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
    final ym = DateFormat('yyyy-MM').format(_start);
    final balances = await db.accountBalancesByMonth(uid, ym);
    setState(() {
      _data = data;
      _loading = false;
      _balancesMonth = balances;
    });
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _money(num v) => 'Rp ${NumberFormat.decimalPattern('id').format(v)}';

  @override
  Widget build(BuildContext context) {
    context.watch<AuthNotifier>();

    // Body only - AppBar & FAB handled by HomePage
    return _loading
        ? const LoadingStateWidget(message: 'Memuat data dashboard...')
        : RefreshIndicator(
            onRefresh: _load,
            child: _data == null
                ? EmptyStateWidget(
                    icon: Icons.dashboard_outlined,
                    title: 'Belum Ada Data',
                    description: 'Mulai tambahkan transaksi pertama Anda',
                    actionLabel: 'Tambah Transaksi',
                    onAction: () => Navigator.pushNamed(context, '/add'),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: AppTheme.space24),
                    children: [
                      // Hero Balance Card
                      BalanceHeroCard(
                        balance: _data!['net'] as num,
                        onTap: () => Navigator.pushNamed(context, '/accounts'),
                      ),

                      const SizedBox(height: AppTheme.space8),

                      // Income & Expense Summary
                      IncomeExpenseSummary(
                        income: _data!['income'] as num,
                        expense: _data!['expense'] as num,
                      ),

                      const SizedBox(height: AppTheme.space16),

                      // Goals + Budgets Mini Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GoalsMiniCard(
                                goals: List<Map<String, dynamic>>.from(
                                  _data!['active_goals'] as List,
                                ),
                                money: _money,
                                onManage: () => Navigator.pushNamed(
                                  context,
                                  '/savings',
                                ).then((_) => _load()),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: _BudgetsMiniCard(
                                budgets: List<Map<String, dynamic>>.from(
                                  _data!['budgets'] as List,
                                ),
                                money: _money,
                                onManage: () => Navigator.pushNamed(
                                  context,
                                  '/budgets',
                                ).then((_) => _load()),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.space16),

                      // Account Balances
                      if (_balancesMonth.isNotEmpty)
                        _Section(
                          title: 'Detail Uang',
                          child: _AccountsList(
                            balances: _balancesMonth,
                            money: _money,
                          ),
                        ),

                      if (_balancesMonth.isNotEmpty)
                        const SizedBox(height: AppTheme.space16),

                      // Spending Chart
                      _Section(
                        title: 'Grafik Pengeluaran',
                        child: SizedBox(
                          height: 220,
                          child: _SpendChart(
                            spendByCat: List<Map<String, dynamic>>.from(
                              _data!['spend_by_cat'] as List,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.space16),

                      // Latest Transactions
                      _Section(
                        title: '10 Transaksi Terakhir',
                        action: TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/transactions',
                          ).then((_) => _load()),
                          child: const Text('Lihat semua'),
                        ),
                        child: (_data!['latest'] as List).isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(AppTheme.space24),
                                child: Center(
                                  child: Text(
                                    'Belum ada transaksi',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final r in (_data!['latest'] as List))
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            (r['type'] == 'income'
                                                    ? AppTheme.incomeColor
                                                    : AppTheme.expenseColor)
                                                .withOpacity(0.1),
                                        child: Text(
                                          (r['category_emoji'] as String?)
                                                  ?.characters
                                                  .first ??
                                              '💰',
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      title: Text(
                                        '${r['type'] == 'income' ? '+' : '-'} ${_money(r['amount'] as num)}',
                                        style: TextStyle(
                                          color: r['type'] == 'income'
                                              ? AppTheme.incomeColor
                                              : AppTheme.expenseColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${r['date']} • ${(r['category'] as String?) ?? '-'} • ${(r['account'] as String?) ?? '-'}',
                                      ),
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/transactions',
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
          );
  }
}

class _GoalsMiniCard extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  final String Function(num) money;
  final VoidCallback onManage;
  const _GoalsMiniCard({
    required this.goals,
    required this.money,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goals Aktif',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (goals.isNotEmpty)
              ...goals.take(2).map((g) {
                final allocated = (g['allocated'] as num).toDouble();
                final target = (g['target_amount'] as num).toDouble();
                final ratio = target <= 0
                    ? 0.0
                    : (allocated / target).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['name'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: ratio, minHeight: 8),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          money(target),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              const Text(
                'Belum ada goals aktif.',
                style: TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onManage,
                child: const Text('Kelola'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetsMiniCard extends StatelessWidget {
  final List<Map<String, dynamic>> budgets;
  final String Function(num) money;
  final VoidCallback onManage;
  const _BudgetsMiniCard({
    required this.budgets,
    required this.money,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Bulan Ini',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (budgets.isNotEmpty)
              ...budgets.take(2).map((b) {
                final amount = (b['amount'] as num).toDouble();
                final spent = (b['spent'] as num).toDouble();
                final pct = amount <= 0
                    ? 0.0
                    : (spent / amount).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['category'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: pct, minHeight: 8),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          money(amount),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              const Text('Belum ada.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onManage,
                child: const Text('Kelola'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  final List<Map<String, dynamic>> balances;
  final String Function(num) money;
  const _AccountsList({required this.balances, required this.money});

  IconData _icon(String acc) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final b in balances)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Icon(_icon(b['acc'] as String), color: const Color(0xFF157347)),
                const SizedBox(width: 12),
                Expanded(child: Text(b['label'] as String)),
                Text(
                  money((b['saldo'] as num?) ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SpendChart extends StatelessWidget {
  final List<Map<String, dynamic>> spendByCat;
  const _SpendChart({required this.spendByCat});

  @override
  Widget build(BuildContext context) {
    if (spendByCat.isEmpty) return const Center(child: Text('Tidak ada data'));
    final values = spendByCat
        .map((e) => (e['total'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final labels = spendByCat
        .map((e) => (e['category'] as String?) ?? '-')
        .toList();
    final maxVal = values.fold<double>(0, (p, c) => c > p ? c : p);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          const gridLines = 5;
          const labelWidth = 56.0;
          const double padY =
              10.0; // top/bottom padding to avoid clipping labels
          final nf = NumberFormat.decimalPattern('id');
          String abbr(double v) {
            final n = v.round();
            if (n >= 1000000000) {
              final val = (n / 1000000000).toStringAsFixed(
                (n % 1000000000 == 0) ? 0 : 1,
              );
              return 'Rp ${val}M';
            }
            if (n >= 1000000) {
              final val = (n / 1000000).toStringAsFixed(
                (n % 1000000 == 0) ? 0 : 1,
              );
              return 'Rp ${val}JT';
            }
            if (n >= 1000) {
              final val = (n / 1000).toStringAsFixed((n % 1000 == 0) ? 0 : 1);
              return 'Rp ${val}K';
            }
            return 'Rp ${nf.format(n)}';
          }

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: LayoutBuilder(
                        builder: (context, cns) {
                          final stepPx = (cns.maxHeight - 2 * padY) / gridLines;
                          final stepVal = maxY / gridLines;
                          return Stack(
                            children: [
                              for (int i = 0; i <= gridLines; i++)
                                Positioned(
                                  left: 0,
                                  bottom: padY + i * stepPx - 7,
                                  child: Text(
                                    abbr(i * stepVal),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: padY,
                              ),
                              child: CustomPaint(
                                painter: _GridPainter(lines: gridLines),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              8,
                              padY,
                              8,
                              padY,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (int i = 0; i < values.length; i++)
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: maxY <= 0
                                            ? 0
                                            : (values[i] / maxY) *
                                                  (h - 40 - 2 * padY),
                                        width: 18,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFFB8E1D9),
                                              Color(0xFF157347),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: labelWidth),
                  Expanded(
                    child: Row(
                      children: [
                        for (final lbl in labels)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                lbl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int lines;
  _GridPainter({required this.lines});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x11000000)
      ..strokeWidth = 1;
    final step = size.height / (lines == 0 ? 1 : lines);
    for (int i = 0; i <= lines; i++) {
      final y = size.height - i * step;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
