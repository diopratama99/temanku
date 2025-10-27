import 'package:flutter/material.dart';
import 'app_bottom_navigation.dart';

/// Main navigation scaffold with responsive layout support
/// Mobile: Bottom navigation bar
/// Tablet/Desktop: Navigation rail
class MainNavigationScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final FloatingActionButton? floatingActionButton;
  final Function(int) onNavigationChanged;

  const MainNavigationScaffold({
    required this.currentIndex,
    required this.child,
    required this.onNavigationChanged,
    this.floatingActionButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoint: < 600dp = mobile
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Mobile layout with bottom navigation
          return Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNavigation(
              currentIndex: currentIndex,
              onDestinationSelected: onNavigationChanged,
            ),
            floatingActionButton: floatingActionButton,
          );
        } else {
          // Tablet/Desktop layout with navigation rail
          return Scaffold(
            body: Row(
              children: [
                AppNavigationRail(
                  currentIndex: currentIndex,
                  onDestinationSelected: onNavigationChanged,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }
      },
    );
  }
}
