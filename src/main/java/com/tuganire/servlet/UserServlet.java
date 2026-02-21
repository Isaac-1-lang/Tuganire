package com.tuganire.servlet;

import com.google.gson.Gson;
import com.tuganire.model.User;
import com.tuganire.service.UserService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * GET /users/search — Search users (for starting DM)
 * POST /users/avatar — Update avatar
 */
@WebServlet(urlPatterns = {"/users/search", "/users/avatar"})
public class UserServlet extends HttpServlet {

    private final UserService userService = new UserService();
    private final Gson gson = new Gson();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        if ("/users/search".equals(req.getServletPath())) {
            Integer userId = (Integer) req.getAttribute("userId");
            if (userId == null) {
                res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
            String q = req.getParameter("q");
            List<User> users = userService.search(q != null ? q : "", 20);
            List<Map<String, Object>> payload = new ArrayList<>();
            for (User u : users) {
                if (u.getId().equals(userId)) continue; // Exclude self
                Map<String, Object> m = new HashMap<>();
                m.put("id", u.getId());
                m.put("username", u.getUsername());
                m.put("avatar", u.getAvatar());
                m.put("isOnline", u.isOnline());
                payload.add(m);
            }
            res.setContentType("application/json");
            res.setCharacterEncoding("UTF-8");
            res.getWriter().write(gson.toJson(payload));
        } else {
            res.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        if ("/users/avatar".equals(req.getServletPath())) {
            Integer userId = (Integer) req.getAttribute("userId");
            if (userId == null) {
                res.sendError(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
            String avatarUrl = req.getParameter("avatarUrl");
            boolean ok = userService.updateAvatar(userId, avatarUrl);
            if (!ok) {
                res.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            res.sendRedirect(req.getContextPath() + "/chat");
        } else {
            res.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }
}
