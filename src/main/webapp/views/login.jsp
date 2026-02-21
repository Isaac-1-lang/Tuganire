<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%
    String redirect = request.getParameter("redirect");
    if (redirect == null) redirect = "";
    String error = request.getParameter("error");
    if (error == null) error = "";
    // Generate CSRF token for the session
    if (session.getAttribute("csrfToken") == null) {
        session.setAttribute("csrfToken", com.tuganire.util.CsrfUtil.generateToken());
    }
%>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login — Tuganire</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body class="auth-page">
    <main class="auth-card">
        <h1>Tuganire</h1>
        <p class="tagline">Let's Talk</p>
        <form action="${pageContext.request.contextPath}/auth/login" method="post" class="auth-form">
            <input type="hidden" name="csrf" value="<%= session.getAttribute("csrfToken") %>">
            <% if (!redirect.isEmpty()) { %>
            <input type="hidden" name="redirect" value="<%= java.net.URLEncoder.encode(redirect, "UTF-8") %>">
            <% } %>
            <div class="form-group">
                <label for="username">Username or Email</label>
                <input type="text" id="username" name="username" required autofocus>
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            <c:if test="${param.error == 'invalid_credentials'}">
                <p class="error-msg">Invalid username or password.</p>
            </c:if>
            <c:if test="${param.error == 'invalid_csrf'}">
                <p class="error-msg">Session expired. Please try again.</p>
            </c:if>
            <button type="submit" class="btn btn-primary">Sign In</button>
        </form>
        <p class="auth-footer">Don't have an account? <a href="${pageContext.request.contextPath}/views/register.jsp">Register</a></p>
    </main>
</body>
</html>
