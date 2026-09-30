package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "inspections")
public class InspectionEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "project_id", nullable = false)
    public String projectId;

    @Column(name = "drawing_id")
    public String drawingId;

    @Column(name = "equipment_id")
    public String equipmentId;

    @Column(nullable = false)
    public String title;

    @Column(name = "inspection_type", nullable = false)
    public String inspectionType = "Piping";

    @Column(nullable = false)
    public String status = "Draft";

    @Column(name = "inspector_name", nullable = false)
    public String inspectorName;

    @Column(name = "inspector_signature_s3_key")
    public String inspectorSignatureS3Key;

    @Column(name = "client_signature_s3_key")
    public String clientSignatureS3Key;

    @Column(name = "inspection_date", nullable = false)
    public Instant inspectionDate = Instant.now();

    @Column(name = "summary_notes", columnDefinition = "TEXT")
    public String summaryNotes;

    public Double latitude;
    public Double longitude;

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();
}
