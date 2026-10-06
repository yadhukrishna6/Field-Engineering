import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/markup.dart';
import '../controllers/markup_controller.dart';

/// Discussion and Review Thread Sheet for Markups (Phase 3 Collaboration)
class AnnotationCommentsSheet extends StatefulWidget {
  final Markup markup;
  final MarkupController controller;
  final VoidCallback? onStatusChanged;

  const AnnotationCommentsSheet({
    super.key,
    required this.markup,
    required this.controller,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Markup markup,
    required MarkupController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AnnotationCommentsSheet(
        markup: markup,
        controller: controller,
      ),
    );
  }

  @override
  State<AnnotationCommentsSheet> createState() => _AnnotationCommentsSheetState();
}

class _AnnotationCommentsSheetState extends State<AnnotationCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  late String _currentStatus;
  late List<Map<String, dynamic>> _comments;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.markup.status;
    _comments = _loadExistingComments();
  }

  List<Map<String, dynamic>> _loadExistingComments() {
    if (widget.markup.metadata != null && widget.markup.metadata!['comments'] is List) {
      return List<Map<String, dynamic>>.from(widget.markup.metadata!['comments']);
    }
    return [
      {
        'id': 'c-init',
        'authorName': widget.markup.createdBy,
        'authorRole': 'Lead Field Engineer',
        'text': widget.markup.text ?? 'Created annotation markup.',
        'createdAt': widget.markup.createdAt.toIso8601String(),
      }
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = {
      'id': 'c-${DateTime.now().millisecondsSinceEpoch}',
      'authorName': 'Lead Field Engineer',
      'authorRole': 'Piping & Inspection',
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _comments.add(newComment);
      _commentController.clear();
    });

    final updatedMetadata = Map<String, dynamic>.from(widget.markup.metadata ?? {});
    updatedMetadata['comments'] = _comments;

    widget.controller.selectMarkup(widget.markup.id);
  }

  void _updateStatus(String newStatus) {
    setState(() => _currentStatus = newStatus);
    widget.controller.updateMarkupStatus(widget.markup.id, newStatus);
    if (widget.onStatusChanged != null) widget.onStatusChanged!();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'approved':
        return const Color(0xFF00E676);
      case 'addressed':
        return Colors.blueAccent;
      case 'open':
      default:
        return AppColors.safetyOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: 480 + keyboardPadding,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + keyboardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131720) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentStatus).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.rate_review_rounded, color: _getStatusColor(_currentStatus), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Markup Review & Discussion Thread',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'ID: ${widget.markup.id.substring(0, 8)} • Layer: ${widget.markup.layer.displayName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Transition Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B212D) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('STATUS: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: ['Open', 'Addressed', 'Closed'].map((s) {
                    final isSelected = _currentStatus.toLowerCase() == s.toLowerCase();
                    final color = _getStatusColor(s);
                    return ChoiceChip(
                      label: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: Colors.transparent,
                      onSelected: (val) {
                        if (val) _updateStatus(s);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Comment Thread List
          Expanded(
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2634) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c['authorName'] ?? 'Engineer',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              c['authorRole'] ?? 'Reviewer',
                              style: const TextStyle(fontSize: 10, color: AppColors.safetyOrange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['text'] ?? '',
                          style: AppTypography.engineeringTextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Comment Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add review note or client feedback...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1B212D) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _addComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.safetyOrange),
                onPressed: _addComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
