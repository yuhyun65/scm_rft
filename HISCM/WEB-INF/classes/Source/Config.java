// ================================
// ComMate: 환경 설정
// ================================

package Common;

public class Config {

	public static String pjtName = "HISCM";

	// 기본 DB 연결 정보
/*
	public static String dbServer = "home.computermate.co.kr" ;
	public static String dbPort = "1343" ;
	public static String dbUser = "sa" ;
	public static String dbPass = "commate" ;
*/
/*
	public static String dbServer = "idc.computermate.co.kr" ;
	public static String dbPort = "1243" ;
	public static String dbUser = "sa" ;
	public static String dbPass = "mate3008[]" ;
*/
//	public static String dbServer = "115.88.241.12\\MSSQLSERVER" ;

	//2026.02.02 / 김태산 / 주석처리
	// public static String dbServer = "106.248.230.82\\MSSQLSERVER" ;
	// public static String dbPort = "1243" ;
	// public static String dbUser = "sa" ;
	// public static String dbPass = "gksdlf1234[]" ;

	// public static String dbName ="ERP_HI" ;

	//2026.02.02 / 김태산 / 테스트 DB 추가
	public static String dbServer = "test4.computermate.co.kr\\MSSQLSERVER" ;
	public static String dbPort = "12019" ;
	public static String dbUser = "sa" ;
	public static String dbPass = "mate3008[]" ;

	public static String dbName ="MES_HI" ;

	// DB 디버그 여부
	public static int isDebug = 0;
}