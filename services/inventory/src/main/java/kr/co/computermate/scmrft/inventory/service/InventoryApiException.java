package kr.co.computermate.scmrft.inventory.service;

import org.springframework.http.HttpStatus;

public class InventoryApiException extends RuntimeException {
  private final HttpStatus status;
  private final String code;

  public InventoryApiException(HttpStatus status, String code, String message) {
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

  public static InventoryApiException badRequest(String message) {
    return new InventoryApiException(HttpStatus.BAD_REQUEST, "INVENTORY_BAD_REQUEST", message);
  }
}
