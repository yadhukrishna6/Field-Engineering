package com.fieldengineering.resource;

import com.fieldengineering.domain.MarkupEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/markups")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MarkupResource {

    @GET
    public List<MarkupEntity> listMarkups(@QueryParam("drawingId") String drawingId, @QueryParam("pageNumber") Integer pageNumber) {
        if (drawingId != null && pageNumber != null) {
            return MarkupEntity.list("drawingId = ?1 and pageNumber = ?2", drawingId, pageNumber);
        } else if (drawingId != null) {
            return MarkupEntity.list("drawingId", drawingId);
        }
        return MarkupEntity.listAll();
    }

    @POST
    @Transactional
    public Response createMarkup(MarkupEntity markup) {
        if (markup.id == null || markup.id.isEmpty()) {
            markup.id = UUID.randomUUID().toString();
        }
        markup.createdAt = Instant.now();
        markup.updatedAt = Instant.now();
        markup.version = 1;
        markup.persist();
        return Response.status(Response.Status.CREATED).entity(markup).build();
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response deleteMarkup(@PathParam("id") String id) {
        boolean deleted = MarkupEntity.deleteById(id);
        if (!deleted) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.noContent().build();
    }
}
