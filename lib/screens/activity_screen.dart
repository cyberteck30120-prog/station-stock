import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HISTORIQUE LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2)),
                  Text('Journal d\'Activité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucune activité enregistrée.')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ActivityItem(log: logs[index], index: index),
                    childCount: logs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Erreur: $e'))),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityLog log;
  final int index;
  const _ActivityItem({required this.log, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = _getActionColor(log.action);
    final icon = _getActionIcon(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary)),
                    Text(
                      DateFormat('HH:mm').format(log.date),
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(log.action.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(log.details, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(log.date),
                  style: TextStyle(fontSize: 9, color: AppTheme.textSecondary.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'ajout': return Colors.blue;
      case 'modification': return Colors.orange;
      case 'stock': return AppTheme.accent;
      case 'suppression': return AppTheme.error;
      case 'inventaire': return Colors.purple;
      default: return AppTheme.primary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'ajout': return LucideIcons.plusCircle;
      case 'modification': return LucideIcons.edit3;
      case 'stock': return LucideIcons.package;
      case 'suppression': return LucideIcons.trash2;
      case 'inventaire': return LucideIcons.clipboardCheck;
      default: return LucideIcons.info;
    }
  }
}
