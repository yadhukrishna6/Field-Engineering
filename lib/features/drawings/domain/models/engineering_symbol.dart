import 'package:flutter/material.dart';

enum SymbolCategory {
  valves,
  pumpsVessels,
  instrumentation,
  electrical,
  pipingFittings,
  stamps,
}

extension SymbolCategoryExtension on SymbolCategory {
  String get displayName {
    switch (this) {
      case SymbolCategory.valves:
        return 'P&ID Valves';
      case SymbolCategory.pumpsVessels:
        return 'Pumps & Vessels';
      case SymbolCategory.instrumentation:
        return 'Instrumentation & Controls';
      case SymbolCategory.electrical:
        return 'Electrical & Power';
      case SymbolCategory.pipingFittings:
        return 'Piping & Fittings';
      case SymbolCategory.stamps:
        return 'Engineering Stamps';
    }
  }

  IconData get icon {
    switch (this) {
      case SymbolCategory.valves:
        return Icons.tune_rounded;
      case SymbolCategory.pumpsVessels:
        return Icons.water_damage_rounded;
      case SymbolCategory.instrumentation:
        return Icons.speed_rounded;
      case SymbolCategory.electrical:
        return Icons.bolt_rounded;
      case SymbolCategory.pipingFittings:
        return Icons.timeline_rounded;
      case SymbolCategory.stamps:
        return Icons.approval_rounded;
    }
  }
}

class EngineeringSymbol {
  final String id;
  final String name;
  final String tagPrefix;
  final SymbolCategory category;
  final String description;
  final IconData icon;
  final Color defaultColor;
  final bool isStamp;
  final String? stampText;

  const EngineeringSymbol({
    required this.id,
    required this.name,
    required this.tagPrefix,
    required this.category,
    required this.description,
    required this.icon,
    this.defaultColor = Colors.cyanAccent,
    this.isStamp = false,
    this.stampText,
  });

  static List<EngineeringSymbol> get standardLibrary => [
        // --- 1. P&ID Valves ---
        const EngineeringSymbol(
          id: 'sym-gate-valve',
          name: 'Gate Valve (ISO 10628)',
          tagPrefix: 'GV',
          category: SymbolCategory.valves,
          description: 'Standard bi-directional isolation gate valve',
          icon: Icons.hourglass_empty_rounded,
          defaultColor: Colors.cyanAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-globe-valve',
          name: 'Globe Valve (Throttling)',
          tagPrefix: 'GLV',
          category: SymbolCategory.valves,
          description: 'Linear motion throttling and flow control valve',
          icon: Icons.circle_outlined,
          defaultColor: Colors.cyanAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-ball-valve',
          name: 'Ball Valve (Quarter-Turn)',
          tagPrefix: 'BV',
          category: SymbolCategory.valves,
          description: 'Full/Reduced bore quarter-turn shutoff valve',
          icon: Icons.radio_button_checked_rounded,
          defaultColor: Colors.cyanAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-check-valve',
          name: 'Check / Non-Return Valve',
          tagPrefix: 'NRV',
          category: SymbolCategory.valves,
          description: 'Swing check valve to prevent backflow',
          icon: Icons.play_arrow_outlined,
          defaultColor: Colors.cyanAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-control-valve',
          name: 'Automated Control Valve',
          tagPrefix: 'FCV',
          category: SymbolCategory.valves,
          description: 'Pneumatic actuator diaphragm control valve',
          icon: Icons.crop_square_rounded,
          defaultColor: Colors.amberAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-psv',
          name: 'Pressure Safety Valve (PSV)',
          tagPrefix: 'PSV',
          category: SymbolCategory.valves,
          description: 'Overpressure relief safety valve with discharge to flare',
          icon: Icons.arrow_upward_rounded,
          defaultColor: Colors.redAccent,
        ),

        // --- 2. Pumps & Vessels ---
        const EngineeringSymbol(
          id: 'sym-centrifugal-pump',
          name: 'Centrifugal Process Pump',
          tagPrefix: 'P',
          category: SymbolCategory.pumpsVessels,
          description: 'Motor-driven centrifugal hydrocarbon pump',
          icon: Icons.rotate_right_rounded,
          defaultColor: Colors.lightGreenAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-separator-vessel',
          name: '3-Phase High Pressure Separator',
          tagPrefix: 'V',
          category: SymbolCategory.pumpsVessels,
          description: 'Horizontal separator for oil, water, and gas separation',
          icon: Icons.crop_16_9_rounded,
          defaultColor: Colors.lightGreenAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-heat-exchanger',
          name: 'Shell & Tube Heat Exchanger',
          tagPrefix: 'E',
          category: SymbolCategory.pumpsVessels,
          description: 'Counter-current process heat exchanger',
          icon: Icons.sync_alt_rounded,
          defaultColor: Colors.lightGreenAccent,
        ),

        // --- 3. Instrumentation & Controls ---
        const EngineeringSymbol(
          id: 'sym-pt',
          name: 'Pressure Transmitter (PT)',
          tagPrefix: 'PT',
          category: SymbolCategory.instrumentation,
          description: '4-20mA HART digital pressure transmitter',
          icon: Icons.speed_rounded,
          defaultColor: Colors.orangeAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-tt',
          name: 'Temperature Transmitter (TT)',
          tagPrefix: 'TT',
          category: SymbolCategory.instrumentation,
          description: 'RTD / Thermocouple process temperature transmitter',
          icon: Icons.thermostat_rounded,
          defaultColor: Colors.orangeAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-ft',
          name: 'Flow Transmitter / Orifice (FT)',
          tagPrefix: 'FT',
          category: SymbolCategory.instrumentation,
          description: 'Coriolis / Ultrasonic process mass flow meter',
          icon: Icons.waves_rounded,
          defaultColor: Colors.orangeAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-lt',
          name: 'Level Transmitter (LT)',
          tagPrefix: 'LT',
          category: SymbolCategory.instrumentation,
          description: 'Guided wave radar vessel level sensor',
          icon: Icons.straighten_rounded,
          defaultColor: Colors.orangeAccent,
        ),

        // --- 4. Electrical & Power ---
        const EngineeringSymbol(
          id: 'sym-motor',
          name: 'Electric Drive Motor (M)',
          tagPrefix: 'M',
          category: SymbolCategory.electrical,
          description: '3-Phase 400V Explosion-proof induction motor (ATEX/IECEx)',
          icon: Icons.electric_bolt_rounded,
          defaultColor: Colors.yellowAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-transformer',
          name: 'Step-Down Power Transformer',
          tagPrefix: 'TX',
          category: SymbolCategory.electrical,
          description: '13.8kV / 480V substation oil-immersed transformer',
          icon: Icons.alt_route_rounded,
          defaultColor: Colors.yellowAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-circuit-breaker',
          name: 'HV Vacuum Circuit Breaker (VCB)',
          tagPrefix: 'CB',
          category: SymbolCategory.electrical,
          description: 'Switchgear vacuum circuit interrupter',
          icon: Icons.power_rounded,
          defaultColor: Colors.yellowAccent,
        ),

        // --- 5. Piping & Fittings ---
        const EngineeringSymbol(
          id: 'sym-flange-pair',
          name: 'Weld Neck Flange Pair (RF)',
          tagPrefix: 'FLG',
          category: SymbolCategory.pipingFittings,
          description: 'ASME B16.5 Class 300# Raised Face Flange connection',
          icon: Icons.horizontal_split_rounded,
          defaultColor: Colors.cyanAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-concentric-reducer',
          name: 'Concentric Pipe Reducer',
          tagPrefix: 'RED',
          category: SymbolCategory.pipingFittings,
          description: '8" to 6" Sch 40 concentric line reducer',
          icon: Icons.filter_list_rounded,
          defaultColor: Colors.cyanAccent,
        ),
        const EngineeringSymbol(
          id: 'sym-spectacle-blind',
          name: 'Spectacle Blind (Open/Closed)',
          tagPrefix: 'SB',
          category: SymbolCategory.pipingFittings,
          description: 'Positive isolation spectacle blind flange',
          icon: Icons.looks_two_rounded,
          defaultColor: Colors.cyanAccent,
        ),

        // --- 6. Engineering Certification Stamps ---
        const EngineeringSymbol(
          id: 'stamp-approved-ifc',
          name: 'APPROVED FOR CONSTRUCTION (IFC)',
          tagPrefix: 'STAMP-IFC',
          category: SymbolCategory.stamps,
          description: 'Official IFC release stamp signed by Lead Engineer',
          icon: Icons.verified_rounded,
          defaultColor: Colors.greenAccent,
          isStamp: true,
          stampText: 'APPROVED FOR CONSTRUCTION\nEPC PROJECT CONTROLS\nLEAD PE VERIFIED',
        ),
        const EngineeringSymbol(
          id: 'stamp-as-built',
          name: 'AS-BUILT FIELD CERTIFIED',
          tagPrefix: 'STAMP-ASB',
          category: SymbolCategory.stamps,
          description: 'Certified as-built field redline verification stamp',
          icon: Icons.verified_user_rounded,
          defaultColor: Colors.blueAccent,
          isStamp: true,
          stampText: 'AS-BUILT RECORD DRAWING\nFIELD MODIFICATIONS ACCEPTED\nFINAL HANDOVER',
        ),
        const EngineeringSymbol(
          id: 'stamp-hold',
          name: 'ENGINEERING HOLD (CRITICAL)',
          tagPrefix: 'STAMP-HLD',
          category: SymbolCategory.stamps,
          description: 'Work stopped pending technical clarification / TQ',
          icon: Icons.pause_circle_filled_rounded,
          defaultColor: Colors.amberAccent,
          isStamp: true,
          stampText: 'ENGINEERING HOLD\nDO NOT PROCEED WITH CONSTRUCTION\nPENDING TQ RESOLUTION',
        ),
        const EngineeringSymbol(
          id: 'stamp-ncr',
          name: 'NON-CONFORMANCE (NCR REJECTED)',
          tagPrefix: 'STAMP-NCR',
          category: SymbolCategory.stamps,
          description: 'Quality non-conformance rejection stamp',
          icon: Icons.cancel_rounded,
          defaultColor: Colors.redAccent,
          isStamp: true,
          stampText: 'REJECTED - QUALITY NCR\nDOES NOT CONFORM TO SPECIFICATION\nRECTIFICATION REQUIRED',
        ),
        const EngineeringSymbol(
          id: 'stamp-pre-comm',
          name: 'PRE-COMMISSIONING ACCEPTED',
          tagPrefix: 'STAMP-PCM',
          category: SymbolCategory.stamps,
          description: 'Pre-commissioning walkdown sign-off stamp',
          icon: Icons.task_alt_rounded,
          defaultColor: Colors.purpleAccent,
          isStamp: true,
          stampText: 'PRE-COMMISSIONING ACCEPTED\nHIDROTEST & PUNCH A CLEARED\nREADY FOR STARTUP',
        ),
      ];
}
