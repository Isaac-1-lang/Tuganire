package com.tuganire.service;

import com.tuganire.dao.UserDAO;
import com.tuganire.model.User;
import com.tuganire.util.JwtUtil;
import com.tuganire.util.PasswordUtil;

import java.util.Optional;

/**
 * Authentication business logic: register, login (returns JWT), logout.
 */
public class AuthService {

    private final UserDAO userDAO = new UserDAO();

    /**
     * Register a new user. Returns the created user or empty if username/email exists.
     */
    public Optional<User> register(String username, String email, String plainPassword) {
        if (username == null || username.isBlank() || email == null || email.isBlank() || plainPassword == null || plainPassword.isBlank()) {
            return Optional.empty();
        }
        username = sanitize(username.trim());
        email = sanitize(email.trim().toLowerCase());
        if (username.length() < 3 || username.length() > 50) {
            return Optional.empty();
        }
        if (userDAO.findByUsername(username).isPresent()) {
            return Optional.empty();
        }
        if (userDAO.findByEmail(email).isPresent()) {
            return Optional.empty();
        }
        String hash = PasswordUtil.hash(plainPassword);
        User user = new User(username, email, hash);
        userDAO.save(user);
        return Optional.of(user);
    }

    /**
     * Login: verify credentials, return JWT string or empty if invalid.
     */
    public Optional<String> login(String usernameOrEmail, String plainPassword) {
        if (usernameOrEmail == null || usernameOrEmail.isBlank() || plainPassword == null || plainPassword.isBlank()) {
            return Optional.empty();
        }
        String input = usernameOrEmail.trim();
        Optional<User> userOpt = input.contains("@")
                ? userDAO.findByEmail(input)
                : userDAO.findByUsername(input);
        if (userOpt.isEmpty()) {
            return Optional.empty();
        }
        User user = userOpt.get();
        if (!PasswordUtil.verify(plainPassword, user.getPasswordHash())) {
            return Optional.empty();
        }
        String token = JwtUtil.createToken(user.getId(), user.getUsername());
        return Optional.of(token);
    }

    /**
     * Logout - caller clears the cookie. This method can update lastSeen if needed.
     */
    public void logout(int userId) {
        userDAO.setOnline(userId, false);
    }

    /**
     * Basic XSS sanitization: remove angle brackets and dangerous chars.
     */
    private String sanitize(String s) {
        if (s == null) return "";
        return s.replaceAll("<", "&lt;")
                .replaceAll(">", "&gt;")
                .replaceAll("\"", "&quot;")
                .trim();
    }
}
