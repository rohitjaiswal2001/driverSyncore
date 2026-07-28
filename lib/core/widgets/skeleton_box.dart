import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A shimmering placeholder block used while real content is loading.
///
/// Prefer this over a blocking spinner for first loads: the skeleton keeps the
/// page layout stable so content does not jump when the real data arrives.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Circular skeleton, sized by [diameter].
  const SkeletonBox.circle({super.key, required double diameter})
    : width = diameter,
      height = diameter,
      borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Slide a soft highlight from left to right across the block.
          final slide = (_controller.value * 2) - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(slide - 0.6, 0),
                end: Alignment(slide + 0.6, 0),
                colors: const [
                  AppColors.skeleton,
                  Color(0xFFF5F8FC),
                  AppColors.skeleton,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
