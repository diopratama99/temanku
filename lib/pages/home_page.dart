import 'package:flutter/material.dart';
import '../widgets/main_navigation_scaffold.dart';
import 'dashboard_page_v2.dart';
import 'statistics_page_modern.dart';
import 'add_transaction_simple.dart';
import 'budgets_page_modern.dart';
import 'profile_page_modern.dart';

/// Home page with bottom navigation
/// Routes: Dashboard, Statistics, Add Transaction, Budgets, Profile
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Pages for each navigation destination
  final List<Widget> _pages = const [
    DashboardPageV2(),
    StatisticsPageModern(),
    AddTransactionSimplePage(),
    BudgetsPageModern(),
    ProfilePageModern(),
  ];

  // AppBar titles for each page
  final List<String> _titles = const [
    'Dashboard',
    'Statistik',
    'Tambah Transaksi',
    'Budgeting',
    'Profil',
  ];

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Get appropriate actions for current page
  List<Widget>? _getAppBarActions() {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationScaffold(
      currentIndex: _currentIndex,
      onNavigationChanged: _onNavigationChanged,
      floatingActionButton: null, // Modern pages have their own FAB
      child: Scaffold(
        appBar:
            (_currentIndex == 1 ||
                _currentIndex == 2 ||
                _currentIndex == 3 ||
                _currentIndex == 4)
            ? null
            : AppBar(
                // Modern pages have no AppBar
                title: Text(_titles[_currentIndex]),
                actions: _getAppBarActions(),
              ),
        body: _pages[_currentIndex],
      ),
    );
  }
}
