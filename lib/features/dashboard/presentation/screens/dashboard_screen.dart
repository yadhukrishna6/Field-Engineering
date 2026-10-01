import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../projects/presentation/controllers/projects_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final projectsState = ref.watch(projectsListNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeProjectTitle = projectsState.projects.isNotEmpty
        ? projectsState.projects.first.name
        : 'Daleel Oil Field';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top System Status Bar
              _buildTopStatusBar(context, settings),
              const SizedBox(height: 14),

              // Hero Banner: Field Engineering Active Workspace Banner
              _buildHeroBanner(context, activeProjectTitle),
              const SizedBox(height: 16),

              // Search Bar with QR Scanner Action
              _buildSearchBar(context),
              const SizedBox(height: 18),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FIELD WORKSPACE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.white60 : Colors.blueGrey.shade700,
                    ),
                  ),
                  Text(
                    '10 Core Modules',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 10-Card Field Engineering Navigation Grid (matching Section 4)
              _buildFeatureGrid(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusBar(BuildContext context, dynamic settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = DateFormat('EEE, d MMM').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Time & Date Indicator
        Row(
          children: [
            const Icon(Icons.tablet_android_rounded, size: 16, color: AppColors.safetyOrange),
            const SizedBox(width: 6),
            Text(
              timeStr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),

        // Quick Controls & Profile Avatar
        Row(
          children: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark ? Colors.amber : Colors.blueGrey,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                ref.read(settingsNotifierProvider.notifier).setThemeMode(newMode);
              },
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => context.push('/settings'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.safetyOrange, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('assets/images/engineer_avatar.png'),
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context, String projectTitle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0369A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Greeting
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.engineering_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'FIELD ENGINEERING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Good Morning, Engineer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                // Status Badges (ONLINE & SYNC STATUS)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Network Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Sync Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 12),
                          SizedBox(width: 4),
                          Text(
                            '✓ Synced',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Project Banner Pill
            InkWell(
              onTap: () => context.push('/projects'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.safetyOrange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Project: ',
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                          children: [
                            TextSpan(
                              text: projectTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search projects, drawings, equipment tags...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white54 : Colors.black45,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.safetyOrange, size: 22),
            tooltip: 'Scan Equipment QR / Barcode',
            onPressed: () => context.push('/qr-scanner'),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.push('/drawings');
          }
        },
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 4 : 2);
        final aspectRatio = constraints.maxWidth > 900 ? 1.45 : (constraints.maxWidth > 600 ? 1.35 : 1.3);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. PROJECTS
            _buildFeatureCard(
              context,
              title: 'Projects',
              subtitle: '4 Active Sites',
              badgeText: '✓ Offline',
              badgeColor: const Color(0xFF10B981),
              icon: Icons.folder_rounded,
              gradientColors: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
              onTap: () => context.push('/projects'),
            ),

            // 2. DRAWINGS
            _buildFeatureCard(
              context,
              title: 'Drawings',
              subtitle: '124 drawings',
              badgeText: '18 markups',
              badgeColor: const Color(0xFFEF4444),
              icon: Icons.layers_rounded,
              gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
              onTap: () => context.push('/drawings'),
            ),

            // 3. ISSUES
            _buildFeatureCard(
              context,
              title: 'Issues',
              subtitle: '23 Issues',
              badgeText: '12 open',
              badgeColor: const Color(0xFFF59E0B),
              icon: Icons.warning_amber_rounded,
              gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
              onTap: () => context.push('/issues'),
            ),

            // 4. INSPECTIONS
            _buildFeatureCard(
              context,
              title: 'Inspections',
              subtitle: '18 Checklists',
              badgeText: '2 pending',
              badgeColor: const Color(0xFF10B981),
              icon: Icons.check_circle_rounded,
              gradientColors: const [Color(0xFF16A34A), Color(0xFF22C55E)],
              onTap: () => context.push('/inspections'),
            ),

            // 5. EQUIPMENT
            _buildFeatureCard(
              context,
              title: 'Equipment',
              subtitle: '56 Tagged Items',
              badgeText: 'QR ready',
              badgeColor: const Color(0xFF8B5CF6),
              icon: Icons.settings_rounded,
              gradientColors: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              onTap: () => context.push('/equipment'),
            ),

            // 6. CALCULATOR
            _buildFeatureCard(
              context,
              title: 'Calculator',
              subtitle: 'Pipes, Tanks, Units',
              badgeText: 'Tools',
              badgeColor: const Color(0xFF14B8A6),
              icon: Icons.calculate_rounded,
              gradientColors: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
              onTap: () => context.push('/calculations'),
            ),

            // 7. MATERIAL TAKEOFF
            _buildFeatureCard(
              context,
              title: 'Material Takeoff',
              subtitle: 'Piping, Flanges, Valves',
              badgeText: 'MTO / BOM',
              badgeColor: const Color(0xFFF97316),
              icon: Icons.inventory_2_rounded,
              gradientColors: const [Color(0xFFEA580C), Color(0xFFFB923C)],
              onTap: () => context.push('/takeoff'),
            ),

            // 8. REPORTS
            _buildFeatureCard(
              context,
              title: 'Reports',
              subtitle: 'Field & As-Built',
              badgeText: 'PDF Export',
              badgeColor: const Color(0xFF0284C7),
              icon: Icons.description_rounded,
              gradientColors: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
              onTap: () => context.push('/reports'),
            ),

            // 9. OFFLINE DATA
            _buildFeatureCard(
              context,
              title: 'Offline Data',
              subtitle: 'Blueprints & Queue',
              badgeText: '100% Offline',
              badgeColor: const Color(0xFF6366F1),
              icon: Icons.cloud_download_rounded,
              gradientColors: const [Color(0xFF6366F1), Color(0xFF818CF8)],
              onTap: () => context.push('/sync'),
            ),

            // 10. SETTINGS
            _buildFeatureCard(
              context,
              title: 'Settings',
              subtitle: 'Preferences & Units',
              badgeText: 'Profile',
              badgeColor: const Color(0xFF64748B),
              icon: Icons.tune_rounded,
              gradientColors: const [Color(0xFF475569), Color(0xFF64748B)],
              onTap: () => context.push('/settings'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Icon + Status Pill Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title and Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black54,
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
}
