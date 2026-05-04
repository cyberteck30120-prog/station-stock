import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';

  void _handlePress(String num) {
    if (_pin.length < 4) {
      setState(() {
        _pin += num;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _handleDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final success = ref.read(authProvider.notifier).login(_pin);
    if (success) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code PIN incorrect'),
          backgroundColor: AppTheme.error,
        ),
      );
      setState(() {
        _pin = '';
      });
    }
  }

  Widget _renderDot(int index) {
    final isFilled = index < _pin.length;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isFilled ? AppTheme.primary : AppTheme.border,
          width: 2,
        ),
        color: isFilled ? AppTheme.primary : Colors.transparent,
      ),
    );
  }

  Widget _buildNumBtn(String? btn) {
    if (btn == null || btn.isEmpty) {
      return const SizedBox(width: 80, height: 80);
    }

    final isDelete = btn == 'delete';
    
    return GestureDetector(
      onTap: () {
        if (isDelete) {
          _handleDelete();
        } else {
          _handlePress(btn);
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isDelete
            ? const Icon(LucideIcons.delete, color: AppTheme.error, size: 32)
            : Text(
                btn,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if users are loaded
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppTheme.logoBackground,
      body: SafeArea(
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur : $e')),
          data: (_) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  SvgPicture.asset(
                    'assets/images/STAS_LOGOMACA1_VECT.svg',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entrez votre code PIN',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => _renderDot(index)),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        for (final row in [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          ['', '0', 'delete'],
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: row.map((btn) => _buildNumBtn(btn)).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
        ),
      ),
    );
  }
}
