import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_palette.dart';
import '../controllers/calculations_controller.dart';
import '../widgets/unit_converter_view.dart';
import '../widgets/pipe_calculator_view.dart';
import '../widgets/tank_calculator_view.dart';
import '../widgets/plate_weight_view.dart';
import '../widgets/concrete_calculator_view.dart';
import '../widgets/geometry_calculator_view.dart';
import '../widgets/saved_calculations_view.dart';

class CalculationsScreen extends ConsumerStatefulWidget {
  const CalculationsScreen({super.key});

  @override
  ConsumerState<CalculationsScreen> createState() => _CalculationsScreenState();
}

class _CalculationsScreenState extends ConsumerState<CalculationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, dynamic>> _tabs = [
    {'title': 'Unit Converter', 'icon': Icons.swap_horiz_rounded},
    {'title': 'Pipe (ASME B31.3)', 'icon': Icons.tune_rounded},
    {'title': 'Tank & Dip Level', 'icon': Icons.opacity_rounded},
    {'title': 'Plate & Weight', 'icon': Icons.fitness_center_rounded},
    {'title': 'Concrete Volume', 'icon': Icons.view_quilt_rounded},
    {'title': 'Geometry & Slopes', 'icon': Icons.architecture_rounded},
    {'title': 'Saved History', 'icon': Icons.history_edu_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveCalculation(String title, Map<String, dynamic> inputs, Map<String, dynamic> results, {String? category}) {
    ref.read(calculationsControllerProvider.notifier).saveCalculation(
          calcType: category ?? 'Engineering',
          title: title,
          inputs: inputs,
          results: results,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENGINEERING CALCULATOR & TOOLS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.safetyOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Process, Mechanical, Structural & Civil Calculations',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primaryLight,
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _tabs.map((t) {
                return Tab(
                  icon: Icon(t['icon'] as IconData, size: 18),
                  text: t['title'] as String,
                  iconMargin: const EdgeInsets.only(bottom: 4),
                );
              }).toList(),
            ),
          ),

          // Tab Content Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UnitConverterView(
                  onSave: (title, inMap, resMap) => _saveCalculation(title, inMap, resMap, category: 'Unit Conversion'),
                ),
                PipeCalculatorView(
                  onSave: (title, inMap, resMap) => _saveCalculation(title, inMap, resMap, category: 'Pipe ASME B31.3'),
                ),
                TankCalculatorView(
                  onSave: (title, inMap, resMap) => _saveCalculation(title, inMap, resMap, category: 'Tank & Vessel'),
                ),
                PlateWeightView(
                  onSave: (title, inMap, resMap) => _saveCalculation(title, inMap, resMap, category: 'Plate & Structural'),
                ),
                ConcreteCalculatorView(
                  onSave: (title, inMap, resMap) => _saveCalculation(title, inMap, resMap, category: 'Civil Concrete'),
                ),
                GeometryCalculatorView(
                  onSave: (title, inMap, resMap) => _saveCalculation(title, inMap, resMap, category: 'Geometry'),
                ),
                const SavedCalculationsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
