import 'package:flutter/material.dart';
import '../widgets/app_bottom_navigation.dart';
import 'statistics_page.dart';
import 'add_transaction_page.dart';
import 'budgets_page.dart';
import 'profile_page.dart';

/// Dashboard page dengan quick actions dan overview
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: const Center(
        child: Text('Dashboard Content'),
      ),
    );
  }
}
