<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%
    if (session.getAttribute("csrfToken") == null) {
        session.setAttribute("csrfToken", com.tuganire.util.CsrfUtil.generateToken());
    }
%>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tuganire</title>
    <link rel="stylesheet" href="<c:url value='/css/style.css'/>">
</head>
<body class="auth-page">
    <main class="auth-card">
        <h1>Tuganire</h1>
        <p class="tagline">Let's Talk</p>
        <form action="${pageContext.request.contextPath}/auth/register" method="post" class="auth-form">
            <input type="hidden" name="csrf" value="<%= session.getAttribute("csrfToken") %>">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" required minlength="3" autofocus>
            </div>
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" required>
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required minlength="6">
            </div>
            <c:if test="${param.error == 'register_failed'}">
                <p class="error-msg">Registration failed. Username or email may already exist.</p>
            </c:if>
            <c:if test="${param.error == 'invalid_csrf'}">
                <p class="error-msg">Session expired. Please try again.</p>
            </c:if>
            <button type="submit" class="btn btn-primary">Create Account</button>
        </form>
        <p class="auth-footer">Already have an account? <a href="${pageContext.request.contextPath}/views/login.jsp">Sign In</a></p>
    </main>
</body>
</html>
