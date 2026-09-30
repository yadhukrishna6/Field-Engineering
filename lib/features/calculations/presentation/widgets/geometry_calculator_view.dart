import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

enum GeoCategory {
  area2D('2D Area & Perimeter', Icons.crop_square_rounded),
  volume3D('3D Volume & Surface', Icons.view_in_ar_rounded),
  lengthTrig('Length, Slope & Arc', Icons.architecture_rounded);

  final String title;
  final IconData icon;
  const GeoCategory(this.title, this.icon);
}

enum Shape2D {
  rectangle('Rectangle'),
  triangle('Triangle (Base & Height)'),
  trapezoid('Trapezoid'),
  circle('Circle'),
  annulus('Annulus (Ring)'),
  sector('Circular Sector');

  final String title;
  const Shape2D(this.title);
}

enum Shape3D {
  cylinder('Cylinder'),
  cone('Cone'),
  frustum('Truncated Cone (Frustum)'),
  sphere('Sphere'),
  sphericalCap('Spherical Cap / Dish'),
  pyramid('Rectangular Pyramid');

  final String title;
  const Shape3D(this.title);
}

class GeometryCalculatorView extends StatefulWidget {
  final Function(String title, Map<String, dynamic> inputs, Map<String, dynamic> results)? onSave;

  const GeometryCalculatorView({super.key, this.onSave});

  @override
  State<GeometryCalculatorView> createState() => _GeometryCalculatorViewState();
}

class _GeometryCalculatorViewState extends State<GeometryCalculatorView> {
  GeoCategory _selectedCategory = GeoCategory.area2D;
  Shape2D _selected2D = Shape2D.rectangle;
  Shape3D _selected3D = Shape3D.cylinder;

  // General Param Controllers
  final _p1Controller = TextEditingController(text: '1000'); // dim A (length, radius, base)
  final _p2Controller = TextEditingController(text: '500'); // dim B (width, height, radius2)
  final _p3Controller = TextEditingController(text: '250'); // dim C (top width, angle, etc)
  final _p4Controller = TextEditingController(text: '100'); // dim D (z-diff, etc)

  double _calcArea = 0.0;
  double _calcPerimeter = 0.0;
  double _calcVolume = 0.0;
  double _calcSurfaceArea = 0.0;
  double _calcLength = 0.0;
  double _calcSlopePercent = 0.0;
  double _calcAngleDeg = 0.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    _p3Controller.dispose();
    _p4Controller.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final a = double.tryParse(_p1Controller.text) ?? 0.0;
      final b = double.tryParse(_p2Controller.text) ?? 0.0;
      final c = double.tryParse(_p3Controller.text) ?? 0.0;

      if (_selectedCategory == GeoCategory.area2D) {
        switch (_selected2D) {
          case Shape2D.rectangle:
            _calcArea = a * b;
            _calcPerimeter = 2 * (a + b);
            break;
          case Shape2D.triangle:
            _calcArea = 0.5 * a * b;
            final hyp = math.sqrt(a * a + b * b);
            _calcPerimeter = a + b + hyp;
            break;
          case Shape2D.trapezoid:
            _calcArea = 0.5 * (a + c) * b;
            final side = math.sqrt(math.pow((a - c).abs() / 2, 2) + b * b);
            _calcPerimeter = a + c + 2 * side;
            break;
          case Shape2D.circle:
            _calcArea = math.pi * a * a;
            _calcPerimeter = 2 * math.pi * a;
            break;
          case Shape2D.annulus:
            final rOuter = math.max(a, b);
            final rInner = math.min(a, b);
            _calcArea = math.pi * (rOuter * rOuter - rInner * rInner);
            _calcPerimeter = 2 * math.pi * (rOuter + rInner);
            break;
          case Shape2D.sector:
            // a: Radius, b: Angle in degrees
            final rad = b * (math.pi / 180.0);
            _calcArea = 0.5 * a * a * rad;
            final arc = a * rad;
            _calcPerimeter = 2 * a + arc;
            break;
        }
      } else if (_selectedCategory == GeoCategory.volume3D) {
        switch (_selected3D) {
          case Shape3D.cylinder:
            // a: Radius, b: Height
            _calcVolume = math.pi * a * a * b;
            _calcSurfaceArea = 2 * math.pi * a * b + 2 * math.pi * a * a;
            break;
          case Shape3D.cone:
            // a: Radius, b: Height
            _calcVolume = (1.0 / 3.0) * math.pi * a * a * b;
            final slant = math.sqrt(a * a + b * b);
            _calcSurfaceArea = math.pi * a * (a + slant);
            break;
          case Shape3D.frustum:
            // a: Base R1, b: Top R2, c: Height
            _calcVolume = (1.0 / 3.0) * math.pi * c * (a * a + b * b + a * b);
            final slant = math.sqrt(math.pow(a - b, 2) + c * c);
            _calcSurfaceArea = math.pi * (a + b) * slant + math.pi * (a * a + b * b);
            break;
          case Shape3D.sphere:
            // a: Radius
            _calcVolume = (4.0 / 3.0) * math.pi * math.pow(a, 3);
            _calcSurfaceArea = 4 * math.pi * a * a;
            break;
          case Shape3D.sphericalCap:
            // a: Sphere Radius R, b: Cap Height h
            final h = math.min(a, b);
            _calcVolume = (1.0 / 3.0) * math.pi * h * h * (3 * a - h);
            _calcSurfaceArea = 2 * math.pi * a * h;
            break;
          case Shape3D.pyramid:
            // a: Base L, b: Base W, c: Height H
            _calcVolume = (1.0 / 3.0) * a * b * c;
            _calcSurfaceArea = a * b + a * math.sqrt(math.pow(b / 2, 2) + c * c) + b * math.sqrt(math.pow(a / 2, 2) + c * c);
            break;
        }
      } else {
        // Length & Slope / Arc
        // Mode 1: 3D Euclidean (a: dx, b: dy, c: dz)
        // Mode 2: Slope Grade (a: Horizontal run, b: Vertical rise)
        // Mode 3: Arc & Chord (a: Radius R, b: Subtended Angle deg)
        _calcLength = math.sqrt(a * a + b * b + c * c);
        if (a > 0) {
          _calcSlopePercent = (b / a) * 100.0;
          _calcAngleDeg = math.atan(b / a) * (180.0 / math.pi);
        }
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
          // Category Selector
          Row(
            children: [
              ...GeoCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    avatar: Icon(cat.icon, size: 18, color: isSelected ? Colors.white : null),
                    label: Text(cat.title),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() => _selectedCategory = cat);
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
                  label: const Text('Save Geometry Calc', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onSave!(
                      'Geometry: ${_selectedCategory.title}',
                      {'category': _selectedCategory.name},
                      {
                        'area': _calcArea.toStringAsFixed(2),
                        'volume': _calcVolume.toStringAsFixed(2),
                        'length': _calcLength.toStringAsFixed(2),
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geometry calculation saved!')),
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
              // Inputs Card
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
                      if (_selectedCategory == GeoCategory.area2D) ...[
                        const Text('2D Shape Selector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Shape2D>(
                          value: _selected2D,
                          decoration: InputDecoration(
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: Shape2D.values.map((s) => DropdownMenuItem(value: s, child: Text(s.title))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selected2D = v);
                              _calculate();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _build2DFields(),
                      ] else if (_selectedCategory == GeoCategory.volume3D) ...[
                        const Text('3D Solid Shape Selector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Shape3D>(
                          value: _selected3D,
                          decoration: InputDecoration(
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: Shape3D.values.map((s) => DropdownMenuItem(value: s, child: Text(s.title))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selected3D = v);
                              _calculate();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _build3DFields(),
                      ] else ...[
                        const Text('3D Vector & Slope Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(label: 'Horizontal Run ΔX (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInputField(label: 'Vertical Rise ΔY (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(label: 'Depth / Offset ΔZ (mm)', controller: _p3Controller, onChanged: (_) => _calculate()),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Results Dashboard
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
                      const Text('Calculated Properties', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      if (_selectedCategory == GeoCategory.area2D) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Calculated 2D Area',
                                val1: '${(_calcArea / 1000000.0).toStringAsFixed(4)} m²',
                                val2: '${_calcArea.toStringAsFixed(0)} mm²',
                                color: AppColors.primaryLight,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Boundary Perimeter',
                                val1: '${(_calcPerimeter / 1000.0).toStringAsFixed(3)} m',
                                val2: '${_calcPerimeter.toStringAsFixed(1)} mm',
                                color: AppColors.safetyOrange,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_selectedCategory == GeoCategory.volume3D) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Calculated 3D Volume',
                                val1: '${(_calcVolume / 1000000000.0).toStringAsFixed(4)} m³',
                                val2: '${(_calcVolume / 1000000.0).toStringAsFixed(2)} Liters',
                                color: AppColors.primaryLight,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Total Surface Area',
                                val1: '${(_calcSurfaceArea / 1000000.0).toStringAsFixed(3)} m²',
                                val2: '${_calcSurfaceArea.toStringAsFixed(0)} mm²',
                                color: AppColors.safetyOrange,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                title: '3D Spatial Distance',
                                val1: '${(_calcLength / 1000.0).toStringAsFixed(3)} m',
                                val2: '${_calcLength.toStringAsFixed(1)} mm',
                                color: AppColors.primaryLight,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Slope Gradient %',
                                val1: '${_calcSlopePercent.toStringAsFixed(2)} %',
                                val2: '${_calcAngleDeg.toStringAsFixed(2)}° Angle',
                                color: Colors.cyan,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _build2DFields() {
    switch (_selected2D) {
      case Shape2D.rectangle:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Length (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Width (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
      case Shape2D.triangle:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Base (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Height (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
      case Shape2D.trapezoid:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInputField(label: 'Bottom Base (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField(label: 'Top Base (mm)', controller: _p3Controller, onChanged: (_) => _calculate())),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField(label: 'Height (mm)', controller: _p2Controller, onChanged: (_) => _calculate()),
          ],
        );
      case Shape2D.circle:
        return _buildInputField(label: 'Radius R (mm)', controller: _p1Controller, onChanged: (_) => _calculate());
      case Shape2D.annulus:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Outer Radius R1 (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Inner Radius R2 (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
      case Shape2D.sector:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Radius R (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Included Angle (Degrees)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
    }
  }

  Widget _build3DFields() {
    switch (_selected3D) {
      case Shape3D.cylinder:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Radius R (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Height H (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
      case Shape3D.cone:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Base Radius R (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Height H (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
      case Shape3D.frustum:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInputField(label: 'Bottom Radius R1 (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField(label: 'Top Radius R2 (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField(label: 'Height H (mm)', controller: _p3Controller, onChanged: (_) => _calculate()),
          ],
        );
      case Shape3D.sphere:
        return _buildInputField(label: 'Sphere Radius R (mm)', controller: _p1Controller, onChanged: (_) => _calculate());
      case Shape3D.sphericalCap:
        return Row(
          children: [
            Expanded(child: _buildInputField(label: 'Sphere Radius R (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(label: 'Cap Height h (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
          ],
        );
      case Shape3D.pyramid:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInputField(label: 'Base Length (mm)', controller: _p1Controller, onChanged: (_) => _calculate())),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField(label: 'Base Width (mm)', controller: _p2Controller, onChanged: (_) => _calculate())),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField(label: 'Pyramid Height (mm)', controller: _p3Controller, onChanged: (_) => _calculate()),
          ],
        );
    }
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
}
