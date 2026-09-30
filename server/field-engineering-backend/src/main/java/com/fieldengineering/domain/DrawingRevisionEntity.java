package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "revisions")
public class DrawingRevisionEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "drawing_id", nullable = false)
    public String drawingId;

    @Column(name = "revision_number", nullable = false)
    public String revisionNumber; // Rev 00, Rev 01, Rev 02, Rev 03

    @Column(name = "revision_description", nullable = false, columnDefinition = "TEXT")
    public String revisionDescription;

    @Column(name = "uploaded_by", nullable = false)
    public String uploadedBy;

    @Column(name = "uploaded_at", nullable = false)
    public Instant uploadedAt = Instant.now();

    @Column(name = "s3_key", nullable = false)
    public String s3Key;

    @Column(name = "revision_status", nullable = false)
    public String revisionStatus = "Approved"; // Draft, Approved, Superseded, As-Built, Void

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();
}
