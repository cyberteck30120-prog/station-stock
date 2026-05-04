import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseRepository {
  final _client = Supabase.instance.client;

  // ── Produits ───────────────────────────────────────────────────────────────

  Future<List<Product>> getAllProducts(String restaurant) async {
    final res = await _client
        .from('products')
        .select()
        .eq('restaurant', restaurant)
        .order('space', ascending: true)
        .order('order_index', ascending: true);
    return (res as List).map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getProductsBySpace(SpaceType space, String restaurant) async {
    final res = await _client
        .from('products')
        .select()
        .eq('restaurant', restaurant)
        .eq('space', space.index)
        .order('order_index', ascending: true);
    return (res as List).map((m) => Product.fromMap(m)).toList();
  }

  Future<void> addProduct(Product product) async {
    await _client.from('products').upsert(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _client.from('products').update(product.toMap()).eq('id', product.id);
  }

  Future<void> updateProductQuantity(String id, double quantity) async {
    await _client.from('products').update({'quantity': quantity}).eq('id', id);
  }

  Future<void> updateProductsOrder(List<Product> products) async {
    for (int i = 0; i < products.length; i++) {
      await _client.from('products').update({'order_index': i}).eq('id', products[i].id);
    }
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // ── Historique / Snapshots ─────────────────────────────────────────────────

  Future<void> saveSnapshot(StockSnapshot snapshot) async {
    await _client.from('stock_snapshots').upsert(snapshot.toMap());
    
    final itemsJson = snapshot.items.map((it) => it.toMap()).toList();
    await _client.from('snapshot_items').upsert(itemsJson);
  }

  Future<List<StockSnapshot>> getAllSnapshots(String restaurant) async {
    final res = await _client
        .from('stock_snapshots')
        .select('*, snapshot_items(*)')
        .eq('restaurant', restaurant)
        .order('date', ascending: false);
    
    return (res as List).map((m) {
      final items = (m['snapshot_items'] as List).map((it) => SnapshotItem.fromMap(it)).toList();
      return StockSnapshot.fromMap(m, items);
    }).toList();
  }

  Future<void> deleteSnapshot(String snapshotId) async {
    await _client.from('stock_snapshots').delete().eq('id', snapshotId);
  }

  // ── Utilisateurs ───────────────────────────────────────────────────────────

  Future<List<AppUser>> getAllUsers() async {
    final res = await _client.from('users').select().order('name', ascending: true);
    return (res as List).map((m) => AppUser.fromMap(m)).toList();
  }

  Future<void> addUser(AppUser user) async {
    await _client.from('users').upsert(user.toMap());
  }

  Future<void> updateUser(AppUser user) async {
    await _client.from('users').update(user.toMap()).eq('id', user.id);
  }

  Future<void> deleteUser(String id) async {
    await _client.from('users').delete().eq('id', id);
  }

  // ── Activités ──────────────────────────────────────────────────────────────

  Future<void> logActivity(ActivityLog log) async {
    await _client.from('activity_logs').upsert(log.toMap());
  }

  Future<List<ActivityLog>> getActivityLogs({int limit = 100}) async {
    final res = await _client
        .from('activity_logs')
        .select()
        .order('date', ascending: false)
        .limit(limit);
    return (res as List).map((m) => ActivityLog.fromMap(m)).toList();
  }
}
