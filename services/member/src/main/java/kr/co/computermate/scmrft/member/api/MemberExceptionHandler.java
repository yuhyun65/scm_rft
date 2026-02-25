package kr.co.computermate.scmrft.member.api;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import kr.co.computermate.scmrft.member.service.MemberApiException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = MemberController.class)
public class MemberExceptionHandler {
  @ExceptionHandler(MemberApiException.class)
  public ResponseEntity<ApiErrorResponse> handleMemberException(
      MemberApiException ex,
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
        "MEMBER_BAD_REQUEST",
        "Invalid query parameter type.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiErrorResponse> handleUnexpected(HttpServletRequest request) {
    ApiErrorResponse body = new ApiErrorResponse(
        "MEMBER_INTERNAL_ERROR",
        "Unexpected error occurred.",
        request.getRequestURI(),
        Instant.now()
    );
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
  }
}
