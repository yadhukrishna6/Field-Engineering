package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "markups")
public class MarkupEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "drawing_id", nullable = false)
    public String drawingId;

    @Column(name = "page_number", nullable = false)
    public int pageNumber = 1;

    @Column(nullable = false)
    public String layer = "markup";

    @Column(nullable = false)
    public String type;

    @Column(nullable = false)
    public int color;

    @Column(name = "fill_color")
    public Integer fillColor;

    @Column(name = "stroke_width", nullable = false)
    public double strokeWidth = 2.0;

    @Column(nullable = false)
    public double opacity = 1.0;

    @Column(name = "geometry_data", nullable = false, columnDefinition = "TEXT")
    public String geometryData;

    @Column(columnDefinition = "TEXT")
    public String text;

    @Column(columnDefinition = "TEXT")
    public String metadata;

    @Column(name = "created_by", nullable = false)
    public String createdBy;

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();
}
