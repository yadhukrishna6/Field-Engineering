package com.fieldengineering.resource;

import com.fieldengineering.domain.MeasurementEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/measurements")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MeasurementResource {

    @GET
    public List<MeasurementEntity> listMeasurements(@QueryParam("drawingId") String drawingId) {
        if (drawingId != null) {
            return MeasurementEntity.list("drawingId", drawingId);
        }
        return MeasurementEntity.listAll();
    }

    @POST
    @Transactional
    public Response createMeasurement(MeasurementEntity measurement) {
        if (measurement.id == null || measurement.id.isEmpty()) {
            measurement.id = UUID.randomUUID().toString();
        }
        measurement.createdAt = Instant.now();
        measurement.version = 1;
        measurement.persist();
        return Response.status(Response.Status.CREATED).entity(measurement).build();
    }
}
