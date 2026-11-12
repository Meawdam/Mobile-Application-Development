import 'package:flutter/foundation.dart';

/// Base URL for the Express API (`backend/app.js` listens on port 3000).
String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulator reaches the host machine via 10.0.2.2.
      return 'http://10.0.2.2:3000';
    default:
      return 'http://localhost:3000';
  }
}

String resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) {
    return '';
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/')) {
    return '$apiBaseUrl$path';
  }
  return '$apiBaseUrl/$path';
}
