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
import '../../features/issues/presentation/screens/issue_details_screen.dart';
import '../../features/photos/presentation/screens/photo_viewer_screen.dart';
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
import '../../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/diagnostics_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
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

    // Screen 1: Home Dashboard (Tablet Native Full-Width without Side Bar)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),

    // Screen 2: Project List
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

    // Screen 3: Drawing List
    GoRoute(
      path: '/drawings',
      builder: (context, state) => const DrawingListScreen(),
    ),

    // Screen 4 & 5: Drawing Fullscreen Details / Vector Canvas & Measurement Tools
    GoRoute(
      path: '/drawings/:id/view',
      builder: (context, state) {
        final drawingId = state.pathParameters['id'] ?? '';
        return DrawingDetailsScreen(drawingId: drawingId);
      },
    ),

    // Screen 11: Drawing Revision Comparison View
    GoRoute(
      path: '/drawings/:id/compare',
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

    // Screen 6: Field Issues & Punch List
    GoRoute(
      path: '/issues',
      builder: (context, state) => const IssuesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final issueId = state.pathParameters['id'] ?? '102';
            return IssueDetailsScreen(issueId: issueId);
          },
        ),
      ],
    ),

    // Screen 7: Photo Viewer & Gallery
    GoRoute(
      path: '/photos/:id',
      builder: (context, state) {
        final photoId = state.pathParameters['id'];
        return PhotoViewerScreen(photoId: photoId);
      },
    ),

    // Screen 8: Field Inspections & Interactive Checklist
    GoRoute(
      path: '/inspections',
      builder: (context, state) => const InspectionsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final inspectionId = state.pathParameters['id'] ?? '';
            return InspectionDetailsScreen(inspectionId: inspectionId);
          },
        ),
      ],
    ),

    // Equipment Master & QR Scanner
    GoRoute(
      path: '/equipment',
      builder: (context, state) => const EquipmentScreen(),
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const EquipmentQrScannerScreen(),
    ),

    // Screen 9: Engineering Calculators
    GoRoute(
      path: '/calculations',
      builder: (context, state) => const CalculationsScreen(),
    ),

    // Screen 10: Material Takeoff (MTO / BOM)
    GoRoute(
      path: '/takeoff',
      builder: (context, state) => const TakeoffScreen(),
    ),

    // Screen 12: Offline & Sync Center
    GoRoute(
      path: '/sync',
      builder: (context, state) => const SyncCenterScreen(),
    ),
    GoRoute(
      path: '/offline-downloads',
      builder: (context, state) => const OfflineDownloadManagerScreen(),
    ),
    GoRoute(
      path: '/offline-data',
      builder: (context, state) => const OfflineDataScreen(),
    ),

    // Screen 13: Reports & Export
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),

    // Screen 14: AI Assistant
    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) => const AiAssistantScreen(),
    ),

    // Settings & Diagnostics
    GoRoute(
      path: '/diagnostics',
      builder: (context, state) => const DiagnosticsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
