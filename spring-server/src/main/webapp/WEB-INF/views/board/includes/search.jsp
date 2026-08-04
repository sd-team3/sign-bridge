<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<form action="/board/search" method="get">
    <div class="search-row">
        <input type="text" name="keyword" class="search-field" value="${keyword}" placeholder="게시글 검색...">
        <button type="submit" class="btn btn-primary btn-sm">검색</button>
    </div>
</form>