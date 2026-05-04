import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_generator.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(snapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des relevés'),
      ),
      body: snapshotsAsync.when(
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clipboardList,
                      size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun relevé enregistré.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Appuyez sur "Enregistrer le relevé"\ndepuis l\'écran principal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshots.length,
            itemBuilder: (context, index) {
              final snap = snapshots[index];
              final barCount = snap.items.where((i) => i.space == SpaceType.bar).length;
              final metroCount = snap.items.where((i) => i.space == SpaceType.metro).length;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassmorphismContainer(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.fileText, color: AppTheme.primary),
                    ),
                    title: Text(
                      snap.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$barCount article(s) Bar · $metroCount article(s) Métro',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton PDF
                        IconButton(
                          icon: const Icon(LucideIcons.download, color: AppTheme.primary),
                          tooltip: 'Exporter en PDF',
                          onPressed: () => _exportSnapshotPdf(context, snap),
                        ),
                        // Bouton Supprimer
                        IconButton(
                          icon: Icon(LucideIcons.trash2,
                              color: AppTheme.error.withOpacity(0.7)),
                          tooltip: 'Supprimer',
                          onPressed: () =>
                              _confirmDelete(context, ref, snap.id, snap.label),
                        ),
                      ],
                    ),
                    onTap: () => _showSnapshotDetail(context, snap),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  void _exportSnapshotPdf(BuildContext context, StockSnapshot snapshot) async {
    try {
      final products = snapshot.items
          .map((item) => Product(
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                space: item.space,
              ))
          .toList();
      await PdfGenerator.generateAndShareInventory(products,
          label: snapshot.label,
          restaurantName: snapshot.restaurant,
          createdBy: snapshot.createdBy);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur PDF: $e')),
        );
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Supprimer ce relevé ?'),
        content: Text('Le relevé "$label" sera définitivement supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              ref.read(inventoryNotifierProvider.notifier).deleteSnapshot(id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSnapshotDetail(BuildContext context, StockSnapshot snapshot) {
    final barItems =
        snapshot.items.where((i) => i.space == SpaceType.bar).toList();
    final metroItems =
        snapshot.items.where((i) => i.space == SpaceType.metro).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(snapshot.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader('BAR', LucideIcons.glassWater),
                  if (barItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text('Aucun article.',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  else
                    ...barItems.map((i) => _itemTile(i)),
                  const SizedBox(height: 16),
                  _sectionHeader('MÉTRO — RÉSERVE', LucideIcons.package),
                  if (metroItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: Text('Aucun article.',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  else
                    ...metroItems.map((i) => _itemTile(i)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _itemTile(SnapshotItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(item.name,
                style: const TextStyle(fontSize: 14)),
          ),
          Text(
            _fmt(item.quantity),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
          ),
          const SizedBox(width: 4),
          Text(item.unit,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  String _fmt(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}
