import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_info.dart';
import '../layout/responsive.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// The one store checker for the app's lifetime.
///
/// It looks the app up on the App Store (iOS) or Google Play (Android) on
/// launch, and again every time the app comes back to the foreground. With
/// [Duration.zero] between alerts, a driver who is behind the store sees the
/// prompt on every one of those checks until they update — 'Later' only puts
/// it off until the next one.
///
/// Run with `--dart-define=FORCE_UPDATE_PROMPT=true` to show the prompt even
/// when the installed build is current, to check how it looks.
final Upgrader _upgrader = Upgrader(
  durationUntilAlertAgain: Duration.zero,
  debugDisplayAlways: const bool.fromEnvironment('FORCE_UPDATE_PROMPT'),
);

/// Prompts the driver to update whenever the store has a newer build than the
/// one installed, in the app's own dialog rather than the package's stock
/// [AlertDialog].
///
/// Sits in [MaterialApp.builder] above the [Navigator], so it outlives every
/// route change — login, logout, the root-route rebuild — and [navigatorKey]
/// is how it reaches the Navigator below it to open the dialog.
///
/// There is no 'Ignore': skipping a version for good would defeat the point.
/// When the installed build is below the store's minimum or the release is
/// marked critical, 'Later' goes too and the dialog cannot be dismissed.
class AppUpdateAlert extends UpgradeAlert {
  /// [upgrader] defaults to the app-wide checker; tests pass their own to
  /// stand in a fake store and platform.
  AppUpdateAlert({
    super.key,
    super.navigatorKey,
    super.child,
    Upgrader? upgrader,
  }) : super(
         upgrader: upgrader ?? _upgrader,
         showIgnore: false,
         barrierDismissible: false,
       );

  @override
  UpgradeAlertState createState() => _AppUpdateAlertState();
}

class _AppUpdateAlertState extends UpgradeAlertState {
  UpgraderState? _lastEvaluated;

  @override
  void checkVersion({required BuildContext context}) {
    // The package re-evaluates on every rebuild of this widget, and the app
    // shell rebuilds it on each sign-in and sign-out. Evaluating once per
    // store check keeps 'Later' from being undone by an unrelated rebuild; the
    // next launch or resume runs a fresh check and brings the prompt back.
    final state = widget.upgrader.state;
    if (identical(state, _lastEvaluated)) return;
    _lastEvaluated = state;
    super.checkVersion(context: context);
  }

  @override
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    if (!context.mounted) return;

    final upgrader = widget.upgrader;
    upgrader.saveLastAlerted();
    final isRequired = upgrader.blocked();

    showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => PopScope(
        // A back gesture is the same as 'Later' — unless there is no 'Later'.
        canPop: !isRequired,
        child: _AppUpdateDialog(
          key: key,
          installedVersion: upgrader.currentInstalledVersion,
          storeVersion: upgrader.currentAppStoreVersion,
          releaseNotes: releaseNotes,
          storeName: upgrader.state.upgraderOS.isIOS
              ? 'the App Store'
              : 'Google Play',
          isRequired: isRequired,
          onLater: () => onUserLater(dialogContext, true),
          // A required update keeps the dialog up behind the store, so coming
          // back without updating still finds the app blocked.
          onUpdate: () => onUserUpdated(dialogContext, !isRequired),
        ),
      ),
      // The dialog can also leave without either button — a back gesture, or
      // the route reset on logout clearing it. Either way the next check has
      // to be free to show it again.
    ).whenComplete(() => displayed = false);
  }

  @override
  void onUserUpdated(BuildContext context, bool shouldPop) {
    _openStoreListing();
    if (shouldPop) popNavigator(context);
  }

  /// Opens the app's listing in the store app itself — the App Store on iOS,
  /// Google Play on Android — where the driver lands on the Update button.
  ///
  /// The package's own launcher opens the iOS listing in an in-app browser
  /// sheet, and on Android it first asks whether the link can be opened, which
  /// Android 11+ answers 'no' to without a manifest query. Asking for the
  /// store app directly needs neither, and the browser is only the fallback
  /// for a phone that has no store app.
  Future<void> _openStoreListing() async {
    final listing = widget.upgrader.versionInfo?.appStoreListingURL;
    if (listing == null || listing.isEmpty) return;

    final uri = Uri.parse(listing);
    for (final mode in const [
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.externalApplication,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (error) {
        debugPrint('Could not open the store listing ($mode): $error');
      }
    }
  }
}

class _AppUpdateDialog extends StatelessWidget {
  final String? installedVersion;
  final String? storeVersion;
  final String? releaseNotes;
  final String storeName;
  final bool isRequired;
  final VoidCallback onLater;
  final VoidCallback onUpdate;

  const _AppUpdateDialog({
    super.key,
    required this.installedVersion,
    required this.storeVersion,
    required this.releaseNotes,
    required this.storeName,
    required this.isRequired,
    required this.onLater,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      constraints: const BoxConstraints(maxWidth: AppContentWidth.dialog),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // On a phone held in landscape the banner and the release notes
          // outgrow the screen; they scroll while the buttons stay in reach.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UpdateBanner(isRequired: isRequired),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: _UpdateDetails(
                      installedVersion: installedVersion,
                      storeVersion: storeVersion,
                      releaseNotes: releaseNotes,
                      storeName: storeName,
                      isRequired: isRequired,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: isRequired
                ? AppButton(
                    label: 'Update now',
                    icon: Icons.download_rounded,
                    size: AppButtonSize.compact,
                    onPressed: onUpdate,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Later',
                          size: AppButtonSize.compact,
                          accent: AppColors.textMedium,
                          onPressed: onLater,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Update now',
                          icon: Icons.download_rounded,
                          size: AppButtonSize.compact,
                          onPressed: onUpdate,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Title, message, the version pair and the store's notes — everything in the
/// dialog that is allowed to scroll.
class _UpdateDetails extends StatelessWidget {
  final String? installedVersion;
  final String? storeVersion;
  final String? releaseNotes;
  final String storeName;
  final bool isRequired;

  const _UpdateDetails({
    required this.installedVersion,
    required this.storeVersion,
    required this.releaseNotes,
    required this.storeName,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final notes = releaseNotes?.trim() ?? '';
    final hasVersions =
        (installedVersion?.isNotEmpty ?? false) &&
        (storeVersion?.isNotEmpty ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRequired ? 'Update required' : 'A new update is ready',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isRequired
              ? 'This version of ${AppInfo.appName} is no longer '
                    'supported. Update from $storeName to keep '
                    'managing your trips.'
              : 'A newer version of ${AppInfo.appName} is '
                    'available on $storeName with the latest fixes '
                    'and improvements for your trips.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textMedium,
          ),
        ),
        if (hasVersions) ...[
          const SizedBox(height: 20),
          _VersionCompare(installed: installedVersion!, latest: storeVersion!),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReleaseNotes(notes: notes),
        ],
      ],
    );
  }
}

/// The brand band across the top of the dialog — the same indigo-to-navy run
/// as the profile header, so the prompt reads as part of the app rather than
/// something the system put in front of it.
class _UpdateBanner extends StatelessWidget {
  final bool isRequired;

  const _UpdateBanner({required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.navyDeep],
        ),
      ),
      child: Stack(
        children: [
          // Two faint rings off the corners give the flat band some depth.
          const Positioned(top: -44, right: -30, child: _Ring(size: 130)),
          const Positioned(bottom: -60, left: -36, child: _Ring(size: 120)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRequired
                        ? Icons.priority_high_rounded
                        : Icons.system_update_rounded,
                    color: isRequired
                        ? AppColors.accentOrange
                        : AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? AppColors.accentOrange
                        : Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    isRequired ? 'REQUIRED UPDATE' : 'NEW VERSION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;

  const _Ring({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 18,
        ),
      ),
    );
  }
}

/// Installed build on the left, store build on the right, so the driver can
/// see at a glance that the prompt is about their copy of the app.
class _VersionCompare extends StatelessWidget {
  final String installed;
  final String latest;

  const _VersionCompare({required this.installed, required this.latest});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _VersionChip(
            label: 'Installed',
            version: installed,
            background: AppColors.background,
            border: AppColors.border,
            labelColor: AppColors.textLight,
            versionColor: AppColors.textMedium,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppColors.textLight,
          ),
        ),
        Expanded(
          child: _VersionChip(
            label: 'Latest',
            version: latest,
            background: AppColors.primaryLight,
            border: AppColors.primary.withValues(alpha: 0.25),
            labelColor: AppColors.primary.withValues(alpha: 0.75),
            versionColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final String version;
  final Color background;
  final Color border;
  final Color labelColor;
  final Color versionColor;

  const _VersionChip({
    required this.label,
    required this.version,
    required this.background,
    required this.border,
    required this.labelColor,
    required this.versionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'v$version',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: versionColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The store's "What's new" text, capped in height so a long changelog
/// scrolls inside its box instead of pushing the buttons off the dialog.
class _ReleaseNotes extends StatelessWidget {
  final String notes;

  const _ReleaseNotes({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                "What's new",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
