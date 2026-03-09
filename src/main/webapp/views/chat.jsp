<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Tuganire — Modern real-time chat application">
    <title>Tuganire — Inbox</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        /* ══════════════════════════════════════
           DESIGN TOKENS
           ══════════════════════════════════════ */
        :root {
            --bg-primary: #ffffff;
            --bg-secondary: #f8fafc;
            --bg-tertiary: #f1f5f9;
            --bg-hover: #f1f5f9;
            --bg-active: #eef2ff;
            --bg-input: #f8fafc;
            --text-primary: #0f172a;
            --text-secondary: #64748b;
            --text-muted: #94a3b8;
            --text-inverse: #ffffff;
            --accent: #6366f1;
            --accent-hover: #4f46e5;
            --accent-light: #eef2ff;
            --accent-glow: rgba(99, 102, 241, 0.25);
            --border: #e2e8f0;
            --border-light: #f1f5f9;
            --error: #ef4444;
            --success: #22c55e;
            --warning: #f59e0b;
            --info: #3b82f6;
            --online: #22c55e;
            --offline: #94a3b8;
            --shadow-sm: 0 1px 2px rgba(0,0,0,0.04);
            --shadow-md: 0 4px 12px rgba(0,0,0,0.06);
            --shadow-lg: 0 10px 30px rgba(0,0,0,0.08);
            --shadow-toast: 0 8px 32px rgba(0,0,0,0.12);
            --radius-sm: 6px;
            --radius-md: 10px;
            --radius-lg: 16px;
            --radius-xl: 24px;
            --radius-full: 9999px;
            --sidebar-width: 340px;
            --transition-fast: 0.15s ease;
            --transition-base: 0.25s ease;
            --transition-slow: 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }

        [data-theme="dark"] {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-tertiary: #334155;
            --bg-hover: #1e293b;
            --bg-active: #312e81;
            --bg-input: #1e293b;
            --text-primary: #f1f5f9;
            --text-secondary: #94a3b8;
            --text-muted: #64748b;
            --text-inverse: #0f172a;
            --accent: #818cf8;
            --accent-hover: #6366f1;
            --accent-light: #312e81;
            --accent-glow: rgba(129, 140, 248, 0.3);
            --border: #334155;
            --border-light: #1e293b;
            --shadow-sm: 0 1px 2px rgba(0,0,0,0.2);
            --shadow-md: 0 4px 12px rgba(0,0,0,0.3);
            --shadow-lg: 0 10px 30px rgba(0,0,0,0.4);
            --shadow-toast: 0 8px 32px rgba(0,0,0,0.5);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.5;
            height: 100vh;
            overflow: hidden;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        /* ══════════════════════════════════════
           CONNECTION STATUS BAR
           ══════════════════════════════════════ */
        .connection-bar {
            position: fixed; top: 0; left: 0; right: 0;
            z-index: 1000;
            padding: 0.4rem 1rem;
            font-size: 0.78rem; font-weight: 600;
            text-align: center;
            display: flex; align-items: center; justify-content: center; gap: 0.5rem;
            transform: translateY(-100%);
            transition: transform var(--transition-base), background var(--transition-base);
        }
        .connection-bar.visible { transform: translateY(0); }
        .connection-bar.offline { background: var(--error); color: #fff; }
        .connection-bar.reconnecting { background: var(--warning); color: #1a1a1a; }
        .connection-bar.online { background: var(--success); color: #fff; }
        .connection-bar .spinner-sm {
            width: 14px; height: 14px;
            border: 2px solid rgba(255,255,255,0.3);
            border-top-color: #fff;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        /* ══════════════════════════════════════
           LAYOUT
           ══════════════════════════════════════ */
        .app-layout {
            display: grid;
            grid-template-columns: var(--sidebar-width) 1fr;
            height: 100vh;
        }

        /* ══════════════════════════════════════
           SIDEBAR
           ══════════════════════════════════════ */
        .sidebar {
            background: var(--bg-secondary);
            border-right: 1px solid var(--border);
            display: flex; flex-direction: column;
            overflow: hidden;
            transition: background var(--transition-base);
        }

        .sidebar-header {
            padding: 1.25rem 1.25rem 0.75rem;
            display: flex; align-items: center; justify-content: space-between;
        }
        .sidebar-brand {
            display: flex; align-items: center; gap: 0.5rem;
            font-weight: 800; font-size: 1.15rem;
            color: var(--text-primary); text-decoration: none;
            letter-spacing: -0.02em;
        }
        .brand-logo { height: 26px; width: auto; object-fit: contain; }

        .sidebar-actions { display: flex; gap: 0.25rem; }

        .icon-btn {
            background: none; border: none;
            color: var(--text-secondary); cursor: pointer;
            padding: 0.45rem; border-radius: var(--radius-sm);
            display: flex; align-items: center; justify-content: center;
            transition: all var(--transition-fast);
            text-decoration: none; position: relative;
        }
        .icon-btn:hover { background: var(--bg-tertiary); color: var(--text-primary); }
        .icon-btn:active { transform: scale(0.92); }
        .icon-btn svg { width: 18px; height: 18px; }

        /* Search */
        .search-container { padding: 0 1rem 0.75rem; position: relative; }
        .search-box { position: relative; display: flex; align-items: center; }
        .search-box svg {
            position: absolute; left: 0.75rem;
            width: 15px; height: 15px; color: var(--text-muted);
            transition: color var(--transition-fast);
        }
        .search-box input {
            width: 100%;
            padding: 0.55rem 0.75rem 0.55rem 2.25rem;
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            background: var(--bg-primary);
            color: var(--text-primary);
            font-size: 0.875rem; font-family: inherit;
            transition: all var(--transition-fast);
        }
        .search-box input:focus {
            outline: none; border-color: var(--accent);
            box-shadow: 0 0 0 3px var(--accent-glow);
        }
        .search-box input:focus ~ svg,
        .search-box:focus-within svg { color: var(--accent); }
        .search-box input::placeholder { color: var(--text-muted); }

        .search-results {
            position: absolute; top: 100%; left: 1rem; right: 1rem;
            background: var(--bg-primary);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-lg);
            max-height: 260px; overflow-y: auto;
            z-index: 50;
            animation: slideDown 0.2s ease;
        }
        .search-results:empty { display: none; }
        .search-results .user-item {
            padding: 0.65rem 1rem; cursor: pointer;
            display: flex; align-items: center; gap: 0.75rem;
            font-size: 0.875rem; font-weight: 500;
            border-bottom: 1px solid var(--border-light);
            transition: background var(--transition-fast);
        }
        .search-results .user-item:last-child { border-bottom: none; }
        .search-results .user-item:hover { background: var(--bg-hover); }

        /* Sidebar Content */
        .sidebar-content { flex: 1; overflow-y: auto; padding: 0 0.5rem 1rem; }
        .sidebar-content::-webkit-scrollbar { width: 4px; }
        .sidebar-content::-webkit-scrollbar-track { background: transparent; }
        .sidebar-content::-webkit-scrollbar-thumb { background: var(--border); border-radius: 4px; }

        .section-title {
            padding: 1rem 0.75rem 0.5rem;
            font-size: 0.68rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.08em;
            color: var(--text-muted);
        }

        /* List Items */
        .list-item {
            display: flex; align-items: center; gap: 0.75rem;
            padding: 0.6rem 0.75rem; border-radius: var(--radius-md);
            cursor: pointer; text-decoration: none;
            color: var(--text-primary);
            transition: all var(--transition-fast);
            margin-bottom: 2px; position: relative;
        }
        .list-item:hover { background: var(--bg-hover); }
        .list-item.active {
            background: var(--accent-light);
        }
        .list-item.active .item-name { color: var(--accent); font-weight: 600; }

        /* Avatar */
        .avatar {
            width: 38px; height: 38px; border-radius: 50%;
            background: linear-gradient(135deg, var(--accent-light), var(--bg-tertiary));
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; color: var(--accent);
            font-size: 0.85rem; flex-shrink: 0;
            position: relative;
            transition: transform var(--transition-fast);
        }
        .list-item:hover .avatar { transform: scale(1.05); }
        .avatar-lg { width: 42px; height: 42px; font-size: 1rem; }

        /* Online indicator dot */
        .online-dot {
            position: absolute; bottom: 0; right: 0;
            width: 11px; height: 11px;
            border-radius: 50%;
            border: 2.5px solid var(--bg-secondary);
            background: var(--offline);
            transition: background var(--transition-base);
        }
        .online-dot.active { background: var(--online); }
        .chat-header .online-dot { border-color: var(--bg-primary); }

        .item-details { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 1px; }
        .item-header { display: flex; justify-content: space-between; align-items: center; }
        .item-name {
            font-size: 0.875rem; font-weight: 500;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .item-preview {
            font-size: 0.78rem; color: var(--text-muted);
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .item-time { font-size: 0.68rem; color: var(--text-muted); flex-shrink: 0; }
        .item-meta { display: flex; align-items: center; gap: 0.5rem; flex-shrink: 0; }

        .badge {
            display: inline-flex; align-items: center; justify-content: center;
            min-width: 1.2rem; height: 1.2rem;
            padding: 0 0.35rem; border-radius: var(--radius-full);
            background: var(--accent); color: #fff;
            font-size: 0.65rem; font-weight: 700;
            animation: popIn 0.3s cubic-bezier(0.68, -0.55, 0.265, 1.55);
        }
        .badge:empty { display: none; }

        /* Skeleton Loaders */
        .skeleton {
            background: linear-gradient(90deg, var(--bg-tertiary) 25%, var(--bg-hover) 50%, var(--bg-tertiary) 75%);
            background-size: 200% 100%;
            animation: shimmer 1.5s infinite;
            border-radius: var(--radius-sm);
        }
        .skeleton-item {
            display: flex; align-items: center; gap: 0.75rem;
            padding: 0.6rem 0.75rem;
        }
        .skeleton-avatar { width: 38px; height: 38px; border-radius: 50%; flex-shrink: 0; }
        .skeleton-lines { flex: 1; display: flex; flex-direction: column; gap: 6px; }
        .skeleton-line { height: 12px; border-radius: 6px; }
        .skeleton-line.w-70 { width: 70%; }
        .skeleton-line.w-50 { width: 50%; }
        .skeleton-line.w-40 { width: 40%; }

        .empty-hint {
            padding: 1.5rem 1rem;
            color: var(--text-muted);
            font-size: 0.85rem;
            text-align: center;
        }

        /* User profile section at bottom */
        .sidebar-footer {
            padding: 0.75rem 1rem;
            border-top: 1px solid var(--border);
            display: flex; align-items: center; gap: 0.75rem;
        }
        .sidebar-footer .user-info { flex: 1; min-width: 0; }
        .sidebar-footer .user-name {
            font-size: 0.85rem; font-weight: 600;
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .sidebar-footer .user-status { font-size: 0.72rem; color: var(--success); }

        /* ══════════════════════════════════════
           MAIN CHAT AREA
           ══════════════════════════════════════ */
        .chat-main {
            display: flex; flex-direction: column;
            background: var(--bg-primary);
            position: relative;
            transition: background var(--transition-base);
            overflow: hidden;
            min-height: 0;
            height: 100%;
        }

        /* Empty State */
        .empty-state {
            flex: 1; display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            background: var(--bg-secondary);
        }
        .empty-icon-wrap {
            width: 110px; height: 110px;
            background: var(--bg-primary);
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            box-shadow: var(--shadow-md);
            margin-bottom: 1.5rem;
            position: relative;
            animation: float 3s ease-in-out infinite;
        }
        .empty-icon-wrap::before {
            content: ''; position: absolute;
            inset: -18px; border-radius: 50%;
            background: radial-gradient(circle, var(--accent-light) 0%, transparent 70%);
            z-index: 0; opacity: 0.6;
        }
        .empty-icon-wrap svg {
            width: 44px; height: 44px;
            color: var(--accent); position: relative; z-index: 1;
        }
        .empty-state h3 {
            font-size: 1.2rem; font-weight: 700;
            color: var(--text-primary); margin-bottom: 0.4rem;
        }
        .empty-state p { color: var(--text-secondary); font-size: 0.9rem; }

        /* Chat Header */
        .chat-header {
            padding: 0.875rem 1.5rem;
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center; justify-content: space-between;
            background: var(--bg-primary);
            z-index: 10;
            backdrop-filter: blur(12px);
            transition: background var(--transition-base);
            flex-shrink: 0;
        }
        .chat-header-info { display: flex; align-items: center; gap: 0.875rem; }
        .chat-header-info h2 { font-size: 1rem; font-weight: 700; }
        .header-status {
            font-size: 0.75rem;
            color: var(--text-secondary);
            display: flex; align-items: center; gap: 0.35rem;
        }
        .header-status .status-dot {
            width: 7px; height: 7px; border-radius: 50%;
            background: var(--offline);
            transition: background var(--transition-base);
        }
        .header-status .status-dot.online { background: var(--online); }
        .chat-actions { display: flex; gap: 0.25rem; }

        /* Messages */
        .messages-container {
            flex: 1 1 0;
            min-height: 0;
            overflow-y: auto;
            padding: 1.5rem 2rem;
            display: flex; flex-direction: column;
            background: var(--bg-secondary);
            position: relative;
            scroll-behavior: smooth;
        }
        .messages-container::-webkit-scrollbar { width: 5px; }
        .messages-container::-webkit-scrollbar-track { background: transparent; }
        .messages-container::-webkit-scrollbar-thumb { background: var(--border); border-radius: 5px; }

        .messages {
            display: flex; flex-direction: column; gap: 0.5rem;
            max-width: 780px; margin: 0 auto; width: 100%;
        }

        /* Date separator */
        .date-separator {
            display: flex; align-items: center; gap: 1rem;
            margin: 1rem 0;
        }
        .date-separator::before, .date-separator::after {
            content: ''; flex: 1; height: 1px;
            background: var(--border);
        }
        .date-separator span {
            font-size: 0.72rem; font-weight: 600;
            color: var(--text-muted);
            background: var(--bg-secondary);
            padding: 0.25rem 0.75rem;
            border-radius: var(--radius-full);
            border: 1px solid var(--border);
        }

        /* Message Rows */
        .message-row {
            display: flex; gap: 0.75rem; max-width: 100%;
            animation: msgIn 0.3s ease-out;
        }
        .message-row.own { flex-direction: row-reverse; }
        .message-avatar {
            width: 30px; height: 30px; border-radius: 50%;
            background: linear-gradient(135deg, var(--accent-light), var(--bg-tertiary));
            color: var(--accent); display: flex;
            align-items: center; justify-content: center;
            font-size: 0.75rem; font-weight: 700;
            flex-shrink: 0; margin-top: auto;
        }
        .message-row.own .message-avatar { display: none; }
        .message-content-wrap {
            max-width: 65%; display: flex; flex-direction: column;
        }
        .message-row.own .message-content-wrap { align-items: flex-end; }

        .message-sender-name {
            font-size: 0.72rem; color: var(--text-secondary);
            margin-bottom: 0.2rem; margin-left: 0.3rem; font-weight: 500;
        }
        .message-row.own .message-sender-name { display: none; }

        .message-bubble {
            padding: 0.65rem 1rem;
            background: var(--bg-primary);
            color: var(--text-primary);
            border: 1px solid var(--border);
            border-radius: 14px 14px 14px 4px;
            font-size: 0.9rem; line-height: 1.55;
            box-shadow: var(--shadow-sm);
            position: relative;
            word-wrap: break-word;
            transition: background var(--transition-base);
        }
        .message-row.own .message-bubble {
            background: var(--accent);
            color: #fff; border: none;
            border-radius: 14px 14px 4px 14px;
            box-shadow: 0 2px 8px var(--accent-glow);
        }
        .message-bubble:hover { filter: brightness(0.97); }

        .message-footer {
            display: flex; align-items: center; gap: 0.35rem;
            margin-top: 0.2rem; padding: 0 0.3rem;
        }
        .message-row.own .message-footer { justify-content: flex-end; }
        .message-time {
            font-size: 0.68rem; color: var(--text-muted);
        }
        /* Read receipt checkmarks */
        .msg-status { display: flex; align-items: center; }
        .msg-status svg { width: 14px; height: 14px; color: var(--text-muted); }
        .msg-status.delivered svg { color: var(--text-secondary); }
        .msg-status.seen svg { color: var(--accent); }

        /* Typing Indicator */
        .typing-indicator {
            padding: 0 2rem 0.25rem;
            font-size: 0.78rem; color: var(--text-secondary);
            min-height: 1.5rem;
            background: var(--bg-secondary);
            display: flex; align-items: center; gap: 0.5rem;
            max-width: 780px; margin: 0 auto; width: 100%;
            flex-shrink: 0;
        }
        .typing-dots { display: flex; gap: 3px; align-items: center; }
        .typing-dots span {
            width: 6px; height: 6px; border-radius: 50%;
            background: var(--text-muted);
            animation: typingBounce 1.4s infinite;
        }
        .typing-dots span:nth-child(2) { animation-delay: 0.2s; }
        .typing-dots span:nth-child(3) { animation-delay: 0.4s; }

        /* Scroll to bottom FAB */
        .scroll-bottom-btn {
            position: absolute; bottom: 90px; right: 2rem;
            width: 40px; height: 40px; border-radius: 50%;
            background: var(--bg-primary); border: 1px solid var(--border);
            box-shadow: var(--shadow-md);
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; z-index: 20;
            opacity: 0; transform: scale(0.8) translateY(10px);
            transition: all var(--transition-base);
            color: var(--text-secondary);
        }
        .scroll-bottom-btn:hover {
            background: var(--accent); color: #fff;
            border-color: var(--accent);
            box-shadow: 0 4px 16px var(--accent-glow);
        }
        .scroll-bottom-btn.visible {
            opacity: 1; transform: scale(1) translateY(0);
        }
        .scroll-bottom-btn svg { width: 18px; height: 18px; }

        /* Input Area */
        .input-area {
            padding: 0.875rem 1.5rem;
            background: var(--bg-primary);
            border-top: 1px solid var(--border);
            z-index: 10;
            transition: background var(--transition-base);
            flex-shrink: 0;
        }
        .input-form {
            display: flex; align-items: center; gap: 0.5rem;
            max-width: 780px; margin: 0 auto; width: 100%;
        }
        .input-wrapper {
            flex: 1; position: relative; display: flex; align-items: center;
        }
        .input-wrapper input {
            width: 100%;
            padding: 0.75rem 3rem 0.75rem 1.125rem;
            border: 1.5px solid var(--border);
            border-radius: var(--radius-xl);
            background: var(--bg-input);
            color: var(--text-primary);
            font-size: 0.9rem; font-family: inherit;
            transition: all var(--transition-fast);
        }
        .input-wrapper input:focus {
            outline: none; border-color: var(--accent);
            background: var(--bg-primary);
            box-shadow: 0 0 0 3px var(--accent-glow);
        }
        .input-wrapper input::placeholder { color: var(--text-muted); }
        .input-emoji-btn {
            position: absolute; right: 0.75rem;
            background: none; border: none; cursor: pointer;
            color: var(--text-muted); padding: 0.25rem;
            border-radius: 50%;
            transition: all var(--transition-fast);
            display: flex; align-items: center;
        }
        .input-emoji-btn:hover { color: var(--accent); background: var(--accent-light); }
        .input-emoji-btn svg { width: 20px; height: 20px; }

        .btn-send {
            width: 42px; height: 42px; flex-shrink: 0;
            background: var(--accent); color: #fff;
            border: none; border-radius: 50%;
            cursor: pointer;
            transition: all var(--transition-fast);
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 2px 8px var(--accent-glow);
        }
        .btn-send:hover {
            background: var(--accent-hover);
            box-shadow: 0 4px 16px var(--accent-glow);
            transform: scale(1.05);
        }
        .btn-send:active { transform: scale(0.95); }
        .btn-send svg { width: 18px; height: 18px; }

        /* Toast Notifications */
        .toast-container {
            position: fixed; top: 1.25rem; right: 1.25rem;
            z-index: 2000; display: flex; flex-direction: column; gap: 0.5rem;
        }
        .toast {
            background: var(--bg-primary);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 0.75rem 1rem;
            box-shadow: var(--shadow-toast);
            font-size: 0.85rem; color: var(--text-primary);
            display: flex; align-items: center; gap: 0.5rem;
            min-width: 280px; max-width: 380px;
            animation: toastIn 0.4s ease-out;
            cursor: pointer;
            transition: opacity 0.3s ease;
        }
        .toast.removing { opacity: 0; transform: translateX(20px); }
        .toast-icon {
            width: 28px; height: 28px; border-radius: 50%;
            background: var(--accent-light);
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .toast-icon svg { width: 14px; height: 14px; color: var(--accent); }
        .toast-text { flex: 1; font-weight: 500; }

        /* Create Room Modal */
        .modal-overlay {
            position: fixed; inset: 0;
            background: rgba(0,0,0,0.4);
            backdrop-filter: blur(4px);
            z-index: 100;
            display: none; align-items: center; justify-content: center;
            animation: fadeIn 0.2s ease;
        }
        .modal-overlay.active { display: flex; }
        .modal {
            background: var(--bg-primary);
            border-radius: var(--radius-lg);
            padding: 2rem;
            width: 90%; max-width: 400px;
            box-shadow: var(--shadow-lg);
            animation: scaleIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .modal h3 { font-size: 1.1rem; font-weight: 700; margin-bottom: 1rem; }
        .modal input[type="text"] {
            width: 100%; padding: 0.65rem 1rem;
            border: 1.5px solid var(--border);
            border-radius: var(--radius-md);
            background: var(--bg-input);
            color: var(--text-primary);
            font-size: 0.9rem; font-family: inherit;
            margin-bottom: 1rem;
        }
        .modal input[type="text"]:focus {
            outline: none; border-color: var(--accent);
            box-shadow: 0 0 0 3px var(--accent-glow);
        }
        .modal-actions { display: flex; gap: 0.5rem; justify-content: flex-end; }
        .btn-modal {
            padding: 0.55rem 1.25rem;
            border-radius: var(--radius-md);
            font-size: 0.875rem; font-weight: 600;
            font-family: inherit; cursor: pointer;
            transition: all var(--transition-fast);
            border: none;
        }
        .btn-modal.primary { background: var(--accent); color: #fff; }
        .btn-modal.primary:hover { background: var(--accent-hover); }
        .btn-modal.secondary { background: var(--bg-tertiary); color: var(--text-primary); }
        .btn-modal.secondary:hover { background: var(--bg-hover); }

        /* ══════════════════════════════════════
           ANIMATIONS
           ══════════════════════════════════════ */
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
        @keyframes slideDown { from { opacity: 0; transform: translateY(-8px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes popIn { 0% { transform: scale(0); } 100% { transform: scale(1); } }
        @keyframes msgIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes typingBounce {
            0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
            30% { transform: translateY(-6px); opacity: 1; }
        }
        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-8px); }
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes scaleIn { from { opacity: 0; transform: scale(0.9); } to { opacity: 1; transform: scale(1); } }
        @keyframes toastIn { from { opacity: 0; transform: translateX(30px); } to { opacity: 1; transform: translateX(0); } }

        /* ══════════════════════════════════════
           RESPONSIVE
           ══════════════════════════════════════ */
        .mobile-menu-btn { display: none; }
        .sidebar-overlay { display: none; }

        @media (max-width: 768px) {
            .app-layout { grid-template-columns: 1fr; }
            .sidebar {
                position: fixed; left: 0; top: 0; bottom: 0;
                width: 85%; max-width: 320px;
                z-index: 100;
                transform: translateX(-100%);
                transition: transform var(--transition-slow);
            }
            .sidebar.open { transform: translateX(0); }
            .sidebar-overlay {
                display: block; position: fixed; inset: 0;
                background: rgba(0,0,0,0.4);
                z-index: 99; opacity: 0; pointer-events: none;
                transition: opacity var(--transition-base);
            }
            .sidebar-overlay.visible { opacity: 1; pointer-events: all; }
            .mobile-menu-btn {
                display: flex; margin-right: 0.5rem;
            }
            .chat-header { padding: 0.875rem 1rem; }
            .messages-container { padding: 1rem; }
            .input-area { padding: 0.75rem 1rem; }
            .message-content-wrap { max-width: 80%; }
        }
    </style>
</head>
<body>
<!-- Connection Status Bar -->
<div class="connection-bar" id="connection-bar">
    <span class="spinner-sm" id="conn-spinner" style="display:none;"></span>
    <span id="conn-text">Connecting...</span>
</div>

<!-- Toast Container -->
<div class="toast-container" id="toast-container"></div>

<!-- Mobile Sidebar Overlay -->
<div class="sidebar-overlay" id="sidebar-overlay"></div>

<div class="app-layout">
    <!-- ── Sidebar ── -->
    <aside class="sidebar" id="sidebar">
        <header class="sidebar-header">
            <a href="${pageContext.request.contextPath}/" class="sidebar-brand">
                <img src="${pageContext.request.contextPath}/static/logo.png" alt="Logo" class="brand-logo">
                Tuganire
            </a>
            <div class="sidebar-actions">
                <button class="icon-btn" title="New Chat" id="new-room-btn">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                    </svg>
                </button>
                <button class="icon-btn" title="Toggle Theme" id="theme-toggle">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" id="theme-icon">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
                    </svg>
                </button>
                <a href="${pageContext.request.contextPath}/auth/logout" class="icon-btn" title="Sign out">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                    </svg>
                </a>
            </div>
        </header>

        <div class="search-container">
            <div class="search-box">
                <input type="text" id="user-search" placeholder="Search people..." autocomplete="off">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>
            <div id="search-results" class="search-results"></div>
        </div>

        <div class="sidebar-content">
            <div class="section-title">Conversations</div>
            <div id="room-list" class="room-list">
                <c:forEach var="room" items="${rooms}">
                    <a href="${pageContext.request.contextPath}/chat?roomId=${room.id}"
                       class="list-item ${currentRoom != null && currentRoom.id == room.id ? 'active' : ''}"
                       data-room-id="${room.id}">
                        <div class="avatar">
                                ${room.name.substring(0, 1).toUpperCase()}
                            <span class="online-dot" data-room-id="${room.id}"></span>
                        </div>
                        <div class="item-details">
                            <div class="item-header">
                                <span class="item-name">${room.name}</span>
                                <span class="item-time" data-room-id="${room.id}"></span>
                            </div>
                            <span class="item-preview" data-room-id="${room.id}"></span>
                        </div>
                        <div class="item-meta">
                            <span class="badge" data-room-id="${room.id}"></span>
                        </div>
                    </a>
                </c:forEach>
                <c:if test="${empty rooms}">
                    <p class="empty-hint">Search for people above to start chatting.</p>
                </c:if>
            </div>

            <div class="section-title">People</div>
            <div id="all-users-list" class="people-list">
                <!-- Skeleton Loaders -->
                <div class="skeleton-item"><div class="skeleton skeleton-avatar"></div><div class="skeleton-lines"><div class="skeleton skeleton-line w-70"></div><div class="skeleton skeleton-line w-40"></div></div></div>
                <div class="skeleton-item"><div class="skeleton skeleton-avatar"></div><div class="skeleton-lines"><div class="skeleton skeleton-line w-50"></div><div class="skeleton skeleton-line w-40"></div></div></div>
                <div class="skeleton-item"><div class="skeleton skeleton-avatar"></div><div class="skeleton-lines"><div class="skeleton skeleton-line w-70"></div><div class="skeleton skeleton-line w-50"></div></div></div>
            </div>
        </div>

        <!-- User Profile Footer -->
        <div class="sidebar-footer">
            <div class="avatar">
                <c:if test="${currentUser != null}">
                    ${currentUser.username.substring(0, 1).toUpperCase()}
                </c:if>
                <span class="online-dot active"></span>
            </div>
            <div class="user-info">
                <div class="user-name">${currentUser != null ? currentUser.username : 'Guest'}</div>
                <div class="user-status">● Online</div>
            </div>
        </div>
    </aside>

    <!-- ── Main Chat Area ── -->
    <main class="chat-main">
        <c:choose>
            <c:when test="${currentRoom != null}">
                <header class="chat-header">
                    <div class="chat-header-info">
                        <button class="icon-btn mobile-menu-btn" id="mobile-menu-btn">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                            </svg>
                        </button>
                        <div class="avatar avatar-lg">
                                ${currentRoom.name.substring(0, 1).toUpperCase()}
                            <span class="online-dot" id="header-online-dot"></span>
                        </div>
                        <div>
                            <h2>${currentRoom.name}</h2>
                            <div class="header-status" id="header-status">
                                <span class="status-dot" id="header-status-dot"></span>
                                <span id="header-status-text">Offline</span>
                            </div>
                        </div>
                    </div>
                    <div class="chat-actions">
                        <button class="icon-btn" title="Room Info">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                            </svg>
                        </button>
                    </div>
                </header>

                <div class="messages-container" id="messages-container">
                    <div class="messages" id="messages">
                        <c:forEach var="msg" items="${messages}">
                            <div class="message-row ${msg.sender.id == currentUser.id ? 'own' : ''}" data-message-id="${msg.id}">
                                <div class="message-avatar">
                                        ${msg.sender.username.substring(0, 1).toUpperCase()}
                                </div>
                                <div class="message-content-wrap">
                                    <span class="message-sender-name">${msg.sender.username}</span>
                                    <div class="message-bubble"><c:out value="${msg.content}"/></div>
                                    <div class="message-footer">
                                        <span class="message-time">${msg.createdAt}</span>
                                        <c:if test="${msg.sender.id == currentUser.id}">
                                                <span class="msg-status delivered">
                                                    <svg viewBox="0 0 16 16" fill="none"><path d="M2 8l3 3 7-7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
                                                </span>
                                        </c:if>
                                    </div>
                                </div>
                            </div>
                        </c:forEach>
                    </div>
                </div>

                <!-- Scroll to Bottom Button -->
                <button class="scroll-bottom-btn" id="scroll-bottom-btn">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"/>
                    </svg>
                </button>

                <div class="typing-indicator" id="typing-indicator"></div>

                <div class="input-area">
                    <form class="input-form" id="message-form">
                        <input type="hidden" id="current-room-id" value="${currentRoom.id}">
                        <div class="input-wrapper">
                            <input type="text" id="message-input" placeholder="Type a message..." autocomplete="off">
                            <button type="button" class="input-emoji-btn" title="Emoji">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </button>
                        </div>
                        <button type="submit" class="btn-send" title="Send">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                            </svg>
                        </button>
                    </form>
                </div>
            </c:when>

            <c:otherwise>
                <header class="chat-header" style="border-bottom: none;">
                    <div class="chat-header-info">
                        <button class="icon-btn mobile-menu-btn" id="mobile-menu-btn-empty">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                            </svg>
                        </button>
                    </div>
                </header>
                <div class="empty-state">
                    <div class="empty-icon-wrap">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                        </svg>
                    </div>
                    <h3>Start a conversation</h3>
                    <p>Select a chat or search for someone to begin messaging.</p>
                </div>
            </c:otherwise>
        </c:choose>
    </main>
</div>

<!-- Create Room Modal -->
<div class="modal-overlay" id="room-modal">
    <div class="modal">
        <h3>Create New Room</h3>
        <input type="text" id="room-name-input" placeholder="Enter room name..." autofocus>
        <div class="modal-actions">
            <button class="btn-modal secondary" id="modal-cancel">Cancel</button>
            <button class="btn-modal primary" id="modal-create">Create</button>
        </div>
    </div>
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