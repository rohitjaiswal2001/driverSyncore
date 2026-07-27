import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dims [child] and centers a spinner over it while [isLoading] is true.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color spinnerColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.spinnerColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(77),
            child: Center(
              child: CircularProgressIndicator(color: spinnerColor),
            ),
          ),
      ],
    );
  }
}
