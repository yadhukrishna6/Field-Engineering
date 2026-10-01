import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/field_gps_service.dart';
import '../../../../shared/widgets/app_header_bar.dart';
import '../../domain/models/equipment_item.dart';
import '../../../projects/domain/models/project.dart';
import '../../../drawings/domain/models/drawing.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  String _selectedProjectId = '';
  List<Project> _projects = [];
  List<EquipmentItem> _equipmentList = [];
  List<Drawing> _drawings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterType;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projectsRepo = ref.read(projectsRepositoryProvider);
    final eqRepo = ref.read(equipmentRepositoryProvider);
    final dwgRepo = ref.read(drawingsRepositoryProvider);

    final projects = await projectsRepo.getProjects();
    final defaultProjId = projects.isNotEmpty ? projects.first.id : '';

    List<EquipmentItem> eqList = [];
    List<Drawing> dwgList = [];

    if (defaultProjId.isNotEmpty) {
      eqList = await eqRepo.getEquipmentByProject(defaultProjId);
      dwgList = await dwgRepo.getDrawingsForProject(defaultProjId);
    } else {
      eqList = await eqRepo.getAllEquipment();
    }

    if (mounted) {
      setState(() {
        _projects = projects;
        _selectedProjectId = defaultProjId;
        _equipmentList = eqList;
        _drawings = dwgList;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEquipment() async {
    final eqRepo = ref.read(equipmentRepositoryProvider);
    List<EquipmentItem> list = [];
    if (_selectedProjectId.isNotEmpty) {
      list = await eqRepo.getEquipmentByProject(_selectedProjectId);
    } else {
      list = await eqRepo.getAllEquipment();
    }
    if (mounted) {
      setState(() => _equipmentList = list);
    }
  }

  void _showEquipmentDialog({EquipmentItem? item}) {
    final tagCtrl = TextEditingController(text: item?.tagNumber ?? '');
    final numCtrl = TextEditingController(text: item?.equipmentNumber ?? 'EQ-${DateTime.now().millisecond}');
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final locationCtrl = TextEditingController(text: item?.location ?? 'Unit 100 Area');
    final notesCtrl = TextEditingController(text: item?.notes ?? '');

    String eqType = item?.type ?? 'Pump';
    String status = item?.status ?? 'Operational';
    String? selectedDrawingId = item?.drawingId ?? (_drawings.isNotEmpty ? _drawings.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.precision_manufacturing_rounded, color: AppColors.safetyOrange),
                  const SizedBox(width: 10),
                  Text(item != null ? 'Edit Equipment Record' : 'Register Field Equipment'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tagCtrl,
                              decoration: const InputDecoration(labelText: 'Tag Number *', hintText: 'e.g., P-101A / V-204'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: numCtrl,
                              decoration: const InputDecoration(labelText: 'Equipment Number', hintText: 'e.g., EQ-1044'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Equipment Name *', hintText: 'e.g., Crude Feed Centrifugal Pump'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: eqType,
                              decoration: const InputDecoration(labelText: 'Equipment Type'),
                              items: const [
                                DropdownMenuItem(value: 'Pump', child: Text('Pump (Centrifugal/Positive)')),
                                DropdownMenuItem(value: 'Vessel', child: Text('Pressure Vessel / Column')),
                                DropdownMenuItem(value: 'Exchanger', child: Text('Heat Exchanger / Cooler')),
                                DropdownMenuItem(value: 'Compressor', child: Text('Gas Compressor')),
                                DropdownMenuItem(value: 'Tank', child: Text('Storage Tank (API 650)')),
                                DropdownMenuItem(value: 'Valve', child: Text('Control / Isolation Valve')),
                                DropdownMenuItem(value: 'Transformer', child: Text('Transformer / Switchgear')),
                                DropdownMenuItem(value: 'Turbine', child: Text('Steam / Gas Turbine')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDlgState(() => eqType = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(labelText: 'Operating Status'),
                              items: const [
                                DropdownMenuItem(value: 'Operational', child: Text('Operational')),
                                DropdownMenuItem(value: 'Under Maintenance', child: Text('Under Maintenance')),
                                DropdownMenuItem(value: 'Standby', child: Text('Standby')),
                                DropdownMenuItem(value: 'Decommissioned', child: Text('Decommissioned')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDlgState(() => status = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationCtrl,
                        decoration: const InputDecoration(labelText: 'Site Location / Plot Area', hintText: 'e.g. Unit 100 Crude Area - Bay 4'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: selectedDrawingId,
                        decoration: const InputDecoration(labelText: 'Linked P&ID / Engineering Drawing'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None (General Equipment)')),
                          ..._drawings.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.drawingNumber} - ${d.title}'))),
                        ],
                        onChanged: (v) => setDlgState(() => selectedDrawingId = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Engineering Notes & Tag Specification'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (tagCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tag Number and Equipment Name are required.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final gps = await FieldGpsService.instance.getCurrentPosition();

                    final newEq = EquipmentItem(
                      id: item?.id ?? _uuid.v4(),
                      projectId: _selectedProjectId.isNotEmpty
                          ? _selectedProjectId
                          : (_projects.isNotEmpty ? _projects.first.id : 'PRJ-101'),
                      equipmentNumber: numCtrl.text.trim(),
                      tagNumber: tagCtrl.text.trim().toUpperCase(),
                      name: nameCtrl.text.trim(),
                      type: eqType,
                      location: locationCtrl.text.trim(),
                      drawingId: selectedDrawingId,
                      notes: notesCtrl.text.trim(),
                      latitude: item?.latitude ?? gps.latitude,
                      longitude: item?.longitude ?? gps.longitude,
                      status: status,
                      createdAt: item?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await ref.read(equipmentRepositoryProvider).saveEquipment(newEq);
                    await _refreshEquipment();
                  },
                  child: Text(item != null ? 'Update Equipment' : 'Register Equipment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<EquipmentItem> get _filteredEquipment {
    return _equipmentList.where((e) {
      if (_filterType != null && e.type != _filterType) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTag = e.tagNumber.toLowerCase().contains(q);
        final matchNum = e.equipmentNumber.toLowerCase().contains(q);
        final matchName = e.name.toLowerCase().contains(q);
        final matchLoc = e.location?.toLowerCase().contains(q) ?? false;
        if (!matchTag && !matchNum && !matchName && !matchLoc) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const AppHeaderBar(
        title: 'Equipment Master & Registry',
        subtitle: 'Tag Tracking & Field P&ID Linking',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Controls Row
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
                                _refreshEquipment();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Search Box
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search by Tag Number (e.g. P-101A), name, location...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Type Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _filterType,
                            hint: const Text('All Types'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Equipment Types')),
                              DropdownMenuItem(value: 'Pump', child: Text('Pumps')),
                              DropdownMenuItem(value: 'Vessel', child: Text('Pressure Vessels')),
                              DropdownMenuItem(value: 'Exchanger', child: Text('Heat Exchangers')),
                              DropdownMenuItem(value: 'Compressor', child: Text('Compressors')),
                              DropdownMenuItem(value: 'Tank', child: Text('Storage Tanks')),
                              DropdownMenuItem(value: 'Valve', child: Text('Valves')),
                              DropdownMenuItem(value: 'Transformer', child: Text('Transformers')),
                            ],
                            onChanged: (v) => setState(() => _filterType = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Register Equipment Button
                      ElevatedButton.icon(
                        onPressed: () => _showEquipmentDialog(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Equipment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safetyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header Title
                  Row(
                    children: [
                      const Text(
                        'Equipment Master Registry',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.safetyOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_filteredEquipment.length} Registered',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.safetyOrange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Equipment Grid
                  Expanded(
                    child: _filteredEquipment.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.precision_manufacturing_outlined, size: 54, color: isDark ? Colors.white24 : Colors.black26),
                                const SizedBox(height: 12),
                                const Text('No equipment items found'),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _filteredEquipment.length,
                            itemBuilder: (context, idx) {
                              final eq = _filteredEquipment[idx];
                              return _buildEquipmentCard(eq, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEquipmentCard(EquipmentItem eq, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showEquipmentDialog(item: eq),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safetyOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.safetyOrange.withOpacity(0.4)),
                    ),
                    child: Text(
                      eq.tagNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.safetyOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    eq.equipmentNumber,
                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: eq.status == 'Operational' ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    eq.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: eq.status == 'Operational' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                eq.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.darkTextMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      eq.location ?? 'Site Location Area',
                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(eq.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  if (eq.drawingId != null)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_rounded, size: 12, color: Colors.blueAccent),
                        SizedBox(width: 3),
                        Text('P&ID Linked', style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
