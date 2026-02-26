package kr.co.computermate.scmrft.board.api;

public record PageMetaResponse(
    int page,
    int size,
    long totalElements,
    int totalPages,
    boolean hasNext
) {
}
