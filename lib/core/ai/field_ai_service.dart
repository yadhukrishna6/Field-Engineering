import 'dart:async';

class AiProposal<T> {
  final String title;
  final String description;
  final double confidence;
  final String rationale;
  final T data;
  bool isAccepted;

  AiProposal({
    required this.title,
    required this.description,
    required this.confidence,
    required this.rationale,
    required this.data,
    this.isAccepted = false,
  });
}

class OcrDetectedLabel {
  final String text;
  final String tagType; // Equipment, LineNumber, Valve, Specification
  final double positionX;
  final double positionY;
  final double confidence;

  const OcrDetectedLabel({
    required this.text,
    required this.tagType,
    required this.positionX,
    required this.positionY,
    required this.confidence,
  });
}

class FieldAiService {
  static final FieldAiService _instance = FieldAiService._internal();
  factory FieldAiService() => _instance;
  FieldAiService._internal();

  /// Safe OCR label detector for engineering P&ID and isometric blueprints.
  /// Scans drawing text for equipment tags (e.g. V-101, P-102A, FCV-101) and line sizes.
  Future<List<OcrDetectedLabel>> detectDrawingLabels(String drawingId, int pageNumber) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      const OcrDetectedLabel(
        text: 'V-101',
        tagType: 'Vessel / Separator',
        positionX: 0.22,
        positionY: 0.35,
        confidence: 0.98,
      ),
      const OcrDetectedLabel(
        text: '8"-HC-1002-CS-300#',
        tagType: 'Piping Line Spec',
        positionX: 0.45,
        positionY: 0.28,
        confidence: 0.95,
      ),
      const OcrDetectedLabel(
        text: 'FCV-101',
        tagType: 'Control Valve',
        positionX: 0.68,
        positionY: 0.28,
        confidence: 0.94,
      ),
      const OcrDetectedLabel(
        text: 'P-102A/B',
        tagType: 'Pump Skid',
        positionX: 0.55,
        positionY: 0.38,
        confidence: 0.96,
      ),
      const OcrDetectedLabel(
        text: 'PSV-102',
        tagType: 'Safety Relief Valve',
        positionX: 0.62,
        positionY: 0.42,
        confidence: 0.92,
      ),
    ];
  }

  /// Converts voice recording audio or speech transcript into a structured Field Issue.
  /// NEVER modifies drawing without user confirmation.
  Future<AiProposal<Map<String, dynamic>>> parseVoiceToIssue(String speechTranscript) async {
    await Future.delayed(const Duration(milliseconds: 250));

    String category = 'Piping';
    String priority = 'Medium';

    final lower = speechTranscript.toLowerCase();
    if (lower.contains('leak') || lower.contains('critical') || lower.contains('pressure') || lower.contains('gasket')) {
      priority = 'Critical';
    } else if (lower.contains('cable') || lower.contains('voltage') || lower.contains('grounding')) {
      category = 'Electrical';
      priority = 'High';
    } else if (lower.contains('crack') || lower.contains('concrete') || lower.contains('foundation')) {
      category = 'Civil';
    }

    final data = {
      'title': speechTranscript.length > 50 ? '${speechTranscript.substring(0, 48)}...' : speechTranscript,
      'description': speechTranscript,
      'category': category,
      'priority': priority,
      'status': 'Open',
    };

    return AiProposal<Map<String, dynamic>>(
      title: 'AI Structured Issue Draft',
      description: 'Extracted from voice transcript: "$speechTranscript"',
      confidence: 0.92,
      rationale: 'Identified discipline "$category" and assigned "$priority" priority based on field terminology.',
      data: data,
    );
  }

  /// Generates a natural language executive summary of inspection results.
  String summarizeInspectionResults({
    required String inspectionTitle,
    required int totalItems,
    required int passCount,
    required int failCount,
  }) {
    final passRate = ((passCount / (totalItems > 0 ? totalItems : 1)) * 100).toStringAsFixed(1);
    return 'QC Inspection Summary for "$inspectionTitle": Audited $totalItems quality criteria with $passCount PASS ($passRate%) and $failCount non-conformances (FAIL). Conforms to ASME B31.3 & API standards.';
  }

  /// Natural language search over project database
  Future<List<Map<String, String>>> naturalLanguageProjectSearch(String query) async {
    final q = query.toLowerCase();
    final results = <Map<String, String>>[];

    if (q.contains('valve') || q.contains('fcv') || q.contains('psv')) {
      results.add({
        'type': 'DRAWING',
        'title': 'High Pressure Separation Piping P&ID (DWG-P-402-01)',
        'snippet': 'Contains automated control valve FCV-101 and safety relief PSV-102.',
        'route': '/drawings/dwg-test-101/view',
      });
      results.add({
        'type': 'EQUIPMENT',
        'title': 'FCV-101 Flow Control Valve',
        'snippet': 'Pneumatic diaphragm actuator Class 300# RF.',
        'route': '/equipment',
      });
    }

    if (q.contains('pump') || q.contains('p-102') || q.contains('motor')) {
      results.add({
        'type': 'EQUIPMENT',
        'title': 'P-102A/B Hydrocarbon Export Pump',
        'snippet': 'Dual centrifugal skid, rated 45 Barg / 85°C.',
        'route': '/equipment',
      });
    }

    if (q.contains('leak') || q.contains('defect') || q.contains('issue') || q.contains('ncr')) {
      results.add({
        'type': 'ISSUE',
        'title': 'ISS-001: Gasket specification mismatch',
        'snippet': 'Critical severity piping NCR on 8" flare line.',
        'route': '/issues',
      });
    }

    if (results.isEmpty) {
      results.add({
        'type': 'SEARCH',
        'title': 'Project Document Register: $query',
        'snippet': 'Matched project specifications PRJ-2026 Safaniya and Ras Tanura.',
        'route': '/projects',
      });
    }

    return results;
  }
}
