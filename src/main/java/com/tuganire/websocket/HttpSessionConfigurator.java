package com.tuganire.websocket;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.tuganire.util.JwtUtil;

import jakarta.websocket.HandshakeResponse;
import jakarta.websocket.server.HandshakeRequest;
import jakarta.websocket.server.ServerEndpointConfig;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * Extracts JWT from cookie during WebSocket handshake and attaches userId/username to userProperties.
 * Rejects the upgrade if token is missing or invalid.
 */
public class HttpSessionConfigurator extends ServerEndpointConfig.Configurator {

    private static final String TOKEN_COOKIE = "token";
    public static final String USER_ID = "userId";
    public static final String USERNAME = "username";

    @Override
    public void modifyHandshake(ServerEndpointConfig config, HandshakeRequest request, HandshakeResponse response) {
        Map<String, List<String>> headers = request.getHeaders();
        List<String> cookieHeaders = headers.get("Cookie");
        String token = null;
        if (cookieHeaders != null) {
            for (String header : cookieHeaders) {
                String[] parts = header.split(";");
                for (String part : parts) {
                    part = part.trim();
                    if (part.startsWith(TOKEN_COOKIE + "=")) {
                        token = part.substring((TOKEN_COOKIE + "=").length()).trim();
                        break;
                    }
                }
                if (token != null) break;
            }
        }
        DecodedJWT jwt = JwtUtil.verify(token);
        if (jwt != null) {
            config.getUserProperties().put(USER_ID, JwtUtil.getUserId(jwt));
            config.getUserProperties().put(USERNAME, JwtUtil.getUsername(jwt));
        }
        // If jwt is null, we don't put userId - ChatEndpoint will reject in @OnOpen
    }
}
