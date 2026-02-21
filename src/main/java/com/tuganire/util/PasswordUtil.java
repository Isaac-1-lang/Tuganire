package com.tuganire.util;

import org.mindrot.jbcrypt.BCrypt;

/**
 * jBCrypt wrapper for password hashing and verification.
 */
public final class PasswordUtil {

    private static final int ROUNDS = 12;

    private PasswordUtil() {
    }

    /**
     * Hash a plain-text password. Never store plain passwords.
     */
    public static String hash(String plainPassword) {
        if (plainPassword == null || plainPassword.isBlank()) {
            throw new IllegalArgumentException("Password cannot be empty");
        }
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(ROUNDS));
    }

    /**
     * Verify plain password against stored hash.
     */
    public static boolean verify(String plainPassword, String hash) {
        if (plainPassword == null || hash == null) {
            return false;
        }
        try {
            return BCrypt.checkpw(plainPassword, hash);
        } catch (Exception e) {
            return false;
        }
    }
}
