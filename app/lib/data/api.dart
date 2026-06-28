import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/memory.dart';

/// Адресът на твоя сървър. Подай го при стартиране:
///   flutter run --dart-define=API_BASE=http://192.168.1.10:8000
/// или смени стойността по подразбиране тук.
const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:8000');

class Api {
  Map<String, dynamic> _toJson(Memory m) => {
        'id': m.uid,
        'text': m.text,
        'kind': m.kind,
        'created_at': m.createdAt.toUtc().toIso8601String(),
        'updated_at': m.updatedAt.toUtc().toIso8601String(),
        'deleted': m.deleted,
      };

  /// Качва списък промени. Връща ok/false.
  Future<bool> push(List<Memory> items) async {
    if (items.isEmpty) return true;
    final res = await http.post(
      Uri.parse('$apiBase/api/sync/push'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'memories': items.map(_toJson).toList()}),
    );
    return res.statusCode == 200;
  }

  /// Изтегля всичко, променено след `since`. Връща (записи, нов курсор).
  Future<(List<Map<String, dynamic>>, int)> pull(int since) async {
    final res = await http.get(Uri.parse('$apiBase/api/sync/pull?since=$since'));
    if (res.statusCode != 200) return (<Map<String, dynamic>>[], since);
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final mems = (data['memories'] as List).cast<Map<String, dynamic>>();
    return (mems, data['cursor'] as int);
  }
}
