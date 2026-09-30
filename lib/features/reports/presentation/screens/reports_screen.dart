import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import '../../../projects/presentation/controllers/projects_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../offline_manager/presentation/controllers/offline_controller.dart';
import '../../../../core/storage/offline_storage_manager.dart';
import '../../../../core/storage/storage_models.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/utils/formatters.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _areaController;
  late TextEditingController _summaryController;
  late TextEditingController _findingsController;
  String? _selectedProjectId;
  String _inspectionType = 'Piping Tie-In & Hydrotest Inspection';
  String _complianceStatus = 'SATISFACTORY / APPROVED';
  bool _isGeneratingReport = false;
  List<FileSystemEntity> _savedReports = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Daily Field Quality & NDT Inspection Report');
    _areaController = TextEditingController(text: 'CDU-4 Header Tie-In Area (Rack 12)');
    _summaryController = TextEditingController(text: 'Visual inspection of 6" butt-welds W-01 through W-08 and hydrotest hold for 2 hours at 22.5 bar.');
    _findingsController = TextEditingController(text: '1. All weld visual inspections conform to ASME B31.3 Table 341.3.2.\n2. Hydrostatic gauge calibration verified (Cal Date: 2026-09-15).\n3. Zero pressure drop observed across 120 min test duration.\n4. Flange bolt torques verified using star pattern.');
    _loadSavedReports();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _areaController.dispose();
    _summaryController.dispose();
    _findingsController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedReports() async {
    try {
      final files = await OfflineStorageManager.instance.listCategoryFiles(StorageCategory.reports);
      if (mounted) {
        setState(() => _savedReports = files);
      }
    } catch (_) {}
  }

  Future<void> _generatePdfReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isGeneratingReport = true);

    try {
      final settings = ref.read(settingsNotifierProvider);
      final projects = ref.read(projectsListNotifierProvider).projects;
      final project = projects.firstWhere(
        (p) => p.id == _selectedProjectId,
        orElse: () => projects.isNotEmpty ? projects.first : projects.first,
      );

      final pdf = pw.Document();
      final reportNumber = 'REP-${DateTime.now().millisecondsSinceEpoch % 100000}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Block
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FIELD ENGINEERING INSPECTION REPORT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900)),
                          pw.Text('OFFLINE GENERATED FIELD CERTIFICATE', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('REPORT NO: $reportNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('DATE: ${AppFormatters.formatDateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Project & Inspector Table
                pw.TableHelper.fromTextArray(
                  headers: ['PROJECT DATA', 'INSPECTION DATA'],
                  data: [
                    ['Project: ${project.name}', 'Inspection Type: $_inspectionType'],
                    ['Code: ${project.projectNumber}', 'Location: ${_areaController.text.trim()}'],
                    ['Client: ${project.client}', 'Inspector: ${settings.engineerName} (${settings.employeeId})'],
                    ['Site: ${project.location}', 'Company: ${settings.company}'],
                  ],
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                ),
                pw.SizedBox(height: 16),

                // Report Title & Scope
                pw.Text('SUBJECT / TITLE: ${_titleController.text.trim()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 6),
                pw.Text('EXECUTIVE SUMMARY:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text(_summaryController.text.trim(), style: const pw.TextStyle(fontSize: 8, height: 1.3)),
                pw.SizedBox(height: 14),

                // Detailed Findings
                pw.Text('INSPECTION FINDINGS & CODE COMPLIANCE (ASME / API):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Text(_findingsController.text.trim(), style: const pw.TextStyle(fontSize: 8, height: 1.4)),
                ),
                pw.SizedBox(height: 16),

                // Compliance Verdict Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green800, width: 1.5),
                    color: PdfColors.green50,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('COMPLIANCE DISPOSITION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text(_complianceStatus, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green900)),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Stamp & Sign-off
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      width: 180,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FIELD ENGINEER SIGN-OFF:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 16),
                          pw.Text(settings.engineerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          pw.Text(settings.engineerTitle, style: const pw.TextStyle(fontSize: 6)),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 180,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CLIENT QA/QC ACCEPTANCE:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 16),
                          pw.Text('CLIENT REPRESENTATIVE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          pw.Text('Signature & Date', style: const pw.TextStyle(fontSize: 6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName = 'Report_$reportNumber.pdf';
      await OfflineStorageManager.instance.saveReport(
        fileName: fileName,
        bytes: pdfBytes,
      );

      await _loadSavedReports();
      ref.read(offlineStorageNotifierProvider.notifier).refreshUsage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.online,
            content: Text('Report $fileName generated and saved to offline storage.'),
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsListNotifierProvider).projects;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Report Builder Form (Flex 5)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description_rounded, color: AppColors.safetyOrange, size: 24),
                          SizedBox(width: 10),
                          Text('Offline Field Inspection Report Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Project Selector
                      DropdownButtonFormField<String>(
                        value: _selectedProjectId ?? (projects.isNotEmpty ? projects.first.id : null),
                        decoration: const InputDecoration(labelText: 'Project Facility *'),
                        items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.projectNumber} - ${p.name}'))).toList(),
                        onChanged: (v) => setState(() => _selectedProjectId = v),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(labelText: 'Report Title *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _inspectionType,
                              decoration: const InputDecoration(labelText: 'Inspection Type'),
                              items: [
                                'Piping Tie-In & Hydrotest Inspection',
                                'NDT Radiographic & UT Examination',
                                'Welding Visual Inspection (VT)',
                                'Flange Face & Gasket Verification',
                                'Civil Foundation & Anchor Bolt Check',
                              ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _inspectionType = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(labelText: 'Plant Area / Location Tag'),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _summaryController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Executive Summary'),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _findingsController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Inspection Findings & Observations'),
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: _complianceStatus,
                        decoration: const InputDecoration(labelText: 'Compliance Disposition'),
                        items: [
                          'SATISFACTORY / APPROVED',
                          'ACCEPTED WITH MINOR PUNCHLIST',
                          'REJECTED / RE-TEST REQUIRED',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _complianceStatus = v);
                        },
                      ),
                      const SizedBox(height: 22),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.safetyOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          icon: _isGeneratingReport
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                          label: Text(_isGeneratingReport ? 'Generating Report...' : 'Generate & Export Certified PDF'),
                          onPressed: _isGeneratingReport ? null : _generatePdfReport,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Right: Saved Offline Reports Stream (Flex 3)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Exported Reports on Tablet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${_savedReports.length} saved', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_savedReports.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('No reports generated yet.')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedReports.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final file = _savedReports[index] as File;
                          final name = p.basename(file.path);
                          final length = file.existsSync() ? file.lengthSync() : 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.purpleAccent),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(StorageUsage.formatBytes(length), style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                            trailing: IconButton(
                              icon: const Icon(Icons.print_rounded, size: 18),
                              tooltip: 'Open / Print',
                              onPressed: () async {
                                final bytes = await file.readAsBytes();
                                await Printing.layoutPdf(onLayout: (format) => bytes, name: name);
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
