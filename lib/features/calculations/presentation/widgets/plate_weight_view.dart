import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

enum MaterialGrade {
  carbonSteel('Carbon Steel (A36/A516)', 7850.0),
  stainless304('Stainless Steel 304 / 316', 7930.0),
  duplex2205('Duplex Stainless 2205', 7800.0),
  aluminum6061('Aluminum 6061-T6', 2700.0),
  titaniumGr2('Titanium Grade 2', 4510.0),
  copper('Pure Copper (C11000)', 8960.0),
  brass('Brass (C36000)', 8500.0);

  final String displayName;
  final double densityKgPerM3;
  const MaterialGrade(this.displayName, this.densityKgPerM3);
}

enum ShapeType {
  rectangularPlate('Rectangular Plate / Sheet'),
  circularPlate('Circular Disc / Blind Plate'),
  solidRoundBar('Solid Round Bar / Shaft'),
  hollowBox('Square / Rect Box (SHS/RHS)'),
  angleBar('Equal / Unequal Angle Bar'),
  channelSection('Structural Channel (PFC)');

  final String title;
  const ShapeType(this.title);
}

class PlateWeightView extends StatefulWidget {
  final Function(String title, Map<String, dynamic> inputs, Map<String, dynamic> results)? onSave;

  const PlateWeightView({super.key, this.onSave});

  @override
  State<PlateWeightView> createState() => _PlateWeightViewState();
}

class _PlateWeightViewState extends State<PlateWeightView> {
  MaterialGrade _selectedMaterial = MaterialGrade.carbonSteel;
  ShapeType _selectedShape = ShapeType.rectangularPlate;

  // Rect Plate Inputs
  final _lengthController = TextEditingController(text: '2400'); // mm
  final _widthController = TextEditingController(text: '1200'); // mm
  final _thicknessController = TextEditingController(text: '12.0'); // mm
  final _quantityController = TextEditingController(text: '4');

  // Circular Plate / Round Bar
  final _diameterController = TextEditingController(text: '500'); // mm
  final _barLengthController = TextEditingController(text: '6000'); // mm

  // Box / Profile Inputs
  final _boxHeightController = TextEditingController(text: '100'); // mm
  final _boxWidthController = TextEditingController(text: '100'); // mm
  final _boxWallController = TextEditingController(text: '6.0'); // mm
  final _profileLengthController = TextEditingController(text: '6000'); // mm

  // Outputs
  double _singleUnitWeightKg = 0.0;
  double _totalBatchWeightKg = 0.0;
  double _surfaceAreaM2 = 0.0;
  double _volumeM3 = 0.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    _quantityController.dispose();
    _diameterController.dispose();
    _barLengthController.dispose();
    _boxHeightController.dispose();
    _boxWidthController.dispose();
    _boxWallController.dispose();
    _profileLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final density = _selectedMaterial.densityKgPerM3;
      final qty = int.tryParse(_quantityController.text) ?? 1;

      double singleVolM3 = 0.0;
      double singleAreaM2 = 0.0;

      switch (_selectedShape) {
        case ShapeType.rectangularPlate:
          final lM = (double.tryParse(_lengthController.text) ?? 0.0) / 1000.0;
          final wM = (double.tryParse(_widthController.text) ?? 0.0) / 1000.0;
          final tM = (double.tryParse(_thicknessController.text) ?? 0.0) / 1000.0;

          singleVolM3 = lM * wM * tM;
          singleAreaM2 = lM * wM;
          break;

        case ShapeType.circularPlate:
          final dM = (double.tryParse(_diameterController.text) ?? 0.0) / 1000.0;
          final tM = (double.tryParse(_thicknessController.text) ?? 0.0) / 1000.0;
          final rM = dM / 2.0;

          singleVolM3 = math.pi * rM * rM * tM;
          singleAreaM2 = math.pi * rM * rM;
          break;

        case ShapeType.solidRoundBar:
          final dM = (double.tryParse(_diameterController.text) ?? 0.0) / 1000.0;
          final lM = (double.tryParse(_barLengthController.text) ?? 0.0) / 1000.0;
          final rM = dM / 2.0;

          singleVolM3 = math.pi * rM * rM * lM;
          singleAreaM2 = 2 * math.pi * rM * lM;
          break;

        case ShapeType.hollowBox:
          final hM = (double.tryParse(_boxHeightController.text) ?? 0.0) / 1000.0;
          final wM = (double.tryParse(_boxWidthController.text) ?? 0.0) / 1000.0;
          final tM = (double.tryParse(_boxWallController.text) ?? 0.0) / 1000.0;
          final lM = (double.tryParse(_profileLengthController.text) ?? 0.0) / 1000.0;

          final outerArea = hM * wM;
          final innerArea = math.max(0.0, (hM - 2 * tM) * (wM - 2 * tM));
          final metalArea = outerArea - innerArea;

          singleVolM3 = metalArea * lM;
          singleAreaM2 = 2 * (hM + wM) * lM;
          break;

        case ShapeType.angleBar:
          final hM = (double.tryParse(_boxHeightController.text) ?? 0.0) / 1000.0;
          final wM = (double.tryParse(_boxWidthController.text) ?? 0.0) / 1000.0;
          final tM = (double.tryParse(_boxWallController.text) ?? 0.0) / 1000.0;
          final lM = (double.tryParse(_profileLengthController.text) ?? 0.0) / 1000.0;

          final metalArea = (hM * tM) + ((wM - tM) * tM);
          singleVolM3 = metalArea * lM;
          singleAreaM2 = 2 * (hM + wM) * lM;
          break;

        case ShapeType.channelSection:
          final hM = (double.tryParse(_boxHeightController.text) ?? 0.0) / 1000.0;
          final wM = (double.tryParse(_boxWidthController.text) ?? 0.0) / 1000.0;
          final tM = (double.tryParse(_boxWallController.text) ?? 0.0) / 1000.0;
          final lM = (double.tryParse(_profileLengthController.text) ?? 0.0) / 1000.0;

          final metalArea = (hM * tM) + 2 * ((wM - tM) * tM);
          singleVolM3 = metalArea * lM;
          singleAreaM2 = (hM + 2 * wM) * lM;
          break;
      }

      _volumeM3 = singleVolM3;
      _singleUnitWeightKg = singleVolM3 * density;
      _totalBatchWeightKg = _singleUnitWeightKg * qty;
      _surfaceAreaM2 = singleAreaM2 * qty;

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
          // Material Selector Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center_rounded, color: AppColors.safetyOrange),
                const SizedBox(width: 12),
                const Text('Material Grade & Density:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<MaterialGrade>(
                  value: _selectedMaterial,
                  items: MaterialGrade.values.map((mat) {
                    return DropdownMenuItem(
                      value: mat,
                      child: Text('${mat.displayName} (${mat.densityKgPerM3.toInt()} kg/m³)', style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedMaterial = v);
                      _calculate();
                    }
                  },
                ),
                const Spacer(),
                if (widget.onSave != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('Save Plate Weight', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      widget.onSave!(
                        'Structural Weight: ${_selectedShape.title} (${_selectedMaterial.name})',
                        {
                          'shape': _selectedShape.name,
                          'material': _selectedMaterial.displayName,
                          'quantity': _quantityController.text,
                        },
                        {
                          'singleWeightKg': _singleUnitWeightKg.toStringAsFixed(2),
                          'totalBatchWeightKg': _totalBatchWeightKg.toStringAsFixed(2),
                          'totalWeightTons': (_totalBatchWeightKg / 1000).toStringAsFixed(3),
                          'totalAreaM2': _surfaceAreaM2.toStringAsFixed(2),
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weight calculation saved!')),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shape Selector Dropdown & Form
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shape and Dimensions Form
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
                      const Text('Cross-Section Geometry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ShapeType>(
                        value: _selectedShape,
                        decoration: InputDecoration(
                          labelText: 'Profile / Plate Type',
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ShapeType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.title))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedShape = v);
                            _calculate();
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dynamic Fields
                      if (_selectedShape == ShapeType.rectangularPlate) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Length (mm)', controller: _lengthController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Width (mm)', controller: _widthController, onChanged: (_) => _calculate())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'Plate Thickness (mm)', controller: _thicknessController, onChanged: (_) => _calculate()),
                      ] else if (_selectedShape == ShapeType.circularPlate) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Diameter (mm)', controller: _diameterController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Plate Thickness (mm)', controller: _thicknessController, onChanged: (_) => _calculate())),
                          ],
                        ),
                      ] else if (_selectedShape == ShapeType.solidRoundBar) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Bar Diameter (mm)', controller: _diameterController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Bar Length (mm)', controller: _barLengthController, onChanged: (_) => _calculate())),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Section Height H (mm)', controller: _boxHeightController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Section Width W (mm)', controller: _boxWidthController, onChanged: (_) => _calculate())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Wall Thickness (mm)', controller: _boxWallController, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Length (mm)', controller: _profileLengthController, onChanged: (_) => _calculate())),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),
                      _buildInputField(
                        label: 'Quantity (Pcs)',
                        controller: _quantityController,
                        onChanged: (_) => _calculate(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Weight Output Dashboard
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
                      const Text('Weight Sizing Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricBox(
                              title: 'Single Piece Weight',
                              value: '${_singleUnitWeightKg.toStringAsFixed(2)} kg',
                              subtitle: '(${(_singleUnitWeightKg * 2.20462).toStringAsFixed(2)} lbs)',
                              accentColor: AppColors.primaryLight,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricBox(
                              title: 'Total Batch Weight',
                              value: '${_totalBatchWeightKg.toStringAsFixed(2)} kg',
                              subtitle: '= ${(_totalBatchWeightKg / 1000).toStringAsFixed(3)} Metric Tons',
                              accentColor: AppColors.safetyOrange,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildDetailRow('Material Selected:', _selectedMaterial.displayName),
                      _buildDetailRow('Density Constant:', '${_selectedMaterial.densityKgPerM3.toInt()} kg/m³'),
                      _buildDetailRow('Single Piece Volume:', '${(_volumeM3 * 1000).toStringAsFixed(3)} Liters (${_volumeM3.toStringAsFixed(5)} m³)'),
                      _buildDetailRow('Total Surface Area (Coating/Painting):', '${_surfaceAreaM2.toStringAsFixed(2)} m² (${(_surfaceAreaM2 * 10.7639).toStringAsFixed(1)} sq ft)'),
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

  Widget _buildMetricBox({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
