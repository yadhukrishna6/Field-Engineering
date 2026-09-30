import 'package:flutter/material.dart';

class MarkupSearchFilterBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onLayerFilterChanged;
  final ValueChanged<String?> onDisciplineFilterChanged;
  final VoidCallback onClearFilters;
  final int totalMarkupsCount;
  final int filteredMarkupsCount;

  const MarkupSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onLayerFilterChanged,
    required this.onDisciplineFilterChanged,
    required this.onClearFilters,
    required this.totalMarkupsCount,
    required this.filteredMarkupsCount,
  });

  @override
  State<MarkupSearchFilterBar> createState() => _MarkupSearchFilterBarState();
}

class _MarkupSearchFilterBarState extends State<MarkupSearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLayer;
  String? _selectedDiscipline;

  final List<String> _layers = [
    'All Layers',
    'Markup Layer',
    'Measurement Layer',
    'Issue Layer',
    'Photo Layer',
    'Inspection Layer',
    'Symbols Layer',
  ];

  final List<String> _disciplines = [
    'All Disciplines',
    'Piping',
    'Mechanical',
    'Electrical',
    'Civil',
    'Structural',
    'Instrumentation',
    'Safety',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll() {
    _searchController.clear();
    setState(() {
      _selectedLayer = null;
      _selectedDiscipline = null;
    });
    widget.onClearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = _searchController.text.isNotEmpty ||
        (_selectedLayer != null && _selectedLayer != 'All Layers') ||
        (_selectedDiscipline != null && _selectedDiscipline != 'All Disciplines');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B212D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search markups, tags, text callouts...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF131720),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  widget.onSearchChanged(val);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Layer Dropdown
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131720),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLayer ?? 'All Layers',
                dropdownColor: const Color(0xFF1E2430),
                icon: const Icon(Icons.layers_rounded, color: Colors.cyanAccent, size: 16),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: _layers.map((layer) {
                  return DropdownMenuItem<String>(
                    value: layer,
                    child: Text(layer),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedLayer = val);
                  widget.onLayerFilterChanged(val == 'All Layers' ? null : val);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Discipline Dropdown
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131720),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDiscipline ?? 'All Disciplines',
                dropdownColor: const Color(0xFF1E2430),
                icon: const Icon(Icons.engineering_rounded, color: Colors.amberAccent, size: 16),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: _disciplines.map((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedDiscipline = val);
                  widget.onDisciplineFilterChanged(val == 'All Disciplines' ? null : val);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.filteredMarkupsCount} / ${widget.totalMarkupsCount}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Clear button if filtered
          if (hasActiveFilter) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Clear filters',
              icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.redAccent, size: 18),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
    );
  }
}
