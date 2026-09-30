import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_palette.dart';
import 'offline_status_badge.dart';
import '../../features/sync/presentation/widgets/sync_status_badge.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../../core/offline/offline_sync_manager.dart';
import '../../core/offline/network_status_state.dart';

class TabletScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const TabletScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  ConsumerState<TabletScaffold> createState() => _TabletScaffoldState();
}

class _TabletScaffoldState extends ConsumerState<TabletScaffold> {
  int _calculateSelectedIndex(String path) {
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/projects')) return 1;
    if (path.startsWith('/drawings')) return 2;
    if (path.startsWith('/issues')) return 3;
    if (path.startsWith('/inspections')) return 4;
    if (path.startsWith('/equipment')) return 5;
    if (path.startsWith('/sync')) return 6;
    if (path.startsWith('/calculations')) return 7;
    if (path.startsWith('/takeoff')) return 8;
    if (path.startsWith('/offline-downloads')) return 9;
    if (path.startsWith('/offline-data')) return 10;
    if (path.startsWith('/reports')) return 11;
    if (path.startsWith('/settings')) return 12;
    return 0;
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/projects');
        break;
      case 2:
        context.go('/drawings');
        break;
      case 3:
        context.go('/issues');
        break;
      case 4:
        context.go('/inspections');
        break;
      case 5:
        context.go('/equipment');
        break;
      case 6:
        context.go('/sync');
        break;
      case 7:
        context.go('/calculations');
        break;
      case 8:
        context.go('/takeoff');
        break;
      case 9:
        context.go('/offline-downloads');
        break;
      case 10:
        context.go('/offline-data');
        break;
      case 11:
        context.go('/reports');
        break;
      case 12:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(widget.currentPath);
    final settings = ref.watch(settingsNotifierProvider);
    final syncState = ref.watch(offlineSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Tablet Navigation Rail / Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.safetyOrange, Color(0xFFE65100)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.safetyOrange.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.architecture_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FIELD ENG',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              'Complete Field Suite',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    children: [
                      _buildNavItem(
                        index: 0,
                        selectedIndex: selectedIndex,
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                      ),
                      _buildNavItem(
                        index: 1,
                        selectedIndex: selectedIndex,
                        icon: Icons.folder_special_rounded,
                        label: 'Projects',
                      ),
                      _buildNavItem(
                        index: 2,
                        selectedIndex: selectedIndex,
                        icon: Icons.layers_rounded,
                        label: 'Drawings & P&ID',
                      ),

                      const SizedBox(height: 8),
                      _buildSectionHeader('FIELD QUALITY & QA/QC (PHASE 4)'),
                      _buildNavItem(
                        index: 3,
                        selectedIndex: selectedIndex,
                        icon: Icons.report_problem_rounded,
                        label: 'Issues & Punch List',
                      ),
                      _buildNavItem(
                        index: 4,
                        selectedIndex: selectedIndex,
                        icon: Icons.checklist_rounded,
                        label: 'Field Inspections',
                      ),
                      _buildNavItem(
                        index: 5,
                        selectedIndex: selectedIndex,
                        icon: Icons.precision_manufacturing_rounded,
                        label: 'Equipment Master',
                      ),

                      const SizedBox(height: 8),
                      _buildSectionHeader('OFFLINE & SYNC (PHASE 5)'),
                      _buildNavItem(
                        index: 6,
                        selectedIndex: selectedIndex,
                        icon: Icons.sync_alt_rounded,
                        label: 'Sync Center',
                      ),
                      _buildNavItem(
                        index: 9,
                        selectedIndex: selectedIndex,
                        icon: Icons.download_for_offline_rounded,
                        label: 'Download Manager',
                      ),
                      _buildNavItem(
                        index: 10,
                        selectedIndex: selectedIndex,
                        icon: Icons.storage_rounded,
                        label: 'Offline Data & Cache',
                      ),
                      _buildNavItem(
                        index: 11,
                        selectedIndex: selectedIndex,
                        icon: Icons.description_rounded,
                        label: 'Reports & Export',
                      ),

                      const SizedBox(height: 8),
                      _buildSectionHeader('ENGINEERING TOOLS'),
                      _buildNavItem(
                        index: 7,
                        selectedIndex: selectedIndex,
                        icon: Icons.calculate_rounded,
                        label: 'Calculators',
                      ),
                      _buildNavItem(
                        index: 8,
                        selectedIndex: selectedIndex,
                        icon: Icons.table_chart_rounded,
                        label: 'Material Takeoff (MTO)',
                      ),

                      const SizedBox(height: 8),
                      _buildSectionHeader('SYSTEM'),
                      _buildNavItem(
                        index: 12,
                        selectedIndex: selectedIndex,
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Bottom Engineer Profile & Lock PIN
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            settings.engineerName.isNotEmpty
                                ? settings.engineerName[0].toUpperCase()
                                : 'E',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.engineerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                settings.employeeId,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.lock_outline_rounded, size: 16),
                          tooltip: 'Lock Tablet Session',
                          onPressed: () => context.go('/pin-login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Tablet Body
          Expanded(
            child: Column(
              children: [
                // Tablet Universal Header Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Breadcrumb or Page Header
                      _buildHeaderTitle(selectedIndex),
                      const Spacer(),

                      // Phase 5: Production Sync State Badge
                      SyncStatusBadge(
                        onTap: () => context.go('/sync'),
                      ),
                      const SizedBox(width: 12),

                      // Network / Offline Indicator Pill
                      const OfflineStatusBadge(),
                      const SizedBox(width: 16),

                      // Toggle Network Mode Quick Button
                      OutlinedButton.icon(
                        icon: Icon(
                          syncState.isForcedOffline
                              ? Icons.wifi_off_rounded
                              : Icons.wifi_rounded,
                          size: 16,
                          color: syncState.status.color,
                        ),
                        label: Text(
                          syncState.isForcedOffline ? 'DESERT MODE (OFFLINE)' : 'ONLINE MODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: syncState.status.color,
                          ),
                        ),
                        onPressed: () {
                          ref.read(offlineSyncProvider.notifier).toggleConnectionMode();
                        },
                      ),
                      const SizedBox(width: 12),

                      // Quick theme toggle
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 20,
                        ),
                        tooltip: isDark ? 'Switch to High-Contrast Desert Light' : 'Switch to Dark Mode',
                        onPressed: () {
                          final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                          ref.read(settingsNotifierProvider.notifier).setThemeMode(newMode);
                        },
                      ),
                    ],
                  ),
                ),

                // Main Page Content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.darkTextMuted,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String label,
  }) {
    final isSelected = index == selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onDestinationSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.safetyOrange.withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.safetyOrange
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.safetyOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(int selectedIndex) {
    String title = 'Field Engineering';
    String subtitle = 'Complete Offline Platform';

    switch (selectedIndex) {
      case 0:
        title = 'Field Dashboard';
        subtitle = 'Key metrics, offline status & QA/QC summaries';
        break;
      case 1:
        title = 'Projects Directory';
        subtitle = 'EPC & Construction site packages';
        break;
      case 2:
        title = 'Drawings & P&ID Viewer';
        subtitle = 'Vector engineering drawings, isometrics & schematics';
        break;
      case 3:
        title = 'Field Issues & Punch List';
        subtitle = 'Drawing pinned punch items, categories, priorities & status lifecycle';
        break;
      case 4:
        title = 'Field Inspections & Checklists';
        subtitle = 'Configurable checklists, digital signatures & PDF certificates';
        break;
      case 5:
        title = 'Equipment Master Registry';
        subtitle = 'Tag numbers, P&ID links, GPS locations & operational logs';
        break;
      case 6:
        title = 'Engineering Calculations';
        subtitle = 'Piping wall thickness, hydrotest pressure & flange torque';
        break;
      case 7:
        title = 'Material Takeoff (MTO / BOM)';
        subtitle = 'Bill of materials, takeoff counts & weight summaries';
        break;
      case 8:
        title = 'Offline Download Manager';
        subtitle = 'Pre-load drawing bundles before desert deployment';
        break;
      case 9:
        title = 'Offline Storage & Cache';
        subtitle = 'Local database, photos, audio memos & signatures inspector';
        break;
      case 10:
        title = 'Field Reports & Export';
        subtitle = 'Generate & export PDF reports offline';
        break;
      case 11:
        title = 'Tablet Configuration & Profile';
        subtitle = 'Security PIN, sync preferences & storage paths';
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
        ),
      ],
    );
  }
}
