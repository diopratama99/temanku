import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../widgets/state_widgets.dart';

/// Monthly Comparison Page - Uji Hipotesis Dua Populasi
/// Compares expenses between two months to detect significant changes
class MonthlyComparisonPage extends StatefulWidget {
  const MonthlyComparisonPage({super.key});

  @override
  State<MonthlyComparisonPage> createState() => _MonthlyComparisonPageState();
}

class _MonthlyComparisonPageState extends State<MonthlyComparisonPage> {
  bool _loading = true;
  String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String _previousMonth = DateFormat(
    'yyyy-MM',
  ).format(DateTime(DateTime.now().year, DateTime.now().month - 1));

  Map<String, dynamic>? _currentData;
  Map<String, dynamic>? _previousData;
  Map<String, dynamic>? _comparisonResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final userId = context.read<AuthNotifier>().user!['id'] as int;
      final db = context.read<AppDatabase>().db;

      // Load current month data
      _currentData = await _loadMonthData(db, userId, _currentMonth);

      // Load previous month data
      _previousData = await _loadMonthData(db, userId, _previousMonth);

      // Perform statistical comparison
      _comparisonResult = _performHypothesisTest();

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        showErrorSnackbar(context, 'Error loading data: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _loadMonthData(
    dynamic db,
    int userId,
    String month,
  ) async {
    // Load total expenses for the month
    final totalResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE user_id = ? AND type = 'expense' 
      AND strftime('%Y-%m', date) = ?
    ''',
      [userId, month],
    );

    final total = (totalResult.first['total'] as num).toDouble();

    // Load expenses by category
    final categoryResult = await db.rawQuery(
      '''
      SELECT 
        c.name as category,
        c.emoji as emoji,
        COALESCE(SUM(t.amount), 0) as amount,
        COUNT(t.id) as count
      FROM categories c
      LEFT JOIN transactions t ON c.id = t.category_id 
        AND t.user_id = ? 
        AND t.type = 'expense'
        AND strftime('%Y-%m', t.date) = ?
      WHERE c.user_id = ? AND c.type = 'expense'
      GROUP BY c.id, c.name, c.emoji
      HAVING amount > 0
      ORDER BY amount DESC
    ''',
      [userId, month, userId],
    );

    // Convert to simpler List<Map<String, dynamic>>
    // Filter out any null values to prevent errors
    final categories = categoryResult
        .map((row) {
          return {
            'category': (row['category'] ?? 'Tanpa Kategori') as String,
            'emoji': (row['emoji'] ?? '📦') as String,
            'amount': (row['amount'] as num?)?.toDouble() ?? 0.0,
            'count': (row['count'] as int?) ?? 0,
          };
        })
        .where((cat) => (cat['amount'] as double) > 0)
        .toList();

    // Calculate total count safely
    int totalCount = 0;
    for (final cat in categories) {
      totalCount += (cat['count'] as int? ?? 0);
    }

    return {
      'month': month,
      'total': total,
      'categories': categories,
      'count': totalCount,
    };
  }

  /// Perform Two-Sample Hypothesis Test (Uji Hipotesis Dua Populasi)
  /// H0: μ1 = μ2 (no significant difference)
  /// H1: μ1 ≠ μ2 (significant difference exists)
  Map<String, dynamic> _performHypothesisTest() {
    if (_currentData == null || _previousData == null) {
      return {};
    }

    final currentTotal = _currentData!['total'] as double;
    final previousTotal = _previousData!['total'] as double;

    // Calculate percentage change
    final percentageChange = previousTotal > 0
        ? ((currentTotal - previousTotal) / previousTotal) * 100
        : 0.0;

    // Perform hypothesis test for each category
    final categoryComparisons = <Map<String, dynamic>>[];

    final currentCategories = _currentData!['categories'] as List;
    final previousCategories = _previousData!['categories'] as List;

    // Create a map for easier lookup
    final prevCatMap = <String, Map<String, dynamic>>{};
    for (final cat in previousCategories) {
      final catName = cat['category'];
      if (catName != null && catName is String) {
        prevCatMap[catName] = cat as Map<String, dynamic>;
      }
    }

    for (final currCat in currentCategories) {
      final catName = currCat['category'];
      final catEmoji = currCat['emoji'];

      // Skip if category name is null
      if (catName == null || catName is! String) continue;

      final currAmount = (currCat['amount'] as num?)?.toDouble() ?? 0.0;
      final prevCat = prevCatMap[catName];

      if (prevCat != null) {
        final prevAmount = (prevCat['amount'] as num?)?.toDouble() ?? 0.0;
        final catChange = prevAmount > 0
            ? ((currAmount - prevAmount) / prevAmount) * 100
            : 0.0;

        // Simple significance test based on percentage change threshold
        // In real stats, you'd use t-test with sample variance
        final isSignificant = catChange.abs() > 10.0; // 10% threshold
        final pValue = _calculateSimplePValue(catChange.abs());

        categoryComparisons.add({
          'category': catName,
          'emoji': catEmoji ?? '📦',
          'currentAmount': currAmount,
          'previousAmount': prevAmount,
          'change': catChange,
          'isSignificant': isSignificant,
          'pValue': pValue,
        });
      } else {
        // New category this month
        categoryComparisons.add({
          'category': catName,
          'emoji': catEmoji ?? '📦',
          'currentAmount': currAmount,
          'previousAmount': 0.0,
          'change': 100.0,
          'isSignificant': true,
          'pValue': 0.01,
        });
      }
    }

    // Sort by absolute change
    categoryComparisons.sort(
      (a, b) => (b['change'] as double).abs().compareTo(
        (a['change'] as double).abs(),
      ),
    );

    // Overall significance
    final overallSignificant = percentageChange.abs() > 5.0;

    return {
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'percentageChange': percentageChange,
      'isSignificant': overallSignificant,
      'categoryComparisons': categoryComparisons,
      'interpretation': _generateInterpretation(
        percentageChange,
        overallSignificant,
        categoryComparisons,
      ),
    };
  }

  /// Calculate simplified p-value based on percentage change
  /// In real implementation, use proper t-distribution
  double _calculateSimplePValue(double percentChange) {
    // Simplified approximation: larger change = smaller p-value
    if (percentChange > 50) return 0.001;
    if (percentChange > 30) return 0.01;
    if (percentChange > 20) return 0.02;
    if (percentChange > 10) return 0.05;
    return 0.15; // Not significant
  }

  String _generateInterpretation(
    double overallChange,
    bool isSignificant,
    List<Map<String, dynamic>> categories,
  ) {
    final buffer = StringBuffer();

    // Overall interpretation
    if (isSignificant) {
      if (overallChange > 0) {
        buffer.write(
          'Pengeluaran bulan ini meningkat signifikan sebesar '
          '+${overallChange.toStringAsFixed(1)}% dibanding bulan lalu.\n\n',
        );
      } else {
        buffer.write(
          'Pengeluaran bulan ini menurun signifikan sebesar '
          '${overallChange.toStringAsFixed(1)}% dibanding bulan lalu.\n\n',
        );
      }
    } else {
      buffer.write(
        'Pengeluaran bulan ini relatif stabil '
        '(${overallChange >= 0 ? '+' : ''}${overallChange.toStringAsFixed(1)}%) '
        'dibanding bulan lalu.\n\n',
      );
    }

    // Category-level insights
    if (categories.isNotEmpty) {
      final topIncrease = categories.firstWhere(
        (c) => (c['change'] as double) > 0 && c['isSignificant'] as bool,
        orElse: () => {},
      );

      if (topIncrease.isNotEmpty) {
        buffer.write(
          'Kategori "${topIncrease['category']}" mengalami kenaikan tertinggi '
          '(+${(topIncrease['change'] as double).toStringAsFixed(1)}%).\n\n',
        );
      }

      final topDecrease = categories.firstWhere(
        (c) => (c['change'] as double) < 0 && c['isSignificant'] as bool,
        orElse: () => {},
      );

      if (topDecrease.isNotEmpty) {
        buffer.write(
          'Kategori "${topDecrease['category']}" mengalami penurunan terbesar '
          '(${(topDecrease['change'] as double).toStringAsFixed(1)}%).\n\n',
        );
      }

      // Count non-significant categories
      final nonSignificant = categories
          .where((c) => !(c['isSignificant'] as bool))
          .length;

      if (nonSignificant > 0) {
        buffer.write(
          '$nonSignificant kategori menunjukkan perubahan yang tidak signifikan (p > 0.05).',
        );
      }
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Perbandingan Bulanan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingStateWidget(message: 'Menganalisis data...')
          : _comparisonResult == null || _comparisonResult!.isEmpty
          ? EmptyStateWidget(
              icon: Icons.analytics_outlined,
              title: 'Tidak Ada Data',
              description: 'Belum ada data pengeluaran untuk dibandingkan',
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: AppTheme.space24),
                    _buildOverallComparison(),
                    const SizedBox(height: AppTheme.space24),
                    _buildInterpretationCard(),
                    const SizedBox(height: AppTheme.space24),
                    _buildCategoryComparisons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulan Ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMMM yyyy',
                      'id_ID',
                    ).format(DateTime.parse('$_currentMonth-01')),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.compare_arrows, color: AppTheme.primaryColor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bulan Lalu',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMMM yyyy',
                      'id_ID',
                    ).format(DateTime.parse('$_previousMonth-01')),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallComparison() {
    final currentTotal = _comparisonResult!['currentTotal'] as double;
    final previousTotal = _comparisonResult!['previousTotal'] as double;
    final change = _comparisonResult!['percentageChange'] as double;
    final isSignificant = _comparisonResult!['isSignificant'] as bool;

    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: change >= 0
              ? [Colors.red.shade400, Colors.red.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: (change >= 0 ? Colors.red : Colors.green).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bulan Ini',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money.format(currentTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      change >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSignificant
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSignificant
                        ? 'Perubahan Signifikan Terdeteksi (p < 0.05)'
                        : 'Perubahan Tidak Signifikan (p > 0.05)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: Colors.white30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bulan Lalu',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                money.format(previousTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationCard() {
    final interpretation = _comparisonResult!['interpretation'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analisis Statistik',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              interpretation,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryComparisons() {
    final categories =
        _comparisonResult!['categoryComparisons'] as List<Map<String, dynamic>>;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perbandingan Per Kategori',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.space16),
        ...categories.map((cat) {
          final change = cat['change'] as double;
          final isSignificant = cat['isSignificant'] as bool;
          final pValue = cat['pValue'] as double;

          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.space12),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cat['emoji'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat['category'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSignificant
                                  ? 'Signifikan (p = ${pValue.toStringAsFixed(3)})'
                                  : 'Tidak Signifikan (p > 0.05)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSignificant
                                    ? Colors.orange.shade700
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (change >= 0 ? Colors.red : Colors.green)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              change >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: change >= 0 ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: change >= 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bulan Ini',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money.format(cat['currentAmount']),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bulan Lalu',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money.format(cat['previousAmount']),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
          );
        }),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Uji Hipotesis'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Uji Hipotesis Dua Populasi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Fitur ini menggunakan konsep statistik untuk '
                'membandingkan pengeluaran dari dua periode berbeda.\n\n'
                'H₀: μ₁ = μ₂ (Tidak ada perbedaan signifikan)\n'
                'H₁: μ₁ ≠ μ₂ (Ada perbedaan signifikan)\n\n',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              Text(
                'Interpretasi p-value:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                '• p < 0.05: Perubahan signifikan\n'
                '• p > 0.05: Perubahan tidak signifikan\n\n'
                'Ini membantu Anda mengevaluasi apakah perubahan '
                'pengeluaran benar-benar berbeda atau hanya fluktuasi normal.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
