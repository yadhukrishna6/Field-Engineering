import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/models/drawing_file.dart';
import '../../domain/models/field_change_item.dart';
import '../../domain/utils/change_list_csv_exporter.dart';

class ChangeListSheet extends StatefulWidget {
  final DrawingFile drawing;
  final List<AnnotationItem> annotations;
  final bool isOutdoor;
  final bool isDark;
  final ValueChanged<FieldChangeItem>? onSelectChange;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportCsv;

  const ChangeListSheet({
    super.key,
    required this.drawing,
    required this.annotations,
    required this.isOutdoor,
    required this.isDark,
    this.onSelectChange,
    this.onExportPdf,
    this.onExportCsv,
  });

  static Future<void> show(
    BuildContext context, {
    required DrawingFile drawing,
    required List<AnnotationItem> annotations,
    required bool isOutdoor,
    required bool isDark,
    ValueChanged<FieldChangeItem>? onSelectChange,
    VoidCallback? onExportPdf,
    VoidCallback? onExportCsv,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ChangeListSheet(
          drawing: drawing,
          annotations: annotations,
          isOutdoor: isOutdoor,
          isDark: isDark,
          onSelectChange: onSelectChange,
          onExportPdf: onExportPdf,
          onExportCsv: onExportCsv,
        ),
      ),
    );
  }

  @override
  State<ChangeListSheet> createState() => _ChangeListSheetState();
}

class _ChangeListSheetState extends State<ChangeListSheet> {
  String _selectedFilter = 'ALL';
  late List<FieldChangeItem> _allChanges;

  @override
  void initState() {
    super.initState();
    _allChanges = FieldChangeItem.extractChanges(widget.annotations);
  }

  List<FieldChangeItem> get _filteredChanges {
    if (_selectedFilter == 'ALL') return _allChanges;
    return _allChanges.where((c) => c.changeType == _selectedFilter).toList();
  }

  Color _getBadgeColor(String type) {
    switch (type) {
      case 'DELETE':
        return const Color(0xFFD03A33);
      case 'ADD':
        return const Color(0xFF08605B);
      case 'REPLACE':
        return const Color(0xFFC25E00);
      case 'VERIFY':
        return const Color(0xFF185FA5);
      case 'PHOTO':
        return const Color(0xFF283593);
      case 'STAMP':
        return const Color(0xFF4A148C);
      default:
        return const Color(0xFF455A64);
    }
  }

  void _copySummaryToClipboard() {
    final summary = ChangeListCsvExporter.generateSummaryMarkdown(
      drawing: widget.drawing,
      changes: _allChanges,
    );
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Executive change summary copied to clipboard!'),
        backgroundColor: Color(0xFF08605B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isOutdoor
        ? AppColors.outdoorSurface
        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = widget.isOutdoor
        ? AppColors.outdoorText
        : (widget.isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = widget.isOutdoor
        ? AppColors.outdoorOutline
        : (widget.isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final primaryColor = widget.isOutdoor
        ? AppColors.outdoorPrimary
        : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    final distinctTypes = ['ALL', ..._allChanges.map((c) => c.changeType).toSet()];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: outlineColor, width: widget.isOutdoor ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Structured Change List (${_allChanges.length} Items)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text(
                          'DWG: ${widget.drawing.drawingNumber ?? widget.drawing.name} | REV: ${widget.drawing.revision ?? "REV 0"}',
                          style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: distinctTypes.map((type) {
                final isSel = _selectedFilter == type;
                final count = type == 'ALL' ? _allChanges.length : _allChanges.where((c) => c.changeType == type).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text('$type ($count)'),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedFilter = type),
                    selectedColor: primaryColor.withOpacity(0.2),
                    backgroundColor: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? primaryColor : textColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Table Content
          Expanded(
            child: _filteredChanges.isEmpty
                ? Center(
                    child: Text(
                      'No change items found for filter "$_selectedFilter"',
                      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredChanges.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredChanges[index];
                      final badgeColor = _getBadgeColor(item.changeType);

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSelectChange?.call(item);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Callout Number Badge
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '#${item.itemNumber}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: badgeColor.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            item.changeType,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                          ),
                                        ),
                                        if (item.attachedTag != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '🔗 ${item.attachedTag}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00695C),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Text(
                                          'Sheet ${item.pageNumber}',
                                          style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'By: ${item.author} | ${item.timestamp.toString().substring(0, 16)}',
                                          style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.5)),
                                        ),
                                        if (item.gps != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '📍 ${item.gps!.lat.toStringAsFixed(4)}°, ${item.gps!.lng.toStringAsFixed(4)}°',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF08605B), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Quick Export Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: outlineColor)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.copy_all_rounded, size: 16),
                  label: const Text('Copy Summary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _copySummaryToClipboard,
                ),
                const Spacer(),
                if (widget.onExportCsv != null) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E88E5),
                      side: const BorderSide(color: Color(0xFF1E88E5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: widget.onExportCsv,
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.onExportPdf != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Export Redline PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: widget.onExportPdf,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
