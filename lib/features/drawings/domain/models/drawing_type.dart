import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

enum DrawingType {
  pid,
  isometric,
  electrical,
  mechanical,
  structural,
  civil,
  piping,
  general,
}

extension DrawingTypeExtension on DrawingType {
  String get code {
    switch (this) {
      case DrawingType.pid:
        return 'P&ID';
      case DrawingType.isometric:
        return 'ISO';
      case DrawingType.electrical:
        return 'ELEC';
      case DrawingType.mechanical:
        return 'MECH';
      case DrawingType.structural:
        return 'STR';
      case DrawingType.civil:
        return 'CIVIL';
      case DrawingType.piping:
        return 'PIPE';
      case DrawingType.general:
        return 'GA';
    }
  }

  String get displayName {
    switch (this) {
      case DrawingType.pid:
        return 'Process & Instrumentation (P&ID)';
      case DrawingType.isometric:
        return 'Piping Isometric (ISO)';
      case DrawingType.electrical:
        return 'Electrical & Instrument (SLD)';
      case DrawingType.mechanical:
        return 'Mechanical & Equipment (GA)';
      case DrawingType.structural:
        return 'Structural & Framing (STR)';
      case DrawingType.civil:
        return 'Civil & Foundation (CIVIL)';
      case DrawingType.piping:
        return 'Piping General Arrangement';
      case DrawingType.general:
        return 'General Layout & Site Plan';
    }
  }

  Color get color {
    switch (this) {
      case DrawingType.pid:
        return AppColors.drawingPid;
      case DrawingType.isometric:
        return AppColors.drawingIsometric;
      case DrawingType.electrical:
        return AppColors.drawingElectrical;
      case DrawingType.mechanical:
        return AppColors.drawingMechanical;
      case DrawingType.structural:
        return AppColors.drawingStructural;
      case DrawingType.civil:
        return AppColors.drawingCivil;
      case DrawingType.piping:
        return AppColors.drawingPiping;
      case DrawingType.general:
        return AppColors.drawingGeneral;
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingType.pid:
        return Icons.schema_rounded;
      case DrawingType.isometric:
        return Icons.view_in_ar_rounded;
      case DrawingType.electrical:
        return Icons.electrical_services_rounded;
      case DrawingType.mechanical:
        return Icons.precision_manufacturing_rounded;
      case DrawingType.structural:
        return Icons.architecture_rounded;
      case DrawingType.civil:
        return Icons.foundation_rounded;
      case DrawingType.piping:
        return Icons.alt_route_rounded;
      case DrawingType.general:
        return Icons.map_rounded;
    }
  }

  static DrawingType fromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'pid':
      case 'p&id':
        return DrawingType.pid;
      case 'isometric':
      case 'iso':
        return DrawingType.isometric;
      case 'electrical':
      case 'elec':
      case 'sld':
        return DrawingType.electrical;
      case 'mechanical':
      case 'mech':
        return DrawingType.mechanical;
      case 'structural':
      case 'str':
        return DrawingType.structural;
      case 'civil':
        return DrawingType.civil;
      case 'piping':
      case 'pipe':
        return DrawingType.piping;
      case 'general':
      case 'ga':
      default:
        return DrawingType.general;
    }
  }
}
