package kr.co.computermate.scmrft.qualitydoc.api;

public record PageMetaResponse(
    int page,
    int size,
    long totalElements,
    int totalPages,
    boolean hasNext
) {
}
