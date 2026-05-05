import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_generator.dart';
import 'dashboard_screen.dart';
import '../screens/history_screen.dart';
import 'admin_screen.dart' as admin_screen;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0; // 0 = Inventaire, 1 = Historique
  bool _isSearchVisible = false;

  @override
  Widget build(BuildContext context) {
    final currentRestaurant = ref.watch(currentRestaurantProvider);
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _selectedTab == 0
                  ? _InventoryTab(
                      currentRestaurant: currentRestaurant,
                      onUserTap: () => _showUserMenu(context, user),
                      onRestaurantTap: user?.role == 'admin' ? () => _showRestaurantPicker(context) : null,
                      isSearchVisible: _isSearchVisible,
                      onToggleSearch: () {
                        if (_isSearchVisible) {
                          ref.read(searchQueryProvider.notifier).set('');
                        }
                        setState(() => _isSearchVisible = !_isSearchVisible);
                      },
                    )
                  : _selectedTab == 1
                      ? const HistoryScreen()
                      : const DashboardScreen(),
            ),
            
            // Navigation Flottante
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingNavBar(),
            ),

            // Recherche Flottante (Glassmorphism)
            if (_isSearchVisible && _selectedTab == 0)
              _buildGlassSearch(),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0 && (user?.canCreateProducts == true)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 110),
              child: FloatingActionButton(
                heroTag: 'add_product_fab',
                onPressed: () {
                  final currentSpace = ref.read(currentSpaceProvider);
                  _showAddOrEditProductDialog(context, ref, null, currentSpace);
                },
                child: const Icon(LucideIcons.plus),
              ),
            )
          : null,
    );
  }

  Widget _buildFloatingNavBar() {
    final user = ref.watch(authProvider);
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(LucideIcons.clipboardList, 'Inventaire', _selectedTab == 0, () => setState(() => _selectedTab = 0)),
                _buildNavItem(LucideIcons.history, 'Historique', _selectedTab == 1, () {
                  if (user?.role == 'admin' || user?.canViewHistory == true) {
                    setState(() => _selectedTab = 1);
                  }
                }),
                _buildNavItem(LucideIcons.barChart3, 'Stats', _selectedTab == 2, () {
                  if (user?.role == 'admin' || user?.canViewStats == true) {
                    setState(() => _selectedTab = 2);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    final color = isSelected ? AppTheme.primary : AppTheme.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSelected ? 26 : 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGlassSearch() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GestureDetector(
          onTap: () {
            ref.read(searchQueryProvider.notifier).set('');
            setState(() => _isSearchVisible = false);
          },
          child: Container(
            color: Colors.black.withOpacity(0.1),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
            child: GestureDetector(
              onTap: () {}, // Empêche la fermeture au clic sur le container
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        prefixIcon: const Icon(LucideIcons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppTheme.background.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('RECHERCHE RAPIDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context, AppUser? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(ref.watch(themeModeProvider) == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun, color: AppTheme.primary),
              title: const Text('Mode Sombre', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: Switch(
                value: ref.watch(themeModeProvider) == ThemeMode.dark,
                onChanged: (_) {
                  ref.read(themeModeProvider.notifier).toggle();
                  HapticFeedback.mediumImpact();
                },
              ),
            ),
            const Divider(),
            if (user?.role == 'admin')
              ListTile(
                leading: const Icon(LucideIcons.shieldCheck, color: Colors.blue),
                title: const Text('Administration', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (context) => const admin_screen.AdminScreen())); },
              ),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: AppTheme.error),
              title: const Text('Déconnexion', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
              onTap: () { ref.read(authProvider.notifier).logout(); Navigator.pop(ctx); context.go('/login'); },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestaurantPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ÉTABLISSEMENTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _restaurantTile(context, 'Cathédrale', LucideIcons.building),
            const SizedBox(height: 12),
            _restaurantTile(context, 'Beaux Arts', LucideIcons.building),
          ],
        ),
      ),
    );
  }

  Widget _restaurantTile(BuildContext context, String name, IconData icon) {
    final isSelected = ref.watch(currentRestaurantProvider) == name;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
      onTap: () { ref.read(currentRestaurantProvider.notifier).setRestaurant(name); Navigator.pop(context); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      tileColor: isSelected ? AppTheme.primary.withOpacity(0.05) : null,
    );
  }
}

class _InventoryTab extends ConsumerWidget {
  final String currentRestaurant;
  final VoidCallback onUserTap;
  final VoidCallback? onRestaurantTap;
  final bool isSearchVisible;
  final VoidCallback onToggleSearch;

  const _InventoryTab({
    required this.currentRestaurant,
    required this.onUserTap,
    this.onRestaurantTap,
    required this.isSearchVisible,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSpace = ref.watch(currentSpaceProvider);
    final productsAsync = ref.watch(productsProvider(currentSpace));
    final user = ref.watch(authProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(context, ref, user),
        _buildSliverSpaceSelector(context, ref, currentSpace),
        productsAsync.when(
          data: (products) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
            sliver: _buildSliverProductsList(context, ref, products, currentSpace),
          ),
          loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
          error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Erreur: $e'))),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref, AppUser? user) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('INVENTAIRE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2)),
                if (user != null) ...[
                  const Spacer(),
                  Text(user.name.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1)),
                ],
              ],
            ),
            GestureDetector(
              onTap: onRestaurantTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentRestaurant, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  if (onRestaurantTap != null)
                    const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              'assets/images/STAS_LOGOMACA1_VECT.svg',
              fit: BoxFit.cover,
            ),
            // Dégradé pour la lisibilité
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withOpacity(0.7),
                    AppTheme.primary.withOpacity(0.95),
                  ],
                ),
              ),
            ),
            // Petit rappel de l'icône package en filigrane
            Positioned(
              right: -20,
              top: -20,
              child: Icon(LucideIcons.package, size: 120, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            final currentSpace = ref.read(currentSpaceProvider);
            final products = ref.read(productsProvider(currentSpace)).value ?? [];
            await PdfGenerator.generateAndShareInventory(
              products,
              label: 'Inventaire ${currentSpace.name.toUpperCase()}',
              restaurantName: currentRestaurant,
              createdBy: user?.name ?? 'Anonyme',
            );
          },
          icon: const Icon(LucideIcons.fileDown, color: Colors.white),
        ),
        IconButton(onPressed: onToggleSearch, icon: const Icon(LucideIcons.search, color: Colors.white)),
        IconButton(onPressed: onUserTap, icon: const Icon(LucideIcons.user, color: Colors.white)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSliverSpaceSelector(BuildContext context, WidgetRef ref, SpaceType currentSpace) {
    final counts = ref.watch(spaceCountsProvider).value ?? {};
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverSpaceSelectorDelegate(
        child: Container(
          height: 70,
          color: AppTheme.primary,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _spaceChip(ref, 'Bar', SpaceType.bar, currentSpace == SpaceType.bar, counts[SpaceType.bar] ?? 0),
                const SizedBox(width: 8),
                _spaceChip(ref, 'Métro', SpaceType.metro, currentSpace == SpaceType.metro, counts[SpaceType.metro] ?? 0),
                const SizedBox(width: 8),
                _spaceChip(ref, 'Labo', SpaceType.labo, currentSpace == SpaceType.labo, counts[SpaceType.labo] ?? 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _spaceChip(WidgetRef ref, String label, SpaceType type, bool isSelected, int count) {
    return Expanded(
      child: GestureDetector(
        onTap: () { ref.read(currentSpaceProvider.notifier).setSpace(type); HapticFeedback.lightImpact(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Theme.of(ref.context).cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isSelected ? Colors.white24 : AppTheme.background, borderRadius: BorderRadius.circular(6)),
                child: Text(count.toString(), style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverProductsList(BuildContext context, WidgetRef ref, List<Product> products, SpaceType currentSpace) {
    if (products.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text('Aucun article trouvé'))));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return _StaggeredProductItem(
            index: index,
            product: product,
            currentSpace: currentSpace,
          );
        },
        childCount: products.length,
      ),
    );
  }
}

class _StaggeredProductItem extends ConsumerStatefulWidget {
  final int index;
  final Product product;
  final SpaceType currentSpace;

  const _StaggeredProductItem({required this.index, required this.product, required this.currentSpace});

  @override
  ConsumerState<_StaggeredProductItem> createState() => _StaggeredProductItemState();
}

class _StaggeredProductItemState extends ConsumerState<_StaggeredProductItem> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLowStock = widget.product.quantity <= widget.product.minQuantity;

    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
        child: Dismissible(
          key: ValueKey(widget.product.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              _showAddOrEditProductDialog(context, ref, widget.product, widget.currentSpace);
              return false;
            } else {
              final confirm = await _showDeleteConfirm(context, ref, widget.product);
              if (confirm == true) { await ref.read(inventoryNotifierProvider.notifier).deleteProduct(widget.product.id); return true; }
              return false;
            }
          },
          background: _swipeBg(LucideIcons.pencil, Colors.amber, Alignment.centerLeft),
          secondaryBackground: _swipeBg(LucideIcons.trash2, AppTheme.error, Alignment.centerRight),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildProductIcon(isLowStock),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                      const SizedBox(height: 12),
                      _PulsingStockBar(product: widget.product, isLowStock: isLowStock),
                    ],
                  )),
                  const SizedBox(width: 12),
                  _buildQuantityController(context, ref, widget.product),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductIcon(bool isLowStock) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(color: isLowStock ? AppTheme.error.withOpacity(0.1) : AppTheme.background.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
      child: widget.product.imagePath != null
          ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(widget.product.imagePath!), fit: BoxFit.cover))
          : Icon(isLowStock ? LucideIcons.flame : LucideIcons.package, color: isLowStock ? AppTheme.error : AppTheme.primary, size: 24),
    );
  }

  Widget _swipeBg(IconData icon, Color color, Alignment align) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.8), borderRadius: BorderRadius.circular(25)),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _PulsingStockBar extends StatefulWidget {
  final Product product;
  final bool isLowStock;
  const _PulsingStockBar({required this.product, required this.isLowStock});

  @override
  State<_PulsingStockBar> createState() => _PulsingStockBarState();
}

class _PulsingStockBarState extends State<_PulsingStockBar> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.product.quantity / (widget.product.minQuantity * 2 + 1)).clamp(0.05, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stock actuel', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textSecondary.withOpacity(0.6))),
            Text('${_fmt(widget.product.quantity)} / ${_fmt(widget.product.minQuantity)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: widget.isLowStock ? AppTheme.error : AppTheme.primary)),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final pulseVal = widget.isLowStock ? (0.6 + (_pulse.value * 0.4)) : 1.0;
            return Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      (widget.isLowStock ? AppTheme.error : AppTheme.primary).withOpacity(pulseVal),
                      (widget.isLowStock ? AppTheme.error : AppTheme.primary).withOpacity(pulseVal * 0.7),
                    ]),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: widget.isLowStock ? [BoxShadow(color: AppTheme.error.withOpacity(0.3 * _pulse.value), blurRadius: 6)] : [],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SliverSpaceSelectorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverSpaceSelectorDelegate({required this.child});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant _SliverSpaceSelectorDelegate oldDelegate) => true;
}

// ── Fonctions utilitaires partagées ──────────────────────────────────────────

String _fmt(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

void _showAddOrEditProductDialog(BuildContext context, WidgetRef ref, Product? product, SpaceType currentSpace) {
  final isEditing = product != null;
  final nameCtrl = TextEditingController(text: product?.name ?? '');
  final minQtyCtrl = TextEditingController(text: product != null ? _fmt(product.minQuantity) : '10');
  final unitCtrl = TextEditingController(text: product?.unit ?? 'Unité');
  final priceHTCtrl = TextEditingController(text: product != null ? _fmt(product.priceHT) : '0');
  final priceTTCCtrl = TextEditingController(text: product != null ? _fmt(product.priceHT * 1.2) : '0');
  String? currentImagePath = product?.imagePath;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(isEditing ? "Modifier l'article" : 'Nouvel article', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                  if (image != null) setDialogState(() => currentImagePath = image.path);
                },
                child: Container(
                  height: 120, width: double.infinity,
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
                  child: currentImagePath != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(File(currentImagePath!), fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.camera, size: 30, color: AppTheme.textSecondary), Text('Ajouter une photo', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary))]),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom"), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: minQtyCtrl, decoration: const InputDecoration(labelText: 'Alerte'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unité'))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: priceHTCtrl, decoration: const InputDecoration(labelText: 'Prix HT (€)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) {
                    final clean = v.replaceAll(',', '.').trim();
                    if (clean.isEmpty) return;
                    final ht = double.tryParse(clean);
                    if (ht != null) {
                      priceTTCCtrl.text = _fmt(ht * 1.2);
                    }
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: priceTTCCtrl, decoration: const InputDecoration(labelText: 'Prix TTC (€)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) {
                    final clean = v.replaceAll(',', '.').trim();
                    if (clean.isEmpty) return;
                    final ttc = double.tryParse(clean);
                    if (ttc != null) {
                      priceHTCtrl.text = _fmt(ttc / 1.2);
                    }
                  })),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final p = Product(
                  id: product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  quantity: product?.quantity ?? 0,
                  minQuantity: double.tryParse(minQtyCtrl.text.replaceAll(',', '.')) ?? 10,
                  priceHT: double.tryParse(priceHTCtrl.text.replaceAll(',', '.')) ?? 0,
                  unit: unitCtrl.text,
                  space: currentSpace,
                  imagePath: currentImagePath,
                  restaurant: ref.read(currentRestaurantProvider),
                );
                if (isEditing) ref.read(inventoryNotifierProvider.notifier).updateProduct(p);
                else ref.read(inventoryNotifierProvider.notifier).addProduct(p);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuantityController(BuildContext context, WidgetRef ref, Product product) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _qtyBtn(LucideIcons.minus, () {
        ref.read(inventoryNotifierProvider.notifier).updateQuantity(product.id, product.quantity - 1);
        HapticFeedback.lightImpact();
      }),
      GestureDetector(
        onTap: () => _showPreciseQuantityDialog(context, ref, product),
        child: Container(
          width: 50,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_fmt(product.quantity), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text(product.unit, style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
      _qtyBtn(LucideIcons.plus, () {
        ref.read(inventoryNotifierProvider.notifier).updateQuantity(product.id, product.quantity + 1);
        HapticFeedback.mediumImpact();
      }, isPrimary: true),
    ],
  );
}

Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: isPrimary ? AppTheme.primary : AppTheme.background, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 16, color: isPrimary ? Colors.white : AppTheme.textPrimary),
    ),
  );
}

void _showPreciseQuantityDialog(BuildContext context, WidgetRef ref, Product product) {
  final ctrl = TextEditingController(text: _fmt(product.quantity));
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Quantité exacte'),
      content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, decoration: InputDecoration(suffixText: product.unit)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(onPressed: () {
          final q = double.tryParse(ctrl.text.replaceAll(',', '.'));
          if (q != null) ref.read(inventoryNotifierProvider.notifier).updateQuantity(product.id, q);
          Navigator.pop(ctx);
        }, child: const Text('Valider')),
      ],
    ),
  );
}

Future<bool?> _showDeleteConfirm(BuildContext context, WidgetRef ref, Product product) {
  return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Supprimer ?'),
    content: Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
    ],
  ));
}
