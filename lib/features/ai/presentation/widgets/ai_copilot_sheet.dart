import 'package:flutter/material.dart';
import '../../../../core/ai/field_ai_service.dart';

class AiCopilotSheet extends StatefulWidget {
  final String drawingId;
  final int pageNumber;
  final Function(OcrDetectedLabel label)? onLabelSelected;
  final Function(Map<String, dynamic> issueData)? onCreateIssueFromAi;
  final VoidCallback? onClose;

  const AiCopilotSheet({
    super.key,
    required this.drawingId,
    required this.pageNumber,
    this.onLabelSelected,
    this.onCreateIssueFromAi,
    this.onClose,
  });

  @override
  State<AiCopilotSheet> createState() => _AiCopilotSheetState();
}

class _AiCopilotSheetState extends State<AiCopilotSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FieldAiService _aiService = FieldAiService();

  // OCR state
  bool _isOcrScanning = false;
  List<OcrDetectedLabel> _detectedLabels = [];

  // Voice to Issue state
  final TextEditingController _voiceInputController = TextEditingController();
  AiProposal<Map<String, dynamic>>? _voiceProposal;
  bool _isProcessingVoice = false;

  // NLP Search state
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _runOcrScan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runOcrScan() async {
    setState(() => _isOcrScanning = true);
    final labels = await _aiService.detectDrawingLabels(widget.drawingId, widget.pageNumber);
    if (mounted) {
      setState(() {
        _detectedLabels = labels;
        _isOcrScanning = false;
      });
    }
  }

  Future<void> _processVoiceTranscript(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _isProcessingVoice = true);
    final proposal = await _aiService.parseVoiceToIssue(text);
    if (mounted) {
      setState(() {
        _voiceProposal = proposal;
        _isProcessingVoice = false;
      });
    }
  }

  Future<void> _performNlpSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _aiService.naturalLanguageProjectSearch(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF171D27),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF121620),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engineering Field AI Copilot',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Safe, Deterministic Human-in-the-Loop Assistance',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: const Color(0xFF141923),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.purpleAccent,
              labelColor: Colors.purpleAccent,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.document_scanner_rounded, size: 16), text: 'Drawing OCR'),
                Tab(icon: Icon(Icons.mic_rounded, size: 16), text: 'Voice to Issue'),
                Tab(icon: Icon(Icons.search_rounded, size: 16), text: 'Smart Search'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOcrTab(),
                _buildVoiceToIssueTab(),
                _buildNlpSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrTab() {
    if (_isOcrScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purpleAccent),
            SizedBox(height: 12),
            Text('Scanning blueprint for tags, lines & specs...', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DETECTED DRAWING TAGS (${_detectedLabels.length})',
              style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              onPressed: _runOcrScan,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._detectedLabels.map((lbl) {
          return Card(
            color: const Color(0xFF1B2230),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            child: ListTile(
              dense: true,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tag_rounded, color: Colors.purpleAccent, size: 16),
              ),
              title: Text(lbl.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(
                '${lbl.tagType} • Confidence: ${(lbl.confidence * 100).toInt()}%',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                  foregroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 28),
                ),
                child: const Text('Focus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  widget.onLabelSelected?.call(lbl);
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVoiceToIssueTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'RECORD OR PASTE VOICE NOTE TO EXTRACT ISSUE',
          style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _voiceInputController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'e.g. Found severe oil leak on flange FLG-102 due to missing spiral wound gasket...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF131720),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('AI Extract Structured Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _isProcessingVoice
                    ? null
                    : () => _processVoiceTranscript(_voiceInputController.text),
              ),
            ),
          ],
        ),
        if (_voiceProposal != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2230),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.purpleAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(_voiceProposal!.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_voiceProposal!.rationale, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const Divider(height: 16, color: Colors.white12),
                Text('Category: ${_voiceProposal!.data['category']}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                Text('Priority: ${_voiceProposal!.data['priority']}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                Text('Title: ${_voiceProposal!.data['title']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Confirm & Save to Punch List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () {
                    widget.onCreateIssueFromAi?.call(_voiceProposal!.data);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNlpSearchTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'e.g. "Find all high pressure valves" or "P-102"',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.purpleAccent, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent, size: 16),
              onPressed: () => _performNlpSearch(_searchController.text),
            ),
            filled: true,
            fillColor: const Color(0xFF131720),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: _performNlpSearch,
        ),
        const SizedBox(height: 10),
        if (_isSearching)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.purpleAccent)))
        else
          ..._searchResults.map((res) {
            return Card(
              color: const Color(0xFF1B2230),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(res['type'] ?? 'DOC', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                title: Text(res['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: Text(res['snippet'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ),
            );
          }),
      ],
    );
  }
}
