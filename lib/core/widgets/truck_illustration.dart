import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

/// Bottom-of-screen truck artwork used across the auth flow.
class TruckIllustration extends StatelessWidget {
  const TruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Image.asset(
        AppAssets.truck,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}
