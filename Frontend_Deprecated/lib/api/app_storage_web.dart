// Web implementation using window.localStorage
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:html' as html;

Future<void> setItem(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<String?> getItem(String key) async {
  return html.window.localStorage[key];
}

Future<void> removeItem(String key) async {
  html.window.localStorage.remove(key);
}

Future<void> openUrl(String url) async {
  html.window.open(url, '_blank');
}
