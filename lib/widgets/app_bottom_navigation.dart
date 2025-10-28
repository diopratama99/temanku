import 'package:flutter/material.dart';

/// Material 3 Bottom Navigation for mobile layout
/// Replaces drawer navigation for better thumb-zone accessibility
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    // Respect device bottom insets (e.g., 3-button navigation bar)
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 70.0;
    const fabSize = 64.0;
    const fabLift = 12.0; // angkat sedikit agar lebih "floating"

    return Semantics(
      label: 'Navigasi utama aplikasi',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom nav bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: navBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.dashboard_rounded,
                      tooltip: 'Dashboard',
                      isSelected: currentIndex == 0,
                      onTap: () => onDestinationSelected(0),
                    ),
                    _NavItem(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Statistik',
                      isSelected: currentIndex == 1,
                      onTap: () => onDestinationSelected(1),
                    ),
                    // Spacer for center FAB
                    const SizedBox(width: 56),
                    _NavItem(
                      icon: Icons.pie_chart_rounded,
                      tooltip: 'Budgeting',
                      isSelected: currentIndex == 3,
                      onTap: () => onDestinationSelected(3),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      tooltip: 'Profil',
                      isSelected: currentIndex == 4,
                      onTap: () => onDestinationSelected(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating center button
          Positioned(
            // Center FAB vertically with other icons inside the nav bar
            // and adapt to any system bottom inset.
            // Formula: center target (bottomInset + navBarHeight/2)
            // minus half of the FAB size to get the distance to the FAB bottom.
            bottom: bottomInset + (navBarHeight / 2) - (fabSize / 2) + fabLift,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: primaryColor,
                shape: const CircleBorder(),
                child: Tooltip(
                  message: 'Tambah Transaksi',
                  child: InkWell(
                    onTap: () => onDestinationSelected(2),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: fabSize,
                      height: fabSize,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom navigation item - icon only for clean minimalist design
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final iconColor = isSelected ? primaryColor : Colors.grey.shade600;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: primaryColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: isSelected ? 28 : 24, color: iconColor),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: isSelected ? 20 : 0,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation rail for tablet/desktop layouts
class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigationRail({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Transaksi'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: Text('Tambah'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.savings_outlined),
          selectedIcon: Icon(Icons.savings),
          label: Text('Target'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profil'),
        ),
      ],
    );
  }
}
