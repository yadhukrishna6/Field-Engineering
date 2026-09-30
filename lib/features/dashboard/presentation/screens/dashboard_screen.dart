import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Status & Profile Bar
              _buildTopStatusBar(context, settings),
              const SizedBox(height: 16),

              // Hero Banner: Industrial Field Engineering
              _buildHeroBanner(context),
              const SizedBox(height: 16),

              // Search Bar with QR Scanner Action
              _buildSearchBar(context),
              const SizedBox(height: 20),

              // 8-Card Quick Access Feature Grid (matching Screen 1)
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Time & Date Indicator (like tablet status bar: 9:41, Tue, 30 Sep)
        Row(
          children: [
            Text(
              '9:41',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tue, 30 Sep',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),

        // User Avatar & Settings link
        Row(
          children: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark ? Colors.amber : Colors.blueGrey,
              ),
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

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/refinery_banner.jpg'),
          fit: BoxFit.cover,
          onError: null,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
            Color(0xFFEA580C),
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
      child: Stack(
        children: [
          // Dark gradient overlay for text legibility
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.35),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // Content Row
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Glowing Icon Emblem
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.architecture_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Title & Subtitle
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Field Engineering',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Drawings • Inspection • Field Work',
                        style: TextStyle(
                          color: Color(0xFFFDBA74),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
          hintText: 'Search projects, drawings, equipment...',
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
            tooltip: 'Scan Equipment QR/Barcode',
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
        final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        final aspectRatio = constraints.maxWidth > 700 ? 1.6 : 1.35;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. Projects (Blue)
            _buildFeatureCard(
              context,
              title: 'Projects',
              subtitle: '4 Projects',
              icon: Icons.folder_rounded,
              gradientColors: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
              onTap: () => context.push('/projects'),
            ),

            // 2. Drawings (Red/Coral)
            _buildFeatureCard(
              context,
              title: 'Drawings',
              subtitle: '120 Drawings',
              icon: Icons.layers_rounded,
              gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
              onTap: () => context.push('/drawings'),
            ),

            // 3. Issues (Orange)
            _buildFeatureCard(
              context,
              title: 'Issues',
              subtitle: '12 Open',
              icon: Icons.warning_amber_rounded,
              gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
              onTap: () => context.push('/issues'),
            ),

            // 4. Inspections (Green)
            _buildFeatureCard(
              context,
              title: 'Inspections',
              subtitle: '8 Checklists',
              icon: Icons.check_circle_rounded,
              gradientColors: const [Color(0xFF16A34A), Color(0xFF22C55E)],
              onTap: () => context.push('/inspections'),
            ),

            // 5. Equipment (Purple)
            _buildFeatureCard(
              context,
              title: 'Equipment',
              subtitle: '56 Items',
              icon: Icons.settings_rounded,
              gradientColors: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              onTap: () => context.push('/equipment'),
            ),

            // 6. Calculator (Teal / Cyan)
            _buildFeatureCard(
              context,
              title: 'Calculator',
              subtitle: 'Tools & Units',
              icon: Icons.calculate_rounded,
              gradientColors: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
              onTap: () => context.push('/calculations'),
            ),

            // 7. Reports (Light Blue)
            _buildFeatureCard(
              context,
              title: 'Reports',
              subtitle: 'Generate Reports',
              icon: Icons.description_rounded,
              gradientColors: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
              onTap: () => context.push('/reports'),
            ),

            // 8. Offline Data (Violet / Indigo)
            _buildFeatureCard(
              context,
              title: 'Offline Data',
              subtitle: 'Downloaded',
              icon: Icons.cloud_download_rounded,
              gradientColors: const [Color(0xFF6366F1), Color(0xFF818CF8)],
              onTap: () => context.push('/sync'),
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
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
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
