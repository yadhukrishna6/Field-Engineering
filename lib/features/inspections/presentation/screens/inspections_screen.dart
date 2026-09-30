import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/field_gps_service.dart';
import '../../domain/models/inspection.dart';
import '../../../projects/domain/models/project.dart';

class InspectionsScreen extends ConsumerStatefulWidget {
  const InspectionsScreen({super.key});

  @override
  ConsumerState<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends ConsumerState<InspectionsScreen> {
  String _selectedProjectId = '';
  List<Project> _projects = [];
  List<Inspection> _inspections = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projectsRepo = ref.read(projectsRepositoryProvider);
    final inspectionsRepo = ref.read(inspectionsRepositoryProvider);

    final projects = await projectsRepo.getProjects();
    final defaultProjId = projects.isNotEmpty ? projects.first.id : '';

    List<Inspection> list = [];
    if (defaultProjId.isNotEmpty) {
      list = await inspectionsRepo.getInspectionsByProject(defaultProjId);
    } else {
      list = await inspectionsRepo.getAllInspections();
    }

    if (mounted) {
      setState(() {
        _projects = projects;
        _selectedProjectId = defaultProjId;
        _inspections = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshInspections() async {
    final inspectionsRepo = ref.read(inspectionsRepositoryProvider);
    List<Inspection> list = [];
    if (_selectedProjectId.isNotEmpty) {
      list = await inspectionsRepo.getInspectionsByProject(_selectedProjectId);
    } else {
      list = await inspectionsRepo.getAllInspections();
    }
    if (mounted) {
      setState(() => _inspections = list);
    }
  }

  void _showNewInspectionDialog() {
    final router = GoRouter.of(context);
    String title = 'Piping Line Pre-Commissioning QC';
    String templateType = 'Piping';
    String inspectorName = 'Lead QC Inspector';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDlgState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.checklist_rounded, color: AppColors.safetyOrange),
                  SizedBox(width: 10),
                  Text('New Field Inspection Checklist'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Inspection Title',
                        hintText: 'e.g. Unit 102 Piping Hydrotest QC',
                      ),
                      controller: TextEditingController(text: title),
                      onChanged: (v) => title = v,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: templateType,
                      decoration: const InputDecoration(labelText: 'Inspection Standard Template'),
                      items: const [
                        DropdownMenuItem(value: 'Piping', child: Text('Piping Inspection (10 Items)')),
                        DropdownMenuItem(value: 'Mechanical', child: Text('Mechanical / Rotary Equipment (9 Items)')),
                        DropdownMenuItem(value: 'Electrical', child: Text('Electrical & Power Quality (7 Items)')),
                        DropdownMenuItem(value: 'Civil', child: Text('Civil & Structural QC (7 Items)')),
                        DropdownMenuItem(value: 'Safety', child: Text('HSE & Field Safety Audit (7 Items)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDlgState(() => templateType = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Lead Inspector Name',
                      ),
                      controller: TextEditingController(text: inspectorName),
                      onChanged: (v) => inspectorName = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final id = _uuid.v4();
                    final gps = await FieldGpsService.instance.getCurrentPosition();

                    final items = Inspection.createTemplateItems(
                      inspectionId: id,
                      templateType: templateType,
                    );

                    final newInspection = Inspection(
                      id: id,
                      projectId: _selectedProjectId.isNotEmpty
                          ? _selectedProjectId
                          : (_projects.isNotEmpty ? _projects.first.id : 'PRJ-101'),
                      title: title,
                      inspectionType: templateType,
                      status: InspectionStatus.inProgress,
                      inspectorName: inspectorName,
                      inspectionDate: DateTime.now(),
                      latitude: gps.latitude,
                      longitude: gps.longitude,
                      items: items,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await ref.read(inspectionsRepositoryProvider).saveInspection(newInspection);
                    await _refreshInspections();

                    if (mounted) {
                      router.push('/inspections/${newInspection.id}');
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Create & Start Inspection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Control Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProjectId.isNotEmpty ? _selectedProjectId : null,
                            hint: const Text('Select Project'),
                            items: _projects.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.projectNumber} - ${p.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedProjectId = val);
                                _refreshInspections();
                              }
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showNewInspectionDialog,
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('New Inspection Checklist'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safetyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header Title
                  const Text(
                    'Field Inspection Checklists & QC Verification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '100% offline configurable QA/QC checklists, digital signatures & PDF certificate generation',
                    style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                  ),
                  const SizedBox(height: 16),

                  // Inspections Grid / List
                  Expanded(
                    child: _inspections.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.checklist_rounded, size: 54, color: isDark ? Colors.white24 : Colors.black26),
                                const SizedBox(height: 12),
                                const Text('No inspection checklists yet'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _showNewInspectionDialog,
                                  child: const Text('Create First Inspection'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _inspections.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final item = _inspections[idx];
                              return _buildInspectionCard(item, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInspectionCard(Inspection item, bool isDark) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final progress = item.completionPercentage;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await context.push('/inspections/${item.id}');
          _refreshInspections();
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.safetyOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.safetyOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Type: ${item.inspectionType} • Inspector: ${item.inspectorName} • Date: ${dateFormat.format(item.inspectionDate)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status == InspectionStatus.approved
                          ? Colors.green.withOpacity(0.15)
                          : AppColors.safetyOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.status == InspectionStatus.approved ? Colors.green : AppColors.safetyOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Checklist Score Pills
              Row(
                children: [
                  _buildScorePill('PASS', item.passCount, Colors.green),
                  const SizedBox(width: 8),
                  _buildScorePill('FAIL', item.failCount, Colors.redAccent),
                  const SizedBox(width: 8),
                  _buildScorePill('PENDING', item.pendingCount, Colors.orangeAccent),
                  const SizedBox(width: 8),
                  _buildScorePill('N/A', item.naCount, Colors.grey),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}% Completed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: isDark ? Colors.black26 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.failCount > 0 ? Colors.redAccent : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScorePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
