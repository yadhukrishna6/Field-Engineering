import 'package:flutter/material.dart';
import '../../domain/models/drawing_calibration.dart';
import '../controllers/markup_controller.dart';
import '../../../../core/theme/color_palette.dart';

class CalibrationDialog extends StatefulWidget {
  final DrawingViewerState viewerState;
  final MarkupController controller;

  const CalibrationDialog({
    super.key,
    required this.viewerState,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required MarkupController controller,
    required DrawingViewerState viewerState,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CalibrationDialog(viewerState: viewerState, controller: controller),
    );
  }

  @override
  State<CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<CalibrationDialog> {
  final _distanceController = TextEditingController(text: '1000');
  CalibrationUnit _selectedUnit = CalibrationUnit.mm;

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.viewerState.calibrationPoints;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.straighten_rounded, color: AppColors.safetyOrange),
          SizedBox(width: 10),
          Text('Calibrate Drawing Scale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.safetyOrange.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.safetyOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      points.length < 2
                          ? 'Tap 2 known reference points on the drawing (e.g. dimension line or grid interval).'
                          : 'Reference points selected (${points.length}/2). Enter the known real-world dimension below.',
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Known Distance Input
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Known Dimension Distance *',
                hintText: 'e.g. 1000, 5.5, 250',
                suffixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CalibrationUnit>(
                      value: _selectedUnit,
                      items: CalibrationUnit.values.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text(u.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Unit Description Pill
            Text(
              'Selected Unit: ${_selectedUnit.displayName}',
              style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supported Units: mm, cm, m, inch, ft. All subsequent distance, area, and volume measurements on this sheet will automatically use this calibrated scale.',
              style: TextStyle(fontSize: 10, color: AppColors.darkTextMuted, height: 1.3),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.controller.cancelCalibration();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safetyOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final dist = double.tryParse(_distanceController.text.trim()) ?? 0.0;
            if (dist <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid positive distance.')),
              );
              return;
            }

            if (points.length < 2) {
              // Close modal and let engineer tap 2 points
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.safetyOrange,
                  content: Text('Calibration mode active: Tap 2 reference points on the drawing.'),
                ),
              );
              return;
            }

            try {
              final cal = await widget.controller.applyCalibration(dist, _selectedUnit);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.online,
                    content: Text('Drawing calibrated: 1 page unit = ${cal.scaleFactor.toStringAsFixed(1)} ${cal.unit.symbol}'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calibration error: $e')),
                );
              }
            }
          },
          child: Text(points.length < 2 ? 'Select Points on Drawing' : 'Apply Calibration'),
        ),
      ],
    );
  }
}
