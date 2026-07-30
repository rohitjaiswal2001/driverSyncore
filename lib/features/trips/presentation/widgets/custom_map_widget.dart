import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomMapWidget extends StatefulWidget {
  final String fromLocation;
  final String toLocation;
  final double progress; // 0.0 to 1.0
  final bool isTripInProgress;

  const CustomMapWidget({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    this.progress = 0.0,
    this.isTripInProgress = false,
  });

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: const Color(0xFF0F172A), // Slate 900 (Dark premium map)
            child: Stack(
              children: [
                // Custom Paint Map
                Positioned.fill(
                  child: CustomPaint(
                    painter: MapPainter(
                      progress: widget.progress,
                      pulseValue: _pulseController.value,
                      isTripInProgress: widget.isTripInProgress,
                    ),
                  ),
                ),
                // Map Controls Overlay (styled for high fidelity)
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      _buildMapButton(Icons.add),
                      const SizedBox(height: 8),
                      _buildMapButton(Icons.remove),
                      const SizedBox(height: 8),
                      _buildMapButton(
                        Icons.my_location,
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ),
                ),
                // Compass Overlay
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withAlpha(204),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(51)),
                    ),
                    child: Transform.rotate(
                      angle: -math.pi / 6,
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Route Info Overlay (bottom-left)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withAlpha(230),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(26)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.isTripInProgress
                                ? AppColors.driverAccent
                                : AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isTripInProgress
                              ? 'Navigating to ${widget.toLocation}'
                              : 'Route: ${widget.fromLocation} ➔ ${widget.toLocation}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapButton(IconData icon, {Color color = Colors.white}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(230),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final bool isTripInProgress;

  MapPainter({
    required this.progress,
    required this.pulseValue,
    required this.isTripInProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // 1. Draw Map Grid Background
    paint.color = const Color(0xFF1E293B).withAlpha(77);
    paint.strokeWidth = 0.5;
    const double gridSpacing = 24.0;

    // Vertical grid lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal grid lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 2. Define the route path (S-curve path from bottom-left/middle to top-right)
    final startPoint = Offset(size.width * 0.15, size.height * 0.8);
    final controlPoint1 = Offset(size.width * 0.35, size.height * 0.9);
    final controlPoint2 = Offset(size.width * 0.3, size.height * 0.4);
    final midPoint1 = Offset(size.width * 0.5, size.height * 0.45);
    final controlPoint3 = Offset(size.width * 0.7, size.height * 0.5);
    final controlPoint4 = Offset(size.width * 0.65, size.height * 0.15);
    final endPoint = Offset(size.width * 0.85, size.height * 0.2);

    final Path routePath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        midPoint1.dx,
        midPoint1.dy,
      )
      ..cubicTo(
        controlPoint3.dx,
        controlPoint3.dy,
        controlPoint4.dx,
        controlPoint4.dy,
        endPoint.dx,
        endPoint.dy,
      );

    // 3. Draw entire route path (Inactive background route)
    paint.color = Colors.white.withAlpha(26);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 6.0;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, paint);

    // 4. Calculate active path up to current progress
    final pathMetrics = routePath.computeMetrics();
    final Path activePath = Path();
    Offset currentPosition = startPoint;
    double currentTangentAngle = 0.0;

    for (final metric in pathMetrics) {
      final double extractLength = metric.length * progress;
      activePath.addPath(metric.extractPath(0, extractLength), Offset.zero);
      if (progress > 0.0) {
        final tangent = metric.getTangentForOffset(extractLength);
        if (tangent != null) {
          currentPosition = tangent.position;
          currentTangentAngle = -tangent.vector.direction;
        }
      }
    }

    // Draw glowing under-lay for active path
    if (progress > 0.0) {
      paint.color = const Color(0xFF38BDF8).withAlpha(77); // Cyan neon glow
      paint.strokeWidth = 10.0;
      canvas.drawPath(activePath, paint);

      // Draw primary active line
      paint.color = const Color(0xFF38BDF8); // Cyan neon line
      paint.strokeWidth = 4.0;
      canvas.drawPath(activePath, paint);
    }

    // 5. Draw Pickup Marker (Start Point)
    _drawMarker(
      canvas: canvas,
      position: startPoint,
      color: const Color(0xFF10B981), // Green
      label: 'PICKUP',
      glow: 1.0,
    );

    // 6. Draw Drop Marker (End Point)
    _drawMarker(
      canvas: canvas,
      position: endPoint,
      color: const Color(0xFF3B82F6), // Blue
      label: 'DROP',
      glow: 0.6,
    );

    // 7. Draw Current User Vehicle Position (Pulsing Dot or Navigation Triangle)
    if (progress > 0.0 && progress < 1.0) {
      // Draw radar pulse rings
      paint.style = PaintingStyle.fill;
      paint.color = const Color(
        0xFF38BDF8,
      ).withAlpha((40 * (1.0 - pulseValue)).toInt());
      canvas.drawCircle(currentPosition, 12 + (20 * pulseValue), paint);
      canvas.drawCircle(currentPosition, 6 + (10 * pulseValue), paint);

      // Draw outer circle
      paint.color = Colors.white;
      canvas.drawCircle(currentPosition, 8.0, paint);

      // Draw inner blue circle
      paint.color = AppColors.primary;
      canvas.drawCircle(currentPosition, 6.0, paint);

      // Draw navigation triangle (arrow direction)
      paint.color = Colors.white;
      final Path trianglePath = Path();

      // Points relative to currentPosition
      const double sizeMultiplier = 4.0;
      final double angle =
          currentTangentAngle + (math.pi / 2); // pointing forward

      final Offset p1 =
          currentPosition +
          Offset(
            math.sin(angle) * sizeMultiplier * 1.5,
            math.cos(angle) * sizeMultiplier * 1.5,
          );
      final Offset p2 =
          currentPosition +
          Offset(
            math.sin(angle + (5 * math.pi / 6)) * sizeMultiplier,
            math.cos(angle + (5 * math.pi / 6)) * sizeMultiplier,
          );
      final Offset p3 =
          currentPosition +
          Offset(
            math.sin(angle - (5 * math.pi / 6)) * sizeMultiplier,
            math.cos(angle - (5 * math.pi / 6)) * sizeMultiplier,
          );

      trianglePath.moveTo(p1.dx, p1.dy);
      trianglePath.lineTo(p2.dx, p2.dy);
      trianglePath.lineTo(p3.dx, p3.dy);
      trianglePath.close();
      canvas.drawPath(trianglePath, paint);
    }
  }

  void _drawMarker({
    required Canvas canvas,
    required Offset position,
    required Color color,
    required String label,
    required double glow,
  }) {
    final Paint paint = Paint()..isAntiAlias = true;

    // Glow ring
    paint.style = PaintingStyle.fill;
    paint.color = color.withAlpha((30 * glow).toInt());
    canvas.drawCircle(position, 12.0, paint);

    // Outer border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    paint.color = Colors.white;
    canvas.drawCircle(position, 6.0, paint);

    // Inner filled dot
    paint.style = PaintingStyle.fill;
    paint.color = color;
    canvas.drawCircle(position, 4.0, paint);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isTripInProgress != isTripInProgress;
  }
}
