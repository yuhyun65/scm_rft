package kr.co.computermate.scmrft.board.api;

import jakarta.validation.constraints.NotBlank;

public record AttachmentRefRequest(
    @NotBlank(message = "fileId is required.")
    String fileId
) {
}
