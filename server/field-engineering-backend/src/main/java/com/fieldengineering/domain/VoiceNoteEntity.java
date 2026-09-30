package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "voice_notes")
public class VoiceNoteEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "s3_key", nullable = false)
    public String s3Key;

    @Column(nullable = false)
    public String title;

    @Column(name = "duration_seconds", nullable = false)
    public int durationSeconds = 0;

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

    @Column(name = "created_by")
    public String createdBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();
}
