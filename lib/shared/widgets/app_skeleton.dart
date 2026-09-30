import 'package:flutter/material.dart';

/// Shimmering skeleton loader for fast, responsive UI without blocking spinners.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF334155).withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

/// Project card skeleton loader
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 140, height: 18),
              AppSkeleton(width: 70, height: 22, borderRadius: BorderRadius.all(Radius.circular(12))),
            ],
          ),
          SizedBox(height: 12),
          AppSkeleton(width: 220, height: 14),
          SizedBox(height: 8),
          AppSkeleton(width: 160, height: 12),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 90, height: 14),
              AppSkeleton(width: 80, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// Drawing row skeleton loader
class DrawingRowSkeleton extends StatelessWidget {
  const DrawingRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          AppSkeleton(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(6))),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 180, height: 16),
                SizedBox(height: 8),
                AppSkeleton(width: 260, height: 12),
              ],
            ),
          ),
          SizedBox(width: 16),
          AppSkeleton(width: 60, height: 24, borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(width: 12),
          AppSkeleton(width: 24, height: 24),
        ],
      ),
    );
  }
}

/// Photo grid skeleton loader
class PhotoGridSkeleton extends StatelessWidget {
  const PhotoGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const AppSkeleton(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        );
      },
    );
  }
}

/// Form skeleton loader
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(width: 120, height: 16),
        SizedBox(height: 8),
        AppSkeleton(width: double.infinity, height: 48),
        SizedBox(height: 20),
        AppSkeleton(width: 160, height: 16),
        SizedBox(height: 8),
        AppSkeleton(width: double.infinity, height: 100),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: AppSkeleton(height: 48)),
            SizedBox(width: 16),
            Expanded(child: AppSkeleton(height: 48)),
          ],
        ),
      ],
    );
  }
}
