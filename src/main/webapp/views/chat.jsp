<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tuganire — Chat</title>
    <link rel="stylesheet" href="<c:url value='/css/style.css'/>">
</head>
<body class="chat-layout">
    <aside class="sidebar">
        <header class="sidebar-header">
            <h2>Tuganire</h2>
            <div class="sidebar-actions">
                <button id="theme-toggle" class="icon-btn" title="Toggle theme">🌙</button>
                <a href="${pageContext.request.contextPath}/auth/logout" class="icon-btn" title="Logout">↪</a>
            </div>
        </header>
        <div class="search-box">
            <input type="text" id="user-search" placeholder="Search users to start DM..." autocomplete="off">
            <div id="search-results" class="search-results"></div>
        </div>
        <div class="room-list">
            <c:forEach var="room" items="${rooms}">
                <a href="${pageContext.request.contextPath}/chat?roomId=${room.id}" class="room-item ${currentRoom != null && currentRoom.id == room.id ? 'active' : ''}" data-room-id="${room.id}">
                    <span class="room-name">${room.name}</span>
                    <span class="room-badge" data-room-id="${room.id}"></span>
                </a>
            </c:forEach>
            <c:if test="${empty rooms}">
                <p class="empty-hint">Search users above to start a conversation</p>
            </c:if>
        </div>
        <button id="new-room-btn" class="btn btn-secondary">+ New Group Room</button>
    </aside>
    <main class="chat-main">
        <c:choose>
            <c:when test="${currentRoom != null}">
                <header class="chat-header">
                    <h3>${currentRoom.name}</h3>
                </header>
                <div class="messages-container" id="messages-container">
                    <div class="messages" id="messages">
                        <c:forEach var="msg" items="${messages}">
                            <div class="message ${msg.sender.id == currentUser.id ? 'own' : ''}" data-message-id="${msg.id}">
                                <span class="msg-sender">${msg.sender.username}</span>
                                <p class="msg-content"><c:out value="${msg.content}"/></p>
                                <span class="msg-time">${msg.createdAt}</span>
                            </div>
                        </c:forEach>
                    </div>
                </div>
                <div class="typing-indicator" id="typing-indicator"></div>
                <form class="input-bar" id="message-form">
                    <input type="hidden" id="current-room-id" value="${currentRoom.id}">
                    <input type="text" id="message-input" placeholder="Type a message..." autocomplete="off">
                    <button type="submit" class="btn btn-primary">Send</button>
                </form>
            </c:when>
            <c:otherwise>
                <div class="empty-chat">
                    <p>Select a conversation or search users to start a new one.</p>
                </div>
            </c:otherwise>
        </c:choose>
    </main>

    <script>
        window.TUGANIRE = {
            contextPath: "${pageContext.request.contextPath}",
            currentUserId: ${currentUser != null ? currentUser.id : 0},
            currentUsername: "${currentUser != null ? currentUser.username : ''}",
            currentRoomId: ${currentRoom != null ? currentRoom.id : 0}
        };
    </script>
    <script src="<c:url value='/js/chat.js'/>"></script>
</body>
</html>
