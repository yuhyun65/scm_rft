package kr.co.computermate.scmrft.report.service;

import org.springframework.http.HttpStatus;

public class ReportApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public ReportApiException(HttpStatus status, String code, String message) {
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

  public static ReportApiException badRequest(String message) {
    return new ReportApiException(HttpStatus.BAD_REQUEST, "REPORT_BAD_REQUEST", message);
  }

  public static ReportApiException notFound(String message) {
    return new ReportApiException(HttpStatus.NOT_FOUND, "REPORT_JOB_NOT_FOUND", message);
  }
}
