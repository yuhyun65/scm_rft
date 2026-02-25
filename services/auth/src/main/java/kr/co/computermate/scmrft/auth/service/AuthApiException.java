package kr.co.computermate.scmrft.auth.service;

import org.springframework.http.HttpStatus;

public class AuthApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public AuthApiException(HttpStatus status, String code, String message) {
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

  public static AuthApiException badRequest(String message) {
    return new AuthApiException(HttpStatus.BAD_REQUEST, "AUTH_BAD_REQUEST", message);
  }

  public static AuthApiException unauthorized(String message) {
    return new AuthApiException(HttpStatus.UNAUTHORIZED, "AUTH_UNAUTHORIZED", message);
  }

  public static AuthApiException locked(String message) {
    return new AuthApiException(HttpStatus.LOCKED, "AUTH_ACCOUNT_LOCKED", message);
  }
}
