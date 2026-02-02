// ########################
// :: (주) 컴퓨터메이트 ::
// ########################

// ADO: 데이터베이스 연결 역할 (쿼리문)

package Common;

import java.io.*;
import java.util.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.net.*;

import kr.co.comsquare.rwXmlLib.*;
import kr.co.comsquare.util.*;

import com.oreilly.servlet.MultipartRequest;
import com.oreilly.servlet.multipart.DefaultFileRenamePolicy;

public class FileUpload {

	public static RwXml Execute(HttpServletRequest request, HttpServletResponse response, RwXml rx, MultipartRequest multi, int msgFiles)
	{
		DBConn dbCon  = null;
		Connection conn = null;
		PreparedStatement pstmt  = null;
		ResultSet rs = null;

		try
		{
			// 파일 업로드
			String fileUploadPath = request.getRealPath("/") + "uploadData"; 
			String address = request.getRequestURL().toString().split("/servlet")[0] + "/uploadData/";

			File delete = new File(fileUploadPath + "\\" + "-");
			delete.delete();
			
			String fileList = "";
			String saveFiles = "";
			String oriFiles = "";

			int num1 = 0;	
			int num2 = 0;

			String getType = multi.getParameter("type");
			String getTableName = multi.getParameter("tableName");
			String getUserName = multi.getParameter("userName");
			String getStrUID = multi.getParameter("fileUID");

			int getUID = 0 ;
			if (getStrUID != "") {
				getUID = mate.strToInt(getStrUID);
			}

			String sqlUpdate = null ;
			String sqlQuery = null ;

			String saveFileList = "";
			String oriFileList = "";

			int fnum = 1;			

			dbCon = new DBConn();
			conn = dbCon.getJDBCConnection();

			if (getUID != 0)
			{
				sqlQuery = "SELECT SAVEFILELIST,ORIFILELIST FROM TRUSTUPLOADFILE WHERE UID=" + getUID;
				pstmt = conn.prepareStatement(sqlQuery);
				rs = pstmt.executeQuery();
				while(rs.next()) {
					saveFileList = rs.getString("saveFileList");
					oriFileList = rs.getString("oriFileList");
				}
			} else {
				saveFileList = "-" ;
				oriFileList = "-" ;
			}

			ArrayList<String> saveFileArray = mate.split(saveFileList, "▤");
			ArrayList<String> OriFileArray = mate.split(oriFileList, "▤");

			if (!(getType.equals("get"))) {

				Enumeration files = multi.getFileNames();
				
				while(files.hasMoreElements()){
					String fileName = (String)files.nextElement();
					String saveFile = multi.getFilesystemName(fileName) ;
					String oriFile = multi.getOriginalFileName(fileName) ;									 
					
					if (!(oriFile.equals("-"))){
						File saveFILE = new File(fileUploadPath + "\\" + saveFile);						
						String FILE = oriFile.substring(0, oriFile.lastIndexOf("."));
						String EXT = oriFile.substring(oriFile.lastIndexOf(".")+1);	
						String sFile = "";

						//파일이름이 한글이면	
						if (mate.isKorean(FILE)){
							sFile = EXT + "File"; 						
						} else {
							sFile = mate.StringReplace(FILE);							
							oriFile = mate.StringReplace(oriFile);
						}

						String saveFileList1 = "";				
						sqlQuery = "SELECT TOP 1 SAVEFILELIST FROM TRUSTUPLOADFILE WHERE SAVEFILELIST LIKE '%" + sFile + "%' ORDER BY UPLOADDATE DESC";
						pstmt = conn.prepareStatement(sqlQuery);
						rs = pstmt.executeQuery();
						while(rs.next()) {
							saveFileList1 = rs.getString("SAVEFILELIST");
						}
												
						if (saveFileList1 == "") {
							num1 = num1 + 1;								
							saveFile = sFile + num1 + "." + EXT ;
							saveFILE.renameTo(new File(fileUploadPath + "\\" + saveFile)); //파일이름변경
						} else {
							if (saveFileList1.indexOf("▤") == -1)
							{
								saveFileList1 = saveFileList1+"▤";
							}
							ArrayList<String> korSaveFile = mate.split(saveFileList1, "▤");
							boolean yn = false;
							fnum = 0;
							
							for(int i=0; i<korSaveFile.size(); i++) {
								String korSaveFiles = korSaveFile.get(i);		
								
								if(korSaveFiles.lastIndexOf(sFile) != -1){
									String fileNum = korSaveFiles.substring(sFile.length(), korSaveFiles.lastIndexOf("."));
									fnum = Integer.parseInt(fileNum);	
									yn = true;										
								}
							}
							if (yn)	{
								num2 = num2 + 1;
								fnum = fnum + num2;
								saveFile = sFile + fnum + "." + EXT ;
								
								saveFILE.renameTo(new File(fileUploadPath + "\\" + saveFile)); //파일이름변경
							}
						}
/*
						File f = new File(fileUploadPath + "\\" + sFile + fnum + "." + EXT);
						if (f.isFile()) {
							fnum += 1;
						}

						saveFile = sFile + fnum + "." + EXT ;
						saveFILE.renameTo(new File(fileUploadPath + "\\" + saveFile)); //파일이름변경
*/
						if (getUID != 0) { 
							for(int i=0; i<saveFileArray.size() ; i++) {
								String getOriFiles = OriFileArray.get(i) ;
								String getSaveFiles = saveFileArray.get(i) ;

								File getSave_file = new File(fileUploadPath + "\\" + getSaveFiles);
								File save_file = new File(fileUploadPath + "\\" + saveFile);
							
								if(oriFile.equals(getOriFiles)) {
									if(save_file.length() == 0){
										save_file.delete();
										getSave_file.renameTo(new File(fileUploadPath + "\\" + saveFile));
									}
								}
							}
						}
					}
					saveFiles += saveFile + "▤";
					oriFiles += oriFile + "▤";					
				}

				if (getUID != 0) {  //수정시 기존 파일들 삭제하고 파일 다시 업로드
					for(int i=0; i<saveFileArray.size() ; i++) {
						String getSaveFiles = saveFileArray.get(i) ;
						File delete_file = new File(fileUploadPath + "\\" + getSaveFiles);		
						delete_file.delete();
					}					
				}
			}
			
			saveFileList = "";
			oriFileList = "";
			
			if (!(saveFiles.equals(""))){
				saveFileList = saveFiles.substring(0, saveFiles.length()-1);
				oriFileList = oriFiles.substring(0, oriFiles.length()-1);
			}
			
			// 파일 저장 혹은 삭제
			int fileUID = getUID;

//			if (!(saveFileList.equals("-") || saveFileList.equals("")))
//			{
				if (getType.equals("add")) {

					if (!saveFileList.equals("-"))
					{
						sqlUpdate  = "INSERT INTO TRUSTUPLOADFILE(USERNAME,TABLENAME,UPLOADDATE,SAVEFILELIST,ORIFILELIST) VALUES('";
						sqlUpdate += getUserName + "', '";
						sqlUpdate += getTableName + "', ";
						sqlUpdate += "GETDATE(), '";
						sqlUpdate += saveFileList + "', '";
						sqlUpdate += oriFileList + "')";
						pstmt = conn.prepareStatement(sqlUpdate);
						pstmt.executeUpdate();

						sqlQuery = "SELECT MAX(UID) AS UID FROM TRUSTUPLOADFILE";
						pstmt = conn.prepareStatement(sqlQuery);
						rs = pstmt.executeQuery();

						while(rs.next()) {					
							fileUID = rs.getInt("uid");
						}
					}

				} else if (getType.equals("mod")){

					if(fileUID == 0) { //글 수정시 파일업로드를 처음할때

						sqlUpdate  = "INSERT INTO TRUSTUPLOADFILE(USERNAME,TABLENAME,UPLOADDATE,SAVEFILELIST,ORIFILELIST) VALUES('";
						sqlUpdate += getUserName + "', '";
						sqlUpdate += getTableName + "', ";
						sqlUpdate += "GETDATE(), '";
						sqlUpdate += saveFileList + "', '";
						sqlUpdate += oriFileList + "')";
						pstmt = conn.prepareStatement(sqlUpdate);
						pstmt.executeUpdate();

						sqlQuery = "SELECT MAX(UID) AS UID FROM TRUSTUPLOADFILE";
						pstmt = conn.prepareStatement(sqlQuery);
						rs = pstmt.executeQuery();

						while(rs.next()) {					
							fileUID = rs.getInt("uid");
						}
					} else { 
							
						if(saveFileList.equals("")) {  //기존파일을 다 삭제한 경우 
							sqlUpdate = "DELETE FROM TRUSTUPLOADFILE WHERE UID="+fileUID;
							pstmt = conn.prepareStatement(sqlUpdate);
							pstmt.executeUpdate();

							fileUID = 0 ;
						} else {
						
							sqlUpdate  = "UPDATE TRUSTUPLOADFILE SET ";
							sqlUpdate += "USERNAME='"+getUserName+"', ";
							sqlUpdate += "UPLOADDATE=GETDATE(), ";
							sqlUpdate += "SAVEFILELIST='"+saveFileList+"', ";
							sqlUpdate += "ORIFILELIST='"+oriFileList+"' ";
							sqlUpdate += "WHERE UID="+fileUID ;
							pstmt = conn.prepareStatement(sqlUpdate);
							pstmt.executeUpdate();
						}
					}

				} else if (getType.equals("del")) {
					sqlUpdate = "DELETE FROM TRUSTUPLOADFILE WHERE UID="+fileUID;
					pstmt = conn.prepareStatement(sqlUpdate);
					pstmt.executeUpdate();

					fileUID = 0 ;
				} 
// 			}
		
			// 처리 결과 조회
			if (fileUID != 0)
			{
				sqlQuery = "SELECT USERNAME,TABLENAME,UPLOADDATE,SAVEFILELIST,ORIFILELIST FROM TRUSTUPLOADFILE WHERE UID=" + fileUID;
				pstmt = conn.prepareStatement(sqlQuery);
				rs = pstmt.executeQuery();
				while(rs.next()) {

					rx.add(msgFiles,"fileUID",fileUID,true);
					rx.add(msgFiles,"userName",rs.getString("userName"),true);
					rx.add(msgFiles,"tableName",rs.getString("tableName"),true);
					rx.add(msgFiles,"uploadDate",rs.getString("uploadDate"),true);
					rx.add(msgFiles,"savefilelist",rs.getString("saveFileList"),true);
					rx.add(msgFiles,"orifilelist",rs.getString("oriFileList"),true);
					rx.add(msgFiles,"address",address,true);
				}
			} else {

					rx.add(msgFiles,"fileUID",fileUID,true);
					rx.add(msgFiles,"userName","-",true);
					rx.add(msgFiles,"tableName","-",true);
					rx.add(msgFiles,"uploadDate","-",true);
					rx.add(msgFiles,"savefilelist","-",true);
					rx.add(msgFiles,"orifilelist","-",true);
					rx.add(msgFiles,"address",address,true);
			}

		} catch(Exception e)
		{
			StringWriter sw = new StringWriter();
			e.printStackTrace(new PrintWriter(sw));

			rx.add(msgFiles, "FileUploadErr", sw.getBuffer().toString().replaceAll("\r\n", "").replaceAll("\t", "\n"), true);
		}
		finally
		{
			dbCon.closeConnection(conn, rs, pstmt);
			return rx;
		}
	}
}