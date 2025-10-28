import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/main_navigation_scaffold.dart';
import 'dashboard_page.dart';
import 'statistics_page.dart';
import 'add_transaction_page.dart';
import 'budgets_page.dart';
import 'profile_page.dart';

/// Home page with bottom navigation
/// Routes: Dashboard, Statistics, Add Transaction, Budgets, Profile
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  // Pages for each navigation destination
  final List<Widget> _pages = const [
    DashboardPage(),
    StatisticsPage(),
    AddTransactionPage(),
    BudgetsPage(),
    ProfilePage(),
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

  Future<bool> _onWillPop() async {
    // If not on dashboard, go back to dashboard
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }

    // If on dashboard, show exit confirmation with double back press
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan sekali lagi untuk keluar'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    // Exit app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: MainNavigationScaffold(
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
      ),
    );
  }
}
