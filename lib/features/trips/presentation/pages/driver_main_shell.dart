import 'package:flutter/material.dart';
import 'driver_dashboard_page.dart';
import 'my_trips_page.dart';
import 'driver_tracking_page.dart';
import 'driver_profile_page.dart';

class DriverMainShell extends StatefulWidget {
  final String username;
  final int initialIndex;

  const DriverMainShell({
    super.key,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  State<DriverMainShell> createState() => _DriverMainShellState();
}

class _DriverMainShellState extends State<DriverMainShell> {
  late final ValueNotifier<int> _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = ValueNotifier<int>(widget.initialIndex);
    _pages = [
      DriverDashboardPage(
        username: widget.username,
        onNavigateToProfile: () => _currentIndex.value = 3,
        onNavigateToTracking: () => _currentIndex.value = 2,
        onNavigateToOrders: () => _currentIndex.value = 1,
      ),
      MyTripsPage(
        userRole: 'driver',
        username: widget.username,
        onProfileTap: () => _currentIndex.value = 3,
      ),
      const DriverTrackingPage(),
      DriverProfilePage(username: widget.username),
    ];
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentIndex,
      builder: (context, currentIndexVal, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: IndexedStack(index: currentIndexVal, children: _pages),
          bottomNavigationBar: _DriverBottomNavBar(
            currentIndex: currentIndexVal,
            onTap: (i) => _currentIndex.value = i,
          ),
        );
      },
    );
  }
}

class _DriverBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DriverBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dark navy theme matching Figma driver screens
    const Color navBgColor = Color(0xFF0F2C59);

    return Container(
      decoration: BoxDecoration(
        color: navBgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', navBgColor),
              _buildNavItem(1, Icons.assignment_outlined, Icons.assignment, 'Orders', navBgColor),
              _buildNavItem(2, Icons.map_outlined, Icons.map, 'Tracking', navBgColor),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile', navBgColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
    Color navBgColor,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                isSelected ? solidIcon : outlineIcon,
                color: isSelected ? navBgColor : Colors.white.withValues(alpha: 0.65),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
