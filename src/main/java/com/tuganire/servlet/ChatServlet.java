package com.tuganire.servlet;

import com.google.gson.Gson;
import com.tuganire.model.Message;
import com.tuganire.service.ChatService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * GET /messages — Load paginated message history (JSON).
 */
@WebServlet(urlPatterns = {"/messages"})
public class ChatServlet extends HttpServlet {

    private final ChatService chatService = new ChatService();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        String roomIdParam = req.getParameter("roomId");
        if (roomIdParam == null || roomIdParam.isBlank()) {
            res.sendError(HttpServletResponse.SC_BAD_REQUEST, "roomId required");
            return;
        }
        int roomId;
        try {
            roomId = Integer.parseInt(roomIdParam);
        } catch (NumberFormatException e) {
            res.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid roomId");
            return;
        }
        int limit = parseIntParam(req.getParameter("limit"), 50);
        int offset = parseIntParam(req.getParameter("offset"), 0);
        limit = Math.min(Math.max(limit, 1), 100);

        List<Message> messages = chatService.loadHistory(roomId, userId, limit, offset);
        List<Map<String, Object>> payload = new ArrayList<>();
        for (Message m : messages) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", m.getId());
            map.put("roomId", m.getRoom().getId());
            map.put("senderId", m.getSender().getId());
            map.put("senderUsername", m.getSender().getUsername());
            map.put("content", m.getContent());
            map.put("mediaUrl", m.getMediaUrl());
            map.put("replyToId", m.getReplyTo() != null ? m.getReplyTo().getId() : null);
            map.put("createdAt", m.getCreatedAt().toString());
            payload.add(map);
        }
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(gson.toJson(payload));
    }

    private int parseIntParam(String s, int def) {
        if (s == null || s.isBlank()) return def;
        try {
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
