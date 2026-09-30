import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_palette.dart';

/// Standard Industrial Tablet Header Bar
/// Clean pattern: [←] Page Title [Actions]
/// Touch-optimized targets for field stylus/gloved use.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
    this.leading,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          if (showBack)
            leading ??
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (onBack != null) {
                        onBack!();
                      } else {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
          if (showBack) const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
