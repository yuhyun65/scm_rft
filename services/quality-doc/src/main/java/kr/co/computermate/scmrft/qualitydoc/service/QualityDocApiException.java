package kr.co.computermate.scmrft.qualitydoc.service;

import org.springframework.http.HttpStatus;

public class QualityDocApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public QualityDocApiException(HttpStatus status, String code, String message) {
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

  public static QualityDocApiException badRequest(String message) {
    return new QualityDocApiException(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message);
  }

  public static QualityDocApiException notFound(String message) {
    return new QualityDocApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", message);
  }

  public static QualityDocApiException conflict(String message) {
    return new QualityDocApiException(HttpStatus.CONFLICT, "CONFLICT", message);
  }
}
