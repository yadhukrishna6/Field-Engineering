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

@Path("/api/v1/revisions")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class RevisionResource {

    @GET
    public List<DrawingRevisionEntity> listAllRevisions(@QueryParam("drawingId") String drawingId) {
        if (drawingId != null && !drawingId.isEmpty()) {
            return DrawingRevisionEntity.list("drawingId", drawingId);
        }
        return DrawingRevisionEntity.listAll();
    }

    @POST
    @Transactional
    public Response createRevision(DrawingRevisionEntity rev) {
        if (rev.id == null || rev.id.isEmpty()) {
            rev.id = UUID.randomUUID().toString();
        }
        rev.uploadedAt = Instant.now();
        rev.createdAt = Instant.now();
        rev.persist();

        // Update drawing current revision pointer
        DrawingEntity drawing = DrawingEntity.findById(rev.drawingId);
        if (drawing != null) {
            drawing.revision = rev.revisionNumber;
            drawing.version += 1;
            drawing.updatedBy = rev.uploadedBy;
            drawing.updatedAt = Instant.now();
        }

        return Response.status(Response.Status.CREATED).entity(rev).build();
    }
}
