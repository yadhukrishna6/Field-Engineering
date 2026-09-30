import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/field_gps_service.dart';
import '../../domain/models/issue.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../../photos/presentation/widgets/photo_attachment_grid.dart';
import '../../../voice_notes/domain/models/voice_note.dart';
import '../../../voice_notes/presentation/widgets/voice_recorder_dialog.dart';
import '../../../voice_notes/presentation/widgets/voice_player_widget.dart';

class IssueDialog extends ConsumerStatefulWidget {
  final Issue? issue;
  final String projectId;
  final String? drawingId;
  final int pageNumber;
  final double? positionX;
  final double? positionY;

  const IssueDialog({
    super.key,
    this.issue,
    required this.projectId,
    this.drawingId,
    this.pageNumber = 1,
    this.positionX,
    this.positionY,
  });

  @override
  ConsumerState<IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends ConsumerState<IssueDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _assignedController;
  late TextEditingController _dueDateController;

  late IssueCategory _category;
  late IssuePriority _priority;
  late IssueStatus _status;

  double? _latitude;
  double? _longitude;
  double? _gpsAccuracy;

  List<PhotoAttachment> _photos = [];
  List<VoiceNote> _voiceNotes = [];
  final _uuid = const Uuid();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final item = widget.issue;

    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _assignedController = TextEditingController(text: item?.assignedTo ?? '');
    _dueDateController = TextEditingController(
      text: item?.dueDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
    );

    _category = item?.category ?? IssueCategory.piping;
    _priority = item?.priority ?? IssuePriority.medium;
    _status = item?.status ?? IssueStatus.open;

    _latitude = item?.latitude;
    _longitude = item?.longitude;
    _gpsAccuracy = item?.gpsAccuracy;

    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    if (widget.issue != null) {
      final photosRepo = ref.read(photosRepositoryProvider);
      final voiceRepo = ref.read(voiceNotesRepositoryProvider);

      final photos = await photosRepo.getPhotosByIssue(widget.issue!.id);
      final voice = await voiceRepo.getVoiceNotesByIssue(widget.issue!.id);

      if (mounted) {
        setState(() {
          _photos = photos;
          _voiceNotes = voice;
          _isLoading = false;
        });
      }
    } else {
      // Auto-capture GPS fix for new issue
      final gps = await FieldGpsService.instance.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = gps.latitude;
          _longitude = gps.longitude;
          _gpsAccuracy = gps.accuracy;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _assignedController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _recordVoiceNote() async {
    final note = await showDialog<VoiceNote>(
      context: context,
      builder: (ctx) => VoiceRecorderDialog(
        issueId: widget.issue?.id,
        drawingId: widget.drawingId,
        pageNumber: widget.pageNumber,
      ),
    );

    if (note != null && mounted) {
      setState(() {
        _voiceNotes.add(note);
      });
    }
  }

  void _saveIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.issue?.id ?? _uuid.v4();
    final now = DateTime.now();

    final issue = Issue(
      id: id,
      projectId: widget.projectId,
      drawingId: widget.drawingId ?? widget.issue?.drawingId,
      pageNumber: widget.pageNumber,
      positionX: widget.positionX ?? widget.issue?.positionX,
      positionY: widget.positionY ?? widget.issue?.positionY,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      priority: _priority,
      status: _status,
      assignedTo: _assignedController.text.trim().isNotEmpty ? _assignedController.text.trim() : null,
      createdBy: widget.issue?.createdBy ?? 'Lead Field Engineer',
      dueDate: _dueDateController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      gpsAccuracy: _gpsAccuracy,
      createdAt: widget.issue?.createdAt ?? now,
      updatedAt: now,
    );

    final issuesRepo = ref.read(issuesRepositoryProvider);
    final photosRepo = ref.read(photosRepositoryProvider);
    final voiceRepo = ref.read(voiceNotesRepositoryProvider);

    await issuesRepo.saveIssue(issue);

    // Persist new photos associated with this issue
    for (final p in _photos) {
      await photosRepo.savePhoto(p.copyWith(issueId: id));
    }

    // Persist new voice notes
    for (final v in _voiceNotes) {
      await voiceRepo.saveVoiceNote(v.copyWith(issueId: id));
    }

    if (mounted) {
      Navigator.pop(context, issue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 800,
        height: 720,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _priority.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.report_problem_rounded, color: _priority.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.issue != null ? 'Edit Field Issue / Punch Item' : 'New Field Issue & Punch Pin',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              if (widget.drawingId != null)
                                Text(
                                  'Linked Drawing Page ${widget.pageNumber} ${widget.positionX != null ? "• Pin Location (X: ${(widget.positionX! * 100).toStringAsFixed(1)}%, Y: ${(widget.positionY! * 100).toStringAsFixed(1)}%)" : ""}',
                                  style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Content Scroll Area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Category Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Issue Title *',
                                      hintText: 'e.g., Flange bolt missing / Valve packing leakage',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    validator: (val) =>
                                        val == null || val.trim().isEmpty ? 'Title is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<IssueCategory>(
                                    value: _category,
                                    decoration: InputDecoration(
                                      labelText: 'Category',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: IssueCategory.values.map((cat) {
                                      return DropdownMenuItem(
                                        value: cat,
                                        child: Row(
                                          children: [
                                            Icon(cat.icon, size: 18, color: cat.color),
                                            const SizedBox(width: 8),
                                            Text(cat.label, style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _category = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Priority & Status & Assigned Row
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<IssuePriority>(
                                    value: _priority,
                                    decoration: InputDecoration(
                                      labelText: 'Priority',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: IssuePriority.values.map((pri) {
                                      return DropdownMenuItem(
                                        value: pri,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(color: pri.color, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(pri.label, style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _priority = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<IssueStatus>(
                                    value: _status,
                                    decoration: InputDecoration(
                                      labelText: 'Status Lifecycle',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    items: IssueStatus.values.map((st) {
                                      return DropdownMenuItem(
                                        value: st,
                                        child: Row(
                                          children: [
                                            Icon(st.icon, size: 16, color: st.color),
                                            const SizedBox(width: 8),
                                            Text(st.label, style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _status = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _assignedController,
                                    decoration: InputDecoration(
                                      labelText: 'Assign To',
                                      hintText: 'e.g., Piping Crew A / Lead QC',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Description Box
                            TextFormField(
                              controller: _descController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Detailed Engineering Description & Corrective Action',
                                hintText: 'Enter observation, drawing reference, specification discrepancy...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // GPS Field Coordinates Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.satellite_alt_rounded, color: Colors.greenAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _latitude != null && _longitude != null
                                          ? 'Field GPS Fix: ${_latitude!.toStringAsFixed(6)}°, ${_longitude!.toStringAsFixed(6)}° (±${_gpsAccuracy?.toStringAsFixed(1) ?? "2.5"}m)'
                                          : 'GPS Coordinates: Not captured',
                                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final fix = await FieldGpsService.instance.getCurrentPosition();
                                      setState(() {
                                        _latitude = fix.latitude;
                                        _longitude = fix.longitude;
                                        _gpsAccuracy = fix.accuracy;
                                      });
                                    },
                                    icon: const Icon(Icons.my_location_rounded, size: 16),
                                    label: const Text('Update GPS', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Photo Attachments Section
                            PhotoAttachmentGrid(
                              photos: _photos,
                              issueId: widget.issue?.id,
                              drawingId: widget.drawingId,
                              pageNumber: widget.pageNumber,
                              onPhotoAdded: (photo) {
                                setState(() => _photos.add(photo));
                              },
                              onPhotoDeleted: (photoId) {
                                setState(() => _photos.removeWhere((p) => p.id == photoId));
                              },
                            ),
                            const SizedBox(height: 16),

                            // Voice Notes Section
                            Row(
                              children: [
                                const Icon(Icons.mic_outlined, size: 18, color: AppColors.safetyOrange),
                                const SizedBox(width: 8),
                                Text(
                                  'Voice Notes (${_voiceNotes.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _recordVoiceNote,
                                  icon: const Icon(Icons.record_voice_over_outlined, size: 16),
                                  label: const Text('Record Voice', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_voiceNotes.isEmpty)
                              Text(
                                'No voice memos attached. Record hands-free audio notes directly in the field.',
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _voiceNotes.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, idx) {
                                  final note = _voiceNotes[idx];
                                  return VoicePlayerWidget(
                                    voiceNote: note,
                                    onDelete: () {
                                      setState(() => _voiceNotes.removeAt(idx));
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 24),

                    // Actions Bar
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _saveIssue,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(widget.issue != null ? 'Update Issue' : 'Create Issue & Place Pin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.safetyOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
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
