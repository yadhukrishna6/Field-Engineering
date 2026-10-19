import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/annotation_item.dart';
import '../../domain/utils/field_calculator.dart';

class FieldCalculationsSheet extends StatefulWidget {
  final List<AnnotationItem> annotations;
  final bool isOutdoor;
  final bool isDark;
  final ValueChanged<String>? onInsertNote;

  const FieldCalculationsSheet({
    super.key,
    required this.annotations,
    required this.isOutdoor,
    required this.isDark,
    this.onInsertNote,
  });

  static Future<void> show(
    BuildContext context, {
    required List<AnnotationItem> annotations,
    required bool isOutdoor,
    required bool isDark,
    ValueChanged<String>? onInsertNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.90,
        child: FieldCalculationsSheet(
          annotations: annotations,
          isOutdoor: isOutdoor,
          isDark: isDark,
          onInsertNote: onInsertNote,
        ),
      ),
    );
  }

  @override
  State<FieldCalculationsSheet> createState() => _FieldCalculationsSheetState();
}

class _FieldCalculationsSheetState extends State<FieldCalculationsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Unit Converter State
  final TextEditingController _lengthMmCtrl = TextEditingController(text: '1000');
  final TextEditingController _pressurePsiCtrl = TextEditingController(text: '150');
  PipeSpec _selectedPipeSpec = FieldCalculator.standardPipes[9]; // 10" NPS default
  String _selectedSchedule = 'SCH 40';

  // Piping Formulas State
  final TextEditingController _hydroDesignCtrl = TextEditingController(text: '285'); // Class 150 design psi
  final TextEditingController _pipeLengthCtrl = TextEditingController(text: '24'); // 24 meters
  final TextEditingController _deltaTempCtrl = TextEditingController(text: '45'); // 45 deg C delta

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lengthMmCtrl.dispose();
    _pressurePsiCtrl.dispose();
    _hydroDesignCtrl.dispose();
    _pipeLengthCtrl.dispose();
    _deltaTempCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isOutdoor
        ? AppColors.outdoorSurface
        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textColor = widget.isOutdoor
        ? AppColors.outdoorText
        : (widget.isDark ? AppColors.darkText : AppColors.lightText);
    final outlineColor = widget.isOutdoor
        ? AppColors.outdoorOutline
        : (widget.isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final primaryColor = widget.isOutdoor
        ? AppColors.outdoorPrimary
        : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: outlineColor, width: widget.isOutdoor ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Field Calculations & Quantities',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Mandatory Disclaimer Banner
          _buildDisclaimerBanner(),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: textColor.withOpacity(0.6),
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Dimension Sum & Tally', icon: Icon(Icons.architecture_rounded, size: 18)),
              Tab(text: 'Unit Converter', icon: Icon(Icons.swap_horiz_rounded, size: 18)),
              Tab(text: 'Piping Formulas', icon: Icon(Icons.science_rounded, size: 18)),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDimensionAndTallyTab(textColor, primaryColor, outlineColor),
                _buildUnitConverterTab(textColor, primaryColor, outlineColor),
                _buildPipingFormulasTab(textColor, primaryColor, outlineColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFFFB74D))),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠️ ${FieldCalculator.disclaimer}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Dimension Sum & Quantities Tally ---

  Widget _buildDimensionAndTallyTab(Color textColor, Color primaryColor, Color outlineColor) {
    final tally = FieldCalculator.calculateQuantitiesTally(widget.annotations);
    final dimSums = FieldCalculator.sumDimensionsByLineTag(widget.annotations);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Summary Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'TOTAL MARKUPS',
                  '${tally.totalMarkups}',
                  'Actionable items',
                  primaryColor,
                  textColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'TOTAL CUT LENGTH',
                  '${tally.totalCutLengthMeters.toStringAsFixed(2)} m',
                  '(${FieldCalculator.formatFeetInches(tally.totalCutLengthMeters * 1000)})',
                  const Color(0xFF08605B),
                  textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dimension Auto-Sum by Line Tag
          Text(
            'DIMENSION AUTO-SUM PER LINE TAG',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          if (dimSums.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: outlineColor),
              ),
              child: Text(
                'No dimensions or cut lengths attached to recognized line tags yet. Use the Dimension tool on the canvas to auto-sum segments.',
                style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.6)),
              ),
            )
          else
            ...dimSums.values.map((sum) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withOpacity(0.4)),
                  color: primaryColor.withOpacity(0.04),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔗 ${sum.lineTag}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Segments: ${sum.segmentCount} | ${sum.segmentsMm.map((v) => "${v.toInt()}mm").join(" + ")}',
                            style: TextStyle(fontSize: 10.5, color: textColor.withOpacity(0.65)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sum.totalMm.toStringAsFixed(0)} mm',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        Text(
                          '(${sum.totalMeters.toStringAsFixed(2)} m / ${FieldCalculator.formatFeetInches(sum.totalMm)})',
                          style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 14),

          // Quantities Breakdown Tally
          Text(
            'FIELD MARKUP BREAKDOWN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTallyPill('Deletions / Strike-out', tally.deletionsCount, const Color(0xFFD03A33)),
              _buildTallyPill('Additions', tally.additionsCount, const Color(0xFF08605B)),
              _buildTallyPill('Replacements', tally.replacementsCount, const Color(0xFFC25E00)),
              _buildTallyPill('Relocations', tally.relocationsCount, const Color(0xFF185FA5)),
              _buildTallyPill('Verifications', tally.verificationsCount, const Color(0xFF00695C)),
              _buildTallyPill('Photos with GPS', tally.photoPinsCount, const Color(0xFF283593)),
              _buildTallyPill('Official Stamps', tally.officialStampsCount, const Color(0xFF4A148C)),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Unit Converter ---

  Widget _buildUnitConverterTab(Color textColor, Color primaryColor, Color outlineColor) {
    final lengthMm = double.tryParse(_lengthMmCtrl.text) ?? 0.0;
    final pressurePsi = double.tryParse(_pressurePsiCtrl.text) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Length Converter
          Text(
            'LENGTH CONVERTER (PIPING & ELEVATIONS)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lengthMmCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Millimeters (mm)',
              labelStyle: TextStyle(color: primaryColor, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUnitItem('${FieldCalculator.mmToMeters(lengthMm).toStringAsFixed(3)} m', 'METERS', textColor),
                _buildUnitItem('${FieldCalculator.mmToInches(lengthMm).toStringAsFixed(2)} in', 'INCHES', textColor),
                _buildUnitItem('${FieldCalculator.mmToFeet(lengthMm).toStringAsFixed(2)} ft', 'FEET', textColor),
                _buildUnitItem(FieldCalculator.formatFeetInches(lengthMm), 'FT - IN', textColor),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pressure Converter
          Text(
            'PRESSURE CONVERTER (PIPELINE & HYDROTEST)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pressurePsiCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Pounds per Sq Inch (psi)',
              labelStyle: TextStyle(color: primaryColor, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUnitItem('${FieldCalculator.psiToBar(pressurePsi).toStringAsFixed(2)} bar', 'BAR', textColor),
                _buildUnitItem('${FieldCalculator.psiToKPa(pressurePsi).toStringAsFixed(1)} kPa', 'KILOPASCAL', textColor),
                _buildUnitItem('${FieldCalculator.psiToMPa(pressurePsi).toStringAsFixed(3)} MPa', 'MEGAPASCAL', textColor),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pipe NPS & Schedule Lookup
          Text(
            'ASME B36.10 PIPE SIZE REFERENCE TABLE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PipeSpec>(
                  value: _selectedPipeSpec,
                  decoration: InputDecoration(
                    labelText: 'Nominal Pipe Size (NPS)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  items: FieldCalculator.standardPipes.map((p) {
                    return DropdownMenuItem(value: p, child: Text('${p.nps} (OD ${p.odMm} mm)'));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedPipeSpec = v ?? _selectedPipeSpec),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSchedule,
                  decoration: InputDecoration(
                    labelText: 'Schedule',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  items: ['SCH 40', 'SCH 80', 'SCH 160'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedSchedule = v ?? _selectedSchedule),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outer Diameter (OD): ${_selectedPipeSpec.odMm} mm (${_selectedPipeSpec.odInch}")',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text('Wall Thickness: ${_selectedSchedule == "SCH 80" ? _selectedPipeSpec.sch80WallMm : (_selectedSchedule == "SCH 160" ? _selectedPipeSpec.sch160WallMm : _selectedPipeSpec.sch40WallMm)} mm',
                    style: TextStyle(fontSize: 12, color: textColor)),
                const SizedBox(height: 4),
                Text('Calculated Inside Diameter (ID): ${_selectedPipeSpec.getInsideDiameterMm(_selectedSchedule).toStringAsFixed(1)} mm',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Piping Formulas (Hydrotest & Volume) ---

  Widget _buildPipingFormulasTab(Color textColor, Color primaryColor, Color outlineColor) {
    final designPressure = double.tryParse(_hydroDesignCtrl.text) ?? 285.0;
    final lengthMeters = double.tryParse(_pipeLengthCtrl.text) ?? 24.0;
    final deltaTemp = double.tryParse(_deltaTempCtrl.text) ?? 45.0;

    final wallMm = _selectedSchedule == 'SCH 80'
        ? _selectedPipeSpec.sch80WallMm
        : (_selectedSchedule == 'SCH 160' ? _selectedPipeSpec.sch160WallMm : _selectedPipeSpec.sch40WallMm);

    final volRes = FieldCalculator.calculatePipeVolumeAndWeight(
      outerDiameterMm: _selectedPipeSpec.odMm,
      wallThicknessMm: wallMm,
      lengthMeters: lengthMeters,
    );

    final hydroPressurePsi = FieldCalculator.calculateHydrotestPressure(designPressure);
    final hydroPressureBar = FieldCalculator.psiToBar(hydroPressurePsi);
    final deltaLMm = FieldCalculator.calculateThermalExpansionMm(lengthMeters: lengthMeters, deltaTempCelsius: deltaTemp);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hydrostatic Test Pressure
          Text(
            'HYDROSTATIC TEST PRESSURE (ASME B31.3 1.5x)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hydroDesignCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Design Pressure (psi)',
              labelStyle: TextStyle(color: primaryColor, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF08605B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF08605B).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MIN HYDROTEST PRESSURE (1.5x)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7))),
                    const SizedBox(height: 2),
                    Text('${hydroPressurePsi.toStringAsFixed(1)} psi (${hydroPressureBar.toStringAsFixed(2)} bar)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF08605B))),
                  ],
                ),
                const Icon(Icons.speed_rounded, color: Color(0xFF08605B), size: 28),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pipe Fill Volume & Rigging Lift Weight
          Text(
            'FILL VOLUME & HYDROTEST RIGGING LIFT WEIGHT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pipeLengthCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Total Pipe Spool Cut Length (m)',
              labelStyle: TextStyle(color: primaryColor, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildFormulaRow('Pipe Spec:', '${_selectedPipeSpec.nps} $_selectedSchedule (Length $lengthMeters m)', textColor),
                _buildFormulaRow('Internal Volume:', '${volRes.internalVolumeLiters.toStringAsFixed(1)} L (${volRes.internalVolumeM3.toStringAsFixed(3)} m³)', textColor),
                _buildFormulaRow('Water Fill Weight:', '${volRes.waterWeightKg.toStringAsFixed(1)} kg', textColor),
                _buildFormulaRow('Crude Oil Weight:', '${volRes.crudeOilWeightKg.toStringAsFixed(1)} kg', textColor),
                _buildFormulaRow('Empty Steel Pipe Weight:', '${volRes.pipeSteelWeightKg.toStringAsFixed(1)} kg', textColor),
                const Divider(height: 12),
                _buildFormulaRow('TOTAL HYDROTEST LIFT WEIGHT:', '${volRes.totalHydrotestWeightTonnes.toStringAsFixed(2)} TONNES', primaryColor, isBold: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Thermal Expansion
          Text(
            'DESERT THERMAL EXPANSION (ΔL = α · L · ΔT)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deltaTempCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Temperature Swing (°C) (e.g. Night 10°C to Day 55°C = 45°C)',
              labelStyle: TextStyle(color: primaryColor, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESTIMATED LINE EXPANSION (ΔL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7))),
                    const SizedBox(height: 2),
                    Text('${deltaLMm.toStringAsFixed(2)} mm over $lengthMeters m spool',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC25E00))),
                  ],
                ),
                const Icon(Icons.wb_sunny_rounded, color: Color(0xFFC25E00), size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          Text(sub, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildTallyPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitItem(String value, String unit, Color textColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 2),
        Text(unit, style: TextStyle(fontSize: 9, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFormulaRow(String label, String value, Color textColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: textColor.withOpacity(0.8))),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}
