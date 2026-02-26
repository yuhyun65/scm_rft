package kr.co.computermate.scmrft.orderlot.api;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.computermate.scmrft.orderlot.service.OrderLotApiException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice(assignableTypes = OrderLotController.class)
public class OrderLotExceptionHandler {
  @ExceptionHandler(OrderLotApiException.class)
  public ResponseEntity<ApiErrorResponse> handleOrderLotApiException(
      OrderLotApiException ex,
      HttpServletRequest request
  ) {
    return withTraceId(request, ex.getStatus(), ex.getCode(), ex.getMessage(), List.of());
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ApiErrorResponse> handleValidationError(
      MethodArgumentNotValidException ex,
      HttpServletRequest request
  ) {
    List<ApiErrorResponse.FieldErrorItem> details = ex.getBindingResult().getFieldErrors().stream()
        .map(error -> new ApiErrorResponse.FieldErrorItem(error.getField(), error.getDefaultMessage()))
        .toList();
    return withTraceId(request, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Validation failed.", details);
  }

  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  public ResponseEntity<ApiErrorResponse> handleTypeMismatch(HttpServletRequest request) {
    return withTraceId(
        request,
        HttpStatus.BAD_REQUEST,
        "VALIDATION_ERROR",
        "Invalid query parameter type.",
        List.of()
    );
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  public ResponseEntity<ApiErrorResponse> handleMalformedPayload(HttpServletRequest request) {
    return withTraceId(
        request,
        HttpStatus.BAD_REQUEST,
        "VALIDATION_ERROR",
        "Malformed request payload.",
        List.of()
    );
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiErrorResponse> handleUnexpected(HttpServletRequest request) {
    return withTraceId(
        request,
        HttpStatus.INTERNAL_SERVER_ERROR,
        "INTERNAL_ERROR",
        "Unexpected error occurred.",
        List.of()
    );
  }

  private ResponseEntity<ApiErrorResponse> withTraceId(
      HttpServletRequest request,
      HttpStatus status,
      String code,
      String message,
      List<ApiErrorResponse.FieldErrorItem> details
  ) {
    String traceId = resolveTraceId(request);
    ApiErrorResponse body = new ApiErrorResponse(
        code,
        message,
        traceId,
        request.getRequestURI(),
        Instant.now(),
        details
    );

    return ResponseEntity.status(status)
        .header("X-Trace-Id", traceId)
        .header(HttpHeaders.CONTENT_TYPE, "application/json")
        .body(body);
  }

  private String resolveTraceId(HttpServletRequest request) {
    String traceId = request.getHeader("X-Trace-Id");
    if (traceId == null || traceId.isBlank()) {
      return UUID.randomUUID().toString();
    }
    return traceId;
  }
}
