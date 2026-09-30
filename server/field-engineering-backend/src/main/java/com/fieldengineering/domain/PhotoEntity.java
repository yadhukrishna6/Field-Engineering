package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "photos")
public class PhotoEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "s3_key", nullable = false)
    public String s3Key;

    @Column(name = "thumbnail_s3_key")
    public String thumbnailS3Key;

    public String title;

    @Column(columnDefinition = "TEXT")
    public String caption;

    public Double latitude;
    public Double longitude;

    @Column(name = "gps_accuracy")
    public Double gpsAccuracy;

    @Column(name = "gps_timestamp")
    public Instant gpsTimestamp;

    @Column(name = "drawing_id")
    public String drawingId;

    @Column(name = "page_number")
    public int pageNumber = 1;

    @Column(name = "position_x")
    public Double positionX;

    @Column(name = "position_y")
    public Double positionY;

    @Column(name = "issue_id")
    public String issueId;

    @Column(name = "inspection_id")
    public String inspectionId;

    @Column(name = "equipment_id")
    public String equipmentId;

    @Column(name = "file_size")
    public long fileSize = 0;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();
}
