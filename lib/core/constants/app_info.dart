/// Static app metadata and support contact details.
///
/// [supportPhone] and [supportEmail] intentionally default to empty. The UI
/// hides any contact action whose value is blank, so filling these in is the
/// only change needed to switch Help & Support from an informational sheet to
/// working call/email actions.
class AppInfo {
  static const String appName = 'Globelink';

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String version = '1.0.0';

  // TODO: Replace with the real support desk details before release.
  static const String supportPhone = '';
  static const String supportEmail = '';

  static bool get hasSupportPhone => supportPhone.trim().isNotEmpty;
  static bool get hasSupportEmail => supportEmail.trim().isNotEmpty;
  static bool get hasSupportContact => hasSupportPhone || hasSupportEmail;
}
