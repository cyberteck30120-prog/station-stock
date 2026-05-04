import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Table produits courants
    await db.execute('''
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,
  min_quantity REAL NOT NULL,
  unit TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  space INTEGER NOT NULL,
  restaurant TEXT NOT NULL DEFAULT 'Cathédrale',
  image_path TEXT,
  price_ht REAL DEFAULT 0.0
)
''');

    // Table en-têtes des relevés
    await db.execute('''
CREATE TABLE stock_snapshots (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  label TEXT NOT NULL,
  restaurant TEXT NOT NULL DEFAULT 'Cathédrale',
  created_by TEXT NOT NULL DEFAULT 'Inconnu'
)
''');

    // Table lignes des relevés
    await db.execute('''
CREATE TABLE snapshot_items (
  id TEXT PRIMARY KEY,
  snapshot_id TEXT NOT NULL,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit TEXT NOT NULL,
  space INTEGER NOT NULL,
  price_ht REAL DEFAULT 0.0,
  FOREIGN KEY (snapshot_id) REFERENCES stock_snapshots(id) ON DELETE CASCADE
)
''');

    // Table utilisateurs
    await db.execute('''
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  pin TEXT NOT NULL DEFAULT '1234',
  role TEXT NOT NULL DEFAULT 'employe',
  can_create_products INTEGER NOT NULL DEFAULT 0,
  can_view_stats INTEGER NOT NULL DEFAULT 0,
  can_view_history INTEGER NOT NULL DEFAULT 0
)
''');

    // Insérer un admin par défaut si création initiale
    await db.insert('users', {
      'id': 'admin-0',
      'name': 'Administrateur',
      'pin': '0000',
      'role': 'admin',
      'can_create_products': 1,
      'can_view_stats': 1,
      'can_view_history': 1,
    });
    
    // Table logs d'activité
    await db.execute('''
CREATE TABLE activity_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  user_name TEXT NOT NULL,
  action TEXT NOT NULL,
  details TEXT NOT NULL,
  product_id TEXT
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE products ADD COLUMN restaurant TEXT NOT NULL DEFAULT 'Cathédrale'");
      await db.execute(
          "ALTER TABLE stock_snapshots ADD COLUMN restaurant TEXT NOT NULL DEFAULT 'Cathédrale'");
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE stock_snapshots ADD COLUMN created_by TEXT NOT NULL DEFAULT 'Inconnu'");
      await db.execute('''
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL
)
''');
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE products ADD COLUMN image_path TEXT");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE products ADD COLUMN price_ht REAL DEFAULT 0.0");
      await db.execute("ALTER TABLE snapshot_items ADD COLUMN price_ht REAL DEFAULT 0.0");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE users ADD COLUMN pin TEXT NOT NULL DEFAULT '1234'");
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'employe'");
      await db.execute("ALTER TABLE users ADD COLUMN can_create_products INTEGER NOT NULL DEFAULT 0");
      
      // Inject admin just in case
      final result = await db.query('users', where: 'role = ?', whereArgs: ['admin']);
      if (result.isEmpty) {
        await db.insert('users', {
          'id': 'admin-0',
          'name': 'Administrateur',
          'pin': '0000',
          'role': 'admin',
          'can_create_products': 1
        });
      }
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE users ADD COLUMN can_view_stats INTEGER NOT NULL DEFAULT 0");
      await db.execute("ALTER TABLE users ADD COLUMN can_view_history INTEGER NOT NULL DEFAULT 0");
      // Admin a tous les droits par défaut
      await db.update('users',
        {'can_view_stats': 1, 'can_view_history': 1},
        where: 'role = ?', whereArgs: ['admin'],
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
CREATE TABLE activity_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  user_name TEXT NOT NULL,
  action TEXT NOT NULL,
  details TEXT NOT NULL,
  product_id TEXT
)
''');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
