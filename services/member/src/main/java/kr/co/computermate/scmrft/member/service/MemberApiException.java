package kr.co.computermate.scmrft.member.service;

import org.springframework.http.HttpStatus;

public class MemberApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public MemberApiException(HttpStatus status, String code, String message) {
    super(message);
    this.status = status;
    this.code = code;
  }

  public HttpStatus getStatus() {
    return status;
  }

  public String getCode() {
    return code;
  }

  public static MemberApiException badRequest(String message) {
    return new MemberApiException(HttpStatus.BAD_REQUEST, "MEMBER_BAD_REQUEST", message);
  }

  public static MemberApiException notFound(String message) {
    return new MemberApiException(HttpStatus.NOT_FOUND, "MEMBER_NOT_FOUND", message);
  }
}

