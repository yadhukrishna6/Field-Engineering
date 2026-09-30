import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/equipment_qr_payload.dart';

typedef EquipmentQrScannerScreen = QrScannerScreen;

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _manualTagController = TextEditingController();
  EquipmentQrPayload? _scannedResult;

  final List<EquipmentQrPayload> _sampleTags = const [
    EquipmentQrPayload(
      tagNumber: 'V-101',
      equipmentNumber: 'EQ-SEP-101',
      name: 'High Pressure 3-Phase Separator',
      projectId: 'PRJ-101',
      drawingId: 'DWG-P-402-01',
      discipline: 'Vessels & Static Equipment',
    ),
    EquipmentQrPayload(
      tagNumber: 'P-102A',
      equipmentNumber: 'EQ-PMP-102A',
      name: 'Main Hydrocarbon Export Pump A',
      projectId: 'PRJ-101',
      drawingId: 'DWG-P-402-01',
      discipline: 'Rotary Machinery',
    ),
    EquipmentQrPayload(
      tagNumber: 'FCV-101',
      equipmentNumber: 'EQ-VAL-101',
      name: 'Automated Pneumatic Flow Control Valve',
      projectId: 'PRJ-101',
      drawingId: 'DWG-P-402-01',
      discipline: 'Instrumentation & Controls',
    ),
    EquipmentQrPayload(
      tagNumber: 'PSV-102',
      equipmentNumber: 'EQ-SAF-102',
      name: 'Overpressure Relief Safety Valve',
      projectId: 'PRJ-101',
      drawingId: 'DWG-P-402-01',
      discipline: 'Safety & Relief Systems',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _manualTagController.dispose();
    super.dispose();
  }

  void _onTagScanned(EquipmentQrPayload payload) {
    setState(() {
      _scannedResult = payload;
    });
    _showEquipmentDetailsModal(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Equipment QR & Barcode Scanner', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
          ],
        ),
      ),
      body: Row(
        children: [
          // Left: Camera Viewfinder Simulation
          Expanded(
            flex: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Simulated Camera Background
                Container(
                  color: const Color(0xFF10141D),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 72, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        const Text(
                          'Point tablet camera at equipment QR code or barcode tag',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // Viewfinder Target Frame
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Animated Laser Scan Line
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: 300 * _animationController.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 8, spreadRadius: 2),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Viewfinder Corner Accents
                Positioned(
                  bottom: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.amberAccent, size: 16),
                        SizedBox(width: 6),
                        Text('Torch: ON • Auto-Focus: Continuous • High-Sensitivity',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Manual Tag Entry & Field Samples Panel
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.surfaceDark,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manual Tag Number Lookup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Enter equipment tag or select sample field equipment for instant lookup:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualTagController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Equipment Tag (e.g. P-102A)',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          ),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) {
                              final payload = EquipmentQrPayload.parse(v.trim());
                              if (payload != null) _onTagScanned(payload);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        onPressed: () {
                          if (_manualTagController.text.trim().isNotEmpty) {
                            final payload = EquipmentQrPayload.parse(_manualTagController.text.trim());
                            if (payload != null) _onTagScanned(payload);
                          }
                        },
                        child: const Text('Lookup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  const Text('Sample Field Equipment Tags (1-Tap Simulation):',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.separated(
                      itemCount: _sampleTags.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tag = _sampleTags[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.qr_code, color: AppColors.primary, size: 20),
                            ),
                            title: Text(tag.tagNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('${tag.name} • ${tag.discipline}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
                            onTap: () => _onTagScanned(tag),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEquipmentDetailsModal(EquipmentQrPayload payload) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tag: ${payload.tagNumber}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${payload.name} (${payload.equipmentNumber})',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: const Text('OPERATIONAL',
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 28),

              // 6 Deep-Link Action Cards (Drawings, Issues, Inspections, Photos, History, Profile)
              const Text('Linked Field Operations & Drawings:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    // 1. Open Linked Drawing
                    _buildDeepLinkCard(
                      icon: Icons.layers_rounded,
                      title: 'Linked P&ID Drawing',
                      subtitle: payload.drawingId ?? 'DWG-P-402-01',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/drawings/dwg-test-101/view');
                      },
                    ),

                    // 2. Open Issues
                    _buildDeepLinkCard(
                      icon: Icons.bug_report_outlined,
                      title: 'Field Issues / NCRs',
                      subtitle: '2 Active Defects',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/issues');
                      },
                    ),

                    // 3. Inspections
                    _buildDeepLinkCard(
                      icon: Icons.fact_check_outlined,
                      title: 'QC Inspections',
                      subtitle: 'Last Pass: 2026-09-28',
                      color: Colors.greenAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/inspections');
                      },
                    ),

                    // 4. Photos & Media
                    _buildDeepLinkCard(
                      icon: Icons.photo_camera_back_outlined,
                      title: 'Field Photographs',
                      subtitle: '4 Photos Attached',
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/equipment');
                      },
                    ),

                    // 5. As-Built & Handover History
                    _buildDeepLinkCard(
                      icon: Icons.history_edu_rounded,
                      title: 'As-Built Dossier',
                      subtitle: 'Stage: Approved (IFC)',
                      color: Colors.amberAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/reports');
                      },
                    ),

                    // 6. Master Registry Profile
                    _buildDeepLinkCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Equipment Master',
                      subtitle: payload.discipline,
                      color: Colors.cyanAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/equipment');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeepLinkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                Icon(Icons.arrow_forward, color: color.withOpacity(0.6), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
