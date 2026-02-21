package com.tuganire.util;

import java.security.SecureRandom;
import java.util.Base64;

/**
 * CSRF token generation for POST forms.
 */
public final class CsrfUtil {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int TOKEN_BYTES = 32;

    private CsrfUtil() {
    }

    public static String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public static boolean validate(String expected, String actual) {
        return expected != null && expected.equals(actual);
    }
}
