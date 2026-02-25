package kr.co.computermate.scmrft.report.api;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import kr.co.computermate.scmrft.report.service.ReportApiException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice(assignableTypes = ReportController.class)
public class ReportExceptionHandler {
  @ExceptionHandler(ReportApiException.class)
  public ResponseEntity<ApiErrorResponse> handleReportException(
      ReportApiException ex,
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

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ApiErrorResponse> handleValidation(
      MethodArgumentNotValidException ex,
      HttpServletRequest request
  ) {
    String message = "Validation failed.";
    FieldError firstError = ex.getBindingResult().getFieldError();
    if (firstError != null && firstError.getDefaultMessage() != null) {
      message = firstError.getDefaultMessage();
    }

    ApiErrorResponse body = new ApiErrorResponse(
        "REPORT_BAD_REQUEST",
        message,
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
  }

  @ExceptionHandler({MethodArgumentTypeMismatchException.class, HttpMessageNotReadableException.class})
  public ResponseEntity<ApiErrorResponse> handleMalformedRequest(HttpServletRequest request) {
    ApiErrorResponse body = new ApiErrorResponse(
        "REPORT_BAD_REQUEST",
        "Malformed request payload or parameter.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiErrorResponse> handleUnexpected(HttpServletRequest request) {
    ApiErrorResponse body = new ApiErrorResponse(
        "REPORT_INTERNAL_ERROR",
        "Unexpected error occurred.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
  }
}
