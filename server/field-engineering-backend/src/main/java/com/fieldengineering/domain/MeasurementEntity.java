package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "measurements")
public class MeasurementEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "drawing_id", nullable = false)
    public String drawingId;

    @Column(name = "page_number", nullable = false)
    public int pageNumber = 1;

    @Column(nullable = false)
    public String type;

    @Column(name = "points_data", nullable = false, columnDefinition = "TEXT")
    public String pointsData;

    @Column(name = "calculated_value", nullable = false)
    public double calculatedValue;

    @Column(nullable = false)
    public String unit;

    @Column(name = "calibration_id")
    public String calibrationId;

    public String label;
    public Integer color;

    @Column(columnDefinition = "TEXT")
    public String metadata;

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();
}
