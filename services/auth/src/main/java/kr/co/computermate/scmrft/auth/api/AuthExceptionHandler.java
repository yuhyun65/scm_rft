package kr.co.computermate.scmrft.auth.api;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import kr.co.computermate.scmrft.auth.service.AuthApiException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = AuthController.class)
public class AuthExceptionHandler {
  @ExceptionHandler(AuthApiException.class)
  public ResponseEntity<ApiErrorResponse> handleAuthException(
      AuthApiException ex,
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
  public ResponseEntity<ApiErrorResponse> handleValidationException(
      MethodArgumentNotValidException ex,
      HttpServletRequest request
  ) {
    String message = "Validation failed.";
    FieldError firstError = ex.getBindingResult().getFieldError();
    if (firstError != null && firstError.getDefaultMessage() != null) {
      message = firstError.getDefaultMessage();
    }

    ApiErrorResponse body = new ApiErrorResponse(
        "AUTH_BAD_REQUEST",
        message,
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  public ResponseEntity<ApiErrorResponse> handleBadPayload(
      HttpMessageNotReadableException ex,
      HttpServletRequest request
  ) {
    ApiErrorResponse body = new ApiErrorResponse(
        "AUTH_BAD_REQUEST",
        "Malformed request payload.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiErrorResponse> handleUnexpectedException(HttpServletRequest request) {
    ApiErrorResponse body = new ApiErrorResponse(
        "AUTH_INTERNAL_ERROR",
        "Unexpected error occurred.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
  }
}

