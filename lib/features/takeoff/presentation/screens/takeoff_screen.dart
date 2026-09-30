import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TakeoffScreen extends ConsumerStatefulWidget {
  final String? drawingNumber;

  const TakeoffScreen({
    super.key,
    this.drawingNumber,
  });

  @override
  ConsumerState<TakeoffScreen> createState() => _TakeoffScreenState();
}

class _TakeoffScreenState extends ConsumerState<TakeoffScreen> {
  final List<Map<String, dynamic>> _items = [
    {'item': 'Pipe (CS)', 'size': 'DN100', 'quantity': 32.5, 'unit': 'm'},
    {'item': 'Valve (Gate)', 'size': 'DN100', 'quantity': 7, 'unit': 'Nos'},
    {'item': 'Flange (RF)', 'size': 'DN100', 'quantity': 14, 'unit': 'Nos'},
    {'item': 'Elbow (90°)', 'size': 'DN100', 'quantity': 8, 'unit': 'Nos'},
    {'item': 'Tee', 'size': 'DN100', 'quantity': 4, 'unit': 'Nos'},
    {'item': 'Reducer', 'size': 'DN100x50', 'quantity': 3, 'unit': 'Nos'},
    {'item': 'Support', 'size': 'Type A', 'quantity': 12, 'unit': 'Nos'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.drawingNumber != null ? '${widget.drawingNumber} - Material Takeoff' : 'P-102 - Material Takeoff';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/drawings');
            }
          },
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _showAddItemDialog,
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                        horizontalMargin: 16,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Item',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Size/Spec',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'Quantity',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Unit',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Action',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                        rows: _items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item['item'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item['size'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${item['quantity']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item['unit'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() => _items.removeAt(idx));
                                      },
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

            // Footer Bar matching Screen 10 (Total Items: 7 & Export button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Items: ${_items.length}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('MTO exported to CSV / Excel successfully')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final itemController = TextEditingController();
    final sizeController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String unit = 'Nos';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add MTO Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Item Name (e.g. Ball Valve)')),
            TextField(controller: sizeController, decoration: const InputDecoration(labelText: 'Size / Spec (e.g. DN50 PN16)')),
            Row(
              children: [
                Expanded(child: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: unit,
                  items: ['Nos', 'm', 'kg', 'pcs', 'sets'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => unit = v);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (itemController.text.isNotEmpty) {
                setState(() {
                  _items.add({
                    'item': itemController.text,
                    'size': sizeController.text,
                    'quantity': double.tryParse(qtyController.text) ?? 1.0,
                    'unit': unit,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
