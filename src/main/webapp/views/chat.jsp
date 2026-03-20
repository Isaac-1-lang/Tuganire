<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Tuganire — Modern real-time chat application">
    <title>Tuganire  Inbox</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        /* ══════════════════════════════════════
           DESIGN TOKENS (Glassmorphism & Gradients)
           ══════════════════════════════════════ */
        :root {
            /* Vibrant animated background gradients base */
            --bg-gradient-1: #e0f2fe;
            --bg-gradient-2: #ccfbf1;
            --bg-gradient-3: #a7f3d0;
            
            /* Glassmorphic variables */
            --glass-bg: rgba(255, 255, 255, 0.5);
            --glass-border: rgba(255, 255, 255, 0.4);
            --glass-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.05);
            --glass-blur: blur(25px);

            --bg-primary: transparent;
            --bg-secondary: rgba(255, 255, 255, 0.4);
            --bg-tertiary: rgba(255, 255, 255, 0.6);
            --bg-hover: rgba(255, 255, 255, 0.8);
            --bg-active: rgba(255, 255, 255, 0.9);
            --bg-input: rgba(255, 255, 255, 0.6);
            --text-primary: #0f172a;
            --text-secondary: #334155;
            --text-muted: #64748b;
            --text-inverse: #ffffff;
            --accent: #0f766e; /* Teal-ish accent */
            --accent-hover: #0d9488;
            --accent-light: rgba(15, 118, 110, 0.15);
            --accent-glow: rgba(15, 118, 110, 0.25);
            --border: rgba(255, 255, 255, 0.3);
            --border-light: rgba(255, 255, 255, 0.2);
            --error: #ef4444;
            --success: #10b981;
            --warning: #f59e0b;
            --info: #3b82f6;
            --online: #10b981;
            --offline: #94a3b8;
            --radius-sm: 8px;
            --radius-md: 12px;
            --radius-lg: 20px;
            --radius-xl: 24px;
            --radius-full: 9999px;
            --nav-width: 80px;
            --sidebar-width: 320px;
            --transition-fast: 0.2s ease;
            --transition-base: 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            --transition-slow: 0.5s cubic-bezier(0.4, 0, 0.2, 1);
        }

        [data-theme="dark"] {
            --bg-gradient-1: #0f172a;
            --bg-gradient-2: #164e63;
            --bg-gradient-3: #064e3b;
            
            --glass-bg: rgba(15, 23, 42, 0.45);
            --glass-border: rgba(255, 255, 255, 0.08);
            --glass-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3);
            
            --bg-secondary: rgba(15, 23, 42, 0.3);
            --bg-tertiary: rgba(30, 41, 59, 0.5);
            --bg-hover: rgba(51, 65, 85, 0.6);
            --bg-active: rgba(15, 118, 110, 0.4);
            --bg-input: rgba(15, 23, 42, 0.6);
            --text-primary: #f8fafc;
            --text-secondary: #cbd5e1;
            --text-muted: #94a3b8;
            --text-inverse: #020617;
            --accent: #2dd4bf;
            --accent-hover: #14b8a6;
            --accent-light: rgba(45, 212, 191, 0.15);
            --accent-glow: rgba(45, 212, 191, 0.3);
            --border: rgba(255, 255, 255, 0.08);
            --border-light: rgba(255, 255, 255, 0.04);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, var(--bg-gradient-1), var(--bg-gradient-2), var(--bg-gradient-3));
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
            color: var(--text-primary);
            line-height: 1.5;
            height: 100vh;
            overflow: hidden;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        /* ══════════════════════════════════════
           MODERN SCROLLBARS
           ══════════════════════════════════════ */
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { 
            background: rgba(15, 23, 42, 0.1); 
            border-radius: var(--radius-full); 
        }
        [data-theme="dark"] ::-webkit-scrollbar-thumb { 
            background: rgba(255, 255, 255, 0.15); 
        }
        ::-webkit-scrollbar-thumb:hover { 
            background: rgba(15, 23, 42, 0.2); 
        }
        [data-theme="dark"] ::-webkit-scrollbar-thumb:hover { 
            background: rgba(255, 255, 255, 0.25); 
        }

        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
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
            grid-template-columns: var(--nav-width) var(--sidebar-width) 1fr;
            height: 100vh;
            padding: 1.5rem;
            gap: 1.5rem;
            max-width: 1600px;
            margin: 0 auto;
        }

        /* ══════════════════════════════════════
           GLASS CARDS BASE
           ══════════════════════════════════════ */
        .glass-card {
            background: var(--glass-bg);
            backdrop-filter: var(--glass-blur);
            -webkit-backdrop-filter: var(--glass-blur);
            border: 1px solid var(--glass-border);
            border-radius: var(--radius-lg);
            box-shadow: var(--glass-shadow);
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        /* ══════════════════════════════════════
           MAIN NAV (LEFTMOST)
           ══════════════════════════════════════ */
        .main-nav {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 2rem 0;
            gap: 2rem;
            border-radius: var(--radius-xl);
        }
        .main-nav .avatar {
            margin-bottom: auto;
            width: 48px; height: 48px;
        }
        .main-nav .nav-icons {
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
            flex: 1;
            justify-content: center;
        }
        .main-nav .nav-bottom-icons {
            margin-top: auto;
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
        }
        .nav-icon-btn {
            background: none; border: none;
            color: var(--text-secondary); cursor: pointer;
            padding: 0.75rem; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            transition: all var(--transition-fast);
            position: relative;
        }
        .nav-icon-btn:hover, .nav-icon-btn.active {
            color: var(--text-primary);
            background: var(--bg-hover);
        }
        .nav-icon-btn.active::after {
            content: '';
            position: absolute;
            left: -12px;
            height: 24px;
            width: 4px;
            background: var(--accent);
            border-radius: 0 4px 4px 0;
        }
        .nav-icon-btn svg { width: 24px; height: 24px; }

        /* ══════════════════════════════════════
           SIDEBAR
           ══════════════════════════════════════ */
        .sidebar {
            border-right: none;
            border-radius: var(--radius-xl);
            padding: 1rem 0;
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
            background: var(--glass-bg);
            backdrop-filter: var(--glass-blur);
            -webkit-backdrop-filter: var(--glass-blur);
            color: var(--text-primary);
            border: 1px solid var(--glass-border);
            border-radius: 18px 18px 18px 4px;
            font-size: 0.9rem; line-height: 1.55;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.03);
            position: relative;
            word-wrap: break-word;
            transition: background var(--transition-base);
        }
        .message-row.own .message-bubble {
            background: linear-gradient(135deg, var(--accent), var(--accent-hover));
            color: #fff; border: none;
            border-radius: 18px 18px 4px 18px;
            box-shadow: 0 4px 15px var(--accent-glow);
        }
        .message-bubble:hover { filter: brightness(1.03); }

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

        /* Emoji Picker */
        .emoji-picker { position:absolute; bottom:60px; right:0; width:320px; background:var(--bg-primary); border:1px solid var(--border); border-radius:var(--radius-lg); box-shadow:var(--shadow-lg); z-index:60; padding:0.75rem; display:none; animation:scaleIn 0.2s ease; }
        .emoji-picker.visible { display:block; }
        .emoji-grid { display:grid; grid-template-columns:repeat(8,1fr); gap:2px; max-height:240px; overflow-y:auto; }
        .emoji-btn { background:none; border:none; font-size:1.4rem; padding:0.3rem; cursor:pointer; border-radius:var(--radius-sm); transition:all 0.1s; }
        .emoji-btn:hover { background:var(--bg-tertiary); transform:scale(1.2); }

        /* File Upload */
        .file-upload-btn { background:none; border:none; cursor:pointer; color:var(--text-muted); padding:0.4rem; border-radius:50%; transition:all var(--transition-fast); display:flex; align-items:center; }
        .file-upload-btn:hover { color:var(--accent); background:var(--accent-light); }
        .file-upload-btn svg { width:20px; height:20px; }
        .chat-image { max-width:280px; max-height:200px; border-radius:var(--radius-md); cursor:pointer; transition:transform 0.2s; }
        .chat-image:hover { transform:scale(1.02); }
        .message-image-bubble { padding:0.3rem!important; background:transparent!important; border:none!important; box-shadow:none!important; }
        .file-attachment { display:flex; align-items:center; gap:0.5rem; }
        .file-link { color:inherit; text-decoration:underline; font-size:0.85rem; }
        .msg-link { color:inherit; text-decoration:underline; opacity:0.9; }
        .avatar-img { width:100%; height:100%; border-radius:50%; object-fit:cover; }
        .message-avatar-img { width:30px; height:30px; border-radius:50%; object-fit:cover; flex-shrink:0; margin-top:auto; }

        /* Context Menu */
        .context-menu { position:fixed; background:var(--bg-primary); border:1px solid var(--border); border-radius:var(--radius-md); box-shadow:var(--shadow-lg); z-index:200; min-width:160px; padding:0.35rem; display:none; animation:scaleIn 0.15s ease; }
        .context-menu.visible { display:block; }
        .ctx-btn { display:flex; align-items:center; gap:0.6rem; width:100%; padding:0.5rem 0.75rem; border:none; background:none; color:var(--text-primary); font-size:0.85rem; cursor:pointer; border-radius:var(--radius-sm); transition:background 0.1s; }
        .ctx-btn:hover { background:var(--bg-hover); }
        .ctx-danger { color:var(--error); }
        .ctx-divider { border:none; border-top:1px solid var(--border); margin:0.25rem 0; }

        /* Quick React Bar */
        .quick-react-bar { position:absolute; top:-2rem; right:0; display:flex; gap:2px; background:var(--bg-primary); border:1px solid var(--border); border-radius:var(--radius-full); padding:0.2rem 0.4rem; box-shadow:var(--shadow-md); animation:scaleIn 0.2s ease; z-index:30; }
        .react-emoji-btn { background:none; border:none; font-size:1.1rem; cursor:pointer; padding:0.15rem 0.25rem; border-radius:var(--radius-sm); transition:transform 0.1s; }
        .react-emoji-btn:hover { transform:scale(1.3); }
        .reactions { display:flex; flex-wrap:wrap; gap:3px; margin-top:0.2rem; }
        .reaction-badge { font-size:0.8rem; background:var(--bg-tertiary); padding:0.1rem 0.35rem; border-radius:var(--radius-full); cursor:default; }

        /* Profile Modal */
        .profile-modal { position:fixed; inset:0; background:rgba(0,0,0,0.4); backdrop-filter:blur(4px); z-index:150; display:none; align-items:center; justify-content:center; }
        .profile-modal.active { display:flex; }
        .profile-modal-content { background:var(--bg-primary); border-radius:var(--radius-lg); padding:2rem; width:90%; max-width:420px; box-shadow:var(--shadow-lg); animation:scaleIn 0.3s ease; }
        .avatar-upload-area { width:90px; height:90px; border-radius:50%; background:var(--bg-tertiary); border:2px dashed var(--border); display:flex; align-items:center; justify-content:center; margin:0 auto 1rem; cursor:pointer; overflow:hidden; transition:border-color 0.2s; }
        .avatar-upload-area:hover { border-color:var(--accent); }
        .avatar-preview-img { width:100%; height:100%; object-fit:cover; border-radius:50%; }

        /* Call Modal */
        .call-modal { position:fixed; inset:0; background:rgba(0,0,0,0.7); backdrop-filter:blur(8px); z-index:200; display:none; align-items:center; justify-content:center; }
        .call-modal.active { display:flex; }
        .call-modal-content { background:var(--bg-primary); border-radius:var(--radius-xl); padding:2.5rem; text-align:center; width:90%; max-width:360px; box-shadow:var(--shadow-lg); animation:scaleIn 0.3s ease; }
        .call-avatar { width:80px; height:80px; border-radius:50%; background:linear-gradient(135deg,var(--accent),var(--accent-hover)); display:flex; align-items:center; justify-content:center; font-size:2rem; color:#fff; font-weight:700; margin:0 auto 1rem; animation:float 2s ease-in-out infinite; }
        .call-actions { display:flex; justify-content:center; gap:1rem; margin-top:1.5rem; }
        .call-btn { width:56px; height:56px; border-radius:50%; border:none; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:transform 0.2s; }
        .call-btn:hover { transform:scale(1.1); }
        .call-btn.accept { background:var(--success); color:#fff; }
        .call-btn.decline { background:var(--error); color:#fff; }
        .call-btn svg { width:24px; height:24px; }

        /* Room Info Panel */
        .room-info-panel { position:absolute; top:0; right:0; bottom:0; width:320px; background:var(--bg-primary); border-left:1px solid var(--border); z-index:50; transform:translateX(100%); transition:transform var(--transition-slow); overflow-y:auto; box-shadow:var(--shadow-lg); }
        .room-info-panel.visible { transform:translateX(0); }
        .room-info-header { padding:1rem 1.25rem; border-bottom:1px solid var(--border); display:flex; align-items:center; justify-content:space-between; }
        .room-info-body { padding:1rem 1.25rem; }
        .member-list-item { display:flex; align-items:center; gap:0.75rem; padding:0.5rem 0; }

        /* Member Pills */
        .member-pill { display:inline-flex; align-items:center; gap:0.3rem; background:var(--accent-light); color:var(--accent); padding:0.25rem 0.6rem; border-radius:var(--radius-full); font-size:0.8rem; font-weight:500; }
        .pill-remove { background:none; border:none; color:var(--accent); cursor:pointer; font-size:1rem; padding:0; margin-left:0.2rem; }
        .modal-member-results { max-height:150px; overflow-y:auto; }
        .member-result { display:flex; align-items:center; gap:0.6rem; padding:0.45rem 0.5rem; cursor:pointer; border-radius:var(--radius-sm); transition:background 0.1s; }
        .member-result:hover { background:var(--bg-hover); }
        #selected-members { display:flex; flex-wrap:wrap; gap:0.35rem; margin-bottom:0.5rem; min-height:0; }

        /* Message Search Bar */
        .msg-search-bar { display:none; padding:0.5rem 1.5rem; border-bottom:1px solid var(--border); background:var(--bg-primary); }
        .msg-search-bar.visible { display:flex; align-items:center; gap:0.5rem; }
        .msg-search-bar input { flex:1; padding:0.45rem 0.75rem; border:1px solid var(--border); border-radius:var(--radius-md); background:var(--bg-input); color:var(--text-primary); font-size:0.85rem; font-family:inherit; }
        .msg-search-bar input:focus { outline:none; border-color:var(--accent); }
        .message-bubble.highlight { box-shadow:0 0 0 2px var(--accent), 0 0 12px var(--accent-glow); }

        /* Misc */
        .message-row { position:relative; }
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
    <!-- ── Main Nav Column ── -->
    <nav class="main-nav glass-card">
        <div class="avatar" id="sidebar-user-avatar">
            <c:choose>
                <c:when test="${currentUser != null && currentUser.avatar != null}">
                    <img src="${currentUser.avatar}" alt="" class="avatar-img">
                </c:when>
                <c:otherwise>
                    ${currentUser != null ? currentUser.username.substring(0, 1).toUpperCase() : '?'}
                </c:otherwise>
            </c:choose>
            <span class="online-dot active"></span>
        </div>
        
        <div class="nav-icons">
            <a href="${pageContext.request.contextPath}/" class="nav-icon-btn" title="Home">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                </svg>
            </a>
            <button class="nav-icon-btn active" title="Messages">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                </svg>
            </button>
            <button class="nav-icon-btn" title="Notifications" id="mute-toggle">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"/>
                </svg>
            </button>
            <button class="nav-icon-btn" title="Theme Toggle" id="theme-toggle">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" id="theme-icon">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
                </svg>
            </button>
            <button class="nav-icon-btn" title="Profile Settings" id="profile-settings-btn">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
            </button>
        </div>
        
        <div class="nav-bottom-icons">
            <a href="${pageContext.request.contextPath}/auth/logout" class="nav-icon-btn" title="Sign out">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
            </a>
        </div>
    </nav>

    <!-- ── Sidebar Column ── -->
    <aside class="sidebar glass-card" id="sidebar">
        <header class="sidebar-header" style="padding-top:0.5rem;">
            <div class="search-box" style="flex:1;">
                <input type="text" id="user-search" placeholder="Search people..." autocomplete="off" style="width:100%;">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </div>
            <button class="nav-icon-btn" title="New Chat" id="new-room-btn" style="margin-left:0.5rem; flex-shrink:0;">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
            </button>
        </header>

        <div class="search-container" style="padding:0;">
            <div id="search-results" class="search-results"></div>
        </div>

        <div class="sidebar-content">
            <div class="section-title">Conversations</div>
            <div id="room-list" class="room-list">
                <c:forEach var="room" items="${rooms}">
                    <a href="javascript:void(0)"
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
    </aside>

    <!-- ── Main Chat Area ── -->
    <main class="chat-main glass-card">
        <!-- Active Chat State -->
        <div id="active-chat-state" style="display: ${currentRoom != null ? 'flex' : 'none'}; flex-direction: column; height: 100%;">
            <header class="chat-header">
                <div class="chat-header-info">
                    <button class="icon-btn mobile-menu-btn" id="mobile-menu-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                        </svg>
                    </button>
                    <div class="avatar avatar-lg" id="current-room-avatar">
                        ${currentRoom != null ? currentRoom.name.substring(0, 1).toUpperCase() : '?'}
                        <span class="online-dot" id="header-online-dot"></span>
                    </div>
                    <div>
                        <h2 id="current-room-name">${currentRoom != null ? currentRoom.name : ''}</h2>
                        <div class="header-status" id="header-status">
                            <span class="status-dot" id="header-status-dot"></span>
                            <span id="header-status-text">Offline</span>
                        </div>
                    </div>
                </div>
                <div class="chat-actions">
                    <button class="icon-btn" title="Search Messages" id="msg-search-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                        </svg>
                    </button>
                    <button class="icon-btn" title="Audio Call" id="audio-call-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                        </svg>
                    </button>
                    <button class="icon-btn" title="Room Info" id="room-info-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                    </button>
                </div>
            </header>

                <!-- Message Search Bar -->
                <div class="msg-search-bar" id="msg-search-bar">
                    <input type="text" id="msg-search-input" placeholder="Search in this chat..." autocomplete="off">
                    <button class="icon-btn" id="msg-search-close" title="Close">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>

                <div class="messages-container" id="messages-container">
                    <div class="messages" id="messages">
                        <c:forEach var="msg" items="${messages}">
                            <div class="message-row ${msg.sender.id == currentUser.id ? 'own' : ''}" data-message-id="${msg.id}" data-sender-id="${msg.sender.id}">
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

                <div class="input-area" style="position:relative;">
                    <form class="input-form" id="message-form">
                        <input type="hidden" id="current-room-id" value="${currentRoom.id}">
                        <button type="button" class="file-upload-btn" id="file-upload-btn" title="Attach file">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"/>
                            </svg>
                        </button>
                        <input type="file" id="file-upload-input" style="display:none;">
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
                    <div class="emoji-picker" id="emoji-picker"></div>
                </div>
                <div class="empty-state" id="empty-state" style="display: ${currentRoom == null ? 'flex' : 'none'};">
                    <header class="chat-header" style="border-bottom: none; width: 100%;">
                        <div class="chat-header-info">
                            <button class="icon-btn mobile-menu-btn" id="mobile-menu-btn-empty">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                                </svg>
                            </button>
                        </div>
                    </header>
                    <div style="flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; width:100%;">
                        <div class="empty-icon-wrap">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                            </svg>
                        </div>
                        <h3>Start a conversation</h3>
                        <p>Select a chat or search for someone to begin messaging.</p>
                    </div>
                </div>
    </main>
</div>

<!-- Create Room Modal (Enhanced) -->
<div class="modal-overlay" id="room-modal">
    <div class="modal">
        <h3>Create New Group</h3>
        <input type="text" id="room-name-input" placeholder="Group name..." autofocus>
        <input type="text" id="room-desc-input" placeholder="Description (optional)..." style="margin-top:0.5rem;">
        <div style="margin-top:0.75rem;">
            <label style="font-size:0.8rem;color:var(--text-secondary);display:block;margin-bottom:0.35rem;">Add Members</label>
            <div id="selected-members"></div>
            <input type="text" id="modal-member-search" placeholder="Search users..." style="margin-top:0.25rem;">
            <div id="modal-member-results" class="modal-member-results"></div>
        </div>
        <div class="modal-actions">
            <button class="btn-modal secondary" id="modal-cancel">Cancel</button>
            <button class="btn-modal primary" id="modal-create">Create</button>
        </div>
    </div>
</div>

<!-- Profile Modal -->
<div class="profile-modal" id="profile-modal">
    <div class="profile-modal-content">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem;">
            <h3 style="margin:0;">Profile Settings</h3>
            <button class="icon-btn" id="profile-modal-close">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" style="width:20px;height:20px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        </div>
        <form id="profile-form" enctype="multipart/form-data">
            <label for="avatar-file-input" class="avatar-upload-area" id="avatar-preview">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" style="width:32px;height:32px;color:var(--text-muted);"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/><circle cx="12" cy="13" r="3" stroke="currentColor" stroke-width="2"/></svg>
            </label>
            <input type="file" name="avatar" id="avatar-file-input" accept="image/*" style="display:none;">
            <p style="text-align:center;font-size:0.75rem;color:var(--text-muted);margin-bottom:1rem;">Click to upload photo</p>
            <label style="font-size:0.8rem;color:var(--text-secondary);display:block;margin-bottom:0.25rem;">Bio / Status</label>
            <input type="text" name="bio" id="profile-bio-input" placeholder="What's on your mind?" maxlength="255">
            <button type="submit" class="btn-modal primary" style="width:100%;margin-top:1rem;">Save Changes</button>
        </form>
    </div>
</div>

<!-- Call Modal -->
<div class="call-modal" id="call-modal">
    <div class="call-modal-content">
        <div class="call-avatar">📞</div>
        <h3 id="call-status">Calling...</h3>
        <div class="call-actions">
            <button class="call-btn accept" id="accept-call-btn" style="display:none;">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
            </button>
            <button class="call-btn decline" id="end-call-btn">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" style="transform:rotate(135deg);"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
            </button>
            <button class="call-btn decline" id="decline-call-btn" style="display:none;">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        </div>
    </div>
</div>
<audio id="remote-audio" autoplay></audio>

<!-- Context Menu -->
<div class="context-menu" id="context-menu"></div>

<!-- Room Info Panel (inside chat main) -->
<div class="room-info-panel" id="room-info-panel">
    <div class="room-info-header">
        <h4 style="margin:0;">Room Info</h4>
        <button class="icon-btn" id="room-info-close">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
    </div>
    <div class="room-info-body">
        <c:if test="${currentRoom != null}">
            <div style="text-align:center;margin-bottom:1rem;">
                <div class="avatar avatar-lg" style="margin:0 auto 0.5rem;width:64px;height:64px;font-size:1.5rem;">${currentRoom.name.substring(0, 1).toUpperCase()}</div>
                <h3 style="margin:0 0 0.25rem;">${currentRoom.name}</h3>
                <p style="font-size:0.8rem;color:var(--text-muted);margin:0;">${currentRoom.type == 'GROUP' ? 'Group Chat' : 'Direct Message'}</p>
            </div>
        </c:if>
    </div>
</div>

<!-- Toast Container -->
<div id="toast-container" style="position:fixed;top:1rem;right:1rem;z-index:300;display:flex;flex-direction:column;gap:0.5rem;pointer-events:none;">
</div>

<!-- Connection Status Bar -->
<div class="connection-bar" id="connection-bar" style="position:fixed;top:0;left:0;right:0;z-index:400;text-align:center;padding:0.3rem;font-size:0.75rem;font-weight:500;display:flex;align-items:center;justify-content:center;gap:0.5rem;transition:all 0.3s ease;transform:translateY(-100%);">
    <div id="conn-spinner" style="width:12px;height:12px;border:2px solid currentColor;border-top:2px solid transparent;border-radius:50%;animation:spin 1s linear infinite;display:none;"></div>
    <span id="conn-text"></span>
</div>
<style>
    .connection-bar.visible { transform:translateY(0); }
    .connection-bar.online { background:var(--success); color:#fff; }
    .connection-bar.reconnecting { background:#f59e0b; color:#fff; }
    .connection-bar.offline { background:var(--error); color:#fff; }
    @keyframes spin { to { transform:rotate(360deg); } }
    .toast { pointer-events:all; display:flex; align-items:center; gap:0.75rem; background:var(--bg-primary); border:1px solid var(--border); border-radius:var(--radius-md); padding:0.75rem 1rem; box-shadow:var(--shadow-lg); cursor:pointer; animation:slideIn 0.3s ease; max-width:320px; }
    .toast.removing { animation:slideOut 0.3s ease; opacity:0; }
    .toast-icon svg { width:20px; height:20px; color:var(--accent); }
    @keyframes slideIn { from { transform:translateX(100%); opacity:0; } to { transform:translateX(0); opacity:1; } }
    @keyframes slideOut { from { opacity:1; } to { opacity:0; transform:translateX(100%); } }
</style>

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