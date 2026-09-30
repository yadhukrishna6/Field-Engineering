import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

enum TankType {
  verticalCylinder('Vertical Cylinder', Icons.view_column_rounded),
  horizontalCylinder('Horizontal Cylinder', Icons.reorder_rounded),
  rectangular('Rectangular / Pit', Icons.crop_din_rounded);

  final String title;
  final IconData icon;
  const TankType(this.title, this.icon);
}

enum HeadType {
  flat('Flat Ends (0% add)'),
  ellipsoidal2to1('2:1 Semi-Ellipsoidal Heads'),
  torispherical('ASME F&D Torispherical Heads');

  final String title;
  const HeadType(this.title);
}

class TankCalculatorView extends StatefulWidget {
  final Function(String title, Map<String, dynamic> inputs, Map<String, dynamic> results)? onSave;

  const TankCalculatorView({super.key, this.onSave});

  @override
  State<TankCalculatorView> createState() => _TankCalculatorViewState();
}

class _TankCalculatorViewState extends State<TankCalculatorView> {
  TankType _selectedType = TankType.verticalCylinder;
  HeadType _selectedHead = HeadType.ellipsoidal2to1;

  // Vertical & Horizontal Cylinder Inputs
  final _diameterController = TextEditingController(text: '3000'); // mm
  final _heightLengthController = TextEditingController(text: '6000'); // mm
  final _dipLevelController = TextEditingController(text: '2000'); // mm

  // Rectangular Inputs
  final _lengthController = TextEditingController(text: '4000'); // mm
  final _widthController = TextEditingController(text: '3000'); // mm
  final _rectHeightController = TextEditingController(text: '2500'); // mm

  // Output Values
  double _totalVolumeM3 = 0.0;
  double _filledVolumeM3 = 0.0;
  double _ullageM3 = 0.0;
  double _percentFull = 0.0;
  double _wettedAreaM2 = 0.0;
  double _totalShellAreaM2 = 0.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _diameterController.dispose();
    _heightLengthController.dispose();
    _dipLevelController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _rectHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final dipMm = double.tryParse(_dipLevelController.text) ?? 0.0;

      if (_selectedType == TankType.verticalCylinder) {
        final dMm = double.tryParse(_diameterController.text) ?? 0.0;
        final hMm = double.tryParse(_heightLengthController.text) ?? 0.0;

        final rM = (dMm / 2.0) / 1000.0;
        final hM = hMm / 1000.0;
        final dipM = math.min(dipMm / 1000.0, hM);

        final totalVol = math.pi * rM * rM * hM;
        final filledVol = math.pi * rM * rM * dipM;

        _totalVolumeM3 = totalVol;
        _filledVolumeM3 = filledVol;
        _ullageM3 = math.max(0.0, totalVol - filledVol);
        _percentFull = totalVol > 0 ? (filledVol / totalVol) * 100.0 : 0.0;

        // Surface areas
        _wettedAreaM2 = (math.pi * rM * rM) + (2 * math.pi * rM * dipM);
        _totalShellAreaM2 = (2 * math.pi * rM * rM) + (2 * math.pi * rM * hM);
      } else if (_selectedType == TankType.horizontalCylinder) {
        final dMm = double.tryParse(_diameterController.text) ?? 0.0;
        final lMm = double.tryParse(_heightLengthController.text) ?? 0.0;

        final rM = (dMm / 2.0) / 1000.0;
        final lM = lMm / 1000.0;
        final dM = dMm / 1000.0;
        final dipM = math.min(dipMm / 1000.0, dM);

        // Cylinder shell volume
        final cylTotalVol = math.pi * rM * rM * lM;

        // Partial cylinder volume by circular segment integration
        // V_cyl_filled = L * [ r^2 * acos((r - h)/r) - (r - h) * sqrt(2*r*h - h^2) ]
        double cylFilledVol = 0.0;
        if (dipM >= dM) {
          cylFilledVol = cylTotalVol;
        } else if (dipM > 0 && rM > 0) {
          final h = dipM;
          final theta = math.acos((rM - h) / rM);
          final segArea = (rM * rM * theta) - ((rM - h) * math.sqrt(math.max(0.0, 2 * rM * h - h * h)));
          cylFilledVol = lM * segArea;
        }

        // Heads volume calculation
        double headTotalVol = 0.0;
        double headFilledVol = 0.0;

        if (_selectedHead == HeadType.ellipsoidal2to1) {
          // 2:1 Semi-ellipsoidal head: depth = D / 4. Total volume for 2 heads = (4/3) * pi * a * b * c = (4/3)*pi*(D/2)^2 * (D/4) = (pi/12)*D^3
          headTotalVol = (math.pi / 12.0) * math.pow(dM, 3);
          // Partial volume of 2 ellipsoidal heads: V_head = pi * (D/4) * ( (dip/D)^2 * (3 - 2*(dip/D)) ) ... standard formula
          final k = math.min(1.0, dipM / dM);
          headFilledVol = headTotalVol * (k * k * (3 - 2 * k));
        } else if (_selectedHead == HeadType.torispherical) {
          // ASME F&D head ~ 0.0809 * D^3 per head, total ~ 0.1618 * D^3
          headTotalVol = 0.1618 * math.pow(dM, 3);
          final k = math.min(1.0, dipM / dM);
          headFilledVol = headTotalVol * (k * k * (3 - 2 * k));
        }

        final totalVol = cylTotalVol + headTotalVol;
        final filledVol = cylFilledVol + headFilledVol;

        _totalVolumeM3 = totalVol;
        _filledVolumeM3 = filledVol;
        _ullageM3 = math.max(0.0, totalVol - filledVol);
        _percentFull = totalVol > 0 ? (filledVol / totalVol) * 100.0 : 0.0;

        _wettedAreaM2 = 2 * math.pi * rM * lM * (_percentFull / 100.0);
        _totalShellAreaM2 = 2 * math.pi * rM * lM + (2 * math.pi * rM * rM);
      } else if (_selectedType == TankType.rectangular) {
        final lMm = double.tryParse(_lengthController.text) ?? 0.0;
        final wMm = double.tryParse(_widthController.text) ?? 0.0;
        final hMm = double.tryParse(_rectHeightController.text) ?? 0.0;

        final lM = lMm / 1000.0;
        final wM = wMm / 1000.0;
        final hM = hMm / 1000.0;
        final dipM = math.min(dipMm / 1000.0, hM);

        final totalVol = lM * wM * hM;
        final filledVol = lM * wM * dipM;

        _totalVolumeM3 = totalVol;
        _filledVolumeM3 = filledVol;
        _ullageM3 = math.max(0.0, totalVol - filledVol);
        _percentFull = totalVol > 0 ? (filledVol / totalVol) * 100.0 : 0.0;

        _wettedAreaM2 = (lM * wM) + 2 * (lM * dipM) + 2 * (wM * dipM);
        _totalShellAreaM2 = 2 * (lM * wM + lM * hM + wM * hM);
      }

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
          // Tank Type Choice Bar
          Row(
            children: [
              ...TankType.values.map((type) {
                final isSelected = _selectedType == type;
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
                        setState(() => _selectedType = type);
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
                  label: const Text('Save Sizing', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onSave!(
                      'Tank Calculation: ${_selectedType.title} (Dip ${_dipLevelController.text} mm)',
                      {
                        'tankType': _selectedType.name,
                        'dipLevelMm': _dipLevelController.text,
                        'diameterMm': _diameterController.text,
                        'heightMm': _heightLengthController.text,
                      },
                      {
                        'totalVolumeM3': _totalVolumeM3.toStringAsFixed(3),
                        'filledVolumeM3': _filledVolumeM3.toStringAsFixed(3),
                        'filledLiters': (_filledVolumeM3 * 1000).toStringAsFixed(1),
                        'filledBarrels': (_filledVolumeM3 / 0.158987).toStringAsFixed(2),
                        'percentFull': _percentFull.toStringAsFixed(1),
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tank calculation saved!')),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Two Column Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dimensions & Inputs
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
                      Text('${_selectedType.title} Dimensions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 16),

                      if (_selectedType == TankType.verticalCylinder || _selectedType == TankType.horizontalCylinder) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Tank Diameter D (mm)',
                                controller: _diameterController,
                                onChanged: (_) => _calculate(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                label: _selectedType == TankType.verticalCylinder ? 'Straight Shell Height H (mm)' : 'Cylinder Length L (mm)',
                                controller: _heightLengthController,
                                onChanged: (_) => _calculate(),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedType == TankType.horizontalCylinder) ...[
                          const SizedBox(height: 12),
                          const Text('Dish Head Type:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<HeadType>(
                            value: _selectedHead,
                            decoration: InputDecoration(
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: HeadType.values.map((h) => DropdownMenuItem(value: h, child: Text(h.title))).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedHead = v);
                                _calculate();
                              }
                            },
                          ),
                        ],
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Length L (mm)',
                                controller: _lengthController,
                                onChanged: (_) => _calculate(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                label: 'Width W (mm)',
                                controller: _widthController,
                                onChanged: (_) => _calculate(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label: 'Total Height / Depth H (mm)',
                          controller: _rectHeightController,
                          onChanged: (_) => _calculate(),
                        ),
                      ],

                      const Divider(height: 28),

                      // Liquid Sounding / Dip level
                      const Row(
                        children: [
                          Icon(Icons.colorize_outlined, color: Colors.cyan, size: 20),
                          SizedBox(width: 8),
                          Text('Liquid Dip Sounding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: 'Dip Tape Level / Liquid Height (mm)',
                        controller: _dipLevelController,
                        onChanged: (_) => _calculate(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Volume & Ullage Output Dashboard
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Storage Volumetric Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_percentFull.toStringAsFixed(1)}% Filled',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress Level Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_percentFull / 100.0).clamp(0.0, 1.0),
                          minHeight: 18,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Main Metric Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Current Liquid Hold-up',
                              val1: '${_filledVolumeM3.toStringAsFixed(3)} m³',
                              val2: '${(_filledVolumeM3 * 1000).toStringAsFixed(0)} Liters',
                              val3: '${(_filledVolumeM3 / 0.158987).toStringAsFixed(1)} bbl',
                              accentColor: Colors.cyan,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total Gross Capacity',
                              val1: '${_totalVolumeM3.toStringAsFixed(3)} m³',
                              val2: '${(_totalVolumeM3 * 1000).toStringAsFixed(0)} Liters',
                              val3: '${(_totalVolumeM3 / 0.158987).toStringAsFixed(1)} bbl',
                              accentColor: AppColors.primaryLight,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildDetailRow('Ullage (Remaining Empty Space):', '${_ullageM3.toStringAsFixed(3)} m³ (${(_ullageM3 * 1000).toStringAsFixed(0)} L)'),
                      _buildDetailRow('Wetted Internal Surface Area:', '${_wettedAreaM2.toStringAsFixed(2)} m²'),
                      _buildDetailRow('Total Shell Surface Area (Painting/Insulation):', '${_totalShellAreaM2.toStringAsFixed(2)} m²'),
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

  Widget _buildMetricCard({
    required String title,
    required String val1,
    required String val2,
    required String val3,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(val1, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 4),
          Text(val2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(val3, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
