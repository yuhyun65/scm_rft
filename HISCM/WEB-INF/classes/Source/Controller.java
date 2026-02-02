
// ================================
// ComMate: 메인 Controller
// ================================

package Common;

// 웹서비스 중개 역할하는 컨트롤러
import java.io.*;
import javax.servlet.*; 
import javax.servlet.http.*;
import java.sql.*;
import java.util.*;

import kr.co.comsquare.rwXmlLib.*;
import kr.co.comsquare.util.* ;

import com.oreilly.servlet.MultipartRequest;
import com.oreilly.servlet.multipart.DefaultFileRenamePolicy;

import java.security.*;

import sun.misc.BASE64Encoder;
import sun.misc.BASE64Decoder;

public class Controller extends HttpServlet {


	public static String getMD5_Base64(String input) {

		BASE64Encoder bencoder = new BASE64Encoder();
		StringBuffer uni_s = new StringBuffer();
		byte[] byte16 = null;

		try
		{
			byte16 = input.getBytes("UTF-16LE");	
			for (int i=0 ; i<byte16.length ; i++)
			{
				uni_s.append((int)byte16[i]);
			}
			input = uni_s.toString();
//			System.out.println(input);
		}
		catch (Exception e) {}  

		byte[] rawData = null;
		try
		{
			MessageDigest md = MessageDigest.getInstance("MD5");
			md.update(byte16);
			rawData = md.digest();				
		}
		catch (Exception e) {}      

		return bencoder.encode(rawData);
    }

	//Servlet service
	public void service(HttpServletRequest request, HttpServletResponse response)
    {							
		String address = request.getRequestURL().toString().split("/servlet")[0] + "/uploadData/";

		RwXml rx = new RwXml();
		rx.setEncoding("UTF-8");
		int rootNodeID = RwXml.rootNodeID ;
		int msgBuff = rx.add(rootNodeID, "msgBuff", "", false);
		rx.add(msgBuff, "address", address, false);
		
		int debug = 0;
		if (Config.isDebug == 1) 
		debug = rx.add(msgBuff, "debug", "", false); 

		try
        {
			request.setCharacterEncoding("utf-8");

			String queryString = request.getParameter("queryString");
			String upload = "";
			String AdminYN = "";

			MultipartRequest multi = null;
			try
			{				
				File isAddr = new File(request.getRealPath("/") + "uploadData");
				if (!isAddr.exists())
				{
					isAddr.mkdir();
				}

				multi = new MultipartRequest(request, request.getRealPath("/") + "uploadData", 1000*1024*1024, "utf-8", new DefaultFileRenamePolicy());
				upload = multi.getParameter("upload");
			}
			catch (Exception e) {}

			if (!isEmpty(upload))
			{
				if (Config.isDebug == 1) rx.add(debug, "upload", "Y", false); 

				int msgFiles = rx.add(msgBuff, "msgFiles", "", false);
				rx = FileUpload.Execute(request, response, rx, multi, msgFiles);
			}
			else if (isEmpty(queryString)) // 쿼리 스트링이 비어 있다면 프로시저 호출
			{
				StringBuffer query = new StringBuffer();
				query.append("Exec " + request.getParameter("spName") + " @WorkGB = '" + request.getParameter("workGB") + "'");
				
				String argList = request.getParameter("argList");
				if (!isEmpty(argList))
				{
					String[] argArray = argList.trim().split(",");
					for (int i=0; i < argArray.length; i++)
					{
						String argName = argArray[i];
						String argValue = request.getParameter(argName);

						if (argName.equals("UserID") && (argValue.equals("mateadmin") || argValue.equals("dhdo")))
							AdminYN = "Y";

						if (request.getParameter("spName").equals("sp_SCM_MemberShip") &&
							request.getParameter("workGB").equals("Login") &&
							argName.equals("UserPass") && AdminYN != "Y")
						{		
							//query.append(", @" + argName + " = '" + argValue + "'");
							query.append(", @" + argName + " = '" + getMD5_Base64(argValue) + "'");

							//ERP사용자가 아닌 경우(외주처), 암호화되지 않는 비밀번호를 넘겨준다. (외주처 비밀번호는 암호화하지 않음)
							query.append(", @UserPass1 = '" + argValue + "'");
						}
						else
						{
							query.append(", @" + argName + " = '" + argValue + "'");
						}
					}
				}
				queryString = query.toString();
System.out.println("********************************************     " + queryString);
				if (Config.isDebug == 1) rx.add(debug, "query", queryString, false); 
				// DB 연결 및 xmldata 얻기
				int data = rx.add(msgBuff, "data", "", false);
				rx = GetData.Execute(request, response, rx, data, queryString);

			} else {

				if (Config.isDebug == 1) rx.add(debug, "query", queryString, false); 
				// DB 연결 및 xmldata 얻기
				int data = rx.add(msgBuff, "data", "", false);
				rx = GetData.Execute(request, response, rx, data, queryString);
			}
        }
        catch(Exception ex)
        {
			StringWriter sw = new StringWriter();
			ex.printStackTrace(new PrintWriter(sw));
			rx.add(msgBuff, "ControllerErr", sw.getBuffer().toString().replaceAll("\r\n", "\n"), true);
			
        }finally{
			response.setContentType("text/xml;charset=utf-8"); 
			try 
			{
				response.getWriter().println(rx.xmlFlush() + rx.xmlEndFlush());
			}
			catch (Exception ex) 
			{
			}
		}		
    }

    private boolean isEmpty(Object object) {

        if (object == null) {
            return true;
        }

        if (object instanceof String) {
            String str = (String) object;
            return str.length() == 0;
        }

        if (object instanceof Collection) {
            Collection collection = (Collection) object;
            return collection.size() == 0;
        }

        //if (object.getClass().isArray()) {
          //  try {
            //    if (Array.getLength(object) == 0) {
              //      return true;
              //  }
            //} catch (Exception e) {
                // do nothing
           // }
        //}

        return false;
    } 
}
