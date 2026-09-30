import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reports = [
      {
        'title': 'Marked-up Drawing',
        'subtitle': 'Drawing with annotations',
        'icon': Icons.layers_rounded,
        'color': const Color(0xFFDC2626),
      },
      {
        'title': 'Inspection Report',
        'subtitle': 'Inspection results with photos',
        'icon': Icons.checklist_rounded,
        'color': const Color(0xFF16A34A),
      },
      {
        'title': 'Issue Report',
        'subtitle': 'Material / equipment punch list',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Measurement Report',
        'subtitle': 'Measurements & engineering calculations',
        'icon': Icons.square_foot_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'title': 'As-Built Report',
        'subtitle': 'Final modifications with digital signatures',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF7C3AED),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Generate Report',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2563EB)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            final color = r['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(r['icon'] as IconData, color: color, size: 22),
                ),
                title: Text(
                  r['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  r['subtitle'] as String,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generating ${r['title']} PDF report...')),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
