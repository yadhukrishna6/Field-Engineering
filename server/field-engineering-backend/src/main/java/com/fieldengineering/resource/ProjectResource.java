package com.fieldengineering.resource;

import com.fieldengineering.domain.ProjectEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/projects")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ProjectResource {

    @GET
    public List<ProjectEntity> listProjects() {
        return ProjectEntity.listAll();
    }

    @GET
    @Path("/{id}")
    public Response getProject(@PathParam("id") String id) {
        ProjectEntity project = ProjectEntity.findById(id);
        if (project == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(project).build();
    }

    @POST
    @Transactional
    public Response createProject(ProjectEntity project) {
        if (project.id == null || project.id.isEmpty()) {
            project.id = UUID.randomUUID().toString();
        }
        project.createdAt = Instant.now();
        project.updatedAt = Instant.now();
        project.version = 1;
        project.persist();
        return Response.status(Response.Status.CREATED).entity(project).build();
    }

    @PUT
    @Path("/{id}")
    @Transactional
    public Response updateProject(@PathParam("id") String id, ProjectEntity update) {
        ProjectEntity existing = ProjectEntity.findById(id);
        if (existing == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        existing.name = update.name;
        existing.description = update.description;
        existing.client = update.client;
        existing.location = update.location;
        existing.status = update.status;
        existing.version += 1;
        existing.updatedBy = update.updatedBy;
        existing.updatedAt = Instant.now();
        return Response.ok(existing).build();
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response deleteProject(@PathParam("id") String id) {
        boolean deleted = ProjectEntity.deleteById(id);
        if (!deleted) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.noContent().build();
    }
}
