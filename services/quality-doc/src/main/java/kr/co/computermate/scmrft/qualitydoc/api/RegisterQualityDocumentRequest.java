package kr.co.computermate.scmrft.qualitydoc.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterQualityDocumentRequest(
    @NotBlank(message = "title is required.")
    @Size(max = 200, message = "title must be less than or equal to 200 characters.")
    String title,
    @NotBlank(message = "documentType is required.")
    @Size(max = 30, message = "documentType must be less than or equal to 30 characters.")
    String documentType,
    @Size(max = 50, message = "publisherMemberId must be less than or equal to 50 characters.")
    String publisherMemberId
) {
}
