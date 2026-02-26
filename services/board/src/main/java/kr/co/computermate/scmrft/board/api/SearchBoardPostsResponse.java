package kr.co.computermate.scmrft.board.api;

import java.util.List;

public record SearchBoardPostsResponse(
    List<BoardPostSummaryResponse> items,
    PageMetaResponse page
) {
}
