package kr.co.computermate.scmrft.orderlot.service;

import org.springframework.http.HttpStatus;

public class OrderLotApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public OrderLotApiException(HttpStatus status, String code, String message) {
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

  public static OrderLotApiException badRequest(String message) {
    return new OrderLotApiException(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message);
  }

  public static OrderLotApiException notFound(String message) {
    return new OrderLotApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", message);
  }

  public static OrderLotApiException conflict(String message) {
    return new OrderLotApiException(HttpStatus.CONFLICT, "CONFLICT", message);
  }

  public static OrderLotApiException upstreamTimeout(String message) {
    return new OrderLotApiException(HttpStatus.GATEWAY_TIMEOUT, "UPSTREAM_TIMEOUT", message);
  }

  public static OrderLotApiException internalError(String message) {
    return new OrderLotApiException(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", message);
  }
}
