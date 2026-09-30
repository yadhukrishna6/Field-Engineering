import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/offline_storage_manager.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/sample_data_seeder.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/color_palette.dart';
import '../../settings/presentation/controllers/settings_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Initializing offline storage engines...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/dashboard');
    });
    _initializeServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Fast non-blocking initialization
      await OfflineStorageManager.instance.initialize();
      await AppDatabase.instance.database;

      // Seed sample data in background
      final projectsRepo = ref.read(projectsRepositoryProvider);
      final drawingsRepo = ref.read(drawingsRepositoryProvider);
      final markupsRepo = ref.read(markupsRepositoryProvider);

      SampleDataSeeder.seedIfEmpty(
        projectsRepository: projectsRepo,
        drawingsRepository: drawingsRepo,
        markupsRepository: markupsRepo,
      );

      if (!mounted) return;
      final settings = ref.read(settingsNotifierProvider);
      if (settings.isPinRequired) {
        context.go('/pin-login');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Industrial Emblem
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.safetyOrange, Color(0xFFD84315)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safetyOrange.withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.architecture_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 32),

                // App Title
                const Text(
                  'FIELD ENGINEERING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Offline-First Industrial Tablet Platform',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Indicator & Subtext
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyOrange),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
