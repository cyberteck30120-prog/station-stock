import '../models/models.dart';
import 'database_helper.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ── Produits courants ──────────────────────────────────────────────────────

  Future<List<Product>> getProductsBySpace(SpaceType space, String restaurant) async {
    final db = await _dbHelper.database;
    final maps = await db.query('products',
        where: 'space = ? AND restaurant = ?', 
        whereArgs: [space.index, restaurant], 
        orderBy: 'order_index ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getAllProducts(String restaurant) async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', 
        where: 'restaurant = ?',
        whereArgs: [restaurant],
        orderBy: 'space ASC, order_index ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> addProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> updateProductQuantity(String id, double quantity) async {
    final db = await _dbHelper.database;
    await db.update('products', {'quantity': quantity}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductsOrder(List<Product> products) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < products.length; i++) {
      batch.update('products', {'order_index': i},
          where: 'id = ?', whereArgs: [products[i].id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ── Historique / Snapshots ─────────────────────────────────────────────────

  Future<void> saveSnapshot(StockSnapshot snapshot) async {
    final db = await _dbHelper.database;
    await db.insert('stock_snapshots', snapshot.toMap());
    final batch = db.batch();
    for (final item in snapshot.items) {
      batch.insert('snapshot_items', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<StockSnapshot>> getAllSnapshots(String restaurant) async {
    final db = await _dbHelper.database;
    final snapshotMaps = await db.query('stock_snapshots',
        where: 'restaurant = ?',
        whereArgs: [restaurant],
        orderBy: 'date DESC');
    final List<StockSnapshot> result = [];
    for (final sm in snapshotMaps) {
      final itemMaps = await db.query('snapshot_items',
          where: 'snapshot_id = ?', whereArgs: [sm['id']]);
      final items = itemMaps.map((m) => SnapshotItem.fromMap(m)).toList();
      result.add(StockSnapshot.fromMap(sm, items));
    }
    return result;
  }

  Future<void> deleteSnapshot(String snapshotId) async {
    final db = await _dbHelper.database;
    await db.delete('snapshot_items',
        where: 'snapshot_id = ?', whereArgs: [snapshotId]);
    await db.delete('stock_snapshots',
        where: 'id = ?', whereArgs: [snapshotId]);
  }

  // ── Utilisateurs ───────────────────────────────────────────────────────────

  Future<List<AppUser>> getAllUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', orderBy: 'name ASC');
    return maps.map((m) => AppUser.fromMap(m)).toList();
  }

  Future<void> addUser(AppUser user) async {
    final db = await _dbHelper.database;
    await db.insert('users', user.toMap());
  }

  Future<void> updateUser(AppUser user) async {
    final db = await _dbHelper.database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> deleteUser(String id) async {
    final db = await _dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ── Activités ──────────────────────────────────────────────────────────────

  Future<void> logActivity(ActivityLog log) async {
    final db = await _dbHelper.database;
    await db.insert('activity_logs', log.toMap());
  }

  Future<List<ActivityLog>> getActivityLogs({int limit = 100}) async {
    final db = await _dbHelper.database;
    final maps = await db.query('activity_logs', orderBy: 'date DESC', limit: limit);
    return maps.map((m) => ActivityLog.fromMap(m)).toList();
  }
}
