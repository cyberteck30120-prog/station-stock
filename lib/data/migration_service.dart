import '../data/inventory_repository.dart';
import '../data/supabase_repository.dart';
import '../models/models.dart';

class MigrationService {
  final InventoryRepository localRepo = InventoryRepository();
  final SupabaseRepository supabaseRepo = SupabaseRepository();

  Future<void> migrateIfNeeded() async {
    try {
      print('MIGRATION: Vérification du Cloud...');
      // 1. Vérifier si le cloud est déjà initialisé (ex: produits existants)
      final cloudProducts = await supabaseRepo.getAllProducts('Cathédrale');
      if (cloudProducts.isNotEmpty) {
        print('MIGRATION: Cloud déjà peuplé (${cloudProducts.length} produits), abandon.');
        return;
      }

      print('MIGRATION: Début de l\'envoi des données locales vers le Cloud...');

    // 2. Migrer les utilisateurs
    final users = await localRepo.getAllUsers();
    for (final u in users) {
      await supabaseRepo.addUser(u);
    }

    // 3. Migrer les produits (tous les restos)
    for (final resto in ['Cathédrale', 'Beaux Arts']) {
      final products = await localRepo.getAllProducts(resto);
      for (final p in products) {
        await supabaseRepo.addProduct(p);
      }
    }

    // 4. Migrer l'historique
    for (final resto in ['Cathédrale', 'Beaux Arts']) {
      final snapshots = await localRepo.getAllSnapshots(resto);
      for (final s in snapshots) {
        await supabaseRepo.saveSnapshot(s);
      }
    }

    print('MIGRATION: Terminée avec succès !');
    } catch (e) {
      print('MIGRATION ERROR: $e');
    }
  }
}
