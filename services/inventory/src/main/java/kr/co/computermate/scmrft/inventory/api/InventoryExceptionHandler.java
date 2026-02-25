package kr.co.computermate.scmrft.inventory.api;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import kr.co.computermate.scmrft.inventory.service.InventoryApiException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice(assignableTypes = InventoryController.class)
public class InventoryExceptionHandler {
  @ExceptionHandler(InventoryApiException.class)
  public ResponseEntity<ApiErrorResponse> handleInventoryException(
      InventoryApiException ex,
      HttpServletRequest request
  ) {
    ApiErrorResponse body = new ApiErrorResponse(
        ex.getCode(),
        ex.getMessage(),
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(ex.getStatus()).body(body);
  }

  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  public ResponseEntity<ApiErrorResponse> handleTypeMismatch(HttpServletRequest request) {
    ApiErrorResponse body = new ApiErrorResponse(
        "INVENTORY_BAD_REQUEST",
        "Invalid query parameter type.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiErrorResponse> handleUnexpected(HttpServletRequest request) {
    ApiErrorResponse body = new ApiErrorResponse(
        "INVENTORY_INTERNAL_ERROR",
        "Unexpected error occurred.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
  }
}
