import 'package:url_launcher/url_launcher.dart';
import 'package:zane_bible_lockscreen/core/config/app_secrets.dart';

/// External URLs opened from the app (browser only — no in-app payments).
class ExternalLinks {
  ExternalLinks._();

  static final Uri buyMeACoffeeUrl =
      Uri.parse('https://buymeacoffee.com/zane.daily.faith');

  /// Opens the Buy Me a Coffee support page in the device's browser.
  /// Returns `false` if the URL cannot be opened.
  static Future<bool> launchBuyMeACoffee() async {
    if (!await canLaunchUrl(buyMeACoffeeUrl)) {
      return false;
    }
    return launchUrl(
      buyMeACoffeeUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  /// Opens the hosted privacy policy when [AppSecrets.privacyPolicyUrl] is set.
  static Future<bool> launchPrivacyPolicy() async {
    if (!AppSecrets.hasPrivacyPolicyUrl) {
      return false;
    }
    final uri = Uri.tryParse(AppSecrets.privacyPolicyUrl);
    if (uri == null || !uri.isScheme('https')) {
      return false;
    }
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
