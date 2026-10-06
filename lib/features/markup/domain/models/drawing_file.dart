class DrawingFile {
  final String id;
  final String name;
  final String fileType; // 'PDF' | 'IMAGE'
  final int pageCount;
  final String localPath;
  final String? fileUrl;
  final DateTime createdAt;

  const DrawingFile({
    required this.id,
    required this.name,
    required this.fileType,
    required this.pageCount,
    required this.localPath,
    this.fileUrl,
    required this.createdAt,
  });

  bool get isPdf => fileType.toUpperCase() == 'PDF';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fileType': fileType,
    'pageCount': pageCount,
    'localPath': localPath,
    'fileUrl': fileUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DrawingFile.fromJson(Map<String, dynamic> json) {
    return DrawingFile(
      id: json['id'] as String,
      name: json['name'] as String,
      fileType: json['fileType'] as String? ?? 'IMAGE',
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 1,
      localPath: json['localPath'] as String? ?? '',
      fileUrl: json['fileUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
