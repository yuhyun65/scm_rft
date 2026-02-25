package kr.co.computermate.scmrft.file.service;

import org.springframework.http.HttpStatus;

public class FileApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public FileApiException(HttpStatus status, String code, String message) {
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

  public static FileApiException badRequest(String message) {
    return new FileApiException(HttpStatus.BAD_REQUEST, "FILE_BAD_REQUEST", message);
  }

  public static FileApiException notFound(String message) {
    return new FileApiException(HttpStatus.NOT_FOUND, "FILE_NOT_FOUND", message);
  }
}
