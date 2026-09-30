import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/color_palette.dart';

enum ConversionCategory {
  length('Length', Icons.straighten_rounded),
  pressure('Pressure', Icons.speed_rounded),
  temperature('Temperature', Icons.thermostat_rounded),
  flow('Flow Rate', Icons.waves_rounded),
  volume('Volume', Icons.opacity_rounded),
  area('Area', Icons.crop_square_rounded),
  weight('Mass / Weight', Icons.fitness_center_rounded);

  final String title;
  final IconData icon;
  const ConversionCategory(this.title, this.icon);
}

class UnitConverterView extends StatefulWidget {
  final Function(String title, Map<String, dynamic> inputs, Map<String, dynamic> results)? onSave;

  const UnitConverterView({super.key, this.onSave});

  @override
  State<UnitConverterView> createState() => _UnitConverterViewState();
}

class _UnitConverterViewState extends State<UnitConverterView> {
  ConversionCategory _selectedCategory = ConversionCategory.length;
  final _inputController = TextEditingController(text: '1000');
  String _fromUnit = 'mm';
  String _toUnit = 'inch';
  double _convertedValue = 0.0;

  // Unit definitions per category: {UnitCode: factorToBase}
  // Base units: Length: meter, Pressure: Pa, Temp: Celsius, Flow: m3/s, Volume: m3, Area: m2, Weight: kg
  static const Map<ConversionCategory, List<String>> _units = {
    ConversionCategory.length: ['mm', 'cm', 'm', 'km', 'inch', 'ft', 'yd', 'mile'],
    ConversionCategory.pressure: ['bar', 'psi', 'kPa', 'MPa', 'atm', 'mmH2O', 'inHg', 'kg/cm²'],
    ConversionCategory.temperature: ['°C', '°F', 'K', '°R'],
    ConversionCategory.flow: ['m³/h', 'L/min', 'L/s', 'gpm (US)', 'gpm (UK)', 'bbl/day', 'SCFM'],
    ConversionCategory.volume: ['m³', 'L', 'mL', 'gal (US)', 'gal (UK)', 'bbl (oil)', 'ft³', 'in³'],
    ConversionCategory.area: ['mm²', 'cm²', 'm²', 'ha', 'ft²', 'yd²', 'in²', 'acre'],
    ConversionCategory.weight: ['kg', 'g', 'ton (metric)', 'lb', 'oz', 'ton (US short)'],
  };

  @override
  void initState() {
    super.initState();
    _updateUnitsForCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _updateUnitsForCategory(ConversionCategory cat) {
    final list = _units[cat]!;
    setState(() {
      _selectedCategory = cat;
      _fromUnit = list[0];
      _toUnit = list.length > 1 ? list[1] : list[0];
    });
    _calculate();
  }

  void _calculate() {
    final val = double.tryParse(_inputController.text) ?? 0.0;
    double result = 0.0;

    switch (_selectedCategory) {
      case ConversionCategory.length:
        result = _convertLinear(val, _fromUnit, _toUnit, {
          'mm': 0.001,
          'cm': 0.01,
          'm': 1.0,
          'km': 1000.0,
          'inch': 0.0254,
          'ft': 0.3048,
          'yd': 0.9144,
          'mile': 1609.344,
        });
        break;
      case ConversionCategory.pressure:
        result = _convertLinear(val, _fromUnit, _toUnit, {
          'bar': 100000.0,
          'psi': 6894.757,
          'kPa': 1000.0,
          'MPa': 1000000.0,
          'atm': 101325.0,
          'mmH2O': 9.80665,
          'inHg': 3386.389,
          'kg/cm²': 98066.5,
        });
        break;
      case ConversionCategory.temperature:
        result = _convertTemperature(val, _fromUnit, _toUnit);
        break;
      case ConversionCategory.flow:
        result = _convertLinear(val, _fromUnit, _toUnit, {
          'm³/h': 1.0 / 3600.0,
          'L/min': 0.001 / 60.0,
          'L/s': 0.001,
          'gpm (US)': 0.00378541 / 60.0,
          'gpm (UK)': 0.00454609 / 60.0,
          'bbl/day': 0.1589873 / 86400.0,
          'SCFM': 0.0283168 / 60.0,
        });
        break;
      case ConversionCategory.volume:
        result = _convertLinear(val, _fromUnit, _toUnit, {
          'm³': 1.0,
          'L': 0.001,
          'mL': 0.000001,
          'gal (US)': 0.00378541,
          'gal (UK)': 0.00454609,
          'bbl (oil)': 0.1589873,
          'ft³': 0.0283168,
          'in³': 0.000016387064,
        });
        break;
      case ConversionCategory.area:
        result = _convertLinear(val, _fromUnit, _toUnit, {
          'mm²': 0.000001,
          'cm²': 0.0001,
          'm²': 1.0,
          'ha': 10000.0,
          'ft²': 0.092903,
          'yd²': 0.836127,
          'in²': 0.00064516,
          'acre': 4046.86,
        });
        break;
      case ConversionCategory.weight:
        result = _convertLinear(val, _fromUnit, _toUnit, {
          'kg': 1.0,
          'g': 0.001,
          'ton (metric)': 1000.0,
          'lb': 0.45359237,
          'oz': 0.0283495,
          'ton (US short)': 907.18474,
        });
        break;
    }

    setState(() {
      _convertedValue = result;
    });
  }

  double _convertLinear(double val, String from, String to, Map<String, double> factors) {
    final base = val * (factors[from] ?? 1.0);
    return base / (factors[to] ?? 1.0);
  }

  double _convertTemperature(double val, String from, String to) {
    // Convert to Celsius first
    double c = val;
    if (from == '°F') c = (val - 32) * 5 / 9;
    if (from == 'K') c = val - 273.15;
    if (from == '°R') c = (val - 491.67) * 5 / 9;

    // Convert Celsius to Target
    if (to == '°C') return c;
    if (to == '°F') return (c * 9 / 5) + 32;
    if (to == 'K') return c + 273.15;
    if (to == '°R') return (c + 273.15) * 9 / 5;
    return c;
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableUnits = _units[_selectedCategory]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ConversionCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    label: Text(cat.title),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _updateUnitsForCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Main Two-Way Converter Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedCategory.title} Conversion Engine',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (widget.onSave != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text('Save Result', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          widget.onSave!(
                            '${_selectedCategory.title} Conversion: ${_inputController.text} $_fromUnit to $_toUnit',
                            {
                              'value': _inputController.text,
                              'fromUnit': _fromUnit,
                              'toUnit': _toUnit,
                              'category': _selectedCategory.name,
                            },
                            {
                              'result': _convertedValue,
                              'formatted': '${_formatNumber(_convertedValue)} $_toUnit',
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conversion saved to calculation history!')),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Responsive input / output row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Input Side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Input Value & Unit', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _inputController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onChanged: (_) => _calculate(),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _fromUnit,
                                decoration: InputDecoration(
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                items: availableUnits.map((u) {
                                  return DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _fromUnit = v);
                                    _calculate();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        // Swap Button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 8),
                          child: IconButton.filledTonal(
                            icon: const Icon(Icons.swap_horiz_rounded, size: 24),
                            tooltip: 'Swap Units',
                            onPressed: _swapUnits,
                          ),
                        ),

                        // Output Side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Converted Result', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        _formatNumber(_convertedValue),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 18),
                                      tooltip: 'Copy Value',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: _formatNumber(_convertedValue)));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Copied to clipboard!')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _toUnit,
                                decoration: InputDecoration(
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                items: availableUnits.map((u) {
                                  return DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _toUnit = v);
                                    _calculate();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Common Engineering Conversion Quick Cards
          const Text(
            'Quick Conversion Multipliers & Reference',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _buildReferenceCard('1 bar', '= 14.5038 psi', '= 100 kPa', isDark),
              _buildReferenceCard('1 inch', '= 25.4 mm', '= 0.0254 m', isDark),
              _buildReferenceCard('1 m³', '= 6.2898 bbl (oil)', '= 1,000 Liters', isDark),
              _buildReferenceCard('1 m³/h', '= 4.4028 gpm (US)', '= 16.666 L/min', isDark),
              _buildReferenceCard('1 MPa', '= 10.0 bar', '= 145.038 psi', isDark),
              _buildReferenceCard('1 ft²', '= 0.0929 m²', '= 144 sq in', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(String title, String val1, String val2, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.safetyOrange)),
          const SizedBox(height: 2),
          Text(val1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(val2, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatNumber(double val) {
    if (val.abs() >= 100000 || (val.abs() > 0 && val.abs() < 0.0001)) {
      return val.toStringAsExponential(4);
    }
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(4).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
