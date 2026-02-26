package kr.co.computermate.scmrft.board.api;

import java.time.Instant;
import java.util.List;

public record BoardPostDetailResponse(
    String postId,
    String boardType,
    String title,
    String status,
    String createdBy,
    Instant createdAt,
    String content,
    List<AttachmentRefResponse> attachments
) {
}
