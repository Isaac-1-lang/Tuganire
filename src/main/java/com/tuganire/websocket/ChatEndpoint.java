package com.tuganire.websocket;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.tuganire.model.Message;
import com.tuganire.model.User;
import com.tuganire.service.ChatService;
import com.tuganire.service.RoomService;
import com.tuganire.service.UserService;

import jakarta.websocket.*;
import jakarta.websocket.server.ServerEndpoint;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * WebSocket endpoint for real-time chat.
 * Supports: MESSAGE, TYPING, SEEN, REACTION, DELETE_MESSAGE, CALL_SIGNAL, JOIN_ROOM
 */
@ServerEndpoint(value = "/ws/chat", configurator = HttpSessionConfigurator.class)
public class ChatEndpoint {

    private static final Map<Integer, Session> USER_SESSIONS = new ConcurrentHashMap<>();
    private static final Gson GSON = new Gson();

    private final ChatService chatService = new ChatService();
    private final UserService userService = new UserService();
    private final RoomService roomService = new RoomService();

    private int userId;
    private String username;

    @OnOpen
    public void onOpen(Session session, EndpointConfig config) {
        Integer uid = (Integer) config.getUserProperties().get(HttpSessionConfigurator.USER_ID);
        String uname = (String) config.getUserProperties().get(HttpSessionConfigurator.USERNAME);
        if (uid == null || uname == null) {
            try {
                session.close(new CloseReason(CloseReason.CloseCodes.CANNOT_ACCEPT, "Unauthorized"));
            } catch (IOException e) {
                // ignore
            }
            return;
        }
        this.userId = uid;
        this.username = uname;
        USER_SESSIONS.put(userId, session);
        userService.setOnline(userId, true);

        // Broadcast with lastSeen
        broadcastUserStatus(userId, username, true, null);
    }

    @OnClose
    public void onClose(Session session) {
        USER_SESSIONS.remove(userId);
        userService.setOnline(userId, false);
        broadcastUserStatus(userId, username, false, Instant.now().toString());
    }

    @OnError
    public void onError(Session session, Throwable t) {
        USER_SESSIONS.remove(userId);
        userService.setOnline(userId, false);
        broadcastUserStatus(userId, username, false, Instant.now().toString());
    }

    @OnMessage
    public void onMessage(Session session, String text) {
        try {
            JsonObject obj = GSON.fromJson(text, JsonObject.class);
            String type = obj.has("type") ? obj.get("type").getAsString() : "";
            switch (type) {
                case "MESSAGE" -> handleMessage(obj);
                case "TYPING" -> handleTyping(obj);
                case "SEEN" -> handleSeen(obj);
                case "REACTION" -> handleReaction(obj);
                case "DELETE_MESSAGE" -> handleDeleteMessage(obj);
                case "CALL_SIGNAL" -> handleCallSignal(obj);
                case "JOIN_ROOM" -> handleJoinRoom(obj);
                default -> { /* ignore */ }
            }
        } catch (Exception e) {
            // Log and ignore malformed messages
        }
    }

    private void handleMessage(JsonObject obj) {
        int roomId = obj.get("roomId").getAsInt();
        String content = obj.has("content") ? obj.get("content").getAsString() : "";
        String mediaUrl = obj.has("mediaUrl") && !obj.get("mediaUrl").isJsonNull()
                ? obj.get("mediaUrl").getAsString() : null;
        String fileName = obj.has("fileName") && !obj.get("fileName").isJsonNull()
                ? obj.get("fileName").getAsString() : null;
        String fileType = obj.has("fileType") && !obj.get("fileType").isJsonNull()
                ? obj.get("fileType").getAsString() : null;
        Integer replyToId = obj.has("replyToId") && !obj.get("replyToId").isJsonNull()
                ? obj.get("replyToId").getAsInt() : null;

        var msgOpt = chatService.sendMessage(roomId, userId, content, replyToId);
        if (msgOpt.isPresent()) {
            Message m = msgOpt.get();
            JsonObject payload = new JsonObject();
            payload.addProperty("type", "MESSAGE");
            payload.addProperty("id", m.getId());
            payload.addProperty("roomId", roomId);
            payload.addProperty("senderId", userId);
            payload.addProperty("senderUsername", username);
            payload.addProperty("content", m.getContent());
            payload.addProperty("replyToId", replyToId != null ? replyToId : 0);
            payload.addProperty("createdAt", m.getCreatedAt().toString());
            // Include file info if present
            if (mediaUrl != null) {
                payload.addProperty("mediaUrl", mediaUrl);
            }
            if (fileName != null) {
                payload.addProperty("fileName", fileName);
            }
            if (fileType != null) {
                payload.addProperty("fileType", fileType);
            }
            // Get sender avatar
            userService.findById(userId).ifPresent(u -> {
                if (u.getAvatar() != null) {
                    payload.addProperty("senderAvatar", u.getAvatar());
                }
            });
            // Broadcast to everyone INCLUDING the sender
            broadcastToRoom(roomId, payload.toString(), null);
        }
    }

    private void handleTyping(JsonObject obj) {
        int roomId = obj.get("roomId").getAsInt();
        boolean isTyping = obj.has("isTyping") && obj.get("isTyping").getAsBoolean();
        JsonObject payload = new JsonObject();
        payload.addProperty("type", "TYPING");
        payload.addProperty("roomId", roomId);
        payload.addProperty("userId", userId);
        payload.addProperty("username", username);
        payload.addProperty("isTyping", isTyping);
        broadcastToRoom(roomId, payload.toString(), null);
    }

    private void handleSeen(JsonObject obj) {
        int messageId = obj.get("messageId").getAsInt();
        int roomId = obj.has("roomId") ? obj.get("roomId").getAsInt() : 0;
        chatService.markAsSeen(messageId, userId);
        JsonObject payload = new JsonObject();
        payload.addProperty("type", "SEEN");
        payload.addProperty("messageId", messageId);
        payload.addProperty("roomId", roomId);
        payload.addProperty("userId", userId);
        broadcastToRoom(roomId, payload.toString(), null);
    }

    private void handleReaction(JsonObject obj) {
        int messageId = obj.get("messageId").getAsInt();
        String emoji = obj.has("emoji") ? obj.get("emoji").getAsString() : "👍";
        var reactionOpt = chatService.addReaction(messageId, userId, emoji);
        if (reactionOpt.isPresent()) {
            var r = reactionOpt.get();
            int roomId = r.getMessage().getRoom().getId();
            JsonObject payload = new JsonObject();
            payload.addProperty("type", "REACTION");
            payload.addProperty("messageId", messageId);
            payload.addProperty("userId", userId);
            payload.addProperty("username", username);
            payload.addProperty("emoji", emoji);
            payload.addProperty("roomId", roomId);
            broadcastToRoom(roomId, payload.toString(), null);
        }
    }

    private void handleDeleteMessage(JsonObject obj) {
        int messageId = obj.get("messageId").getAsInt();
        var roomIdOpt = chatService.deleteMessage(messageId, userId);
        if (roomIdOpt.isPresent()) {
            int roomId = roomIdOpt.get();
            JsonObject payload = new JsonObject();
            payload.addProperty("type", "DELETE_MESSAGE");
            payload.addProperty("messageId", messageId);
            payload.addProperty("roomId", roomId);
            payload.addProperty("userId", userId);
            broadcastToRoom(roomId, payload.toString(), null);
        }
    }

    /**
     * WebRTC call signaling — relay offer/answer/candidate between users.
     */
    private void handleCallSignal(JsonObject obj) {
        int targetUserId = obj.get("targetUserId").getAsInt();
        String signalType = obj.has("signalType") ? obj.get("signalType").getAsString() : "";

        JsonObject payload = new JsonObject();
        payload.addProperty("type", "CALL_SIGNAL");
        payload.addProperty("signalType", signalType);
        payload.addProperty("fromUserId", userId);
        payload.addProperty("fromUsername", username);

        // Forward specific fields depending on signal type
        if (obj.has("sdp")) {
            payload.addProperty("sdp", obj.get("sdp").getAsString());
        }
        if (obj.has("candidate")) {
            payload.add("candidate", obj.get("candidate"));
        }
        if (obj.has("roomId")) {
            payload.addProperty("roomId", obj.get("roomId").getAsInt());
        }

        // Send directly to the target user
        Session targetSession = USER_SESSIONS.get(targetUserId);
        if (targetSession != null && targetSession.isOpen()) {
            try {
                targetSession.getBasicRemote().sendText(payload.toString());
            } catch (IOException ignored) {
            }
        }
    }

    private void handleJoinRoom(JsonObject obj) {
        // Client signals they're viewing this room
    }

    private void broadcastToRoom(int roomId, String message, Integer excludeUserId) {
        List<User> members = roomService.getMembers(roomId);
        Set<Integer> memberIds = members.stream().map(User::getId).collect(Collectors.toSet());
        for (Map.Entry<Integer, Session> e : USER_SESSIONS.entrySet()) {
            if (!memberIds.contains(e.getKey())) continue;
            if (excludeUserId != null && e.getKey().equals(excludeUserId)) continue;
            try {
                if (e.getValue().isOpen()) {
                    e.getValue().getBasicRemote().sendText(message);
                }
            } catch (IOException ignored) {
            }
        }
    }

    private void broadcastUserStatus(int uid, String uname, boolean online, String lastSeen) {
        JsonObject payload = new JsonObject();
        payload.addProperty("type", "USER_STATUS");
        payload.addProperty("userId", uid);
        payload.addProperty("username", uname);
        payload.addProperty("isOnline", online);
        if (lastSeen != null) {
            payload.addProperty("lastSeen", lastSeen);
        }
        for (Session s : USER_SESSIONS.values()) {
            try {
                if (s.isOpen()) {
                    s.getBasicRemote().sendText(payload.toString());
                }
            } catch (IOException ignored) {
            }
        }
    }
}
