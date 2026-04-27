import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'constants.dart';
import 'local_db.dart';

class LocalStore {
  static String _webKey(String table) => 'web_store_$table';

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? orderBy,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webKey(table));
      final rows = raw == null
          ? <Map<String, dynamic>>[]
          : (jsonDecode(raw) as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
      rows.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      return rows;
    }

    final db = await LocalDb.instance;
    return db.query(table, orderBy: orderBy);
  }

  static Future<void> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (kIsWeb) {
      final rows = await query(table);
      final id = values['id'];
      if (conflictAlgorithm == ConflictAlgorithm.ignore && rows.any((item) => item['id'] == id)) {
        return;
      }
      rows.removeWhere((item) => item['id'] == id);
      rows.insert(0, values);
      await _saveWeb(table, rows);
      return;
    }

    final db = await LocalDb.instance;
    await db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  static Future<void> update(
    String table,
    Map<String, dynamic> values, {
    required String id,
  }) async {
    if (kIsWeb) {
      final rows = await query(table);
      final index = rows.indexWhere((item) => item['id'] == id);
      if (index >= 0) {
        rows[index] = {...rows[index], ...values};
        await _saveWeb(table, rows);
      }
      return;
    }

    final db = await LocalDb.instance;
    await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> pendingSyncQueue() async {
    final rows = await query(AppConstants.tSyncQueue, orderBy: 'created_at DESC');
    return rows.where((item) => item['status'] == 'PENDENTE').toList();
  }

  static Future<int> syncAttempts(String clientId) async {
    final rows = await query(AppConstants.tSyncQueue);
    final row = rows.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['client_generated_id'] == clientId,
          orElse: () => null,
        );
    return int.tryParse((row?['tentativas'] ?? 0).toString()) ?? 0;
  }

  static Future<void> _saveWeb(String table, List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webKey(table), jsonEncode(rows));
  }
}
