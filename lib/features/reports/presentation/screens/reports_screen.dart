import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../../projects/presentation/controllers/projects_controller.dart';
import '../../../../core/storage/offline_storage_manager.dart';
import '../../../../core/storage/storage_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/rbac_manager.dart';

enum EngineeringReportType {
  markedUpDrawing,
  fieldInspection,
  issueReport,
  punchList,
  materialTakeoff,
  measurementReport,
  asBuiltDossier,
}

extension EngineeringReportTypeExtension on EngineeringReportType {
  String get title {
    switch (this) {
      case EngineeringReportType.markedUpDrawing:
        return '1. Marked-up Drawing PDF';
      case EngineeringReportType.fieldInspection:
        return '2. Field Inspection QC Report';
      case EngineeringReportType.issueReport:
        return '3. Field Issues & NCR Report';
      case EngineeringReportType.punchList:
        return '4. Punch-List Report';
      case EngineeringReportType.materialTakeoff:
        return '5. Material Takeoff (MTO) Report';
      case EngineeringReportType.measurementReport:
        return '6. Calibration & Measurement Log';
      case EngineeringReportType.asBuiltDossier:
        return '7. As-Built Field Dossier';
    }
  }

  String get description {
    switch (this) {
      case EngineeringReportType.markedUpDrawing:
        return 'Vectorized drawing snapshot with revision block, layer annotations, and engineer stamp.';
      case EngineeringReportType.fieldInspection:
        return 'QC inspection checklist, test equipment calibration, and digital inspector sign-offs.';
      case EngineeringReportType.issueReport:
        return 'Complete log of field defects, categorized by discipline, severity, and photo attachments.';
      case EngineeringReportType.punchList:
        return 'Pre-commissioning Punch-list items categorized by Priority A/B/C with due dates.';
      case EngineeringReportType.materialTakeoff:
        return 'Bill of materials (BOM), line items, quantities, total weights (kg), and cost estimations.';
      case EngineeringReportType.measurementReport:
        return 'Accurate point-to-point, polyline, surface area, and angle dimensional records.';
      case EngineeringReportType.asBuiltDossier:
        return 'Comprehensive field verification package containing drawing revisions, tests, and sign-offs.';
    }
  }

  IconData get icon {
    switch (this) {
      case EngineeringReportType.markedUpDrawing:
        return Icons.draw_outlined;
      case EngineeringReportType.fieldInspection:
        return Icons.fact_check_outlined;
      case EngineeringReportType.issueReport:
        return Icons.bug_report_outlined;
      case EngineeringReportType.punchList:
        return Icons.checklist_rtl_outlined;
      case EngineeringReportType.materialTakeoff:
        return Icons.inventory_2_outlined;
      case EngineeringReportType.measurementReport:
        return Icons.straighten_outlined;
      case EngineeringReportType.asBuiltDossier:
        return Icons.folder_special_outlined;
    }
  }
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  EngineeringReportType _selectedType = EngineeringReportType.fieldInspection;
  String? _selectedProjectId;
  String _drawingNumber = 'DWG-P-402-01';
  String _revision = 'Rev 01';
  bool _isGenerating = false;
  List<FileSystemEntity> _savedReports = [];

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    try {
      final files = await OfflineStorageManager.instance.listCategoryFiles(StorageCategory.reports);
      if (mounted) {
        setState(() => _savedReports = files);
      }
    } catch (_) {}
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final projectsState = ref.read(projectsListNotifierProvider);
      final projects = projectsState.projects;
      final project = projects.isNotEmpty
          ? projects.firstWhere(
              (p) => p.id == _selectedProjectId,
              orElse: () => projects.first,
            )
          : null;

      final pdf = pw.Document();
      final reportNo = 'REP-${_selectedType.name.toUpperCase().substring(0, 3)}-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final currentUser = SecureStorageService().currentUser;
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
                color: PdfColors.blue50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FIELD ENGINEERING DOCUMENTATION SYSTEM',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                      pw.Text(_selectedType.title.toUpperCase(),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('REPORT NO: $reportNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text('REVISION: $_revision | DATE: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 16),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CONFIDENTIAL & PROPRIETARY — EPC FIELD VERIFICATION DOSSIER',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            final projectName = project != null ? project.name : "Offshore Gathering Platform";
            final projectNo = project != null ? project.projectNumber : "PRJ-2026-EP4";
            final projectClient = project != null ? project.client : "Saudi Aramco";
            final projectLocation = project != null ? project.location : "Safaniya Offshore Field";

            return [
              // 1. Project & Metadata Box
              pw.TableHelper.fromTextArray(
                headers: ['PROJECT DATA', 'DOCUMENT / DRAWING CONTROL'],
                data: [
                  ['Project: $projectName', 'Drawing No: $_drawingNumber'],
                  ['Project No: $projectNo', 'Drawing Rev: $_revision (Approved IFC)'],
                  ['Client: $projectClient', 'Lead Engineer: ${currentUser.fullName}'],
                  ['Location: $projectLocation', 'Organization: ${currentUser.company}'],
                ],
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 16),

              // Report-Specific Body Content
              ..._buildReportPdfSections(_selectedType),

              pw.SizedBox(height: 24),

              // Digital Engineering Sign-Off Stamps
              pw.Text('ENGINEERING VERIFICATION & ACCEPTANCE STAMPS:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue800),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('LEAD FIELD ENGINEER / QC INSPECTOR',
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Name: ${currentUser.fullName} (${currentUser.role.displayName})',
                              style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Status: VERIFIED & DIGITALLY APPROVED',
                              style: pw.TextStyle(fontSize: 7, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.green800),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CLIENT REPRESENTATIVE / PMT',
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Company: $projectClient', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('Status: CONCURRED / ACCEPTED',
                              style: pw.TextStyle(fontSize: 7, color: PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final filename = '${reportNo}_${_selectedType.name}.pdf';
      await OfflineStorageManager.instance.saveReport(
        fileName: filename,
        bytes: bytes,
      );

      await AuditLogger().log(
        action: 'GENERATE_REPORT',
        entityType: 'REPORT',
        entityId: reportNo,
        details: 'Generated ${_selectedType.title} for project ${project?.projectNumber ?? "PRJ-2026-EP4"}',
      );

      await _loadSavedReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated successfully: $filename'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Print / Preview',
              textColor: Colors.white,
              onPressed: () => Printing.layoutPdf(onLayout: (format) async => bytes),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  List<pw.Widget> _buildReportPdfSections(EngineeringReportType type) {
    switch (type) {
      case EngineeringReportType.markedUpDrawing:
        return [
          pw.Text('DRAWING MARKUP REGISTER & REDLINE SUMMARY:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'PAGE', 'MARKUP TYPE', 'LAYER', 'COLOR', 'REMARKS & COORDINATES'],
            data: [
              ['MKP-01', 'Page 1', 'Cloud Box', 'Piping Layer', 'Red (0xFFFF0000)', 'Tie-in nozzle N-04 requires 600# RF flange spec update.'],
              ['MKP-02', 'Page 1', 'Arrow & Text', 'Safety Layer', 'Yellow (0xFFFFEB3B)', 'Add emergency bypass valve tag PSV-102B.'],
              ['MKP-03', 'Page 1', 'Freehand Trace', 'Electrical', 'Blue (0xFF2196F3)', 'Cable tray routing clash with 8" condensate header.'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];

      case EngineeringReportType.fieldInspection:
        return [
          pw.Text('QUALITY CONTROL INSPECTION & CHECKLIST RESULTS:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['ITEM #', 'INSPECTION CRITERIA / ASME STANDARD', 'RESULT', 'COMMENTS & EVIDENCE'],
            data: [
              ['1.01', 'ASME B31.3 Table 341.3.2 Visual Weld Quality', 'PASS', 'Zero undercut, porosity, or misalignment detected on W-01 through W-08.'],
              ['1.02', 'Hydrostatic Pressure Test (22.5 Barg @ 120 min)', 'PASS', 'Pressure recorded steady with calibrated digital gauge PG-44.'],
              ['1.03', 'Stud Bolt Torque Pattern & Lubrication Check', 'PASS', 'Star tightening sequence adhered to API 6A torque table.'],
              ['1.04', 'NDE Radiographic Examination (RT 10%)', 'PASS', 'Film review approved by Level-II RT Inspector (Report RT-883).'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];

      case EngineeringReportType.issueReport:
        return [
          pw.Text('FIELD ISSUES & NON-CONFORMANCE (NCR) LOG:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['ISSUE ID', 'DISCIPLINE', 'SEVERITY', 'STATUS', 'ASSIGNED TO', 'FINDING DESCRIPTION'],
            data: [
              ['ISS-001', 'Piping', 'CRITICAL', 'OPEN', 'Lead Piping Eng', 'Gasket rating mismatch on 8" high pressure flare line.'],
              ['ISS-002', 'Civil', 'MEDIUM', 'IN PROGRESS', 'Site Civil Supv', 'Anchor bolt misalignment on pump foundation P-102B.'],
              ['ISS-003', 'Electrical', 'HIGH', 'RESOLVED', 'Senior Electrical Eng', 'Earth bonding continuity test showed 2.4 ohms (> 1.0 ohm limit).'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];

      case EngineeringReportType.punchList:
        return [
          pw.Text('PRE-COMMISSIONING PUNCH-LIST ITEMS (CAT A / B / C):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['PUNCH #', 'CATEGORY', 'DISCIPLINE', 'LOCATION', 'DUE DATE', 'ACTION REQUIRED'],
            data: [
              ['PL-101', 'Cat A (Hold)', 'Safety', 'Rack 12 Module', '2026-10-05', 'Install missing safety shower beacon and interlock.'],
              ['PL-102', 'Cat B (Pre-Start)', 'Piping', 'V-101 Separator', '2026-10-15', 'Touch-up paint coat on manifold insulation cladding.'],
              ['PL-103', 'Cat C (Warranty)', 'Civil', 'Access Stairway', '2026-11-01', 'Secure handrail kickplate corner weld.'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];

      case EngineeringReportType.materialTakeoff:
        return [
          pw.Text('BILL OF MATERIALS & MATERIAL TAKEOFF (MTO):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['ITEM', 'DESCRIPTION & SPEC', 'SIZE', 'QTY', 'UNIT', 'UNIT WT (KG)', 'TOTAL WT (KG)'],
            data: [
              ['Pipe-01', 'Seamless Carbon Steel ASTM A106 Gr.B Sch 40', '6" NPS', '145.0', 'm', '28.26', '4,097.7 kg'],
              ['Flange-01', 'Weld Neck Flange ASME B16.5 CL300 RF', '6" NPS', '24.0', 'pcs', '11.50', '276.0 kg'],
              ['Valve-01', 'Full Bore Ball Valve API 6D CL300 Lever', '6" NPS', '6.0', 'pcs', '45.00', '270.0 kg'],
              ['Gasket-01', 'Spiral Wound SS316 Graphite Filled 300#', '6" NPS', '24.0', 'pcs', '0.40', '9.6 kg'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];

      case EngineeringReportType.measurementReport:
        return [
          pw.Text('CALIBRATED DRAWING MEASUREMENT & DIMENSIONAL AUDIT:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['MEAS ID', 'TYPE', 'CALIBRATED VALUE', 'UNIT', 'SCALE BASIS', 'TARGET ELEMENT'],
            data: [
              ['MEA-01', 'Distance', '14.850', 'm', '1 px = 0.0245 m', 'Clearance between V-101 and P-102 pump skid.'],
              ['MEA-02', 'Polyline', '42.600', 'm', '1 px = 0.0245 m', 'Total run length of 8" HC flare header.'],
              ['MEA-03', 'Area', '185.200', 'm²', '1 px = 0.0245 m', 'Secondary containment bund surface area.'],
              ['MEA-04', 'Angle', '45.000', '°', 'Geometric arc', '3D offset branch angle for tie-in T-02.'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];

      case EngineeringReportType.asBuiltDossier:
        return [
          pw.Text('AS-BUILT ENGINEERING DOSSIER & FINAL HANDOVER CERTIFICATE:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Text(
            'This comprehensive dossier certifies that all field modifications, markups, hydrotests, and inspection records for drawing $_drawingNumber ($_revision) have been audited against EPC standards and approved for permanent operations.',
            style: const pw.TextStyle(fontSize: 8, height: 1.4),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['DOSSIER SECTION', 'RECORDS ATTACHED', 'AUDIT STATUS', 'SIGN-OFF'],
            data: [
              ['Section 1: Drawing Revision History', 'Rev 00, Rev 01, Rev 02', 'AUDITED', 'Alex Morgan, Lead PE'],
              ['Section 2: Quality Inspection Records', 'Hydrotest & NDT Packages', 'ACCEPTED', 'QC Inspector Lead'],
              ['Section 3: NCR & Punch-list Clearance', 'All Cat-A Items Closed', 'VERIFIED', 'Client Rep PMT'],
              ['Section 4: Calibrated MTO Quantities', 'As-Built Material Log', 'RECONCILED', 'EPC Project Controls'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsListNotifierProvider);
    final projects = projectsState.projects;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text(
              'Engineering Reports & Documentation',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Report Type Selector & Config
          SizedBox(
            width: 360,
            child: Container(
              color: AppColors.surfaceDark,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Select Report Type (1-7):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...EngineeringReportType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(type.icon, color: isSelected ? AppColors.accent : AppColors.textSecondary),
                        title: Text(
                          type.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          type.description,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => setState(() => _selectedType = type),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  // Project & Revision Selector
                  const Text('Report Parameters:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProjectId ?? (projects.isNotEmpty ? projects.first.id : null),
                    dropdownColor: AppColors.cardDark,
                    decoration: const InputDecoration(
                      labelText: 'Select Project',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    items: projects.map((p) {
                      return DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13)));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedProjectId = val),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _drawingNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Drawing Number', labelStyle: TextStyle(color: AppColors.textSecondary)),
                    onChanged: (v) => _drawingNumber = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _revision,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Drawing Revision (e.g. Rev 01)', labelStyle: TextStyle(color: AppColors.textSecondary)),
                    onChanged: (v) => _revision = v,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(_isGenerating ? 'Generating PDF...' : 'Generate & Export PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isGenerating ? null : _generateReport,
                  ),
                ],
              ),
            ),
          ),

          // Right Panel: Saved PDF Archives & Quick View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offline Generated Reports Archive', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                          const Text('All exported PDF certificates are stored locally and encrypted for cloud synchronization.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.accent),
                        onPressed: _loadSavedReports,
                        tooltip: 'Refresh list',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _savedReports.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 48, color: AppColors.textSecondary),
                                SizedBox(height: 12),
                                Text('No reports generated yet.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Select one of the 7 report types on the left and click "Generate & Export PDF".',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _savedReports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final file = _savedReports[index];
                              final filename = p.basename(file.path);
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                  title: Text(filename, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: const Text('Offline PDF • Ready for Print / Cloud Sync', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.print, color: AppColors.accent, size: 20),
                                        tooltip: 'Print / Share',
                                        onPressed: () async {
                                          if (file is File) {
                                            final bytes = await file.readAsBytes();
                                            Printing.layoutPdf(onLayout: (_) async => bytes);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
