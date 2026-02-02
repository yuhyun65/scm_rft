<%@ page import="Common.classes.setValue"%>
<%
	String[] pageURL = request.getRequestURL().toString().split("/printConfig");
	String installURL = pageURL[0] ;
	setValue value = new setValue();
%>
<?xml version="1.0" encoding="utf-8"?>
<root>
	<content name="<%=value.pjtName%>_VB6KO" ver="1.0" url="<%=installURL%>/lotPrint/VB6KO.DLL" target="C:\ComMate\<%=value.pjtName%>" type="regsvr32"/>
	<content name="<%=value.pjtName%>_lotPrint" ver="2.0" url="<%=installURL%>/lotPrint/lotPrint.exe" target="C:\ComMate\<%=value.pjtName%>" type="copy"/>
</root>