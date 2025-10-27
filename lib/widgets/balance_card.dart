import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Modern minimalist balance card inspired by Revolut/Monzo
class ModernBalanceCard extends StatelessWidget {
  final num balance;
  final num income;
  final num expense;
  final VoidCallback? onTap;

  const ModernBalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    this.onTap,
    super.key,
  });

  String _formatMoney(num value) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF157347), // Temanku green
            Color(0xFF0d5233), // Darker green
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF157347).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Saldo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),

                // Balance amount
                Text(
                  _formatMoney(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Income & Expense row
                Row(
                  children: [
                    Expanded(
                      child: _MoneyIndicator(
                        label: 'Pemasukan',
                        amount: income,
                        icon: Icons.arrow_downward,
                        isIncome: true,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: _MoneyIndicator(
                        label: 'Pengeluaran',
                        amount: expense,
                        icon: Icons.arrow_upward,
                        isIncome: false,
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

class _MoneyIndicator extends StatelessWidget {
  final String label;
  final num amount;
  final IconData icon;
  final bool isIncome;

  const _MoneyIndicator({
    required this.label,
    required this.amount,
    required this.icon,
    required this.isIncome,
  });

  String _formatMoney(num value) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
