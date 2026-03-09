<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib uri="jakarta.tags.core" prefix="c" %>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Tuganire — Inbox</title>
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
            <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
                rel="stylesheet">
            <style>
                :root {
                    /* Clean Light Theme based on reference */
                    --bg-primary: #ffffff;
                    --bg-secondary: #f8fafc;
                    --bg-tertiary: #f1f5f9;
                    --bg-hover: #f1f5f9;
                    --text-primary: #0f172a;
                    --text-secondary: #64748b;
                    --text-muted: #94a3b8;
                    --accent: #0f1422;
                    --accent-hover: #1e293b;
                    --accent-light: #eef2ff;
                    --border: #e2e8f0;
                    --border-light: #f1f5f9;
                    --error: #ef4444;
                    --success: #22c55e;

                    --sidebar-width: 320px;
                }

                * {
                    box-sizing: border-box;
                    margin: 0;
                    padding: 0;
                }

                body {
                    font-family: 'Inter', system-ui, -apple-system, sans-serif;
                    background: var(--bg-primary);
                    color: var(--text-primary);
                    line-height: 1.5;
                    height: 100vh;
                    overflow: hidden;
                    -webkit-font-smoothing: antialiased;
                }

                /* ── Layout ── */
                .app-layout {
                    display: grid;
                    grid-template-columns: var(--sidebar-width) 1fr;
                    height: 100vh;
                    background: var(--bg-primary);
                }

                /* ── Action Bar (Far Left vertical sliver in reference, combined into sidebar here for simplicity) ── */

                /* ── Sidebar (Left) ── */
                .sidebar {
                    background: var(--bg-secondary);
                    border-right: 1px solid var(--border);
                    display: flex;
                    flex-direction: column;
                    overflow: hidden;
                }

                .sidebar-header {
                    padding: 1.25rem 1rem 0.75rem;
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                }

                .sidebar-brand {
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                    font-weight: 700;
                    font-size: 1.1rem;
                    color: var(--text-primary);
                    text-decoration: none;
                }

                .brand-logo {
                    height: 24px;
                    width: auto;
                    object-fit: contain;
                }

                .sidebar-actions {
                    display: flex;
                    gap: 0.5rem;
                }

                .icon-btn {
                    background: none;
                    border: none;
                    color: var(--text-secondary);
                    cursor: pointer;
                    padding: 0.4rem;
                    border-radius: 6px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    transition: background 0.2s, color 0.2s;
                    text-decoration: none;
                }

                .icon-btn:hover {
                    background: var(--bg-tertiary);
                    color: var(--text-primary);
                }

                .icon-btn svg {
                    width: 18px;
                    height: 18px;
                }

                /* Search Box */
                .search-container {
                    padding: 0 1rem 1rem;
                    position: relative;
                }

                .search-box {
                    position: relative;
                    display: flex;
                    align-items: center;
                }

                .search-box svg {
                    position: absolute;
                    left: 0.75rem;
                    width: 16px;
                    height: 16px;
                    color: var(--text-muted);
                }

                .search-box input {
                    width: 100%;
                    padding: 0.5rem 0.75rem 0.5rem 2.25rem;
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    background: var(--bg-primary);
                    color: var(--text-primary);
                    font-size: 0.9rem;
                    font-family: inherit;
                    transition: all 0.2s;
                }

                .search-box input:focus {
                    outline: none;
                    border-color: var(--accent);
                    box-shadow: 0 0 0 3px var(--accent-light);
                }

                .search-box input::placeholder {
                    color: var(--text-muted);
                }

                /* Search Results Dropdown */
                .search-results {
                    position: absolute;
                    top: 100%;
                    left: 1rem;
                    right: 1rem;
                    background: var(--bg-primary);
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
                    max-height: 250px;
                    overflow-y: auto;
                    z-index: 50;
                }

                .search-results:empty {
                    display: none;
                    border: none;
                }

                .search-results .user-item {
                    padding: 0.75rem 1rem;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    border-bottom: 1px solid var(--border-light);
                    font-size: 0.9rem;
                    font-weight: 500;
                }

                .search-results .user-item:last-child {
                    border-bottom: none;
                }

                .search-results .user-item:hover {
                    background: var(--bg-hover);
                }

                /* Lists Area */
                .sidebar-content {
                    flex: 1;
                    overflow-y: auto;
                    padding: 0 0.5rem 1rem;
                }

                .section-title {
                    padding: 1.25rem 0.5rem 0.5rem;
                    font-size: 0.75rem;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                    color: var(--text-secondary);
                }

                /* List Items (Rooms & People) */
                .list-item {
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    padding: 0.6rem 0.5rem;
                    border-radius: 8px;
                    cursor: pointer;
                    text-decoration: none;
                    color: var(--text-primary);
                    transition: background 0.2s;
                    margin-bottom: 0.1rem;
                }

                .list-item:hover {
                    background: var(--bg-hover);
                }

                .list-item.active {
                    background: var(--accent-light);
                }

                .avatar {
                    width: 36px;
                    height: 36px;
                    border-radius: 50%;
                    background: var(--bg-tertiary);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 600;
                    color: var(--accent);
                    font-size: 0.9rem;
                    flex-shrink: 0;
                }

                .list-item.active .avatar {
                    background: #fff;
                }

                .item-details {
                    flex: 1;
                    min-width: 0;
                    display: flex;
                    flex-direction: column;
                    gap: 0.1rem;
                }

                .item-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }

                .item-name {
                    font-size: 0.9rem;
                    font-weight: 500;
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }

                .list-item.active .item-name {
                    color: var(--accent);
                    font-weight: 600;
                }

                .item-time {
                    font-size: 0.7rem;
                    color: var(--text-muted);
                }

                .badge {
                    display: inline-flex;
                    align-items: center;
                    justify-content: center;
                    min-width: 1.25rem;
                    height: 1.25rem;
                    padding: 0 0.4rem;
                    border-radius: 1rem;
                    background: var(--accent);
                    color: white;
                    font-size: 0.7rem;
                    font-weight: 600;
                }

                .badge:empty {
                    display: none;
                }

                .empty-hint {
                    padding: 1rem 0.5rem;
                    color: var(--text-muted);
                    font-size: 0.85rem;
                    text-align: center;
                }

                /* ── Main Chat Area (Right) ── */
                .chat-main {
                    display: flex;
                    flex-direction: column;
                    background: var(--bg-primary);
                    position: relative;
                }

                /* Empty State */
                .empty-state {
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    background: var(--bg-secondary);
                }

                .empty-icon-wrap {
                    width: 120px;
                    height: 120px;
                    background: #ffffff;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
                    margin-bottom: 1.5rem;
                    position: relative;
                }

                .empty-icon-wrap::before {
                    content: '';
                    position: absolute;
                    top: -20px;
                    left: -20px;
                    right: -20px;
                    bottom: -20px;
                    border-radius: 50%;
                    background: rgba(255, 255, 255, 0.4);
                    z-index: 0;
                }

                .empty-icon-wrap svg {
                    width: 48px;
                    height: 48px;
                    color: var(--text-muted);
                    position: relative;
                    z-index: 1;
                }

                .empty-state h3 {
                    font-size: 1.25rem;
                    font-weight: 600;
                    color: var(--text-primary);
                    margin-bottom: 0.5rem;
                }

                .empty-state p {
                    color: var(--text-secondary);
                    font-size: 0.95rem;
                }

                /* Active Chat */
                .chat-header {
                    padding: 1.25rem 2rem;
                    border-bottom: 1px solid var(--border);
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    background: var(--bg-primary);
                    z-index: 10;
                }

                .chat-header-info {
                    display: flex;
                    align-items: center;
                    gap: 1rem;
                }

                .chat-header-info h2 {
                    font-size: 1.1rem;
                    font-weight: 600;
                    color: var(--text-primary);
                }

                .chat-header-info p {
                    font-size: 0.85rem;
                    color: var(--text-secondary);
                }

                .chat-actions {
                    display: flex;
                    gap: 0.5rem;
                }

                .messages-container {
                    flex: 1;
                    overflow-y: auto;
                    padding: 2rem;
                    display: flex;
                    flex-direction: column;
                    background: var(--bg-secondary);
                }

                .messages {
                    display: flex;
                    flex-direction: column;
                    gap: 1rem;
                    max-width: 800px;
                    margin: 0 auto;
                    width: 100%;
                }

                /* Message Bubbles */
                .message-row {
                    display: flex;
                    gap: 1rem;
                    max-width: 100%;
                }

                .message-row.own {
                    flex-direction: row-reverse;
                }

                .message-avatar {
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    background: var(--bg-tertiary);
                    color: var(--text-secondary);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 0.8rem;
                    font-weight: 600;
                    flex-shrink: 0;
                    margin-top: auto;
                }

                .message-row.own .message-avatar {
                    display: none;
                }

                .message-content-wrap {
                    max-width: 70%;
                    display: flex;
                    flex-direction: column;
                }

                .message-row.own .message-content-wrap {
                    align-items: flex-end;
                }

                .message-sender-name {
                    font-size: 0.75rem;
                    color: var(--text-secondary);
                    margin-bottom: 0.25rem;
                    margin-left: 0.25rem;
                }

                .message-row.own .message-sender-name {
                    display: none;
                }

                .message-bubble {
                    padding: 0.75rem 1rem;
                    background: #ffffff;
                    color: var(--text-primary);
                    border: 1px solid var(--border);
                    border-radius: 12px 12px 12px 2px;
                    font-size: 0.95rem;
                    line-height: 1.5;
                    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
                    position: relative;
                }

                .message-row.own .message-bubble {
                    background: var(--accent);
                    color: #ffffff;
                    border: none;
                    border-radius: 12px 12px 2px 12px;
                    box-shadow: 0 2px 4px rgba(99, 102, 241, 0.15);
                }

                .message-time {
                    font-size: 0.7rem;
                    color: var(--text-muted);
                    margin-top: 0.25rem;
                    margin-left: 0.25rem;
                }

                .message-row.own .message-time {
                    margin-left: 0;
                    margin-right: 0.25rem;
                }

                /* Input Area */
                .input-area {
                    padding: 1.25rem 2rem;
                    background: var(--bg-primary);
                    border-top: 1px solid var(--border);
                    z-index: 10;
                }

                .input-form {
                    display: flex;
                    gap: 0.75rem;
                    max-width: 800px;
                    margin: 0 auto;
                    width: 100%;
                }

                .input-form input {
                    flex: 1;
                    padding: 0.875rem 1rem;
                    border: 1px solid var(--border);
                    border-radius: 24px;
                    background: var(--bg-secondary);
                    color: var(--text-primary);
                    font-size: 0.95rem;
                    font-family: inherit;
                    transition: all 0.2s;
                }

                .input-form input:focus {
                    outline: none;
                    border-color: var(--accent);
                    background: #ffffff;
                    box-shadow: 0 0 0 3px var(--accent-light);
                }

                .input-form input::placeholder {
                    color: var(--text-muted);
                }

                .btn-send {
                    padding: 0 1.5rem;
                    background: var(--accent);
                    color: #ffffff;
                    border: none;
                    border-radius: 24px;
                    font-weight: 600;
                    font-size: 0.95rem;
                    font-family: inherit;
                    cursor: pointer;
                    transition: background 0.2s, transform 0.1s;
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                }

                .btn-send:hover {
                    background: var(--accent-hover);
                }

                .btn-send:active {
                    transform: scale(0.97);
                }

                .typing-indicator {
                    padding: 0 2rem 0.5rem;
                    font-size: 0.8rem;
                    color: var(--text-secondary);
                    min-height: 1.5rem;
                    background: var(--bg-secondary);
                }

                /* Utilities */
                .btn-primary-sm {
                    padding: 0.4rem 0.75rem;
                    background: var(--accent);
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-size: 0.8rem;
                    font-weight: 500;
                    cursor: pointer;
                    text-decoration: none;
                }

                .btn-primary-sm:hover {
                    background: var(--accent-hover);
                }
            </style>
        </head>

        <body>
            <div class="app-layout">
                <!-- ── Sidebar ── -->
                <aside class="sidebar">
                    <header class="sidebar-header">
                        <a href="${pageContext.request.contextPath}/" class="sidebar-brand">
                            <img src="${pageContext.request.contextPath}/static/logo.png" alt="Logo" class="brand-logo">
                            Tuganire
                        </a>
                        <div class="sidebar-actions">
                            <button class="icon-btn" title="Create Group" id="new-room-btn">
                                <svg xmlns="http://www.w3.org/-g2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M12 4v16m8-8H4" />
                                </svg>
                            </button>
                            <a href="${pageContext.request.contextPath}/auth/logout" class="icon-btn" title="Sign out">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                                </svg>
                            </a>
                        </div>
                    </header>

                    <div class="search-container">
                        <div class="search-box">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                            <input type="text" id="user-search" placeholder="Search people..." autocomplete="off">
                        </div>
                        <div id="search-results" class="search-results"></div>
                    </div>

                    <div class="sidebar-content">
                        <div class="section-title">Rooms & Messages</div>
                        <div id="room-list" class="room-list">
                            <c:forEach var="room" items="${rooms}">
                                <a href="${pageContext.request.contextPath}/chat?roomId=${room.id}"
                                    class="list-item ${currentRoom != null && currentRoom.id == room.id ? 'active' : ''}"
                                    data-room-id="${room.id}">
                                    <div class="avatar">
                                        <!-- First letter of room name as avatar placeholder -->
                                        ${room.name.substring(0, 1).toUpperCase()}
                                    </div>
                                    <div class="item-details">
                                        <div class="item-header">
                                            <span class="item-name">${room.name}</span>
                                        </div>
                                    </div>
                                    <span class="badge" data-room-id="${room.id}"></span>
                                </a>
                            </c:forEach>
                            <c:if test="${empty rooms}">
                                <p class="empty-hint">Search people above to start chatting.</p>
                            </c:if>
                        </div>

                        <div class="section-title">All People</div>
                        <div id="all-users-list" class="people-list">
                            <!-- Loaded via JS -->
                            <p class="empty-hint">Loading...</p>
                        </div>
                    </div>
                </aside>

                <!-- ── Main Chat Area ── -->
                <main class="chat-main">
                    <c:choose>
                        <c:when test="${currentRoom != null}">
                            <!-- Active Chat View -->
                            <header class="chat-header">
                                <div class="chat-header-info">
                                    <div class="avatar">
                                        ${currentRoom.name.substring(0, 1).toUpperCase()}
                                    </div>
                                    <div>
                                        <h2>${currentRoom.name}</h2>
                                    </div>
                                </div>
                                <div class="chat-actions">
                                    <button class="icon-btn" title="Room Info">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                            stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg>
                                    </button>
                                </div>
                            </header>

                            <div class="messages-container" id="messages-container">
                                <div class="messages" id="messages">
                                    <c:forEach var="msg" items="${messages}">
                                        <div class="message-row ${msg.sender.id == currentUser.id ? 'own' : ''}"
                                            data-message-id="${msg.id}">
                                            <div class="message-avatar">
                                                ${msg.sender.username.substring(0, 1).toUpperCase()}
                                            </div>
                                            <div class="message-content-wrap">
                                                <span class="message-sender-name">${msg.sender.username}</span>
                                                <div class="message-bubble">
                                                    <c:out value="${msg.content}" />
                                                </div>
                                                <span class="message-time">${msg.createdAt}</span>
                                            </div>
                                        </div>
                                    </c:forEach>
                                </div>
                            </div>

                            <div class="typing-indicator" id="typing-indicator"></div>

                            <div class="input-area">
                                <form class="input-form" id="message-form">
                                    <input type="hidden" id="current-room-id" value="${currentRoom.id}">
                                    <input type="text" id="message-input" placeholder="Message ${currentRoom.name}..."
                                        autocomplete="off">
                                    <button type="submit" class="btn-send">
                                        Send
                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none"
                                            viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                                d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                                        </svg>
                                    </button>
                                </form>
                            </div>
                        </c:when>

                        <c:otherwise>
                            <!-- Empty State View -->
                            <div class="empty-state">
                                <div class="empty-icon-wrap">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                        stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                                            d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                                    </svg>
                                </div>
                                <h3>It's empty here</h3>
                                <p>Choose a conversation to view details or start a new chat.</p>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </main>
            </div>

            <script>
                window.TUGANIRE = {
                    contextPath: "${pageContext.request.contextPath}",
                    currentUserId: Number("${currentUser != null ? currentUser.id : 0}"),
                    currentUsername: "${currentUser != null ? currentUser.username : ''}",
                    currentRoomId: Number("${currentRoom != null ? currentRoom.id : 0}")
                };
            </script>
            <script src="${pageContext.request.contextPath}/js/chat.js"></script>
        </body>

        </html>