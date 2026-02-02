// ########################
// :: (주) 컴퓨터메이트 ::
// ########################

// 공통 클래스 선언

package Common;

import java.io.*;
import javax.servlet.*; 
import javax.servlet.http.*;
import java.sql.*;
import java.util.*;

import kr.co.comsquare.rwXmlLib.*;
import kr.co.comsquare.util.* ;

public class mate {

	// 함수설명: 문자를 숫자로 바꾸는 함수
	public static int strToInt(String str)
	{
		str = replace(str) ;
		return Integer.parseInt(str);
	}

	// 함수설명: 숫자를 문자로 바꾸는 함수
	public static String intToStr(int number)
	{
		return Integer.toString(number);
	}

	// 함수설명: 숫자를 지정한 자리수만큼 앞에 0을 붙여서 문자로 반환
	public static String addZero(int number, int length)
	{
		String str = Integer.toString(number);
		int addCount = length - str.length() ;

		if ( addCount < 0)  return "Err" ;
		else for (int i=0; i<addCount; i++) str = "0" + str ;
		return str ;
	}

	// 함수설명: 숫자를 지정한 자리수만큼 앞에 공백을 붙여서 문자로 반환
	public static String addSpace(int number, int length)
	{
		String str = Integer.toString(number);
		int addCount = length - str.length() ;

		if ( addCount < 0)  return "Err" ;
		else for (int i=0; i<addCount; i++) str = " " + str ;
		return str ;
	}

	// 함수설명: 문자열 치환 함수
	public static String replace(String str, String findStr, String replaceStr) {
		str = str.replaceAll(findStr, replaceStr);
		return str ;
	}

	// 함수설명: 문자열의 앞뒤 공백과 문자사이 공백 없에는 함수
	public static String replace(String str) {
		str = str.replaceAll(" ", "");
		return str ;
	}

	// 함수설명: 특정 문자열을 구분자로 문자열을 나누어 ArrayList 저장
	public static ArrayList<String> split(String str, String token) {

		int tokenLength = token.length(); // 토큰의 길이
		ArrayList<String> returnArray = new ArrayList<String>(); 

		int  index = str.indexOf(token) ; // 토큰의 위치 인덱스
		
		while(index > -1) {

			returnArray.add(str.substring(0, index)); 
			str = str.substring(index+tokenLength, str.length()) ;

			index = str.indexOf(token);
		}

		returnArray.add(str) ;

		return returnArray ;

	}

	// 함수설명: 특정 문자열을 구분자로 문자열을 나누어 2차원 ArrayList 저장
	public static ArrayList<ArrayList> split(String str, String colToken, String rowToken) {

		int tokenLength = rowToken.length(); // 토큰의 길이

		ArrayList<ArrayList> returnArray = new ArrayList<ArrayList>(); 

		int  index = str.indexOf(rowToken) ; // 토큰의 위치 인덱스
		
		while(index > -1) {

			ArrayList<String> colArray = new ArrayList<String>();

			String colStr = str.substring(0, index) ;
			colArray = split(colStr, colToken) ;
			returnArray.add(colArray);
			
			str = str.substring(index+tokenLength, str.length()) ;

			index = str.indexOf(rowToken);
		}

		ArrayList<String> colArray = new ArrayList<String>();
		colArray = split(str, colToken) ;
		returnArray.add(colArray);

		return returnArray ;

	}

	// 지정 포멧으로 현재 날짜 얻기
	public static String getDate(String format) {
		
		Calendar now = Calendar.getInstance();
		int yyyy = now.get(Calendar.YEAR) ;
		int m = now.get(Calendar.MONTH) + 1;
		int d = now.get(Calendar.DATE) ;
		String mm = Integer.toString(m);
		String dd = Integer.toString(d) + "";

		if(m < 10) {
			mm = "0"+m;
		}
		
		if(d < 10) {
			dd = "0"+d;
		}

		if (format.equals("yyyy/mm/dd")) 	return yyyy+"/"+mm+"/"+dd ;
		else if (format.equals("yyyy-mm-dd")) return yyyy+"-"+mm+"-"+dd ;
		else if (format.equals("mm/dd/yyyy")) return mm+"/"+dd+"/"+yyyy ;
		else if (format.equals("mm-dd-yyyy")) return mm+"-"+dd+"-"+yyyy ;
		else if (format.equals("yyyymmdd")) return yyyy+""+mm+""+dd ;
		else if (format.equals("mmddyyyy")) return mm+""+dd+""+yyyy ;
		else return yyyy+""+mm+""+dd ;

	} public static String getDate() { return getDate("yyyymmdd"); }

	 //한글인지 체크(한글이면 true, 영어면 false)
	public static boolean isKorean (String p_str) { 

        if (p_str == null || p_str.length() == 0) { 
            return true; 
        } 

        p_str = p_str.trim(); 

        String a_str[] = new String[p_str.length()]; 

        for (int i = 0; i < a_str.length; i++) { 
            a_str[i] = p_str.substring(i, i + 1); 
            char a_chars[] = a_str[i].toCharArray(); 

            for (int j = 0; j < a_chars.length; j++) { 
                if (a_chars[j] >= '!' && a_chars[j] <= '~') { 
                } else { 
                    return true; 
                } 
            } 

//            for (int j = 0; j < a_chars.length; j++) { 
//                if (a_chars[j] >= 'a' && a_chars[j] <= 'z' || 
//                    a_chars[j] >= 'A' && a_chars[j] <= 'Z') { 
//                } else { 
//                    if (a_chars[j] >= '0' && a_chars[j] <= '9') {  
//                    } else { 
//                        return true; 
//                    } 
//               } 
//           } 

        } 
        return false; 
    }

	 // 함수설명: 특수문자 제거 함수 -> !"#$%&'*+`/:;<=>?@[\]^,
	 public static String StringReplace(String str){
	  int str_length = str.length();
	  String strlistchar   = "";
	  String str_imsi   = ""; 
	  String[] filter_word={"\\!","\\$","\\%","\\&","\\'","\\*","\\+","\\`","\\/","\\:","\\;","\\<","\\=","\\>","\\?","\\@","\\[","\\\\","\\]", "\\^"};

	  for(int i=0;i<filter_word.length;i++){
	   str_imsi = str.replaceAll(filter_word[i],"");
	   str = str_imsi;
	  }
	  return str;
	   }
}
