import 'package:flutter/material.dart';

/// Width breakpoints, in logical pixels, that the app lays out against.
///
/// The app ships to iPad (`TARGETED_DEVICE_FAMILY = 1,2`) in every
/// orientation, so a phone-width layout can be handed anything from a 320pt
/// SE up to a 1366pt iPad Pro in landscape. Stretching a form or a card list
/// across that much width is what makes an iPad build look like a blown-up
/// phone app, so every screen funnels its content through the helpers below
/// instead of filling whatever width it is given.
///
/// The numbers follow Material's window size classes, which line up closely
/// with the widths iPadOS hands an app in Split View and Slide Over:
///   * `< 600`  — phones, and Slide Over on iPad.
///   * `< 900`  — portrait iPad, and a half-width Split View slot.
///   * `>= 900` — landscape iPad and full-screen iPad Pro.
abstract final class AppBreakpoints {
  /// Anything narrower is treated as a phone.
  static const double compact = 600;

  /// Portrait iPad / half-width multitasking slot.
  static const double medium = 900;
}

/// Ceilings on how wide a block of content is allowed to grow.
///
/// Past these widths, extra space becomes margin rather than longer lines:
/// a 1000pt-wide text field or a list row whose label and value sit half a
/// screen apart is harder to use than a centred column of phone-ish width.
abstract final class AppContentWidth {
  /// Sign-in, registration, OTP — single-column forms and their buttons.
  static const double form = 520;

  /// Scrolling page content: cards, lists, detail rows.
  static const double content = 760;

  /// Content that genuinely benefits from width, e.g. a map card or a page
  /// that pairs two columns side by side on a tablet.
  static const double wide = 1080;

  /// Modal surfaces — dialogs and bottom sheets.
  static const double dialog = 460;
  static const double sheet = 580;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// True on a device whose *shortest* side is tablet-sized — i.e. an iPad,
  /// regardless of which way it is being held.
  ///
  /// Use this for decisions about the hardware (how large a touch target or
  /// an illustration should be). For decisions about the space actually
  /// available right now, use [isWideLayout], which correctly reports a
  /// narrow Split View slot on that same iPad as compact.
  bool get isTabletDevice => screenSize.shortestSide >= AppBreakpoints.compact;

  /// True when the window currently has at least tablet width available.
  bool get isWideLayout => screenWidth >= AppBreakpoints.compact;

  /// True at landscape-iPad width, where side-by-side layouts start to pay off.
  bool get isExpandedLayout => screenWidth >= AppBreakpoints.medium;

  bool get isLandscape => screenWidth > screenHeight;

  /// Horizontal page margin that grows with the window.
  ///
  /// Phones keep the 16pt gutter the designs were drawn at; wider windows get
  /// more breathing room so content is not pinned to the bezel.
  double get pageGutter {
    if (isExpandedLayout) return 40;
    if (isWideLayout) return 32;
    return 16;
  }

  /// Vertical rhythm multiplier for the gaps between sections.
  ///
  /// A tablet has the height to afford slightly looser spacing; a phone does
  /// not, so it stays at exactly the spacing the screens were designed with.
  double scaledGap(double phoneGap) =>
      isWideLayout ? phoneGap * 1.25 : phoneGap;
}

/// Centres [child] and stops it growing past [maxWidth].
///
/// On a phone this is a no-op wrapper — the child still fills the width — so
/// it can be dropped into an existing screen without changing how that screen
/// renders on the devices it was designed for.
///
/// [padding] is applied *inside* the constraint, so the content keeps its
/// intended margins instead of butting against the edge of the centred box.
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  /// Passed to the underlying [Align]. Leave null to fill the available
  /// height; set to `1.0` where the parent hands down loose constraints as
  /// tall as the screen (e.g. `Scaffold.bottomNavigationBar`), otherwise the
  /// container grows to that full height instead of hugging its child.
  final double? heightFactor;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidth.content,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.heightFactor,
  });

  /// Preset for single-column forms.
  const AdaptiveContainer.form({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.heightFactor,
  }) : maxWidth = AppContentWidth.form;

  /// Preset for content that should use the extra width, e.g. maps.
  const AdaptiveContainer.wide({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.heightFactor,
  }) : maxWidth = AppContentWidth.wide;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return Align(
      alignment: alignment,
      heightFactor: heightFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}

/// Symmetric padding that centres a scroll view's contents on wide windows.
///
/// A `ListView` cannot be wrapped in a [ConstrainedBox] without losing the
/// full-bleed scrollbar and the edge-to-edge overscroll glow, so instead of
/// constraining the viewport this pads it: the leftover width is split evenly
/// between the two sides, which centres the rows while the scrollable itself
/// still owns the whole screen.
///
/// [horizontal] is the margin the design calls for on a phone, and [vertical]
/// pairs (top, bottom) are passed through untouched.
EdgeInsets adaptiveScrollPadding(
  BuildContext context, {
  double horizontal = 16,
  double top = 0,
  double bottom = 0,
  double maxContentWidth = AppContentWidth.content,
}) {
  final available = context.screenWidth;
  final overflow = available - maxContentWidth - (horizontal * 2);
  final side = overflow > 0 ? horizontal + (overflow / 2) : horizontal;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}
