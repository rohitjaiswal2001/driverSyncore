import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// How much weight a button carries on the screen it sits on.
enum AppButtonVariant {
  /// The one thing the screen is asking for: filled with the accent.
  primary,

  /// The alternative to the primary action — outlined, same size, so the two
  /// read as a pair rather than as a button next to a link.
  secondary,

  /// A destructive primary: filled red, for deleting an account or cancelling
  /// a shipment.
  danger,

  /// No fill and no border, for the action that is genuinely optional —
  /// 'Skip', 'Resend', 'Cancel' inside a sheet.
  ghost,
}

/// Regular buttons stand alone at the bottom of a form or a page; compact ones
/// sit in pairs inside a card, where the full height would swamp the content.
enum AppButtonSize { regular, compact }

/// The app's button — one height, one corner radius and one label weight for
/// every action, in place of the [ElevatedButton.styleFrom] block each screen
/// used to write out with its own numbers.
///
/// [variant] says how much weight the action carries and [accent] recolours it
/// without changing its shape, so a green 'Confirm' and a navy 'Continue' stay
/// the same button.
///
/// [isLoading] puts a spinner where the icon goes and keeps the label, so a
/// form neither jumps nor goes quiet while it submits — and it blocks the
/// press, so a slow request cannot be fired twice.
class AppButton extends StatelessWidget {
  final String label;

  /// A null press disables the button, exactly as it does on the Material
  /// buttons this wraps.
  final VoidCallback? onPressed;

  /// Sits before the label. Left off, the label centres on its own.
  final IconData? icon;

  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Spinner in place of the icon, and no press until it clears.
  final bool isLoading;

  /// The colour the button is built from — the fill for [AppButtonVariant
  /// .primary], the text and the border for the rest. Defaults to the brand
  /// colour, or to [AppColors.danger] for [AppButtonVariant.danger].
  final Color? accent;

  /// Stretches to the width it is given. A button at the bottom of a form
  /// wants this; one in a row of two is already sized by its [Expanded].
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.isLoading = false,
    this.accent,
    this.expand = true,
  });

  /// Outlined counterpart to the primary action.
  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.regular,
    this.isLoading = false,
    this.accent,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  /// Filled red, for an action that destroys something.
  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.regular,
    this.isLoading = false,
    this.accent,
    this.expand = true,
  }) : variant = AppButtonVariant.danger;

  /// Text alone, for the action that can be ignored.
  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.regular,
    this.isLoading = false,
    this.accent,
    this.expand = true,
  }) : variant = AppButtonVariant.ghost;

  static const double _regularHeight = 54;
  static const double _compactHeight = 46;
  static const double _radius = 14;

  double get _height =>
      size == AppButtonSize.regular ? _regularHeight : _compactHeight;

  double get _fontSize => size == AppButtonSize.regular ? 15.5 : 13.5;

  double get _iconSize => size == AppButtonSize.regular ? 20 : 17;

  Color get _accent {
    if (accent != null) return accent!;
    return variant == AppButtonVariant.danger
        ? AppColors.danger
        : AppColors.primary;
  }

  bool get _isFilled =>
      variant == AppButtonVariant.primary || variant == AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    // A loading button stays disabled rather than merely ignoring the tap, so
    // it also looks unavailable while the request is in flight.
    final enabled = onPressed != null && !isLoading;
    final press = enabled ? onPressed : null;
    final foreground = _isFilled ? Colors.white : _accent;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    // The padding is the same across the variants; only the fill changes, so
    // a primary and a secondary side by side line their labels up.
    final padding = EdgeInsets.symmetric(
      horizontal: size == AppButtonSize.regular ? 20 : 12,
    );

    final ButtonStyle style;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        style = ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accent.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: shape,
        );
      case AppButtonVariant.secondary:
        style = OutlinedButton.styleFrom(
          foregroundColor: _accent,
          disabledForegroundColor: AppColors.textLight,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: enabled ? _accent.withValues(alpha: 0.5) : AppColors.border,
            width: 1.4,
          ),
          padding: padding,
          shape: shape,
        );
      case AppButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: _accent,
          disabledForegroundColor: AppColors.textLight,
          padding: padding,
          shape: shape,
        );
    }

    // The spinner takes the icon's place rather than the whole row: a button
    // that drops its label while it works says less than one that keeps it.
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: _iconSize),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary ||
      AppButtonVariant.danger => ElevatedButton(
        onPressed: press,
        style: style,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: press,
        style: style,
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: press,
        style: style,
        child: child,
      ),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      height: _height,
      child: button,
    );
  }
}
