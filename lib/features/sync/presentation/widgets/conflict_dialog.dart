import 'package:flutter/material.dart';
import '../../../../core/sync/conflict_resolver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final SyncConflictRecord conflict;
  final Function(ConflictResolution strategy, Map<String, dynamic>? mergedPayload) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final mergedPreview = conflict.mergePayloads();

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conflict Detected', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  'Entity: ${conflict.entityType.toUpperCase()} #${conflict.entityId.substring(0, 8)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Another field engineer or cloud server updated this record concurrently. Please select how to resolve this collision:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local Version Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tablet_android, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 6),
                            Text('Local Version (v${conflict.localVersion})',
                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 4),
                        _buildPayloadSnippet(conflict.localPayload),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Server Version Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_outlined, color: Colors.purpleAccent, size: 16),
                            const SizedBox(width: 6),
                            Text('Server Version (v${conflict.serverVersion})',
                                style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 4),
                        _buildPayloadSnippet(conflict.serverPayload),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.compare_arrows, size: 18),
          label: const Text('Compare Details'),
          onPressed: () => _showDetailedComparisonSheet(context),
        ),
        const Spacer(),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent),
          onPressed: () {
            Navigator.pop(context);
            onResolve(ConflictResolution.keepLocal, null);
          },
          child: const Text('Keep Local'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.purpleAccent),
          onPressed: () {
            Navigator.pop(context);
            onResolve(ConflictResolution.keepServer, null);
          },
          child: const Text('Keep Server'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.merge_type, size: 18),
          label: const Text('Merge Changes'),
          onPressed: () {
            Navigator.pop(context);
            onResolve(ConflictResolution.merge, mergedPreview);
          },
        ),
      ],
    );
  }

  Widget _buildPayloadSnippet(Map<String, dynamic> payload) {
    if (payload.isEmpty) {
      return const Text('No attributes', style: TextStyle(color: Colors.grey, fontSize: 11));
    }
    final entries = payload.entries.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              text: '${e.key}: ',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: '${e.value}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  void _showDetailedComparisonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detailed Attribute Diff', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: conflict.localPayload.keys.map((k) {
                    final localVal = conflict.localPayload[k];
                    final serverVal = conflict.serverPayload[k];
                    final isDiff = localVal != serverVal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDiff ? Colors.amber.withOpacity(0.1) : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(6),
                        border: isDiff ? Border.all(color: Colors.amberAccent) : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(k, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Local: $localVal', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('Server: $serverVal', style: const TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
