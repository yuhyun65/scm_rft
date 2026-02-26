package kr.co.computermate.scmrft.orderlot.api;

public record PageMetaResponse(
    int page,
    int size,
    long totalElements,
    int totalPages,
    boolean hasNext
) {
}
