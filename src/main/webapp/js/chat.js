/**
 * Tuganire — Real-Time Chat Client
 */
(function () {
    'use strict';

    const ctx = window.TUGANIRE || {};
    const baseUrl = ctx.contextPath || '';
    const wsBase = (location.protocol === 'https:' ? 'wss:' : 'ws:') + '//' + location.host + baseUrl;
    let ws = null;
    let typingTimeout = null;
    let unreadCount = 0;

    // DOM refs (set when chat area exists)
    let messagesContainer, messagesEl, messageForm, messageInput, typingIndicator, currentRoomIdEl;

    function init() {
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
            }
            connectWs();
        }

        initUserSearch();
        initThemeToggle();
        initNewRoomBtn();
        updateDocumentTitle();
    }

    function connectWs() {
        const url = wsBase + '/ws/chat';
        ws = new WebSocket(url);

        ws.onopen = () => {
            if (ctx.currentRoomId) {
                sendWs({ type: 'JOIN_ROOM', roomId: ctx.currentRoomId });
            }
        };

        ws.onmessage = (ev) => {
            try {
                const data = JSON.parse(ev.data);
                handleWsMessage(data);
            } catch (e) {}
        };

        ws.onclose = () => {
            setTimeout(connectWs, 3000);
        };

        ws.onerror = () => {};
    }

    function sendWs(obj) {
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(obj));
        }
    }

    function handleWsMessage(data) {
        switch (data.type) {
            case 'MESSAGE':
                appendMessage(data);
                if (data.roomId !== ctx.currentRoomId) {
                    showToast(data.senderUsername + ': ' + (data.content || '').substring(0, 50));
                    incrementUnread(data.roomId);
                } else {
                    scrollToBottom();
                }
                break;
            case 'TYPING':
                if (data.roomId === ctx.currentRoomId && data.userId !== ctx.currentUserId) {
                    typingIndicator.textContent = data.isTyping ? data.username + ' is typing...' : '';
                }
                break;
            case 'SEEN':
                if (data.roomId === ctx.currentRoomId) {
                    const msgEl = document.querySelector(`[data-message-id="${data.messageId}"]`);
                    if (msgEl) msgEl.classList.add('seen');
                }
                break;
            case 'REACTION':
                if (data.roomId === (currentRoomIdEl?.value || ctx.currentRoomId)) {
                    const msgEl = document.querySelector(`[data-message-id="${data.messageId}"]`);
                    if (msgEl) {
                        let r = msgEl.querySelector('.reactions');
                        if (!r) {
                            r = document.createElement('span');
                            r.className = 'reactions';
                            msgEl.appendChild(r);
                        }
                        r.textContent = (r.textContent || '') + ' ' + (data.emoji || '👍');
                    }
                }
                break;
            case 'USER_STATUS':
                // Could update online indicators in UI
                break;
        }
    }

    function appendMessage(data) {
        if (!messagesEl) return;
        const isOwn = data.senderId === ctx.currentUserId;
        const div = document.createElement('div');
        div.className = 'message' + (isOwn ? ' own' : '');
        div.dataset.messageId = data.id;
        div.innerHTML = `
            <span class="msg-sender">${escapeHtml(data.senderUsername || '')}</span>
            <p class="msg-content">${escapeHtml(data.content || '')}</p>
            <span class="msg-time">${data.createdAt ? new Date(data.createdAt).toLocaleTimeString() : ''}</span>
        `;
        messagesEl.appendChild(div);
    }

    function escapeHtml(s) {
        const div = document.createElement('div');
        div.textContent = s;
        return div.innerHTML;
    }

    function onSendMessage(e) {
        e.preventDefault();
        const roomId = currentRoomIdEl?.value || ctx.currentRoomId;
        const content = (messageInput?.value || '').trim();
        if (!roomId || !content) return;

        sendWs({ type: 'MESSAGE', roomId: parseInt(roomId), content });
        messageInput.value = '';
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

    function debounce(fn, ms) {
        let t;
        return function () {
            clearTimeout(t);
            t = setTimeout(() => fn.apply(this, arguments), ms);
        };
    }

    function scrollToBottom() {
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    }

    function showToast(text) {
        const t = document.createElement('div');
        t.className = 'toast';
        t.textContent = text;
        document.body.appendChild(t);
        setTimeout(() => t.remove(), 4000);
    }

    function incrementUnread(roomId) {
        unreadCount++;
        const badge = document.querySelector(`.room-badge[data-room-id="${roomId}"]`);
        if (badge) {
            badge.textContent = (parseInt(badge.textContent || 0) + 1).toString();
        }
        updateDocumentTitle();
    }

    function updateDocumentTitle() {
        const title = unreadCount > 0 ? `(${unreadCount}) Tuganire` : 'Tuganire';
        document.title = title;
    }

    function initUserSearch() {
        const input = document.getElementById('user-search');
        const results = document.getElementById('search-results');
        if (!input || !results) return;

        let searchTimeout;
        input.addEventListener('input', () => {
            clearTimeout(searchTimeout);
            const q = input.value.trim();
            if (q.length < 2) {
                results.innerHTML = '';
                results.style.display = 'none';
                return;
            }
            searchTimeout = setTimeout(() => {
                fetch(baseUrl + '/users/search?q=' + encodeURIComponent(q))
                    .then(r => r.json())
                    .then(users => {
                        results.innerHTML = users.map(u => `
                            <div class="user-item" data-user-id="${u.id}" data-username="${escapeHtml(u.username)}">
                                ${u.username} ${u.isOnline ? '🟢' : ''}
                            </div>
                        `).join('') || '<div class="user-item">No users found</div>';
                        results.style.display = 'block';
                        results.querySelectorAll('.user-item[data-user-id]').forEach(el => {
                            el.addEventListener('click', () => {
                                const uid = el.dataset.userId;
                                startDm(uid);
                                results.innerHTML = '';
                                results.style.display = 'none';
                                input.value = '';
                            });
                        });
                    })
                    .catch(() => {});
            }, 300);
        });

        document.addEventListener('click', (e) => {
            if (!results.contains(e.target) && !input.contains(e.target)) {
                results.style.display = 'none';
            }
        });
    }

    function startDm(userId) {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = baseUrl + '/rooms';
        const typeInput = document.createElement('input');
        typeInput.type = 'hidden';
        typeInput.name = 'type';
        typeInput.value = 'DM';
        const targetInput = document.createElement('input');
        targetInput.type = 'hidden';
        targetInput.name = 'targetUserId';
        targetInput.value = userId;
        form.appendChild(typeInput);
        form.appendChild(targetInput);
        document.body.appendChild(form);
        form.submit();
    }

    function initThemeToggle() {
        const btn = document.getElementById('theme-toggle');
        if (!btn) return;
        const theme = localStorage.getItem('tuganire-theme') || 'dark';
        document.documentElement.dataset.theme = theme;
        btn.textContent = theme === 'dark' ? '🌙' : '☀️';
        btn.addEventListener('click', () => {
            const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
            document.documentElement.dataset.theme = next;
            localStorage.setItem('tuganire-theme', next);
            btn.textContent = next === 'dark' ? '🌙' : '☀️';
        });
    }

    function initNewRoomBtn() {
        const btn = document.getElementById('new-room-btn');
        if (!btn) return;
        btn.addEventListener('click', () => {
            const name = prompt('Room name:');
            if (name && name.trim()) {
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = baseUrl + '/rooms';
                const input = document.createElement('input');
                input.type = 'hidden';
                input.name = 'name';
                input.value = name.trim();
                form.appendChild(input);
                document.body.appendChild(form);
                form.submit();
            }
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
