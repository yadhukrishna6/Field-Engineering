import 'package:flutter/material.dart';
import '../../domain/models/engineering_symbol.dart';

class EngineeringSymbolsDrawer extends StatefulWidget {
  final Function(EngineeringSymbol symbol, String customTag, double scale, double rotation) onSymbolSelected;
  final VoidCallback? onClose;

  const EngineeringSymbolsDrawer({
    super.key,
    required this.onSymbolSelected,
    this.onClose,
  });

  @override
  State<EngineeringSymbolsDrawer> createState() => _EngineeringSymbolsDrawerState();
}

class _EngineeringSymbolsDrawerState extends State<EngineeringSymbolsDrawer> {
  SymbolCategory _selectedCategory = SymbolCategory.valves;
  String _searchQuery = '';
  EngineeringSymbol? _previewSymbol;
  final TextEditingController _tagController = TextEditingController();
  double _symbolScale = 1.0;
  double _symbolRotation = 0.0; // 0, 90, 180, 270 in degrees

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _selectSymbol(EngineeringSymbol symbol) {
    setState(() {
      _previewSymbol = symbol;
      _tagController.text = '${symbol.tagPrefix}-${DateTime.now().millisecondsSinceEpoch % 1000}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbols = EngineeringSymbol.standardLibrary.where((s) {
      final matchesCategory = s.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.tagPrefix.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2430),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
        border: Border(
          left: BorderSide(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.architecture_rounded, color: Colors.cyanAccent, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engineering Symbols & Stamps',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'ISO 10628 / ASME B16 / ISA-5.1',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search valves, transmitters, stamps...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent, size: 18),
                filled: true,
                fillColor: const Color(0xFF131720),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: SymbolCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    label: Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    backgroundColor: const Color(0xFF181D27),
                    selectedColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Symbols Grid
          Expanded(
            child: symbols.isEmpty
                ? Center(
                    child: Text(
                      'No matching symbols in this category',
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: symbols.length,
                    itemBuilder: (context, index) {
                      final sym = symbols[index];
                      final isSelected = _previewSymbol?.id == sym.id;
                      return InkWell(
                        onTap: () => _selectSymbol(sym),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? sym.defaultColor.withOpacity(0.18)
                                : const Color(0xFF161B24),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? sym.defaultColor : Colors.white.withOpacity(0.08),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: sym.defaultColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(sym.icon, color: sym.defaultColor, size: 24),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sym.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '[ ${sym.tagPrefix} ]',
                                style: TextStyle(
                                  color: sym.defaultColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Configuration & Stamp Placement Bar
          if (_previewSymbol != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131720),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(_previewSymbol!.icon, color: _previewSymbol!.defaultColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _previewSymbol!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tag & Orientation Controls
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _tagController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Tag / Callout Label',
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF1A202C),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rotation Button
                      IconButton(
                        tooltip: 'Rotate 90°',
                        icon: const Icon(Icons.rotate_90_degrees_ccw_rounded, color: Colors.cyanAccent),
                        onPressed: () {
                          setState(() {
                            _symbolRotation = (_symbolRotation + 90.0) % 360.0;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scale Slider
                  Row(
                    children: [
                      const Text('Scale:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _symbolScale,
                          min: 0.5,
                          max: 2.5,
                          divisions: 8,
                          label: '${_symbolScale}x',
                          activeColor: Colors.cyanAccent,
                          onChanged: (val) => setState(() => _symbolScale = val),
                        ),
                      ),
                      Text('${_symbolScale.toStringAsFixed(1)}x',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                    ],
                  ),

                  // Stamp / Place Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _previewSymbol!.defaultColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      _previewSymbol!.isStamp ? Icons.approval_rounded : Icons.add_location_alt_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _previewSymbol!.isStamp ? 'Place Certification Stamp' : 'Stamp Symbol on Drawing',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      final tag = _tagController.text.trim().isNotEmpty
                          ? _tagController.text.trim()
                          : _previewSymbol!.tagPrefix;
                      widget.onSymbolSelected(
                        _previewSymbol!,
                        tag,
                        _symbolScale,
                        _symbolRotation,
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
