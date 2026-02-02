<%@ page contentType="text/html;charset=utf-8"  pageEncoding="utf-8"%>
<%
	String[] pageURL = request.getRequestURL().toString().split("/index");
	String rootURL = pageURL[0] ; 
	if (rootURL.substring(rootURL.length() - 1).equals("/")) 
	{
		rootURL = rootURL.substring(0, rootURL.length() - 1);
	}
	String TFUpdateURL = rootURL + "/install/TFSmartUpdater_m.cab#version=3,0,0,1";
%>
<HTML>
<HEAD>
<script language="javascript">
	function window::onLoad()  {
		 
		var ret = TFUpdate.getConfig("<%=rootURL%>/install/config.jsp");
		if (ret != true) {
			var message = "뷰어 설치 작업을 제대로 수행하지 못했습니다. \n\n";
			message += "페이지 오류 발생 시 관리자한테 문의하세요.";
			alert(message);
		} 
				
//var WshShell = new ActiveXObject("Wscript.Shell"); 
//strDesktop = WshShell.SpecialFolders("Desktop"); 
//var oUrlLink = WshShell.CreateShortcut(strDesktop + "\\SCMYI.url"); 
//oUrlLink.TargetPath = '<%=rootURL%>/index.jsp'; 
//oUrlLink.Save();

		// location.href='<%=rootURL%>/xrwCom/comLogin.jsp' ;

	   location.href="<%=rootURL%>/xrwCom/comLogin.jsp?UserID=<%=request.getParameter("UserID")%>&UserPass=<%=request.getParameter("UserPass")%>" ;

/*
		window.open('<%=rootURL%>/xrwCom/comLogin.jsp?UserID=<%=request.getParameter("UserID")%>&UserPass=<%=request.getParameter("UserPass")%>',
			'login','menubar=no, toolbar=no, scrollbars=no, status=no, location=no, top=50, left=200 ');
		window.open("about:blank","_self") ;

		window.opener=self;
		window.close();
*/
	}

</script>
</HEAD>
<BODY>
	<OBJECT id="TFUpdate" classid="CLSID:ED5D862B-6A06-46de-A929-F2C588742CBD" width="0" height="0" CODEBASE="<%=TFUpdateURL%>">
		<PARAM name="deleteZipFile" value="false"/>			<!-- zip 파일을 지운다 -->
		<PARAM name="registry" value="true"/>				<!-- registry를 이용하지 않는다.(false) -->
		<PARAM name="enableLog" value ="false" />			<!-- log를 남긴다. -->
		<PARAM name="selfUi" value="true" />				<!-- 자체 UI를 이용한다. -->
		<PARAM name="dlgNotClose" value="true" />			<!-- UI를 하나의 dialog로 사용한다. -->
		<PARAM name="hideDownloadCancel" value="true" />	<!-- true 설정 시 취소 버튼을 숨김 -->
		<PARAM name="stopNotFindContent" value= "true" />	<!-- 추가된 option 서버에 파일이 없어도 계속 진행 된다. -->
		<PARAM name="useNameTarget" value="true" />			<!-- name과 target을 기준으로 검색을 진행. -->
		<PARAM name="auto_high_integrity" value="true" />	<!-- broker high 권한을 자동을 획득 -->
	</OBJECT>
</BODY>
</HTML>