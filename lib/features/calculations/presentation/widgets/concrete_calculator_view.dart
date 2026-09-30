import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

enum ConcreteStructureType {
  slabFoundation('Slab / Equipment Pad Footing', Icons.view_quilt_rounded),
  circularColumn('Circular Pier / Column', Icons.circle_outlined),
  retainingWall('Retaining Wall / Trench', Icons.domain_rounded);

  final String title;
  final IconData icon;
  const ConcreteStructureType(this.title, this.icon);
}

enum ConcreteMixGrade {
  m15('M15 (1 : 2 : 4) - Paving & Lean Concrete', 1.0, 2.0, 4.0),
  m20('M20 (1 : 1.5 : 3) - Standard Structural RCC', 1.0, 1.5, 3.0),
  m25('M25 (1 : 1 : 2) - Heavy Foundation & Slabs', 1.0, 1.0, 2.0),
  m30('M30 (1 : 0.75 : 1.5) - High Strength Columns', 1.0, 0.75, 1.5);

  final String title;
  final double cementRatio;
  final double sandRatio;
  final double aggregateRatio;
  const ConcreteMixGrade(this.title, this.cementRatio, this.sandRatio, this.aggregateRatio);

  double get totalRatio => cementRatio + sandRatio + aggregateRatio;
}

class ConcreteCalculatorView extends StatefulWidget {
  final Function(String title, Map<String, dynamic> inputs, Map<String, dynamic> results)? onSave;

  const ConcreteCalculatorView({super.key, this.onSave});

  @override
  State<ConcreteCalculatorView> createState() => _ConcreteCalculatorViewState();
}

class _ConcreteCalculatorViewState extends State<ConcreteCalculatorView> {
  ConcreteStructureType _selectedStructure = ConcreteStructureType.slabFoundation;
  ConcreteMixGrade _selectedGrade = ConcreteMixGrade.m20;

  // Slab Inputs
  final _slabLengthController = TextEditingController(text: '8000'); // mm
  final _slabWidthController = TextEditingController(text: '5000'); // mm
  final _slabThicknessController = TextEditingController(text: '250'); // mm
  final _slabQuantityController = TextEditingController(text: '1');

  // Column Inputs
  final _colDiameterController = TextEditingController(text: '600'); // mm
  final _colHeightController = TextEditingController(text: '3500'); // mm
  final _colQuantityController = TextEditingController(text: '4');

  // Retaining Wall Inputs
  final _wallLengthController = TextEditingController(text: '12000'); // mm
  final _wallHeightController = TextEditingController(text: '2500'); // mm
  final _wallTopThickController = TextEditingController(text: '200'); // mm
  final _wallBottomThickController = TextEditingController(text: '400'); // mm

  // Wastage % (e.g. 5%)
  double _wastagePercent = 5.0;

  // Outputs
  double _wetVolumeM3 = 0.0;
  double _grossVolumeWithWastageM3 = 0.0;
  double _cementBags50kg = 0.0;
  double _sandTons = 0.0;
  double _aggregateTons = 0.0;
  double _waterLiters = 0.0;
  double _totalConcreteWeightTons = 0.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _slabLengthController.dispose();
    _slabWidthController.dispose();
    _slabThicknessController.dispose();
    _slabQuantityController.dispose();
    _colDiameterController.dispose();
    _colHeightController.dispose();
    _colQuantityController.dispose();
    _wallLengthController.dispose();
    _wallHeightController.dispose();
    _wallTopThickController.dispose();
    _wallBottomThickController.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      double netVolM3 = 0.0;

      switch (_selectedStructure) {
        case ConcreteStructureType.slabFoundation:
          final lM = (double.tryParse(_slabLengthController.text) ?? 0.0) / 1000.0;
          final wM = (double.tryParse(_slabWidthController.text) ?? 0.0) / 1000.0;
          final tM = (double.tryParse(_slabThicknessController.text) ?? 0.0) / 1000.0;
          final qty = int.tryParse(_slabQuantityController.text) ?? 1;
          netVolM3 = lM * wM * tM * qty;
          break;

        case ConcreteStructureType.circularColumn:
          final dM = (double.tryParse(_colDiameterController.text) ?? 0.0) / 1000.0;
          final hM = (double.tryParse(_colHeightController.text) ?? 0.0) / 1000.0;
          final qty = int.tryParse(_colQuantityController.text) ?? 1;
          final rM = dM / 2.0;
          netVolM3 = math.pi * rM * rM * hM * qty;
          break;

        case ConcreteStructureType.retainingWall:
          final lM = (double.tryParse(_wallLengthController.text) ?? 0.0) / 1000.0;
          final hM = (double.tryParse(_wallHeightController.text) ?? 0.0) / 1000.0;
          final topM = (double.tryParse(_wallTopThickController.text) ?? 0.0) / 1000.0;
          final btmM = (double.tryParse(_wallBottomThickController.text) ?? 0.0) / 1000.0;
          final avgThick = (topM + btmM) / 2.0;
          netVolM3 = lM * hM * avgThick;
          break;
      }

      final grossVolM3 = netVolM3 * (1.0 + _wastagePercent / 100.0);
      _wetVolumeM3 = netVolM3;
      _grossVolumeWithWastageM3 = grossVolM3;

      // Dry Volume = 1.54 * Wet Volume
      final dryVolM3 = grossVolM3 * 1.54;

      // Mix Proportion Breakdown
      final totRatio = _selectedGrade.totalRatio;
      final cementVolM3 = (dryVolM3 * _selectedGrade.cementRatio) / totRatio;
      final sandVolM3 = (dryVolM3 * _selectedGrade.sandRatio) / totRatio;
      final aggVolM3 = (dryVolM3 * _selectedGrade.aggregateRatio) / totRatio;

      // 1 m3 Cement = 1440 kg = ~28.8 bags (50kg each)
      final cementKg = cementVolM3 * 1440.0;
      _cementBags50kg = cementKg / 50.0;

      // Sand density ~ 1600 kg/m3 = 1.6 tons/m3
      _sandTons = sandVolM3 * 1.6;

      // Coarse Aggregate density ~ 1500 kg/m3 = 1.5 tons/m3
      _aggregateTons = aggVolM3 * 1.5;

      // Water calculation: W/C ~ 0.5 (25 liters per 50kg bag)
      _waterLiters = _cementBags50kg * 25.0;

      // RCC density ~ 2400 kg/m3 = 2.4 tons/m3
      _totalConcreteWeightTons = grossVolM3 * 2.4;

      setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Structure Type Selector Bar
          Row(
            children: [
              ...ConcreteStructureType.values.map((type) {
                final isSelected = _selectedStructure == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    avatar: Icon(type.icon, size: 18, color: isSelected ? Colors.white : null),
                    label: Text(type.title),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() => _selectedStructure = type);
                        _calculate();
                      }
                    },
                  ),
                );
              }),
              const Spacer(),
              if (widget.onSave != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                  label: const Text('Save Concrete Calc', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onSave!(
                      'Concrete: ${_selectedStructure.title} (${_selectedGrade.name})',
                      {
                        'structure': _selectedStructure.title,
                        'grade': _selectedGrade.title,
                        'wastagePercent': _wastagePercent,
                      },
                      {
                        'grossVolumeM3': _grossVolumeWithWastageM3.toStringAsFixed(2),
                        'cementBags50kg': _cementBags50kg.ceil(),
                        'sandTons': _sandTons.toStringAsFixed(2),
                        'aggregateTons': _aggregateTons.toStringAsFixed(2),
                        'waterLiters': _waterLiters.toStringAsFixed(0),
                        'totalWeightTons': _totalConcreteWeightTons.toStringAsFixed(2),
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Concrete calculation saved to history!')),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Two Main Columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Geometry & Grade Input Form
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Geometry Dimensions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),

                      if (_selectedStructure == ConcreteStructureType.slabFoundation) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Length (mm)', controller: _slabLengthController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Width (mm)', controller: _slabWidthController, onChanged: (_) => _calculate())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Thickness (mm)', controller: _slabThicknessController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Quantity (Pads)', controller: _slabQuantityController, onChanged: (_) => _calculate())),
                          ],
                        ),
                      ] else if (_selectedStructure == ConcreteStructureType.circularColumn) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Column Diameter (mm)', controller: _colDiameterController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Height (mm)', controller: _colHeightController, onChanged: (_) => _calculate())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'Number of Columns', controller: _colQuantityController, onChanged: (_) => _calculate()),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Wall Length (mm)', controller: _wallLengthController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Height (mm)', controller: _wallHeightController, onChanged: (_) => _calculate())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Top Thickness (mm)', controller: _wallTopThickController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Bottom Thickness (mm)', controller: _wallBottomThickController, onChanged: (_) => _calculate())),
                          ],
                        ),
                      ],

                      const Divider(height: 28),

                      // Mix Design Selector
                      const Text('Concrete Mix Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ConcreteMixGrade>(
                        value: _selectedGrade,
                        decoration: InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ConcreteMixGrade.values.map((g) => DropdownMenuItem(value: g, child: Text(g.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedGrade = v);
                            _calculate();
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Site Wastage Allowance: ${_wastagePercent.toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(
                            width: 150,
                            child: Slider(
                              value: _wastagePercent,
                              min: 0,
                              max: 20,
                              divisions: 20,
                              onChanged: (v) {
                                setState(() => _wastagePercent = v);
                                _calculate();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right: Material Takeoff Breakdown Card
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Material Bill & Batch Estimation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Volume Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Total Wet Concrete',
                              val1: '${_grossVolumeWithWastageM3.toStringAsFixed(2)} m³',
                              val2: '${(_grossVolumeWithWastageM3 * 1.30795).toStringAsFixed(2)} yd³',
                              color: AppColors.primaryLight,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Cement 50kg Bags',
                              val1: '${_cementBags50kg.ceil()} Bags',
                              val2: '${(_cementBags50kg * 50 / 1000).toStringAsFixed(2)} Tons',
                              color: AppColors.safetyOrange,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Materials Breakdown
                      _buildMaterialRow(
                        icon: Icons.grain_rounded,
                        name: 'Fine Aggregate (Sand)',
                        val: '${_sandTons.toStringAsFixed(2)} Metric Tons',
                        sub: '(${(_sandTons / 1.6).toStringAsFixed(2)} m³)',
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 8),
                      _buildMaterialRow(
                        icon: Icons.terrain_rounded,
                        name: 'Coarse Aggregate (Gravel)',
                        val: '${_aggregateTons.toStringAsFixed(2)} Metric Tons',
                        sub: '(${(_aggregateTons / 1.5).toStringAsFixed(2)} m³)',
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(height: 8),
                      _buildMaterialRow(
                        icon: Icons.water_drop_rounded,
                        name: 'Mixing Water Required',
                        val: '${_waterLiters.toStringAsFixed(0)} Liters',
                        sub: '(${(_waterLiters / 3.78541).toStringAsFixed(0)} US gal)',
                        color: Colors.cyan,
                      ),
                      const Divider(height: 24),

                      _buildDetailRow('Net Formwork Volume:', '${_wetVolumeM3.toStringAsFixed(2)} m³'),
                      _buildDetailRow('Total Poured Weight:', '${_totalConcreteWeightTons.toStringAsFixed(2)} Metric Tons'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String val1,
    required String val2,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(val1, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(val2, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMaterialRow({
    required IconData icon,
    required String name,
    required String val,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
