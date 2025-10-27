import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Hero component displaying user's current balance
/// Primary focal point of dashboard (C3 fix)
class BalanceHeroCard extends StatelessWidget {
  final num balance;
  final VoidCallback? onTap;

  const BalanceHeroCard({required this.balance, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Semantics(
      label:
          'Saldo tersisa ${money.format(balance)}. Ketuk untuk melihat detail.',
      button: onTap != null,
      child: Card(
        elevation: AppTheme.elevation2,
        margin: const EdgeInsets.all(AppTheme.space16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space32,
              horizontal: AppTheme.space24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        'Sisa Uang',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  money.format(balance),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Text(
                            'Update real-time',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact income/expense summary cards
class IncomeExpenseSummary extends StatelessWidget {
  final num income;
  final num expense;

  const IncomeExpenseSummary({
    required this.income,
    required this.expense,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.arrow_downward_rounded,
              label: 'Pemasukan',
              amount: money.format(income),
              color: AppTheme.incomeColor,
              semanticLabel: 'Pemasukan bulan ini ${money.format(income)}',
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: _SummaryTile(
              icon: Icons.arrow_upward_rounded,
              label: 'Pengeluaran',
              amount: money.format(expense),
              color: AppTheme.expenseColor,
              semanticLabel: 'Pengeluaran bulan ini ${money.format(expense)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;
  final String semanticLabel;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel,
      child: Card(
        elevation: AppTheme.elevation1,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                amount,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
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
