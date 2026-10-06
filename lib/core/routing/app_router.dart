import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/markup/domain/models/drawing_file.dart';
import '../../features/markup/presentation/screens/drawings_list_screen.dart';
import '../../features/markup/presentation/screens/markup_editor_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/drawings',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/drawings',
    ),
    // Screen 1: Drawings List (Home Screen)
    GoRoute(
      path: '/drawings',
      builder: (context, state) => const DrawingsListScreen(),
      routes: [
        // Screen 2: Editor
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final extra = state.extra as DrawingFile?;
            final id = state.pathParameters['id'] ?? '';
            final drawing = extra ??
                DrawingFile(
                  id: id,
                  name: 'Technical Drawing $id',
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
);
