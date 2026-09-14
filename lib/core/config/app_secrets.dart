/// Build-time secrets and release URLs.
///
/// Pass at compile time, for example:
/// `flutter build appbundle --release --dart-define-from-file=dart_defines.json`
///
/// See [dart_defines.json.example] in the project root.
abstract final class AppSecrets {
  static const pexelsApiKey = String.fromEnvironment('PEXELS_API_KEY');

  /// HTTPS URL of the hosted privacy policy (required for Google Play).
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

  static bool get hasPexelsApiKey => pexelsApiKey.isNotEmpty;

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.isNotEmpty;
}
