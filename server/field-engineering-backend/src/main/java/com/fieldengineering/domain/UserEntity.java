package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "users")
public class UserEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(nullable = false, unique = true)
    public String email;

    @Column(name = "password_hash", nullable = false)
    public String passwordHash;

    @Column(name = "full_name", nullable = false)
    public String fullName;

    @Column(name = "employee_id")
    public String employeeId;

    @Column(nullable = false)
    public String role; // leadEngineer, qcInspector, fieldTechnician, clientRepresentative

    @Column(nullable = false)
    public boolean active = true;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    public Instant updatedAt = Instant.now();

    public static UserEntity findByEmail(String email) {
        return find("email", email).firstResult();
    }
}
