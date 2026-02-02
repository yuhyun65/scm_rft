
// ================================
// ComMate: 데이터베이스 연결 설정
// ================================

package Common;

import javax.naming.*;
import java.sql.*;
import javax.sql.*;

public class DBConn {

	public Connection getJDBCConnection()
	{
		return getJDBCConnection("mssql");
	}
	public Connection getJDBCConnection(String dbType)
	{
		Connection conn = null;

		String driver = "";
		String url = "";

		try{

			if("mssql".equals(dbType))
			{              
				driver	= "com.microsoft.sqlserver.jdbc.SQLServerDriver";
				url		= "jdbc:sqlserver://"+Config.dbServer+":"+Config.dbPort+";DatabaseName="+Config.dbName;
				//url		= "jdbc:sqlserver://"+Config.dbServer+":"+Config.dbPort+";DatabaseName="+Config.dbName+";user="+Config.dbUser+";password="+Config.dbPass+";";
			}
			else if("oracle".equals(dbType))
			{
				driver	= "oracle.jdbc.driver.OracleDriver";
				url		= "jdbc:oracle:thin:@"+Config.dbServer+":"+Config.dbPort+":"+Config.dbName;
			}

			Class.forName(driver).newInstance();
			//System.out.println(url);
			conn = DriverManager.getConnection(url,Config.dbUser,Config.dbPass);
			//conn = DriverManager.getConnection(url);

		}catch(Exception e){
			
			e.printStackTrace();
		}

		return conn;
	}
	public void closeConnection(Connection conn, ResultSet rs, PreparedStatement pstmt)
	{
		if (conn != null)		try{conn.close();}catch(Exception e){}
		if (rs != null) 		try{rs.close();}catch(Exception e){}
		if (pstmt != null)		try{pstmt.close();}catch(Exception e){}
	}

	public void closeConnection(Connection conn)
	{
		closeConnection(conn, null, null);
	}

	public void closeConnection(Connection conn, ResultSet rs)
	{
		closeConnection(conn, rs, null);
	}

	public void closeConnection(Connection conn, PreparedStatement pstmt)
	{
		closeConnection(conn, null, pstmt);
	}

}