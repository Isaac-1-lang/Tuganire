package com.tuganire.servlet;

import com.google.gson.Gson;
import com.tuganire.model.Room;
import com.tuganire.model.RoomType;
import com.tuganire.service.ChatService;
import com.tuganire.service.RoomService;

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
 * GET /rooms — List joined rooms (JSON for SPA or forward to JSP)
 * POST /rooms — Create room
 * POST /rooms/join — Join room (via path param or body)
 */
@WebServlet(urlPatterns = {"/rooms", "/rooms/*"})
public class RoomServlet extends HttpServlet {

    private final RoomService roomService = new RoomService();
    private final ChatService chatService = new ChatService();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        List<Room> rooms = roomService.listRoomsForUser(userId);
        List<Map<String, Object>> payload = new ArrayList<>();
        for (Room r : rooms) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", r.getId());
            m.put("name", r.getName());
            m.put("type", r.getType().name());
            m.put("unreadCount", chatService.countUnread(r.getId(), userId));
            chatService.getLastMessage(r.getId()).ifPresent(msg -> {
                m.put("lastMessage", msg.getContent());
                m.put("lastMessageAt", msg.getCreatedAt().toString());
            });
            payload.add(m);
        }
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        res.getWriter().write(gson.toJson(payload));
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        String pathInfo = req.getPathInfo();
        if (pathInfo != null && pathInfo.matches("/\\d+/join")) {
            handleJoin(req, res, userId);
            return;
        }

        String name = req.getParameter("name");
        String typeStr = req.getParameter("type");
        String targetUserIdStr = req.getParameter("targetUserId"); // For DM

        if (typeStr != null && "DM".equalsIgnoreCase(typeStr) && targetUserIdStr != null) {
            int targetUserId = Integer.parseInt(targetUserIdStr);
            var roomOpt = roomService.createOrGetDm(userId, targetUserId);
            if (roomOpt.isEmpty()) {
                res.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            res.sendRedirect(req.getContextPath() + "/chat?roomId=" + roomOpt.get().getId());
        } else {
            var roomOpt = roomService.createGroupRoom(name != null ? name : "New Room", userId);
            if (roomOpt.isEmpty()) {
                res.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            res.sendRedirect(req.getContextPath() + "/chat?roomId=" + roomOpt.get().getId());
        }
    }

    private void handleJoin(HttpServletRequest req, HttpServletResponse res, int userId) throws IOException {
        String pathInfo = req.getPathInfo();
        int roomId = Integer.parseInt(pathInfo.replaceAll("[^0-9]", ""));
        boolean ok = roomService.joinRoom(roomId, userId);
        if (!ok) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        res.sendRedirect(req.getContextPath() + "/chat?roomId=" + roomId);
    }
}
