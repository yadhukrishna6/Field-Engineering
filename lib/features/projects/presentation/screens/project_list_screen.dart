import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/projects_controller.dart';
import '../widgets/project_form_dialog.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../../../core/theme/color_palette.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0; // 0: All, 1: My Projects, 2: Offline, 3: Recent

  final List<String> _filters = ['All', 'My Projects', 'Offline', 'Recent'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(projectsListNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'Projects',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ProjectFormDialog(),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Filter Chips Row: All, My Projects, Offline, Recent
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(_filters[index]),
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => _selectedFilterIndex = index);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Projects List
            Expanded(
              child: state.isLoading && state.projects.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      children: _buildProjectCards(context, isDark, state.projects),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProjectCards(BuildContext context, bool isDark, List<Project> projects) {
    // If empty, supply sample data matching Screen 2
    final displayProjects = projects.isNotEmpty
        ? projects
        : [
            Project(
              id: 'prj-001',
              projectNumber: 'PRJ-2026-001',
              name: 'Daleel Oil Field',
              description: 'Central Processing Facility Expansion & Separation Train',
              client: 'Daleel Petroleum',
              location: 'UAE - Abu Dhabi',
              status: ProjectStatus.active,
              drawingCount: 120,
              downloadedCount: 120,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Project(
              id: 'prj-002',
              projectNumber: 'PRJ-2026-002',
              name: 'Al-Dabb\'ah Project',
              description: 'Nuclear Power Generation Auxiliary Piping',
              client: 'NPPA',
              location: 'Egypt',
              status: ProjectStatus.active,
              drawingCount: 85,
              downloadedCount: 85,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Project(
              id: 'prj-003',
              projectNumber: 'PRJ-2026-003',
              name: 'Pipeline Project',
              description: 'Cross-Country 48" Crude Transmission Line',
              client: 'Aramco',
              location: 'Saudi Arabia',
              status: ProjectStatus.active,
              drawingCount: 60,
              downloadedCount: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Project(
              id: 'prj-004',
              projectNumber: 'PRJ-2026-004',
              name: 'Plant Maintenance',
              description: 'Annual Turnaround & Flare Header Inspection',
              client: 'QatarEnergy',
              location: 'Qatar',
              status: ProjectStatus.active,
              drawingCount: 40,
              downloadedCount: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];

    return displayProjects.map((proj) {
      final isDownloaded = proj.downloadedCount > 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/drawings');
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF334155), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.factory_rounded, color: Colors.white54, size: 36),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              proj.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.more_horiz_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: isDark ? Colors.white54 : Colors.black45),
                          const SizedBox(width: 3),
                          Text(
                            proj.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stats Row: Drawings, Issues, Inspections
                      Row(
                        children: [
                          Text(
                            '${proj.drawingCount} Drawings',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '42 Issues',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '18 Inspections',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Downloaded Badge or Download Button
                      if (isDownloaded)
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'Downloaded',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      else
                        InkWell(
                          onTap: () {
                            ref.read(projectsListNotifierProvider.notifier).downloadProjectOffline(proj.id);
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_download_rounded, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Download',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
