package com.fieldengineering.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;

@Entity
@Table(name = "inspection_items")
public class InspectionItemEntity extends PanacheEntityBase {
    @Id
    @Column(length = 64)
    public String id;

    @Column(name = "inspection_id", nullable = false)
    public String inspectionId;

    @Column(nullable = false)
    public String category;

    @Column(nullable = false, columnDefinition = "TEXT")
    public String description;

    @Column(nullable = false)
    public String status = "PENDING"; // PASS, FAIL, N/A, PENDING

    @Column(columnDefinition = "TEXT")
    public String comments;

    @Column(name = "photo_ids_json", columnDefinition = "TEXT")
    public String photoIdsJson;

    @Column(name = "order_index", nullable = false)
    public int orderIndex = 0;
}
