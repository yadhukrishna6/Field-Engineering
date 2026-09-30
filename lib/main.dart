import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'core/storage/offline_storage_manager.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Non-blocking database factory initialization
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-initialize in background without blocking UI startup
  OfflineStorageManager.instance.initialize().catchError((e) {
    debugPrint('Storage init notice: $e');
  });

  runApp(
    const ProviderScope(
      child: FieldEngineeringApp(),
    ),
  );
}

class FieldEngineeringApp extends ConsumerWidget {
  const FieldEngineeringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      title: 'Field Engineering',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
