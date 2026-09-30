package com.fieldengineering.resource;

import com.fieldengineering.domain.AuditLogEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/audit-logs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuditLogResource {

    @GET
    public List<AuditLogEntity> listAuditLogs(@QueryParam("userEmail") String userEmail) {
        if (userEmail != null && !userEmail.isEmpty()) {
            return AuditLogEntity.list("userEmail", userEmail);
        }
        return AuditLogEntity.listAll();
    }

    @POST
    @Transactional
    public Response recordAuditLog(AuditLogEntity log) {
        if (log.id == null || log.id.isEmpty()) {
            log.id = UUID.randomUUID().toString();
        }
        log.createdAt = Instant.now();
        log.persist();
        return Response.status(Response.Status.CREATED).entity(log).build();
    }
}
