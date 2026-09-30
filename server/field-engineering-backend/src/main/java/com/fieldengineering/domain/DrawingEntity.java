package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "drawings")
public class DrawingEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "project_id", nullable = false)
    public String projectId;

    @Column(name = "drawing_number", nullable = false)
    public String drawingNumber;

    @Column(nullable = false)
    public String title;

    @Column(name = "drawing_type", nullable = false)
    public String drawingType;

    @Column(nullable = false)
    public String revision = "Rev 00";

    @Column(name = "s3_key", nullable = false)
    public String s3Key;

    @Column(name = "thumbnail_s3_key")
    public String thumbnailS3Key;

    @Column(name = "page_count", nullable = false)
    public int pageCount = 1;

    @Column(name = "file_size", nullable = false)
    public long fileSize = 0;

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();
}
