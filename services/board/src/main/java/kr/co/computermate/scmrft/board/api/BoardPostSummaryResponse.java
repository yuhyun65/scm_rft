package kr.co.computermate.scmrft.board.api;

import java.time.Instant;

public record BoardPostSummaryResponse(
    String postId,
    String boardType,
    String title,
    String status,
    String createdBy,
    Instant createdAt
) {
}
