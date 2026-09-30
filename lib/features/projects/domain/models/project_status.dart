import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

enum ProjectStatus {
  active,
  onHold,
  completed,
  archived,
}

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }

  Color get badgeColor {
    switch (this) {
      case ProjectStatus.active:
        return AppColors.statusActive;
      case ProjectStatus.onHold:
        return AppColors.statusOnHold;
      case ProjectStatus.completed:
        return AppColors.statusCompleted;
      case ProjectStatus.archived:
        return AppColors.statusArchived;
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectStatus.active:
        return Icons.play_circle_fill_rounded;
      case ProjectStatus.onHold:
        return Icons.pause_circle_filled_rounded;
      case ProjectStatus.completed:
        return Icons.check_circle_rounded;
      case ProjectStatus.archived:
        return Icons.archive_rounded;
    }
  }

  static ProjectStatus fromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'active':
        return ProjectStatus.active;
      case 'onhold':
      case 'on_hold':
      case 'on hold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.active;
    }
  }
}
