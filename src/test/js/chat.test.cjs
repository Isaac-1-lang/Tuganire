const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function client() {
    const elements = new Map();
    function element(id) {
        if (!elements.has(id)) elements.set(id, {
            value: '', innerHTML: '', textContent: '', style: {}, dataset: {}, hidden: false,
            listeners: {}, classList: { add() {}, remove() {}, toggle() {} },
            addEventListener(event, fn) { this.listeners[event] = fn; },
            querySelectorAll() { return []; }, querySelector() { return null; },
            setAttribute() {}, focus() {}, contains() { return false; }
        });
        return elements.get(id);
    }
    const requests = [];
    const context = {
        window: { TUGANIRE: { contextPath: '/tuganire', currentRoomId: 1 }, history: { pushState() {} } },
        location: { protocol: 'http:', host: 'localhost' }, localStorage: { getItem() {} },
        document: { readyState: 'loading', addEventListener() {}, getElementById: element,
            createElement() { return { textContent: '', get innerHTML() { return this.textContent; } }; },
            querySelectorAll() { return []; }, querySelector() { return null; } },
        WebSocket: { OPEN: 1 }, AbortController, setTimeout, clearTimeout, console: { error() {} },
        fetch(url) { return new Promise(resolve => requests.push({ url, resolve })); }
    };
    let source = fs.readFileSync('src/main/webapp/js/chat.js', 'utf8');
    source = source.replace('    if (document.readyState', `
        showToast = () => {};
        messagesEl = document.getElementById('messages');
        messageInput = document.getElementById('message-input');
        currentRoomIdEl = document.getElementById('current-room-id');
        window.test = { initUserSearch, loadRoomAsync, onSendMessage };
    if (document.readyState`);
    vm.runInNewContext(source, context);
    return { ...context, element, requests, api: context.window.test };
}

test('initial people load does not open a duplicate search overlay', async () => {
    const c = client();
    c.api.initUserSearch();
    c.requests[0].resolve({ ok: true, headers: { get: () => 'application/json' }, json: async () => [] });
    await new Promise(resolve => setImmediate(resolve));
    assert.equal(c.element('search-results').style.display, 'none');
});

test('disconnected send preserves the draft', () => {
    const c = client();
    c.element('message-input').value = 'Keep this draft';
    c.api.onSendMessage({ preventDefault() {} });
    assert.equal(c.element('message-input').value, 'Keep this draft');
});

test('latest room selection wins even when an older response arrives last', async () => {
    const c = client();
    const first = c.api.loadRoomAsync('2', null);
    const second = c.api.loadRoomAsync('3', null);
    const response = () => ({ ok: true, json: async () => [] });
    c.requests[1].resolve(response());
    await second;
    c.requests[0].resolve(response());
    await first;
    assert.equal(c.window.TUGANIRE.currentRoomId, '3');
    assert.equal(c.element('active-chat-state').style.display, 'flex');
    assert.equal(c.element('room-loading').hidden, true);
});

test('failed room load keeps the previous conversation and clears loading', async () => {
    const c = client();
    const loading = c.api.loadRoomAsync('2', null);
    assert.equal(c.element('room-loading').hidden, false);
    c.element('message-input').value = 'Draft';
    c.api.onSendMessage({ preventDefault() {} });
    assert.equal(c.element('message-input').value, 'Draft');
    c.requests[0].resolve({ ok: false });
    await loading;
    assert.equal(c.window.TUGANIRE.currentRoomId, 1);
    assert.equal(c.element('room-loading').hidden, true);
});

test('a stale people response cannot overwrite the current search', async () => {
    const c = client();
    c.api.initUserSearch();
    c.element('user-search').value = 'Nobody';
    c.element('user-search').listeners.input();
    await new Promise(resolve => setTimeout(resolve, 350));
    const response = () => ({ ok: true, headers: { get: () => 'application/json' }, json: async () => [] });
    c.requests[1].resolve(response());
    await new Promise(resolve => setImmediate(resolve));
    c.requests[0].resolve(response());
    await new Promise(resolve => setImmediate(resolve));
    assert.match(c.element('all-users-list').innerHTML, /No users found/);
});
