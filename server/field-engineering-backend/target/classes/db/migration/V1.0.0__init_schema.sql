-- ==============================================================================
-- FIELD ENGINEERING POSTGRESQL CLOUD SCHEMA (V1.0.0)
-- ==============================================================================

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    employee_id VARCHAR(64),
    role VARCHAR(64) NOT NULL DEFAULT 'leadEngineer',
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id VARCHAR(64) PRIMARY KEY,
    project_number VARCHAR(128) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    client VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    status VARCHAR(64) NOT NULL DEFAULT 'Active',
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Drawings Table
CREATE TABLE IF NOT EXISTS drawings (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    drawing_number VARCHAR(128) NOT NULL,
    title VARCHAR(255) NOT NULL,
    drawing_type VARCHAR(64) NOT NULL,
    revision VARCHAR(32) NOT NULL DEFAULT 'Rev 00',
    s3_key VARCHAR(512) NOT NULL,
    thumbnail_s3_key VARCHAR(512),
    page_count INT NOT NULL DEFAULT 1,
    file_size BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Drawing Revisions Table (Immutable Historical Revisions)
CREATE TABLE IF NOT EXISTS revisions (
    id VARCHAR(64) PRIMARY KEY,
    drawing_id VARCHAR(64) NOT NULL REFERENCES drawings(id) ON DELETE CASCADE,
    revision_number VARCHAR(32) NOT NULL,
    revision_description TEXT NOT NULL,
    uploaded_by VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    s3_key VARCHAR(512) NOT NULL,
    revision_status VARCHAR(64) NOT NULL DEFAULT 'Approved',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. Markups Table (Layered Vector Annotations)
CREATE TABLE IF NOT EXISTS markups (
    id VARCHAR(64) PRIMARY KEY,
    drawing_id VARCHAR(64) NOT NULL REFERENCES drawings(id) ON DELETE CASCADE,
    page_number INT NOT NULL DEFAULT 1,
    layer VARCHAR(64) NOT NULL DEFAULT 'markup',
    type VARCHAR(64) NOT NULL,
    color INT NOT NULL,
    fill_color INT,
    stroke_width REAL NOT NULL DEFAULT 2.0,
    opacity REAL NOT NULL DEFAULT 1.0,
    geometry_data JSONB NOT NULL,
    text TEXT,
    metadata JSONB,
    created_by VARCHAR(255) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. Calibrations Table
CREATE TABLE IF NOT EXISTS calibrations (
    id VARCHAR(64) PRIMARY KEY,
    drawing_id VARCHAR(64) NOT NULL REFERENCES drawings(id) ON DELETE CASCADE,
    page_number INT NOT NULL DEFAULT 1,
    point1_x REAL NOT NULL,
    point1_y REAL NOT NULL,
    point2_x REAL NOT NULL,
    point2_y REAL NOT NULL,
    known_distance REAL NOT NULL,
    unit VARCHAR(32) NOT NULL,
    scale_factor REAL NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. Measurements Table
CREATE TABLE IF NOT EXISTS measurements (
    id VARCHAR(64) PRIMARY KEY,
    drawing_id VARCHAR(64) NOT NULL REFERENCES drawings(id) ON DELETE CASCADE,
    page_number INT NOT NULL DEFAULT 1,
    type VARCHAR(64) NOT NULL,
    points_data JSONB NOT NULL,
    calculated_value REAL NOT NULL,
    unit VARCHAR(32) NOT NULL,
    calibration_id VARCHAR(64),
    label VARCHAR(255),
    color INT,
    metadata JSONB,
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. Issues & Punch List Table
CREATE TABLE IF NOT EXISTS issues (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    drawing_id VARCHAR(64) REFERENCES drawings(id) ON DELETE SET NULL,
    page_number INT NOT NULL DEFAULT 1,
    position_x REAL,
    position_y REAL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(64) NOT NULL DEFAULT 'Piping',
    priority VARCHAR(64) NOT NULL DEFAULT 'Medium',
    status VARCHAR(64) NOT NULL DEFAULT 'Open',
    assigned_to VARCHAR(255),
    created_by VARCHAR(255) NOT NULL,
    due_date VARCHAR(64),
    equipment_id VARCHAR(64),
    inspection_id VARCHAR(64),
    latitude REAL,
    longitude REAL,
    gps_accuracy REAL,
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9. Photos Table
CREATE TABLE IF NOT EXISTS photos (
    id VARCHAR(64) PRIMARY KEY,
    s3_key VARCHAR(512) NOT NULL,
    thumbnail_s3_key VARCHAR(512),
    title VARCHAR(255),
    caption TEXT,
    latitude REAL,
    longitude REAL,
    gps_accuracy REAL,
    gps_timestamp TIMESTAMP WITH TIME ZONE,
    drawing_id VARCHAR(64),
    page_number INT DEFAULT 1,
    position_x REAL,
    position_y REAL,
    issue_id VARCHAR(64),
    inspection_id VARCHAR(64),
    equipment_id VARCHAR(64),
    file_size BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 10. Voice Notes Table
CREATE TABLE IF NOT EXISTS voice_notes (
    id VARCHAR(64) PRIMARY KEY,
    s3_key VARCHAR(512) NOT NULL,
    title VARCHAR(255) NOT NULL,
    duration_seconds INT NOT NULL DEFAULT 0,
    drawing_id VARCHAR(64),
    page_number INT DEFAULT 1,
    position_x REAL,
    position_y REAL,
    issue_id VARCHAR(64),
    inspection_id VARCHAR(64),
    created_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 11. Inspections Table
CREATE TABLE IF NOT EXISTS inspections (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    drawing_id VARCHAR(64),
    equipment_id VARCHAR(64),
    title VARCHAR(255) NOT NULL,
    inspection_type VARCHAR(64) NOT NULL DEFAULT 'Piping',
    status VARCHAR(64) NOT NULL DEFAULT 'Draft',
    inspector_name VARCHAR(255) NOT NULL,
    inspector_signature_s3_key VARCHAR(512),
    client_signature_s3_key VARCHAR(512),
    inspection_date TIMESTAMP WITH TIME ZONE NOT NULL,
    summary_notes TEXT,
    latitude REAL,
    longitude REAL,
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. Inspection Items Table
CREATE TABLE IF NOT EXISTS inspection_items (
    id VARCHAR(64) PRIMARY KEY,
    inspection_id VARCHAR(64) NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    category VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    comments TEXT,
    photo_ids_json JSONB,
    order_index INT NOT NULL DEFAULT 0
);

-- 13. Equipment Master Table
CREATE TABLE IF NOT EXISTS equipment (
    id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    equipment_number VARCHAR(128) NOT NULL,
    tag_number VARCHAR(128) NOT NULL,
    name VARCHAR(255) NOT NULL,
    drawing_type VARCHAR(64) NOT NULL DEFAULT 'Pump',
    location VARCHAR(255),
    drawing_id VARCHAR(64),
    notes TEXT,
    photo_s3_key VARCHAR(512),
    latitude REAL,
    longitude REAL,
    status VARCHAR(64) NOT NULL DEFAULT 'Operational',
    version INT NOT NULL DEFAULT 1,
    updated_by VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 14. Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(64) PRIMARY KEY,
    action VARCHAR(64) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_role VARCHAR(64) NOT NULL,
    entity_type VARCHAR(64) NOT NULL,
    entity_id VARCHAR(64),
    details TEXT,
    ip_address VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Cloud Fast Delta Querying
CREATE INDEX IF NOT EXISTS idx_cloud_drawings_project ON drawings(project_id);
CREATE INDEX IF NOT EXISTS idx_cloud_revisions_drawing ON revisions(drawing_id);
CREATE INDEX IF NOT EXISTS idx_cloud_markups_drawing ON markups(drawing_id, page_number);
CREATE INDEX IF NOT EXISTS idx_cloud_issues_project ON issues(project_id);
CREATE INDEX IF NOT EXISTS idx_cloud_inspections_project ON inspections(project_id);
CREATE INDEX IF NOT EXISTS idx_cloud_equipment_tag ON equipment(tag_number);
CREATE INDEX IF NOT EXISTS idx_cloud_audit_created ON audit_logs(created_at);
