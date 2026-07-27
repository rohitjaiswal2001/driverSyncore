import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';

enum UserRole {
  driver;

  String get title {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
    }
  }

  String get description {
    switch (this) {
      case UserRole.driver:
        return 'Manage trips\n& update\nstatus';
    }
  }

  String get iconAsset {
    switch (this) {
      case UserRole.driver:
        return AppAssets.driverIcon;
    }
  }

  Color get activeColor {
    switch (this) {
      case UserRole.driver:
        return AppColors.driverAccent;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case UserRole.driver:
        return AppColors.driverBg;
    }
  }
}
