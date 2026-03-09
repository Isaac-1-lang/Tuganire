package com.tuganire.filter;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.tuganire.util.JwtUtil;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Arrays;

/**
 * JWT validation on every request. Protects all routes except login, register, assets, ws.
 */
@WebFilter(urlPatterns = {"/*"})
public class AuthFilter extends HttpFilter {

    private static final String TOKEN_COOKIE = "token";
    private static final String[] PUBLIC_PATHS = {"/auth/login", "/auth/register", "/auth/logout", "/login", "/register"};
    private static final String[] PUBLIC_PREFIXES = {"/assets/", "/css/", "/js/", "/ws/", "/views/login", "/views/register", "/views/error"};

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        String path = getPathWithinContext(req);
        System.out.println("AuthFilter: path = " + path + "| "+ isPublicPath(path));

        if (isPublicPath(path)) {
            chain.doFilter(req, res);
            return;
        }

        String token = getTokenFromCookie(req);
        DecodedJWT jwt = JwtUtil.verify(token);
        if (jwt == null) {
            if (isAjax(req)) {
                res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            } else {
                res.sendRedirect(req.getContextPath() + "/views/login.jsp?redirect=" + java.net.URLEncoder.encode(path, "UTF-8"));
            }
            return;
        }

        req.setAttribute("userId", JwtUtil.getUserId(jwt));
        req.setAttribute("username", JwtUtil.getUsername(jwt));
        chain.doFilter(req, res);
    }

    /** Extracts path within context. Handles getRequestURI() vs getContextPath() edge cases. */
    private String getPathWithinContext(HttpServletRequest req) {
        String uri = req.getRequestURI();
        String ctx = req.getContextPath();
        if (ctx != null && !ctx.isEmpty() && uri != null && uri.startsWith(ctx)) {
            String path = uri.substring(ctx.length());
            return path.isEmpty() ? "/" : path;
        }
        return (uri != null && !uri.isEmpty()) ? uri : "/";
    }

    private boolean isPublicPath(String path) {
        if (path == null) return false;
        String p = path.startsWith("/") ? path : "/" + path;
        for (String pub : PUBLIC_PATHS) {
            if (p.equals(pub) || p.startsWith(pub + "?")) return true;
        }
        for (String prefix : PUBLIC_PREFIXES) {
            if (p.startsWith(prefix)) return true;
        }
        String lower = p.toLowerCase();
        if (lower.endsWith(".css") || lower.endsWith(".js") || lower.endsWith(".ico")
                || lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".svg") || lower.endsWith(".woff2")) {
            return true;
        }
        return false;
    }

    private String getTokenFromCookie(HttpServletRequest req) {
        Cookie[] cookies = req.getCookies();
        if (cookies == null) return null;
        return Arrays.stream(cookies)
                .filter(c -> TOKEN_COOKIE.equals(c.getName()))
                .map(Cookie::getValue)
                .findFirst()
                .orElse(null);
    }

    private boolean isAjax(HttpServletRequest req) {
        String requestedWith = req.getHeader("X-Requested-With");
        return "XMLHttpRequest".equals(requestedWith);
    }
}
