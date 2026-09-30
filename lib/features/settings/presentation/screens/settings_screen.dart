import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/settings_controller.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/sample_data_seeder.dart';
import '../../../../core/security/rbac_manager.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/audit_logger.dart';
import '../../../projects/presentation/controllers/projects_controller.dart';
import '../../../drawings/presentation/controllers/drawings_controller.dart';
import '../../../offline_manager/presentation/controllers/offline_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _idController;
  late TextEditingController _companyController;
  late TextEditingController _pinController;
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _nameController = TextEditingController(text: settings.engineerName);
    _titleController = TextEditingController(text: settings.engineerTitle);
    _idController = TextEditingController(text: settings.employeeId);
    _companyController = TextEditingController(text: settings.company);
    _pinController = TextEditingController(text: settings.securityPin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _idController.dispose();
    _companyController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(settingsNotifierProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          title: _titleController.text.trim(),
          employeeId: _idController.text.trim(),
          company: _companyController.text.trim(),
        );
    setState(() => _isEditingProfile = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.online,
          content: Text('Field Engineer profile saved.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const Text(
              'Tablet Settings & Offline Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Text(
              'Configure engineer identification, security PIN, desert high-contrast theme, and storage rules.',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Profile Section
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge_rounded, color: AppColors.safetyOrange, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Field Engineer Identification & Stamping Profile',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        if (!_isEditingProfile)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Profile'),
                            onPressed: () => setState(() => _isEditingProfile = true),
                          )
                        else
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _nameController.text = settings.engineerName;
                                    _titleController.text = settings.engineerTitle;
                                    _idController.text = settings.employeeId;
                                    _companyController.text = settings.company;
                                    _isEditingProfile = false;
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _saveProfile,
                                child: const Text('Save Profile'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!_isEditingProfile)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.safetyOrange,
                            child: Text(
                              settings.engineerName.isNotEmpty ? settings.engineerName[0].toUpperCase() : 'E',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.engineerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.engineerTitle,
                                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Employee ID: ${settings.employeeId} • Company: ${settings.company}',
                                  style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Engineer Full Name *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _idController,
                                  decoration: const InputDecoration(labelText: 'Employee / Badge ID *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(labelText: 'Official Job Title *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _companyController,
                                  decoration: const InputDecoration(labelText: 'Company / Organization *'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Security & PIN Section
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppColors.safetyOrange, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Offline Tablet Security & PIN Protection',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SwitchListTile(
                    title: const Text('Require 4-Digit PIN to Access Tablet Application'),
                    subtitle: const Text('Ensures project blueprints and inspection records are protected on lost/unattended devices in field camps.'),
                    value: settings.isPinRequired,
                    onChanged: (val) {
                      ref.read(settingsNotifierProvider.notifier).togglePinRequired(val);
                    },
                  ),
                  const Divider(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Tablet Security PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Default field PIN is 1234. Change it for your assigned tablet device.', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.pin_rounded, size: 16),
                        label: const Text('Change PIN'),
                        onPressed: () => _showChangePinDialog(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Theme & Display Mode
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_sunny_rounded, color: AppColors.safetyOrange, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Visual Mode & Desert Sunlight Readability',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: settings.themeMode,
                    title: const Text('Industrial Dark Mode (Low Light / Control Rooms)'),
                    subtitle: const Text('High-contrast dark theme optimized for night inspections and battery conservation.'),
                    onChanged: (v) {
                      if (v != null) ref.read(settingsNotifierProvider.notifier).setThemeMode(v);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: settings.themeMode,
                    title: const Text('Desert Sunlight High-Contrast Light Mode'),
                    subtitle: const Text('Maximum contrast white blueprint background designed for direct desert sunlight glare.'),
                    onChanged: (v) {
                      if (v != null) ref.read(settingsNotifierProvider.notifier).setThemeMode(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phase 7: Role-Based Access Control (RBAC) & Field Security
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, color: Colors.greenAccent, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Role-Based Access Control & Security Governance',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Active session role dictates permissions for revision uploads, markups, inspection sign-offs, and cloud synchronization.',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Role selector
                  StatefulBuilder(
                    builder: (context, setSecState) {
                      final sec = SecureStorageService();
                      final currentRole = sec.currentUser.role;

                      return Column(
                        children: UserRole.values.map((role) {
                          final isSelected = currentRole == role;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.safetyOrange.withOpacity(0.12) : AppColors.darkSurfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.safetyOrange : Colors.white10,
                              ),
                            ),
                            child: RadioListTile<UserRole>(
                              value: role,
                              groupValue: currentRole,
                              title: Text(role.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                'Approve Revisions: ${role.canApproveRevisions ? "YES" : "NO"} • Inspections: ${role.canPerformInspections ? "YES" : "NO"} • Sign-Offs: ${role.canSignInspection ? "YES" : "NO"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  sec.switchUserRole(val);
                                  setSecState(() {});
                                  AuditLogger().log(
                                    action: 'ROLE_SWITCH',
                                    entityType: 'SECURITY',
                                    details: 'Switched session role to ${val.displayName}',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Switched role to ${val.displayName}')),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // Audit Log Inspector Trigger
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Local AES-256 Storage: ENCRYPTED & ACTIVE',
                            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.history_toggle_off, size: 16),
                        label: const Text('View Field Audit Logs'),
                        onPressed: () => _showAuditLogViewer(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Development & Field Reset Tools
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: AppColors.safetyOrange, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Database Reset & Field Demo Utilities',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ListTile(
                    title: const Text('Re-seed Sample EPC Projects & Vector Drawings'),
                    subtitle: const Text('Re-generates authentic sample engineering packages (Al-Khafji, Ras Tanura, Das Island).'),
                    trailing: OutlinedButton.icon(
                      icon: const Icon(Icons.dataset_rounded, size: 16),
                      label: const Text('Re-seed Data'),
                      onPressed: () async {
                        final projRepo = ref.read(projectsRepositoryProvider);
                        final dwgRepo = ref.read(drawingsRepositoryProvider);
                        final markupsRepo = ref.read(markupsRepositoryProvider);
                        await SampleDataSeeder.seedIfEmpty(
                          projectsRepository: projRepo,
                          drawingsRepository: dwgRepo,
                          markupsRepository: markupsRepo,
                        );
                        ref.read(projectsListNotifierProvider.notifier).loadProjects();
                        ref.read(allDrawingsNotifierProvider.notifier).loadDrawings();
                        ref.read(offlineStorageNotifierProvider.notifier).refreshUsage();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample EPC projects and vector blueprints loaded.')),
                          );
                        }
                      },
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

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set New Security PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '4-Digit PIN',
              hintText: 'e.g. 1234',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (pinController.text.length == 4) {
                  ref.read(settingsNotifierProvider.notifier).setSecurityPin(pinController.text);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Security PIN successfully updated.')),
                  );
                }
              },
              child: const Text('Update PIN'),
            ),
          ],
        );
      },
    );
  }

  void _showAuditLogViewer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<AuditLogEntry>>(
          future: AuditLogger().getRecentLogs(),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_toggle_off, color: AppColors.safetyOrange),
                      SizedBox(width: 8),
                      Text('Engineering Field Audit Trail (ISO / IEC Compliant)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Cryptographically recorded field actions, user stamps, IP, and revision mutations.',
                      style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : logs.isEmpty
                            ? const Center(child: Text('No audit logs recorded yet.'))
                            : ListView.separated(
                                itemCount: logs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkSurfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.safetyOrange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(log.action,
                                              style: const TextStyle(color: AppColors.safetyOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${log.userEmail} (${log.userRole})',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(height: 2),
                                              Text(log.details,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        Text(DateFormat('HH:mm:ss').format(log.createdAt),
                                            style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

