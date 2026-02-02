<%@ page import="Common.classes.setValue"%>
<%
	String getStyleType = request.getParameter("styleType");
	String getStyleVer = request.getParameter("styleVer");
	String getFunctionVer = request.getParameter("functionVer");
	String getInitVer = request.getParameter("initVer");
	String getEventVer = request.getParameter("eventVer");

	String[] pageURL = request.getRequestURL().toString().split("/initConfig");
	String installURL = pageURL[0] ;
	setValue value = new setValue();
%>
<?xml version="1.0" encoding="utf-8"?>
<root>
	<content name="<%=value.pjtName%>_MateStyle" ver="<%=getStyleVer%>" url="<%=installURL%>/style/<%=getStyleType%>/style.css" target="C:\ComMate\<%=value.pjtName%>" type="copy"/>

<!--
	<content name="<%=value.pjtName%>_MateFunction" ver="<%=getFunctionVer%>" url="<%=installURL%>/xrw/function.xrw" target="C:\ComMate\<%=value.pjtName%>" type="copy"/>
	<content name="<%=value.pjtName%>_MateInit" ver="<%=getInitVer%>" url="<%=installURL%>/xrw/init.xrw" target="C:\ComMate\<%=value.pjtName%>" type="copy"/>
	<content name="<%=value.pjtName%>_MateEvent" ver="<%=getEventVer%>" url="<%=installURL%>/xrw/event.xrw" target="C:\ComMate\<%=value.pjtName%>" type="copy"/>
-->

</root>