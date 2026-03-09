<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <%@ taglib uri="jakarta.tags.core" prefix="c" %>
        <% String redirect=request.getParameter("redirect"); if (redirect==null) redirect="" ; String
            error=request.getParameter("error"); if (error==null) error="" ; if
            (session.getAttribute("csrfToken")==null) { session.setAttribute("csrfToken",
            com.tuganire.util.CsrfUtil.generateToken()); } %>
            <!DOCTYPE html>
            <html lang="en">

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Tuganire  Injira </title>
                <link rel="preconnect" href="https://fonts.googleapis.com">
                <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
                    rel="stylesheet">
                <style>
                    *,
                    *::before,
                    *::after {
                        box-sizing: border-box;
                        margin: 0;
                        padding: 0;
                    }

                    body {
                        font-family: 'Inter', system-ui, -apple-system, sans-serif;
                        background: #f0f0f5;
                        color: #0f172a;
                        line-height: 1.6;
                        min-height: 100vh;
                        display: flex;
                        padding: 1.25rem;
                    }

                    /* ── Split Layout ── */
                    .auth-wrapper {
                        display: grid;
                        grid-template-columns: 1fr 1fr;
                        min-height: calc(100vh - 2.5rem);
                        width: 100%;
                        border-radius: 20px;
                        overflow: hidden;
                        box-shadow: 0 8px 40px rgba(0, 0, 0, 0.08);
                        background: #ffffff;
                    }

                    /* ── Left: Form Side ── */
                    .auth-left {
                        display: flex;
                        flex-direction: column;
                        justify-content: center;
                        padding: 3rem 4rem;
                        position: relative;
                        background: #ffffff;
                    }

                    .brand {
                        position: absolute;
                        top: 2rem;
                        left: 4rem;
                        display: flex;
                        align-items: center;
                        gap: 0.6rem;
                        font-weight: 700;
                        font-size: 1rem;
                        color: #0f172a;
                        text-decoration: none;
                    }

                    .brand-logo {
                        height: 50px;
                        width: auto;
                        object-fit: contain;
                    }

                    .brand-dot {
                        width: 10px;
                        height: 10px;
                        background: #0f1422;
                        border-radius: 50%;
                    }

                    .auth-content {
                        max-width: 360px;
                        width: 100%;
                    }

                    .auth-content h1 {
                        font-size: 2rem;
                        font-weight: 700;
                        color: #0f172a;
                        margin-bottom: 0.5rem;
                        letter-spacing: -0.02em;
                    }

                    .auth-subtitle {
                        color: #64748b;
                        font-size: 0.95rem;
                        margin-bottom: 2rem;
                    }

                    /* ── Form Styles ── */
                    .auth-form .form-group {
                        margin-bottom: 1.25rem;
                    }

                    .auth-form label {
                        display: block;
                        font-size: 0.875rem;
                        font-weight: 500;
                        color: #344155;
                        margin-bottom: 0.4rem;
                    }

                    .auth-form input[type="text"],
                    .auth-form input[type="password"],
                    .auth-form input[type="email"] {
                        width: 100%;
                        padding: 0.65rem 0.875rem;
                        border: 1px solid #d1d5db;
                        border-radius: 8px;
                        background: #ffffff;
                        color: #0f172a;
                        font-size: 0.95rem;
                        font-family: 'Inter', sans-serif;
                        transition: border-color 0.2s, box-shadow 0.2s;
                    }

                    .auth-form input:focus {
                        outline: none;
                        border-color: #0f1422;
                        box-shadow: 0 0 0 3px rgba(15, 20, 34, 0.12);
                    }

                    .auth-form input::placeholder {
                        color: #9ca3af;
                    }

                    .form-options {
                        display: flex;
                        align-items: center;
                        justify-content: space-between;
                        margin-bottom: 1.5rem;
                        font-size: 0.85rem;
                    }

                    .remember-me {
                        display: flex;
                        align-items: center;
                        gap: 0.4rem;
                        color: #344155;
                        cursor: pointer;
                    }

                    .remember-me input[type="checkbox"] {
                        width: 16px;
                        height: 16px;
                        accent-color: #0f1422;
                        cursor: pointer;
                    }

                    .forgot-link {
                        color: #0f1422;
                        text-decoration: none;
                        font-weight: 500;
                        transition: color 0.2s;
                    }

                    .forgot-link:hover {
                        color: #1e293b;
                    }

                    /* ── Buttons ── */
                    .btn-primary {
                        width: 100%;
                        padding: 0.75rem 1.5rem;
                        background: #0f1422;
                        color: #ffffff;
                        border: none;
                        border-radius: 8px;
                        font-size: 0.95rem;
                        font-weight: 600;
                        font-family: 'Inter', sans-serif;
                        cursor: pointer;
                        transition: background 0.2s, transform 0.1s, box-shadow 0.2s;
                    }

                    .btn-primary:hover {
                        background: #1e293b;
                        box-shadow: 0 4px 14px rgba(15, 20, 34, 0.25);
                    }

                    .btn-primary:active {
                        transform: scale(0.98);
                    }

                    /* ── Error Message ── */
                    .error-msg {
                        background: #fef2f2;
                        color: #dc2626;
                        font-size: 0.85rem;
                        padding: 0.6rem 0.875rem;
                        border-radius: 8px;
                        margin-bottom: 1rem;
                        border: 1px solid #fecaca;
                    }

                    /* ── Divider ── */
                    .divider {
                        display: flex;
                        align-items: center;
                        gap: 1rem;
                        margin: 1.5rem 0;
                        color: #9ca3af;
                        font-size: 0.8rem;
                    }

                    .divider::before,
                    .divider::after {
                        content: '';
                        flex: 1;
                        height: 1px;
                        background: #e5e7eb;
                    }

                    /* ── Footer ── */
                    .auth-footer {
                        text-align: center;
                        margin-top: 1.5rem;
                        font-size: 0.9rem;
                        color: #64748b;
                    }

                    .auth-footer a {
                        color: #0f1422;
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
                        color: #94a3b8;
                    }

                    /* ── Right: Spline Side ── */
                    .auth-right {
                        background: #0f1422;
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
                    <!-- Left Side: Login Form -->
                    <div class="auth-left">
                        <a href="${pageContext.request.contextPath}/" class="brand">
                            <img src="${pageContext.request.contextPath}/static/logo.png" alt="Tuganire"
                                class="brand-logo">
                            Tuganire
                        </a>

                        <div class="auth-content">
                            <h1>Welcome back</h1>
                            <p class="auth-subtitle">Welcome back! Please enter your details.</p>

                            <c:if test="${param.error == 'invalid_credentials'}">
                                <p class="error-msg">Invalid username or password. Please try again.</p>
                            </c:if>
                            <c:if test="${param.error == 'invalid_csrf'}">
                                <p class="error-msg">Session expired. Please try again.</p>
                            </c:if>

                            <form action="${pageContext.request.contextPath}/auth/login" method="post"
                                class="auth-form">
                                <input type="hidden" name="csrf" value="<%= session.getAttribute("csrfToken") %>">
                                <% if (!redirect.isEmpty()) { %>
                                    <input type="hidden" name="redirect"
                                        value="<%= java.net.URLEncoder.encode(redirect, "UTF-8") %>">
                                    <% } %>

                                        <div class="form-group">
                                            <label for="username">Username or Email</label>
                                            <input type="text" id="username" name="username"
                                                placeholder="Enter your username or email" required autofocus>
                                        </div>

                                        <div class="form-group">
                                            <label for="password">Password</label>
                                            <input type="password" id="password" name="password"
                                                placeholder="Enter your password" required>
                                        </div>

                                        <button type="submit" class="btn-primary">Sign in</button>
                            </form>

                            <p class="auth-footer">Don't have an account? <a
                                    href="${pageContext.request.contextPath}/views/register.jsp">Sign up</a></p>
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