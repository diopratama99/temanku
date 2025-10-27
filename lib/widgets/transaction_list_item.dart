import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/theme_utils.dart';

/// Accessible transaction list item with semantic labels
/// Fixes M2: Better readability and interaction patterns
class TransactionListTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TransactionListTile({
    required this.transaction,
    required this.onTap,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction['type'] == 'income';
    final amount = transaction['amount'] as num;
    final category = transaction['category'] as String? ?? 'Tanpa Kategori';
    final date = transaction['date'] as String;
    final emoji = transaction['category_emoji'] as String? ?? '💰';
    final account = transaction['account'] as String? ?? '-';
    final notes = transaction['notes'] as String? ?? '';

    final money = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final formattedDate = DateFormat(
      'dd MMM yyyy',
      'id',
    ).format(DateFormat('yyyy-MM-dd').parse(date));

    final semanticLabel =
        '${isIncome ? 'Pemasukan' : 'Pengeluaran'} '
        '${money.format(amount)}, kategori $category, '
        'tanggal $formattedDate, metode pembayaran $account';

    Widget listItem = Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          (isIncome
                                  ? (ThemeUtils.isDarkMode(context)
                                        ? AppTheme.darkIncomeColor
                                        : AppTheme.incomeColor)
                                  : (ThemeUtils.isDarkMode(context)
                                        ? AppTheme.darkExpenseColor
                                        : AppTheme.expenseColor))
                              .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),

                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name
                        Text(
                          category,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.space4),

                        // Date & account
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: AppTheme.space4),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Icon(
                              _getAccountIcon(account),
                              size: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: AppTheme.space4),
                            Expanded(
                              child: Text(
                                account,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Notes (if available)
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            notes,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'} ${money.format(amount)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isIncome
                              ? (ThemeUtils.isDarkMode(context)
                                    ? AppTheme.darkIncomeColor
                                    : AppTheme.incomeColor)
                              : (ThemeUtils.isDarkMode(context)
                                    ? AppTheme.darkExpenseColor
                                    : AppTheme.expenseColor),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isIncome
                                      ? (ThemeUtils.isDarkMode(context)
                                            ? AppTheme.darkIncomeColor
                                            : AppTheme.incomeColor)
                                      : (ThemeUtils.isDarkMode(context)
                                            ? AppTheme.darkExpenseColor
                                            : AppTheme.expenseColor))
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Text(
                          isIncome ? 'Masuk' : 'Keluar',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isIncome
                                ? (ThemeUtils.isDarkMode(context)
                                      ? AppTheme.darkIncomeColor
                                      : AppTheme.incomeColor)
                                : (ThemeUtils.isDarkMode(context)
                                      ? AppTheme.darkExpenseColor
                                      : AppTheme.expenseColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Delete button di pojok kanan bawah
              if (onDelete != null) ...[
                const SizedBox(height: AppTheme.space8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus Transaksi?'),
                          content: Text(
                            'Apakah Anda yakin ingin menghapus transaksi '
                            '$category sebesar ${money.format(amount)}? '
                            'Tindakan ini tidak dapat dibatalkan.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.expenseColor,
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        onDelete!();
                      }
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: ThemeUtils.isDarkMode(context)
                                ? AppTheme.darkExpenseColor
                                : const Color(0xFFC62828),
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Text(
                            'Hapus',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ThemeUtils.isDarkMode(context)
                                  ? AppTheme.darkExpenseColor
                                  : const Color(0xFFC62828),
                              fontWeight: FontWeight.w600,
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
      ),
    );

    // Wrap with Dismissible if delete is enabled
    if (onDelete != null) {
      listItem = Dismissible(
        key: ValueKey(transaction['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.expenseColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppTheme.space24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete, color: Colors.white, size: 28),
              SizedBox(height: AppTheme.space4),
              Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Transaksi?'),
                  content: Text(
                    'Apakah Anda yakin ingin menghapus transaksi '
                    '$category sebesar ${money.format(amount)}? '
                    'Tindakan ini tidak dapat dibatalkan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.expenseColor,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) => onDelete!(),
        child: listItem,
      );
    }

    return Semantics(label: semanticLabel, button: true, child: listItem);
  }

  IconData _getAccountIcon(String account) {
    switch (account) {
      case 'Transfer':
        return Icons.account_balance;
      case 'Tunai':
        return Icons.payments;
      case 'E-Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}

/// Compact transaction card for mobile grid view
class TransactionCompactCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  const TransactionCompactCard({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction['type'] == 'income';
    final amount = transaction['amount'] as num;
    final category = transaction['category'] as String? ?? '-';
    final emoji = transaction['category_emoji'] as String? ?? '💰';

    final money = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: AppTheme.space8),
              Text(
                category,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                '${isIncome ? '+' : '-'}${money.format(amount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isIncome
                      ? (ThemeUtils.isDarkMode(context)
                            ? AppTheme.darkIncomeColor
                            : AppTheme.incomeColor)
                      : (ThemeUtils.isDarkMode(context)
                            ? AppTheme.darkExpenseColor
                            : AppTheme.expenseColor),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
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
