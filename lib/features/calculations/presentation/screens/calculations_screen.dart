import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

class CalculationsScreen extends StatefulWidget {
  const CalculationsScreen({super.key});

  @override
  State<CalculationsScreen> createState() => _CalculationsScreenState();
}

class _CalculationsScreenState extends State<CalculationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pipe Wall Thickness Calculator State (ASME B31.3: t = (P*D) / (2*(S*E + P*Y)) + CA)
  final _pressureController = TextEditingController(text: '80.0'); // bar
  final _diameterController = TextEditingController(text: '168.3'); // mm (6" pipe)
  final _stressController = TextEditingController(text: '137.9'); // MPa (A106 Gr.B)
  final _corrosionController = TextEditingController(text: '3.0'); // mm
  double _calculatedThickness = 0.0;
  double _calculatedMawp = 0.0;

  // Hydrotest Calculator State (ASME B31.3 Section 345.4.2: Pt = 1.5 * P * (St/S))
  final _designPressureController = TextEditingController(text: '50.0'); // bar
  final _stStressController = TextEditingController(text: '137.9'); // MPa at test temp
  final _sStressController = TextEditingController(text: '137.9'); // MPa at design temp
  double _calculatedTestPressure = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculatePipeThickness();
    _calculateHydrotest();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pressureController.dispose();
    _diameterController.dispose();
    _stressController.dispose();
    _corrosionController.dispose();
    _designPressureController.dispose();
    _stStressController.dispose();
    _sStressController.dispose();
    super.dispose();
  }

  void _calculatePipeThickness() {
    try {
      final pBar = double.tryParse(_pressureController.text) ?? 0.0;
      final dMm = double.tryParse(_diameterController.text) ?? 0.0;
      final sMpa = double.tryParse(_stressController.text) ?? 0.0;
      final caMm = double.tryParse(_corrosionController.text) ?? 0.0;

      final pMpa = pBar / 10.0;
      const e = 1.0; // Seamless pipe quality factor
      const y = 0.4; // Temperature coefficient for ferritic steel < 482°C

      if (sMpa > 0 && dMm > 0) {
        final tPressure = (pMpa * dMm) / (2 * (sMpa * e + pMpa * y));
        final tTotal = tPressure + caMm;
        final mawp = (2 * sMpa * e * (tTotal - caMm)) / (dMm - 2 * y * (tTotal - caMm)) * 10;

        setState(() {
          _calculatedThickness = tTotal;
          _calculatedMawp = mawp;
        });
      }
    } catch (_) {}
  }

  void _calculateHydrotest() {
    try {
      final p = double.tryParse(_designPressureController.text) ?? 0.0;
      final st = double.tryParse(_stStressController.text) ?? 1.0;
      final s = double.tryParse(_sStressController.text) ?? 1.0;

      if (s > 0) {
        final pt = 1.5 * p * (st / s);
        setState(() {
          _calculatedTestPressure = pt;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.calculate_rounded, color: AppColors.safetyOrange, size: 28),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Engineering Calculations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Text(
                      'Offline ASME B31.3, API 570, and mechanical sizing tools for site inspections.',
                      style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.safetyOrange,
                labelColor: AppColors.safetyOrange,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.architecture_rounded, size: 18), text: 'ASME B31.3 Pipe Wall Thickness'),
                  Tab(icon: Icon(Icons.water_drop_rounded, size: 18), text: 'Hydrostatic Test Pressure'),
                  Tab(icon: Icon(Icons.bolt_rounded, size: 18), text: 'ASME Flange Bolt Torque Chart'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPipeThicknessTab(isDark),
                  _buildHydrotestTab(isDark),
                  _buildFlangeTorqueTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipeThicknessTab(bool isDark) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Form (Flex 3)
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Input Parameters (ASME B31.3 Process Piping)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pressureController,
                    decoration: const InputDecoration(labelText: 'Internal Design Pressure (P)', suffixText: 'bar (gauge)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculatePipeThickness(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _diameterController,
                    decoration: const InputDecoration(labelText: 'Pipe Outside Diameter (D)', suffixText: 'mm (e.g. 168.3 for 6")'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculatePipeThickness(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _stressController,
                    decoration: const InputDecoration(labelText: 'Basic Allowable Stress (S)', suffixText: 'MPa (e.g. 137.9 for A106-B)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculatePipeThickness(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _corrosionController,
                    decoration: const InputDecoration(labelText: 'Corrosion Allowance (CA)', suffixText: 'mm (typically 1.5 - 3.0 mm)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculatePipeThickness(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Output Results Card (Flex 2)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF132F24), Color(0xFF091913)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.online.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.online, size: 22),
                      SizedBox(width: 8),
                      Text('CALCULATED RESULTS', style: TextStyle(color: AppColors.online, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Required Min Wall Thickness (tm):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${_calculatedThickness.toStringAsFixed(2)} mm',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  const Text('Maximum Allowable Working Pressure (MAWP):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${_calculatedMawp.toStringAsFixed(1)} bar',
                    style: const TextStyle(color: AppColors.safetyOrange, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const Text(
                    'Code Formula: t = (P × D) / [2 × (S × E + P × Y)] + CA\nStandard: ASME B31.3 Para 304.1.2',
                    style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrotestTab(bool isDark) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hydrostatic Test Parameters (ASME B31.3 Para 345.4.2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _designPressureController,
                    decoration: const InputDecoration(labelText: 'Internal Design Pressure (P)', suffixText: 'bar (gauge)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateHydrotest(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _stStressController,
                    decoration: const InputDecoration(labelText: 'Allowable Stress at Test Temperature (St)', suffixText: 'MPa'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateHydrotest(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sStressController,
                    decoration: const InputDecoration(labelText: 'Allowable Stress at Design Temperature (S)', suffixText: 'MPa'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateHydrotest(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F263E), Color(0xFF081421)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop_rounded, color: Colors.lightBlueAccent, size: 22),
                      SizedBox(width: 8),
                      Text('MINIMUM HYDROTEST PRESSURE', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Required Hydrostatic Test Pressure (Pt):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${_calculatedTestPressure.toStringAsFixed(1)} bar',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const Text(
                    'Formula: Pt = 1.5 × P × (St / S)\nNote: Hydrotest pressure shall not exceed yield stress at test temperature.',
                    style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlangeTorqueTab(bool isDark) {
    final rows = [
      {'size': '1/2"', 'rating': '150#', 'stud': '1/2"-13', 'qty': '4', 'torque': '41 Nm (30 ft-lb)'},
      {'size': '2"', 'rating': '150#', 'stud': '5/8"-11', 'qty': '4', 'torque': '108 Nm (80 ft-lb)'},
      {'size': '3"', 'rating': '150#', 'stud': '5/8"-11', 'qty': '4', 'torque': '149 Nm (110 ft-lb)'},
      {'size': '4"', 'rating': '150#', 'stud': '5/8"-11', 'qty': '8', 'torque': '163 Nm (120 ft-lb)'},
      {'size': '6"', 'rating': '300#', 'stud': '3/4"-10', 'qty': '12', 'torque': '271 Nm (200 ft-lb)'},
      {'size': '8"', 'rating': '300#', 'stud': '7/8"-9', 'qty': '12', 'torque': '434 Nm (320 ft-lb)'},
      {'size': '10"', 'rating': '300#', 'stud': '1"-8', 'qty': '16', 'torque': '651 Nm (480 ft-lb)'},
      {'size': '12"', 'rating': '600#', 'stud': '1-1/4"-8', 'qty': '20', 'torque': '1383 Nm (1020 ft-lb)'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ASME B16.5 Flange Bolt Torque Guide (Grade B7 / 2H Studs with Moly Lubricant)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = rows[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(r['size']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  ),
                  title: Text('Flange ${r['size']} Class ${r['rating']} (${r['qty']}x ${r['stud']} Studs)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Star pattern sequence tightening in 3 stages (30%, 60%, 100%)', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.safetyOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(r['torque']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.safetyOrange)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
