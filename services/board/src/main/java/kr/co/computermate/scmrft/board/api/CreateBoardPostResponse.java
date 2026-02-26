package kr.co.computermate.scmrft.board.api;

import java.time.Instant;

public record CreateBoardPostResponse(
    String postId,
    Instant createdAt
) {
}
