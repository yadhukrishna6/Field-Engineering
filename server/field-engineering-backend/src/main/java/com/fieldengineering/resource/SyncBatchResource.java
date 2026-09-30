package com.fieldengineering.resource;

import com.fieldengineering.domain.*;
import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.annotation.security.RolesAllowed;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.Instant;
import java.util.*;

@Path("/api/v1/sync")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SyncBatchResource {

    public static class SyncBatchRequest {
        public String clientId;
        public String lastSyncTimestamp;
        public List<SyncOperation> operations = new ArrayList<>();
    }

    public static class SyncOperation {
        public String id;
        public String entityType; // PROJECT, DRAWING, REVISION, MARKUP, MEASUREMENT, ISSUE, INSPECTION, EQUIPMENT, PHOTO, VOICE_NOTE
        public String entityId;
        public String action; // CREATE, UPDATE, DELETE, UPLOAD_FILE
        public int clientVersion;
        public String payloadJson;
        public String timestamp;
    }

    public static class SyncBatchResponse {
        public String serverTimestamp;
        public List<String> appliedOperationIds = new ArrayList<>();
        public List<ConflictReport> conflicts = new ArrayList<>();
        public ServerDeltaData delta = new ServerDeltaData();
    }

    public static class ConflictReport {
        public String operationId;
        public String entityType;
        public String entityId;
        public int serverVersion;
        public int clientVersion;
        public String serverPayloadJson;
        public String message;
    }

    public static class ServerDeltaData {
        public List<ProjectEntity> projects = new ArrayList<>();
        public List<DrawingEntity> drawings = new ArrayList<>();
        public List<DrawingRevisionEntity> revisions = new ArrayList<>();
        public List<MarkupEntity> markups = new ArrayList<>();
        public List<MeasurementEntity> measurements = new ArrayList<>();
        public List<IssueEntity> issues = new ArrayList<>();
        public List<InspectionEntity> inspections = new ArrayList<>();
        public List<EquipmentEntity> equipment = new ArrayList<>();
    }

    @POST
    @Path("/push")
    @Transactional
    public Response processBatchSync(SyncBatchRequest request) {
        SyncBatchResponse response = new SyncBatchResponse();
        response.serverTimestamp = Instant.now().toString();

        if (request != null && request.operations != null) {
            for (SyncOperation op : request.operations) {
                try {
                    // Check version conflict if it's an UPDATE or DELETE
                    boolean hasConflict = checkConflict(op, response);
                    if (!hasConflict) {
                        applyOperation(op);
                        response.appliedOperationIds.add(op.id);
                    }
                } catch (Exception e) {
                    ConflictReport cr = new ConflictReport();
                    cr.operationId = op.id;
                    cr.entityType = op.entityType;
                    cr.entityId = op.entityId;
                    cr.message = "Sync error: " + e.getMessage();
                    response.conflicts.add(cr);
                }
            }
        }

        return Response.ok(response).build();
    }

    private boolean checkConflict(SyncOperation op, SyncBatchResponse response) {
        if ("UPDATE".equalsIgnoreCase(op.action) || "DELETE".equalsIgnoreCase(op.action)) {
            if ("MARKUP".equalsIgnoreCase(op.entityType)) {
                MarkupEntity entity = MarkupEntity.findById(op.entityId);
                if (entity != null && entity.version > op.clientVersion) {
                    ConflictReport cr = new ConflictReport();
                    cr.operationId = op.id;
                    cr.entityType = op.entityType;
                    cr.entityId = op.entityId;
                    cr.serverVersion = entity.version;
                    cr.clientVersion = op.clientVersion;
                    cr.message = "Server has newer version (" + entity.version + " > " + op.clientVersion + ")";
                    response.conflicts.add(cr);
                    return true;
                }
            } else if ("ISSUE".equalsIgnoreCase(op.entityType)) {
                IssueEntity entity = IssueEntity.findById(op.entityId);
                if (entity != null && entity.version > op.clientVersion) {
                    ConflictReport cr = new ConflictReport();
                    cr.operationId = op.id;
                    cr.entityType = op.entityType;
                    cr.entityId = op.entityId;
                    cr.serverVersion = entity.version;
                    cr.clientVersion = op.clientVersion;
                    cr.message = "Issue was modified concurrently on server.";
                    response.conflicts.add(cr);
                    return true;
                }
            }
        }
        return false;
    }

    private void applyOperation(SyncOperation op) {
        // Handle discrete operations by entity type
        if ("DELETE".equalsIgnoreCase(op.action)) {
            if ("MARKUP".equalsIgnoreCase(op.entityType)) MarkupEntity.deleteById(op.entityId);
            if ("MEASUREMENT".equalsIgnoreCase(op.entityType)) MeasurementEntity.deleteById(op.entityId);
            if ("ISSUE".equalsIgnoreCase(op.entityType)) IssueEntity.deleteById(op.entityId);
            if ("INSPECTION".equalsIgnoreCase(op.entityType)) InspectionEntity.deleteById(op.entityId);
            if ("EQUIPMENT".equalsIgnoreCase(op.entityType)) EquipmentEntity.deleteById(op.entityId);
        }
    }

    @GET
    @Path("/pull")
    public Response pullDeltas(@QueryParam("since") String sinceTimestamp) {
        ServerDeltaData delta = new ServerDeltaData();
        delta.projects = ProjectEntity.listAll();
        delta.drawings = DrawingEntity.listAll();
        delta.revisions = DrawingRevisionEntity.listAll();
        delta.markups = MarkupEntity.listAll();
        delta.measurements = MeasurementEntity.listAll();
        delta.issues = IssueEntity.listAll();
        delta.inspections = InspectionEntity.listAll();
        delta.equipment = EquipmentEntity.listAll();

        return Response.ok(delta).build();
    }
}
