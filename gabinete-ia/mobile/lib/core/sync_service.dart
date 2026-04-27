import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'api_client.dart';
import 'constants.dart';
import 'local_db.dart';

class SyncService {
  static Future<Map<String, int>> syncAll() async {
    if (AppConstants.previewMode) {
      return {'success': 0, 'errors': 0};
    }

    final db = await LocalDb.instance;
    var success = 0;
    var errors = 0;

    final pending = await db.query(
      AppConstants.tSyncQueue,
      where: 'status = ?',
      whereArgs: ['PENDENTE'],
    );

    if (pending.isEmpty) {
      return {'success': 0, 'errors': 0};
    }

    final items = pending
        .map(
          (row) => {
            'client_generated_id': row['client_generated_id'],
            'entidade': row['entidade'],
            'payload': jsonDecode(row['payload'] as String),
          },
        )
        .toList();

    try {
      final res = await ApiClient.instance.post('/mobile/sync', data: {'items': items});
      final data = res.data as Map<String, dynamic>;

      for (final processed in (data['processed'] as List<dynamic>)) {
        await db.update(
          AppConstants.tSyncQueue,
          {'status': 'ENVIADO'},
          where: 'client_generated_id = ?',
          whereArgs: [processed['client_generated_id']],
        );
        success++;
      }

      for (final itemError in (data['errors'] as List<dynamic>)) {
        final currentAttempts = Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT tentativas FROM ${AppConstants.tSyncQueue} WHERE client_generated_id = ?',
                [itemError['client_generated_id']],
              ),
            ) ??
            0;
        await db.update(
          AppConstants.tSyncQueue,
          {
            'status': 'ERRO',
            'tentativas': currentAttempts + 1,
          },
          where: 'client_generated_id = ?',
          whereArgs: [itemError['client_generated_id']],
        );
        errors++;
      }
    } catch (_) {
      errors = pending.length;
    }

    return {'success': success, 'errors': errors};
  }

  static Future<void> enqueue({
    required String clientId,
    required String entidade,
    required Map<String, dynamic> payload,
  }) async {
    if (AppConstants.previewMode) {
      return;
    }

    final db = await LocalDb.instance;
    await db.insert(
      AppConstants.tSyncQueue,
      {
        'id': clientId,
        'client_generated_id': clientId,
        'entidade': entidade,
        'payload': jsonEncode(payload),
        'status': 'PENDENTE',
        'tentativas': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    if (AppConstants.previewMode) {
      return [];
    }

    final db = await LocalDb.instance;
    return db.query(AppConstants.tSyncQueue, orderBy: 'created_at DESC');
  }
}
