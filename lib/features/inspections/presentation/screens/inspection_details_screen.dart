import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/digital_signature_pad.dart';

class InspectionDetailsScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const InspectionDetailsScreen({super.key, required this.inspectionId});

  @override
  ConsumerState<InspectionDetailsScreen> createState() => _InspectionDetailsScreenState();
}

class _InspectionDetailsScreenState extends ConsumerState<InspectionDetailsScreen> {
  final TextEditingController _commentsController = TextEditingController(
    text: 'Installation verified. Minor adjustment required on support location.',
  );

  final List<Map<String, dynamic>> _checklist = [
    {'title': 'Pipe installed as per drawing', 'status': 'Pass'},
    {'title': 'Correct diameter and material', 'status': 'Pass'},
    {'title': 'Flange installed', 'status': 'Pending'},
    {'title': 'Valve installed', 'status': 'Pass'},
    {'title': 'Support installed', 'status': 'Fail'},
    {'title': 'Welding completed', 'status': 'N/A'},
    {'title': 'Insulating completed', 'status': 'Pending'},
    {'title': 'Hydro test completed', 'status': 'N/A'},
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pass':
        return const Color(0xFF16A34A);
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Fail':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  void _cycleStatus(int index) {
    setState(() {
      final current = _checklist[index]['status'];
      if (current == 'Pass') {
        _checklist[index]['status'] = 'Pending';
      } else if (current == 'Pending') {
        _checklist[index]['status'] = 'Fail';
      } else if (current == 'Fail') {
        _checklist[index]['status'] = 'N/A';
      } else {
        _checklist[index]['status'] = 'Pass';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inspections');
            }
          },
        ),
        title: Text(
          'Piping Inspection',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
            ),
            child: const Center(
              child: Text(
                'In Progress',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checklist Container (matching Screen 8)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklist.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final item = _checklist[index];
                          final status = item['status'] as String;
                          final statusColor = _getStatusColor(status);
                          final isPassed = status == 'Pass';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isPassed ? const Color(0xFF2563EB) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isPassed ? const Color(0xFF2563EB) : (isDark ? Colors.white38 : Colors.black38),
                                      width: 2,
                                    ),
                                  ),
                                  child: isPassed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _cycleStatus(index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: statusColor.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comments Box
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _commentsController,
                        maxLines: 3,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Add QA/QC inspector notes...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar (matching Screen 8)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                    tooltip: 'Attach Inspection Photo',
                    onPressed: () => context.push('/photos/sample'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: Color(0xFFD97706)),
                    tooltip: 'Record Voice Note',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final sig = await DigitalSignaturePadDialog.show(
                          context,
                          documentTitle: 'Piping Inspection Completion Sign-off',
                        );
                        if (!mounted) return;
                        if (sig != null) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Inspection completed and digitally signed!')),
                          );
                        }
                      },
                      child: const Text(
                        'Complete Inspection',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
