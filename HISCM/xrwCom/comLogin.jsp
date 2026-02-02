<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8"%>
<%
	String[] pageURL = request.getRequestURL().toString().split("/xrwCom");
	String rootURL = pageURL[0] ;
%>
<html>
	<head>
		<title>::::::::::::::::::::::::::::::::::::::::::::::::::::</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<script language="javascript" src="<%=rootURL%>/script/preview.js"></script>
		<script language="javascript">
			var UserID = "<%=request.getParameter("UserID")%>";
			var UserPass = "<%=request.getParameter("UserPass")%>";
			function GetUserID()
			{
				return UserID ;
			}
			function GetUserPass()
			{
				return UserPass ;
			}
		</script>
	</head>

	<body leftmargin="0" marginwidth="0" topmargin="50%" marginheight="0" bgcolor="">
	<!-- body leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" -->
		<div align="center">
		<!--br><br -->
		<script language="javascript">
			TrustFormWrite("TFViewer", "<%=rootURL%>/xrwCom/comLogin.xrw", "TFViewer", "", "550", "380");
//			window.resizeTo(500, 370);
		</script>
		</div>
	</body>
</html>