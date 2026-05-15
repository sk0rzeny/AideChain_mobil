import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'aidechain.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE distributions_offline (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          beneficiaire_id INTEGER NOT NULL,
          projet_aide_id INTEGER NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL
        )
      '''),
    );
  }

  static Future<int> saveDistribution({
    required int beneficiaireId,
    required int projetAideId,
    String? notes,
  }) async {
    final database = await db;
    return database.insert('distributions_offline', {
      'beneficiaire_id': beneficiaireId,
      'projet_aide_id': projetAideId,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingDistributions() async {
    final database = await db;
    return database.query('distributions_offline', orderBy: 'created_at ASC');
  }

  static Future<void> deleteDistribution(int id) async {
    final database = await db;
    await database.delete('distributions_offline', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> countPending() async {
    final database = await db;
    final result = await database.rawQuery('SELECT COUNT(*) as count FROM distributions_offline');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
