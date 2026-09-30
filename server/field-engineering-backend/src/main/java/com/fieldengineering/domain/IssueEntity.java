package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "issues")
public class IssueEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "project_id", nullable = false)
    public String projectId;

    @Column(name = "drawing_id")
    public String drawingId;

    @Column(name = "page_number", nullable = false)
    public int pageNumber = 1;

    @Column(name = "position_x")
    public Double positionX;

    @Column(name = "position_y")
    public Double positionY;

    @Column(nullable = false)
    public String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    public String description;

    @Column(nullable = false)
    public String category = "Piping";

    @Column(nullable = false)
    public String priority = "Medium";

    @Column(nullable = false)
    public String status = "Open";

    @Column(name = "assigned_to")
    public String assignedTo;

    @Column(name = "created_by", nullable = false)
    public String createdBy;

    @Column(name = "due_date")
    public String dueDate;

    @Column(name = "equipment_id")
    public String equipmentId;

    @Column(name = "inspection_id")
    public String inspectionId;

    public Double latitude;
    public Double longitude;

    @Column(name = "gps_accuracy")
    public Double gpsAccuracy;

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();
}
