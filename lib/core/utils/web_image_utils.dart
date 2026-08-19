import 'package:flutter/foundation.dart';

/// Utility class to sanitize image URLs for Flutter Web cross-origin restrictions.
class WebImageUtils {
  /// Converts an image URL into a CORS-safe URL when running on Flutter Web.
  ///
  /// Google profile pictures (`lh3.googleusercontent.com`) do not return `Access-Control-Allow-Origin`
  /// headers for XHR/fetch requests issued by Flutter Web's canvas renderer.
  /// Routing them through `images.weserv.nl` allows the browser to load the image cleanly.
  static String getCorsSafeUrl(String originalUrl) {
    if (!kIsWeb) return originalUrl;

    if (originalUrl.contains('googleusercontent.com')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(originalUrl)}';
    }

    return originalUrl;
  }
}
