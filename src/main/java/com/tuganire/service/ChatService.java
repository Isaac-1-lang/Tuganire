package com.tuganire.service;

import com.tuganire.dao.MessageDAO;
import com.tuganire.dao.RoomDAO;
import com.tuganire.dao.UserDAO;
import com.tuganire.model.Message;
import com.tuganire.model.Reaction;
import com.tuganire.model.Room;
import com.tuganire.model.User;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * Chat business logic: send message, load history, mark as seen, add reaction.
 */
public class ChatService {

    private final MessageDAO messageDAO = new MessageDAO();
    private final RoomDAO roomDAO = new RoomDAO();
    private final UserDAO userDAO = new UserDAO();

    /**
     * Send a message. User must be a member of the room.
     */
    public Optional<Message> sendMessage(int roomId, int senderId, String content, Integer replyToId) {
        if (content == null || content.isBlank()) {
            return Optional.empty();
        }
        content = sanitize(content.trim());
        if (content.length() > 10000) {
            return Optional.empty();
        }
        if (!roomDAO.isMember(roomId, senderId)) {
            return Optional.empty();
        }
        Optional<Room> roomOpt = roomDAO.findById(roomId);
        Optional<User> senderOpt = userDAO.findById(senderId);
        if (roomOpt.isEmpty() || senderOpt.isEmpty()) {
            return Optional.empty();
        }
        Message msg = new Message(roomOpt.get(), senderOpt.get(), content);
        if (replyToId != null) {
            messageDAO.findById(replyToId).ifPresent(msg::setReplyTo);
        }
        Message saved = messageDAO.save(msg);
        return Optional.of(saved);
    }

    /**
     * Load paginated message history for a room. User must be a member.
     */
    public List<Message> loadHistory(int roomId, int userId, int limit, int offset) {
        if (!roomDAO.isMember(roomId, userId)) {
            return List.of();
        }
        return messageDAO.findByRoomId(roomId, limit, offset);
    }

    /**
     * Mark message as read for a user.
     */
    public void markAsSeen(int messageId, int userId) {
        messageDAO.markAsRead(messageId, userId);
        Optional<Message> msgOpt = messageDAO.findById(messageId);
        msgOpt.ifPresent(msg -> roomDAO.updateLastReadAt(msg.getRoom().getId(), userId, Instant.now()));
    }

    /**
     * Add or update emoji reaction on a message.
     */
    public Optional<Reaction> addReaction(int messageId, int userId, String emoji) {
        if (emoji == null || emoji.isBlank() || emoji.length() > 10) {
            return Optional.empty();
        }
        Optional<Message> msgOpt = messageDAO.findById(messageId);
        if (msgOpt.isEmpty()) {
            return Optional.empty();
        }
        Message msg = msgOpt.get();
        if (!roomDAO.isMember(msg.getRoom().getId(), userId)) {
            return Optional.empty();
        }
        Reaction r = messageDAO.addOrUpdateReaction(messageId, userId, emoji.trim());
        return Optional.ofNullable(r);
    }

    public Optional<Message> getMessage(int id) {
        return messageDAO.findById(id);
    }

    public Optional<Message> getLastMessage(int roomId) {
        return messageDAO.getLastMessage(roomId);
    }

    public long countUnread(int roomId, int userId) {
        Instant lastRead = roomDAO.getLastReadAt(roomId, userId);
        return messageDAO.countUnread(roomId, userId, lastRead);
    }

    private String sanitize(String s) {
        if (s == null) return "";
        return s.replaceAll("<", "&lt;")
                .replaceAll(">", "&gt;")
                .replaceAll("\"", "&quot;")
                .replaceAll("'", "&#39;")
                .trim();
    }
}
