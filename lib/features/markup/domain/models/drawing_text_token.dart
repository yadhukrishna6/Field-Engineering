class DrawingTextToken {
  final String text;
  final int pageNumber;
  final double x; // normalized 0.0 .. 1.0
  final double y; // normalized 0.0 .. 1.0
  final double width;
  final double height;
  final bool isTag;

  const DrawingTextToken({
    required this.text,
    required this.pageNumber,
    required this.x,
    required this.y,
    this.width = 0.08,
    this.height = 0.03,
    this.isTag = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'pageNumber': pageNumber,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'isTag': isTag,
  };

  factory DrawingTextToken.fromJson(Map<String, dynamic> json) {
    return DrawingTextToken(
      text: json['text'] as String? ?? '',
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.08,
      height: (json['height'] as num?)?.toDouble() ?? 0.03,
      isTag: json['isTag'] as bool? ?? false,
    );
  }
}
