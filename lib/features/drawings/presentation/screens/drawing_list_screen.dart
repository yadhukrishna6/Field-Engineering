import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/drawing.dart';
import '../../domain/models/drawing_type.dart';
import '../controllers/drawings_controller.dart';
import '../widgets/drawing_import_modal.dart';

class DrawingListScreen extends ConsumerStatefulWidget {
  final String? projectName;

  const DrawingListScreen({
    super.key,
    this.projectName,
  });

  @override
  ConsumerState<DrawingListScreen> createState() => _DrawingListScreenState();
}

class _DrawingListScreenState extends ConsumerState<DrawingListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(allDrawingsNotifierProvider);
    final title = widget.projectName ?? 'Daleel Oil Field';

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
              context.go('/projects');
            }
          },
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
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
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Upload Blueprint (PDF & Image)',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const DrawingImportModal(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Drawings (24)'),
            Tab(text: 'Issues (12)'),
            Tab(text: 'Inspections (8)'),
            Tab(text: 'Equipment (56)'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Drawings List (Screen 3)
            _buildDrawingsTab(context, isDark, state.drawings),

            // Tab 2: Issues Quick Tab
            _buildIssuesRedirect(context),

            // Tab 3: Inspections Quick Tab
            _buildInspectionsRedirect(context),

            // Tab 4: Equipment Quick Tab
            _buildEquipmentRedirect(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingsTab(BuildContext context, bool isDark, List<Drawing> drawings) {
    final sampleDrawings = drawings.isNotEmpty
        ? drawings
        : [
            Drawing(
              id: 'dwg-p-402',
              projectId: 'prj-001',
              drawingNumber: 'P-102 - Hook-up Isometric',
              title: 'Crude Separation Train Hook-Up Isometric',
              drawingType: DrawingType.isometric,
              revision: 'Rev 02',
              filePath: 'assets/sample_drawings/isometric_sample.pdf',
              pageCount: 3,
              fileSize: 9017753, // ~8.6 MB
              downloaded: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Drawing(
              id: 'dwg-p-101',
              projectId: 'prj-001',
              drawingNumber: 'P-101 - Piping Plan',
              title: 'General Area Piping Layout & Elevation',
              drawingType: DrawingType.piping,
              revision: 'Rev 03',
              filePath: 'assets/sample_drawings/piping_sample.pdf',
              pageCount: 4,
              fileSize: 13002342, // ~12.4 MB
              downloaded: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Drawing(
              id: 'dwg-p-103',
              projectId: 'prj-001',
              drawingNumber: 'P-103 - P&ID',
              title: 'Process & Instrumentation Diagram - Flare Header',
              drawingType: DrawingType.pid,
              revision: 'Rev 05',
              filePath: 'assets/sample_drawings/pid_drawing_sample.pdf',
              pageCount: 2,
              fileSize: 6501171, // ~6.2 MB
              downloaded: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Drawing(
              id: 'dwg-s-101',
              projectId: 'prj-001',
              drawingNumber: 'S-101 - Structural Plan',
              title: 'Pipe Rack Support Structural Foundation',
              drawingType: DrawingType.structural,
              revision: 'Rev 01',
              filePath: 'assets/sample_drawings/structural_sample.pdf',
              pageCount: 5,
              fileSize: 10590617, // ~10.1 MB
              downloaded: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];

    return Column(
      children: [
        // Search & Filter input bar
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
                hintText: 'Search drawings...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                  onPressed: () {},
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // Drawings List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: sampleDrawings.length,
            itemBuilder: (context, index) {
              final drawing = sampleDrawings[index];
              return _buildDrawingCard(context, isDark, drawing);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingCard(BuildContext context, bool isDark, Drawing drawing) {
    final sizeMb = (drawing.fileSize / (1024 * 1024)).toStringAsFixed(1);
    final isDownloaded = drawing.downloaded;
    final filePath = drawing.filePath.toLowerCase();
    final isImage = filePath.endsWith('.png') ||
        filePath.endsWith('.jpg') ||
        filePath.endsWith('.jpeg') ||
        filePath.endsWith('.webp') ||
        filePath.endsWith('.bmp') ||
        filePath.endsWith('.tif') ||
        filePath.endsWith('.tiff');
    final formatLabel = isImage ? 'IMAGE' : 'PDF';
    final hasLocalImage = isImage && !kIsWeb && File(drawing.filePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/drawings/${drawing.id}/view');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Drawing Vector / Blueprint Thumbnail
              Container(
                width: 68,
                height: 68,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: isImage && drawing.filePath.startsWith('data:image')
                    ? Image.network(
                        drawing.filePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_rounded,
                            color: Color(0xFF2563EB),
                            size: 32,
                          ),
                        ),
                      )
                    : (hasLocalImage
                        ? Image.file(
                            File(drawing.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                drawing.drawingType.icon,
                                color: const Color(0xFF2563EB),
                                size: 32,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              isImage ? Icons.image_rounded : drawing.drawingType.icon,
                              color: const Color(0xFF2563EB),
                              size: 32,
                            ),
                          )),
              ),
              const SizedBox(width: 14),

              // Title & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drawing.drawingNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${drawing.revision}  |  $formatLabel  |  $sizeMb MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Download status badge
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
                      const Row(
                        children: [
                          Icon(Icons.cloud_download_outlined, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Not Downloaded',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Trailing chevron
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesRedirect(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.report_problem_rounded),
        label: const Text('Open Project Punch List (12 Issues)'),
        onPressed: () => context.push('/issues'),
      ),
    );
  }

  Widget _buildInspectionsRedirect(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.checklist_rounded),
        label: const Text('Open Inspections (8 Checklists)'),
        onPressed: () => context.push('/inspections'),
      ),
    );
  }

  Widget _buildEquipmentRedirect(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.precision_manufacturing_rounded),
        label: const Text('Open Equipment Master (56 Items)'),
        onPressed: () => context.push('/equipment'),
      ),
    );
  }
}
