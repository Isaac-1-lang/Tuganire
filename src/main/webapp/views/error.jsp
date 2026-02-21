<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error — Tuganire</title>
    <link rel="stylesheet" href="<c:url value='/css/style.css'/>">
</head>
<body class="auth-page">
    <main class="auth-card">
        <h1>Something went wrong</h1>
        <p class="error-msg">${not empty param.message ? param.message : 'An error occurred. Please try again.'}</p>
        <a href="${pageContext.request.contextPath}/views/login.jsp" class="btn btn-primary">Back to Login</a>
    </main>
</body>
</html>
