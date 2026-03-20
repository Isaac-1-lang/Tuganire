package com.tuganire.servlet;

import com.google.gson.Gson;
import com.tuganire.model.User;
import com.tuganire.service.UserService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;


import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Handles profile viewing and avatar uploads.
 * GET  /profile       — Get current user profile (JSON)
 * POST /profile       — Update profile (avatar image, bio)
 */
@WebServlet(urlPatterns = {"/profile"})
@MultipartConfig(
        maxFileSize = 5 * 1024 * 1024, // 5 MB
        maxRequestSize = 6 * 1024 * 1024,
        fileSizeThreshold = 1024 * 1024
)
public class ProfileServlet extends HttpServlet {

    private final UserService userService = new UserService();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        var userOpt = userService.findById(userId);
        if (userOpt.isEmpty()) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        User u = userOpt.get();
        Map<String, Object> payload = new HashMap<>();
        payload.put("id", u.getId());
        payload.put("username", u.getUsername());
        payload.put("email", u.getEmail());
        payload.put("avatar", u.getAvatar());
        payload.put("bio", u.getBio());
        payload.put("isOnline", u.isOnline());
        payload.put("createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString() : null);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(gson.toJson(payload));
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException, ServletException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        String uploadsDir = getUploadsDir(req);

        // Handle avatar upload
        String avatarUrl = null;
        try {
            Part filePart = req.getPart("avatar");
            if (filePart != null && filePart.getSize() > 0) {
                String originalName = getFileName(filePart);
                String ext = getFileExtension(originalName);
                if (!isImageExtension(ext)) {
                    sendJson(res, HttpServletResponse.SC_BAD_REQUEST, Map.of("error", "Only image files are allowed"));
                    return;
                }
                String savedName = "avatar_" + userId + "_" + UUID.randomUUID().toString().substring(0, 8) + "." + ext;
                Path savePath = Paths.get(uploadsDir, "avatars", savedName);
                Files.createDirectories(savePath.getParent());
                filePart.write(savePath.toString());
                avatarUrl = req.getContextPath() + "/uploads/avatars/" + savedName;
            }
        } catch (Exception e) {
            // No file part or multipart issue — continue with bio update only
        }

        // Handle bio update
        String bio = req.getParameter("bio");

        var userOpt = userService.findById(userId);
        if (userOpt.isEmpty()) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        if (avatarUrl != null) {
            userService.updateAvatar(userId, avatarUrl);
        }
        if (bio != null) {
            userService.updateBio(userId, bio);
        }

        // Redirect back to chat if not AJAX
        if (isAjax(req)) {
            var updatedUser = userService.findById(userId).orElse(null);
            Map<String, Object> payload = new HashMap<>();
            payload.put("success", true);
            if (updatedUser != null) {
                payload.put("avatar", updatedUser.getAvatar());
                payload.put("bio", updatedUser.getBio());
            }
            sendJson(res, HttpServletResponse.SC_OK, payload);
        } else {
            res.sendRedirect(req.getContextPath() + "/chat");
        }
    }

    private String getUploadsDir(HttpServletRequest req) {
        String realPath = req.getServletContext().getRealPath("/uploads");
        if (realPath == null) {
            realPath = System.getProperty("catalina.base") + "/webapps/" +
                    req.getContextPath().replace("/", "") + "/uploads";
        }
        return realPath;
    }

    private String getFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return "file";
        for (String token : header.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "file";
    }

    private String getFileExtension(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return (dot > 0) ? fileName.substring(dot + 1).toLowerCase() : "png";
    }

    private boolean isImageExtension(String ext) {
        return ext.equals("jpg") || ext.equals("jpeg") || ext.equals("png") ||
                ext.equals("gif") || ext.equals("webp") || ext.equals("svg");
    }

    private boolean isAjax(HttpServletRequest req) {
        return "XMLHttpRequest".equals(req.getHeader("X-Requested-With"));
    }

    private void sendJson(HttpServletResponse res, int status, Map<String, Object> data) throws IOException {
        res.setStatus(status);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(gson.toJson(data));
    }
}
