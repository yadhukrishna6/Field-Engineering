package com.fieldengineering.resource;

import com.fieldengineering.domain.IssueEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/issues")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class IssueResource {

    @GET
    public List<IssueEntity> listIssues(@QueryParam("projectId") String projectId, @QueryParam("drawingId") String drawingId) {
        if (drawingId != null && !drawingId.isEmpty()) {
            return IssueEntity.list("drawingId", drawingId);
        } else if (projectId != null && !projectId.isEmpty()) {
            return IssueEntity.list("projectId", projectId);
        }
        return IssueEntity.listAll();
    }

    @GET
    @Path("/{id}")
    public Response getIssue(@PathParam("id") String id) {
        IssueEntity issue = IssueEntity.findById(id);
        if (issue == null) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.ok(issue).build();
    }

    @POST
    @Transactional
    public Response createIssue(IssueEntity issue) {
        if (issue.id == null || issue.id.isEmpty()) {
            issue.id = UUID.randomUUID().toString();
        }
        issue.createdAt = Instant.now();
        issue.updatedAt = Instant.now();
        issue.version = 1;
        issue.persist();
        return Response.status(Response.Status.CREATED).entity(issue).build();
    }

    @PUT
    @Path("/{id}")
    @Transactional
    public Response updateIssue(@PathParam("id") String id, IssueEntity update) {
        IssueEntity existing = IssueEntity.findById(id);
        if (existing == null) return Response.status(Response.Status.NOT_FOUND).build();

        existing.title = update.title;
        existing.description = update.description;
        existing.category = update.category;
        existing.priority = update.priority;
        existing.status = update.status;
        existing.assignedTo = update.assignedTo;
        existing.dueDate = update.dueDate;
        existing.version += 1;
        existing.updatedBy = update.updatedBy;
        existing.updatedAt = Instant.now();

        return Response.ok(existing).build();
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response deleteIssue(@PathParam("id") String id) {
        boolean deleted = IssueEntity.deleteById(id);
        if (!deleted) return Response.status(Response.Status.NOT_FOUND).build();
        return Response.noContent().build();
    }
}
