// This file is only used in web builds via conditional import
// Uses dart:html (deprecated but still functional in Flutter web)
// TODO: Migrate to package:web when flutter_web_plugins fully supports it
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html; // ignore: deprecated_member_use
import 'dart:typed_data';

class WebHelper {
  static void downloadImage(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    // ignore: unused_local_variable
    final _ = anchor; // prevent premature GC
    html.Url.revokeObjectUrl(url);
  }
}
