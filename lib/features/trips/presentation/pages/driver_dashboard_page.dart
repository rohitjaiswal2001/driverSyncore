import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/driver_greeting_header.dart';
import '../widgets/shift_timer_card.dart';
import '../widgets/dashboard_quick_action_grid.dart';
import '../widgets/upcoming_assignment_card.dart';

class DriverDashboardPage extends StatefulWidget {
  final String username;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToTracking;
  final VoidCallback onNavigateToOrders;

  const DriverDashboardPage({
    super.key,
    required this.username,
    required this.onNavigateToProfile,
    required this.onNavigateToTracking,
    required this.onNavigateToOrders,
  });

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _isShiftActive = true;
  late Duration _shiftDuration;
  Timer? _shiftTimer;

  @override
  void initState() {
    super.initState();
    // Default shift elapsed duration: 6 hours 42 minutes 0 seconds
    _shiftDuration = const Duration(hours: 6, minutes: 42, seconds: 0);
    _startTimer();
  }

  void _startTimer() {
    if (_shiftTimer != null) return;
    _shiftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isShiftActive) {
        setState(() {
          _shiftDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    _shiftTimer?.cancel();
    _shiftTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return "${hours}h ${minutes}m elapsed";
  }

  void _toggleShift() {
    setState(() {
      _isShiftActive = !_isShiftActive;
      if (_isShiftActive) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: widget.onNavigateToProfile,
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: AppColors.driverAccent,
                    radius: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
        title: const Text(
          'SyntraCore',
          style: TextStyle(
            color: Color(0xFF0F2C59),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textDark),
            onPressed: widget.onNavigateToOrders,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textDark),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Driver Greeting Header
            DriverGreetingHeader(
              username: widget.username,
            ),
            const SizedBox(height: 20),

            // 2. Shift Timer Card
            ShiftTimerCard(
              formattedDuration: _formatDuration(_shiftDuration),
              isShiftActive: _isShiftActive,
              onToggleShift: _toggleShift,
            ),
            const SizedBox(height: 24),

            // 3. Active Trip Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE TRIP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMedium,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'BK-2026-10025',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2C59),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active Trip Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom timeline track on the left
                      Column(
                        children: [
                          const SizedBox(height: 3),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0F2C59),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFF0F2C59),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Dashed timeline track connector
                          Column(
                            children: List.generate(5, (_) {
                              return Container(
                                width: 2,
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                color: const Color(0xFFCBD5E1),
                              );
                            }),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Details on the right
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pickup
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PICKUP',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMedium,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'New Delhi Terminal 3',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'In Progress',
                                    style: TextStyle(
                                      color: Color(0xFFD97706),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Destination
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DESTINATION',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMedium,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'JNPT Port, Mumbai',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Map Container with centered Track on Map button
                  Container(
                    height: 140,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2E5B5E), // Teal slate color
                          Color(0xFF88A096), // Sage slate color
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Centered Button
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2C59),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              minimumSize: const Size(0, 0), // Override global minimumSize
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text(
                              'Track on Map',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: widget.onNavigateToTracking,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Quick Actions
            DashboardQuickActionGrid(
              onUploadDocsTap: () {},
              onContactAdminTap: () {},
              onTripStatusTap: widget.onNavigateToOrders,
            ),
            const SizedBox(height: 24),

            // 5. Upcoming Assignments Section
            const Text(
              'UPCOMING ASSIGNMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            UpcomingAssignmentCard(
              title: 'Ahmedabad Express Delivery',
              startTime: '08:00 AM Departure',
              month: 'OCT',
              day: '12',
              onTap: widget.onNavigateToOrders,
            ),
            UpcomingAssignmentCard(
              title: 'Ahmedabad Express Delivery',
              startTime: '08:00 AM Departure',
              month: 'OCT',
              day: '12',
              onTap: widget.onNavigateToOrders,
            ),
          ],
        ),
      ),
    );
  }
}
