import 'package:flutter/material.dart';

void downloadStringAsFile(String content, String fileName) {
  // File download not supported on this platform
  // Could be extended to use share_plus or path_provider for mobile
  debugPrint('Download not available on this platform. Content length: ${content.length}');
}
