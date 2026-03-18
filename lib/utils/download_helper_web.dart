import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadStringAsFile(String content, String fileName) {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;

  web.document.body?.appendChild(anchor);
  anchor.click();

  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}
