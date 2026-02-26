package kr.co.computermate.scmrft.qualitydoc.repository;

import java.util.List;

public record QualityDocumentSearchResult(
    List<QualityDocumentEntity> items,
    long total
) {
}
