class DatabaseTables {
  static const String projects = 'projects';
  static const String drawings = 'drawings';
  static const String downloadQueue = 'download_queue';
  static const String markups = 'markups';

  // Projects Columns
  static const String colId = 'id';
  static const String colProjectNumber = 'project_number';
  static const String colName = 'name';
  static const String colDescription = 'description';
  static const String colClient = 'client';
  static const String colLocation = 'location';
  static const String colStatus = 'status';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Drawings Columns
  static const String colProjectId = 'project_id';
  static const String colDrawingNumber = 'drawing_number';
  static const String colTitle = 'title';
  static const String colDrawingType = 'drawing_type';
  static const String colRevision = 'revision';
  static const String colFilePath = 'file_path';
  static const String colThumbnailPath = 'thumbnail_path';
  static const String colPageCount = 'page_count';
  static const String colFileSize = 'file_size';
  static const String colDownloaded = 'downloaded';

  // Markups Columns
  static const String colDrawingId = 'drawing_id';
  static const String colPageNumber = 'page_number';
  static const String colLayer = 'layer';
  static const String colMarkupType = 'type';
  static const String colColor = 'color';
  static const String colFillColor = 'fill_color';
  static const String colStrokeWidth = 'stroke_width';
  static const String colOpacity = 'opacity';
  static const String colGeometryData = 'geometry_data';
  static const String colText = 'text';
  static const String colMetadata = 'metadata';
  static const String colCreatedBy = 'created_by';

  // Download Queue Columns
  static const String colProgress = 'progress';
  static const String colQueueStatus = 'queue_status';
  static const String colErrorMessage = 'error_message';
}
