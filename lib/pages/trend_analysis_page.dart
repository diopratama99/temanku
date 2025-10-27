import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/trend_analysis.dart';
import '../utils/theme_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendAnalysisPage extends StatefulWidget {
  const TrendAnalysisPage({super.key});

  @override
  State<TrendAnalysisPage> createState() => _TrendAnalysisPageState();
}

class _TrendAnalysisPageState extends State<TrendAnalysisPage> {
  bool _loading = true;
  String _period = 'monthly'; // 'weekly' or 'monthly'

  // Data untuk analisis
  List<Map<String, dynamic>> _transactions = [];
  List<double> _expenseValues = [];
  List<double> _incomeValues = [];
  List<String> _labels = [];

  TrendAnalysis? _expenseTrend;
  CorrelationAnalysis? _correlation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final db = context.read<AppDatabase>();
    final auth = context.read<AuthNotifier>();
    final user = auth.user;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final uid = user['id'] as int;

    // Ambil transaksi 6 bulan terakhir
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 6, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    final transactions = await db.db.rawQuery(
      '''
      SELECT t.*, c.name AS category, c.emoji AS category_emoji
      FROM transactions t
      LEFT JOIN categories c ON c.id=t.category_id
      WHERE t.user_id=? AND t.date BETWEEN ? AND ?
      ORDER BY t.date ASC
    ''',
      [
        uid,
        DateFormat('yyyy-MM-dd').format(start),
        DateFormat('yyyy-MM-dd').format(end),
      ],
    );

    // Kelompokkan berdasarkan periode
    final groupedData = _groupByPeriod(transactions);

    // Ekstrak nilai untuk analisis
    _expenseValues = groupedData.map((g) => g['expense'] as double).toList();
    _incomeValues = groupedData.map((g) => g['income'] as double).toList();
    _labels = groupedData.map((g) => g['label'] as String).toList();

    // Lakukan analisis tren
    _expenseTrend = TrendAnalysisUtils.linearRegression(_expenseValues);
    _correlation = TrendAnalysisUtils.correlation(
      _incomeValues,
      _expenseValues,
    );

    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _groupByPeriod(
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, Map<String, double>> groups = {};

    for (var tx in transactions) {
      final date = DateTime.parse(tx['date'] as String);
      String key;

      if (_period == 'weekly') {
        // Format: Week 1 Jan, Week 2 Jan, etc
        final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
        key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-W$weekOfMonth';
      } else {
        // Format: Jan 2024, Feb 2024, etc
        key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      }

      if (!groups.containsKey(key)) {
        groups[key] = {'income': 0, 'expense': 0};
      }

      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'income') {
        groups[key]!['income'] = groups[key]!['income']! + amount;
      } else {
        groups[key]!['expense'] = groups[key]!['expense']! + amount;
      }
    }

    // Konversi ke list dan urutkan
    final sorted = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted
        .map(
          (e) => {
            'key': e.key,
            'label': _period == 'weekly'
                ? 'W${((DateTime.parse('${e.key.split('-W')[0]}-01').day - 1) ~/ 7) + 1} ${DateFormat('MMM').format(DateTime.parse('${e.key.split('-W')[0]}-01'))}'
                : DateFormat('MMM yyyy').format(DateTime.parse('${e.key}-01')),
            'income': e.value['income']!,
            'expense': e.value['expense']!,
          },
        )
        .toList();
  }

  String _formatMoney(double value) {
    return 'Rp ${NumberFormat.decimalPattern('id').format(value.round())}';
  }

  Widget _buildPeriodSelector() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _period == 'monthly' ? 'Per Bulan' : 'Per Minggu',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodButton(
                    label: 'Bulanan',
                    isSelected: _period == 'monthly',
                    onTap: () {
                      if (_period != 'monthly') {
                        setState(() => _period = 'monthly');
                        _loadData();
                      }
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Mingguan',
                    isSelected: _period == 'weekly',
                    onTap: () {
                      if (_period != 'weekly') {
                        setState(() => _period = 'weekly');
                        _loadData();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analisa Tren Keuangan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 80,
                    color: isDark
                        ? AppTheme.darkTextDisabled
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambah transaksi untuk melihat analisa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildTrendChart(),
                        const SizedBox(height: 16),
                        _buildExpenseTrendInsight(),
                        const SizedBox(height: 16),
                        _buildPredictionCard(),
                        const SizedBox(height: 16),
                        _buildCorrelationCard(),
                        const SizedBox(height: 16),
                        _buildStatisticsCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTrendChart() {
    if (_expenseValues.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lihat pola pengeluaran kamu',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final textStyle = TextStyle(
                          color:
                              touchedSpot.bar.gradient?.colors.first ??
                              touchedSpot.bar.color ??
                              Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        );
                        return LineTooltipItem(
                          'Rp${NumberFormat.decimalPattern('id').format(touchedSpot.y.round())}',
                          textStyle,
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getChartInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _labels.length) {
                          return const Text('');
                        }

                        // Show fewer labels for better readability
                        // Weekly: show every 4th label (once a month)
                        // Monthly: show every 2nd label
                        final skipInterval = _period == 'weekly' ? 4 : 2;
                        if (_labels.length > 4 && index % skipInterval != 0) {
                          return const Text('');
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Transform.rotate(
                            angle: -0.5, // Rotate labels for better spacing
                            child: Text(
                              _labels[index],
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatShortMoney(value),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                minX: 0,
                maxX: (_expenseValues.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(),
                lineBarsData: [
                  // Data aktual dengan gradient
                  LineChartBarData(
                    spots: _expenseValues.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: const Color(0xFFEF4444),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF4444).withOpacity(0.3),
                          const Color(0xFFEF4444).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Garis tren (prediksi) - hanya untuk data yang ada, tidak extend
                  if (_expenseTrend != null)
                    LineChartBarData(
                      spots: _expenseTrend!.predictions
                          .asMap()
                          .entries
                          .where((e) => e.key < _expenseValues.length)
                          .map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          })
                          .toList(),
                      isCurved: false,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dashArray: [8, 4],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend dengan styling lebih baik
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                const Color(0xFFEF4444),
                'Pengeluaran Aktual',
                isDashed: false,
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                const Color(0xFF0EA5E9),
                'Prediksi Tren',
                isDashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {required bool isDashed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: isDashed ? Colors.transparent : color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: isDashed
                ? CustomPaint(painter: DashedLinePainter(color: color))
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTrendInsight() {
    if (_expenseTrend == null) return const SizedBox();

    final changePercent = _expenseTrend!.averageChangePercent;
    final isIncreasing = changePercent > 0;
    final absPercent = changePercent.abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIncreasing
              ? [const Color(0xFFEF4444).withOpacity(0.1), Colors.white]
              : [const Color(0xFF10B981).withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncreasing
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : const Color(0xFF10B981).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isIncreasing
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isIncreasing
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isIncreasing ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gimana Pengeluaran Kamu?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isIncreasing ? '📈' : '📉',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isIncreasing
                            ? 'Pengeluaran kamu terus naik nih!'
                            : 'Bagus! Pengeluaran kamu turun!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isIncreasing
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isIncreasing
                      ? 'Rata-rata naik ${absPercent.toStringAsFixed(1)}% setiap ${_period == 'monthly' ? 'bulan' : 'minggu'}. '
                      : 'Rata-rata turun ${absPercent.toStringAsFixed(1)}% setiap ${_period == 'monthly' ? 'bulan' : 'minggu'}. ',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isIncreasing
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIncreasing
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: isIncreasing
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isIncreasing
                              ? 'Coba cek lagi pengeluaran kamu ya, jangan sampai over budget!'
                              : 'Pertahankan! Kamu udah berhasil kontrol pengeluaran dengan baik.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isIncreasing
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF166534),
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildPredictionCard() {
    if (_expenseTrend == null || _expenseValues.isEmpty)
      return const SizedBox();

    final nextPrediction = _expenseTrend!.predict(
      _expenseValues.length.toDouble(),
    );
    final currentAvg = TrendAnalysisUtils.mean(_expenseValues);
    final change = ((nextPrediction - currentAvg) / currentAvg * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prediksi AI',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Berdasarkan pola pengeluaran kamu',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _period == 'monthly'
                      ? 'Bulan depan kamu akan keluar:'
                      : 'Minggu depan kamu akan keluar:',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatMoney(nextPrediction),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            change > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'dari rata-rata kamu',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard() {
    if (_correlation == null) return const SizedBox();

    final r = _correlation!.correlation;
    final absR = r.abs();

    Color cardColor;
    if (absR >= 0.8) {
      cardColor = const Color(0xFF7C3AED);
    } else if (absR >= 0.6) {
      cardColor = const Color(0xFF8B5CF6);
    } else if (absR >= 0.4) {
      cardColor = const Color(0xFFA78BFA);
    } else {
      cardColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Hubungan Masuk & Keluar Uang',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _correlation!.strength,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cardColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Skor: ${r.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  r > 0.5
                      ? '� Biasanya kalau masuk uang banyak, keluar uang juga ikutan banyak. Coba diatur ya supaya tetap balance!'
                      : r < -0.5
                      ? '� Keren! Pas masuk uang banyak, pengeluaran kamu malah bisa dikontrol. Pertahankan!'
                      : '� Uang masuk dan keluar kamu gak terlalu berhubungan. Ini artinya kamu udah punya pola pengeluaran yang konsisten.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_expenseValues.isEmpty) return const SizedBox();

    final avgExpense = TrendAnalysisUtils.mean(_expenseValues);
    final stdDev = TrendAnalysisUtils.standardDeviation(_expenseValues);
    final maxExpense = _expenseValues.reduce((a, b) => a > b ? a : b);
    final minExpense = _expenseValues.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade700, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Angka',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Data pengeluaran kamu',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildStatRow(
            icon: Icons.functions,
            label: 'Rata-rata per ${_period == 'monthly' ? 'bulan' : 'minggu'}',
            value: _formatMoney(avgExpense),
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 14),
          _buildStatRow(
            icon: Icons.arrow_upward,
            label: 'Paling banyak keluar',
            value: _formatMoney(maxExpense),
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 14),
          _buildStatRow(
            icon: Icons.arrow_downward,
            label: 'Paling sedikit keluar',
            value: _formatMoney(minExpense),
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 14),
          _buildStatRow(
            icon: Icons.timeline,
            label: 'Selisih naik-turun',
            value: _formatMoney(stdDev),
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_expenseValues.isEmpty) return 100;

    final maxActual = _expenseValues.reduce((a, b) => a > b ? a : b);
    final maxPrediction =
        _expenseTrend?.predictions
            .where((p) => p > 0)
            .reduce((a, b) => a > b ? a : b) ??
        maxActual;

    final max = maxActual > maxPrediction ? maxActual : maxPrediction;
    return (max * 1.2).ceilToDouble();
  }

  double _getChartInterval() {
    final maxY = _getMaxY();
    if (maxY < 1000000) return 200000;
    if (maxY < 5000000) return 1000000;
    return 2000000;
  }

  String _formatShortMoney(double value) {
    if (value >= 1000000) {
      return 'Rp${(value / 1000000).toStringAsFixed(0)}jt';
    } else if (value >= 1000) {
      return 'Rp${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp${value.toStringAsFixed(0)}';
  }
}

// Custom painter untuk garis putus-putus
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
