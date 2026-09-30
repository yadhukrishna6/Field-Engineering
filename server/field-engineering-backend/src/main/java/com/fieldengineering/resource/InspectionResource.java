package com.fieldengineering.resource;

import com.fieldengineering.domain.InspectionEntity;
import com.fieldengineering.domain.InspectionItemEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/inspections")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class InspectionResource {

    @GET
    public List<InspectionEntity> listInspections(@QueryParam("projectId") String projectId) {
        if (projectId != null && !projectId.isEmpty()) {
            return InspectionEntity.list("projectId", projectId);
        }
        return InspectionEntity.listAll();
    }

    @GET
    @Path("/{id}")
    public Response getInspection(@PathParam("id") String id) {
        InspectionEntity insp = InspectionEntity.findById(id);
        if (insp == null) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.ok(insp).build();
    }

    @GET
    @Path("/{id}/items")
    public List<InspectionItemEntity> getInspectionItems(@PathParam("id") String inspectionId) {
        return InspectionItemEntity.list("inspectionId", inspectionId);
    }

    @POST
    @Transactional
    public Response createInspection(InspectionEntity inspection) {
        if (inspection.id == null || inspection.id.isEmpty()) {
            inspection.id = UUID.randomUUID().toString();
        }
        inspection.createdAt = Instant.now();
        inspection.updatedAt = Instant.now();
        inspection.version = 1;
        inspection.persist();
        return Response.status(Response.Status.CREATED).entity(inspection).build();
    }

    @PUT
    @Path("/{id}/items/{itemId}")
    @Transactional
    public Response updateInspectionItem(@PathParam("id") String inspectionId, @PathParam("itemId") String itemId, InspectionItemEntity update) {
        InspectionItemEntity existing = InspectionItemEntity.findById(itemId);
        if (existing == null) {
            update.id = itemId;
            update.inspectionId = inspectionId;
            update.persist();
            return Response.ok(update).build();
        }
        existing.status = update.status;
        existing.comments = update.comments;
        existing.photoIdsJson = update.photoIdsJson;
        return Response.ok(existing).build();
    }
}
