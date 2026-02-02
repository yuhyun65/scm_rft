<?xml version="1.0" encoding="utf-8"?>
<%@ page import="java.io.*,java.lang.*,java.util.*,java.sql.*,java.util.Date"%>
<%@ page import="Common.Config"%>
<%
	String[] pageURL = request.getRequestURL().toString().split("/install");
	String installURL = pageURL[0] ;

	Date d = new Date();
	long activeVer = 0;
	activeVer = d.getTime();
%>
<root>
	<content name="ComMate_TFViewer" ver="4.069" url="<%=installURL%>/install/view/nprw.dll" target="C:\ComMate\<%=Config.pjtName%>" type="reg"/>

	<content name="<%=Config.pjtName%>_TFReport" ver="1.118" url="<%=installURL%>/install/view/TFReport.dll" target="C:\ComMate\<%=Config.pjtName%>" type="reg"/>
	<content name="<%=Config.pjtName%>_TFExcel" ver="2.515" url="<%=installURL%>/install/excel/TFExcel.dll" target="C:\ComMate\<%=Config.pjtName%>" type="reg"/>
	<content name="<%=Config.pjtName%>_msvbvm60" ver="6.098" url="<%=installURL%>/install/excel/msvbvm60.dll" target="C:\ComMate\<%=Config.pjtName%>" type="reg"/>
	<content name="<%=Config.pjtName%>_rnxlc50" ver="5.001" url="<%=installURL%>/install/excel/rnxlc50.dll" target="C:\ComMate\<%=Config.pjtName%>" type="reg"/>
	<content name="<%=Config.pjtName%>_MateMDB" ver="2.2" url="<%=installURL%>/install/mdb/mate.mdb" target="C:\ComMate\<%=Config.pjtName%>" type="copy"/>
	<content name="<%=Config.pjtName%>_VB6KO" ver="2.0" url="<%=installURL%>/install/lotPrint/VB6KO.DLL" target="C:\ComMate\<%=Config.pjtName%>" type="regsvr32"/>
	<content name="<%=Config.pjtName%>_lotPrint" ver="2.2" url="<%=installURL%>/install/lotPrint/lotPrint.exe" target="C:\ComMate\<%=Config.pjtName%>" type="copy"/>
	<!--<content name="<%=Config.pjtName%>_CODE39-1" ver="<%=activeVer%>" url="<%=installURL%>/install/font/CODE39-1.TTF" target="C:\ComMate\<%=Config.pjtName%>" type="copy"/> 
	<content name="<%=Config.pjtName%>_CODE39-2" ver="1.0" url="<%=installURL%>/install/font/CODE39-1.TTF" target="C:\WINDOWS\Fonts" type="copy"/> -->

	<content name="<%=Config.pjtName%>_CODE39" ver="1.0" url="<%=installURL%>/install/font/CODE39.TTF" target="C:\Windows\Fonts" type="regsvr32"/>
	<content name="<%=Config.pjtName%>_CODE39_1" ver="1.0" url="<%=installURL%>/install/font/CODE39.TTF" target="C:\ComMate\<%=Config.pjtName%>\font" type="copy"/> 
	<content name="<%=Config.pjtName%>_3OF9" ver="1.0" url="<%=installURL%>/install/font/3OF9.TTF" target="C:\Windows\Fonts" type="regsvr32"/>
	<content name="<%=Config.pjtName%>_3OF9_1" ver="1.0" url="<%=installURL%>/install/font/3OF9.TTF" target="C:\ComMate\<%=Config.pjtName%>\font" type="copy"/> 
	
	<!-- 바탕화면 아이콘 생성 -->
	<content name="<%=Config.pjtName%>_matescm" target="C:\ComMate\<%=Config.pjtName%>\icon" type="copy"
	url="<%=installURL%>/install/icon/matescm.ico" ver="<%=activeVer%>"/>

	<content name="<%=Config.pjtName%>_icon" ver="<%=activeVer%>" target="C:\ComMate\<%=Config.pjtName%>\icon\matescm.ico" url="<%=installURL%>/index.jsp" type="makeinternetlnk" lnkName="<%=Config.pjtName%>"/> 
</root>