import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../controllers/markup_controller.dart';

class CountToolDialog extends StatefulWidget {
  final MarkupController controller;
  final DrawingViewerState viewerState;

  const CountToolDialog({
    super.key,
    required this.controller,
    required this.viewerState,
  });

  static Future<void> show(
    BuildContext context, {
    required MarkupController controller,
    required DrawingViewerState viewerState,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CountToolDialog(
        controller: controller,
        viewerState: viewerState,
      ),
    );
  }

  @override
  State<CountToolDialog> createState() => _CountToolDialogState();
}

class _CountToolDialogState extends State<CountToolDialog> {
  final _labelController = TextEditingController(text: 'Valve');
  Color _selectedColor = const Color(0xFF00E676);

  static const List<String> _presets = [
    'Gate Valve',
    'Ball Valve',
    'Check Valve',
    'Control Valve',
    'Flange',
    'Elbow 90°',
    'Tee',
    'Reducer',
    'Pipe Support',
    'Pressure Gauge',
    'Transmitter',
    'Pump',
  ];

  static const List<Color> _presetColors = [
    Color(0xFF00E676), // Green
    Color(0xFFFF9100), // Amber
    Color(0xFF00E5FF), // Cyan
    Color(0xFFFF5252), // Red
    Color(0xFFE040FB), // Purple
    Color(0xFFFFD700), // Gold
  ];

  @override
  void initState() {
    super.initState();
    if (widget.viewerState.activeCountLabel.isNotEmpty) {
      _labelController.text = widget.viewerState.activeCountLabel;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countsOnPage = widget.viewerState.measurements
        .where((m) => m.type.name == 'count')
        .toList();

    // Group counts by label
    final Map<String, int> countSummary = {};
    for (final c in countsOnPage) {
      final label = c.countLabel.isEmpty ? 'Item' : c.countLabel;
      countSummary[label] = (countSummary[label] ?? 0) + 1;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pin_drop_outlined,
                    color: AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Component Count Tool',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Tap symbols on the drawing to place numbered badges',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Presets
            Text(
              'Quick Select Preset',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _labelController.text == preset;
                return ChoiceChip(
                  label: Text(preset),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primaryLight : null,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _labelController.text = preset;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Label input
            Text(
              'Component Name / Tag',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                hintText: 'e.g. 2" Gate Valve, HV-101, FE-204',
                prefixIcon: const Icon(Icons.label_outline, size: 20),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Badge Color
            Text(
              'Badge Color',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _presetColors.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.black87)
                        : null,
                  ),
                );
              }).toList(),
            ),

            if (countSummary.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Counts on this Sheet (${countsOnPage.length} total)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      for (final m in countsOnPage) {
                        widget.controller.deleteMeasurement(m.id);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView(
                  shrinkWrap: true,
                  children: countSummary.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${e.value} pcs',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Start Counting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final label = _labelController.text.trim();
                    widget.controller.startCountMode(
                      label: label.isEmpty ? 'Item' : label,
                      color: _selectedColor,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
