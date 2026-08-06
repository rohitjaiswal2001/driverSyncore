import 'package:flutter/material.dart';
import 'driver_dashboard_page.dart';
import 'driver_profile_page.dart';
import 'driver_tracking_page.dart';

class DriverMainShell extends StatelessWidget {
  final String username;
  final int initialIndex;

  const DriverMainShell({
    super.key,
    required this.username,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DriverDashboardPage(
      username: username,
      onNavigateToProfile: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverProfilePage(username: username),
          ),
        );
      },
      onNavigateToTracking: (controller) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverTrackingPage(controller: controller),
          ),
        );
      },
    );
  }
}
