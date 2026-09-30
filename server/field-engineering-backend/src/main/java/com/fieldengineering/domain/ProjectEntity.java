package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "projects")
public class ProjectEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "project_number", nullable = false, unique = true)
    public String projectNumber;

    @Column(nullable = false)
    public String name;

    @Column(columnDefinition = "TEXT")
    public String description;

    @Column(nullable = false)
    public String client;

    @Column(nullable = false)
    public String location;

    @Column(nullable = false)
    public String status = "Active";

    @Column(nullable = false)
    public int version = 1;

    @Column(name = "updated_by")
    public String updatedBy;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();
}
