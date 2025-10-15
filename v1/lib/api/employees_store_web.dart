// lib/api/employees_store_web.dart
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:convert';
import 'dart:html' as html;

import 'employees_store.dart';

class _WebEmployeesStore implements EmployeesStore {
  static const _kKey = 'employees.json';

  @override
  Future<String?> read() async => html.window.localStorage[_kKey];

  @override
  Future<void> write(String json) async {
    html.window.localStorage[_kKey] = json;
  }

  @override
  Future<String?> export(String prettyJson, {String fileName = 'employees.json'}) async {
    final bytes = utf8.encode(prettyJson);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.append(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
    return 'Downloaded $fileName';
  }
}

EmployeesStore createEmployeesStore() => _WebEmployeesStore();
