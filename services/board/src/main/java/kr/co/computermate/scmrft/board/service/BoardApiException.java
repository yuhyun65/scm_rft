package kr.co.computermate.scmrft.board.service;

import org.springframework.http.HttpStatus;

public class BoardApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public BoardApiException(HttpStatus status, String code, String message) {
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

  public static BoardApiException badRequest(String message) {
    return new BoardApiException(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message);
  }

  public static BoardApiException unauthorized(String message) {
    return new BoardApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", message);
  }

  public static BoardApiException forbidden(String message) {
    return new BoardApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", message);
  }

  public static BoardApiException notFound(String message) {
    return new BoardApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", message);
  }

  public static BoardApiException failedDependency(String message) {
    return new BoardApiException(HttpStatus.FAILED_DEPENDENCY, "DEPENDENCY_FAILED", message);
  }

  public static BoardApiException badGateway(String message) {
    return new BoardApiException(HttpStatus.BAD_GATEWAY, "BAD_GATEWAY", message);
  }

  public static BoardApiException upstreamTimeout(String message) {
    return new BoardApiException(HttpStatus.GATEWAY_TIMEOUT, "UPSTREAM_TIMEOUT", message);
  }
}
