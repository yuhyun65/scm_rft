package kr.co.computermate.scmrft.qualitydoc.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record QualityDocumentAckRequest(
    @NotBlank(message = "memberId is required.")
    @Size(max = 40, message = "memberId must be less than or equal to 40 characters.")
    String memberId,
    @NotBlank(message = "ackType is required.")
    String ackType,
    @Size(max = 500, message = "comment must be less than or equal to 500 characters.")
    String comment
) {
}
