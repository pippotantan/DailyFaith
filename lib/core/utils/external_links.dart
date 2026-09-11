import 'package:url_launcher/url_launcher.dart';

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
}
