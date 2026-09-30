package com.fieldengineering.resource;

import com.fieldengineering.domain.EquipmentEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/equipment")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class EquipmentResource {

    @GET
    public List<EquipmentEntity> listEquipment(@QueryParam("projectId") String projectId) {
        if (projectId != null && !projectId.isEmpty()) {
            return EquipmentEntity.list("projectId", projectId);
        }
        return EquipmentEntity.listAll();
    }

    @GET
    @Path("/tag/{tagNumber}")
    public Response getByTag(@PathParam("tagNumber") String tagNumber) {
        EquipmentEntity eq = EquipmentEntity.find("tagNumber", tagNumber).firstResult();
        if (eq == null) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.ok(eq).build();
    }

    @POST
    @Transactional
    public Response createEquipment(EquipmentEntity eq) {
        if (eq.id == null || eq.id.isEmpty()) {
            eq.id = UUID.randomUUID().toString();
        }
        eq.createdAt = Instant.now();
        eq.updatedAt = Instant.now();
        eq.version = 1;
        eq.persist();
        return Response.status(Response.Status.CREATED).entity(eq).build();
    }
}
