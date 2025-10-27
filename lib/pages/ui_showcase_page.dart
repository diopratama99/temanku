import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_hero_card.dart';
import '../widgets/state_widgets.dart';
import '../widgets/form_fields.dart';
import '../widgets/transaction_list_item.dart';

/// UI Showcase page to demonstrate all new components
/// Use route: /showcase
class UIShowcasePage extends StatefulWidget {
  const UIShowcasePage({super.key});

  @override
  State<UIShowcasePage> createState() => _UIShowcasePageState();
}

class _UIShowcasePageState extends State<UIShowcasePage> {
  final _currencyCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategory;

  final _mockCategories = [
    {'id': 1, 'name': 'Makanan', 'emoji': '🍔'},
    {'id': 2, 'name': 'Transport', 'emoji': '🚗'},
    {'id': 3, 'name': 'Belanja', 'emoji': '🛒'},
  ];

  final _mockTransactions = [
    {
      'id': 1,
      'type': 'expense',
      'amount': 50000,
      'category': 'Makanan',
      'category_emoji': '🍔',
      'date': '2025-10-24',
      'account': 'E-Wallet',
      'notes': 'Makan siang di kantor',
    },
    {
      'id': 2,
      'type': 'income',
      'amount': 5000000,
      'category': 'Gaji',
      'category_emoji': '💰',
      'date': '2025-10-23',
      'account': 'Transfer',
      'notes': 'Gaji bulanan',
    },
  ];

  @override
  void dispose() {
    _currencyCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Components Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space16),
        children: [
          _buildSection(
            'Design Tokens',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColorRow('Primary', AppTheme.primaryColor),
                _buildColorRow('Income', AppTheme.incomeColor),
                _buildColorRow('Expense', AppTheme.expenseColor),
                _buildColorRow('Text Primary', AppTheme.textPrimary),
                _buildColorRow('Text Secondary', AppTheme.textSecondary),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Hero Balance Card',
            BalanceHeroCard(
              balance: 15750000,
              onTap: () {
                showSuccessSnackbar(context, 'Balance card tapped!');
              },
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Income/Expense Summary',
            const IncomeExpenseSummary(income: 5000000, expense: 2500000),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Empty State',
            SizedBox(
              height: 300,
              child: EmptyStateWidget(
                icon: Icons.category_outlined,
                title: 'Belum Ada Kategori',
                description:
                    'Buat kategori pertama Anda untuk mulai melacak transaksi',
                actionLabel: 'Tambah Kategori',
                onAction: () {
                  showSuccessSnackbar(context, 'Add category clicked!');
                },
              ),
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Loading State',
            const SizedBox(
              height: 150,
              child: LoadingStateWidget(message: 'Memuat data transaksi...'),
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Error State',
            SizedBox(
              height: 300,
              child: ErrorStateWidget(
                title: 'Gagal Memuat Data',
                message:
                    'Terjadi kesalahan saat memuat data. Periksa koneksi internet Anda.',
                onRetry: () {
                  showSuccessSnackbar(context, 'Retry clicked!');
                },
              ),
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Form Fields',
            Column(
              children: [
                CurrencyFormField(
                  controller: _currencyCtrl,
                  label: 'Jumlah',
                  helperText: 'Masukkan jumlah dalam Rupiah',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                PasswordFormField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  showStrengthIndicator: true,
                ),
                const SizedBox(height: AppTheme.space16),
                DatePickerField(
                  selectedDate: _selectedDate,
                  onDateChanged: (date) {
                    setState(() => _selectedDate = date);
                  },
                  label: 'Tanggal',
                ),
                const SizedBox(height: AppTheme.space16),
                CategoryDropdownField(
                  value: _selectedCategory,
                  items: _mockCategories,
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  label: 'Kategori',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Transaction List Items',
            Column(
              children: [
                for (final transaction in _mockTransactions)
                  TransactionListTile(
                    transaction: transaction,
                    onTap: () {
                      showSuccessSnackbar(
                        context,
                        'Transaction ${transaction['id']} tapped',
                      );
                    },
                    onDelete: () {
                      showSuccessSnackbar(
                        context,
                        'Transaction ${transaction['id']} deleted',
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Buttons',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    showSuccessSnackbar(context, 'Filled button clicked!');
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Filled Button'),
                ),
                const SizedBox(height: AppTheme.space12),
                OutlinedButton.icon(
                  onPressed: () {
                    showErrorSnackbar(context, 'Outlined button clicked!');
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Outlined Button'),
                ),
                const SizedBox(height: AppTheme.space12),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info),
                  label: const Text('Text Button'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space24),

          _buildSection(
            'Typography Scale',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Headline Large',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  'Headline Medium',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Title Large',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Title Medium',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Body Large',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Body Medium',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Label Large',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.space16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
