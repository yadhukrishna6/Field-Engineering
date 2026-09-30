import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/color_palette.dart';

/// Centralized offline-first image component.
/// Prioritizes local unsynced/cached files before attempting asset or network fetching.
/// Provides smooth shimmering loading skeleton and actionable error states with retry.
class AppImage extends StatefulWidget {
  final String? imageSource;
  final File? file;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? semanticLabel;
  final bool enableRetry;
  final VoidCallback? onRetry;

  const AppImage({
    super.key,
    this.imageSource,
    this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.semanticLabel,
    this.enableRetry = true,
    this.onRetry,
  });

  @override
  State<AppImage> createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> {
  int _retryKey = 0;
  bool _hasError = false;

  void _handleRetry() {
    setState(() {
      _hasError = false;
      _retryKey++;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_hasError) {
      content = _buildErrorView();
    } else if (widget.file != null) {
      content = _buildFileImage(widget.file!);
    } else if (widget.imageSource != null && widget.imageSource!.isNotEmpty) {
      final src = widget.imageSource!;
      if (src.startsWith('assets/')) {
        content = _buildAssetImage(src);
      } else if (src.startsWith('http://') || src.startsWith('https://')) {
        content = _buildNetworkImage(src);
      } else if (!kIsWeb && File(src).existsSync()) {
        content = _buildFileImage(File(src));
      } else {
        // Attempt as asset first, then fallback
        content = _buildAssetImage(src);
      }
    } else {
      content = _buildErrorView(customMsg: 'No image specified');
    }

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }

  Widget _buildFileImage(File file) {
    if (kIsWeb) {
      return _buildFallbackIcon();
    }
    return Image.file(
      file,
      key: ValueKey('file_${file.path}_$_retryKey'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      semanticLabel: widget.semanticLabel,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorView(customMsg: 'Local file missing');
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _buildLoadingSkeleton();
      },
    );
  }

  Widget _buildAssetImage(String assetPath) {
    return Image.asset(
      assetPath,
      key: ValueKey('asset_${assetPath}_$_retryKey'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      semanticLabel: widget.semanticLabel,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackVisual(assetPath);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _buildLoadingSkeleton();
      },
    );
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      key: ValueKey('net_${url}_$_retryKey'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      semanticLabel: widget.semanticLabel,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingSkeleton();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorView(customMsg: 'Remote image unavailable');
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    if (widget.placeholder != null) return widget.placeholder!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF1E293B),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyOrange.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackVisual(String path) {
    // Generates a clean industrial placeholder box matching field engineering aesthetics
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: widget.borderRadius,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, color: AppColors.darkTextSecondary.withOpacity(0.5), size: 28),
          const SizedBox(height: 6),
          Text(
            'Field Photo',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.darkTextSecondary.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.image, color: AppColors.darkTextSecondary, size: 24),
      ),
    );
  }

  Widget _buildErrorView({String? customMsg}) {
    if (widget.errorWidget != null) return widget.errorWidget!;
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: widget.borderRadius,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.orange.shade400, size: 26),
          const SizedBox(height: 4),
          Text(
            customMsg ?? 'Image unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
          ),
          if (widget.enableRetry) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: _handleRetry,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 13, color: AppColors.safetyOrange),
                    SizedBox(width: 4),
                    Text('Retry', style: TextStyle(fontSize: 11, color: AppColors.safetyOrange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
