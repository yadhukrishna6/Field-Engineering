package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "audit_logs")
public class AuditLogEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(nullable = false)
    public String action;

    @Column(name = "user_email", nullable = false)
    public String userEmail;

    @Column(name = "user_role", nullable = false)
    public String userRole;

    @Column(name = "entity_type", nullable = false)
    public String entityType;

    @Column(name = "entity_id")
    public String entityId;

    @Column(columnDefinition = "TEXT")
    public String details;

    @Column(name = "ip_address")
    public String ipAddress;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();
}
