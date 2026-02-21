package com.tuganire.util;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;

import java.time.Instant;
import java.util.Date;

/**
 * JWT sign and verify helpers. Uses HS256. Token stored in httpOnly cookie.
 */
public final class JwtUtil {

    private static final String CLAIM_USER_ID = "userId";
    private static final String CLAIM_USERNAME = "username";

    private JwtUtil() {
    }

    /**
     * Generate a signed JWT containing userId and username.
     */
    public static String createToken(int userId, String username) {
        int expiryHours = Integer.parseInt(EnvConfig.get("JWT_EXPIRY_HOURS", "24"));
        Instant expiresAt = Instant.now().plusSeconds(expiryHours * 3600L);

        return JWT.create()
                .withClaim(CLAIM_USER_ID, userId)
                .withClaim(CLAIM_USERNAME, username)
                .withExpiresAt(Date.from(expiresAt))
                .sign(Algorithm.HMAC256(EnvConfig.getRequired("JWT_SECRET")));
    }

    /**
     * Verify and decode token. Returns null if invalid or expired.
     */
    public static DecodedJWT verify(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        try {
            return JWT.require(Algorithm.HMAC256(EnvConfig.getRequired("JWT_SECRET")))
                    .build()
                    .verify(token);
        } catch (JWTVerificationException e) {
            return null;
        }
    }

    public static int getUserId(DecodedJWT jwt) {
        return jwt.getClaim(CLAIM_USER_ID).asInt();
    }

    public static String getUsername(DecodedJWT jwt) {
        return jwt.getClaim(CLAIM_USERNAME).asString();
    }
}
