import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/models/takeoff_item.dart';

class TakeoffItemDialog extends StatefulWidget {
  final TakeoffItem? existingItem;
  final String defaultProjectId;
  final String? defaultDrawingId;
  final int defaultPageNumber;
  final Function(TakeoffItem item) onSave;

  const TakeoffItemDialog({
    super.key,
    this.existingItem,
    required this.defaultProjectId,
    this.defaultDrawingId,
    this.defaultPageNumber = 1,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    TakeoffItem? existingItem,
    required String defaultProjectId,
    String? defaultDrawingId,
    int defaultPageNumber = 1,
    required Function(TakeoffItem item) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => TakeoffItemDialog(
        existingItem: existingItem,
        defaultProjectId: defaultProjectId,
        defaultDrawingId: defaultDrawingId,
        defaultPageNumber: defaultPageNumber,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TakeoffItemDialog> createState() => _TakeoffItemDialogState();
}

class _TakeoffItemDialogState extends State<TakeoffItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TakeoffItemType _selectedType;
  late final TextEditingController _nameController;
  late final TextEditingController _specController;
  late final TextEditingController _sizeController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _weightController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;

  static const List<String> _unitPresets = ['pcs', 'm', 'ft', 'sets', 'joints', 'kg', 'tons'];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _selectedType = item?.itemType ?? TakeoffItemType.valve;
    _nameController = TextEditingController(text: item?.itemName ?? '');
    _specController = TextEditingController(text: item?.specification ?? '');
    _sizeController = TextEditingController(text: item?.size ?? '');
    _qtyController = TextEditingController(text: item != null ? item.quantity.toString() : '1');
    _unitController = TextEditingController(text: item?.unit ?? 'pcs');
    _weightController = TextEditingController(text: item != null && item.unitWeightKg > 0 ? item.unitWeightKg.toString() : '');
    _costController = TextEditingController(text: item != null && item.unitCost > 0 ? item.unitCost.toString() : '');
    _notesController = TextEditingController(text: item?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specController.dispose();
    _sizeController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _weightController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TakeoffItemType type) {
    setState(() {
      _selectedType = type;
      if (_nameController.text.isEmpty || _isDefaultName(_nameController.text)) {
        switch (type) {
          case TakeoffItemType.pipe:
            _nameController.text = 'Seamless Carbon Steel Pipe';
            _specController.text = 'ASTM A106 Gr.B / ASME B36.10';
            _sizeController.text = '6" Sch 40';
            _unitController.text = 'm';
            break;
          case TakeoffItemType.valve:
            _nameController.text = 'Ball Valve 150# RF';
            _specController.text = 'API 6D / ASME B16.34';
            _sizeController.text = '6" Class 150';
            _unitController.text = 'pcs';
            break;
          case TakeoffItemType.flange:
            _nameController.text = 'Weld Neck Flange RF';
            _specController.text = 'ASTM A105 / ASME B16.5';
            _sizeController.text = '6" 150#';
            _unitController.text = 'pcs';
            break;
          case TakeoffItemType.elbow:
            _nameController.text = '90° LR Elbow BW';
            _specController.text = 'ASTM A234 WPB / ASME B16.9';
            _sizeController.text = '6" Sch 40';
            _unitController.text = 'pcs';
            break;
          case TakeoffItemType.tee:
            _nameController.text = 'Equal Tee BW';
            _specController.text = 'ASTM A234 WPB / ASME B16.9';
            _sizeController.text = '6" Sch 40';
            _unitController.text = 'pcs';
            break;
          case TakeoffItemType.reducer:
            _nameController.text = 'Concentric Reducer BW';
            _specController.text = 'ASTM A234 WPB / ASME B16.9';
            _sizeController.text = '6" x 4" Sch 40';
            _unitController.text = 'pcs';
            break;
          case TakeoffItemType.support:
            _nameController.text = 'Clamped Pipe Shoe Support';
            _specController.text = 'Carbon Steel Galv';
            _sizeController.text = 'H=100mm for 6" Pipe';
            _unitController.text = 'sets';
            break;
          case TakeoffItemType.equipment:
            _nameController.text = 'Pressure Vessel / Separator';
            _specController.text = 'ASME Sec VIII Div 1';
            _sizeController.text = 'V-101';
            _unitController.text = 'pcs';
            break;
          case TakeoffItemType.custom:
            break;
        }
      }
    });
  }

  bool _isDefaultName(String name) {
    return [
      'Seamless Carbon Steel Pipe',
      'Ball Valve 150# RF',
      'Weld Neck Flange RF',
      '90° LR Elbow BW',
      'Equal Tee BW',
      'Concentric Reducer BW',
      'Clamped Pipe Shoe Support',
      'Pressure Vessel / Separator',
    ].contains(name);
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final isEdit = widget.existingItem != null;
      final item = TakeoffItem(
        id: isEdit ? widget.existingItem!.id : '',
        projectId: widget.existingItem?.projectId ?? widget.defaultProjectId,
        drawingId: widget.existingItem?.drawingId ?? widget.defaultDrawingId,
        pageNumber: widget.existingItem?.pageNumber ?? widget.defaultPageNumber,
        itemType: _selectedType,
        itemName: _nameController.text.trim(),
        specification: _specController.text.trim().isNotEmpty ? _specController.text.trim() : null,
        size: _sizeController.text.trim().isNotEmpty ? _sizeController.text.trim() : null,
        quantity: double.tryParse(_qtyController.text) ?? 1.0,
        unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'pcs',
        unitWeightKg: double.tryParse(_weightController.text) ?? 0.0,
        unitCost: double.tryParse(_costController.text) ?? 0.0,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        linkedCountTag: widget.existingItem?.linkedCountTag,
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(item);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existingItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedType.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_selectedType.icon, color: _selectedType.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Takeoff Item' : 'Add Material Takeoff Item',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Bill of Materials (BOM) / Piping & Equipment Takeoff',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Category Selector
              const Text('Item Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TakeoffItemType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(type.icon, size: 14, color: isSelected ? Colors.white : type.color),
                        label: Text(type.displayName, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: type.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (sel) {
                          if (sel) _onTypeChanged(type);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Form fields
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name / Description *',
                        hintText: 'e.g. 6" Ball Valve 150# RF',
                        filled: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size / Rating',
                        hintText: 'e.g. 6" NPS / 150#',
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _specController,
                      decoration: const InputDecoration(
                        labelText: 'Specification / Material Standard',
                        hintText: 'e.g. ASTM A105 / ASME B16.5',
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        filled: true,
                      ),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Valid qty' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _unitPresets.contains(_unitController.text) ? _unitController.text : _unitPresets.first,
                      decoration: const InputDecoration(labelText: 'Unit', filled: true),
                      items: _unitPresets.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _unitController.text = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Unit Weight (kg)',
                        hintText: 'Optional',
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Unit Cost (\$)',
                        hintText: 'Optional',
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Engineering Notes / Tag / Location',
                  hintText: 'e.g. Flanged RF, Gear operator, Tag HV-101',
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                    label: Text(isEdit ? 'Update Item' : 'Add to Takeoff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedType.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submit,
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
