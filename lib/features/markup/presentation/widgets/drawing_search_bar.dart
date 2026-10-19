import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/drawing_text_token.dart';

class DrawingSearchBar extends StatefulWidget {
  final List<DrawingTextToken> tokens;
  final bool isOutdoor;
  final bool isDark;
  final ValueChanged<DrawingTextToken> onSelectToken;
  final VoidCallback onClose;

  const DrawingSearchBar({
    super.key,
    required this.tokens,
    required this.isOutdoor,
    required this.isDark,
    required this.onSelectToken,
    required this.onClose,
  });

  @override
  State<DrawingSearchBar> createState() => _DrawingSearchBarState();
}

class _DrawingSearchBarState extends State<DrawingSearchBar> {
  final TextEditingController _queryController = TextEditingController();
  List<DrawingTextToken> _results = [];

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final matched = widget.tokens.where((t) => t.text.toLowerCase().contains(query)).toList();
    setState(() => _results = matched);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onSearchChanged);
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isOutdoor
        ? AppColors.outdoorSurface
        : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final outlineColor = widget.isOutdoor
        ? AppColors.outdoorOutline
        : (widget.isDark ? AppColors.darkOutline : AppColors.lightOutline);
    final textColor = widget.isOutdoor
        ? AppColors.outdoorText
        : (widget.isDark ? AppColors.darkText : AppColors.lightText);
    final primaryColor = widget.isOutdoor
        ? AppColors.outdoorPrimary
        : (widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor, width: widget.isOutdoor ? 2.0 : 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search line tag, spool, valve...',
                      hintStyle: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_queryController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => _queryController.clear(),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Results count header & dropdown
          if (_queryController.text.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.centerLeft,
              color: widget.isOutdoor ? AppColors.outdoorChip : AppColors.lightChip,
              child: Text(
                '${_results.length} match${_results.length == 1 ? "" : "es"} found',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No matching text on drawing', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final token = _results[idx];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P.${token.pageNumber}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          title: Text(
                            token.text,
                            style: AppTypography.engineeringTextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          trailing: token.isTag
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('TAG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                                )
                              : null,
                          onTap: () => widget.onSelectToken(token),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
