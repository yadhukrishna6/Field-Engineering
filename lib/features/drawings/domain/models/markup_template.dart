import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'markup.dart';

class MarkupTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final List<Markup> markups;

  const MarkupTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.markups,
  });

  static List<MarkupTemplate> get standardTemplates => [
        MarkupTemplate(
          id: 'tpl-tie-in-redline',
          name: 'Tie-In Redline Package',
          description: 'Cloud boundary with spec callout and tie-in nozzle tag',
          category: 'Piping',
          icon: Icons.cloud_queue_rounded,
          color: Colors.redAccent,
          markups: [
            Markup(
              id: const Uuid().v4(),
              drawingId: '',
              pageNumber: 1,
              layer: DrawingLayer.markup,
              type: MarkupType.revisionCloud,
              points: const [
                Point2D(0.40, 0.35),
                Point2D(0.60, 0.35),
                Point2D(0.60, 0.55),
                Point2D(0.40, 0.55),
              ],
              color: const Color(0xFFFF5252),
              strokeWidth: 3.0,
              text: 'TIE-IN POINT TP-04 (6"-HC-300# RF)',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: 'Lead Piping Engineer',
            ),
          ],
        ),
        MarkupTemplate(
          id: 'tpl-safety-psv-tag',
          name: 'PSV Safety Relief Warning',
          description: 'High-vis safety flag with design set-pressure tag',
          category: 'Safety',
          icon: Icons.warning_amber_rounded,
          color: Colors.amberAccent,
          markups: [
            Markup(
              id: const Uuid().v4(),
              drawingId: '',
              pageNumber: 1,
              layer: DrawingLayer.markup,
              type: MarkupType.arrow,
              points: const [Point2D(0.45, 0.40), Point2D(0.55, 0.40)],
              color: const Color(0xFFFFD740),
              strokeWidth: 3.5,
              text: 'CRITICAL: PSV-102 Set Pressure 35.0 Barg',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: 'Field Safety Officer',
            ),
          ],
        ),
        MarkupTemplate(
          id: 'tpl-electrical-clash',
          name: 'Cable Tray Interference Clash',
          description: 'High-voltage cable tray routing clash box with civil coordinates',
          category: 'Electrical',
          icon: Icons.electrical_services_rounded,
          color: Colors.purpleAccent,
          markups: [
            Markup(
              id: const Uuid().v4(),
              drawingId: '',
              pageNumber: 1,
              layer: DrawingLayer.markup,
              type: MarkupType.rectangle,
              points: const [
                Point2D(0.30, 0.60),
                Point2D(0.50, 0.60),
                Point2D(0.50, 0.75),
                Point2D(0.30, 0.75),
              ],
              color: const Color(0xFFE040FB),
              strokeWidth: 2.5,
              text: 'CLASH: 400V Tray vs 8" Steam Header',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: 'Lead Electrical Engineer',
            ),
          ],
        ),
      ];
}
