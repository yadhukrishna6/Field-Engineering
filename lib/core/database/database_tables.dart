class DatabaseTables {
  // Core Tables
  static const String projects = 'projects';
  static const String drawings = 'drawings';
  static const String downloadQueue = 'download_queue';
  static const String markups = 'markups';
  static const String calibrations = 'calibrations';
  static const String measurements = 'measurements';
  static const String takeoffItems = 'takeoff_items';
  static const String savedCalculations = 'saved_calculations';

  // Phase 4 Tables
  static const String issues = 'issues';
  static const String photos = 'photos';
  static const String voiceNotes = 'voice_notes';
  static const String inspections = 'inspections';
  static const String inspectionItems = 'inspection_items';
  static const String equipment = 'equipment';

  // Phase 5 Tables: Sync, Revisions, Audit & Conflicts
  static const String syncQueue = 'sync_queue';
  static const String revisions = 'revisions';
  static const String auditLogs = 'audit_logs';
  static const String conflicts = 'conflicts';

  // Common Columns
  static const String colId = 'id';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colVersion = 'version';
  static const String colUpdatedBy = 'updated_by';

  // Projects Columns
  static const String colProjectNumber = 'project_number';
  static const String colName = 'name';
  static const String colDescription = 'description';
  static const String colClient = 'client';
  static const String colLocation = 'location';
  static const String colStatus = 'status';

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

  // Calibrations Columns
  static const String colPoint1X = 'point1_x';
  static const String colPoint1Y = 'point1_y';
  static const String colPoint2X = 'point2_x';
  static const String colPoint2Y = 'point2_y';
  static const String colKnownDistance = 'known_distance';
  static const String colScaleUnit = 'unit';
  static const String colScaleFactor = 'scale_factor';

  // Measurements Columns
  static const String colMeasurementType = 'type';
  static const String colPointsData = 'points_data';
  static const String colCalculatedValue = 'calculated_value';
  static const String colUnit = 'unit';
  static const String colCalibrationId = 'calibration_id';
  static const String colLabel = 'label';

  // Material Takeoff (MTO) Columns
  static const String colItemType = 'item_type';
  static const String colItemName = 'item_name';
  static const String colSpecification = 'specification';
  static const String colSize = 'size';
  static const String colQuantity = 'quantity';
  static const String colUnitWeight = 'unit_weight_kg';
  static const String colUnitCost = 'unit_cost';
  static const String colNotes = 'notes';
  static const String colLinkedCountTag = 'linked_count_tag';

  // Saved Calculations Columns
  static const String colCalcType = 'calc_type';
  static const String colInputsJson = 'inputs_json';
  static const String colResultsJson = 'results_json';
  static const String colEngineerNotes = 'engineer_notes';

  // Download Queue Columns
  static const String colProgress = 'progress';
  static const String colQueueStatus = 'queue_status';
  static const String colErrorMessage = 'error_message';

  // Phase 4: Issues & Punchlist Columns
  static const String colPositionX = 'position_x';
  static const String colPositionY = 'position_y';
  static const String colCategory = 'category';
  static const String colPriority = 'priority';
  static const String colAssignedTo = 'assigned_to';
  static const String colDueDate = 'due_date';
  static const String colEquipmentId = 'equipment_id';
  static const String colInspectionId = 'inspection_id';
  static const String colLatitude = 'latitude';
  static const String colLongitude = 'longitude';
  static const String colGpsAccuracy = 'gps_accuracy';

  // Phase 4: Photos Columns
  static const String colCaption = 'caption';
  static const String colGpsTimestamp = 'gps_timestamp';
  static const String colIssueId = 'issue_id';

  // Phase 4: Voice Notes Columns
  static const String colDurationSeconds = 'duration_seconds';

  // Phase 4: Inspections & Checklists Columns
  static const String colInspectionType = 'inspection_type';
  static const String colInspectorName = 'inspector_name';
  static const String colInspectorSignaturePath = 'inspector_signature_path';
  static const String colClientSignaturePath = 'client_signature_path';
  static const String colInspectionDate = 'inspection_date';
  static const String colSummaryNotes = 'summary_notes';

  // Phase 4: Inspection Items Columns
  static const String colComments = 'comments';
  static const String colPhotoIdsJson = 'photo_ids_json';
  static const String colOrderIndex = 'order_index';

  // Phase 4: Equipment Master Columns
  static const String colEquipmentNumber = 'equipment_number';
  static const String colTagNumber = 'tag_number';
  static const String colPhotoPath = 'photo_path';

  // Phase 5: Sync Queue Columns
  static const String colEntityType = 'entity_type';
  static const String colEntityId = 'entity_id';
  static const String colOperation = 'operation'; // CREATE, UPDATE, DELETE, UPLOAD_FILE
  static const String colPayloadJson = 'payload_json';
  static const String colRetryCount = 'retry_count';
  static const String colSyncStatus = 'sync_status'; // pending, syncing, synced, failed

  // Phase 5: Drawing Revisions Columns
  static const String colRevisionNumber = 'revision_number'; // Rev 00, Rev 01, Rev 02, Rev 03
  static const String colRevisionDescription = 'revision_description';
  static const String colUploadedBy = 'uploaded_by';
  static const String colUploadedAt = 'uploaded_at';
  static const String colRevisionStatus = 'revision_status'; // Draft, Approved, Superseded, As-Built, Void

  // Phase 5: Audit Logs Columns
  static const String colAction = 'action';
  static const String colUserEmail = 'user_email';
  static const String colUserRole = 'user_role';
  static const String colDetails = 'details';
  static const String colIpAddress = 'ip_address';

  // Phase 5: Conflicts Columns
  static const String colLocalPayloadJson = 'local_payload_json';
  static const String colServerPayloadJson = 'server_payload_json';
  static const String colLocalVersion = 'local_version';
  static const String colServerVersion = 'server_version';
  static const String colResolutionStatus = 'resolution_status'; // pending, resolved_local, resolved_server, resolved_merge
}
