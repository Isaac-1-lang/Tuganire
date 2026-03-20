<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib uri="jakarta.tags.core" prefix="c" %>
        <% if (session.getAttribute("csrfToken")==null) { session.setAttribute("csrfToken",
            com.tuganire.util.CsrfUtil.generateToken()); } %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Tuganire  Fungura Konti</title>
                <link rel="icon" href="<c:url value='/static/logo.png'/>">
                <link rel="preconnect" href="https://fonts.googleapis.com">
                <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
                    rel="stylesheet">

                <style>
                    :root {
                        --bg-gradient-1: #0f172a;
                        --bg-gradient-2: #020617;
                        --bg-gradient-3: #1e1b4b;
                        --accent: #38bdf8;
                        --accent-hover: #0284c7;
                        --glass-bg: rgba(255, 255, 255, 0.05);
                        --glass-blur: blur(25px);
                        --glass-border: rgba(255, 255, 255, 0.1);
                        --text-primary: #ffffff;
                        --text-secondary: #94a3b8;
                        --input-bg: rgba(255, 255, 255, 0.06);
                        --input-border: rgba(255, 255, 255, 0.15);
                    }

                    body {
                        font-family: 'Inter', system-ui, -apple-system, sans-serif;
                        background: linear-gradient(135deg, var(--bg-gradient-1), var(--bg-gradient-2), var(--bg-gradient-3));
                        background-size: 400% 400%;
                        animation: gradientBG 15s ease infinite;
                        color: var(--text-primary);
                        line-height: 1.6;
                        min-height: 100vh;
                        display: flex;
                        padding: 1.25rem;
                    }

                    @keyframes gradientBG {
                        0% { background-position: 0% 50%; }
                        50% { background-position: 100% 50%; }
                        100% { background-position: 0% 50%; }
                    }

                    /* ── Split Layout ── */
                    .auth-wrapper {
                        display: grid;
                        grid-template-columns: 1fr 1fr;
                        min-height: calc(100vh - 2.5rem);
                        width: 100%;
                        border-radius: 20px;
                        overflow: hidden;
                        box-shadow: 0 8px 40px rgba(0, 0, 0, 0.3);
                        background: transparent;
                        border: 1px solid var(--glass-border);
                    }

                    /* ── Left: Form Side ── */
                    .auth-left {
                        display: flex;
                        flex-direction: column;
                        justify-content: center;
                        padding: 3rem 4rem;
                        position: relative;
                        background: var(--glass-bg);
                        backdrop-filter: var(--glass-blur);
                        -webkit-backdrop-filter: var(--glass-blur);
                        border-right: 1px solid var(--glass-border);
                    }

                    .brand {
                        position: absolute;
                        top: 2rem;
                        left: 4rem;
                        display: flex;
                        align-items: center;
                        gap: 0.6rem;
                        font-weight: 700;
                        font-size: 1.15rem;
                        color: var(--text-primary);
                        text-decoration: none;
                        letter-spacing: -0.02em;
                    }

                    .brand-logo {
                        height: 50px;
                        width: auto;
                        object-fit: contain;
                    }

                    .auth-content {
                        max-width: 360px;
                        width: 100%;
                        margin-top: 2rem;
                    }

                    .auth-content h1 {
                        font-size: 2rem;
                        font-weight: 700;
                        color: var(--text-primary);
                        margin-bottom: 0.5rem;
                        letter-spacing: -0.02em;
                    }

                    .auth-subtitle {
                        color: var(--text-secondary);
                        font-size: 0.95rem;
                        margin-bottom: 1.5rem;
                    }

                    /* ── Form Styles ── */
                    .auth-form .form-group {
                        margin-bottom: 1.25rem;
                    }

                    .auth-form label {
                        display: block;
                        font-size: 0.875rem;
                        font-weight: 500;
                        color: var(--text-secondary);
                        margin-bottom: 0.5rem;
                    }

                    .auth-form input[type="text"],
                    .auth-form input[type="password"],
                    .auth-form input[type="email"] {
                        width: 100%;
                        padding: 0.75rem 1rem;
                        border: 1px solid var(--input-border);
                        border-radius: 12px;
                        background: var(--input-bg);
                        color: var(--text-primary);
                        font-size: 0.95rem;
                        font-family: 'Inter', sans-serif;
                        transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
                    }

                    .auth-form input:focus {
                        outline: none;
                        border-color: var(--accent);
                        background: rgba(255, 255, 255, 0.1);
                        box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.15);
                    }

                    .auth-form input::placeholder {
                        color: #64748b;
                    }

                    /* ── Password strength hint ── */
                    .field-hint {
                        font-size: 0.78rem;
                        color: rgba(255, 255, 255, 0.4);
                        margin-top: 0.4rem;
                    }

                    /* ── Buttons ── */
                    .btn-primary {
                        width: 100%;
                        padding: 0.85rem 1.5rem;
                        background: linear-gradient(135deg, var(--accent), var(--accent-hover));
                        color: #ffffff;
                        border: none;
                        border-radius: 12px;
                        font-size: 0.95rem;
                        font-weight: 600;
                        font-family: 'Inter', sans-serif;
                        cursor: pointer;
                        margin-top: 0.5rem;
                        transition: filter 0.2s, transform 0.1s, box-shadow 0.2s;
                        box-shadow: 0 4px 14px rgba(2, 132, 199, 0.3);
                    }

                    .btn-primary:hover {
                        filter: brightness(1.1);
                        box-shadow: 0 4px 18px rgba(2, 132, 199, 0.45);
                    }

                    .btn-primary:active {
                        transform: scale(0.98);
                    }

                    /* ── Error Message ── */
                    .error-msg {
                        background: rgba(220, 38, 38, 0.15);
                        color: #fca5a5;
                        font-size: 0.85rem;
                        padding: 0.6rem 0.875rem;
                        border-radius: 8px;
                        margin-bottom: 1.25rem;
                        border: 1px solid rgba(220, 38, 38, 0.3);
                    }

                    /* ── Footer ── */
                    .auth-footer {
                        text-align: center;
                        margin-top: 1.5rem;
                        font-size: 0.9rem;
                        color: var(--text-secondary);
                    }

                    .auth-footer a {
                        color: var(--accent);
                        text-decoration: none;
                        font-weight: 600;
                    }

                    .auth-footer a:hover {
                        text-decoration: underline;
                    }

                    .copyright {
                        position: absolute;
                        bottom: 2rem;
                        left: 4rem;
                        font-size: 0.8rem;
                        color: var(--text-secondary);
                    }

                    /* ── Right: Spline Side ── */
                    .auth-right {
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        position: relative;
                        overflow: hidden;
                    }

                    .auth-right iframe {
                        width: 100%;
                        height: 100%;
                        border: none;
                        opacity: 0.95;
                    }

                    /* ── Responsive ── */
                    @media (max-width: 1024px) {
                        .auth-wrapper {
                            grid-template-columns: 1fr;
                        }

                        .auth-right {
                            display: none;
                        }

                        .auth-left {
                            padding: 2rem;
                            align-items: center;
                        }

                        .brand {
                            left: 2rem;
                        }

                        .copyright {
                            left: 2rem;
                        }
                    }

                    @media (max-width: 480px) {
                        .auth-left {
                            padding: 1.5rem;
                        }

                        .brand {
                            left: 1.5rem;
                            top: 1.5rem;
                        }

                        .copyright {
                            left: 1.5rem;
                            bottom: 1.5rem;
                        }
                    }

                    /* ── Fade in animation ── */
                    @keyframes fadeUp {
                        from {
                            opacity: 0;
                            transform: translateY(16px);
                        }

                        to {
                            opacity: 1;
                            transform: translateY(0);
                        }
                    }

                    .auth-content {
                        animation: fadeUp 0.5s ease-out;
                    }
                </style>
            </head>

            <body>
                <div class="auth-wrapper">
                    <!-- Left Side: Register Form -->
                    <div class="auth-left">
                        <a href="${pageContext.request.contextPath}/" class="brand">
                            <img src="${pageContext.request.contextPath}/static/logo.png" alt="Tuganire"
                                class="brand-logo">
                            Tuganire
                        </a>

                        <div class="auth-content">
                            <h1>Create an account</h1>
                            <p class="auth-subtitle">Join Tuganire and start chatting with your friends.</p>

                            <c:if test="${param.error == 'register_failed'}">
                                <p class="error-msg">Registration failed. Username or email may already exist.</p>
                            </c:if>
                            <c:if test="${param.error == 'invalid_csrf'}">
                                <p class="error-msg">Session expired. Please try again.</p>
                            </c:if>

                            <form action="${pageContext.request.contextPath}/auth/register" method="post"
                                class="auth-form">
                                <input type="hidden" name="csrf" value="<%= session.getAttribute("csrfToken") %>">

                                <div class="form-group">
                                    <label for="username">Username</label>
                                    <input type="text" id="username" name="username" placeholder="Choose a username"
                                        required minlength="3" autofocus>
                                </div>

                                <div class="form-group">
                                    <label for="email">Email</label>
                                    <input type="email" id="email" name="email" placeholder="Enter your email" required>
                                </div>

                                <div class="form-group">
                                    <label for="password">Password</label>
                                    <input type="password" id="password" name="password" placeholder="Create a password"
                                        required minlength="6">
                                    <p class="field-hint">Must be at least 6 characters</p>
                                </div>

                                <button type="submit" class="btn-primary">Create account</button>
                            </form>

                            <p class="auth-footer">Already have an account? <a
                                    href="${pageContext.request.contextPath}/views/login.jsp">Sign in</a></p>
                        </div>

                        <p class="copyright">&copy; Tuganire <%= java.time.Year.now().getValue() %>
                        </p>
                    </div>

                    <!-- Right Side: Spline 3D Model -->
                    <div class="auth-right">
                        <iframe src="https://my.spline.design/3dcubes-5i3n1Ga668A5YE7BgJq9qfop/" loading="lazy"
                            title="3D Interactive Model" allow="autoplay">
                        </iframe>
                    </div>
                </div>
            </body>

            </html>