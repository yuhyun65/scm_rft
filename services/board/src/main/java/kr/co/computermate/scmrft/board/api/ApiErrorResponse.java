package kr.co.computermate.scmrft.board.api;

import java.time.Instant;
import java.util.List;

public record ApiErrorResponse(
    String code,
    String message,
    String traceId,
    String path,
    Instant timestamp,
    List<FieldErrorItem> details
) {
  public record FieldErrorItem(String field, String reason) {
  }
}
