import 'package:flutter/material.dart';
import '../../../../core/reliability/diagnostics_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final DiagnosticsService _service = DiagnosticsService();
  SystemDiagnosticsReport? _report;
  bool _isLoading = true;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);
    final rep = await _service.runDiagnostics();
    if (mounted) {
      setState(() {
        _report = rep;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerBackup() async {
    setState(() => _actionMessage = 'Creating SQLite snapshot backup...');
    final msg = await _service.createSnapshotBackup();
    if (mounted) {
      setState(() => _actionMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _verifyCache() async {
    setState(() => _actionMessage = 'Verifying storage cache integrity...');
    final res = await _service.verifyCacheIntegrity();
    if (mounted) {
      setState(() => _actionMessage = 'Cache status: ${res['status']} (${res['verifiedDrawings']} drawings, ${res['verifiedAttachments']} photos verified)');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Integrity check passed: ${res['corruptedFilesCount']} corrupted files.'),
        backgroundColor: Colors.cyanAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141923),
        title: const Row(
          children: [
            Icon(Icons.monitor_heart_rounded, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text('System Diagnostics & DB Health', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            onPressed: _loadDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Health Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C28),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _report!.isDatabaseHealthy ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _report!.isDatabaseHealthy
                              ? Colors.greenAccent.withOpacity(0.12)
                              : Colors.redAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _report!.isDatabaseHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: _report!.isDatabaseHealthy ? Colors.greenAccent : Colors.redAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _report!.isDatabaseHealthy ? 'SQLite Database Healthy' : 'Database Integrity Warning',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PRAGMA integrity_check: ${_report!.integrityCheckResult}',
                              style: TextStyle(
                                color: _report!.isDatabaseHealthy ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Table Record Metrics
                const Text(
                  'LOCAL SQLITE DATABASE TABLES',
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C28),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _report!.tableCounts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, idx) {
                      final key = _report!.tableCounts.keys.elementAt(idx);
                      final count = _report!.tableCounts[key] ?? 0;
                      return ListTile(
                        dense: true,
                        title: Text(key, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count records',
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Diagnostic Actions
                const Text(
                  'MAINTENANCE & BACKUP ACTIONS',
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.backup_rounded),
                        label: const Text('Create DB Snapshot', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _triggerBackup,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.verified_rounded, color: Colors.greenAccent),
                        label: const Text('Verify Cache Files', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _verifyCache,
                      ),
                    ),
                  ],
                ),

                if (_actionMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141D2B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: Text(_actionMessage!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ],
            ),
    );
  }
}
