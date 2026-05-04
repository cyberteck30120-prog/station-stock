import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

import 'providers/providers.dart';

import 'data/migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://limqfseyczmqpcqpazxu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpbXFmc2V5Y3ptcXBjcXBhenh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MjMxMzYsImV4cCI6MjA5MzQ5OTEzNn0.9KpgDrX0afjVAM9-BLR6mDoqxNAWaDPeOs-pdPE_q2s',
  );
  
  // Migration unique des données locales vers le cloud si nécessaire
  await MigrationService().migrateIfNeeded();
  
  runApp(
    const ProviderScope(
      child: InventoryApp(),
    ),
  );
}

class InventoryApp extends ConsumerWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Station Service Stock',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
