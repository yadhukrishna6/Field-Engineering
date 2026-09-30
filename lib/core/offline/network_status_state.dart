import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

enum ConnectionStatus {
  online,
  offline,
  syncPending,
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get label {
    switch (this) {
      case ConnectionStatus.online:
        return 'ONLINE';
      case ConnectionStatus.offline:
        return 'OFFLINE';
      case ConnectionStatus.syncPending:
        return 'SYNC PENDING';
    }
  }

  Color get color {
    switch (this) {
      case ConnectionStatus.online:
        return AppColors.online;
      case ConnectionStatus.offline:
        return AppColors.offline;
      case ConnectionStatus.syncPending:
        return AppColors.syncPending;
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.online:
        return Icons.cloud_done_rounded;
      case ConnectionStatus.offline:
        return Icons.cloud_off_rounded;
      case ConnectionStatus.syncPending:
        return Icons.sync_rounded;
    }
  }

  String get description {
    switch (this) {
      case ConnectionStatus.online:
        return 'Connected to remote engineering server';
      case ConnectionStatus.offline:
        return 'Working locally in desert/field mode (100% offline)';
      case ConnectionStatus.syncPending:
        return 'Local changes queued. Ready to sync when online';
    }
  }
}
