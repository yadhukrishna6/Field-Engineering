import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/markup/domain/models/drawing_file.dart';
import '../../features/markup/presentation/screens/home_screen.dart';
import '../../features/markup/presentation/screens/drawings_screen.dart';
import '../../features/markup/presentation/screens/drawing_detail_screen.dart';
import '../../features/markup/presentation/screens/markup_editor_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // 1. Home Screen
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // 2. Drawings List Screen
    GoRoute(
      path: '/drawings',
      name: 'drawings',
      builder: (context, state) => const DrawingsScreen(),
      routes: [
        // 3. Drawing Detail Screen
        GoRoute(
          path: ':id',
          name: 'drawing-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra as DrawingFile?;
            return DrawingDetailScreen(
              drawingId: id,
              initialDrawing: extra,
            );
          },
          routes: [
            // 4. Editor Screen
            GoRoute(
              path: 'edit',
              name: 'markup-editor',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                final extra = state.extra as DrawingFile?;
                final drawing = extra ??
                    DrawingFile(
                      id: id,
                      name: 'Drawing $id',
                      fileType: 'PDF',
                      pageCount: 1,
                      localPath: 'assets/sample_drawings/pid_drawing_sample.pdf',
                      createdAt: DateTime.now(),
                    );
                return MarkupEditorScreen(drawing: drawing);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
