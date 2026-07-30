import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shows whether a booking is an import (inbound to Koper) or an export
/// (outbound from Koper), from the booking's `direction` field.
///
/// Renders nothing when the source data carries no direction, so it never
/// guesses a value.
class DirectionBadge extends StatelessWidget {
  final String? direction;
  final bool compact;

  const DirectionBadge({super.key, required this.direction, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final normalised = direction?.trim().toLowerCase();
    if (normalised != 'import' && normalised != 'export') {
      return const SizedBox.shrink();
    }

    final isImport = normalised == 'import';
    final color = isImport ? AppColors.accentBlue : AppColors.accentOrange;
    final label = isImport ? 'IMPORT' : 'EXPORT';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImport ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: compact ? 11 : 12,
            color: color,
          ),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 9.5,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
