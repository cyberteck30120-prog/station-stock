import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    bool canCreateProducts = false;
    bool canViewStats = false;
    bool canViewHistory = false;
    String selectedRole = 'employe';
    String selectedRestaurant = 'Cathédrale';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Nouveau Profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de l\'employé'),
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(labelText: 'Code PIN (4 chiffres)'),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRestaurant,
                  decoration: const InputDecoration(labelText: 'Restaurant affecté', prefixIcon: Icon(LucideIcons.home)),
                  items: ['Cathédrale', 'Beaux Arts'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => selectedRestaurant = v!),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: Text('Rôle', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                      _roleRadio('employe', 'Employé', 'Accès de base', selectedRole, setDialogState, (r) => selectedRole = r),
                      _roleRadio('assistant_manager', 'Assistant Manager', 'Droits configurables', selectedRole, setDialogState, (r) => selectedRole = r),
                      _roleRadio('manager', 'Manager', 'Accès catalogue + stats', selectedRole, setDialogState, (r) {
                        selectedRole = r;
                        canCreateProducts = true;
                        canViewStats = true;
                        canViewHistory = true;
                      }),
                      _roleRadio('admin', 'Administrateur', 'Tous les droits', selectedRole, setDialogState, (r) {
                        selectedRole = r;
                        canCreateProducts = true;
                        canViewStats = true;
                        canViewHistory = true;
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _permSwitch('Peut gérer le catalogue', 'Ajouter/modifier des produits', canCreateProducts, selectedRole == 'admin' || selectedRole == 'manager' ? null : (v) => setDialogState(() => canCreateProducts = v)),
                _permSwitch('Voir les statistiques', 'Accès au dashboard', canViewStats, selectedRole == 'admin' || selectedRole == 'manager' ? null : (v) => setDialogState(() => canViewStats = v)),
                _permSwitch('Voir les relevés', 'Accès à l\'historique', canViewHistory, selectedRole == 'admin' || selectedRole == 'manager' ? null : (v) => setDialogState(() => canViewHistory = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                  final autoRights = selectedRole == 'admin' || selectedRole == 'manager';
                  final newUser = AppUser(
                    name: nameCtrl.text,
                    pin: pinCtrl.text,
                    role: selectedRole,
                    restaurant: selectedRestaurant,
                    canCreateProducts: autoRights ? true : canCreateProducts,
                    canViewStats: autoRights ? true : canViewStats,
                    canViewHistory: autoRights ? true : canViewHistory,
                  );
                  ref.read(usersProvider.notifier).addUser(newUser);
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir un nom et un PIN à 4 chiffres.')),
                  );
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(AppUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final pinCtrl = TextEditingController(text: user.pin);
    bool canCreateProducts = user.canCreateProducts;
    bool canViewStats = user.canViewStats;
    bool canViewHistory = user.canViewHistory;
    String selectedRole = user.role;
    String selectedRestaurant = user.restaurant;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Modifier le Profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de l\'employé'),
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(labelText: 'Code PIN (4 chiffres)'),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRestaurant,
                  decoration: const InputDecoration(labelText: 'Restaurant affecté', prefixIcon: Icon(LucideIcons.home)),
                  items: ['Cathédrale', 'Beaux Arts'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => selectedRestaurant = v!),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: Text('Rôle', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                       _roleRadio('employe', 'Employé', 'Accès de base', selectedRole, setDialogState, (r) => selectedRole = r),
                       _roleRadio('assistant_manager', 'Assistant Manager', 'Droits configurables', selectedRole, setDialogState, (r) => selectedRole = r),
                       _roleRadio('manager', 'Manager', 'Accès catalogue + stats', selectedRole, setDialogState, (r) {
                         selectedRole = r;
                         canCreateProducts = true;
                         canViewStats = true;
                         canViewHistory = true;
                       }),
                       _roleRadio('admin', 'Administrateur', 'Tous les droits', selectedRole, setDialogState, (r) {
                         selectedRole = r;
                         canCreateProducts = true;
                         canViewStats = true;
                         canViewHistory = true;
                       }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _permSwitch('Peut gérer le catalogue', 'Ajouter/modifier des produits', canCreateProducts,
                  selectedRole == 'admin' || selectedRole == 'manager' ? null : (v) => setDialogState(() => canCreateProducts = v)),
                _permSwitch('Voir les statistiques', 'Accès au dashboard', canViewStats,
                  selectedRole == 'admin' || selectedRole == 'manager' ? null : (v) => setDialogState(() => canViewStats = v)),
                _permSwitch('Voir les relevés', 'Accès à l\'historique', canViewHistory,
                  selectedRole == 'admin' || selectedRole == 'manager' ? null : (v) => setDialogState(() => canViewHistory = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                  final autoRights = selectedRole == 'admin' || selectedRole == 'manager';
                  final updatedUser = AppUser(
                    id: user.id,
                    name: nameCtrl.text,
                    pin: pinCtrl.text,
                    role: selectedRole,
                    restaurant: selectedRestaurant,
                    canCreateProducts: autoRights ? true : canCreateProducts,
                    canViewStats: autoRights ? true : canViewStats,
                    canViewHistory: autoRights ? true : canViewHistory,
                  );
                  ref.read(usersProvider.notifier).updateUser(updatedUser);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

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
                  Text('ADMINISTRATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2)),
                  Text('Gestion du Personnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SvgPicture.asset('assets/images/STAS_LOGOMACA1_VECT.svg', fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.primary.withOpacity(0.7), AppTheme.primary.withOpacity(0.95)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.userPlus, color: Colors.white),
                onPressed: _showAddUserDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('Aucun utilisateur trouvé.')));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _StaggeredUserItem(index: index, user: users[index], onEdit: () => _showEditUserDialog(users[index])),
                    childCount: users.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Erreur : $e')))),
          ),
        ],
      ),
    );
  }
}

class _StaggeredUserItem extends ConsumerStatefulWidget {
  final int index;
  final AppUser user;
  final VoidCallback onEdit;
  const _StaggeredUserItem({required this.index, required this.user, required this.onEdit});

  @override
  ConsumerState<_StaggeredUserItem> createState() => _StaggeredUserItemState();
}

class _StaggeredUserItemState extends ConsumerState<_StaggeredUserItem> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassmorphismContainer(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: _roleColor(user.role).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(_roleIcon(user.role), color: _roleColor(user.role), size: 24),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              subtitle: Text('PIN : ${user.pin} • ${_roleLabel(user.role)} • ${user.restaurant}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.canCreateProducts) const Icon(LucideIcons.packagePlus, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(LucideIcons.edit3, size: 20, color: AppTheme.primary), onPressed: widget.onEdit),
                  if (user.role != 'admin')
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppTheme.error, size: 20),
                      onPressed: () => _confirmDelete(context, ref, user),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer le profil de ${user.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () { ref.read(usersProvider.notifier).deleteUser(user.id); Navigator.pop(ctx); },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers rôles ─────────────────────────────────────────────────────────────

String _roleLabel(String role) {
  switch (role) {
    case 'admin':             return 'Administrateur';
    case 'manager':           return 'Manager';
    case 'assistant_manager': return 'Assistant Manager';
    default:                  return 'Employé';
  }
}

Color _roleColor(String role) {
  switch (role) {
    case 'admin':             return const Color(0xFF4F46E5); // indigo
    case 'manager':           return const Color(0xFF059669); // vert
    case 'assistant_manager': return const Color(0xFFF59E0B); // ambre
    default:                  return const Color(0xFF6B7280); // gris
  }
}

IconData _roleIcon(String role) {
  switch (role) {
    case 'admin':             return LucideIcons.shieldAlert;
    case 'manager':           return LucideIcons.briefcase;
    case 'assistant_manager': return LucideIcons.userCheck;
    default:                  return LucideIcons.user;
  }
}

Widget _roleRadio(
  String value,
  String label,
  String subtitle,
  String groupValue,
  StateSetter setDialogState,
  Function(String) onSelect,
) {
  return RadioListTile<String>(
    value: value,
    groupValue: groupValue,
    onChanged: (val) => setDialogState(() => onSelect(val!)),
    title: Text(label, style: const TextStyle(fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    activeColor: _roleColor(value),
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
  );
}

Widget _permSwitch(
  String title,
  String subtitle,
  bool value,
  Function(bool)? onChanged,
) {
  return SwitchListTile(
    title: Text(title, style: TextStyle(fontSize: 14, color: onChanged == null ? const Color(0xFF6B7280) : null)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    value: value,
    onChanged: onChanged,
    contentPadding: EdgeInsets.zero,
    activeColor: const Color(0xFF4F46E5),
    secondary: onChanged == null
        ? const Icon(LucideIcons.lock, size: 16, color: Color(0xFF6B7280))
        : null,
  );
}

