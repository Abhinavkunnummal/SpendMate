import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class OfflineSyncManager {
  static const String _syncQueueKey = 'spendmate_offline_mutation_queue';

  /// Adds a pending mutation to local offline queue
  static Future<void> queueMutation({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_syncQueueKey) ?? [];

    final item = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    };

    rawList.add(jsonEncode(item));
    await prefs.setStringList(_syncQueueKey, rawList);
  }

  /// Flushes pending offline mutations to the backend API
  static Future<int> flushQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_syncQueueKey) ?? [];
    if (rawList.isEmpty) return 0;

    final apiClient = ApiClient();
    int syncedCount = 0;
    final List<String> remaining = [];

    for (final raw in rawList) {
      try {
        final item = jsonDecode(raw) as Map<String, dynamic>;
        final method = item['method'] as String;
        final endpoint = item['endpoint'] as String;
        final payload = item['payload'] as Map<String, dynamic>;

        if (method == 'POST') {
          await apiClient.dio.post(endpoint, data: payload);
        } else if (method == 'PUT') {
          await apiClient.dio.put(endpoint, data: payload);
        } else if (method == 'DELETE') {
          await apiClient.dio.delete(endpoint);
        }

        syncedCount++;
      } catch (e) {
        remaining.add(raw);
      }
    }

    await prefs.setStringList(_syncQueueKey, remaining);
    return syncedCount;
  }
}
