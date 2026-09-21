import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// The app's header — a brand wash running from its deepest at the top down to
/// near-white at the bottom, so it settles into the page rather than cutting
/// across it, and rounded off at the bottom so the page behind reads as a
/// separate surface.
///
/// It replaces the plain white [AppBar] every screen used to build for itself,
/// each with its own title size, colour and elevation, and all of them the same
/// white as the content underneath.
///
/// The wash is mixed from [accent], so a screen carries its own colour while
/// keeping the same shape and type as every other screen: green where a booking
/// is approved or confirmed, red where an account is deleted, slate behind the
/// legal text, brand navy everywhere else.
///
/// [bottomHeight] has to match what [bottom] actually lays out to: a
/// [PreferredSizeWidget] commits to its height before its child is measured.
class TintedPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// One line of context under the title. Wraps to two lines at most.
  final String? subtitle;

  /// The colour the wash is mixed from — what makes the bar this page's.
  final Color accent;

  /// Trailing pill on the title row, usually a live count or a status — see
  /// [HeaderCountPill].
  final Widget? badge;

  /// Round buttons after the title — see [HeaderIconButton], which is what
  /// they should be for the header to read as one piece.
  final List<Widget> actions;

  /// Shows a back button whenever the route can be popped, exactly as
  /// [AppBar] does. The tabs inside the shell pass false: their route can be
  /// popped — back to the login screen — but they must not offer it.
  final bool automaticallyImplyLeading;

  /// Attached under the title block, e.g. a filter row.
  final Widget? bottom;
  final double bottomHeight;

  const TintedPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.accent = AppColors.primary,
    this.badge,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.bottomHeight = 0,
  });

  /// Title row alone, or with room for two lines of [subtitle] under it.
  double get _titleBlockHeight => subtitle == null ? 48 : 76;

  @override
  Size get preferredSize => Size.fromHeight(_titleBlockHeight + bottomHeight);

  @override
  Widget build(BuildContext context) {
    final showBack = automaticallyImplyLeading && Navigator.canPop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The wash is light at every accent, so the clock and the battery have
      // to be dark. A custom bar gets none of the contrast handling [AppBar]
      // does for free.
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: _shape,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Keeps the wash and the accent line inside the rounded corners while
        // leaving the shadow above to fall outside them.
        child: ClipRRect(
          borderRadius: _shape,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: headerGradient(accent)),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: _titleBlockHeight,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            showBack ? 8 : 20,
                            2,
                            _hasTrailing ? 8 : 20,
                            6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  if (showBack) ...[
                                    HeaderIconButton(
                                      icon: Icons.arrow_back_rounded,
                                      tooltip: 'Back',
                                      onPressed: () =>
                                          Navigator.maybePop(context),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 8),
                                    badge!,
                                  ],
                                  for (final action in actions) ...[
                                    const SizedBox(width: 6),
                                    action,
                                  ],
                                ],
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 3),
                                Padding(
                                  // Lines up with the title rather than the
                                  // back button sitting to the left of it.
                                  padding: EdgeInsets.only(
                                    left: showBack ? 46 : 0,
                                  ),
                                  child: Text(
                                    subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMedium,
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (bottom != null)
                      SizedBox(height: bottomHeight, child: bottom),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasTrailing => badge != null || actions.isNotEmpty;

  static const BorderRadius _shape = BorderRadius.vertical(
    bottom: Radius.circular(24),
  );
}

/// The wash the headers paint: the [accent] at its strongest along the top,
/// falling away to a hint of it at the bottom, so the bar settles into the page
/// rather than ending on a hard edge.
///
/// Shared with the Home tab's collapsing header, which is the same bar in its
/// fullest form — the two must not drift apart.
LinearGradient headerGradient(Color accent) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    headerWash(accent, 0.26),
    headerWash(accent, 0.15),
    headerWash(accent, 0.05),
  ],
  stops: const [0, 0.55, 1],
);

/// The wash behind a row attached to the bottom of a header — the same colour
/// across its width, since [headerGradient] runs straight down.
///
/// A row that fades its own edges out, like the quote filters, matches against
/// this rather than guessing a constant.
Color headerWashBehindBottomRow(Color accent) => headerWash(accent, 0.09);

/// The wash [headerGradient] paints, [amount] of the way into its [accent].
Color headerWash(Color accent, double amount) =>
    Color.alphaBlend(accent.withValues(alpha: amount), Colors.white);

/// Live count or status pill for [TintedPageHeader.badge], e.g. `148 quotes`.
class HeaderCountPill extends StatelessWidget {
  final String label;

  const HeaderCountPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Round white button for [TintedPageHeader.actions] and the header's own back
/// button. White on the wash, so an action reads as a control rather than as
/// another piece of text in the title row.
///
/// A null [onPressed] greys the icon out and stops the tap, the way a disabled
/// [IconButton] does; [busy] swaps the icon for a spinner while the action it
/// fired is still running, so a refresh does not have to leave the row.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 38,
            height: 38,
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 19,
                    color: enabled ? AppColors.primary : AppColors.textLight,
                  ),
          ),
        ),
      ),
    );
  }
}
