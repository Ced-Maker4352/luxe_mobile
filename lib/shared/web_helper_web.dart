// ignore_for_file: avoid_web_libraries_in_flutter
// This file is only used in web builds via conditional import
import 'dart:html' as html; // ignore: deprecated_member_use
import 'dart:typed_data';

class WebHelper {
  static void downloadImage(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
