<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<jsp:include page="sidebar.jsp" />

<!-- ═══════════ MAIN ═══════════ -->
<div class="main">

  <!-- TOPBAR -->
  <div class="topbar">
    <div style="display:flex;align-items:center;gap:12px">
      <button onclick="document.getElementById('sidebar').classList.toggle('open')" style="display:none;background:none;border:none;font-size:20px;cursor:pointer" id="menu-toggle">☰</button>
      <span class="topbar-title">${pageTitle}</span>
    </div>
    <span class="topbar-path">${pageName}</span>
    <div class="topbar-right">
      <button class="topbar-btn btn-ghost" onclick="location.reload()">↻ 새로고침</button>
      <a href="${pageContext.request.contextPath}/" class="topbar-btn btn-ghost">← 사이트로</a>
    </div>
  </div>

  <div class="content">
