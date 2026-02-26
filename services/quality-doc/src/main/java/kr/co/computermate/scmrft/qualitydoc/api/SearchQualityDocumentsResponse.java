package kr.co.computermate.scmrft.qualitydoc.api;

import java.util.List;

public record SearchQualityDocumentsResponse(
    List<QualityDocumentSummaryResponse> items,
    PageMetaResponse page
) {
}
