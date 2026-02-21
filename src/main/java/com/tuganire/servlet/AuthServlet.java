package com.tuganire.servlet;

import com.tuganire.service.AuthService;
import com.tuganire.util.CsrfUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Handles /auth/login, /auth/register, /auth/logout.
 */
@WebServlet(urlPatterns = {"/auth/login", "/auth/register", "/auth/logout"})
public class AuthServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        String path = req.getServletPath();
        if ("/auth/login".equals(path)) {
            handleLogin(req, res);
        } else if ("/auth/register".equals(path)) {
            handleRegister(req, res);
        } else {
            res.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if ("/auth/logout".equals(req.getServletPath())) {
            handleLogout(req, res);
        } else {
            res.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    private void handleLogin(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if (!CsrfUtil.validate((String) req.getSession().getAttribute("csrfToken"), req.getParameter("csrf"))) {
            res.sendRedirect(req.getContextPath() + "/views/login.jsp?error=invalid_csrf");
            return;
        }
        String usernameOrEmail = req.getParameter("username");
        String password = req.getParameter("password");
        var tokenOpt = authService.login(usernameOrEmail, password);
        if (tokenOpt.isEmpty()) {
            res.sendRedirect(req.getContextPath() + "/views/login.jsp?error=invalid_credentials");
            return;
        }
        String token = tokenOpt.get();
        Cookie cookie = new Cookie("token", token);
        cookie.setHttpOnly(true);
        cookie.setSecure(req.isSecure());
        cookie.setPath("/");
        cookie.setMaxAge(24 * 60 * 60); // 24 hours
        cookie.setAttribute("SameSite", "Strict");
        res.addCookie(cookie);

        String redirect = req.getParameter("redirect");
        if (redirect != null && !redirect.isBlank() && redirect.startsWith("/")) {
            res.sendRedirect(req.getContextPath() + redirect);
        } else {
            res.sendRedirect(req.getContextPath() + "/chat");
        }
    }

    private void handleRegister(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if (!CsrfUtil.validate((String) req.getSession().getAttribute("csrfToken"), req.getParameter("csrf"))) {
            res.sendRedirect(req.getContextPath() + "/views/register.jsp?error=invalid_csrf");
            return;
        }
        String username = req.getParameter("username");
        String email = req.getParameter("email");
        String password = req.getParameter("password");
        var userOpt = authService.register(username, email, password);
        if (userOpt.isEmpty()) {
            res.sendRedirect(req.getContextPath() + "/views/register.jsp?error=register_failed");
            return;
        }
        // Auto-login after register
        var tokenOpt = authService.login(username, password);
        tokenOpt.ifPresent(token -> {
            Cookie cookie = new Cookie("token", token);
            cookie.setHttpOnly(true);
            cookie.setSecure(req.isSecure());
            cookie.setPath("/");
            cookie.setMaxAge(24 * 60 * 60);
            cookie.setAttribute("SameSite", "Strict");
            res.addCookie(cookie);
        });
        res.sendRedirect(req.getContextPath() + "/chat");
    }

    private void handleLogout(HttpServletRequest req, HttpServletResponse res) throws IOException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId != null) {
            authService.logout(userId);
        }
        Cookie cookie = new Cookie("token", "");
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        res.addCookie(cookie);
        res.sendRedirect(req.getContextPath() + "/views/login.jsp");
    }
}
