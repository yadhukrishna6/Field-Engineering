import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

class PipeCalculatorView extends StatefulWidget {
  final Function(String title, Map<String, dynamic> inputs, Map<String, dynamic> results)? onSave;

  const PipeCalculatorView({super.key, this.onSave});

  @override
  State<PipeCalculatorView> createState() => _PipeCalculatorViewState();
}

class _PipeCalculatorViewState extends State<PipeCalculatorView> {
  // ASME B31.3 Inputs
  final _pressureController = TextEditingController(text: '50.0'); // bar
  final _diameterController = TextEditingController(text: '168.3'); // mm (6" pipe OD)
  final _allowableStressController = TextEditingController(text: '137.9'); // MPa (A106 Gr.B)
  final _corrosionController = TextEditingController(text: '3.0'); // mm
  final _jointFactorController = TextEditingController(text: '1.0'); // E factor (1.0 seamless, 0.85 ERW)
  final _yCoeffController = TextEditingController(text: '0.4'); // Y factor

  // Hydrotest Inputs
  final _hydroDesignPressureController = TextEditingController(text: '50.0'); // bar
  final _stStressController = TextEditingController(text: '137.9'); // MPa
  final _sStressController = TextEditingController(text: '137.9'); // MPa

  // Pipe Flow & Volume Inputs
  final _pipeLengthController = TextEditingController(text: '100.0'); // meters
  final _flowRateController = TextEditingController(text: '50.0'); // m3/h

  // Standard Schedules Data: {NPS: {OD: mm, Sch: {Name: Wall_mm}}}
  static const Map<String, Map<String, dynamic>> _pipeSchedules = {
    '1/2"': {'od': 21.3, 'sch': {'Sch 40 (STD)': 2.77, 'Sch 80 (XS)': 3.73, 'Sch 160': 4.78}},
    '3/4"': {'od': 26.7, 'sch': {'Sch 40 (STD)': 2.87, 'Sch 80 (XS)': 3.91, 'Sch 160': 5.56}},
    '1"': {'od': 33.4, 'sch': {'Sch 40 (STD)': 3.38, 'Sch 80 (XS)': 4.55, 'Sch 160': 6.35}},
    '1-1/2"': {'od': 48.3, 'sch': {'Sch 40 (STD)': 3.68, 'Sch 80 (XS)': 5.08, 'Sch 160': 7.14}},
    '2"': {'od': 60.3, 'sch': {'Sch 40 (STD)': 3.91, 'Sch 80 (XS)': 5.54, 'Sch 160': 8.74, 'XXS': 11.07}},
    '3"': {'od': 88.9, 'sch': {'Sch 40 (STD)': 5.49, 'Sch 80 (XS)': 7.62, 'Sch 160': 11.13, 'XXS': 15.24}},
    '4"': {'od': 114.3, 'sch': {'Sch 40 (STD)': 6.02, 'Sch 80 (XS)': 8.56, 'Sch 120': 11.10, 'Sch 160': 13.49}},
    '6"': {'od': 168.3, 'sch': {'Sch 40 (STD)': 7.11, 'Sch 80 (XS)': 10.97, 'Sch 120': 14.27, 'Sch 160': 18.26}},
    '8"': {'od': 219.1, 'sch': {'Sch 20': 6.35, 'Sch 40 (STD)': 8.18, 'Sch 80 (XS)': 12.70, 'Sch 120': 18.26, 'Sch 160': 23.01}},
    '10"': {'od': 273.0, 'sch': {'Sch 20': 6.35, 'Sch 40 (STD)': 9.27, 'Sch 80 (XS)': 15.09, 'Sch 120': 21.44, 'Sch 160': 28.58}},
    '12"': {'od': 323.8, 'sch': {'Sch 20': 6.35, 'Sch 40 (STD)': 10.31, 'Sch 80 (XS)': 17.48, 'Sch 120': 25.40, 'Sch 160': 33.32}},
    '14"': {'od': 355.6, 'sch': {'Sch 30': 7.92, 'Sch 40 (STD)': 11.13, 'Sch 80 (XS)': 19.05, 'Sch 120': 27.79, 'Sch 160': 35.71}},
    '16"': {'od': 406.4, 'sch': {'Sch 30': 7.92, 'Sch 40 (STD)': 12.70, 'Sch 80 (XS)': 21.44, 'Sch 120': 30.96, 'Sch 160': 40.49}},
    '18"': {'od': 457.0, 'sch': {'Sch 30': 7.92, 'Sch 40 (STD)': 14.27, 'Sch 80 (XS)': 23.83, 'Sch 120': 34.93, 'Sch 160': 45.24}},
    '20"': {'od': 508.0, 'sch': {'Sch 30': 9.53, 'Sch 40 (STD)': 15.09, 'Sch 80 (XS)': 26.19, 'Sch 120': 38.10, 'Sch 160': 50.01}},
    '24"': {'od': 610.0, 'sch': {'Sch 30': 9.53, 'Sch 40 (STD)': 17.48, 'Sch 80 (XS)': 30.96, 'Sch 120': 46.02, 'Sch 160': 59.54}},
  };

  String _selectedNps = '6"';
  String _selectedSch = 'Sch 40 (STD)';

  // Results
  double _minThickness = 0.0;
  double _pressureThickness = 0.0;
  double _mawpBar = 0.0;
  double _testPressureBar = 0.0;
  double _pipeWeightKgPerM = 0.0;
  double _waterWeightKgPerM = 0.0;
  double _innerDiameterMm = 0.0;
  double _pipeCapacityLiters = 0.0;
  double _flowVelocityMPerS = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateAll();
  }

  @override
  void dispose() {
    _pressureController.dispose();
    _diameterController.dispose();
    _allowableStressController.dispose();
    _corrosionController.dispose();
    _jointFactorController.dispose();
    _yCoeffController.dispose();
    _hydroDesignPressureController.dispose();
    _stStressController.dispose();
    _sStressController.dispose();
    _pipeLengthController.dispose();
    _flowRateController.dispose();
    super.dispose();
  }

  void _onNpsChanged(String nps) {
    final schMap = _pipeSchedules[nps]!['sch'] as Map<String, double>;
    setState(() {
      _selectedNps = nps;
      _diameterController.text = _pipeSchedules[nps]!['od'].toString();
      _selectedSch = schMap.keys.first;
    });
    _calculateAll();
  }

  void _calculateAll() {
    try {
      final pBar = double.tryParse(_pressureController.text) ?? 0.0;
      final dMm = double.tryParse(_diameterController.text) ?? 0.0;
      final sMpa = double.tryParse(_allowableStressController.text) ?? 0.0;
      final caMm = double.tryParse(_corrosionController.text) ?? 0.0;
      final e = double.tryParse(_jointFactorController.text) ?? 1.0;
      final y = double.tryParse(_yCoeffController.text) ?? 0.4;

      final pMpa = pBar / 10.0;

      if (sMpa > 0 && dMm > 0) {
        // ASME B31.3 formula 3a: t = (P * D) / (2 * (S*E + P*Y))
        final denom = 2 * (sMpa * e + pMpa * y);
        if (denom > 0) {
          final tReq = (pMpa * dMm) / denom;
          final tTotal = tReq + caMm;

          // MAWP formula
          final mawpMpa = (2 * sMpa * e * (tTotal - caMm)) / (dMm - 2 * y * (tTotal - caMm));

          _pressureThickness = tReq;
          _minThickness = tTotal;
          _mawpBar = mawpMpa * 10.0;
        }
      }

      // Hydrotest: Pt = 1.5 * P * (St / S)
      final desP = double.tryParse(_hydroDesignPressureController.text) ?? 0.0;
      final st = double.tryParse(_stStressController.text) ?? 1.0;
      final s = double.tryParse(_sStressController.text) ?? 1.0;
      if (s > 0) {
        _testPressureBar = 1.5 * desP * (st / s);
      }

      // Schedule dimensions and weight
      final schMap = _pipeSchedules[_selectedNps]!['sch'] as Map<String, double>;
      final wallThicknessMm = schMap[_selectedSch] ?? 7.11;
      final odMm = (_pipeSchedules[_selectedNps]!['od'] as num).toDouble();
      final idMm = odMm - 2 * wallThicknessMm;
      _innerDiameterMm = math.max(0.0, idMm);

      // Steel density 7850 kg/m3. Pipe cross sectional area in m2: pi/4 * (OD^2 - ID^2)
      final odM = odMm / 1000.0;
      final idM = _innerDiameterMm / 1000.0;
      final metalAreaM2 = (math.pi / 4.0) * (odM * odM - idM * idM);
      _pipeWeightKgPerM = metalAreaM2 * 7850.0;

      // Water internal area in m2: pi/4 * ID^2
      final waterAreaM2 = (math.pi / 4.0) * (idM * idM);
      _waterWeightKgPerM = waterAreaM2 * 1000.0;

      // Pipe Volume for Length
      final lenM = double.tryParse(_pipeLengthController.text) ?? 0.0;
      final totalVolM3 = waterAreaM2 * lenM;
      _pipeCapacityLiters = totalVolM3 * 1000.0;

      // Flow velocity: v = Q (m3/s) / A (m2)
      final flowM3h = double.tryParse(_flowRateController.text) ?? 0.0;
      if (waterAreaM2 > 0) {
        final qM3s = flowM3h / 3600.0;
        _flowVelocityMPerS = qM3s / waterAreaM2;
      }

      setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSchedules = (_pipeSchedules[_selectedNps]!['sch'] as Map<String, double>).keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Quick Pipe Dimension Preset Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.safetyOrange),
                const SizedBox(width: 12),
                const Text('Nominal Pipe Size (NPS):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedNps,
                  items: _pipeSchedules.keys.map((nps) {
                    return DropdownMenuItem(value: nps, child: Text(nps, style: const TextStyle(fontWeight: FontWeight.bold)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _onNpsChanged(v);
                  },
                ),
                const SizedBox(width: 24),
                const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: currentSchedules.contains(_selectedSch) ? _selectedSch : currentSchedules.first,
                  items: currentSchedules.map((sch) {
                    return DropdownMenuItem(value: sch, child: Text(sch));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedSch = v);
                      _calculateAll();
                    }
                  },
                ),
                const Spacer(),
                if (widget.onSave != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('Save Calculation', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      widget.onSave!(
                        'Pipe ASME B31.3: $_selectedNps $_selectedSch @ ${_pressureController.text} bar',
                        {
                          'nps': _selectedNps,
                          'schedule': _selectedSch,
                          'pressureBar': _pressureController.text,
                          'diameterMm': _diameterController.text,
                          'allowableStressMpa': _allowableStressController.text,
                          'corrosionAllowanceMm': _corrosionController.text,
                        },
                        {
                          'minThicknessMm': _minThickness.toStringAsFixed(3),
                          'mawpBar': _mawpBar.toStringAsFixed(2),
                          'hydrotestBar': _testPressureBar.toStringAsFixed(2),
                          'pipeWeightKgM': _pipeWeightKgPerM.toStringAsFixed(2),
                          'waterCapacityL': _pipeCapacityLiters.toStringAsFixed(1),
                          'velocityMs': _flowVelocityMPerS.toStringAsFixed(2),
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pipe calculations saved to history!')),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Two Main Columns: ASME B31.3 & Hydrotest vs Pipe Schedule / Flow metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: ASME B31.3 Wall Thickness & Hydrotest
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // ASME B31.3 Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ASME B31.3 Process Piping Wall Thickness',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Internal Pressure P (bar)',
                                  controller: _pressureController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Outside Diameter D (mm)',
                                  controller: _diameterController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Allowable Stress S (MPa)',
                                  controller: _allowableStressController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Corrosion Allowance CA (mm)',
                                  controller: _corrosionController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Calculation Summary Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                _buildResultRow('Required Pressure Thickness (t):', '${_pressureThickness.toStringAsFixed(3)} mm'),
                                const Divider(height: 16),
                                _buildResultRow(
                                  'Minimum Required Thickness (tm = t + CA):',
                                  '${_minThickness.toStringAsFixed(3)} mm',
                                  highlight: true,
                                ),
                                const Divider(height: 16),
                                _buildResultRow('Max Allowable Working Pressure (MAWP):', '${_mawpBar.toStringAsFixed(2)} bar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hydrotest Calculator Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.water_drop_outlined, color: Colors.cyan, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ASME B31.3 Hydrostatic Test Pressure (Pt = 1.5·P·St/S)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Design Pressure P (bar)',
                                  controller: _hydroDesignPressureController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Stress at Test Temp St (MPa)',
                                  controller: _stStressController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.cyan.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Min Hydrotest Pressure Required:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${_testPressureBar.toStringAsFixed(2)} bar (${(_testPressureBar * 14.5038).toStringAsFixed(1)} psi)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right Column: Physical Properties, Schedule Data & Flow Velocity
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Container(
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
                            children: [
                              const Icon(Icons.line_weight_rounded, color: AppColors.safetyOrange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Physical Specs ($_selectedNps $_selectedSch)',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildPropRow('Outer Diameter (OD):', '${_pipeSchedules[_selectedNps]!['od']} mm'),
                          _buildPropRow('Internal Diameter (ID):', '${_innerDiameterMm.toStringAsFixed(2)} mm'),
                          _buildPropRow('Empty Pipe Weight:', '${_pipeWeightKgPerM.toStringAsFixed(2)} kg/m (${(_pipeWeightKgPerM * 0.6719).toStringAsFixed(2)} lb/ft)'),
                          _buildPropRow('Water Weight Inside:', '${_waterWeightKgPerM.toStringAsFixed(2)} kg/m'),
                          _buildPropRow('Total Operating Weight (Filled):', '${(_pipeWeightKgPerM + _waterWeightKgPerM).toStringAsFixed(2)} kg/m'),
                          const Divider(height: 24),

                          // Volume & Flow sizing
                          const Text('Pipeline Volume & Flow Velocity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Line Length (m)',
                                  controller: _pipeLengthController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Flow Rate (m³/h)',
                                  controller: _flowRateController,
                                  onChanged: (_) => _calculateAll(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildPropRow('Total Line Hold-up Volume:', '${_pipeCapacityLiters.toStringAsFixed(1)} L (${(_pipeCapacityLiters / 1000).toStringAsFixed(2)} m³)'),
                          _buildPropRow('Hold-up in Barrels:', '${(_pipeCapacityLiters / 158.987).toStringAsFixed(2)} bbl (oil)'),
                          _buildPropRow(
                            'Internal Flow Velocity:',
                            '${_flowVelocityMPerS.toStringAsFixed(2)} m/s (${(_flowVelocityMPerS * 3.28084).toStringAsFixed(2)} ft/s)',
                          ),
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildResultRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.safetyOrange : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPropRow(String label, String value) {
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
