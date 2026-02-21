package com.tuganire.servlet;

import com.tuganire.model.Room;
import com.tuganire.service.ChatService;
import com.tuganire.service.RoomService;
import com.tuganire.service.UserService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * Serves the main chat page. GET /chat
 */
@WebServlet(urlPatterns = {"/chat"})
public class ChatPageServlet extends HttpServlet {

    private final RoomService roomService = new RoomService();
    private final ChatService chatService = new ChatService();
    private final UserService userService = new UserService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        Integer userId = (Integer) req.getAttribute("userId");
        if (userId == null) {
            res.sendRedirect(req.getContextPath() + "/views/login.jsp?redirect=/chat");
            return;
        }

        List<Room> rooms = roomService.listRoomsForUser(userId);
        req.setAttribute("rooms", rooms);
        req.setAttribute("currentUser", userService.findById(userId).orElse(null));

        String roomIdParam = req.getParameter("roomId");
        if (roomIdParam != null && !roomIdParam.isBlank()) {
            try {
                int roomId = Integer.parseInt(roomIdParam);
                Optional<Room> roomOpt = roomService.getRoom(roomId, userId);
                if (roomOpt.isPresent()) {
                    req.setAttribute("currentRoom", roomOpt.get());
                    var messages = chatService.loadHistory(roomId, userId, 50, 0);
                    req.setAttribute("messages", messages);
                }
            } catch (NumberFormatException ignored) {
            }
        }

        req.getRequestDispatcher("/views/chat.jsp").forward(req, res);
    }
}
