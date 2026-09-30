import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/theme/color_palette.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/models/issue.dart';
import '../widgets/issue_dialog.dart';
import '../../../projects/domain/models/project.dart';

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedProjectId = '';
  List<Project> _projects = [];
  List<Issue> _issues = [];
  bool _isLoading = true;

  String _searchQuery = '';
  IssueCategory? _filterCategory;
  IssuePriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final projectsRepo = ref.read(projectsRepositoryProvider);
    final issuesRepo = ref.read(issuesRepositoryProvider);

    final projects = await projectsRepo.getProjects();
    final defaultProjId = projects.isNotEmpty ? projects.first.id : '';

    List<Issue> issues = [];
    if (defaultProjId.isNotEmpty) {
      issues = await issuesRepo.getIssuesByProject(defaultProjId);
    } else {
      issues = await issuesRepo.getAllIssues();
    }

    if (mounted) {
      setState(() {
        _projects = projects;
        _selectedProjectId = defaultProjId;
        _issues = issues;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshIssues() async {
    final issuesRepo = ref.read(issuesRepositoryProvider);
    List<Issue> issues = [];
    if (_selectedProjectId.isNotEmpty) {
      issues = await issuesRepo.getIssuesByProject(_selectedProjectId);
    } else {
      issues = await issuesRepo.getAllIssues();
    }
    if (mounted) {
      setState(() => _issues = issues);
    }
  }

  void _createIssue() async {
    final newIssue = await showDialog<Issue>(
      context: context,
      builder: (ctx) => IssueDialog(
        projectId: _selectedProjectId.isNotEmpty
            ? _selectedProjectId
            : (_projects.isNotEmpty ? _projects.first.id : 'PRJ-DEFAULT'),
      ),
    );

    if (newIssue != null) {
      _refreshIssues();
    }
  }

  void _editIssue(Issue issue) async {
    final updated = await showDialog<Issue>(
      context: context,
      builder: (ctx) => IssueDialog(
        issue: issue,
        projectId: issue.projectId,
      ),
    );

    if (updated != null) {
      _refreshIssues();
    }
  }

  void _updateStatus(Issue issue, IssueStatus newStatus) async {
    final updated = issue.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await ref.read(issuesRepositoryProvider).updateIssue(updated);
    _refreshIssues();
  }

  List<Issue> get _filteredIssues {
    return _issues.where((item) {
      // Tab filter
      switch (_tabController.index) {
        case 1:
          if (item.status != IssueStatus.open) return false;
          break;
        case 2:
          if (item.status != IssueStatus.inProgress) return false;
          break;
        case 3:
          if (item.status != IssueStatus.resolved) return false;
          break;
        case 4:
          if (item.status != IssueStatus.verified) return false;
          break;
        case 5:
          if (item.status != IssueStatus.closed) return false;
          break;
      }

      // Category filter
      if (_filterCategory != null && item.category != _filterCategory) return false;

      // Priority filter
      if (_filterPriority != null && item.priority != _filterPriority) return false;

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchDesc = item.description.toLowerCase().contains(query);
        final matchAssignee = item.assignedTo?.toLowerCase().contains(query) ?? false;
        if (!matchTitle && !matchDesc && !matchAssignee) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _exportPunchListPdf() async {
    final doc = pw.Document();
    final items = _filteredIssues;
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FIELD ENGINEERING — OFFICIAL PUNCH LIST & ISSUES LOG',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Generated Offline on Tablet • Date: $nowStr',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text('Total Items: ${items.length}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Item #', 'Title & Description', 'Category', 'Priority', 'Status', 'Assigned To', 'Due Date', 'GPS Location'],
              data: items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final it = entry.value;
                return [
                  '#$idx',
                  '${it.title}\n${it.description}',
                  it.category.label,
                  it.priority.label,
                  it.status.label,
                  it.assignedTo ?? 'Unassigned',
                  it.dueDate ?? '-',
                  it.latitude != null ? '${it.latitude!.toStringAsFixed(4)}°, ${it.longitude!.toStringAsFixed(4)}°' : 'Drawing Pin',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Field_Punch_List_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final openCount = _issues.where((i) => i.status == IssueStatus.open).length;
    final progressCount = _issues.where((i) => i.status == IssueStatus.inProgress).length;
    final resolvedCount = _issues.where((i) => i.status == IssueStatus.resolved || i.status == IssueStatus.verified).length;
    final criticalCount = _issues.where((i) => i.priority == IssuePriority.critical && i.status != IssueStatus.closed).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Control Row: Project Selector & Action Buttons
                  Row(
                    children: [
                      // Project Selector Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProjectId.isNotEmpty ? _selectedProjectId : null,
                            hint: const Text('Select Project'),
                            items: _projects.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.projectNumber} - ${p.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedProjectId = val);
                                _refreshIssues();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Search Input
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search issues by title, description, assignee...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Category Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<IssueCategory?>(
                            value: _filterCategory,
                            hint: const Text('All Categories', style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Categories')),
                              ...IssueCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))),
                            ],
                            onChanged: (val) => setState(() => _filterCategory = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Export PDF
                      OutlinedButton.icon(
                        onPressed: _exportPunchListPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text('Export Punch List'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Create Issue Button
                      ElevatedButton.icon(
                        onPressed: _createIssue,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Field Issue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safetyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // KPI Cards Row
                  Row(
                    children: [
                      _buildKpiCard('TOTAL ISSUES', _issues.length.toString(), Icons.folder_open_rounded, AppColors.primary, isDark),
                      const SizedBox(width: 12),
                      _buildKpiCard('OPEN PINS', openCount.toString(), Icons.error_outline_rounded, Colors.redAccent, isDark),
                      const SizedBox(width: 12),
                      _buildKpiCard('IN PROGRESS', progressCount.toString(), Icons.pending_actions_rounded, Colors.orangeAccent, isDark),
                      const SizedBox(width: 12),
                      _buildKpiCard('RESOLVED / VERIFIED', resolvedCount.toString(), Icons.task_alt_rounded, Colors.greenAccent, isDark),
                      const SizedBox(width: 12),
                      _buildKpiCard('CRITICAL PUNCH', criticalCount.toString(), Icons.warning_amber_rounded, Colors.red, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lifecycle Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppColors.safetyOrange,
                    labelColor: AppColors.safetyOrange,
                    unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    tabs: [
                      Tab(text: 'All Items (${_issues.length})'),
                      Tab(text: 'Open ($openCount)'),
                      Tab(text: 'In Progress ($progressCount)'),
                      Tab(text: 'Resolved (${_issues.where((i) => i.status == IssueStatus.resolved).length})'),
                      Tab(text: 'Verified (${_issues.where((i) => i.status == IssueStatus.verified).length})'),
                      Tab(text: 'Closed (${_issues.where((i) => i.status == IssueStatus.closed).length})'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Issues List
                  Expanded(
                    child: _filteredIssues.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                                const SizedBox(height: 12),
                                Text(
                                  'No issues match the selected filter',
                                  style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredIssues.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = _filteredIssues[idx];
                              return _buildIssueCard(item, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.darkTextMuted, letterSpacing: 0.5),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(Issue item, bool isDark) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _editIssue(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.category.icon, color: item.category.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Title, Description & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.priority.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: item.priority.color.withOpacity(0.4)),
                          ),
                          child: Text(
                            item.priority.label.toUpperCase(),
                            style: TextStyle(
                              color: item.priority.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Pills row (Drawing Pin, Assigned, Due Date, GPS)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTag(
                          icon: Icons.category_rounded,
                          label: item.category.label,
                          color: item.category.color,
                          isDark: isDark,
                        ),
                        if (item.isPinnedToDrawing)
                          _buildTag(
                            icon: Icons.push_pin_rounded,
                            label: 'Page ${item.pageNumber} Pin',
                            color: Colors.purpleAccent,
                            isDark: isDark,
                          ),
                        if (item.assignedTo != null && item.assignedTo!.isNotEmpty)
                          _buildTag(
                            icon: Icons.person_outline_rounded,
                            label: item.assignedTo!,
                            color: Colors.blueAccent,
                            isDark: isDark,
                          ),
                        if (item.dueDate != null)
                          _buildTag(
                            icon: Icons.calendar_today_rounded,
                            label: 'Due: ${item.dueDate}',
                            color: Colors.teal,
                            isDark: isDark,
                          ),
                        if (item.latitude != null)
                          _buildTag(
                            icon: Icons.gps_fixed_rounded,
                            label: '${item.latitude!.toStringAsFixed(4)}°, ${item.longitude!.toStringAsFixed(4)}°',
                            color: Colors.green,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Status Dropdown & Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: item.status.color.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<IssueStatus>(
                        value: item.status,
                        isDense: true,
                        items: IssueStatus.values.map((st) {
                          return DropdownMenuItem(
                            value: st,
                            child: Row(
                              children: [
                                Icon(st.icon, size: 14, color: st.color),
                                const SizedBox(width: 6),
                                Text(
                                  st.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: st.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newSt) {
                          if (newSt != null) _updateStatus(item, newSt);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Updated: ${dateFormat.format(item.updatedAt)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }
}
