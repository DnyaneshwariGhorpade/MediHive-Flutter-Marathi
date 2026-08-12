import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/schema.dart';

class PatientRepository {
  Future<Database> get _db async => DatabaseHelper().database;

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    return db.query(tablePatients, orderBy: 'id ASC');
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _db;
    final rows = await db.query(tablePatients, where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<Map<String, dynamic>?> getBySyncId(String syncId) async {
    final db = await _db;
    final rows = await db.query(
      tablePatients,
      where: 'sync_id = ?',
      whereArgs: [syncId],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> getByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    return db.query(
      tablePatients,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<Map<String, String>> getSyncIdNameMap() async {
    final db = await _db;
    final rows = await db.query(tablePatients, columns: ['sync_id', 'full_name']);
    return {
      for (final r in rows)
        (r['sync_id'] as String? ?? ''): (r['full_name'] as String? ?? ''),
    };
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final now = DateTime.now().toIso8601String();
    final db = await _db;
    return db.insert(tablePatients, {
      'id': row['id'],
      'sync_id': row['sync_id'],
      'full_name': row['full_name'],
      'mobile_number': row['mobile_number'],
      'alternate_mobile': row['alternate_mobile'],
      'gender': row['gender'],
      'dob': row['dob'],
      'age': row['age'],
      'blood_group': row['blood_group'],
      'address': row['address'],
      'clinic_id': row['clinic_id'],
      'device_id': row['device_id'],
      'sync_status': row['sync_status'] ?? 'pending',
      'last_synced_at': row['last_synced_at'],
      'created_at': row['created_at'] ?? now,
      'updated_at': row['updated_at'] ?? row['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
      'weight': row['weight'],
    });
  }

  Future<int> update(int id, Map<String, dynamic> row) async {
    final db = await _db;
    final affected = await db.update(tablePatients, {
      ...row,
      'updated_at': row['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
    print('PATIENT REPO UPDATE: id=$id affectedRows=$affected');
    return affected;
  }

  Future<int> updateSyncId(String oldSyncId, String newSyncId) async {
    final db = await _db;
    return db.update(
      tablePatients,
      {'sync_id': newSyncId, 'updated_at': DateTime.now().toUtc().toIso8601String()},
      where: 'sync_id = ?',
      whereArgs: [oldSyncId],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(tablePatients, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM $tablePatients');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getByMobile(String mobile) async {
    final db = await _db;
    final rows = await db.query(
      tablePatients,
      where: 'mobile_number = ?',
      whereArgs: [mobile],
      orderBy: 'full_name ASC',
    );
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final row in rows) {
      final key = '${row['full_name']}|${row['gender']}|${row['dob']}';
      if (seen.add(key)) {
        unique.add(row);
      }
    }
    return unique;
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final db = await _db;
    return db.query(tablePatients,
      where: 'full_name LIKE ? OR mobile_number LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'full_name ASC',
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete(tablePatients);
  }

  Future<int> getMaxId() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COALESCE(MAX(id), 0) AS max_id FROM $tablePatients');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
