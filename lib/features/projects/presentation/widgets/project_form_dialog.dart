import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../controllers/projects_controller.dart';
import '../../../../core/theme/color_palette.dart';

class ProjectFormDialog extends ConsumerStatefulWidget {
  final Project? existingProject;

  const ProjectFormDialog({super.key, this.existingProject});

  @override
  ConsumerState<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _clientController;
  late TextEditingController _locationController;
  late ProjectStatus _status;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _numberController = TextEditingController(text: p?.projectNumber ?? 'EPC-2026-${(100 + DateTime.now().millisecond % 900)}');
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _clientController = TextEditingController(text: p?.client ?? '');
    _locationController = TextEditingController(text: p?.location ?? '');
    _status = p?.status ?? ProjectStatus.active;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _clientController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.existingProject != null;
    final project = Project(
      id: widget.existingProject?.id ?? const Uuid().v4(),
      projectNumber: _numberController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      client: _clientController.text.trim(),
      location: _locationController.text.trim(),
      status: _status,
      createdAt: widget.existingProject?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      await ref.read(projectsListNotifierProvider.notifier).updateProject(project);
    } else {
      await ref.read(projectsListNotifierProvider.notifier).createProject(project);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProject != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEdit ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                            color: AppColors.safetyOrange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Field Project' : 'Create New Field Project',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _numberController,
                          decoration: const InputDecoration(
                            labelText: 'Project Number *',
                            hintText: 'e.g. EPC-2026-084',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<ProjectStatus>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: ProjectStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(s.icon, color: s.badgeColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(s.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Project Facility / Package Name *',
                      hintText: 'e.g. Al-Khafji Gas Compression Station',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clientController,
                          decoration: const InputDecoration(
                            labelText: 'Client / Operator *',
                            hintText: 'e.g. Saudi Aramco / ADNOC',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Field Site Location *',
                            hintText: 'e.g. Neutral Zone / Offshore Block 4',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Project Scope & Engineering Description',
                      hintText: 'Field inspection scope, high pressure piping lines, vessel inspection tags...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(isEdit ? 'Update Project' : 'Create Project'),
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
