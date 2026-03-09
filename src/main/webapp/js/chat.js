/**
 * Tuganire — Premium Real-Time Chat Client
 * Features: Connection status, online indicators, typing animations,
 * read receipts, toasts, scroll-to-bottom, theme toggle, mobile drawer
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
    const onlineUsers = new Set();

    // DOM refs
    let messagesContainer, messagesEl, messageForm, messageInput, typingIndicator, currentRoomIdEl;

    /* ══════════════════════════════════════
       INITIALIZATION
       ══════════════════════════════════════ */
    function init() {
        connectWs();

        if (ctx.currentRoomId) {
            messagesContainer = document.getElementById('messages-container');
            messagesEl = document.getElementById('messages');
            messageForm = document.getElementById('message-form');
            messageInput = document.getElementById('message-input');
            typingIndicator = document.getElementById('typing-indicator');
            currentRoomIdEl = document.getElementById('current-room-id');

            if (messageForm && messageInput) {
                messageForm.addEventListener('submit', onSendMessage);
                messageInput.addEventListener('input', debounce(onTyping, 400));
                messageInput.focus();
            }

            initScrollWatcher();
            scrollToBottom(false);
            formatMessageTimes();
        }

        initUserSearch();
        initThemeToggle();
        initNewRoomModal();
        initMobileDrawer();
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
       WEBSOCKET MESSAGE HANDLER
       ══════════════════════════════════════ */
    function handleWsMessage(data) {
        switch (data.type) {
            case 'MESSAGE':
                if (data.roomId === ctx.currentRoomId) {
                    appendMessage(data);
                    if (!isUserScrolledUp) scrollToBottom(true);
                    // Mark as seen
                    sendWs({ type: 'SEEN', messageId: data.id, roomId: data.roomId });
                } else {
                    showToast(data.senderUsername, (data.content || '').substring(0, 60));
                    incrementUnread(data.roomId);
                }
                updateRoomPreview(data.roomId, data.content, data.createdAt);
                break;

            case 'TYPING':
                if (data.roomId === ctx.currentRoomId && data.userId !== ctx.currentUserId) {
                    showTypingIndicator(data.isTyping, data.username);
                }
                break;

            case 'SEEN':
                if (data.roomId === ctx.currentRoomId) {
                    const msgEl = document.querySelector(`[data-message-id="${data.messageId}"] .msg-status`);
                    if (msgEl) {
                        msgEl.className = 'msg-status seen';
                        msgEl.innerHTML = '<svg viewBox="0 0 16 16" fill="none"><path d="M1 8l3 3 5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M6 8l3 3 5-5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
                    }
                }
                break;

            case 'REACTION':
                if (data.roomId === ctx.currentRoomId) {
                    const msgEl = document.querySelector(`[data-message-id="${data.messageId}"]`);
                    if (msgEl) {
                        let r = msgEl.querySelector('.reactions');
                        if (!r) {
                            r = document.createElement('span');
                            r.className = 'reactions';
                            r.style.cssText = 'font-size:0.85rem; margin-top:0.2rem; display:block;';
                            const bubble = msgEl.querySelector('.message-bubble');
                            if (bubble) bubble.parentNode.insertBefore(r, bubble.nextSibling);
                        }
                        r.textContent = (r.textContent || '') + ' ' + (data.emoji || '👍');
                    }
                }
                break;

            case 'USER_STATUS':
                updateOnlineStatus(data.userId, data.username, data.isOnline);
                break;
        }
    }

    /* ══════════════════════════════════════
       MESSAGE RENDERING
       ══════════════════════════════════════ */
    function appendMessage(data) {
        if (!messagesEl) return;
        const isOwn = data.senderId === ctx.currentUserId;
        const div = document.createElement('div');
        div.className = 'message-row' + (isOwn ? ' own' : '');
        div.dataset.messageId = data.id;

        const avatarLetter = data.senderUsername ? data.senderUsername.substring(0, 1).toUpperCase() : '?';
        const timeStr = data.createdAt
            ? new Date(data.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            : new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        const statusHtml = isOwn ? `
            <span class="msg-status delivered">
                <svg viewBox="0 0 16 16" fill="none"><path d="M2 8l3 3 7-7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </span>` : '';

        div.innerHTML = `
            <div class="message-avatar">${escapeHtml(avatarLetter)}</div>
            <div class="message-content-wrap">
                <span class="message-sender-name">${escapeHtml(data.senderUsername || '')}</span>
                <div class="message-bubble">${escapeHtml(data.content || '')}</div>
                <div class="message-footer">
                    <span class="message-time">${timeStr}</span>
                    ${statusHtml}
                </div>
            </div>
        `;
        messagesEl.appendChild(div);
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
    function updateOnlineStatus(userId, username, isOnline) {
        if (isOnline) {
            onlineUsers.add(userId);
        } else {
            onlineUsers.delete(userId);
        }

        // Update people list dots
        document.querySelectorAll(`.user-item[data-user-id="${userId}"]`).forEach(el => {
            const dot = el.querySelector('.online-dot');
            if (dot) dot.classList.toggle('active', isOnline);
            const statusText = el.querySelector('.user-online-text');
            if (statusText) statusText.textContent = isOnline ? 'Online' : 'Offline';
        });

        // Update chat header if this is the current room partner
        const headerDot = document.getElementById('header-online-dot');
        const headerStatusDot = document.getElementById('header-status-dot');
        const headerStatusText = document.getElementById('header-status-text');
        if (headerDot && headerStatusDot && headerStatusText) {
            // For DMs, check if partner is online
            if (isOnline) {
                headerDot.classList.add('active');
                headerStatusDot.classList.add('online');
                headerStatusText.textContent = 'Online';
            }
        }
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
            container.innerHTML = users.map(u => `
                <div class="user-item" data-user-id="${u.id}" data-username="${escapeHtml(u.username)}"
                     style="display:flex;align-items:center;gap:0.75rem;padding:0.6rem 0.75rem;cursor:pointer;border-radius:8px;transition:background 0.15s;">
                    <div class="avatar" style="width:34px;height:34px;font-size:0.8rem;">
                        ${escapeHtml(u.username.substring(0, 1).toUpperCase())}
                        <span class="online-dot ${u.isOnline ? 'active' : ''}"></span>
                    </div>
                    <div style="flex:1;min-width:0;">
                        <div style="font-size:0.875rem;font-weight:500;">${escapeHtml(u.username)}</div>
                        <div class="user-online-text" style="font-size:0.72rem;color:${u.isOnline ? 'var(--success)' : 'var(--text-muted)'};">
                            ${u.isOnline ? '● Online' : '○ Offline'}
                        </div>
                    </div>
                </div>
            `).join('');
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

        // Load users on init
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
       CREATE ROOM MODAL
       ══════════════════════════════════════ */
    function initNewRoomModal() {
        const btn = document.getElementById('new-room-btn');
        const modal = document.getElementById('room-modal');
        const nameInput = document.getElementById('room-name-input');
        const cancelBtn = document.getElementById('modal-cancel');
        const createBtn = document.getElementById('modal-create');
        if (!btn || !modal) return;

        btn.addEventListener('click', () => {
            modal.classList.add('active');
            if (nameInput) setTimeout(() => nameInput.focus(), 100);
        });

        cancelBtn?.addEventListener('click', () => modal.classList.remove('active'));

        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.classList.remove('active');
        });

        const doCreate = () => {
            const name = nameInput?.value?.trim();
            if (!name) return;
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = baseUrl + '/rooms';
            const input = document.createElement('input');
            input.type = 'hidden'; input.name = 'name'; input.value = name;
            form.appendChild(input);
            document.body.appendChild(form);
            form.submit();
        };

        createBtn?.addEventListener('click', doCreate);
        nameInput?.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') { e.preventDefault(); doCreate(); }
            if (e.key === 'Escape') modal.classList.remove('active');
        });
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
