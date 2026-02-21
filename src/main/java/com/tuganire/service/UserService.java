package com.tuganire.service;

import com.tuganire.dao.UserDAO;
import com.tuganire.model.User;

import java.util.List;
import java.util.Optional;

/**
 * User business logic: search users, update profile/avatar, get online status.
 */
public class UserService {

    private final UserDAO userDAO = new UserDAO();

    public Optional<User> findById(int id) {
        return userDAO.findById(id);
    }

    public Optional<User> findByUsername(String username) {
        return userDAO.findByUsername(username);
    }

    /**
     * Search users by username or email (for starting DMs).
     */
    public List<User> search(String query, int limit) {
        return userDAO.searchByUsernameOrEmail(query, limit);
    }

    /**
     * Update user avatar URL.
     */
    public boolean updateAvatar(int userId, String avatarUrl) {
        Optional<User> userOpt = userDAO.findById(userId);
        if (userOpt.isEmpty()) {
            return false;
        }
        User user = userOpt.get();
        user.setAvatar(sanitize(avatarUrl));
        userDAO.update(user);
        return true;
    }

    /**
     * Set user online/offline status.
     */
    public void setOnline(int userId, boolean online) {
        userDAO.setOnline(userId, online);
    }

    private String sanitize(String s) {
        if (s == null || s.isBlank()) return null;
        return s.replaceAll("<", "")
                .replaceAll(">", "")
                .replaceAll("\"", "")
                .trim();
    }
}
