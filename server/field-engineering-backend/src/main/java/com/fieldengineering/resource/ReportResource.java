package com.fieldengineering.resource;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.Instant;
import java.util.*;

@Path("/api/v1/reports")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ReportResource {

    public static class ReportRequest {
        public String type; // MARKED_UP_DRAWING, FIELD_INSPECTION, ISSUE_REPORT, PUNCH_LIST, MATERIAL_TAKEOFF, MEASUREMENT_REPORT, AS_BUILT
        public String projectId;
        public String drawingId;
        public String revision;
        public String generatedBy;
    }

    public static class ReportSummary {
        public String id;
        public String type;
        public String title;
        public String projectId;
        public String drawingId;
        public String revision;
        public String generatedBy;
        public String generatedAt;
        public String downloadUrl;
        public String status;
    }

    @POST
    @Path("/generate")
    public Response requestReportGeneration(ReportRequest request) {
        ReportSummary summary = new ReportSummary();
        summary.id = UUID.randomUUID().toString();
        summary.type = request.type;
        summary.projectId = request.projectId;
        summary.drawingId = request.drawingId;
        summary.revision = request.revision != null ? request.revision : "Rev 00";
        summary.generatedBy = request.generatedBy != null ? request.generatedBy : "Lead Engineer";
        summary.generatedAt = Instant.now().toString();
        summary.status = "COMPLETED";
        summary.title = "Engineering Report: " + request.type + " - " + summary.revision;
        summary.downloadUrl = "/api/v1/reports/download/" + summary.id + ".pdf";

        return Response.status(Response.Status.CREATED).entity(summary).build();
    }

    @GET
    @Path("/types")
    public Response getSupportedReportTypes() {
        List<Map<String, String>> types = List.of(
            Map.of("key", "MARKED_UP_DRAWING", "name", "1. Marked-up Drawing PDF", "desc", "Complete vectorized PDF with layer annotations"),
            Map.of("key", "FIELD_INSPECTION", "name", "2. Field Inspection QC Report", "desc", "Checklist results, pass/fail status, sign-offs"),
            Map.of("key", "ISSUE_REPORT", "name", "3. Field Issues & NCR Report", "desc", "Open/Closed field defects categorized by discipline"),
            Map.of("key", "PUNCH_LIST", "name", "4. Punch-List Report", "desc", "Pre-commissioning and walk-through items"),
            Map.of("key", "MATERIAL_TAKEOFF", "name", "5. Material Takeoff (MTO) Report", "desc", "Quantity estimates calculated from drawing markups"),
            Map.of("key", "MEASUREMENT_REPORT", "name", "6. Calibration & Measurement Log", "desc", "Point-to-point, area, and angle dimensional records"),
            Map.of("key", "AS_BUILT", "name", "7. As-Built Field Engineering Dossier", "desc", "Comprehensive field verification handover package")
        );
        return Response.ok(types).build();
    }
}
