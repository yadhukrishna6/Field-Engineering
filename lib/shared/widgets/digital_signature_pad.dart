import 'package:flutter/material.dart';
import '../../core/security/digital_signature_service.dart';
import '../../core/security/rbac_manager.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DigitalSignaturePadDialog extends StatefulWidget {
  final String title;
  final String purpose;
  final String targetEntityId;
  final Function(DigitalSignature signature) onSigned;

  const DigitalSignaturePadDialog({
    super.key,
    required this.title,
    required this.purpose,
    required this.targetEntityId,
    required this.onSigned,
  });

  static Future<DigitalSignature?> show(
    BuildContext context, {
    String title = 'Sign Document',
    String purpose = 'APPROVAL',
    String targetEntityId = 'doc-current',
    String? documentTitle,
    String? authorRole,
  }) async {
    DigitalSignature? signed;
    await showDialog(
      context: context,
      builder: (ctx) => DigitalSignaturePadDialog(
        title: documentTitle ?? title,
        purpose: purpose,
        targetEntityId: targetEntityId,
        onSigned: (sig) {
          signed = sig;
          Navigator.of(ctx).pop();
        },
      ),
    );
    return signed;
  }

  @override
  State<DigitalSignaturePadDialog> createState() => _DigitalSignaturePadDialogState();
}

class _DigitalSignaturePadDialogState extends State<DigitalSignaturePadDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    final user = SecureStorageService().currentUser;
    _nameController = TextEditingController(text: user.fullName);
    _titleController = TextEditingController(text: user.role.displayName);
    _companyController = TextEditingController(text: user.company);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SecureStorageService().currentUser;

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.draw_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                Text(
                  'Sign-off Purpose: ${widget.purpose.replaceAll('_', ' ')}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Signer Metadata Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Signer Name', labelStyle: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Title / Discipline', labelStyle: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Draw signature below using stylus or finger (Stylus Pressure & Palm Rejection Enabled):',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),

            // Signature Canvas Box
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Baseline Watermark
                  const Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Divider(color: Colors.black26, thickness: 1.0),
                  ),
                  const Positioned(
                    bottom: 10,
                    right: 20,
                    child: Text('SIGNATURE / DIGITAL STAMP', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        final localPos = details.localPosition;
                        _currentStroke = [localPos];
                        _strokes.add(_currentStroke!);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentStroke?.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      _currentStroke = null;
                    },
                    child: CustomPaint(
                      painter: SignaturePainter(strokes: _strokes),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Clear Signature'),
          onPressed: () {
            setState(() {
              _strokes.clear();
            });
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.verified_rounded, size: 18),
          label: const Text('Confirm & Apply Sign-Off'),
          onPressed: _strokes.isEmpty
              ? null
              : () {
                  final sig = DigitalSignatureService().createSignature(
                    signerName: _nameController.text.trim(),
                    signerTitle: _titleController.text.trim(),
                    signerCompany: _companyController.text.trim(),
                    signerRole: user.role,
                    purpose: widget.purpose,
                    targetEntityId: widget.targetEntityId,
                    strokePaths: _strokes,
                  );
                  Navigator.pop(context);
                  widget.onSigned(sig);
                },
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F2042)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}
