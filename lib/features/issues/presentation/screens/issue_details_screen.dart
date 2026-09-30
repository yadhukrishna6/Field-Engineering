import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IssueDetailsScreen extends ConsumerStatefulWidget {
  final String issueId;

  const IssueDetailsScreen({super.key, required this.issueId});

  @override
  ConsumerState<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends ConsumerState<IssueDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleController = TextEditingController(text: 'Valve mismatch');
  final _descController = TextEditingController(
    text: 'Installed valve differs from drawing. Need to verify size and type.',
  );
  final _gpsController = TextEditingController(text: '24.4532, 54.3771');
  final _assignedController = TextEditingController(text: 'Mechanical Team');
  final _createdByController = TextEditingController(text: 'Yadhu Krishnan');
  final _dateController = TextEditingController(text: '30 Sep 2026 10:45');

  String _selectedCategory = 'Piping';
  String _selectedPriority = 'High';
  String _selectedStatus = 'Open';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _gpsController.dispose();
    _assignedController.dispose();
    _createdByController.dispose();
    _dateController.dispose();
    super.dispose();
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
              context.go('/issues');
            }
          },
        ),
        title: Text(
          'Issue #${widget.issueId.replaceAll('ISSUE-', '')}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Change Status',
            onSelected: (newStatus) {
              setState(() {
                _selectedStatus = newStatus;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Issue status updated to $_selectedStatus')),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Open', child: Text('Open')),
              const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'Resolved', child: Text('Resolved')),
              const PopupMenuItem(value: 'Closed', child: Text('Closed')),
            ],
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  _selectedStatus,
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Photos (3)'),
            Tab(text: 'Voice (1)'),
            Tab(text: 'Measurements (2)'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Row: Left Drawing Pin Thumbnail + Right Form (matching Screen 6)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Blueprint Pin Thumbnail
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.schema_rounded, size: 80, color: Colors.blueGrey),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.redAccent, blurRadius: 10, spreadRadius: 2),
                              ],
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                          ),
                          Positioned(
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('P-102 Pin', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right Metadata Column
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Title'),
                        TextField(
                          controller: _titleController,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Category'),
                                  DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    items: ['Piping', 'Mechanical', 'Electrical', 'Civil', 'Structural']
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedCategory = v!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Priority'),
                                  DropdownButton<String>(
                                    value: _selectedPriority,
                                    isExpanded: true,
                                    items: ['Low', 'Medium', 'High', 'Critical']
                                        .map((p) => DropdownMenuItem(
                                              value: p,
                                              child: Text(
                                                p,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: p == 'High' || p == 'Critical' ? Colors.redAccent : Colors.amber,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedPriority = v!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Description Field
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Description'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // GPS, Assigned To, Created By, Date Fields
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildFieldLabel('Location (GPS)')),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _gpsController.text,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent),
                                ),
                              ),
                              const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFieldLabel('Assigned To')),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _assignedController.text,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFieldLabel('Created By')),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _createdByController.text,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFieldLabel('Date')),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _dateController.text,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Action Buttons: Add Photo, Add Voice, Add Measurement
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: const Text('Add Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/photos/sample'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.mic_none_rounded, size: 16),
                      label: const Text('Add Voice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.square_foot_rounded, size: 16),
                      label: const Text('Add Measure', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/calculations'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
    );
  }
}
