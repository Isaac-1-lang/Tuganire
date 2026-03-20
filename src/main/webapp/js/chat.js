/**
 * Tuganire Premium Real-Time Chat Client v2
 * Features: Real-time WebSocket messaging, emoji picker, file uploads,
 * profile management, group creation with members, audio calls (WebRTC),
 * message deletion, context menus, notification sounds, search,
 * read receipts, typing indicators, theme toggle, mobile drawer
 */
(function () {
    'use strict';

    const ctx = window.TUGANIRE || {};
    const baseUrl = ctx.contextPath || '';
    const wsBase = (location.protocol === 'https:' ? 'wss:' : 'ws:') + '//' + location.host + baseUrl;
    let ws = null;
    let typingTimeout = null;
    let unreadCount = 0;
    let reconnectAttempts = 0;
    let reconnectTimer = null;
    let isUserScrolledUp = false;
    let isMuted = localStorage.getItem('tuganire-muted') === 'true';
    const onlineUsers = new Map(); // userId -> { username, lastSeen }

    // Audio call state
    let localStream = null;
    let peerConnection = null;
    let callTarget = null;
    let callRoomId = null;
    let ringtoneInterval = null;

    // DOM refs
    let messagesContainer, messagesEl, messageForm, messageInput, typingIndicator, currentRoomIdEl;

    /* ══════════════════════════════════════
       INITIALIZATION
       ══════════════════════════════════════ */
    function init() {
        connectWs();

        // Always initialize these references
        messagesContainer = document.getElementById('messages-container');
        messagesEl = document.getElementById('messages');
        messageForm = document.getElementById('message-form');
        messageInput = document.getElementById('message-input');
        typingIndicator = document.getElementById('typing-indicator');
        currentRoomIdEl = document.getElementById('current-room-id');

        if (messageForm && messageInput) {
            messageForm.addEventListener('submit', onSendMessage);
            messageInput.addEventListener('input', debounce(onTyping, 400));
        }

        if (ctx.currentRoomId) {
            if (messageInput) messageInput.focus();
            initScrollWatcher();
            scrollToBottom(false);
            formatMessageTimes();
        }

        initRoomSwitching();
        initUserSearch();
        initThemeToggle();
        initMobileDrawer();
        initProfileModal();
        initEmojiPicker();
        initFileUpload();
        initContextMenu();
        initRoomInfoPanel();
        initAudioCallUI();
        initMuteToggle();
        initMessageSearch();
        updateDocumentTitle();
    }

    /* ══════════════════════════════════════
       WEBSOCKET CONNECTION
       ══════════════════════════════════════ */
    function connectWs() {
        showConnectionStatus('reconnecting');
        const url = wsBase + '/ws/chat';
        ws = new WebSocket(url);

        ws.onopen = () => {
            reconnectAttempts = 0;
            showConnectionStatus('online');
            if (ctx.currentRoomId) {
                sendWs({ type: 'JOIN_ROOM', roomId: ctx.currentRoomId });
            }
        };

        ws.onmessage = (ev) => {
            try {
                const data = JSON.parse(ev.data);
                handleWsMessage(data);
            } catch (e) { /* ignore malformed */ }
        };

        ws.onclose = () => {
            showConnectionStatus('offline');
            scheduleReconnect();
        };

        ws.onerror = () => {
            showConnectionStatus('offline');
        };
    }

    function scheduleReconnect() {
        reconnectAttempts++;
        const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 30000);
        clearTimeout(reconnectTimer);
        reconnectTimer = setTimeout(connectWs, delay);
    }

    function sendWs(obj) {
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(obj));
        }
    }

    /* ══════════════════════════════════════
       CONNECTION STATUS BAR
       ══════════════════════════════════════ */
    function showConnectionStatus(status) {
        const bar = document.getElementById('connection-bar');
        const spinner = document.getElementById('conn-spinner');
        const text = document.getElementById('conn-text');
        if (!bar) return;

        bar.className = 'connection-bar';

        if (status === 'online') {
            bar.classList.add('online', 'visible');
            spinner.style.display = 'none';
            text.textContent = 'Connected';
            setTimeout(() => bar.classList.remove('visible'), 2000);
        } else if (status === 'reconnecting') {
            bar.classList.add('reconnecting', 'visible');
            spinner.style.display = 'block';
            text.textContent = 'Reconnecting...';
        } else if (status === 'offline') {
            bar.classList.add('offline', 'visible');
            spinner.style.display = 'none';
            text.textContent = 'Connection lost — Retrying...';
        }
    }

    /* ══════════════════════════════════════
       ASYNC ROOM SWITCHING
       ══════════════════════════════════════ */
    function initRoomSwitching() {
        const roomLinks = document.querySelectorAll('#room-list .list-item');
        roomLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const roomId = this.getAttribute('data-room-id');
                if (roomId && Number(roomId) !== Number(ctx.currentRoomId)) {
                    loadRoomAsync(roomId, this);
                }
            });
        });
    }

    async function loadRoomAsync(roomId, clickedEl) {
        try {
            // Update UI Active State in sidebar
            document.querySelectorAll('#room-list .list-item').forEach(el => el.classList.remove('active'));
            if (clickedEl) clickedEl.classList.add('active');

            // Fetch history via AJAX
            const response = await fetch(`${ctx.contextPath}/messages?roomId=${roomId}&page=1`);
            if (!response.ok) throw new Error('Failed to load messages');
            
            const data = await response.json();
            
            // Switch current state
            ctx.currentRoomId = roomId;
            if (currentRoomIdEl) currentRoomIdEl.value = roomId;

            // Update Header Information
            const roomNameWrapper = clickedEl ? clickedEl.querySelector('.item-name') : null;
            const roomName = roomNameWrapper ? roomNameWrapper.textContent : 'Group Chat';
            const roomLetter = roomName.substring(0, 1).toUpperCase();
            
            document.getElementById('current-room-name').textContent = roomName;
            const avatarEl = document.getElementById('current-room-avatar');
            if (avatarEl) {
                avatarEl.innerHTML = `${roomLetter}<span class="online-dot" id="header-online-dot"></span>`;
            }

            // Render Messages
            if (messagesEl) {
                messagesEl.innerHTML = ''; // clear existing
                // data.messages logic (similar to page load, but from JSON)
                if (data && data.length > 0) {
                    // Reverse because messages usually come latest first from API, 
                    // or maybe API already sorts chronological.
                    // Assuming API returns chronological for a page or latest depending on implementation
                    // Let's check chronological order via appending
                    data.forEach(msg => appendMessage(msg));
                }
            }

            // Hide Empty State, Show Chat State
            document.getElementById('empty-state').style.display = 'none';
            document.getElementById('active-chat-state').style.display = 'flex';

            // Push state to browser history
            window.history.pushState({roomId: roomId}, '', `${ctx.contextPath}/chat?roomId=${roomId}`);

            // Join Room in WebSocket to receive messages
            sendWs({ type: 'JOIN_ROOM', roomId: ctx.currentRoomId });

            initScrollWatcher();
            scrollToBottom(false);
            if (messageInput) messageInput.focus();

            // Clear unread badge
            const badge = document.querySelector(`.badge[data-room-id="${roomId}"]`);
            if (badge) {
                badge.style.display = 'none';
                badge.textContent = '';
            }
        } catch (error) {
            console.error('Error loading room:', error);
            showToast('System', 'Failed to change conversation.');
        }
    }

    /* ══════════════════════════════════════
       WEBSOCKET MESSAGE HANDLER
       ══════════════════════════════════════ */
    function handleWsMessage(data) {
        switch (data.type) {
            case 'MESSAGE':
                if (Number(data.roomId) === Number(ctx.currentRoomId)) {
                    appendMessage(data);
                    if (!isUserScrolledUp) scrollToBottom(true);
                    sendWs({ type: 'SEEN', messageId: data.id, roomId: data.roomId });
                } else {
                    showToast(data.senderUsername, (data.content || '').substring(0, 60));
                    incrementUnread(data.roomId);
                }
                updateRoomPreview(data.roomId, data.content, data.createdAt);
                if (data.senderId !== ctx.currentUserId) {
                    playNotificationSound();
                }
                break;

            case 'TYPING':
                if (Number(data.roomId) === Number(ctx.currentRoomId) && data.userId !== ctx.currentUserId) {
                    showTypingIndicator(data.isTyping, data.username);
                }
                break;

            case 'SEEN':
                if (Number(data.roomId) === Number(ctx.currentRoomId)) {
                    const msgEl = document.querySelector(`[data-message-id="${data.messageId}"] .msg-status`);
                    if (msgEl) {
                        msgEl.className = 'msg-status seen';
                        msgEl.innerHTML = '<svg viewBox="0 0 16 16" fill="none"><path d="M1 8l3 3 5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 8l3 3 5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
                    }
                }
                break;

            case 'REACTION':
                if (Number(data.roomId) === Number(ctx.currentRoomId)) {
                    const msgEl = document.querySelector(`[data-message-id="${data.messageId}"]`);
                    if (msgEl) {
                        let r = msgEl.querySelector('.reactions');
                        if (!r) {
                            r = document.createElement('div');
                            r.className = 'reactions';
                            const bubble = msgEl.querySelector('.message-bubble');
                            if (bubble) bubble.parentNode.insertBefore(r, bubble.nextSibling);
                        }
                        const badge = document.createElement('span');
                        badge.className = 'reaction-badge';
                        badge.textContent = data.emoji || '👍';
                        badge.title = data.username;
                        r.appendChild(badge);
                    }
                }
                break;

            case 'DELETE_MESSAGE':
                if (Number(data.roomId) === Number(ctx.currentRoomId)) {
                    const el = document.querySelector(`[data-message-id="${data.messageId}"]`);
                    if (el) {
                        el.style.opacity = '0';
                        el.style.transform = 'translateX(20px)';
                        el.style.transition = 'all 0.3s ease';
                        setTimeout(() => el.remove(), 300);
                    }
                }
                break;

            case 'USER_STATUS':
                updateOnlineStatus(data.userId, data.username, data.isOnline, data.lastSeen);
                break;

            case 'CALL_SIGNAL':
                handleCallSignal(data);
                break;
        }
    }

    /* ══════════════════════════════════════
       MESSAGE RENDERING
       ══════════════════════════════════════ */
    function appendMessage(data) {
        if (!messagesEl) return;
        const isOwn = Number(data.senderId) === Number(ctx.currentUserId);
        const div = document.createElement('div');
        div.className = 'message-row' + (isOwn ? ' own' : '');
        div.dataset.messageId = data.id;
        div.dataset.senderId = data.senderId;

        const avatarLetter = data.senderUsername ? data.senderUsername.substring(0, 1).toUpperCase() : '?';
        const timeStr = data.createdAt
            ? new Date(data.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            : new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        const statusHtml = isOwn ? `
            <span class="msg-status delivered">
                <svg viewBox="0 0 16 16" fill="none"><path d="M2 8l3 3 7-7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </span>` : '';

        // Determine avatar HTML
        let avatarHtml;
        if (data.senderAvatar) {
            avatarHtml = `<img src="${escapeHtml(data.senderAvatar)}" alt="${escapeHtml(avatarLetter)}" class="message-avatar-img">`;
        } else {
            avatarHtml = `<div class="message-avatar">${escapeHtml(avatarLetter)}</div>`;
        }

        // Determine content HTML (text vs file/image)
        let contentHtml = '';
        if (data.mediaUrl && data.fileType === 'image') {
            contentHtml = `<div class="message-bubble message-image-bubble"><img src="${escapeHtml(data.mediaUrl)}" alt="Image" class="chat-image" onclick="window.open('${escapeHtml(data.mediaUrl)}','_blank')"></div>`;
            if (data.content) {
                contentHtml += `<div class="message-bubble">${escapeHtml(data.content)}</div>`;
            }
        } else if (data.mediaUrl && data.fileType === 'file') {
            contentHtml = `<div class="message-bubble file-attachment">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" width="18" height="18">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"/>
                </svg>
                <a href="${escapeHtml(data.mediaUrl)}" target="_blank" class="file-link">${escapeHtml(data.fileName || 'Download')}</a>
            </div>`;
            if (data.content) {
                contentHtml += `<div class="message-bubble">${escapeHtml(data.content)}</div>`;
            }
        } else {
            contentHtml = `<div class="message-bubble">${formatMessageContent(data.content || '')}</div>`;
        }

        div.innerHTML = `
            ${avatarHtml}
            <div class="message-content-wrap">
                <span class="message-sender-name">${escapeHtml(data.senderUsername || '')}</span>
                ${contentHtml}
                <div class="message-footer">
                    <span class="message-time">${timeStr}</span>
                    ${statusHtml}
                </div>
            </div>
        `;
        messagesEl.appendChild(div);
    }

    function formatMessageContent(text) {
        let safe = escapeHtml(text);
        // Convert URLs to links
        safe = safe.replace(/(https?:\/\/[^\s<]+)/g, '<a href="$1" target="_blank" class="msg-link">$1</a>');
        // Convert newlines
        safe = safe.replace(/\n/g, '<br>');
        return safe;
    }

    function formatMessageTimes() {
        document.querySelectorAll('.message-time').forEach(el => {
            const raw = el.textContent.trim();
            if (!raw) return;
            try {
                const d = new Date(raw);
                if (!isNaN(d.getTime())) {
                    el.textContent = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                }
            } catch (e) { /* keep raw */ }
        });
    }

    /* ══════════════════════════════════════
       ONLINE STATUS
       ══════════════════════════════════════ */
    function updateOnlineStatus(userId, username, isOnline, lastSeen) {
        if (isOnline) {
            onlineUsers.set(userId, { username, lastSeen: null });
        } else {
            onlineUsers.set(userId, { username, lastSeen: lastSeen || new Date().toISOString() });
        }

        // Update people list dots
        document.querySelectorAll(`.user-item[data-user-id="${userId}"]`).forEach(el => {
            const dot = el.querySelector('.online-dot');
            if (dot) dot.classList.toggle('active', isOnline);
            const statusText = el.querySelector('.user-online-text');
            if (statusText) {
                if (isOnline) {
                    statusText.textContent = 'Online';
                    statusText.style.color = 'var(--success)';
                } else {
                    statusText.textContent = lastSeen ? 'Last seen ' + relativeTime(lastSeen) : 'Offline';
                    statusText.style.color = 'var(--text-muted)';
                }
            }
        });

        // Update chat header
        const headerDot = document.getElementById('header-online-dot');
        const headerStatusDot = document.getElementById('header-status-dot');
        const headerStatusText = document.getElementById('header-status-text');
        if (headerDot && headerStatusDot && headerStatusText) {
            if (isOnline) {
                headerDot.classList.add('active');
                headerStatusDot.classList.add('online');
                headerStatusText.textContent = 'Online';
            } else {
                headerDot.classList.remove('active');
                headerStatusDot.classList.remove('online');
                headerStatusText.textContent = lastSeen ? 'Last seen ' + relativeTime(lastSeen) : 'Offline';
            }
        }
    }

    function relativeTime(isoStr) {
        try {
            const d = new Date(isoStr);
            const diff = (Date.now() - d.getTime()) / 1000;
            if (diff < 60) return 'just now';
            if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
            if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
            return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
        } catch (e) { return ''; }
    }

    /* ══════════════════════════════════════
       ROOM PREVIEW UPDATES
       ══════════════════════════════════════ */
    function updateRoomPreview(roomId, content, createdAt) {
        const preview = document.querySelector(`.item-preview[data-room-id="${roomId}"]`);
        const timeEl = document.querySelector(`.item-time[data-room-id="${roomId}"]`);
        if (preview) {
            preview.textContent = (content || '').substring(0, 40);
        }
        if (timeEl && createdAt) {
            try {
                const d = new Date(createdAt);
                timeEl.textContent = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            } catch (e) { /* ignore */ }
        }
    }

    /* ══════════════════════════════════════
       TYPING INDICATOR
       ══════════════════════════════════════ */
    function showTypingIndicator(isTyping, username) {
        if (!typingIndicator) return;
        if (isTyping) {
            typingIndicator.innerHTML = `
                <div class="typing-dots"><span></span><span></span><span></span></div>
                <span>${escapeHtml(username)} is typing...</span>
            `;
        } else {
            typingIndicator.innerHTML = '';
        }
    }

    /* ══════════════════════════════════════
       SCROLL MANAGEMENT
       ══════════════════════════════════════ */
    function initScrollWatcher() {
        if (!messagesContainer) return;
        const scrollBtn = document.getElementById('scroll-bottom-btn');

        messagesContainer.addEventListener('scroll', () => {
            const { scrollTop, scrollHeight, clientHeight } = messagesContainer;
            isUserScrolledUp = scrollHeight - scrollTop - clientHeight > 100;
            if (scrollBtn) {
                scrollBtn.classList.toggle('visible', isUserScrolledUp);
            }
        });

        if (scrollBtn) {
            scrollBtn.addEventListener('click', () => scrollToBottom(true));
        }
    }

    function scrollToBottom(smooth) {
        if (!messagesContainer) return;
        if (smooth) {
            messagesContainer.scrollTo({ top: messagesContainer.scrollHeight, behavior: 'smooth' });
        } else {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    }

    /* ══════════════════════════════════════
       TOAST NOTIFICATIONS
       ══════════════════════════════════════ */
    function showToast(title, message) {
        const container = document.getElementById('toast-container');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.innerHTML = `
            <div class="toast-icon">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                </svg>
            </div>
            <div class="toast-text">
                <strong>${escapeHtml(title)}</strong><br>
                <span style="color:var(--text-secondary);font-size:0.8rem;">${escapeHtml(message)}</span>
            </div>
        `;
        toast.onclick = () => {
            toast.classList.add('removing');
            setTimeout(() => toast.remove(), 300);
        };
        container.appendChild(toast);
        setTimeout(() => {
            toast.classList.add('removing');
            setTimeout(() => toast.remove(), 300);
        }, 4500);
    }

    /* ══════════════════════════════════════
       NOTIFICATION SOUND
       ══════════════════════════════════════ */
    let audioCtx = null;
    function playNotificationSound() {
        if (isMuted) return;
        try {
            if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(880, audioCtx.currentTime);
            osc.frequency.setValueAtTime(660, audioCtx.currentTime + 0.1);
            gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.3);
            osc.start(audioCtx.currentTime);
            osc.stop(audioCtx.currentTime + 0.3);
        } catch (e) { /* audio not supported */ }
    }

    function initMuteToggle() {
        const btn = document.getElementById('mute-toggle');
        if (!btn) return;
        updateMuteIcon(btn);
        btn.addEventListener('click', () => {
            isMuted = !isMuted;
            localStorage.setItem('tuganire-muted', isMuted);
            updateMuteIcon(btn);
        });
    }

    function updateMuteIcon(btn) {
        if (isMuted) {
            btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2"/></svg>';
            btn.title = 'Unmute';
        } else {
            btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"/></svg>';
            btn.title = 'Mute';
        }
    }

    /* ══════════════════════════════════════
       UNREAD BADGES
       ══════════════════════════════════════ */
    function incrementUnread(roomId) {
        unreadCount++;
        const badge = document.querySelector(`.badge[data-room-id="${roomId}"]`);
        if (badge) {
            const cur = parseInt(badge.textContent || '0', 10);
            badge.textContent = (cur + 1).toString();
        }
        updateDocumentTitle();
    }

    function updateDocumentTitle() {
        document.title = unreadCount > 0 ? `(${unreadCount}) Tuganire` : 'Tuganire — Inbox';
    }

    /* ══════════════════════════════════════
       SEND MESSAGE
       ══════════════════════════════════════ */
    function onSendMessage(e) {
        e.preventDefault();
        const roomId = currentRoomIdEl?.value || ctx.currentRoomId;
        const content = (messageInput?.value || '').trim();
        if (!roomId || !content) return;

        sendWs({ type: 'MESSAGE', roomId: parseInt(roomId), content });
        messageInput.value = '';
        messageInput.focus();
        sendWs({ type: 'TYPING', roomId: parseInt(roomId), isTyping: false });
    }

    function onTyping() {
        const roomId = currentRoomIdEl?.value || ctx.currentRoomId;
        if (!roomId) return;
        sendWs({ type: 'TYPING', roomId: parseInt(roomId), isTyping: true });
        clearTimeout(typingTimeout);
        typingTimeout = setTimeout(() => {
            sendWs({ type: 'TYPING', roomId: parseInt(roomId), isTyping: false });
        }, 1500);
    }

    /* ══════════════════════════════════════
       USER SEARCH
       ══════════════════════════════════════ */
    function initUserSearch() {
        const input = document.getElementById('user-search');
        const results = document.getElementById('search-results');
        const allUsersList = document.getElementById('all-users-list');
        if (!input || !results) return;

        let searchTimeout;

        const bindClicks = (container) => {
            if (!container) return;
            container.querySelectorAll('.user-item[data-user-id]').forEach(el => {
                el.addEventListener('click', () => {
                    startDm(el.dataset.userId);
                    results.innerHTML = '';
                    results.style.display = 'none';
                    input.value = '';
                });
            });
        };

        const renderUsers = (container, users, emptyText) => {
            if (!container) return;
            if (users.length === 0) {
                container.innerHTML = `<div class="empty-hint">${emptyText}</div>`;
                return;
            }
            container.innerHTML = users.map(u => {
                const avatarHtml = u.avatar
                    ? `<img src="${escapeHtml(u.avatar)}" alt="" class="avatar-img">`
                    : escapeHtml(u.username.substring(0, 1).toUpperCase());
                return `
                <div class="user-item" data-user-id="${u.id}" data-username="${escapeHtml(u.username)}"
                     style="display:flex;align-items:center;gap:0.75rem;padding:0.6rem 0.75rem;cursor:pointer;border-radius:8px;transition:background 0.15s;">
                    <div class="avatar" style="width:34px;height:34px;font-size:0.8rem;">
                        ${avatarHtml}
                        <span class="online-dot ${u.isOnline ? 'active' : ''}"></span>
                    </div>
                    <div style="flex:1;min-width:0;">
                        <div style="font-size:0.875rem;font-weight:500;">${escapeHtml(u.username)}</div>
                        <div class="user-online-text" style="font-size:0.72rem;color:${u.isOnline ? 'var(--success)' : 'var(--text-muted)'};">
                            ${u.isOnline ? '● Online' : '○ Offline'}
                        </div>
                    </div>
                </div>`;
            }).join('');
            bindClicks(container);
        };

        const runSearch = (q) => {
            const url = baseUrl + '/users/search?q=' + encodeURIComponent(q);
            fetch(url, {
                credentials: 'same-origin',
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            })
                .then(r => {
                    const ct = r.headers.get('content-type') || '';
                    if (!r.ok || !ct.includes('application/json')) {
                        throw new Error('Search failed');
                    }
                    return r.json();
                })
                .then(users => {
                    renderUsers(results, users, 'No users found');
                    results.style.display = 'block';
                    renderUsers(allUsersList, users, 'No users available');
                })
                .catch(() => {
                    results.innerHTML = '<div class="empty-hint">Unable to load users</div>';
                    results.style.display = 'block';
                    if (allUsersList) {
                        allUsersList.innerHTML = '<div class="empty-hint">Unable to load users</div>';
                    }
                });
        };

        input.addEventListener('input', () => {
            clearTimeout(searchTimeout);
            const q = input.value.trim();
            searchTimeout = setTimeout(() => runSearch(q), 300);
        });

        input.addEventListener('focus', () => {
            if (!input.value.trim()) runSearch('');
        });

        document.addEventListener('click', (e) => {
            if (!results.contains(e.target) && !input.contains(e.target)) {
                results.style.display = 'none';
            }
        });

        runSearch('');
    }

    function startDm(userId) {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = baseUrl + '/rooms';
        const typeInput = document.createElement('input');
        typeInput.type = 'hidden'; typeInput.name = 'type'; typeInput.value = 'DM';
        const targetInput = document.createElement('input');
        targetInput.type = 'hidden'; targetInput.name = 'targetUserId'; targetInput.value = userId;
        form.appendChild(typeInput);
        form.appendChild(targetInput);
        document.body.appendChild(form);
        form.submit();
    }

    /* ══════════════════════════════════════
       THEME TOGGLE
       ══════════════════════════════════════ */
    function initThemeToggle() {
        const btn = document.getElementById('theme-toggle');
        const icon = document.getElementById('theme-icon');
        if (!btn) return;

        const saved = localStorage.getItem('tuganire-theme') || 'light';
        document.documentElement.dataset.theme = saved;
        updateThemeIcon(saved, icon);

        btn.addEventListener('click', () => {
            const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
            document.documentElement.dataset.theme = next;
            localStorage.setItem('tuganire-theme', next);
            updateThemeIcon(next, icon);
        });
    }

    function updateThemeIcon(theme, icon) {
        if (!icon) return;
        if (theme === 'dark') {
            icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>';
        } else {
            icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>';
        }
    }

    /* ══════════════════════════════════════
       CREATE ROOM MODAL (Enhanced with members)
       ══════════════════════════════════════ */
    function initNewRoomModal() {
        const btn = document.getElementById('new-room-btn');
        const modal = document.getElementById('room-modal');
        const nameInput = document.getElementById('room-name-input');
        const descInput = document.getElementById('room-desc-input');
        const cancelBtn = document.getElementById('modal-cancel');
        const createBtn = document.getElementById('modal-create');
        const memberSearch = document.getElementById('modal-member-search');
        const memberResults = document.getElementById('modal-member-results');
        const selectedMembers = document.getElementById('selected-members');
        if (!btn || !modal) return;

        const selectedIds = new Set();

        btn.addEventListener('click', () => {
            modal.classList.add('active');
            if (nameInput) setTimeout(() => nameInput.focus(), 100);
        });

        cancelBtn?.addEventListener('click', () => {
            modal.classList.remove('active');
            selectedIds.clear();
            if (selectedMembers) selectedMembers.innerHTML = '';
        });

        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.classList.remove('active');
                selectedIds.clear();
                if (selectedMembers) selectedMembers.innerHTML = '';
            }
        });

        // Member search in modal
        if (memberSearch && memberResults) {
            let searchTimeout;
            memberSearch.addEventListener('input', () => {
                clearTimeout(searchTimeout);
                const q = memberSearch.value.trim();
                searchTimeout = setTimeout(() => {
                    fetch(baseUrl + '/users/search?q=' + encodeURIComponent(q), {
                        credentials: 'same-origin',
                        headers: { 'X-Requested-With': 'XMLHttpRequest' }
                    })
                        .then(r => r.json())
                        .then(users => {
                            memberResults.innerHTML = users.filter(u => !selectedIds.has(u.id)).map(u => `
                            <div class="member-result" data-user-id="${u.id}" data-username="${escapeHtml(u.username)}">
                                <div class="avatar" style="width:28px;height:28px;font-size:0.7rem;">${escapeHtml(u.username.substring(0, 1).toUpperCase())}</div>
                                <span>${escapeHtml(u.username)}</span>
                            </div>
                        `).join('');
                            memberResults.querySelectorAll('.member-result').forEach(el => {
                                el.addEventListener('click', () => {
                                    const uid = parseInt(el.dataset.userId);
                                    const uname = el.dataset.username;
                                    selectedIds.add(uid);
                                    addMemberPill(selectedMembers, uid, uname, selectedIds);
                                    memberSearch.value = '';
                                    memberResults.innerHTML = '';
                                });
                            });
                        })
                        .catch(() => { });
                }, 300);
            });
        }

        const doCreate = () => {
            const name = nameInput?.value?.trim();
            if (!name) return;
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = baseUrl + '/rooms';
            const input = document.createElement('input');
            input.type = 'hidden'; input.name = 'name'; input.value = name;
            form.appendChild(input);

            if (descInput?.value?.trim()) {
                const descField = document.createElement('input');
                descField.type = 'hidden'; descField.name = 'description'; descField.value = descInput.value.trim();
                form.appendChild(descField);
            }

            selectedIds.forEach(id => {
                const mi = document.createElement('input');
                mi.type = 'hidden'; mi.name = 'memberIds'; mi.value = id;
                form.appendChild(mi);
            });

            document.body.appendChild(form);
            form.submit();
        };

        createBtn?.addEventListener('click', doCreate);
        nameInput?.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') { e.preventDefault(); doCreate(); }
            if (e.key === 'Escape') modal.classList.remove('active');
        });
    }

    function addMemberPill(container, userId, username, selectedIds) {
        if (!container) return;
        const pill = document.createElement('span');
        pill.className = 'member-pill';
        pill.innerHTML = `${escapeHtml(username)} <button type="button" class="pill-remove">&times;</button>`;
        pill.querySelector('.pill-remove').addEventListener('click', () => {
            selectedIds.delete(userId);
            pill.remove();
        });
        container.appendChild(pill);
    }

    /* ══════════════════════════════════════
       MOBILE DRAWER
       ══════════════════════════════════════ */
    function initMobileDrawer() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebar-overlay');
        const menuBtn = document.getElementById('mobile-menu-btn') || document.getElementById('mobile-menu-btn-empty');
        if (!sidebar || !overlay) return;

        const openDrawer = () => {
            sidebar.classList.add('open');
            overlay.classList.add('visible');
        };
        const closeDrawer = () => {
            sidebar.classList.remove('open');
            overlay.classList.remove('visible');
        };

        menuBtn?.addEventListener('click', openDrawer);
        overlay.addEventListener('click', closeDrawer);
    }

    /* ══════════════════════════════════════
       PROFILE MODAL
       ══════════════════════════════════════ */
    function initProfileModal() {
        const btn = document.getElementById('profile-settings-btn');
        const modal = document.getElementById('profile-modal');
        const closeBtn = document.getElementById('profile-modal-close');
        const form = document.getElementById('profile-form');
        if (!btn || !modal) return;

        btn.addEventListener('click', () => {
            modal.classList.add('active');
            // Load current profile
            fetch(baseUrl + '/profile', {
                credentials: 'same-origin',
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            })
                .then(r => r.json())
                .then(data => {
                    const bioInput = document.getElementById('profile-bio-input');
                    const avatarPreview = document.getElementById('avatar-preview');
                    if (bioInput) bioInput.value = data.bio || '';
                    if (avatarPreview && data.avatar) {
                        avatarPreview.innerHTML = `<img src="${escapeHtml(data.avatar)}" alt="Avatar" class="avatar-preview-img">`;
                    }
                })
                .catch(() => { });
        });

        closeBtn?.addEventListener('click', () => modal.classList.remove('active'));
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.classList.remove('active');
        });

        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                const formData = new FormData(form);
                fetch(baseUrl + '/profile', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: { 'X-Requested-With': 'XMLHttpRequest' },
                    body: formData
                })
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            showToast('Profile', 'Updated successfully');
                            modal.classList.remove('active');
                            // Update sidebar avatar
                            if (data.avatar) {
                                const sidebarAvatar = document.getElementById('sidebar-user-avatar');
                                if (sidebarAvatar) {
                                    sidebarAvatar.innerHTML = `<img src="${escapeHtml(data.avatar)}" alt="" class="avatar-img"><span class="online-dot active"></span>`;
                                }
                            }
                        }
                    })
                    .catch(() => showToast('Error', 'Failed to update profile'));
            });
        }
    }

    /* ══════════════════════════════════════
       EMOJI PICKER
       ══════════════════════════════════════ */
    function initEmojiPicker() {
        const btn = document.querySelector('.input-emoji-btn');
        const picker = document.getElementById('emoji-picker');
        if (!btn || !picker) return;

        const emojis = [
            '😀','😂','😍','🥰','😎','🤔','😢','😡','👍','👎',
            '❤️','🔥','🎉','💯','🙏','👋','🤝','💪','🤣','😄',
            '😊','🥺','😇','🤩','😘','😜','🤗','🤫','🙄','😴',
            '🤯','😱','🤮','🤑','😈','👻','💀','👀','🖐️','✌️',
            '🤞','🤟','👏','🙌','👊','✊','🤲','🤝','💅','🧡',
            '💛','💚','💙','💜','🖤','🤍','💔','💕','💕','💖',
            '✨','⭐','🌟','💫','🎊','🎁','🎈','🏆','🥇','🎯',
            '🇷🇼','🌍','🌴','☀️','🌙','⚡','🔔','📱','💻','🎵'
        ];

        picker.innerHTML = `<div class="emoji-grid">${emojis.map(e => `<button type="button" class="emoji-btn" data-emoji="${e}">${e}</button>`).join('')}</div>`;

        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            picker.classList.toggle('visible');
        });

        picker.addEventListener('click', (e) => {
            const emojiBtn = e.target.closest('.emoji-btn');
            if (emojiBtn && messageInput) {
                const emoji = emojiBtn.dataset.emoji;
                const pos = messageInput.selectionStart;
                const before = messageInput.value.substring(0, pos);
                const after = messageInput.value.substring(pos);
                messageInput.value = before + emoji + after;
                messageInput.focus();
                messageInput.selectionStart = messageInput.selectionEnd = pos + emoji.length;
                picker.classList.remove('visible');
            }
        });

        document.addEventListener('click', (e) => {
            if (!picker.contains(e.target) && !btn.contains(e.target)) {
                picker.classList.remove('visible');
            }
        });
    }

    /* ══════════════════════════════════════
       FILE UPLOAD
       ══════════════════════════════════════ */
    function initFileUpload() {
        const btn = document.getElementById('file-upload-btn');
        const input = document.getElementById('file-upload-input');
        if (!btn || !input) return;

        btn.addEventListener('click', () => input.click());

        input.addEventListener('change', () => {
            const file = input.files[0];
            if (!file) return;

            const formData = new FormData();
            formData.append('file', file);

            // Show uploading indicator
            showToast('Upload', `Uploading ${file.name}...`);

            fetch(baseUrl + '/upload', {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'X-Requested-With': 'XMLHttpRequest' },
                body: formData
            })
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        const roomId = currentRoomIdEl?.value || ctx.currentRoomId;
                        if (roomId) {
                            sendWs({
                                type: 'MESSAGE',
                                roomId: parseInt(roomId),
                                content: file.name,
                                mediaUrl: data.url,
                                fileName: data.fileName,
                                fileType: data.fileType
                            });
                        }
                    } else {
                        showToast('Error', data.error || 'Upload failed');
                    }
                })
                .catch(() => showToast('Error', 'Upload failed'));

            input.value = '';
        });
    }

    /* ══════════════════════════════════════
       CONTEXT MENU (Right-click on messages)
       ══════════════════════════════════════ */
    function initContextMenu() {
        const menu = document.getElementById('context-menu');
        if (!menu) return;

        document.addEventListener('contextmenu', (e) => {
            const msgRow = e.target.closest('.message-row');
            if (!msgRow) return;
            e.preventDefault();

            const messageId = msgRow.dataset.messageId;
            const senderId = msgRow.dataset.senderId;
            const isOwn = Number(senderId) === Number(ctx.currentUserId);

            let menuHtml = `
                <button class="ctx-btn" data-action="react" data-msg-id="${messageId}">
                    <span>😀</span> React
                </button>
                <button class="ctx-btn" data-action="copy" data-msg-id="${messageId}">
                    <span>📋</span> Copy
                </button>
            `;

            if (isOwn) {
                menuHtml += `
                    <hr class="ctx-divider">
                    <button class="ctx-btn ctx-danger" data-action="delete" data-msg-id="${messageId}">
                        <span>🗑️</span> Delete
                    </button>
                `;
            }

            menu.innerHTML = menuHtml;
            menu.style.top = e.clientY + 'px';
            menu.style.left = e.clientX + 'px';
            menu.classList.add('visible');

            // Bind actions
            menu.querySelectorAll('.ctx-btn').forEach(btn => {
                btn.addEventListener('click', () => {
                    const action = btn.dataset.action;
                    const msgId = parseInt(btn.dataset.msgId);
                    if (action === 'delete') {
                        sendWs({ type: 'DELETE_MESSAGE', messageId: msgId });
                    } else if (action === 'react') {
                        showQuickReact(msgRow, msgId);
                    } else if (action === 'copy') {
                        const bubble = msgRow.querySelector('.message-bubble');
                        if (bubble) navigator.clipboard?.writeText(bubble.textContent);
                    }
                    menu.classList.remove('visible');
                });
            });
        });

        document.addEventListener('click', () => {
            if (menu) menu.classList.remove('visible');
        });
    }

    function showQuickReact(msgRow, messageId) {
        const quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
        const bar = document.createElement('div');
        bar.className = 'quick-react-bar';
        bar.innerHTML = quickEmojis.map(e => `<button class="react-emoji-btn">${e}</button>`).join('');
        bar.querySelectorAll('.react-emoji-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                sendWs({ type: 'REACTION', messageId: messageId, emoji: btn.textContent });
                bar.remove();
            });
        });
        msgRow.appendChild(bar);
        setTimeout(() => bar.remove(), 5000);
    }

    /* ══════════════════════════════════════
       ROOM INFO PANEL
       ══════════════════════════════════════ */
    function initRoomInfoPanel() {
        const btn = document.getElementById('room-info-btn');
        const panel = document.getElementById('room-info-panel');
        const closeBtn = document.getElementById('room-info-close');
        if (!btn || !panel) return;

        btn.addEventListener('click', () => {
            panel.classList.toggle('visible');
        });

        closeBtn?.addEventListener('click', () => {
            panel.classList.remove('visible');
        });
    }

    /* ══════════════════════════════════════
       AUDIO CALL (WebRTC)
       ══════════════════════════════════════ */
    function initAudioCallUI() {
        const callBtn = document.getElementById('audio-call-btn');
        const callModal = document.getElementById('call-modal');
        const endCallBtn = document.getElementById('end-call-btn');
        const acceptCallBtn = document.getElementById('accept-call-btn');
        const declineCallBtn = document.getElementById('decline-call-btn');
        if (!callBtn) return;

        callBtn.addEventListener('click', async () => {
            // Get the partner user ID from room members (for DM)
            const partnerId = callBtn.dataset.partnerId;
            if (!partnerId) {
                showToast('Call', 'Audio calls are only available in DM chats');
                return;
            }
            await startCall(parseInt(partnerId));
        });

        endCallBtn?.addEventListener('click', endCall);
        declineCallBtn?.addEventListener('click', endCall);
        acceptCallBtn?.addEventListener('click', async () => {
            await acceptCall();
        });
    }

    async function startCall(targetUserId) {
        try {
            localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
            callTarget = targetUserId;
            callRoomId = ctx.currentRoomId;

            const config = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] };
            peerConnection = new RTCPeerConnection(config);

            localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));

            peerConnection.onicecandidate = (e) => {
                if (e.candidate) {
                    sendWs({
                        type: 'CALL_SIGNAL',
                        signalType: 'candidate',
                        targetUserId: targetUserId,
                        candidate: e.candidate,
                        roomId: callRoomId
                    });
                }
            };

            peerConnection.ontrack = (e) => {
                const audio = document.getElementById('remote-audio');
                if (audio) audio.srcObject = e.streams[0];
            };

            const offer = await peerConnection.createOffer();
            await peerConnection.setLocalDescription(offer);

            sendWs({
                type: 'CALL_SIGNAL',
                signalType: 'offer',
                targetUserId: targetUserId,
                sdp: offer.sdp,
                roomId: callRoomId
            });

            showCallUI('calling');
        } catch (e) {
            showToast('Call', 'Could not access microphone');
        }
    }

    async function acceptCall() {
        try {
            localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
            localStream.getTracks().forEach(track => peerConnection.addTrack(track, localStream));

            const answer = await peerConnection.createAnswer();
            await peerConnection.setLocalDescription(answer);

            sendWs({
                type: 'CALL_SIGNAL',
                signalType: 'answer',
                targetUserId: callTarget,
                sdp: answer.sdp,
                roomId: callRoomId
            });

            showCallUI('active');
        } catch (e) {
            showToast('Call', 'Could not access microphone');
            endCall();
        }
    }

    function handleCallSignal(data) {
        const signalType = data.signalType;

        if (signalType === 'offer') {
            callTarget = data.fromUserId;
            callRoomId = data.roomId;

            const config = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] };
            peerConnection = new RTCPeerConnection(config);

            peerConnection.onicecandidate = (e) => {
                if (e.candidate) {
                    sendWs({
                        type: 'CALL_SIGNAL',
                        signalType: 'candidate',
                        targetUserId: callTarget,
                        candidate: e.candidate,
                        roomId: callRoomId
                    });
                }
            };

            peerConnection.ontrack = (e) => {
                const audio = document.getElementById('remote-audio');
                if (audio) audio.srcObject = e.streams[0];
            };

            peerConnection.setRemoteDescription(new RTCSessionDescription({
                type: 'offer',
                sdp: data.sdp
            }));

            // Show incoming call UI
            showCallUI('incoming', data.fromUsername);
        } else if (signalType === 'answer') {
            if (peerConnection) {
                peerConnection.setRemoteDescription(new RTCSessionDescription({
                    type: 'answer',
                    sdp: data.sdp
                }));
            }
            showCallUI('active');
        } else if (signalType === 'candidate') {
            if (peerConnection && data.candidate) {
                peerConnection.addIceCandidate(new RTCIceCandidate(data.candidate));
            }
        } else if (signalType === 'end') {
            endCall();
        }
    }

    function showCallUI(state, callerName) {
        const modal = document.getElementById('call-modal');
        const callStatus = document.getElementById('call-status');
        const acceptBtn = document.getElementById('accept-call-btn');
        const endBtn = document.getElementById('end-call-btn');
        const declineBtn = document.getElementById('decline-call-btn');
        if (!modal) return;

        modal.classList.add('active');

        if (state === 'calling') {
            if (callStatus) callStatus.textContent = 'Calling...';
            if (acceptBtn) acceptBtn.style.display = 'none';
            if (declineBtn) declineBtn.style.display = 'none';
            if (endBtn) endBtn.style.display = 'flex';
        } else if (state === 'incoming') {
            if (callStatus) callStatus.textContent = `${callerName || 'Someone'} is calling...`;
            if (acceptBtn) acceptBtn.style.display = 'flex';
            if (declineBtn) declineBtn.style.display = 'flex';
            if (endBtn) endBtn.style.display = 'none';
            playRingtone();
        } else if (state === 'active') {
            if (callStatus) callStatus.textContent = 'Call in progress';
            if (acceptBtn) acceptBtn.style.display = 'none';
            if (declineBtn) declineBtn.style.display = 'none';
            if (endBtn) endBtn.style.display = 'flex';
            stopRingtone();
        }
    }

    function endCall() {
        if (callTarget) {
            sendWs({
                type: 'CALL_SIGNAL',
                signalType: 'end',
                targetUserId: callTarget,
                roomId: callRoomId
            });
        }
        if (peerConnection) {
            peerConnection.close();
            peerConnection = null;
        }
        if (localStream) {
            localStream.getTracks().forEach(t => t.stop());
            localStream = null;
        }
        callTarget = null;
        callRoomId = null;
        stopRingtone();

        const modal = document.getElementById('call-modal');
        if (modal) modal.classList.remove('active');

        const audio = document.getElementById('remote-audio');
        if (audio) audio.srcObject = null;
    }

    function playRingtone() {
        stopRingtone();
        ringtoneInterval = setInterval(() => {
            playNotificationSound();
        }, 1000);
    }

    function stopRingtone() {
        if (ringtoneInterval) {
            clearInterval(ringtoneInterval);
            ringtoneInterval = null;
        }
    }

    /* ══════════════════════════════════════
       MESSAGE SEARCH
       ══════════════════════════════════════ */
    function initMessageSearch() {
        const btn = document.getElementById('msg-search-btn');
        const bar = document.getElementById('msg-search-bar');
        const input = document.getElementById('msg-search-input');
        const closeBtn = document.getElementById('msg-search-close');
        if (!btn || !bar || !input) return;

        btn.addEventListener('click', () => {
            bar.classList.toggle('visible');
            if (bar.classList.contains('visible')) {
                input.focus();
            }
        });

        closeBtn?.addEventListener('click', () => {
            bar.classList.remove('visible');
            input.value = '';
            // Remove highlights
            document.querySelectorAll('.message-bubble.highlight').forEach(el => {
                el.classList.remove('highlight');
            });
        });

        input.addEventListener('input', debounce(() => {
            const query = input.value.trim().toLowerCase();
            document.querySelectorAll('.message-bubble.highlight').forEach(el => {
                el.classList.remove('highlight');
            });
            if (!query) return;
            document.querySelectorAll('.message-bubble').forEach(el => {
                if (el.textContent.toLowerCase().includes(query)) {
                    el.classList.add('highlight');
                }
            });
            // Scroll to first match
            const first = document.querySelector('.message-bubble.highlight');
            if (first) first.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }, 300));
    }

    /* ══════════════════════════════════════
       UTILITIES
       ══════════════════════════════════════ */
    function escapeHtml(s) {
        const div = document.createElement('div');
        div.textContent = s;
        return div.innerHTML;
    }

    function debounce(fn, ms) {
        let t;
        return function () {
            clearTimeout(t);
            t = setTimeout(() => fn.apply(this, arguments), ms);
        };
    }

    /* ══════════════════════════════════════
       BOOT
       ══════════════════════════════════════ */
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
