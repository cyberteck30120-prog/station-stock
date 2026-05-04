import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'activity_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barProducts = ref.watch(productsProvider(SpaceType.bar));
    final metroProducts = ref.watch(productsProvider(SpaceType.metro));
    final laboProducts = ref.watch(productsProvider(SpaceType.labo));
    final snapshots = ref.watch(snapshotsProvider);
    final restaurant = ref.watch(currentRestaurantProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tableau de Bord', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(restaurant, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinancialSummary(barProducts, metroProducts, laboProducts),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Évolution Valeur Stock', LucideIcons.trendingUp),
                  const SizedBox(height: 16),
                  _buildEvolutionChart(context, snapshots),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Répartition Valeur HT', LucideIcons.pieChart),
                  const SizedBox(height: 16),
                  _buildValuePieChart(context, barProducts, metroProducts, laboProducts),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Alertes de Stock', LucideIcons.alertTriangle),
                  const SizedBox(height: 16),
                  _buildAlertsList(context, barProducts, metroProducts, laboProducts),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Activité Récente', LucideIcons.activity),
                  const SizedBox(height: 16),
                  _buildRecentActivity(context, ref),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(
      AsyncValue<List<Product>> bar, AsyncValue<List<Product>> metro, AsyncValue<List<Product>> labo) {
    double totalHT = 0;
    void process(AsyncValue<List<Product>> async) {
      async.whenData((list) => list.forEach((p) => totalHT += (p.quantity * p.priceHT)));
    }
    process(bar); process(metro); process(labo);
    double totalTTC = totalHT * 1.2;

    return Row(
      children: [
        Expanded(
          child: _financialCard('VALEUR HT', totalHT, LucideIcons.database, [const Color(0xFF6366F1), const Color(0xFF4F46E5)]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _financialCard('VALEUR TTC', totalTTC, LucideIcons.coins, [const Color(0xFF10B981), const Color(0xFF059669)]),
        ),
      ],
    );
  }

  Widget _financialCard(String label, double value, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(value),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(BuildContext context, AsyncValue<List<StockSnapshot>> snapshotsAsync) {
    return snapshotsAsync.when(
      data: (snapshots) {
        if (snapshots.length < 2) return _emptyChartPlaceholder('Analyses en cours d\'accumulation...');
        final recent = snapshots.take(7).toList().reversed.toList();
        final spots = <FlSpot>[];
        for (int i = 0; i < recent.length; i++) {
          double val = 0;
          for (var it in recent[i].items) val += (it.quantity * it.priceHT);
          spots.add(FlSpot(i.toDouble(), val));
        }

        return Container(
          height: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      int i = v.toInt();
                      if (i >= 0 && i < recent.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat('dd/MM').format(recent[i].date), style: TextStyle(fontSize: 8, color: AppTheme.textSecondary.withOpacity(0.5))),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF818CF8)]),
                  barWidth: 6,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.2), AppTheme.primary.withOpacity(0.0)]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildValuePieChart(BuildContext context, AsyncValue<List<Product>> bar,
      AsyncValue<List<Product>> metro, AsyncValue<List<Product>> labo) {
    double bV = 0, mV = 0, lV = 0;
    bar.whenData((l) => l.forEach((p) => bV += p.quantity * p.priceHT));
    metro.whenData((l) => l.forEach((p) => mV += p.quantity * p.priceHT));
    labo.whenData((l) => l.forEach((p) => lV += p.quantity * p.priceHT));
    double total = bV + mV + lV;
    if (total == 0) return _emptyChartPlaceholder('Données insuffisantes.');

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 6,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(value: bV, title: 'BAR', color: AppTheme.primary, radius: 25, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
            PieChartSectionData(value: mV, title: 'METRO', color: AppTheme.accent, radius: 25, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
            PieChartSectionData(value: lV, title: 'LABO', color: Colors.orange, radius: 25, titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context, AsyncValue<List<Product>> bar,
      AsyncValue<List<Product>> metro, AsyncValue<List<Product>> labo) {
    final alerts = <Product>[];
    for (var a in [bar, metro, labo]) a.whenData((l) => alerts.addAll(l.where((p) => p.quantity <= p.minQuantity)));

    if (alerts.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Inventaire optimal ✅', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700))));

    return Column(
      children: alerts.take(5).map((p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.error.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.flame, color: AppTheme.error, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text('Alerte < ${_fmt(p.minQuantity)} ${p.unit}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(p.quantity), style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(p.unit, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.error)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) return const Center(child: Text('Aucune activité récente.'));
        final recent = logs.take(3).toList();
        return Column(
          children: [
            ...recent.map((log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 24,
                    decoration: BoxDecoration(color: _getActionColor(log.action), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      Text(log.details, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  Text(DateFormat('HH:mm').format(log.date), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
            )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ActivityScreen())),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('VOIR TOUT LE JOURNAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Erreur: $e'),
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

  Widget _emptyChartPlaceholder(String t) => Container(height: 150, decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(28)), child: Center(child: Text(t, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))));
  static String _fmt(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}
