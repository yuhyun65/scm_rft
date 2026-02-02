// ================================
// ComMate: DB 로 부터 데이터 가져오기
// ================================

package Common;

import java.io.*;
import java.util.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.http.*;

import kr.co.comsquare.rwXmlLib.*;
import kr.co.comsquare.util.*;

public class GetData
{
	public static RwXml Execute(HttpServletRequest request, HttpServletResponse response, RwXml rx, int data, String query)
    {
		DBConn dbCon = null;
		Connection conn = null;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
			
		try
		{
			dbCon = new DBConn();
			conn = dbCon.getJDBCConnection();

			pstmt = conn.prepareStatement(query);
			rs = pstmt.executeQuery();

			ResultSetMetaData rsmd = rs.getMetaData();
			int columnCount = rsmd.getColumnCount();

			while(rs.next())
			{
				int item = rx.add(data, "item", "", false);
				for (int i=1; i<=columnCount; i++)
				{
					String argName = rsmd.getColumnName(i);
					if (argName.equals(""))
					{
						argName = "EMPTY";
					}
					String rsStr = "";
					try
					{
						rsStr = rs.getString(i).trim();
					}
					catch (Exception e) { }
					rx.add(item, argName, rsStr, true);
				}
			}

		}catch (Exception e) {

			StringWriter sw = new StringWriter();
			e.printStackTrace(new PrintWriter(sw));

			rx.add(data, "GetDataErr", sw.getBuffer().toString(), true);

		} finally {

			dbCon.closeConnection(conn, rs, pstmt);

			return rx;
		}
	 }
}
