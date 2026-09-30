import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/pin_login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/projects/presentation/screens/project_details_screen.dart';
import '../../features/drawings/presentation/screens/drawing_list_screen.dart';
import '../../features/drawings/presentation/screens/drawing_details_screen.dart';
import '../../features/offline_manager/presentation/screens/offline_download_manager_screen.dart';
import '../../features/offline_manager/presentation/screens/offline_data_screen.dart';
import '../../features/calculations/presentation/screens/calculations_screen.dart';
import '../../features/takeoff/presentation/screens/takeoff_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/tablet_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // 1. Splash Screen
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // 2. Local PIN Unlock Screen
    GoRoute(
      path: '/pin-login',
      builder: (context, state) => const PinLoginScreen(),
    ),

    // 3. Drawing Fullscreen Details / Vector PDF Inspection View
    GoRoute(
      path: '/drawings/:id/view',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final drawingId = state.pathParameters['id'] ?? '';
        return DrawingDetailsScreen(drawingId: drawingId);
      },
    ),

    // Tablet Shell Route (Persistent Navigation Rail / Sidebar & Top Bar)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return TabletScaffold(
          currentPath: state.uri.toString(),
          child: child,
        );
      },
      routes: [
        // 3. Dashboard
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),

        // 4. Project List
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectListScreen(),
          routes: [
            // 5. Project Details
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final projectId = state.pathParameters['id'] ?? '';
                return ProjectDetailsScreen(projectId: projectId);
              },
            ),
          ],
        ),

        // 6. Drawing List
        GoRoute(
          path: '/drawings',
          builder: (context, state) => const DrawingListScreen(),
        ),

        // 8. Offline Download Manager
        GoRoute(
          path: '/offline-downloads',
          builder: (context, state) => const OfflineDownloadManagerScreen(),
        ),

        // 9. Offline Data & Cache Inspector
        GoRoute(
          path: '/offline-data',
          builder: (context, state) => const OfflineDataScreen(),
        ),

        // Field Engineering Calculations
        GoRoute(
          path: '/calculations',
          builder: (context, state) => const CalculationsScreen(),
        ),

        // Material Takeoff & Bill of Materials (MTO / BOM)
        GoRoute(
          path: '/takeoff',
          builder: (context, state) => const TakeoffScreen(),
        ),

        // Field Reports Generator
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        // 10. Settings
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
