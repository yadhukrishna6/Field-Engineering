import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/theme/color_palette.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/models/inspection.dart';
import '../../domain/models/inspection_item.dart';
import '../widgets/signature_pad_dialog.dart';
import '../../../issues/domain/models/issue.dart';
import '../../../photos/domain/models/photo_attachment.dart';
import '../../../photos/presentation/widgets/photo_attachment_grid.dart';

class InspectionDetailsScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const InspectionDetailsScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  ConsumerState<InspectionDetailsScreen> createState() => _InspectionDetailsScreenState();
}

class _InspectionDetailsScreenState extends ConsumerState<InspectionDetailsScreen> {
  Inspection? _inspection;
  List<PhotoAttachment> _photos = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadInspection();
  }

  Future<void> _loadInspection() async {
    final repo = ref.read(inspectionsRepositoryProvider);
    final photosRepo = ref.read(photosRepositoryProvider);

    final item = await repo.getInspectionById(widget.inspectionId);
    final photos = await photosRepo.getPhotosByInspection(widget.inspectionId);

    if (mounted) {
      setState(() {
        _inspection = item;
        _photos = photos;
        _isLoading = false;
      });
    }
  }

  void _updateItemStatus(InspectionItem item, ChecklistStatus newStatus) async {
    if (_inspection == null) return;
    final updatedItem = item.copyWith(status: newStatus);

    await ref.read(inspectionsRepositoryProvider).updateInspectionItem(updatedItem);

    final updatedItems = _inspection!.items.map((i) => i.id == item.id ? updatedItem : i).toList();
    setState(() {
      _inspection = _inspection!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _editItemComments(InspectionItem item) {
    final controller = TextEditingController(text: item.comments ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Comments for "${item.description}"'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter field observations, non-conformance notes or remedial actions...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = item.copyWith(comments: controller.text.trim());
              await ref.read(inspectionsRepositoryProvider).updateInspectionItem(updated);

              final updatedList = _inspection!.items.map((i) => i.id == item.id ? updated : i).toList();
              setState(() {
                _inspection = _inspection!.copyWith(items: updatedList);
              });
            },
            child: const Text('Save Comment'),
          ),
        ],
      ),
    );
  }

  void _createPunchItemFromFailure(InspectionItem item) async {
    if (_inspection == null) return;

    final issuesRepo = ref.read(issuesRepositoryProvider);
    final issue = Issue(
      id: _uuid.v4(),
      projectId: _inspection!.projectId,
      drawingId: _inspection!.drawingId,
      inspectionId: _inspection!.id,
      title: 'FAILED: ${item.description}',
      description: item.comments?.isNotEmpty == true
          ? item.comments!
          : 'Failed inspection item during ${_inspection!.inspectionType} audit: ${item.description}',
      category: IssueCategory.fromString(_inspection!.inspectionType),
      priority: IssuePriority.high,
      status: IssueStatus.open,
      createdBy: _inspection!.inspectorName,
      dueDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 3))),
      latitude: _inspection!.latitude,
      longitude: _inspection!.longitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await issuesRepo.saveIssue(issue);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Punch list item created for failed item: ${item.description}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _captureInspectorSignature() async {
    if (_inspection == null) return;
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => SignaturePadDialog(
        title: 'QC Inspector Signature',
        signatoryName: _inspection!.inspectorName,
      ),
    );

    if (path != null && mounted) {
      final updated = _inspection!.copyWith(
        inspectorSignaturePath: path,
        updatedAt: DateTime.now(),
      );
      await ref.read(inspectionsRepositoryProvider).updateInspection(updated);
      setState(() => _inspection = updated);
    }
  }

  void _captureClientSignature() async {
    if (_inspection == null) return;
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => SignaturePadDialog(
        title: 'Client / Representative Signature',
        signatoryName: 'Client Field Engineer',
      ),
    );

    if (path != null && mounted) {
      final updated = _inspection!.copyWith(
        clientSignaturePath: path,
        status: InspectionStatus.approved,
        updatedAt: DateTime.now(),
      );
      await ref.read(inspectionsRepositoryProvider).updateInspection(updated);
      setState(() => _inspection = updated);
    }
  }

  Future<void> _exportCertificatePdf() async {
    if (_inspection == null) return;

    final doc = pw.Document();
    final item = _inspection!;
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Load inspector signature image if available
    pw.MemoryImage? inspectorSigImg;
    if (item.inspectorSignaturePath != null && !kIsWeb && File(item.inspectorSignaturePath!).existsSync()) {
      inspectorSigImg = pw.MemoryImage(File(item.inspectorSignaturePath!).readAsBytesSync());
    }

    pw.MemoryImage? clientSigImg;
    if (item.clientSignaturePath != null && !kIsWeb && File(item.clientSignaturePath!).existsSync()) {
      clientSigImg = pw.MemoryImage(File(item.clientSignaturePath!).readAsBytesSync());
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Certificate Title Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey800,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('OFFICIAL FIELD INSPECTION CERTIFICATE',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('EPC Quality Assurance & Field Engineering Verification',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                    ],
                  ),
                  pw.Text(item.status.label.toUpperCase(),
                      style: pw.TextStyle(color: PdfColors.amberAccent, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Metadata Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  children: [
                    _pdfCell('Inspection Title:', item.title, bold: true),
                    _pdfCell('Inspection Type:', item.inspectionType),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Inspector Name:', item.inspectorName),
                    _pdfCell('Inspection Date:', DateFormat('yyyy-MM-dd').format(item.inspectionDate)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('GPS Coordinates:', item.latitude != null ? '${item.latitude!.toStringAsFixed(6)}°, ${item.longitude!.toStringAsFixed(6)}°' : 'Site Location'),
                    _pdfCell('Completion:', '${(item.completionPercentage * 100).toInt()}% (Pass: ${item.passCount}, Fail: ${item.failCount})'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Checklist Items Table
            pw.Text('CHECKLIST VERIFICATION ITEMS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['#', 'Inspection Item Description', 'Result', 'Comments & Notes'],
              data: item.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final it = e.value;
                return [
                  idx.toString(),
                  it.description,
                  it.status.label,
                  it.comments ?? '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),

            // Dual Signature Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Inspector
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('QC Inspector Verification', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      if (inspectorSigImg != null)
                        pw.Image(inspectorSigImg, height: 45)
                      else
                        pw.Container(height: 45, child: pw.Center(child: pw.Text('[Inspector Signed Locally]', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)))),
                      pw.Divider(height: 1),
                      pw.Text('Name: ${item.inspectorName}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Date: $nowStr', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),

                // Client / Owner Representative
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey400)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Client / Representative Acceptance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      if (clientSigImg != null)
                        pw.Image(clientSigImg, height: 45)
                      else
                        pw.Container(height: 45, child: pw.Center(child: pw.Text('[Pending Client Signature]', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)))),
                      pw.Divider(height: 1),
                      pw.Text('Status: ${item.status.label}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Date: $nowStr', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Inspection_Certificate_${item.id.substring(0, 8)}.pdf',
    );
  }

  pw.Widget _pdfCell(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || _inspection == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final item = _inspection!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${item.inspectionType} Inspection Checklist • Inspector: ${item.inspectorName}',
              style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: _exportCertificatePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Export Certificate PDF'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Bar with KPI Tiles & Signatures
            Row(
              children: [
                _buildStatBadge('PASS', item.passCount, Colors.green, isDark),
                const SizedBox(width: 12),
                _buildStatBadge('FAIL', item.failCount, Colors.redAccent, isDark),
                const SizedBox(width: 12),
                _buildStatBadge('PENDING', item.pendingCount, Colors.orangeAccent, isDark),
                const SizedBox(width: 12),
                _buildStatBadge('N/A', item.naCount, Colors.grey, isDark),
                const Spacer(),

                // Inspector Signature Action
                OutlinedButton.icon(
                  onPressed: _captureInspectorSignature,
                  icon: Icon(
                    item.inspectorSignaturePath != null ? Icons.verified : Icons.draw_rounded,
                    color: item.inspectorSignaturePath != null ? Colors.green : AppColors.safetyOrange,
                    size: 18,
                  ),
                  label: Text(item.inspectorSignaturePath != null ? 'Inspector Signed ✓' : 'Sign as Inspector'),
                ),
                const SizedBox(width: 12),

                // Client Signature Action
                ElevatedButton.icon(
                  onPressed: _captureClientSignature,
                  icon: Icon(
                    item.clientSignaturePath != null ? Icons.verified : Icons.fact_check_rounded,
                    size: 18,
                  ),
                  label: Text(item.clientSignaturePath != null ? 'Client Approved ✓' : 'Client Approval Sign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.clientSignaturePath != null ? Colors.green : AppColors.safetyOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Checklist Items Header
            const Text(
              'Inspection Checklist Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Checklist Items Table / List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: item.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final chkItem = item.items[index];
                return _buildChecklistItemCard(chkItem, index + 1, isDark);
              },
            ),
            const SizedBox(height: 24),

            // Photo Attachments Section
            PhotoAttachmentGrid(
              photos: _photos,
              inspectionId: item.id,
              onPhotoAdded: (p) async {
                await ref.read(photosRepositoryProvider).savePhoto(p);
                setState(() => _photos.add(p));
              },
              onPhotoDeleted: (photoId) async {
                await ref.read(photosRepositoryProvider).deletePhoto(photoId);
                setState(() => _photos.removeWhere((p) => p.id == photoId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(count.toString(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _buildChecklistItemCard(InspectionItem chkItem, int number, bool isDark) {
    final isFail = chkItem.status == ChecklistStatus.fail;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFail ? Colors.redAccent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isFail ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Number Tag
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chkItem.description,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (chkItem.comments != null && chkItem.comments!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Note: ${chkItem.comments}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isFail ? Colors.redAccent : AppColors.darkTextMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Status Toggle Buttons (PASS, FAIL, N/A, PENDING)
              Wrap(
                spacing: 6,
                children: [
                  _buildStatusButton(chkItem, ChecklistStatus.pass, Colors.green),
                  _buildStatusButton(chkItem, ChecklistStatus.fail, Colors.redAccent),
                  _buildStatusButton(chkItem, ChecklistStatus.na, Colors.grey),
                  _buildStatusButton(chkItem, ChecklistStatus.pending, Colors.orangeAccent),
                ],
              ),
            ],
          ),

          // Actions Row: Comment & Punch List conversion for FAIL items
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _editItemComments(chkItem),
                icon: const Icon(Icons.comment_outlined, size: 14),
                label: Text(
                  chkItem.comments != null && chkItem.comments!.isNotEmpty ? 'Edit Note' : 'Add Note',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              if (isFail) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _createPunchItemFromFailure(chkItem),
                  icon: const Icon(Icons.add_task_rounded, size: 14, color: Colors.redAccent),
                  label: const Text(
                    'Generate Punch List Item',
                    style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(InspectionItem item, ChecklistStatus status, Color color) {
    final isSelected = item.status == status;

    return InkWell(
      onTap: () => _updateItemStatus(item, status),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3)),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
