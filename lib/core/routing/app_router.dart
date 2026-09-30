import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/pin_login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/projects/presentation/screens/project_details_screen.dart';
import '../../features/drawings/presentation/screens/drawing_list_screen.dart';
import '../../features/drawings/presentation/screens/drawing_details_screen.dart';
import '../../features/drawings/presentation/screens/revision_comparison_screen.dart';
import '../../features/drawings/domain/models/drawing.dart';
import '../../features/drawings/domain/models/drawing_type.dart';
import '../../features/issues/presentation/screens/issues_screen.dart';
import '../../features/inspections/presentation/screens/inspections_screen.dart';
import '../../features/inspections/presentation/screens/inspection_details_screen.dart';
import '../../features/equipment/presentation/screens/equipment_screen.dart';
import '../../features/equipment/presentation/screens/qr_scanner_screen.dart';
import '../../features/offline_manager/presentation/screens/offline_download_manager_screen.dart';
import '../../features/offline_manager/presentation/screens/offline_data_screen.dart';
import '../../features/calculations/presentation/screens/calculations_screen.dart';
import '../../features/takeoff/presentation/screens/takeoff_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/sync/presentation/screens/sync_center_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/diagnostics_screen.dart';
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

    // 4. Drawing Revision Comparison View
    GoRoute(
      path: '/drawings/:id/compare',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final drawingId = state.pathParameters['id'] ?? '';
        final extraDrawing = state.extra as Drawing?;
        final drawing = extraDrawing ??
            Drawing(
              id: drawingId,
              projectId: 'prj-001',
              drawingNumber: 'DWG-P-402-01',
              title: 'High Pressure Separation Piping P&ID',
              drawingType: DrawingType.pid,
              revision: 'Rev 01',
              filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
              pageCount: 1,
              fileSize: 204800,
              downloaded: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
        return RevisionComparisonScreen(drawing: drawing);
      },
    ),

    // 5. Inspection Details / Interactive Checklist Fullscreen View
    GoRoute(
      path: '/inspections/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final inspectionId = state.pathParameters['id'] ?? '';
        return InspectionDetailsScreen(inspectionId: inspectionId);
      },
    ),

    // 6. QR / Barcode Fullscreen Scanner
    GoRoute(
      path: '/qr-scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EquipmentQrScannerScreen(),
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
        // Dashboard
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),

        // Project List
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final projectId = state.pathParameters['id'] ?? '';
                return ProjectDetailsScreen(projectId: projectId);
              },
            ),
          ],
        ),

        // Drawing List
        GoRoute(
          path: '/drawings',
          builder: (context, state) => const DrawingListScreen(),
        ),

        // Phase 4: Field Issues & Punch List
        GoRoute(
          path: '/issues',
          builder: (context, state) => const IssuesScreen(),
        ),

        // Phase 4: Field Inspections
        GoRoute(
          path: '/inspections',
          builder: (context, state) => const InspectionsScreen(),
        ),

        // Phase 4: Equipment Master
        GoRoute(
          path: '/equipment',
          builder: (context, state) => const EquipmentScreen(),
        ),

        // Phase 5: Sync Center & Cloud Bridge
        GoRoute(
          path: '/sync',
          builder: (context, state) => const SyncCenterScreen(),
        ),

        // Engineering Calculators
        GoRoute(
          path: '/calculations',
          builder: (context, state) => const CalculationsScreen(),
        ),

        // Material Takeoff & Bill of Materials (MTO / BOM)
        GoRoute(
          path: '/takeoff',
          builder: (context, state) => const TakeoffScreen(),
        ),

        // Offline Download Manager
        GoRoute(
          path: '/offline-downloads',
          builder: (context, state) => const OfflineDownloadManagerScreen(),
        ),

        // Offline Data & Cache Inspector
        GoRoute(
          path: '/offline-data',
          builder: (context, state) => const OfflineDataScreen(),
        ),

        // Phase 6: Diagnostics & Database Health
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const DiagnosticsScreen(),
        ),

        // Field Reports Generator
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        // Settings
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
