class DatabaseTables {
  static const String drawings = 'drawings';
  static const String pageMarkups = 'page_markups';

  // Common Columns
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colFileType = 'fileType';
  static const String colPageCount = 'pageCount';
  static const String colLocalPath = 'localPath';
  static const String colFileUrl = 'fileUrl';
  static const String colCreatedAt = 'createdAt';

  // Page Markup Columns
  static const String colDrawingId = 'drawingId';
  static const String colPageNumber = 'pageNumber';
  static const String colPayload = 'payload';
  static const String colVersion = 'version';
  static const String colUpdatedAt = 'updatedAt';
}
