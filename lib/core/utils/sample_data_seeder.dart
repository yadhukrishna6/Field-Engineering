import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../features/projects/domain/models/project.dart';
import '../../features/projects/domain/models/project_status.dart';
import '../../features/projects/domain/repositories/projects_repository.dart';
import '../../features/drawings/domain/models/drawing.dart';
import '../../features/drawings/domain/models/drawing_type.dart';
import '../../features/drawings/domain/models/markup.dart';
import '../../features/drawings/domain/repositories/drawings_repository.dart';
import '../../features/drawings/domain/repositories/markups_repository.dart';
import 'drawing_generator.dart';

class SampleDataSeeder {
  static const _uuid = Uuid();

  static Future<void> seedIfEmpty({
    required ProjectsRepository projectsRepository,
    required DrawingsRepository drawingsRepository,
    MarkupsRepository? markupsRepository,
  }) async {
    try {
      final existingProjects = await projectsRepository.getProjects();
      if (existingProjects.isNotEmpty) {
        debugPrint('SampleDataSeeder: Projects already exist (${existingProjects.length}). Skipping seeding.');
        return;
      }

      debugPrint('SampleDataSeeder: Initializing offline field engineering demo data & blueprint markups...');

      // Project 1: Al-Khafji Gas Compression & Export Facility
      final project1 = Project(
        id: 'proj_alkhafji_01',
        projectNumber: 'EPC-2026-084',
        name: 'Al-Khafji Gas Compression & Dehydration Plant',
        description: 'Engineering and field inspection of 180 MMSCFD high-pressure sour gas compression station, glycol dehydration unit, and 24" export pipeline header.',
        client: 'Saudi Aramco / KJO Consortium',
        location: 'Neutral Zone, Offshore & Onshore Terminal',
        status: ProjectStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      // Project 2: Ras Tanura Refinery Piping Revamp
      final project2 = Project(
        id: 'proj_rastanura_02',
        projectNumber: 'REV-2025-119',
        name: 'Ras Tanura Crude Distillation Unit (CDU-4) Revamp',
        description: 'Field replacement and tie-in inspection of ASTM A335 Grade P11 high-temperature piping runs, heat exchanger bypass loops, and safety relief manifolds.',
        client: 'Aramco Downstream Operations',
        location: 'Ras Tanura Industrial City',
        status: ProjectStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      // Project 3: Das Island Off-Gas Flare Recovery
      final project3 = Project(
        id: 'proj_dasisland_03',
        projectNumber: 'FLR-2026-042',
        name: 'Das Island Zero Flaring & Flare Gas Recovery System',
        description: 'EPC field inspection and hydrotesting of flare gas recovery skid, liquid ring compressors, and 16" duplex stainless steel discharge lines.',
        client: 'ADNOC Offshore',
        location: 'Das Island, UAE',
        status: ProjectStatus.onHold,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now().subtract(const Duration(days: 12)),
      );

      // Project 4: Basra South Crude Storage Terminal
      final project4 = Project(
        id: 'proj_basra_04',
        projectNumber: 'STG-2024-301',
        name: 'Basra South Crude Storage Tank Farm (Phase 3)',
        description: 'Completed construction inspection of 4x 500,000 bbl floating roof storage tanks, foam fire suppression network, and fiscal metering skids.',
        client: 'Basra Oil Company (BOC)',
        location: 'Basra, Iraq',
        status: ProjectStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 360)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      await projectsRepository.createProject(project1);
      await projectsRepository.createProject(project2);
      await projectsRepository.createProject(project3);
      await projectsRepository.createProject(project4);

      // Generate Authentic Vector PDF Drawings for Project 1
      final drawing1 = await _createSampleDrawing(
        drawingsRepository: drawingsRepository,
        projectId: project1.id,
        projectName: project1.name,
        clientName: project1.client,
        drawingNumber: '084-PID-001',
        title: 'HP Production Separator V-101 & Gas Compression Train P&ID',
        drawingType: DrawingType.pid,
        revision: 'Rev 2',
        pageCount: 2,
        downloaded: true,
      );

      await _createSampleDrawing(
        drawingsRepository: drawingsRepository,
        projectId: project1.id,
        projectName: project1.name,
        clientName: project1.client,
        drawingNumber: '084-ISO-3001',
        title: '6"-P-3001-CS300 HP Gas Discharge Line to Scrubber Isometric',
        drawingType: DrawingType.isometric,
        revision: 'Rev B',
        pageCount: 1,
        downloaded: true,
      );

      await _createSampleDrawing(
        drawingsRepository: drawingsRepository,
        projectId: project1.id,
        projectName: project1.name,
        clientName: project1.client,
        drawingNumber: '084-SLD-401',
        title: 'Substation-01 33kV/6.6kV/415V Power Distribution SLD',
        drawingType: DrawingType.electrical,
        revision: 'Rev 1',
        pageCount: 1,
        downloaded: true,
      );

      await _createSampleDrawing(
        drawingsRepository: drawingsRepository,
        projectId: project1.id,
        projectName: project1.name,
        clientName: project1.client,
        drawingNumber: '084-STR-205',
        title: 'Compressor Shelter Heavy Steel Structure & Crane Rail GA',
        drawingType: DrawingType.structural,
        revision: 'Rev 0',
        pageCount: 2,
        downloaded: false,
      );

      // Generate Sample Drawings for Project 2
      await _createSampleDrawing(
        drawingsRepository: drawingsRepository,
        projectId: project2.id,
        projectName: project2.name,
        clientName: project2.client,
        drawingNumber: '119-PID-102',
        title: 'CDU-4 Crude Feed Pre-Heat Exchanger Train E-201A/B/C/D',
        drawingType: DrawingType.pid,
        revision: 'Rev 3',
        pageCount: 2,
        downloaded: true,
      );

      // Seed Initial Engineering Markups on 084-PID-001
      if (drawing1 != null && markupsRepository != null) {
        final sampleMarkups = [
          // 1. Revision Cloud over Separator V-101
          Markup(
            id: 'markup_cloud_01',
            drawingId: drawing1.id,
            pageNumber: 1,
            layer: DrawingLayer.markup,
            type: MarkupType.revisionCloud,
            color: const Color(0xFFD32F2F), // Safety Red
            strokeWidth: 2.5,
            opacity: 1.0,
            bounds: const Rect.fromLTRB(0.08, 0.15, 0.40, 0.45),
            createdBy: 'Lead Field Piping Engineer',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          // 2. Callout Text for Nozzle Tie-in
          Markup(
            id: 'markup_text_02',
            drawingId: drawing1.id,
            pageNumber: 1,
            layer: DrawingLayer.markup,
            type: MarkupType.text,
            color: const Color(0xFFD32F2F),
            strokeWidth: 2.0,
            points: [const Point2D(0.42, 0.20)],
            bounds: const Rect.fromLTWH(0.42, 0.20, 0.22, 0.06),
            text: 'REV 2: Added 2" Drain Bypass Nozzle N6 per DCN-084-012',
            fontSize: 13.0,
            createdBy: 'Lead Field Piping Engineer',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          // 3. Arrow Leader Line connecting text to cloud
          Markup(
            id: 'markup_arrow_03',
            drawingId: drawing1.id,
            pageNumber: 1,
            layer: DrawingLayer.markup,
            type: MarkupType.arrow,
            color: const Color(0xFFD32F2F),
            strokeWidth: 2.0,
            points: [const Point2D(0.41, 0.22), const Point2D(0.38, 0.24)],
            createdBy: 'Lead Field Piping Engineer',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          // 4. Punchlist Issue Pin on Gas Discharge Line
          Markup(
            id: 'markup_pin_04',
            drawingId: drawing1.id,
            pageNumber: 1,
            layer: DrawingLayer.issue,
            type: MarkupType.issuePin,
            color: Colors.redAccent,
            strokeWidth: 2.0,
            points: [const Point2D(0.52, 0.35)],
            text: 'PNC-01',
            metadata: {'title': 'Flange misalignment on 8"-HC-1001-A1A', 'status': 'OPEN', 'severity': 'HIGH'},
            createdBy: 'Lead QA/QC Inspector',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          // 5. Dimension Measurement Line on Separator Skirt
          Markup(
            id: 'markup_dim_05',
            drawingId: drawing1.id,
            pageNumber: 1,
            layer: DrawingLayer.measurement,
            type: MarkupType.measurement,
            color: const Color(0xFF1565C0), // Blue
            strokeWidth: 1.5,
            points: [const Point2D(0.12, 0.48), const Point2D(0.35, 0.48)],
            text: '2850 mm (C/C Distance)',
            createdBy: 'Lead Field Piping Engineer',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];

        await markupsRepository.saveMarkupsBatch(sampleMarkups);
      }

      debugPrint('SampleDataSeeder: Seeded projects, vector blueprints, and engineering annotations successfully.');
    } catch (e, st) {
      debugPrint('Error during sample seeding: $e\n$st');
    }
  }

  static Future<Drawing?> _createSampleDrawing({
    required DrawingsRepository drawingsRepository,
    required String projectId,
    required String projectName,
    required String clientName,
    required String drawingNumber,
    required String title,
    required DrawingType drawingType,
    required String revision,
    required int pageCount,
    required bool downloaded,
  }) async {
    try {
      final pdfFile = await DrawingGenerator.generateSampleEngineeringPdf(
        drawingNumber: drawingNumber,
        title: title,
        projectName: projectName,
        clientName: clientName,
        drawingType: drawingType,
        revision: revision,
        pageCount: pageCount,
      );

      final fileSize = await pdfFile.length();

      final drawing = Drawing(
        id: _uuid.v4(),
        projectId: projectId,
        drawingNumber: drawingNumber,
        title: title,
        drawingType: drawingType,
        revision: revision,
        filePath: pdfFile.path,
        thumbnailPath: null,
        pageCount: pageCount,
        fileSize: fileSize,
        downloaded: downloaded,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      return await drawingsRepository.addDrawing(drawing);
    } catch (e) {
      debugPrint('Error creating sample drawing $drawingNumber: $e');
      return null;
    }
  }
}
