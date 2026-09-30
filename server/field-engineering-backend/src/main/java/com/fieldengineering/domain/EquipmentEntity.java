package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "equipment")
public class EquipmentEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "project_id", nullable = false)
    public String projectId;

    @Column(name = "equipment_number", nullable = false)
    public String equipmentNumber;

    @Column(name = "tag_number", nullable = false)
    public String tagNumber;

    @Column(nullable = false)
    public String name;

    @Column(name = "drawing_type", nullable = false)
    public String drawingType = "Pump";

    public String location;

    @Column(name = "drawing_id")
    public String drawingId;

    @Column(columnDefinition = "TEXT")
    public String notes;

    @Column(name = "photo_s3_key")
    public String photoS3Key;

    public Double latitude;
    public Double longitude;

    @Column(nullable = false)
    public String status = "Operational";

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();
}
