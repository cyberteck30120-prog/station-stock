import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../data/inventory_repository.dart';
import '../data/supabase_repository.dart';

final repositoryProvider = Provider((ref) => SupabaseRepository());

// ── Espace actif ───────────────────────────────────────────────────────────
class CurrentSpaceNotifier extends Notifier<SpaceType> {
  @override
  SpaceType build() => SpaceType.bar;
  void setSpace(SpaceType space) => state = space;
}

final currentSpaceProvider =
    NotifierProvider<CurrentSpaceNotifier, SpaceType>(() => CurrentSpaceNotifier());

// ── Thème (Mode Sombre/Clair) ───────────────────────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;
  void toggle() => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ThemeModeNotifier());

// ── Restaurant actif ───────────────────────────────────────────────────────
class CurrentRestaurantNotifier extends Notifier<String> {
  @override
  String build() => 'Cathédrale';
  void setRestaurant(String restaurant) => state = restaurant;
}

final currentRestaurantProvider =
    NotifierProvider<CurrentRestaurantNotifier, String>(() => CurrentRestaurantNotifier());

// ── Profils Utilisateurs ───────────────────────────────────────────────────
class UsersNotifier extends Notifier<AsyncValue<List<AppUser>>> {
  @override
  AsyncValue<List<AppUser>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(repositoryProvider).getAllUsers());
  }

  Future<void> addUser(AppUser user) async {
    await ref.read(repositoryProvider).addUser(user);
    await _load();
  }

  Future<void> updateUser(AppUser user) async {
    await ref.read(repositoryProvider).updateUser(user);
    await _load();
  }

  Future<void> deleteUser(String id) async {
    await ref.read(repositoryProvider).deleteUser(id);
    await _load();
  }
}

final usersProvider = NotifierProvider<UsersNotifier, AsyncValue<List<AppUser>>>(() => UsersNotifier());

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  bool login(String pin) {
    final usersAsync = ref.read(usersProvider);
    if (usersAsync.hasValue) {
      final users = usersAsync.value!;
      final user = users.cast<AppUser?>().firstWhere(
        (u) => u?.pin == pin, 
        orElse: () => null
      );
      if (user != null) {
        state = user;
        // Met à jour automatiquement le restaurant actif selon l'utilisateur
        ref.read(currentRestaurantProvider.notifier).setRestaurant(user.restaurant);
        return true;
      }
    }
    return false;
  }

  void logout() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(() => AuthNotifier());

// ── Recherche ──────────────────────────────────────────────────────────────
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

// ── Produits ───────────────────────────────────────────────────────────────
final productsProvider =
    FutureProvider.family<List<Product>, SpaceType>((ref, space) async {
  final restaurant = ref.watch(currentRestaurantProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  
  final all = await ref.read(repositoryProvider).getProductsBySpace(space, restaurant);
  
  if (query.isEmpty) return all;
  return all.where((p) => p.name.toLowerCase().contains(query)).toList();
});

final spaceCountsProvider = FutureProvider<Map<SpaceType, int>>((ref) async {
  final restaurant = ref.watch(currentRestaurantProvider);
  final all = await ref.read(repositoryProvider).getAllProducts(restaurant);
  
  final counts = {
    SpaceType.bar: 0,
    SpaceType.metro: 0,
    SpaceType.labo: 0,
  };
  
  for (final p in all) {
    counts[p.space] = (counts[p.space] ?? 0) + 1;
  }
  return counts;
});

// ── Historique ─────────────────────────────────────────────────────────────
final snapshotsProvider = FutureProvider<List<StockSnapshot>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final restaurant = ref.watch(currentRestaurantProvider);
  return repo.getAllSnapshots(restaurant);
});

// ── Activités ──────────────────────────────────────────────────────────────
class ActivityLogsNotifier extends Notifier<AsyncValue<List<ActivityLog>>> {
  @override
  AsyncValue<List<ActivityLog>> build() {
    _load();
    return const AsyncValue.loading();
  }
  Future<void> _load() async {
    state = await AsyncValue.guard(() => ref.read(repositoryProvider).getActivityLogs());
  }
  void refresh() => _load();
}

final activityLogsProvider = NotifierProvider<ActivityLogsNotifier, AsyncValue<List<ActivityLog>>>(() => ActivityLogsNotifier());

// ── Notifier principal ─────────────────────────────────────────────────────
class InventoryNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> _log(String action, String details, {String? productId}) async {
    final user = ref.read(authProvider);
    final log = ActivityLog(
      date: DateTime.now(),
      userName: user?.name ?? 'Anonyme',
      action: action,
      details: details,
      productId: productId,
    );
    await ref.read(repositoryProvider).logActivity(log);
    ref.read(activityLogsProvider.notifier).refresh();
  }

  Future<void> updateProduct(Product product) async {
    await ref.read(repositoryProvider).updateProduct(product);
    await _log('Modification', 'Produit : ${product.name}', productId: product.id);
    ref.invalidate(productsProvider);
    ref.invalidate(spaceCountsProvider);
  }

  Future<void> updateQuantity(String productId, double newQuantity) async {
    await ref.read(repositoryProvider).updateProductQuantity(productId, newQuantity);
    // On pourrait chercher le nom ici, mais on se contente de l'ID ou on laisse plus simple
    await _log('Stock', 'Nouveau stock : $newQuantity', productId: productId);
    ref.invalidate(productsProvider);
  }

  Future<void> deleteProduct(String productId) async {
    await ref.read(repositoryProvider).deleteProduct(productId);
    await _log('Suppression', 'Produit ID : $productId');
    ref.invalidate(productsProvider);
    ref.invalidate(spaceCountsProvider);
  }

  Future<void> addProduct(Product product) async {
    await ref.read(repositoryProvider).addProduct(product);
    await _log('Ajout', 'Nouveau produit : ${product.name}', productId: product.id);
    ref.invalidate(productsProvider);
    ref.invalidate(spaceCountsProvider);
  }

  Future<void> reorderProducts(
      int oldIndex, int newIndex, List<Product> current) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final list = List<Product>.from(current);
    list.insert(newIndex, list.removeAt(oldIndex));
    await ref.read(repositoryProvider).updateProductsOrder(list);
    ref.invalidate(productsProvider);
  }

  Future<void> saveSnapshot(String label) async {
    final repo = ref.read(repositoryProvider);
    final restaurant = ref.read(currentRestaurantProvider);
    final user = ref.read(authProvider);
    final allProducts = await repo.getAllProducts(restaurant);
    
    final snapshot = StockSnapshot(
      date: DateTime.now(),
      label: label,
      restaurant: restaurant,
      createdBy: user?.name ?? 'Anonyme',
      items: [],
    );

    final itemsWithId = allProducts
        .map((p) => SnapshotItem(
              snapshotId: snapshot.id,
              name: p.name,
              quantity: p.quantity,
              unit: p.unit,
              space: p.space,
              priceHT: p.priceHT,
            ))
        .toList();

    final snapshotWithItems = StockSnapshot(
      id: snapshot.id,
      date: snapshot.date,
      label: snapshot.label,
      restaurant: restaurant,
      createdBy: snapshot.createdBy,
      items: itemsWithId,
    );

    await repo.saveSnapshot(snapshotWithItems);
    await _log('Inventaire', 'Validation de l\'inventaire : ${snapshotWithItems.label}');
    ref.invalidate(snapshotsProvider);
  }

  Future<void> deleteSnapshot(String snapshotId) async {
    await ref.read(repositoryProvider).deleteSnapshot(snapshotId);
    ref.invalidate(snapshotsProvider);
  }
}

final inventoryNotifierProvider =
    NotifierProvider<InventoryNotifier, void>(() => InventoryNotifier());
