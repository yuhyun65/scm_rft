package kr.co.computermate.scmrft.orderlot.service;

import java.util.Locale;
import java.util.Set;

public enum OrderStatus {
  PENDING,
  CONFIRMED,
  IN_PROGRESS,
  COMPLETED,
  CANCELED;

  private static final Set<String> VALUES = Set.of(
      PENDING.name(),
      CONFIRMED.name(),
      IN_PROGRESS.name(),
      COMPLETED.name(),
      CANCELED.name()
  );

  public static String normalize(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    String upper = value.trim().toUpperCase(Locale.ROOT);
    if (!VALUES.contains(upper)) {
      throw OrderLotApiException.badRequest("status must be one of PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELED.");
    }
    return upper;
  }
}
