import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<bool> openStoreUrl(String rawUrl, {String? deepLink}) async {
    String url = rawUrl.trim();

    // Prefer deep link on native iOS/Android if available, but web must use HTTPS
    if (!kIsWeb && deepLink != null && deepLink.isNotEmpty) {
      final deepUri = Uri.tryParse(deepLink);
      if (deepUri != null && await canLaunchUrl(deepUri)) {
        try {
          final launched = await launchUrl(deepUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        } catch (_) {}
      }
    }

    if (url.isEmpty) return false;

    // Ensure valid URL scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      print('UrlLauncherHelper error launching $url: $e');
      return false;
    }
  }
}
