import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalculationsScreen extends ConsumerStatefulWidget {
  const CalculationsScreen({super.key});

  @override
  ConsumerState<CalculationsScreen> createState() => _CalculationsScreenState();
}

class _CalculationsScreenState extends ConsumerState<CalculationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pipe Inputs (Matching Screen 9)
  final _odController = TextEditingController(text: '100');
  final _wallThicknessController = TextEditingController(text: '5');
  final _lengthController = TextEditingController(text: '12');
  final _densityController = TextEditingController(text: '7850');

  // Calculation Results
  double _pipeWeightKg = 146.2;
  double _volumeM3 = 0.089;
  double _surfaceAreaM2 = 3.77;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calculatePipe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _odController.dispose();
    _wallThicknessController.dispose();
    _lengthController.dispose();
    _densityController.dispose();
    super.dispose();
  }

  void _calculatePipe() {
    final odMm = double.tryParse(_odController.text) ?? 100.0;
    final tMm = double.tryParse(_wallThicknessController.text) ?? 5.0;
    final lenM = double.tryParse(_lengthController.text) ?? 12.0;
    final density = double.tryParse(_densityController.text) ?? 7850.0;

    final odM = odMm / 1000.0;
    final idM = math.max(0.0, (odMm - 2 * tMm) / 1000.0);

    // Cross-sectional metal area: pi/4 * (OD^2 - ID^2)
    final metalAreaM2 = (math.pi / 4.0) * (odM * odM - idM * idM);
    _pipeWeightKg = metalAreaM2 * lenM * density;

    // Internal fluid volume: pi/4 * ID^2 * length
    _volumeM3 = (math.pi / 4.0) * (idM * idM) * lenM;

    // Outer surface area: pi * OD * length
    _surfaceAreaM2 = math.pi * odM * lenM;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Calculator',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2563EB)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom formula calculator saved')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Pipe'),
            Tab(text: 'Tank'),
            Tab(text: 'Plate'),
            Tab(text: 'Concrete'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Input Card
              Container(
                padding: const EdgeInsets.all(18),
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
                child: Column(
                  children: [
                    _buildInputField(
                      label: 'Outside Diameter (OD)',
                      unit: 'mm',
                      controller: _odController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: 'Wall Thickness',
                      unit: 'mm',
                      controller: _wallThicknessController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: 'Length',
                      unit: 'm',
                      controller: _lengthController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      label: 'Material Density',
                      unit: 'kg/m³',
                      controller: _densityController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Calculate Button (matching Screen 9)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _calculatePipe,
                        child: const Text(
                          'Calculate',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Results Grid / Cards
              _buildResultCard(
                title: 'Pipe Weight',
                value: '${_pipeWeightKg.toStringAsFixed(1)} kg',
                subtitle: 'Theoretical dry carbon steel weight',
                icon: Icons.fitness_center_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildResultCard(
                      title: 'Volume',
                      value: '${_volumeM3.toStringAsFixed(3)} m³',
                      subtitle: 'Internal hold-up',
                      icon: Icons.water_drop_rounded,
                      accentColor: const Color(0xFF06B6D4),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultCard(
                      title: 'Surface Area',
                      value: '${_surfaceAreaM2.toStringAsFixed(2)} m²',
                      subtitle: 'External coating area',
                      icon: Icons.square_foot_rounded,
                      accentColor: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _calculatePipe(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            unit,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
