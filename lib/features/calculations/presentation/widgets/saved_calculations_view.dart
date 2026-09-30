import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/models/saved_calculation.dart';
import '../controllers/calculations_controller.dart';

class SavedCalculationsView extends ConsumerStatefulWidget {
  const SavedCalculationsView({super.key});

  @override
  ConsumerState<SavedCalculationsView> createState() => _SavedCalculationsViewState();
}

class _SavedCalculationsViewState extends ConsumerState<SavedCalculationsView> {
  String _searchQuery = '';
  String _selectedType = 'ALL';

  static const List<String> _filterCategories = [
    'ALL',
    'Pipe',
    'Tank',
    'Plate',
    'Concrete',
    'Geometry',
    'Conversion',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculationsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = state.savedCalculations.where((c) {
      if (_selectedType != 'ALL') {
        if (!c.calcType.toLowerCase().contains(_selectedType.toLowerCase()) &&
            !c.title.toLowerCase().contains(_selectedType.toLowerCase())) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = c.title.toLowerCase().contains(q);
        final matchesNotes = (c.engineerNotes ?? '').toLowerCase().contains(q);
        return matchesTitle || matchesNotes;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search Header
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search saved calculations, notes or equipment tags...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Export Calculation Dossier PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: filtered.isEmpty ? null : () => _exportDossierPdf(filtered),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterCategories.map((cat) {
                final isSelected = _selectedType == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedType = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // List or Empty View
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calculate_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              state.savedCalculations.isEmpty
                                  ? 'No saved calculations yet.'
                                  : 'No calculations match your filter.',
                              style: const TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Use any calculator tab and tap "Save Calculation" to record results.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildCalculationCard(item, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationCard(SavedCalculation item, bool isDark) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.calcType.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                dateFormat.format(item.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 18),
                tooltip: 'Print Calculation Sheet',
                onPressed: () => _printSinglePdf(item),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy Results',
                onPressed: () {
                  final text = 'Calculation: ${item.title}\nResults: ${item.results.toString()}';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied calculation to clipboard!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Delete Record',
                onPressed: () => _confirmDelete(item),
              ),
            ],
          ),
          const Divider(height: 20),

          // Inputs & Results Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Inputs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Input Parameters:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.inputs.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Results
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calculated Output:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.results.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.safetyOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.safetyOrange.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.safetyOrange),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (item.engineerNotes != null && item.engineerNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Engineer Notes: ${item.engineerNotes}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(SavedCalculation item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calculation Record'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(calculationsControllerProvider.notifier).deleteCalculation(item.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _printSinglePdf(SavedCalculation item) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('FIELD ENGINEERING REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt), style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Calculation Title: ${item.title}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('Discipline / Type: ${item.calcType}', style: const pw.TextStyle(fontSize: 12)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 14),

                pw.Text('INPUT PARAMETERS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                ...item.inputs.entries.map((e) => pw.Bullet(text: '${e.key}: ${e.value}')),

                pw.SizedBox(height: 16),
                pw.Text('CALCULATED RESULTS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                ...item.results.entries.map((e) => pw.Bullet(text: '${e.key}: ${e.value}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),

                if (item.engineerNotes != null && item.engineerNotes!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text('ENGINEER NOTES', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(item.engineerNotes!, style: const pw.TextStyle(fontSize: 11)),
                ],

                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.Text('Generated locally via Field Engineering Offline Platform (Phase 3 Engine)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportDossierPdf(List<SavedCalculation> items) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey400))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('FIELD ENGINEERING DOSSIER — CALCULATION LOG', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            text: 'Engineering Calculations Summary Report',
          ),
          pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} | Total Records: ${items.length}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Title / Description', 'Calculated Key Results'],
            data: items.map((c) {
              final resStr = c.results.entries.map((e) => '${e.key}: ${e.value}').join('\n');
              return [
                DateFormat('MM-dd HH:mm').format(c.createdAt),
                c.calcType,
                c.title,
                resStr,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.topLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
