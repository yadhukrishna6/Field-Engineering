package com.fieldengineering.resource;

import com.fieldengineering.domain.VoiceNoteEntity;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Path("/api/v1/voice-notes")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class VoiceNoteResource {

    @GET
    public List<VoiceNoteEntity> listVoiceNotes(@QueryParam("issueId") String issueId, @QueryParam("drawingId") String drawingId) {
        if (issueId != null && !issueId.isEmpty()) {
            return VoiceNoteEntity.list("issueId", issueId);
        } else if (drawingId != null && !drawingId.isEmpty()) {
            return VoiceNoteEntity.list("drawingId", drawingId);
        }
        return VoiceNoteEntity.listAll();
    }

    @POST
    @Transactional
    public Response registerVoiceNote(VoiceNoteEntity voice) {
        if (voice.id == null || voice.id.isEmpty()) {
            voice.id = UUID.randomUUID().toString();
        }
        voice.createdAt = Instant.now();
        voice.persist();
        return Response.status(Response.Status.CREATED).entity(voice).build();
    }
}
