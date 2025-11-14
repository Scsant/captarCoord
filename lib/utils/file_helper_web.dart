import 'dart:convert';
import 'dart:html' as html;

Future<String> saveJsonToFile(String jsonString, String filename) async {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Downloaded: $filename';
}




