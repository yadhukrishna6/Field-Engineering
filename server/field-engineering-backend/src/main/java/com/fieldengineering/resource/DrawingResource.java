package com.fieldengineering.resource;

import com.fieldengineering.domain.DrawingEntity;
import com.fieldengineering.domain.DrawingRevisionEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/drawings")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class DrawingResource {

    @GET
    public List<DrawingEntity> listDrawings(@QueryParam("projectId") String projectId) {
        if (projectId != null && !projectId.isEmpty()) {
            return DrawingEntity.list("projectId", projectId);
        }
        return DrawingEntity.listAll();
    }

    @GET
    @Path("/{id}")
    public Response getDrawing(@PathParam("id") String id) {
        DrawingEntity drawing = DrawingEntity.findById(id);
        if (drawing == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(drawing).build();
    }

    @POST
    @Transactional
    public Response createDrawing(DrawingEntity drawing) {
        if (drawing.id == null || drawing.id.isEmpty()) {
            drawing.id = UUID.randomUUID().toString();
        }
        drawing.createdAt = Instant.now();
        drawing.updatedAt = Instant.now();
        drawing.version = 1;
        drawing.persist();

        // Also record initial revision (Rev 00)
        DrawingRevisionEntity rev00 = new DrawingRevisionEntity();
        rev00.id = UUID.randomUUID().toString();
        rev00.drawingId = drawing.id;
        rev00.revisionNumber = drawing.revision != null ? drawing.revision : "Rev 00";
        rev00.revisionDescription = "Initial Issued for Construction (IFC) Drawing";
        rev00.uploadedBy = drawing.updatedBy != null ? drawing.updatedBy : "Document Controller";
        rev00.uploadedAt = Instant.now();
        rev00.s3Key = drawing.s3Key;
        rev00.revisionStatus = "Approved";
        rev00.createdAt = Instant.now();
        rev00.persist();

        return Response.status(Response.Status.CREATED).entity(drawing).build();
    }

    @GET
    @Path("/{id}/revisions")
    public List<DrawingRevisionEntity> listRevisions(@PathParam("id") String drawingId) {
        return DrawingRevisionEntity.list("drawingId", drawingId);
    }
}
