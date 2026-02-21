package com.tuganire.service;

import com.tuganire.dao.RoomDAO;
import com.tuganire.dao.UserDAO;
import com.tuganire.model.Room;
import com.tuganire.model.RoomType;
import com.tuganire.model.User;

import java.util.List;
import java.util.Optional;

/**
 * Room business logic: create room, join, leave, list rooms, get members.
 */
public class RoomService {

    private final RoomDAO roomDAO = new RoomDAO();
    private final UserDAO userDAO = new UserDAO();

    /**
     * Create a GROUP room. Creator is automatically a member.
     */
    public Optional<Room> createGroupRoom(String name, int creatorId) {
        if (name == null || name.isBlank()) {
            return Optional.empty();
        }
        name = sanitize(name.trim());
        if (name.length() > 100) {
            return Optional.empty();
        }
        Optional<User> creatorOpt = userDAO.findById(creatorId);
        if (creatorOpt.isEmpty()) {
            return Optional.empty();
        }
        Room room = new Room(name, RoomType.GROUP, creatorOpt.get());
        roomDAO.save(room);
        roomDAO.addMember(room, creatorOpt.get());
        return Optional.of(room);
    }

    /**
     * Create or get existing DM between two users.
     */
    public Optional<Room> createOrGetDm(int userId1, int userId2) {
        if (userId1 == userId2) {
            return Optional.empty();
        }
        Optional<User> u1 = userDAO.findById(userId1);
        Optional<User> u2 = userDAO.findById(userId2);
        if (u1.isEmpty() || u2.isEmpty()) {
            return Optional.empty();
        }
        Optional<Room> existing = roomDAO.findDmBetweenUsers(userId1, userId2);
        if (existing.isPresent()) {
            return existing;
        }
        String dmName = u1.get().getUsername() + " & " + u2.get().getUsername();
        Room room = new Room(dmName, RoomType.DM, u1.get());
        roomDAO.save(room);
        roomDAO.addMember(room, u1.get());
        roomDAO.addMember(room, u2.get());
        return Optional.of(room);
    }

    /**
     * Join a GROUP room (not applicable for DM).
     */
    public boolean joinRoom(int roomId, int userId) {
        Optional<Room> roomOpt = roomDAO.findById(roomId);
        Optional<User> userOpt = userDAO.findById(userId);
        if (roomOpt.isEmpty() || userOpt.isEmpty()) {
            return false;
        }
        Room room = roomOpt.get();
        if (room.getType() != RoomType.GROUP) {
            return false; // DMs are created with both members
        }
        if (roomDAO.isMember(roomId, userId)) {
            return true; // already a member
        }
        roomDAO.addMember(room, userOpt.get());
        return true;
    }

    /**
     * Leave a room. Cannot leave if you're the only member (or handle that case).
     */
    public boolean leaveRoom(int roomId, int userId) {
        if (!roomDAO.isMember(roomId, userId)) {
            return false;
        }
        roomDAO.removeMember(roomId, userId);
        return true;
    }

    /**
     * List rooms the user is a member of.
     */
    public List<Room> listRoomsForUser(int userId) {
        return roomDAO.findRoomsByUserId(userId);
    }

    /**
     * Get room by id. User must be a member.
     */
    public Optional<Room> getRoom(int roomId, int userId) {
        Optional<Room> roomOpt = roomDAO.findById(roomId);
        if (roomOpt.isEmpty()) {
            return Optional.empty();
        }
        if (!roomDAO.isMember(roomId, userId)) {
            return Optional.empty();
        }
        return roomOpt;
    }

    public List<User> getMembers(int roomId) {
        return roomDAO.getMembers(roomId);
    }

    public boolean isMember(int roomId, int userId) {
        return roomDAO.isMember(roomId, userId);
    }

    private String sanitize(String s) {
        if (s == null) return "";
        return s.replaceAll("<", "&lt;")
                .replaceAll(">", "&gt;")
                .replaceAll("\"", "&quot;")
                .trim();
    }
}
