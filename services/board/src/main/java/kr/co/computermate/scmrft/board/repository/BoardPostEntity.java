package kr.co.computermate.scmrft.board.repository;

import java.time.Instant;
import java.util.UUID;

public record BoardPostEntity(
    UUID postId,
    String boardType,
    String title,
    String content,
    String status,
    String createdBy,
    Instant createdAt
) {
}
