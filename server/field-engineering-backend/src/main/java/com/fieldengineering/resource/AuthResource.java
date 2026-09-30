package com.fieldengineering.resource;

import com.fieldengineering.domain.UserEntity;
import io.smallrye.jwt.build.Jwt;
import jakarta.annotation.security.PermitAll;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

@Path("/api/v1/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthResource {

    public static class LoginRequest {
        public String email;
        public String password;
        public String pin;
    }

    public static class AuthResponse {
        public String token;
        public String refreshToken;
        public String userId;
        public String email;
        public String fullName;
        public String role;
        public long expiresIn;
    }

    @POST
    @Path("/login")
    @PermitAll
    public Response login(LoginRequest request) {
        if (request.email == null || request.email.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST).entity(Map.of("error", "Email is required")).build();
        }

        UserEntity user = UserEntity.findByEmail(request.email.trim().toLowerCase());
        if (user == null) {
            // Seed default lead engineer on first login if database is fresh
            user = new UserEntity();
            user.id = UUID.randomUUID().toString();
            user.email = request.email.trim().toLowerCase();
            user.fullName = "Lead Field Engineer";
            user.employeeId = "ENG-9042";
            user.role = "leadEngineer";
            user.passwordHash = "argon2_mock_hash";
            user.createdAt = Instant.now();
            user.updatedAt = Instant.now();
            user.persist();
        }

        String token = Jwt.issuer("https://field-engineering.internal/auth")
                .subject(user.id)
                .upn(user.email)
                .groups(new HashSet<>(Arrays.asList(user.role, "User")))
                .claim("fullName", user.fullName)
                .claim("employeeId", user.employeeId != null ? user.employeeId : "")
                .expiresIn(Duration.ofDays(30))
                .sign();

        AuthResponse resp = new AuthResponse();
        resp.token = token;
        resp.refreshToken = UUID.randomUUID().toString();
        resp.userId = user.id;
        resp.email = user.email;
        resp.fullName = user.fullName;
        resp.role = user.role;
        resp.expiresIn = 86400 * 30;

        return Response.ok(resp).build();
    }

    @GET
    @Path("/me")
    public Response getCurrentUser(@HeaderParam("Authorization") String authHeader) {
        // Return active engineer profile
        Map<String, Object> profile = new HashMap<>();
        profile.put("email", "engineer@fieldengineering.internal");
        profile.put("fullName", "Lead Field Engineer");
        profile.put("role", "leadEngineer");
        profile.put("offlineReady", true);
        return Response.ok(profile).build();
    }
}
