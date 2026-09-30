import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/models/takeoff_item.dart';
import '../controllers/takeoff_controller.dart';
import '../widgets/takeoff_item_dialog.dart';

class TakeoffScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final String? drawingId;

  const TakeoffScreen({
    super.key,
    this.projectId,
    this.drawingId,
  });

  @override
  ConsumerState<TakeoffScreen> createState() => _TakeoffScreenState();
}

class _TakeoffScreenState extends ConsumerState<TakeoffScreen> {
  String _searchQuery = '';
  TakeoffItemType? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(takeoffControllerProvider.notifier).loadItems(
            projectId: widget.projectId,
            drawingId: widget.drawingId,
          );
    });
  }

  void _openAddItemDialog() {
    TakeoffItemDialog.show(
      context,
      defaultProjectId: widget.projectId ?? 'proj-default',
      defaultDrawingId: widget.drawingId,
      onSave: (item) {
        ref.read(takeoffControllerProvider.notifier).addItem(
              projectId: item.projectId,
              drawingId: item.drawingId,
              pageNumber: item.pageNumber,
              itemType: item.itemType,
              itemName: item.itemName,
              specification: item.specification,
              size: item.size,
              quantity: item.quantity,
              unit: item.unit,
              unitWeightKg: item.unitWeightKg,
              unitCost: item.unitCost,
              notes: item.notes,
              linkedCountTag: item.linkedCountTag,
            );
      },
    );
  }

  void _openEditItemDialog(TakeoffItem item) {
    TakeoffItemDialog.show(
      context,
      existingItem: item,
      defaultProjectId: item.projectId,
      defaultDrawingId: item.drawingId,
      defaultPageNumber: item.pageNumber,
      onSave: (updated) {
        ref.read(takeoffControllerProvider.notifier).updateItem(updated);
      },
    );
  }

  void _confirmDelete(TakeoffItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Takeoff Item'),
        content: Text('Are you sure you want to remove "${item.itemName}" from the Bill of Materials?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(takeoffControllerProvider.notifier).deleteItem(item.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(takeoffControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = state.items.where((item) {
      if (_selectedCategory != null && item.itemType != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = item.itemName.toLowerCase().contains(q);
        final matchesSpec = (item.specification ?? '').toLowerCase().contains(q);
        final matchesSize = (item.size ?? '').toLowerCase().contains(q);
        final matchesNotes = (item.notes ?? '').toLowerCase().contains(q);
        return matchesName || matchesSpec || matchesSize || matchesNotes;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Screen Header & KPI Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MATERIAL TAKEOFF & BILL OF MATERIALS (MTO / BOM)',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.safetyOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Piping, Valves, Fittings, Structural & Equipment Takeoff',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Export CSV'),
                      onPressed: filteredItems.isEmpty ? null : () => _exportCsv(filteredItems),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Export MTO PDF'),
                      onPressed: filteredItems.isEmpty ? null : () => _exportPdf(filteredItems),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Takeoff Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openAddItemDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4 KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Line Items',
                    value: '${state.items.length}',
                    subtitle: 'Unique Components',
                    icon: Icons.format_list_bulleted_rounded,
                    color: AppColors.primaryLight,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Quantity',
                    value: '${state.totalQuantity.toStringAsFixed(1)}',
                    subtitle: 'Units Aggregated',
                    icon: Icons.inventory_rounded,
                    color: Colors.cyan,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Est. Weight',
                    value: state.totalWeightKg > 1000
                        ? '${(state.totalWeightKg / 1000).toStringAsFixed(2)} T'
                        : '${state.totalWeightKg.toStringAsFixed(1)} kg',
                    subtitle: '${state.totalWeightKg.toStringAsFixed(0)} kg total',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.safetyOrange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Total Est. Cost',
                    value: '\$${state.totalCost.toStringAsFixed(0)}',
                    subtitle: '${state.items.where((i) => i.unitCost > 0).length} priced items',
                    icon: Icons.monetization_on_outlined,
                    color: AppColors.online,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Search and Category Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items by name, specification, size, tag, or notes...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('All (${state.items.length})'),
                      selected: _selectedCategory == null,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: _selectedCategory == null ? Colors.white : null,
                        fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = null),
                    ),
                  ),
                  ...TakeoffItemType.values.map((type) {
                    final isSelected = _selectedCategory == type;
                    final count = state.countByType[type] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        avatar: Icon(type.icon, size: 14, color: isSelected ? Colors.white : type.color),
                        label: Text('${type.displayName} ($count)', style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: type.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = type),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Material Takeoff Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.playlist_add_check_circle_outlined, size: 60, color: Colors.grey.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  state.items.isEmpty
                                      ? 'No takeoff items added yet.'
                                      : 'No items match the selected category/search.',
                                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Item'),
                                  onPressed: _openAddItemDialog,
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                    isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Item Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Spec / Standard', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Size / Rating', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Unit Wt', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Total Wt', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Unit Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Notes / Tag', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filteredItems.map((item) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(item.itemType.icon, size: 16, color: item.itemType.color),
                                              const SizedBox(width: 6),
                                              Text(item.itemType.displayName, style: TextStyle(color: item.itemType.color, fontWeight: FontWeight.w600, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        DataCell(Text(item.specification ?? '—', style: const TextStyle(fontSize: 12))),
                                        DataCell(Text(item.size ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                        DataCell(
                                          Text(
                                            item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight),
                                          ),
                                        ),
                                        DataCell(Text(item.unit, style: const TextStyle(fontSize: 12))),
                                        DataCell(Text(item.unitWeightKg > 0 ? '${item.unitWeightKg.toStringAsFixed(1)} kg' : '—', style: const TextStyle(fontSize: 12))),
                                        DataCell(Text(item.totalWeightKg > 0 ? '${item.totalWeightKg.toStringAsFixed(1)} kg' : '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                        DataCell(Text(item.unitCost > 0 ? '\$${item.unitCost.toStringAsFixed(2)}' : '—', style: const TextStyle(fontSize: 12))),
                                        DataCell(Text(item.totalCost > 0 ? '\$${item.totalCost.toStringAsFixed(2)}' : '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.online))),
                                        DataCell(
                                          Text(
                                            item.notes ?? (item.linkedCountTag != null ? 'Tag: ${item.linkedCountTag}' : '—'),
                                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                tooltip: 'Edit Item',
                                                onPressed: () => _openEditItemDialog(item),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                                tooltip: 'Delete Item',
                                                onPressed: () => _confirmDelete(item),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(List<TakeoffItem> items) async {
    final pdf = pw.Document();

    final totalQty = items.fold(0.0, (sum, i) => sum + i.quantity);
    final totalWt = items.fold(0.0, (sum, i) => sum + i.totalWeightKg);
    final totalCost = items.fold(0.0, (sum, i) => sum + i.totalCost);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey400))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('FIELD ENGINEERING PLATFORM — MATERIAL TAKEOFF (MTO / BOM)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} | Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            text: 'Bill of Materials & Material Takeoff Summary',
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Items: ${items.length} | Total Qty: ${totalQty.toStringAsFixed(1)} | Total Weight: ${totalWt.toStringAsFixed(1)} kg | Total Cost: \$${totalCost.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['#', 'Category', 'Item Description', 'Specification', 'Size', 'Qty', 'Unit', 'Unit Wt', 'Total Wt', 'Cost', 'Notes'],
            data: items.asMap().entries.map((e) {
              final idx = e.key + 1;
              final i = e.value;
              return [
                '$idx',
                i.itemType.displayName,
                i.itemName,
                i.specification ?? '—',
                i.size ?? '—',
                i.quantity.toStringAsFixed(i.quantity % 1 == 0 ? 0 : 2),
                i.unit,
                i.unitWeightKg > 0 ? '${i.unitWeightKg.toStringAsFixed(1)} kg' : '—',
                i.totalWeightKg > 0 ? '${i.totalWeightKg.toStringAsFixed(1)} kg' : '—',
                i.totalCost > 0 ? '\$${i.totalCost.toStringAsFixed(2)}' : '—',
                i.notes ?? '—',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.topLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportCsv(List<TakeoffItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Category,Item Name,Specification,Size,Quantity,Unit,Unit Weight (kg),Total Weight (kg),Unit Cost (\$),Total Cost (\$),Notes');

    for (final i in items) {
      final line = [
        '"${i.itemType.displayName}"',
        '"${i.itemName.replaceAll('"', '""')}"',
        '"${(i.specification ?? '').replaceAll('"', '""')}"',
        '"${(i.size ?? '').replaceAll('"', '""')}"',
        i.quantity,
        '"${i.unit}"',
        i.unitWeightKg,
        i.totalWeightKg,
        i.unitCost,
        i.totalCost,
        '"${(i.notes ?? '').replaceAll('"', '""')}"',
      ].join(',');
      buffer.writeln(line);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Takeoff CSV data copied to clipboard! (Ready to paste in Excel / Sheets)')),
    );
  }
}
