import 'dart:convert';
import 'drawing_text_token.dart';

class DrawingFile {
  final String id;
  final String name;
  final String fileType; // 'PDF' | 'IMAGE'
  final int pageCount;
  final String localPath;
  final String? fileUrl;
  final DateTime createdAt;

  // Phase C: Title-Block & Metadata
  final String? jobNumber;
  final String? drawingNumber;
  final String? revision;
  final String? projectName;
  final String? title;
  final List<DrawingTextToken> extractedTokens;

  // Phase D: Review, Status & Audit
  final String? status; // 'in_progress' | 'under_review' | 'approved' | 'rejected'

  const DrawingFile({
    required this.id,
    required this.name,
    required this.fileType,
    required this.pageCount,
    required this.localPath,
    this.fileUrl,
    required this.createdAt,
    this.jobNumber,
    this.drawingNumber,
    this.revision,
    this.projectName,
    this.title,
    this.extractedTokens = const [],
    this.status = 'in_progress',
  });

  bool get isPdf => fileType.toUpperCase() == 'PDF';
  bool get isApproved => (status ?? '').toLowerCase() == 'approved';

  DrawingFile copyWith({
    String? id,
    String? name,
    String? fileType,
    int? pageCount,
    String? localPath,
    String? fileUrl,
    DateTime? createdAt,
    String? jobNumber,
    String? drawingNumber,
    String? revision,
    String? projectName,
    String? title,
    List<DrawingTextToken>? extractedTokens,
    String? status,
  }) {
    return DrawingFile(
      id: id ?? this.id,
      name: name ?? this.name,
      fileType: fileType ?? this.fileType,
      pageCount: pageCount ?? this.pageCount,
      localPath: localPath ?? this.localPath,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      jobNumber: jobNumber ?? this.jobNumber,
      drawingNumber: drawingNumber ?? this.drawingNumber,
      revision: revision ?? this.revision,
      projectName: projectName ?? this.projectName,
      title: title ?? this.title,
      extractedTokens: extractedTokens ?? this.extractedTokens,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fileType': fileType,
    'pageCount': pageCount,
    'localPath': localPath,
    'fileUrl': fileUrl,
    'createdAt': createdAt.toIso8601String(),
    if (jobNumber != null) 'jobNumber': jobNumber,
    if (drawingNumber != null) 'drawingNumber': drawingNumber,
    if (revision != null) 'revision': revision,
    if (projectName != null) 'projectName': projectName,
    if (title != null) 'title': title,
    'extractedTokens': extractedTokens.map((t) => t.toJson()).toList(),
    if (status != null) 'status': status,
  };

  Map<String, dynamic> toDbMap() => {
    'id': id,
    'name': name,
    'fileType': fileType,
    'pageCount': pageCount,
    'localPath': localPath,
    'fileUrl': fileUrl,
    'createdAt': createdAt.toIso8601String(),
    'jobNumber': jobNumber,
    'drawingNumber': drawingNumber,
    'revision': revision,
    'projectName': projectName,
    'title': title,
    'extractedTokens': jsonEncode(extractedTokens.map((t) => t.toJson()).toList()),
    'status': status,
  };

  factory DrawingFile.fromJson(Map<String, dynamic> json) {
    List<DrawingTextToken> tokens = [];
    final rawTokens = json['extractedTokens'];
    if (rawTokens is String) {
      try {
        final decoded = jsonDecode(rawTokens);
        if (decoded is List) {
          tokens = decoded.map((t) => DrawingTextToken.fromJson(t as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    } else if (rawTokens is List) {
      tokens = rawTokens.map((t) => DrawingTextToken.fromJson(t as Map<String, dynamic>)).toList();
    }

    return DrawingFile(
      id: json['id'] as String,
      name: json['name'] as String,
      fileType: json['fileType'] as String? ?? 'IMAGE',
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 1,
      localPath: json['localPath'] as String? ?? '',
      fileUrl: json['fileUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      jobNumber: json['jobNumber'] as String?,
      drawingNumber: json['drawingNumber'] as String?,
      revision: json['revision'] as String?,
      projectName: json['projectName'] as String?,
      title: json['title'] as String?,
      extractedTokens: tokens,
      status: json['status'] as String? ?? 'in_progress',
    );
  }
}
