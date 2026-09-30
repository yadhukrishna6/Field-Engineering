package com.fieldengineering.resource;

import com.fieldengineering.domain.PhotoEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/photos")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PhotoResource {

    @GET
    public List<PhotoEntity> listPhotos(@QueryParam("issueId") String issueId, @QueryParam("drawingId") String drawingId) {
        if (issueId != null && !issueId.isEmpty()) {
            return PhotoEntity.list("issueId", issueId);
        } else if (drawingId != null && !drawingId.isEmpty()) {
            return PhotoEntity.list("drawingId", drawingId);
        }
        return PhotoEntity.listAll();
    }

    @POST
    @Transactional
    public Response registerPhoto(PhotoEntity photo) {
        if (photo.id == null || photo.id.isEmpty()) {
            photo.id = UUID.randomUUID().toString();
        }
        photo.createdAt = Instant.now();
        photo.persist();
        return Response.status(Response.Status.CREATED).entity(photo).build();
    }
}
