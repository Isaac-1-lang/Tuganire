package com.tuganire.servlet;

import com.google.gson.Gson;

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
 * POST /upload — Upload files (images, documents) for use in chat messages.
 * Returns JSON with the file URL for embedding in messages.
 */
@WebServlet(urlPatterns = {"/upload"})
@MultipartConfig(
        maxFileSize = 25 * 1024 * 1024, // 25 MB
        maxRequestSize = 26 * 1024 * 1024,
        fileSizeThreshold = 2 * 1024 * 1024
)
public class FileUploadServlet extends HttpServlet {

    private final Gson gson = new Gson();

    private static final String[] ALLOWED_EXTENSIONS = {
            "jpg", "jpeg", "png", "gif", "webp", "svg",
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
            "txt", "csv", "zip", "rar", "7z",
            "mp3", "wav", "ogg", "mp4", "webm"
    };

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException, ServletException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        Part filePart = req.getPart("file");
        if (filePart == null || filePart.getSize() == 0) {
            sendJson(res, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("error", "No file provided"));
            return;
        }

        String originalName = getFileName(filePart);
        String ext = getFileExtension(originalName);
        if (!isAllowed(ext)) {
            sendJson(res, HttpServletResponse.SC_BAD_REQUEST,
                    Map.of("error", "File type not allowed"));
            return;
        }

        String uploadsDir = getUploadsDir(req);
        String savedName = UUID.randomUUID().toString().substring(0, 12) + "_" + sanitizeFileName(originalName);
        String subDir = isImage(ext) ? "images" : "files";
        Path savePath = Paths.get(uploadsDir, subDir, savedName);
        Files.createDirectories(savePath.getParent());
        filePart.write(savePath.toString());

        String fileUrl = req.getContextPath() + "/uploads/" + subDir + "/" + savedName;
        String fileType = isImage(ext) ? "image" : "file";
        long fileSize = filePart.getSize();

        Map<String, Object> payload = new HashMap<>();
        payload.put("success", true);
        payload.put("url", fileUrl);
        payload.put("fileName", originalName);
        payload.put("fileType", fileType);
        payload.put("fileSize", fileSize);
        payload.put("extension", ext);

        sendJson(res, HttpServletResponse.SC_OK, payload);
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
        return (dot > 0) ? fileName.substring(dot + 1).toLowerCase() : "";
    }

    private String sanitizeFileName(String name) {
        return name.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private boolean isAllowed(String ext) {
        for (String a : ALLOWED_EXTENSIONS) {
            if (a.equals(ext)) return true;
        }
        return false;
    }

    private boolean isImage(String ext) {
        return ext.equals("jpg") || ext.equals("jpeg") || ext.equals("png") ||
                ext.equals("gif") || ext.equals("webp") || ext.equals("svg");
    }

    private void sendJson(HttpServletResponse res, int status, Map<String, Object> data) throws IOException {
        res.setStatus(status);
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(gson.toJson(data));
    }
}
